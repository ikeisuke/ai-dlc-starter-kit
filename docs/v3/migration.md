# AI-DLC v3 移行方針: v2 → v3 マイグレーション

- **ステータス**: Accepted（Unit 004 設計フェーズ承認済 / 2026-06-10）
- **対象サイクル**: v3.0.0-alpha.1
- **位置づけ**: v2 → v3 移行の**方針**正本。移行モード・データ変換マッピング・非互換点・推奨モード・条件付き EOL との関係を確定する
- **入力**: `docs/v3/rfc.md`（Unit 001: DG-3 条件付き EOL / DG-5 GitHub 前提 / §4.3 core-extension 分類 / §5.7 v2 共存方針 / §7 引き継ぎマトリクス）、`docs/v3/data-model.md`（Unit 003: 変換先ディレクトリ構造 / state.json schema / work item frontmatter の正本）、`docs/v3/workflow.md`（Unit 002: コマンド名 develop / フェーズコマンド体系）、`docs/v3-renewal-plan.md`（v2 → v3 移行セクション）
- **SoT 境界**: 変換先 schema（ディレクトリ構造 / state.json / work item frontmatter）の正本は `data-model.md`。本書は変換**規則**のみを定義し、変換先 schema を再定義しない
- **スコープ外**: migration スクリプトの実装（引数仕様 / 終了コード / 実体コードは後続フェーズ）/ v3 config.toml キー終端設計の schema 定義本体（正本は `data-model.md` §11。本書は §3.1 で変換規則のみを定義する）/ v2 EOL の運用実行・告知掲載・メンテナンスモード運用の実施作業（条件付き EOL の方針記述のみ本書スコープ）

---

## 1. 概要 / 目的

v2 から v3 への移行方針を定める。基本姿勢は以下の 3 点である（RFC §5.3 / §5.7 / `renewal-plan` 移行セクション）:

- **完全自動変換は目指さない**: 変換できないケースは人間に確認する前提とする。本書は移行の「方針」を確定し、変換スクリプトの実装は後続フェーズに委ねる。
- **推奨は new-cycle-only**: v2 の過去資産を触らず、v3 を新しい cycle として開始する。過去資産は v2 のまま残置（archive 的）し、変換失敗リスクを負わない。
- **片方向移行（rollback 不可）**: v2 → v3 は片方向であり、v2 runtime 互換は維持しない（RFC §5.7）。一度 v3 へ移ったあと v2 へ巻き戻すことは保証しない。

consumer は本書の移行モード比較（§2）・データ変換マッピング（§3）・非互換点（§4）から、自プロジェクトの移行コストを見積もれる。

## 2. 移行モード

移行モードは 3 種を定義する。consumer は自プロジェクトの状況に応じて選択する。

| モード | 概要 | 推奨対象 | 前提条件 | 変換有無 | 既知リスク |
|-------|------|---------|---------|---------|-----------|
| **new-cycle-only**（推奨） | v2 の過去資産は触らず v3 cycle を新規に開始する | 大半の consumer。過去サイクルを v3 ツールから参照不要にできるプロジェクト | v3 を新しい cycle として始められること | なし（過去資産は v2 のまま残置） | 過去サイクルの状態は v3 ツールから参照できない（v2 ファイルとして残るのみ） |
| **best-effort** | `intent` / `unit` / `history` 等を v3 形式に変換する | 進行中のサイクルを v3 で継続したいプロジェクト | 変換不能ケースを人間が補完できること | あり（§3 のマッピングを適用） | 完全変換は保証されない。変換不能箇所は人間確認が必要。片方向移行（rollback 不可） |
| **archive-only** | v2 cycle を archive 扱いとし、所在を示す index のみ作る | 過去資産の所在記録だけ残したいプロジェクト | （特になし） | なし（index 生成のみ） | v3 ツールでの内容操作は不可（参照用 index のみ） |

**推奨は new-cycle-only**。理由は、過去資産を触らないため変換失敗のリスクがなく、移行コストが最小になるため（`renewal-plan` 移行方針）。

> **「変換有無」列の意味**: 本表の「変換有無」は**過去 cycle 資産の変換**の有無を指す。
> v3 config 生成（v2 config からのキーマッピング）と state.json 初期化は、選択モードに
> かかわらず §6 の手順 1 / 5 として**全モード共通**で実施される（archive-only の
> 「index 生成のみ」は「過去資産への操作が index 生成のみ」の意味であり、共通処理を
> 省略する意味ではない）。

## 3. v2 → v3 データ変換マッピング

`best-effort` モードで適用する変換規則を示す。**変換先 schema の正本は `data-model.md`（Unit 003）**であり、本表は「どの v2 資産を、どの v3 成果物に、どう変換するか」の規則のみを定義する。変換先パスはすべて `.aidlc/` 配下の正本パスで記述する（`data-model.md` §2 と粒度を統一）。

