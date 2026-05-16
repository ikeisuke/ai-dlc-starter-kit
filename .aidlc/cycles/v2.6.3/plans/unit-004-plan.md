# Unit 004 実装計画: Operations Phase マージ前 CI 通過確認フローの SoT 化

## 対象 Unit

- **Unit**: 004 - Operations Phase マージ前 CI 通過確認フローの SoT 化
- **関連 Issue**: #694
- **優先度**: Medium
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.0 サイクルでは PR マージ直前に「Unit 005 のテスト削除」「`check-cycle-phase-completion` の強化」「マージ前 CI 通過確認の繰り返し」が必要となり、属人的な対応が発生した。これらの修復は Unit 完了時点では検出されず、PR マージ直前のフェーズで顕在化した。

`steps/operations/` 配下に「マージ前 CI 通過確認 + 失敗時の修復経路」フローが SoT として明文化されていないため、各サイクルで再現性のない対応が繰り返される構造的リスクが残っている。

本 Unit は #694 提案を反映し、`steps/operations/operations-release.md` の §7.12（PR マージ前レビュー）と §7.13（PR マージ）の間に「マージ前 CI 通過確認」サブステップを新設して SoT 化する。同時に CI 失敗時の修復経路を 3 分岐で明文化し、`reviewing-operations-premerge` スキルとの観点重複を解消する。

## スコープ

### 含まれるもの（責務）

- `skills/aidlc/steps/operations/operations-release.md` への「マージ前 CI 通過確認」サブステップ新設（§7.12.6 として §7.12.5 と §7.13 の間に配置）
  - **PR 番号 / HEAD SHA 起点を第一**とした CI ジョブ通過確認手順を明示（`gh pr checks <PR>` / `gh pr view --json statusCheckRollup` / `gh run list --commit <HEAD-SHA>`）
  - `gh run list --branch <branch>` はブランチ命名規約準拠時のみの **フォールバック扱い**として記載（命名不一致時の代替手順も併記）
  - `gh_status != available` 時のスキップ条件と手動確認案内
  - `bin/check-cycle-phase-completion.sh` の opt-in シグナル方式による条件付き呼び出し（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」規約準拠）
- CI 失敗時の修復経路 SoT 化（3 分岐）:
  - **修復可能**: 修正コミット → 再 push → §7.12.6 再実行ループ
  - **修復不能（環境依存・flaky）**: `AskUserQuestion` でマージブロック解除をユーザー承認（`automation_mode` に関わらず常時必須）
  - **構造的不整合（Unit 跨ぎ）**: サイクル内修正として扱い新規 Issue 起票しない（マージ後の振り返りで Try として記録する案内）
- `reviewing-operations-premerge` スキルとの観点重複・補完関係の明示記述:
  - §7.12.6 冒頭または末尾に「本ステップと `reviewing-operations-premerge` の役割分担」を明示する短い節を追加
  - 重複観点（PR マージ前確認）と補完観点（CI 状態 vs PR 全体品質・セキュリティ）の区別
- `steps/operations/index.md` の「§2 分岐ロジック」または該当箇所に §7.12.6 の存在を反映（必要な場合）
- 既存 §7.13 内の `error:checks-status-unknown` ハンドリングとの整合確認（重複しない / 役割分担明示）

### 含まれないもの（境界）

- `bin/check-cycle-phase-completion.sh` 自体のロジック変更（呼び出し SoT 化のみ）
- `reviewing-operations-premerge` スキル本体の評価軸変更
- マージ前ステップ以外（PR 作成 / マージ後 cleanup）の改修
- `scripts/operations-release.sh` の `merge-pr` サブコマンド内 CI チェックロジック変更
- 新規スクリプト作成（既存 `gh` CLI と `bin/check-cycle-phase-completion.sh` の呼び出しのみで完結）

## 実装方針

### Phase 1: 設計

#### ドメインモデル（マージ前 CI 確認の責務分割）

