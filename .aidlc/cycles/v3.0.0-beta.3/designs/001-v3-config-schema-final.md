# Design 001: v3 config.toml キー終端設計（SoT ギャップ解消）

- trace: work item 001-v3-config-schema-final
- matrix_case: normal_standard
- design_mode: simple

## Goal

RFC §6.4 と data-model.md §8 が相互委譲して未確定のままになっている v3 config.toml の終端キー集合を確定文書 1 箇所に記載し、migration.md §8 の SoT ギャップ注記を解消する。あわせて work item 002 のフォールバック opt-in の発動形態を判断・記録し、002（release hard gate フォールバック）と 003（migration の config 変換先 schema）の前提を確立する。

## Context

- **SoT ギャップの現状**: RFC §6.4 は「v3 設定キーの確定値は data-model.md の defaults.toml 設計で確定」と委譲し、data-model.md §8 注記は「config.toml キー全体の終端設計は本書のスコープ外（RFC §6 で別途確定予定）」と差し戻している。migration.md §8 はこの循環を既知の SoT ギャップとして注記し、config 変換規則の具体化を保留している。
- **v2 ベースライン**: `skills/aidlc/config/defaults.toml` は 34 キー（RFC §6.1 測定定義 / §6.2 で確認済み）。RFC §6.4 は終端値の揺れ（8 か 12 か）を認識しつつ方向性として ~8 を採用している。
- **v3 skeleton が現に読むキー**: `rules.depth_level.level`（develop Step 1 / doctor）、`rules.automation.mode`（develop 2.2 / release Step 3 の承認ゲート）、`rules.reviewing.mode` / `rules.reviewing.tools`（develop Step 5 / release premerge の review routing）、`rules.release.changelog` / `rules.release.version_tag`（release 4-3 の opt-in 実行）。加えて委譲先の共有資産 `review-routing.md` が `rules.reviewing.exclude_patterns`（機密除外）を参照する。
- **制約**: config ローダー実装の変更はスコープ外（work item 001 Scope）。v3 skeleton は v2 の `read-config.sh` を共用しており、キーパスを変えるとローダー・steps 双方の変更が必要になる。

## Design

### D1: 確定文書の配置 = data-model.md 新 §11「config.toml schema」

終端キー集合（キー名 / 型 / 既定値 / 用途）は **`docs/v3/data-model.md` に新 §11 として追加**し、これを唯一の正本とする。

- 理由: RFC §6.4 自身が data-model.md への委譲を宣言済みであり、schema 系 SoT（state.json / frontmatter / journal）は data-model.md に集約されている。RFC は Decision Gate Log / 方向性文書であり schema 定義を持たない。
- 末尾追加（§11）とし、既存 §1〜§10 の番号を変えない。§1 の節一覧に §11 を追記する。
- 参照の張り替え（循環解消）:
  - RFC §6.4: 「data-model.md で確定」→「data-model.md §11 で確定済み（終端値 8）」に更新
  - data-model.md §8 注記: 「スコープ外（RFC §6 で別途確定予定）」→「§11 で確定」に置換
  - migration.md §8: SoT ギャップ注記を解消し data-model.md §11 への確定参照に置換。§3 config 行の「（終端 schema 未確定 / §8）」→「data-model.md §11」
  - 参照方向は RFC → data-model §11 ← migration の一方向となり循環しない

### D2: キーパス命名 = v2 互換の `[rules.<domain>]` 階層を維持

キーのリネーム・階層変更は行わない（削減のみ）。

- 理由: v3 skeleton / doctor / 共有 review 資産が既に `rules.depth_level.level` 等の v2 パスを読んでおり、ローダー変更はスコープ外。維持により migration の retained キーは identity mapping になり、変換規則が最小化される。キー削減（34 → 8）が本質であり、命名変更は非目標。

### D3: v3 終端キー集合 = 8 キー

