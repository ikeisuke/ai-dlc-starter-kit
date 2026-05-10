# ユーザーストーリー

## Epic: v2.6.1 patch リリース - v2.6.0 安定化

v2.6.0 リリース後に検出された 5 件のクリティカル / UX / 設計原則 / CI ノイズ問題を一括で解消し、v2.6 系の安定運用を実現する。

---

## DoD（Epic 共通の運用チェックリスト）

各ストーリーの受け入れ基準（AC）は振る舞い・出力・ログ・テストで定義する。以下の運用観点は AC ではなく Epic 共通の DoD（Definition of Done）として扱い、Operations Phase の完了処理で確認する:

- 関連 Issue（#688 / #686 / #690 / #689 / #687）が PR マージ後に close されること
- v2.6.1 Milestone に上記 5 Issue がすべて紐付いていること
- CHANGELOG.md に v2.6.1 セクションが追加され、全 5 ストーリーの変更が patch 扱いで記載されていること
- Repository Settings > Branch protection / Ruleset の現行 required check 一覧（`.aidlc/cycles/v2.6.1/operations/required-checks.md` スナップショット）が CI で全件 green であること

## リリース系タスクの責務分担（Construction / Operations 境界の明示）

Intent「含まれるもの」のうち Issue 直結タスクは Unit 001〜005 で担当する。一方、以下のリリース系タスクは **個別 Unit ではなく Operations Phase で実施する** Epic 共通タスクとして扱い、Unit 群のスコープ漏れではないことを明示する:

| リリース系タスク | 担当フェーズ | 担当ステップ |
|----------------|-----------|------------|
| `bin/update-version.sh --version v2.6.1` 実行（version 更新） | Operations Phase | リリース準備 §7.1 後 |
| CHANGELOG.md v2.6.1 セクション追記 | Operations Phase | リリース準備 §7.2 |
| Milestone v2.6.1 作成・Issue 紐付け（早期紐付けは Inception §16 で試行済み） | Operations Phase | 完了処理 |
| draft PR 作成・PR レビュー反映・マージ | Operations Phase | リリース準備〜完了処理 |
| Branch protection / Ruleset 現行 required check 一覧スナップショット（`operations/required-checks.md`） | Operations Phase | デプロイ準備 §7 序盤 |
| post-merge-sync（main 同期 + マージ済みブランチ削除） | Operations Phase | ポストマージクリーンアップ |

これらは AI-DLC の Operations Phase 標準フローでカバーされるため、各 Unit に「Operations で実施」と再掲しなくても管理上の漏れは生じない。本テーブルは AI レビュー指摘（Round 1 #4: 受け皿不明確）への明示的回答として保持する。

---

### ストーリー 1: zsh 環境での `/aidlc v` OOM クラッシュ回避

**優先順位**: Must-have

As a Claude Code（macOS / zsh）を利用する AI-DLC Starter Kit 利用者
I want to `/aidlc v`（バージョン取得操作）が Bash ツール経由で常に正常終了する
So that バージョン確認時に zsh `command_not_found_handler` 無限再帰による OOM クラッシュで作業が中断されない

**受け入れ基準（正常系）**:

- [ ] zsh + Claude Code Bash ツール経由で AI-DLC スキルが提供する version 取得操作を実行した際に、OOM クラッシュが発生せず正常終了する（exit 0）かつ、stdout に `marketplace.json.metadata.version` の値が `v` プレフィックスなしで出力される
- [ ] `scripts/lib/version.sh` を `bash <path> <json_path>` 形式（CLI モード）または `bash -c "source <path>; read_marketplace_version <json_path>"` 形式で呼び出した際に、正しいバージョン文字列が stdout に出力される
- [ ] SKILL.md の version アクション記述が、AI エージェント向けに「使用すべき呼び出し経路」と「使用すべきでない経路（zsh 対話シェルからの `source`）」を曖昧さなく区別している
- [ ] 既存の `marketplace.json.metadata.version` を SoT とする version 取得契約（出力フォーマット・終了コード規約）が変更されない（後方互換）

**受け入れ基準（異常系）**:

- [ ] `marketplace.json` が存在しない場合、stderr に `metadata-version-missing-or-empty` 等の明示的エラーメッセージを出力し、exit code 非 0 で終了する（既存挙動維持）
- [ ] `marketplace.json` の `metadata.version` キーが空または不正な場合、stderr に明示的エラーメッセージを出力し、exit code 非 0 で終了する（既存挙動維持）
- [ ] dasel / jq の双方が不在で抽出不能な場合、stderr に明示的エラーメッセージを出力し、exit code 非 0 で終了する（既存挙動維持）

