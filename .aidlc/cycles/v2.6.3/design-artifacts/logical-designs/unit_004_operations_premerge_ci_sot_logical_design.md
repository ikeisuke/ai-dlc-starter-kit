# 論理設計: Unit 004 / Operations Phase マージ前 CI 通過確認フロー SoT 化

## 概要

ドメインモデル（`unit_004_operations_premerge_ci_sot_domain_model.md`）で定義した責務を `skills/aidlc/steps/operations/operations-release.md` 上の新規サブステップ §7.12.6 として配置する論理設計を定義する。具体的な markdown 記述は Phase 2（実装）で書く。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成・インターフェース・配置位置の定義のみを行う。

## アーキテクチャパターン

- **SoT（Single Source of Truth）ドキュメント設計パターン**: 1 つのフローの正本記述を 1 箇所に集約し、横断ルール（`reviewing-operations-premerge`）からの参照は観点分担マトリクスで明示する
- **opt-in シグナル方式**: 環境差（starter kit リポジトリ vs consumer プロジェクト）を本体側で判定せず、必要ファイルの存在を opt-in シグナルとして扱う（CLAUDE.md 規約）
- **多層防御パターン**: §7.12.6（事前確認 + 修復ループ）と §7.13（マージ時最終フィルタ）を併存させて事故防止する

採用理由:

- 1 サイクル横断で属人化していた CI 修復経路を SoT として固定し、再現性を確保するため
- consumer プロジェクトに配布した際に「starter kit 特有のチェック」が誤動作しないようにするため
- 既存 §7.13 内 CI チェックを破壊せず、より早いタイミングで明示確認を挟むため

## コンポーネント構成

### ステップファイル構成

```text
skills/aidlc/steps/operations/operations-release.md
├── §7.1 バージョン確認（既存）
├── ...
├── §7.12 PR マージ前レビュー（既存 / reviewing-operations-premerge 呼び出し）
├── §7.12.5 PR レビュー反映コミット Squash 統合（既存）
│    └── 末尾: §7.12.6 への接続行を追加（次ステップ明示）
├── §7.12.6 マージ前 CI 通過確認【新設 / 本 Unit】
│    ├── 観点分担マトリクス（reviewing-operations-premerge / §7.13 との重複・補完）
│    ├── CI 通過確認コマンド（PR 番号 / HEAD SHA 起点を第一）
│    ├── opt-in 構造整合性チェック（bin/check-cycle-phase-completion.sh 存在時のみ）
│    ├── 失敗分類基準テーブル（3 値正規化）
│    ├── 3 分岐修復経路（A: 修復可能 / B: 修復不能 / C: 構造的不整合）
│    └── AskUserQuestion 雛形（B 分岐 / automation_mode 不問）
└── §7.13 PR マージ（既存）
     └── 冒頭: §7.12.6 で事前確認済みである前提を明示する 1 行を追加

skills/aidlc/steps/operations/index.md（必要時のみ更新）
└── §2 分岐ロジック内に §7.12.6 への参照を追加（grep で未存在時のみ）
```

### コンポーネント詳細

#### §7.12.6 マージ前 CI 通過確認（新設サブセクション）

- **責務**: PR の全 CI ジョブ通過確認 + 失敗時の修復経路ルーティング
- **依存**: `gh` CLI（`pr checks` / `pr view --json statusCheckRollup` / `run list`）、`bin/check-cycle-phase-completion.sh`（opt-in）、`AskUserQuestion`（B 分岐のみ）
- **公開インターフェース**（ドキュメント記述の公開構造）:
  - 観点分担マトリクスの表
  - CI 通過確認コマンド一覧（第一推奨 → 補助1 → 補助2 → フォールバック → 命名不一致時の代替手順）
  - 失敗分類基準テーブル（5 列構造）
  - 3 分岐修復経路の擬似フロー図
  - `AskUserQuestion` 質問文・選択肢雛形

#### §7.12.5 末尾追記（既存ファイル小規模変更）

- **責務**: §7.12.6 への接続を明示
- **追加文言**: 1 行（squash 後 force-push 完了後に §7.12.6 で CI 再走確認に進む旨）

#### §7.13 冒頭追記（既存ファイル小規模変更）

- **責務**: §7.12.6 で事前確認済みである前提を明示し、`gh_status != available` 時のスキップ可能性に言及
- **追加文言**: 2-3 行程度

#### `index.md` 反映（条件付き）

- **責務**: フェーズインデックスから §7.12.6 への参照可能性
- **判定**: `grep -E '7\.12\.6|マージ前 CI 通過確認' skills/aidlc/steps/operations/index.md` の hit 件数 = 0 のときのみ追加

## インターフェース設計