| # | キー | 型 | 既定値 | 用途 |
|---|------|----|--------|------|
| 1 | `rules.depth_level.level` | string enum（`minimal` / `standard` / `comprehensive`） | `"standard"` | size × depth_level マトリクス（§8）の cycle 側入力 |
| 2 | `rules.automation.mode` | string enum（`manual` / `semi_auto`） | `"manual"` | 承認ゲートの自動承認制御（workflow.md §5） |
| 3 | `rules.reviewing.mode` | string enum（`required` / `recommend` / `disabled`） | `"recommend"` | review 処理パス選択（routing_review_mode） |
| 4 | `rules.reviewing.tools` | array of string | `["codex"]` | review ツール優先順位（フォールバック順序） |
| 5 | `rules.reviewing.exclude_patterns` | array of string | `[]` | review 時の機密情報除外パターン |
| 6 | `rules.release.changelog` | bool | `false` | release 4-3 changelog 追記 opt-in |
| 7 | `rules.release.version_tag` | bool | `false` | release 4-3 tag 作成 opt-in（extension 相当 / 既定 off） |
| 8 | `rules.release.required_ci_zero_fallback` | bool | `false` | required CI 0 件時の release hard gate フォールバック opt-in（002 / #745） |

- 採用基準: v3 フェーズフロー（steps）または委譲先共有資産が現に参照する挙動制御キーのみを残す。v2 の情報フィールド・v2 固有機能キー（feedback / retrospective / git 細粒度制御 / inception / linting / cycle / version_check / construction / documentation / github 等の 27 キー）は終端集合に含めない（v2 34 − 維持 7 = drop 27 / v3 新規 1 を加えて終端 8）。
- RFC §6.2 の削減目標（34 → ~8 / ~76%）と整合し、§6.4 の「8 か 12 か」の揺れを **8 で確定**する。
- 共存期間の注記: v3 が一時的に委譲する v2 共有資産（review-flow.md / review-routing.md 等)が参照する v2-only キー（例: `rules.reviewing.codex_bot_account`）は v3 終端 schema に含めない。不在時は各資産の文書化された既定値へフォールバックし、review 統合（9→1 aidlc-review）で解消する。

### D4: 002 フォールバック opt-in の発動形態 = config フラグ + 発動時ユーザー承認の二段

`rules.release.required_ci_zero_fallback = true`（config フラグ / 既定 `false`）を **経路の解放**とし、実際の発動時には別途**ユーザー承認 + release.md / journal への記録**を必須とする（承認手順の詳細定義は 002 のスコープ）。

- 理由: 「required CI が存在しない」は環境の恒常的属性であり、宣言的な config フラグが適合する（プロジェクト規約の代替方針 2「明示的フラグ」）。毎回の対話確認のみで表現すると `semi_auto` 運用と両立せず、反復承認の形骸化リスクもある。config diff として opt-in が監査可能になる。
- 既定 `false` により現行 fail-closed 挙動は不変（002 AC / intent AC-1 と整合）。
- フラグ名は発動条件（required check 0 件）を自己記述する `required_ci_zero_fallback` とする。

### D5: v2 → v3 キー対応表 = migration.md §3 に具体化（新 §3.1）

migration.md §3 の config 行を具体化する **§3.1「config キーマッピング」** を追加する:

- retained 8 キーのうち v2 に存在する 7 キー（#1〜#7）: identity mapping（キーパス・型・既定値とも不変）
- `rules.release.required_ci_zero_fallback`（#8）: v2 に対応キーなし（v3 新規 / migration では生成時に既定 `false`）
- v2 の残り 27 キー: 変換せず**警告**（エラーにしない / 非互換点 #3 と整合）。ドロップ対象はキー単位で列挙する
- 変換先 schema の正本は data-model.md §11 とし、migration.md は変換規則（identity / drop+warn）のみを持つ（SoT 二重定義回避）

### 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `docs/v3/data-model.md` | §11 新設（8 キー schema 表 + 採用基準 + 共存期間注記）/ §8 注記を §11 参照へ置換 / §1 節一覧更新 |
| `docs/v3/rfc.md` | §6.4 の終端値ポイントを「8 で確定（data-model.md §11）」へ更新 |
| `docs/v3/migration.md` | §8 SoT ギャップ注記の解消（§11 参照へ置換）/ §3 config 行の具体化 + §3.1 キーマッピング表新設 / ヘッダのスコープ外記述更新 |

### 検証方針

- 3 文書の相互参照が循環なく一方向（RFC → data-model §11 ← migration）であることの目視レビュー
- ドキュメント系 CI（markdownlint 等）pass