**受け入れ基準（テスト）**:

- [ ] bats テストで「`bash scripts/lib/version.sh <path>` を呼び出して期待値が返る」「正常 / 異常系の終了コードと stderr 出力」を検証する

**技術的考慮事項**:

- Issue #688 で 3 案提示（SKILL.md 改訂 / 薄いラッパー CLI / `version.sh` への CLI モード追加）。Construction Phase の設計レビューで採用案を確定する
- Unit 007（v2.6.0）の `squash-unit.sh` で採用された `if [[ "${BASH_SOURCE[0]}" == "$0" ]]` パターンとの整合性を維持する

---

### ストーリー 2: `cycle/*` の draft PR で Cycle Phase Completion Check を skip

**優先順位**: Must-have

As a AI-DLC Starter Kit のメタ開発者
I want to `cycle/*` ブランチの draft PR では Cycle Phase Completion Check ジョブが skipped 表示になる
So that Construction 中の中間 push で CI が不要に fail せず、レビューや merge ready の判断ノイズが減る

**受け入れ基準（正常系）**:

- [ ] `cycle/*` ブランチの draft PR を開いた状態で `synchronize` イベントが発火しても、Cycle Phase Completion Check ジョブは GitHub UI 上で skipped 表示になる
- [ ] 同 PR を `ready_for_review` に切替えると、Cycle Phase Completion Check ジョブが通常通り実行される
- [ ] `main` 向け非 draft PR（cycle 以外も含む）の Cycle Phase Completion Check ジョブの実行可否が現行と変わらない（既存挙動維持）
- [ ] Repository Ruleset で当 check を required にしているユーザー向けの互換挙動が `docs/cycle-phase-completion-check-ruleset.md`（存在する場合）または CHANGELOG で案内されている

**受け入れ基準（異常系）**:

- [ ] draft PR を `ready_for_review` → `convert_to_draft` の往復で切替えても、ジョブが各状態で正しく skipped / 実行に切り替わる（イベント取りこぼしなし）

**技術的考慮事項**:

- Issue #686 推奨案 A（job 条件 `if: startsWith(github.head_ref, 'cycle/') && github.event.pull_request.draft == false`）を Construction で採用候補として検討する（実装手段の確定は設計レビュー）

---

### ストーリー 3: `aidlc-feedback` のブラウザ強制起動を解消

**優先順位**: Must-have

As a AI-DLC Starter Kit を利用してフィードバックを送る利用者・AI エージェント
I want to `/aidlc feedback` 実行時にブラウザが自動起動せず、必要時のみ opt-in でブラウザ経路を選べる
So that 複数件のフィードバックを連続で起票したり AI エージェントが auto mode で一括起票する際に UX 摩擦が発生しない

**受け入れ基準（正常系）**:

- [ ] `/aidlc feedback` のデフォルト経路が直接起票（ブラウザ非起動）に変更され、ブラウザが自動起動しない
- [ ] `[rules.feedback].open_in_browser`（または等価）の設定値、明示フラグ、TTY 状態の組合せに対する経路選択が下記「優先順位真理値表」に従って一意に決まる
- [ ] 起票内容のユーザー承認フロー（feedback.md 手順 1 のヒアリング）が引き続き機能する（事前確認なしの直接起票はしない）
- [ ] `skills/aidlc-feedback/steps/feedback.md` および関連 SKILL.md / CHANGELOG に変更内容と opt-in 手順、優先順位真理値表が記載されている

**優先順位真理値表（設定 / フラグ / TTY → 経路）**:

| 設定 `open_in_browser` | 明示フラグ `--web` 指定 | TTY 状態 | 採用経路 |
|----------------------|---------------------|---------|---------|
| `true`（または等価） | -                   | TTY     | `--web`（ブラウザ） |
| `true`               | -                   | 非 TTY  | 直接起票（**TTY 優先 over 設定**: 非 TTY では `--web` を強制無効化、警告ログを stderr に出力） |
| `false` / 未設定     | あり                | TTY     | `--web`（ブラウザ） |
| `false` / 未設定     | あり                | 非 TTY  | 直接起票（同上、警告ログ出力） |
| `false` / 未設定     | なし                | TTY     | 直接起票（デフォルト） |
| `false` / 未設定     | なし                | 非 TTY  | 直接起票（デフォルト） |