| v2 資産 | v3 変換先 | 変換方法 | 変換先正本 |
|---------|----------|---------|-----------|
| `requirements/intent.md` または `inception/intent.md` | `.aidlc/cycles/<cycle>/intent.md` | パスコピー | `data-model.md` §2 |
| `story-artifacts/units/*.md` | `.aidlc/cycles/<cycle>/work-items/*.md` | テンプレート差分を埋める（frontmatter 必須キー `id` / `status` / `size` / `risk` / `assigned` / `dependencies` を生成） | `data-model.md` §4 |
| `progress.md` | `.aidlc/state.json` | パース + schema 生成（`define_completed` / `release` 状態を導出） | `data-model.md` §3 |
| `history/*.md` | `.aidlc/cycles/<cycle>/journal.md` | 要約統合（追記型の軽量形式に集約） | `data-model.md` §7 |
| `operations/release_notes.md` | `.aidlc/cycles/<cycle>/release.md` | パスコピー | `data-model.md` §2 |
| `.aidlc/config.toml`（v2: 34 キー） | `.aidlc/config.toml`（v3: 8 キー） | キーマッピング（§3.1）+ 不要キー警告 | `data-model.md` §11 |

**config 変換の扱い**: 本書は config について「v2 キー → v3 キーの対応規則（§3.1）」と「v3 で未サポートになった v2 キーを**警告する**（エラーにはしない / 非互換点 #3 と整合）挙動」のみを記述する。v3 config の 8 キー終端集合（キー名 / 型 / 既定値 / 用途）の正本は `data-model.md` §11 である（§8 参照）。

### 3.1 config キーマッピング（v2 → v3）

変換先 schema の正本は `data-model.md` §11。本節は `best-effort` および new-cycle-only の「v2 config 読み込み → v3 config 生成」に適用する変換規則のみを定義する。

**維持キー（7 キー / identity mapping）**: 以下はキーパス・型・既定値とも v2 から不変で引き継ぐ。

| v2 キー | v3 キー |
|---------|---------|
| `rules.depth_level.level` | 同一（identity） |
| `rules.automation.mode` | 同一（identity） |
| `rules.reviewing.mode` | 同一（identity） |
| `rules.reviewing.tools` | 同一（identity） |
| `rules.reviewing.exclude_patterns` | 同一（identity） |
| `rules.release.changelog` | 同一（identity） |
| `rules.release.version_tag` | 同一（identity） |

**v3 新規キー（1 キー）**: `rules.release.required_ci_zero_fallback` は v2 に対応キーがない（migration では生成時に既定 `false` を適用し、v2 側から値を引き継がない）。

**ドロップキー（27 キー / 変換せず警告）**: 以下は v3 に変換先がなく、検出時に**警告する**（エラーにしない / 非互換点 #3 と整合）。

| v2 テーブル | ドロップされるキー |
|------------|------------------|
| `[rules.feedback]` | `enabled` / `upstream_repo` / `open_in_browser` |
| `[rules.reviewing]` | `codex_bot_account` |
| `[rules.depth_level]` | `history_level` |
| `[rules.construction]` | `max_retry` |
| `[rules.linting]` | `enabled` / `command` |
| `[rules.cycle]` | `mode` / `git_tracked` |
| `[rules.version_check]` | `enabled` |
| `[rules.git]` | `commit_on_unit_complete` / `commit_on_phase_complete` / `branch_mode` / `unit_branch_enabled` / `squash_enabled` / `merge_method` / `draft_pr` / `ai_author` / `ai_author_auto_detect` |
| `[rules.documentation]` | `language` |
| `[rules.github]` | `milestone_enabled` |
| `[rules.inception]` | `dedup_lookback_cycles` |
| `[rules.retrospective]` | `feedback_mode` / `feedback_max_per_cycle` / `auto_issue_creation` / `aggregate_issue_enabled` |

## 4. v2 との非互換点

v2 から v3 への主要な非互換点を、consumer への影響とともに列挙する（`renewal-plan` 非互換点リスト + RFC §4.3 / DG-5）。

| # | 非互換点 | consumer への影響 |
|---|---------|------------------|
| 1 | ステップファイル構造（35 ファイル → 5 ファイル） | カスタムステップは**再作成が必要** |
| 2 | 状態管理（`progress.md` 推論ベース → `state.json` 明示 schema） | **マイグレーション対象**（`progress.md` は v3 で認識されない） |
| 3 | 設定キー削減（多数 → 少数） | 未サポートキーは**無視される**（エラーにはしない） |
| 4 | レビュースキル統合（perspective を持つ `reviewing-*` 9 スキル + 共有基盤 `reviewing-common` の複製解消 → `aidlc-review` 1 本。`workflow.md` §6.1 と同粒度） | **再インストールが必要**（`marketplace.json` 更新） |
| 5 | スクリプト API（廃止スクリプトの直接呼び出し） | 直接呼ぶ consumer は**壊れる**。スクリプト直接呼び出しは非推奨パスのため**マイグレーション対象外** |
| 6 | recovery 動作（ファイル存在推論 → `state.json` 明示状態） | `progress.md` は v3 で**認識されない**（**マイグレーション対象**） |
| 7 | コマンド名（旧名 → 新名 `develop` 等） | 旧名は**エイリアスとして維持**（ヘルプ・ドキュメントは新名が主） |
| 8 | 成果物構造（`history/*.md` → `journal.md` 単一追記型） | **マイグレーション対象**（要約統合） |
| 9 | GitHub Projects 連携 | **廃止**（core の責務外。プロジェクト管理は外部ツールで運用） |
| 10 | Milestone 自動管理 / GitHub Release・version_tag 自動作成 | core から **extension 化（opt-in / 既定 off）**。core 既定では実行されず、利用には extension の有効化が必要 |