| レイヤー | 責務 | 入出力 |
|---------|------|--------|
| §7.12.6 マージ前 CI 通過確認（新設） | PR の全 CI ジョブが通過していることを明示確認、失敗時の修復経路ルーティング | 入力: PR 番号 / `gh_status` / 出力: 通過 OK→§7.13、失敗→3 分岐ルーティング |
| §7.12.6 内の構造整合性チェック（opt-in） | `bin/check-cycle-phase-completion.sh` 存在時のみ実行、サイクル内構造の整合性検証 | 入力: スクリプト存在判定 / 出力: exit 0=続行、exit 非 0=構造的不整合分岐 |
| §7.13 PR マージ（既存） | マージ実行と内部 CI 状態の最終確認（`error:checks-status-unknown` ハンドリング） | 入力: マージ方法 / 出力: `merged` / `auto-merge-set` / `error:<code>` |
| `reviewing-operations-premerge` スキル（既存 §7.12） | PR 全体の品質・セキュリティ観点レビュー | 入力: PR 差分 / 出力: レビューサマリ |

**観点分担マトリクス**:

| 観点 | §7.12 reviewing-operations-premerge | §7.12.6 マージ前 CI 通過確認 | §7.13 merge-pr |
|------|------------------------------------|----------------------------|---------------|
| PR 差分内容の妥当性 | ○ | - | - |
| セキュリティ最終チェック | ○ | - | - |
| CI ジョブ通過状態 | - | ○（明示確認） | △（merge 直前の最終確認） |
| 構造整合性（サイクル横断） | - | ○（opt-in） | - |
| マージ実行 | - | - | ○ |

#### 論理設計

- **§7.12.6 配置位置の確定**:
  - §7.12.5（PR レビュー反映コミット Squash 統合）と §7.13（PR マージ）の間に新設
  - 理由: Squash 後の HEAD で CI が実行されることを確実にし、Squash 前後の状態混在を防ぐ
  - §7.12.5 が `squash:success` を返した場合の force-push 後に CI を再走させることを §7.12.6 で明示

- **CI 通過確認コマンドの選択**（Round 1 指摘 #2 反映: ブランチ命名依存の緩和）:
  - 第一推奨: `gh pr checks <PR番号>`（PR コンテキストで全 check の状態を取得 / ブランチ命名に依存しない）
  - 補助1: `gh pr view <PR番号> --json statusCheckRollup`（失敗詳細を JSON で取得、PR 番号起点）
  - 補助2: `gh run list --commit <HEAD-SHA> --limit 5`（HEAD SHA 起点 / PR 番号と切り離した取得）
  - フォールバック: `gh run list --branch <cycle-branch> --limit 5`（ブランチ命名が `cycle/{{CYCLE}}` 規約準拠時のみ。命名規約から外れる場合は本フォールバックを使用せず、補助1 または補助2 で対応）
  - **命名不一致時の代替手順**: ブランチ名が `cycle/{{CYCLE}}` と異なる場合、`gh pr view --json headRefName` で実ブランチ名を取得してから `gh run list --branch` に渡すか、PR 番号 / HEAD SHA 起点の取得（第一推奨 / 補助1 / 補助2）に切り替える
  - `--watch` フラグの取り扱い: 進行中の CI 完了を待つ場合に使用。自動化フローでは推奨せず、ユーザー判断で利用

- **opt-in シグナル方式による構造整合性チェック**:
  - 判定: `[ -x bin/check-cycle-phase-completion.sh ]`（存在かつ実行可能）
  - 存在時: スクリプトを実行し exit code で分岐（0=続行、非 0=構造的不整合として 3 分岐の「構造的不整合」へ）
  - 不在時: スキップ（consumer プロジェクト想定 / メッセージ表示なし）
  - 根拠: CLAUDE.md「opt-in シグナル」「starter kit 自身と consumer プロジェクトの両方で同じスクリプトが実行される」「本体側に starter kit リポジトリ判定を埋め込まない」原則