### ドキュメント側（§7.12.6）の公開構造

#### 観点分担マトリクス（表構造）

| 列名 | 内容 |
|------|------|
| 観点 | PR 差分内容の妥当性 / セキュリティ最終チェック / CI ジョブ通過状態 / 構造整合性（サイクル横断） / マージ実行 |
| §7.12 reviewing-operations-premerge | ○ / - 記号 |
| §7.12.6 マージ前 CI 通過確認 | ○ / - / △ 記号 |
| §7.13 merge-pr | ○ / - / △ 記号 |

#### CI 通過確認コマンド（順序付きリスト）

1. 第一推奨: `gh pr checks <PR番号>`
2. 補助1: `gh pr view <PR番号> --json statusCheckRollup`
3. 補助2: `gh run list --commit <HEAD-SHA> --limit 5`
4. フォールバック: `gh run list --branch <cycle-branch> --limit 5`（命名規約準拠時のみ）
5. 命名不一致時: `gh pr view --json headRefName` で実ブランチ名取得 → 補助2 に切替

#### 失敗分類基準テーブル（5 列構造）

| 列名 | 値ドメイン |
|------|----------|
| classification_reason | `reproducible_local` / `flaky_or_env` / `cross_unit_structural` |
| 再現性 | 自然言語の説明 |
| ログ根拠（例） | キーワード列挙 |
| 再試行回数上限 | 整数（0 / 1） |
| 環境要因判定条件 | 自然言語の説明 |
| 分岐 | `A` / `B` / `C` |

#### 3 分岐修復経路（擬似フロー）

ASCII アート図で 3 分岐を表現。優先順位 **`C > B > A`**（Round 1 指摘 #2 反映: 構造的不整合を環境要因より先に収束させる）を明示。C 検出時は B の `AskUserQuestion` に進まないガードも図中で明示。

#### AskUserQuestion 雛形（B 分岐）

```text
question: 「CI 失敗の原因が環境依存と判断されました。マージブロック解除を承認しますか？」
header: 「CI修復」
options:
  - 承認（マージ続行）
  - 中断（ユーザー判断で次のアクション決定）
```

## スクリプトインターフェース設計

本 Unit では新規スクリプトを作成しない。既存 `gh` CLI と `bin/check-cycle-phase-completion.sh` の呼び出しのみを記述する。

### 呼び出し記法（ドキュメント内）

| コマンド | 引数 | 終了コード解釈 |
|---------|------|--------------|
| `gh pr checks <PR>` | PR 番号 | exit 0 = 全 pass / exit 非 0 = 失敗あり |
| `gh pr view <PR> --json statusCheckRollup` | PR 番号 | JSON 出力を `failed_jobs` 構成に利用 |
| `gh run list --commit <SHA> --limit 5` | HEAD SHA | 直近 5 run の状態取得 |
| `gh run list --branch <BR> --limit 5` | ブランチ名 | 命名規約準拠時のフォールバック |
| `[ -x bin/check-cycle-phase-completion.sh ]` | パス | 存在 + 実行可能で true |
| `bin/check-cycle-phase-completion.sh` | （引数は本 Unit のスコープ外） | exit 0 = 続行 / exit 非 0 = 構造的不整合（C 分岐） |

## エラーハンドリング設計

### CI 通過確認時のエラー（Round 1 指摘 #3 反映: 制御責務を §7.13 に一本化）

| 状況 | §7.12.6 の動作 | 後続処理 |
|------|--------------|---------|
| `gh_status != available` | スキップ + `ci_check_state=unknown` を `history/operations.md` に明示記録して終了 | §7.13 が最終判定を担う（最終防衛線） |
| `gh pr checks` の API エラー | `ci_check_state=unknown` を明示記録して終了（§7.12.6 内で再試行・ユーザー判断は行わない） | §7.13 既存の `error:checks-status-unknown` ハンドリング（`reason:checks-query-failed` の `AskUserQuestion`）が一本化された制御権限で対応 |
| PR 番号不明 | 補助2（HEAD SHA 起点）に切替して取得継続 | 取得成功時は通常フローへ |
| ブランチ命名規約から外れる | 補助2 に切替（`--branch` フォールバック使用禁止） | 取得成功時は通常フローへ |

**責務境界の片方向化規約**（Round 1 指摘 #3 反映）:

- §7.12.6 の責務は「CI 状態の取得 + 失敗分類 + 修復経路 A/B/C のルーティング」に限定
- 取得不能（gh 不在 / API エラー）は §7.12.6 で **最終判定しない**。`ci_check_state=unknown` の明示記録で終了し、最終的な「マージ可否判定」は §7.13 が `error:checks-status-unknown` セクションで一本化
- これにより §7.12.6 → §7.13 の制御フローは **片方向**（§7.13 から §7.12.6 に判断を巻き戻さない）となり、相互参照による責務曖昧化を排除