優先順位の文言定義: **「TTY 状態 > 設定 > フラグ」** （非 TTY では常に直接起票、TTY では設定が `true` ならブラウザ、設定が `false`/未設定なら明示フラグでブラウザ、それも無ければ直接起票）

**受け入れ基準（異常系）**:

- [ ] 設定値が型不一致（数値・配列等）または不正値の場合、警告ログを stderr に出力したうえで「未設定」相当（直接起票）にフォールバックする
- [ ] `gh issue create` が失敗した場合、stderr にエラー内容（コマンドと exit code）を出力し非 0 終了する。既存の対話再試行フローがあれば維持
- [ ] `.aidlc/config.toml` 自体が壊れている場合、設定読取ステップが警告 + デフォルト挙動継続で進む（既存 `read-config.sh` の挙動準拠）

**受け入れ基準（テスト）**:

- [ ] 上記真理値表の全 6 行を bats / シェルテストで網羅検証する

**技術的考慮事項**:

- 非 TTY 判定は `[[ -t 0 ]]` 等の bash 標準機能で実装
- 設定読取手段は本ストーリー単独では制約しない（`read-config.sh` 経由統一はストーリー 4 の規約で扱う）

---

### ストーリー 4: dasel 直接呼び出しの `read-config.sh` 経由統一

**優先順位**: Should-have

As a AI-DLC Starter Kit 上で動作する AI エージェント
I want to `.aidlc/config.toml` の読取が常に `read-config.sh` 経由で行われ、`dasel` の不正フラグ（`-f` 等）を誤生成しない
So that AI エージェントによる規約逸脱（dasel CLI v3 の `unknown flag` エラー、ひいては feedback 機能停止）が再発しない

**受け入れ基準（正常系）**:

- [ ] `skills/aidlc-feedback/steps/feedback.md` 等のスキル内手順書から、dasel 直接呼び出し（`cat ... | dasel ...` を含む）が排除され、設定読取は `scripts/read-config.sh` 経由に統一されている（ファイル単位での grep が 0 件）
- [ ] `steps/common/rules-core.md` に「設定読取は `read-config.sh` を主経路として使う」「dasel を直接使う場合の許容形式（`cat file | dasel -i toml '<key>'` / `dasel -i toml '<key>' < file`）」が明文化されている
- [ ] 同じく `rules-core.md` に「禁止呼び出しパターン」セクションが新設され、AI エージェントが誤生成しがちな anti-pattern が列挙されている

**受け入れ基準（異常系）**:

- [ ] `read-config.sh` のキー不在（exit 1）/ 致命エラー（exit 2）時の挙動規定が `rules-core.md` で再確認できるように案内されている（既存挙動を変更しないことを明示）
- [ ] `aidlc-feedback` の機能テスト（既存 bats）が引き続き green であり、規約改訂後も振る舞い変化がない

**受け入れ基準（テスト）**:

- [ ] スキル内手順書からの dasel 直接呼び出し排除を以下の 2 系統で検証する:
  1. **不正フラグ検出**: `grep -RnE "dasel\s+-f\b" skills/` が 0 件
  2. **直接呼び出し検出**: `grep -RnE "(\| ?dasel\b|\bdasel\b)" skills/` で抽出した行のうち、許容パターン（`scripts/lib/version.sh` 等の lib 内部実装、`docs/` 配下の解説、ドキュメント末尾の許容形式説明など、本サイクルで明示的に許容するパス）以外が 0 件
- [ ] 上記 2 系統の検出を bats テストまたは shellcheck/grep ベースの軽量チェックスクリプトで CI に組み込み、リグレッション防止する
- [ ] `aidlc-feedback` の機能テスト（既存 bats）が引き続き green であり、規約改訂後も振る舞い変化がない（再掲）

**技術的考慮事項**:

- 規約改訂の対象範囲は `aidlc-feedback` を起点とし、他スキルへの波及は Construction 計画レビューで確定
- `rules-core.md` の追記位置は既存の「## コマンド実行ルール」と整合する位置に配置

---

### ストーリー 5: `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

**優先順位**: Should-have

As a AI-DLC Starter Kit のメタ開発者および consumer プロジェクト開発者
I want to `squash-unit.sh` の CI 構造チェックスクリプトの一覧が `.aidlc/config.toml` で設定駆動になる
So that starter kit 固有のチェックスクリプト名・パスが本体スクリプトにハードコードされず、consumer プロジェクトが独自チェックを追加・無効化できる