- **CI 失敗時の修復経路 3 分岐ロジック**（設計レビュー Round 1 指摘 #2 反映: 優先順位を **C > B > A** に変更）:

  ```text
  CI 失敗検出
    │
    ├─ 失敗ジョブごとに「分類基準テーブル」で classification_reason を確定
    │  （複数失敗ジョブは各々で分類、最も重い分岐を優先: C > B > A）
    │  ※ C 検出時は B の AskUserQuestion に進まない（構造的不整合を先に収束）
    │
    ├─ C. 構造的不整合（Unit 跨ぎ / 当サイクル内で派生）
    │    → サイクル内修正として §7.12.6 冒頭から再実行
    │      （新規 Issue 起票しない / 振り返りで Try として記録案内）
    │
    ├─ B. 修復不能（環境依存・flaky・インフラ起因 / C 非併存時のみ到達）
    │    → AskUserQuestion（automation_mode に関わらず常時必須）
    │      質問: 「CI 失敗の原因が環境依存と判断されました。
    │             マージブロック解除を承認しますか？」
    │      選択肢: 承認（マージ続行）/ 中断
    │
    └─ A. 修復可能（コード起因・テスト修正で解消）
         → 修正コミット → push → §7.12.6 冒頭から再実行
  ```

- **失敗分類基準テーブル**（Round 1 指摘 #1 反映: 分岐再現性の担保）:

  各失敗ジョブを以下の表で `classification_reason` キー（`reproducible_local` / `flaky_or_env` / `cross_unit_structural`）に正規化する。複数失敗ジョブがある場合は各々で分類し、最も重い分岐を選択する（優先順位: C > B > A、設計レビュー Round 1 指摘 #2 反映）。

  | classification_reason | 再現性 | ログ根拠（例） | 再試行回数上限 | 環境要因判定条件 | 分岐 |
  |----------------------|--------|---------------|---------------|----------------|------|
  | `reproducible_local` | ローカルで再現可能 | テスト失敗 stack trace / lint error / type error | 0（即座に修正） | 該当なし | A. 修復可能 |
  | `flaky_or_env` | 同 SHA で再実行すると pass する / ネットワーク / インフラ起因 | timeout / `connection refused` / `rate limit` / runner エラー | 1（同 SHA で 1 回再実行して pass すれば classification を `reproducible_local` に再評価せず素通し、再失敗で B 確定） | CI 失敗ログに環境系キーワードを含む or 同 SHA リトライで pass する | B. 修復不能 |
  | `cross_unit_structural` | Unit 跨ぎで派生する依存破壊 / SoT 整合性チェック失敗 | `bin/check-cycle-phase-completion.sh` の exit 非 0 出力 / `markdownlint` のサイクル横断違反 | 0（サイクル内で即時修正） | 失敗ジョブが構造整合性検証系である | C. 構造的不整合 |

  **分岐インターフェース契約**: 分岐ロジックの入力は `classification_reason` キー（上記 3 値）の集合、出力は分岐 ID（`A` / `B` / `C`）。複数失敗ジョブから集合を構成し、優先順位 **C > B > A** で最も高位の分岐を選択。判定は AI / ユーザーの協調で実施し、判定根拠（失敗ログの該当抜粋 + 表のどの列にマッチしたか）を `history/operations.md` に記録する（同 SHA リトライ実施時はリトライ回数も併記）。

  **C 検出時のガード**（設計レビュー Round 1 指摘 #2 反映）: `cross_unit_structural` が分類集合に含まれる場合、`flaky_or_env` が併存していても B 分岐の `AskUserQuestion` には進まない。C を先に収束させ、再走後の集合で再判定する（構造的不整合を未解決のままマージブロック解除する経路を構造的に閉じる）。

  **同 SHA リトライ運用ガード**: `flaky_or_env` 仮判定で同 SHA リトライを行う場合は `gh run rerun <run-id>`（または `gh pr checks --watch` 後の再評価）を最大 1 回までとし、リトライ回数が `flaky_or_env` の「再試行回数上限」を超えた場合は B 確定として `AskUserQuestion` に進む。

- **`AskUserQuestion` 必須性の根拠**:
  - 分岐 B（修復不能）はマージブロック解除という破壊的決定を含む
  - SKILL.md「AskUserQuestion 使用ルール」表の「ユーザー選択」種別に該当
  - `automation_mode=semi_auto` / `full_auto` でも自動化対象外