非互換点は RFC の core/extension 境界（DG-5 / §4.3）と整合する。すなわち、Projects は廃止、Milestone 自動管理および GitHub Release・version_tag 自動作成は extension（opt-in）であり、core は extension 不在でも動作する。

## 5. 条件付き EOL と v2 共存方針

RFC §7 引き継ぎマトリクスが本書（migration.md / Unit 004）に渡す DG-3 関連事項を**方針レベル**で記述する。EOL 宣言・告知掲載・メンテナンスモード運用の実際の**実施作業**は本書の対象外であり、以下は移行が成立するための前提条件としての関係性を示す。

- **条件付き EOL の 3 条件**（RFC §5.3）: 以下 3 条件をすべて満たした時点で v2 を EOL とする。
  1. マイグレーションが最低 2 つの consumer プロジェクトでテスト済み
  2. v3 で 1 cycle のドッグフーディングが完了済み
  3. EOL 告知が README / CHANGELOG に 1 バージョン前から掲載済み
- **移行期間中の v2 凍結（クリーンカット）**（RFC §5.7）: EOL までの期間、v2 `skills/aidlc` には通常改善・v3 互換対応を行わない。セキュリティ / クリティカル修正のみを例外として最小変更を許容する。
- **consumer runtime 非影響**（RFC §5.7）: v3 のリリースは v2 利用者の runtime を壊さない。consumer が v3 を導入するまで、その v2 はそのまま動作する。
- **片方向移行（rollback 不可）**（RFC §5.7）: 移行は片方向であり v2 runtime 互換は維持しない。

これら 4 点は「v2 を凍結しつつ consumer の runtime を壊さず、v3 へ一方向に移る」という移行成立の前提として相互に関係する。条件付き EOL は移行（本書）が信頼できる状態に達したことを前提に発効する。

## 6. 移行コマンドの方針概要

移行は `/aidlc-migrate` スキルが担う。`aidlc-migrate` はフェーズコマンド（`define` / `develop` / `release` / `reflect`）ではなく、一時的・移行専用の extension スキルである（RFC §4.3）。以下はその手順の**方針**であり、スクリプト実装・引数仕様・終了コードは本書では確定しない（後続フェーズ）。

手順方針（`renewal-plan` 移行コマンドセクション）:

1. v2 `config.toml` を読み、v3 `config.toml` を生成する（キーマッピング + 不要キー警告）
2. 移行モードの選択を人間に確認する（new-cycle-only / best-effort / archive-only）
3. 選択に応じてデータ変換を実行する（best-effort 時は §3 のマッピングを適用 / new-cycle-only・archive-only は変換を最小化）
4. 変換結果を人間に確認する（完全自動変換は目指さない）
5. `state.json` を初期化する

## 7. 推奨移行モードと片方向移行（まとめ）

- **推奨移行モードは new-cycle-only**。過去資産を触らないため変換失敗リスクがなく、移行コストが最小になる。
- **v2 → v3 は片方向移行（rollback 不可）**。`best-effort` で変換した場合も、v2 への巻き戻しは保証しない。
- consumer は非互換点（§4）とデータ変換マッピング（§3）から移行コストを見積もれる。

## 8. RFC / data-model.md との整合（SoT 二重定義回避）

- **変換先 schema の SoT**: データ変換の変換先（ディレクトリ構造 / state.json / work item frontmatter）は `data-model.md`（Unit 003）が正本である。本書は変換規則のみを定義し、schema 本体を再定義しない。各変換行に変換先正本（`data-model.md` §N）を併記している（§3）。
- **config 変換の SoT**: v3 `config.toml` のキー終端設計（34 → 8 のキー集合・命名）は **`data-model.md` §11（config.toml schema）が正本として確定済み**である（v3.0.0-beta.3 work item 001 で、RFC §6.4 と `data-model.md` §8 の相互委譲による SoT ギャップを解消）。本書は schema 本体を再定義せず、変換**規則**（維持キーの identity mapping / 新規キーの既定値適用 / ドロップキーの警告）のみを §3.1 に定義する。参照方向は RFC §6.4 → `data-model.md` §11 ← 本書 §3.1 の一方向であり循環しない。
- **コマンド名整合**: 本書は `develop` を正本とし、`build` 表記は使用しない（RFC DG-1 / `workflow.md`）。
- **core/extension 境界整合**: 非互換点 §4 の #9 / #10 は DG-5（Projects は廃止、Milestone 自動管理・GitHub Release/version_tag 自動作成は extension）と整合する。core は extension 不在でも成立する。