**受け入れ基準（正常系: 設定駆動）**:

- [ ] `.aidlc/config.toml` に `[rules.squash.internal_ci_checks].scripts`（または等価）設定キーが追加され、デフォルト値として既存 3 種（`bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`）が starter kit リポジトリで指定されている
- [ ] `skills/aidlc/scripts/squash-unit.sh` 本体は CI チェックスクリプト名・パスをハードコードせず、設定リストを読んで動作する（`grep -E "check-(skill-references|bash-substitution|test-isolation)" skills/aidlc/scripts/squash-unit.sh` が 0 件）

**受け入れ基準（後方互換）**:

- [ ] 設定キー不在 / セクション不在の場合に、starter kit デフォルトの 3 種が fallback として読み込まれ、v2.6.0 Unit 007 と同一の挙動になる（既存 bats テストが green）

**受け入れ基準（異常系）**:

- [ ] 設定値が型不一致（文字列・数値等）の場合、警告ログを stderr に出力したうえで fallback default（既存 3 種）にフォールバックする
- [ ] 設定 `scripts` 配列が空 `[]` の場合、集約 skip ログ（`internal-ci-checks:skip:reason=empty-config` 等）を出力し、CI チェックを実行せず exit 0 で続行する
- [ ] 設定リスト内の個別スクリプトがリポジトリに不在の場合、当該スクリプトのみ個別 skip（既存 opt-in シグナル方式の挙動と互換）し、他のスクリプトは実行される
- [ ] スクリプトパスがリポジトリルート外（絶対パス・上位 traversal）を指定する場合、設定検証で reject し警告ログを出力する

**受け入れ基準（consumer 互換）**:

- [ ] consumer プロジェクト想定（設定不在 + `bin/` 配下に対応スクリプト不在）で、CI チェック全体が opt-in シグナル方式で skip される（v2.6.0 Unit 007 の consumer 挙動と互換）

**受け入れ基準（テスト）**:

- [ ] bats テストで以下 6 ケース（設定駆動 / fallback / 異常設定 / 空配列 / 部分不在 / consumer 不在）を網羅検証する

**Small/Estimable 補足**:

- 本ストーリーは設定キー導入が中核で、ロジック変更は `run_internal_ci_checks_or_skip()` の単一関数に閉じる。AC は段階的に「設定駆動 → fallback → 異常系 → consumer 互換 → テスト」の 5 ブロックで構造化されており、Construction では同順で段階的に実装可能（PR としては 1 Unit 完結、内部レビューで段階的にチェック）

**「ハードコード禁止」と「fallback default」の境界（解釈衝突回避）**:

- **「ハードコード禁止」の範囲**: `skills/aidlc/scripts/squash-unit.sh` の制御フロー本体（`run_internal_ci_checks_or_skip()` のループ内・条件分岐内）に CI チェックスクリプトのファイル名・パスをリテラル文字列で書かないこと。本ストーリーの正常系 AC「`grep -E "check-(skill-references|bash-substitution|test-isolation)" skills/aidlc/scripts/squash-unit.sh` が 0 件」はこの本体ファイルに対する制約として定義する
- **fallback default の許容配置**: 設定キー不在時のデフォルト 3 種（`bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`）は、以下のいずれかに集約して保持してよい:
  - `.aidlc/config.toml`（または `defaults.toml` / 等価）の規定値として宣言
  - `skills/aidlc/scripts/lib/squash-defaults.sh`（または等価）の共通定数として保持し、`squash-unit.sh` 本体はこの lib を参照するのみ
- **採用判断**: 上記 2 案のうちどちらを採るかは Construction 設計レビューで確定する。本ストーリー時点では「`squash-unit.sh` 本体直書き禁止」「fallback 配置先は設定ファイルまたは共通定数 lib」の 2 制約のみ拘束する

**技術的考慮事項**:

- 後方互換最優先（patch リリース）。既存 3 種が動作不変であることを最優先で検証
- Issue #691（v2.7.0 へ送り）の「汎用 CI チェックをスキル本体に取り込む設計検討」と整合する設計選択肢を残す（本サイクルでは設定キー導入のみに留め、スキル本体取り込みは v2.7.0 で再検討）
- 設定読取手段は本ストーリー単独では制約しない（`read-config.sh` 経由統一はストーリー 4 の規約に従う）