### 失敗分類時のエラー

| 状況 | 対応 |
|------|------|
| ログ根拠が表のどのキーワードにも該当しない | デフォルトで `reproducible_local`（A 分岐）に倒し、ユーザー判断を仰ぐ機会を担保（最も保守的な分類） |
| 同 SHA リトライ後も `flaky_or_env` のまま | B 確定で `AskUserQuestion` |
| `cross_unit_structural` 判定の根拠ログが不明確 | `bin/check-cycle-phase-completion.sh` 不在環境では C 分岐を発火させず A/B のみで判定 |

## ファイル / セクション間の依存関係図

```text
operations-release.md §7.12.6 (新設)
  ├─ 参照: CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」（opt-in シグナル方式）
  ├─ 参照: SKILL.md「AskUserQuestion 使用ルール」（B 分岐の必須性根拠）
  ├─ 参照: §7.12 reviewing-operations-premerge（観点分担マトリクス）
  ├─ 委譲: gh CLI（CI 状態取得）
  └─ 委譲: bin/check-cycle-phase-completion.sh（opt-in 構造チェック）

operations-release.md §7.12.5 末尾
  └─ 接続: §7.12.6（次ステップ明示）

operations-release.md §7.13 冒頭
  └─ 前提参照: §7.12.6（事前確認済みであること）
  └─ 最終判定権: 取得不能ケース（§7.12.6 が `ci_check_state=unknown` で終了した場合）の
     マージ可否を一本化（既存 error:checks-status-unknown セクション）

依存方向の片方向化（Round 1 指摘 #3 反映）:
  §7.12.6 → §7.13（一方向のみ）
  §7.13 から §7.12.6 への巻き戻し依存は持たない

index.md §2 分岐ロジック（条件付き）
  └─ 参照追加: §7.12.6（grep 未ヒット時のみ）
```

## テスト戦略

ドキュメント変更が主体のため自動テストは追加せず、以下を確認する:

| 検証項目 | 検証手段 |
|---------|---------|
| markdownlint 新規エラー 0 件 | `npx markdownlint-cli2 skills/aidlc/steps/operations/operations-release.md` |
| 既存 bats 回帰なし | `bats tests/check-cycle-phase-completion.bats`（呼び出し追加のみのため自然に維持） |
| §7.12.6 の手順読み下し（gh CLI 不在ケース） | 手動で gh CLI 不在を仮定して文書を読み、指示が破綻しないか確認 |
| §7.12.6 の手順読み下し（bin/check-cycle-phase-completion.sh 不在ケース） | 手動で opt-in シグナル不在を仮定して文書を読み、自然にスキップされるか確認 |
| `index.md` 反映の機械判定 | 下記コードブロックの `grep` コマンドを `skills/aidlc/steps/operations/index.md` に対して実行し hit 件数で判定 |

`index.md` 反映の機械判定用コマンド（テーブルセル内 `|` 衝突回避のためコードブロックに退避）:

```bash
grep -E '7\.12\.6|マージ前 CI 通過確認' skills/aidlc/steps/operations/index.md
```

## 設計判断記録

- **§7.12.6 の位置選択（§7.12.5 と §7.13 の間）**: Squash 後の HEAD で CI を再走させてからマージに進む順序を担保。§7.12 / §7.12.5 / §7.13 の既存ナンバリングに割り込む形で §7.12.6 を採用し、既存セクションの番号変更を避ける（後方互換）
- **失敗分類の 3 値正規化**: 2 値（修復可能 / 不能）では「サイクル内構造的不整合」を表現できないため 3 値に分割。再現性 / ログ根拠 / 再試行回数 / 環境要因判定の 4 軸で機械的に分類可能とする
- **opt-in シグナルでの構造チェック発火**: starter kit 自身が consumer プロジェクトと同じスクリプトを実行するドッグフーディング前提を維持しつつ、`bin/check-cycle-phase-completion.sh` の存在を opt-in シグナルとして扱うことで「自リポジトリ判定の本体埋め込み」を避ける（CLAUDE.md 規約準拠）
- **AskUserQuestion を B 分岐のみで必須化**: A / C はループ再実行（破壊的決定なし）、B はマージブロック解除（破壊的）。SKILL.md「AskUserQuestion 使用ルール」表の「ユーザー選択」種別に該当するため `automation_mode` 不問で必須
- **§7.13 既存 CI チェックの保持**: §7.12.6 は事前確認、§7.13 はマージスクリプト実行時の最終フィルタ。多層防御で事故防止する設計とし、`error:checks-status-unknown` セクション（line 343-368）は変更しない