- **既存 §7.13 `error:checks-status-unknown` ハンドリングとの役割分担**（設計レビュー Round 1 指摘 #3 反映: 制御責務を §7.13 に一本化、片方向依存）:
  - §7.12.6: 「CI 状態の取得 + 失敗分類 + 修復経路 A/B/C ルーティング」に責務限定
  - 取得不能時（gh 不在 / API エラー）: §7.12.6 で再試行・ユーザー判断は行わず、`ci_check_state=unknown` を `history/operations.md` に明示記録して終了
  - §7.13: マージ可否の最終判定を一本化（既存 `error:checks-status-unknown` セクションが `reason:checks-query-failed` の `AskUserQuestion` 経路で対応）
  - 依存方向: §7.12.6 → §7.13 の片方向のみ。§7.13 から §7.12.6 へ判断を巻き戻さない（相互参照による責務曖昧化を排除）

#### ドキュメント設計

- `operations-release.md` 改訂内容:
  - §7.12.6 新設（CI 通過確認 + opt-in 構造チェック + 3 分岐修復経路 + 観点分担マトリクス）
  - §7.13 冒頭への 1 行追記（「§7.12.6 で事前確認済みであること」前提を明示。`gh_status != available` 時のスキップ可能性も併記）
  - 既存 §7.12.5 末尾への 1 行追記（次ステップが §7.12.6 である旨）

- `index.md` 改訂内容（Round 1 指摘 #3 反映: 機械判定可能な条件化）:
  - 「§2 分岐ロジック」または該当箇所に §7.12.6 への参照が **未存在の場合は必ず追加** する（grep で `7.12.6` または `マージ前 CI 通過確認` が `steps/operations/index.md` 内にヒットしない場合に追加判定が成立）
  - 既に同等の参照が存在する場合は重複追加しない（grep ヒット時はスキップ）

- 既存記述との整合:
  - §7.13 内の `error:checks-status-unknown` セクション（line 343-368）は変更しない
  - §7.12 内の `reviewing-operations-premerge` 呼び出し記述は変更しない（観点分担は §7.12.6 内で明示）

#### テスト設計

本 Unit はドキュメント変更が主体のため、自動テスト追加は最小化する。

- **markdownlint**: `markdownlint-cli2 skills/aidlc/steps/operations/operations-release.md` で新規エラー 0 件を確認
- **行数チェック**: SKILL.md 本文制限（500 行以内）は SKILL.md に対する制約であり本 Unit は `steps/operations/` のみ変更するため非該当。`operations-release.md` は現状 369 行で、追加分（§7.12.6 で約 60-80 行想定）後でも 500 行以内に収まる見込み
- **既存テスト回帰**: `tests/check-cycle-phase-completion.bats` の動作に変更を与えないこと（呼び出し追加のみのため自然に維持）
- **手動検証**: §7.12.6 の手順を Operations Phase シミュレーションで読み下し、`gh` CLI 不在 / `bin/check-cycle-phase-completion.sh` 不在の各ケースで指示が破綻しないことを確認

### Phase 2: 実装

1. **`operations-release.md` 改訂**:
   - §7.12.6「マージ前 CI 通過確認」サブステップ新設
     - 観点分担マトリクス
     - CI 通過確認コマンド（`gh pr checks` / `gh run list`）
     - opt-in 構造整合性チェック（`[ -x bin/check-cycle-phase-completion.sh ]`）
     - 3 分岐修復経路（修復可能 / 修復不能 / 構造的不整合）
     - `AskUserQuestion` 必須条件と質問雛形
   - §7.12.5 末尾と §7.13 冒頭への小規模追記
2. **`index.md` 改訂**（機械判定条件 / 設計・実装・完了条件で統一）:
   - `grep -E '7\.12\.6|マージ前 CI 通過確認' skills/aidlc/steps/operations/index.md` を実行
   - hit 件数 = 0 の場合: 「§2 分岐ロジック」または該当箇所に §7.12.6 への参照を **必ず追加**
   - hit 件数 ≥ 1 の場合: 重複追加せずスキップ
3. **markdownlint 実行**:
   - `npx markdownlint-cli2 skills/aidlc/steps/operations/operations-release.md` で新規エラー 0 件を確認
4. **回帰確認**:
   - `bats tests/check-cycle-phase-completion.bats` 全 pass を確認
   - SKILL.md の本文行数チェック（変更対象外だが念のため 500 行以内維持を確認）

## 完了条件チェックリスト

### #694 受け入れ基準

- [x] `steps/operations/operations-release.md` に「マージ前 CI 通過確認」サブステップが新設されている（§7.12.6 として §7.12.5 と §7.13 の間に配置）
- [x] CI 通過確認コマンドが **PR 番号 / HEAD SHA 起点を第一**（`gh pr checks <PR>` / `gh pr view --json statusCheckRollup` / `gh run list --commit <HEAD-SHA>`）として明文化されており、`gh run list --branch <branch>` は命名規約準拠時のフォールバック扱いとして記載されている
- [x] CI 失敗時の修復経路が 3 分岐で SoT 化されている（修復可能 / 修復不能 / 構造的不整合）
- [x] 「修復不能」分岐で `AskUserQuestion` 必須が明示されている（`automation_mode` に関わらず）
- [x] 「構造的不整合」分岐で新規 Issue 起票しない旨が明示されている
- [x] `bin/check-cycle-phase-completion.sh` の opt-in シグナル方式（存在時のみ実行）が明示されている
- [x] `reviewing-operations-premerge` スキルとの観点分担マトリクスが §7.12.6 内に記載されている
- [x] 既存 §7.13 `error:checks-status-unknown` ハンドリングとの役割分担が明示されている
- [x] 失敗分類基準テーブル（`reproducible_local` / `flaky_or_env` / `cross_unit_structural` の 3 値）が §7.12.6 内に記載されている（Round 1 指摘 #1 反映）
- [x] CI 確認コマンドが PR 番号 / HEAD SHA 起点を第一とし、ブランチ命名依存はフォールバックに格下げされている（Round 1 指摘 #2 反映）
- [x] `steps/operations/index.md` に §7.12.6 への参照が grep で確認できる（未存在時は追加、Round 1 指摘 #3 反映）

### 共通

- [x] `operations-release.md` の markdownlint で新規エラー 0 件
- [x] `tests/check-cycle-phase-completion.bats` 全 pass（回帰なし）
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い実施されている
- [x] CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」「コマンド置換禁止」「printf -v 系 result-out 関数の local 命名規約」「codex exec の stdin 待ちガード」規約に違反しない

## リスク・考慮事項

- **§7.12.6 と §7.13 内 CI チェックの役割重複懸念**: §7.13 の `error:checks-status-unknown` ハンドリングは「マージスクリプト実行時の最終フィルタ」、§7.12.6 は「事前の明示確認 + 修復ループ」と役割分離する。両者を併存させて多層防御とする方針を §7.12.6 冒頭に明示
- **`bin/check-cycle-phase-completion.sh` の consumer 配布有無**: 本スクリプトは starter kit リポジトリ内の `bin/` 配下に存在し、consumer プロジェクトには通常配布されない。opt-in シグナル方式（`[ -x ...]`）により consumer 側で自然にスキップされる設計。CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」「opt-in シグナル」原則準拠
- **`AskUserQuestion` の使い分け**: 「修復不能」分岐は破壊的決定（マージブロック解除）を含むため `automation_mode` に関わらず必須。「修復可能」「構造的不整合」分岐はループ再実行であり対話不要（ただし AI / ユーザーが分類判断を共有する形でフローを進める）
- **既存記述との整合**: §7.12.5（Squash）→ §7.12.6（CI 確認）→ §7.13（マージ）の順序が崩れないよう、§7.12.5 末尾 / §7.13 冒頭への小規模追記で順序を明示する
- **全作業で Bash ツール経由のコマンド置換（`$(...)` / backtick）を引数文字列に含めない**（CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」/ Unit 001 SoT 準拠）
- **codex exec の stdin 待ちガード**: AI レビュー実行時は `</dev/null` または stdin リダイレクト経由で呼び出す（CLAUDE.md「codex exec の stdin 待ちガード」規約準拠）
