# ユーザーストーリー

## Epic: v2.4.3 patch — 4 Issue 統合解消

### ストーリー 1: アップグレードブランチ運用の意図明示（#612）

**優先順位**: Must-have

As a メタ開発者（スターターキット自身を編集する人）/ ダウンストリーム利用者
I want to `aidlc-setup` のアップグレード走行で作成されるブランチ命名と、`.aidlc/rules.md` のブランチ運用文言が「ダウンストリーム向け（`chore/aidlc-v<version>-upgrade`）」と「スターターキット自身（`cycle/v<version>`）」を明確に区別していてほしい
So that スターターキット自身の dogfooding 中に「`upgrade/v2.4.x` ブランチがリリース用と誤読される」紛らわしさを解消し、両者の役割が一目で分かる状態にしたい

**受け入れ基準**:

- [ ] `.aidlc/rules.md` L274 周辺の「アップグレード時: `upgrade/vX.X.X` ブランチを作成」記述が、現実の命名 `chore/aidlc-v<version>-upgrade` に整合し、かつ「これはダウンストリームプロジェクト向けの運用」と明示されている
- [ ] `.aidlc/rules.md` のブランチ運用フローに「スターターキット自身（`ikeisuke/ai-dlc-starter-kit`）は `cycle/vX.X.X` を使用する」旨の対比節が追加されている
- [ ] `skills/aidlc-setup/SKILL.md` 冒頭または該当節に「本スキルのアップグレードフローはダウンストリームプロジェクト向け、スターターキット自身では実行不要（cycle/vX.X.X リリースで設定同期）」が明記されている
- [ ] `skills/aidlc-setup/steps/03-migrate.md` の §9 周辺で `chore/aidlc-v<version>-upgrade` 命名のままダウンストリーム向け文脈が維持されている（命名変更コードパス自体の追加は不要）
- [ ] 過去サイクルで作成された `upgrade/v*` ブランチ（既存）には影響しない（リネーム作業を行わない）
- [ ] 変更後、`grep -rn "upgrade/v" .aidlc/rules.md skills/aidlc-setup/ skills/aidlc-migrate/` の結果が以下のいずれかになる: (a) 過去履歴・例示としての言及のみ、(b) `chore/aidlc-v<version>-upgrade` への置換完了
- [ ] `aidlc-migrate` スキル配下の文言を `grep -rn "upgrade/v\|chore/aidlc-v" skills/aidlc-migrate/` で全洗い出しし、結果を Construction Phase の design.md または history に証跡として残す。`upgrade/v` 言及がある場合は対比節を追加し、`chore/aidlc-v` のみの場合は対比節追加要否を design.md に判断記録する
- [ ] setup / migrate の双方で、最終的な運用文言（ダウンストリーム向け命名 + スターターキット自身の対比）が整合している（grep 結果の差分が解消されている）

**技術的考慮事項**:

- 主な変更は文言（Markdown）。実装ロジック（ブランチ作成コマンド）は既に `chore/aidlc-*` で稼働中のため最小修正
- `bin/post-merge-sync.sh` は対応プレフィックスに `chore/aidlc-v*-upgrade` が含まれているか Construction Phase で確認（v2.4.2 で追加済みの可能性あり）
- スターターキット自身向け / ダウンストリーム向けの判定ロジック（origin URL チェック等）の実装は本サイクルでは対象外（Intent 案 B 採用、案 A は対象外）

---

### ストーリー 2: レビューツール設定への self 正式統合（#611）

**優先順位**: Must-have

As a メタ開発者 / ダウンストリーム利用者
I want to `[rules.reviewing].tools` に `"self"`（および alias `"claude"`）を正式に許容する設定で、外部 CLI（codex 等）が usage limit / 不在 / parse 失敗した際にツール解決の通常順序として self に降りるよう動作してほしい
So that 「`fallback_to_self` が暗黙特殊分岐」だった現状を「ツール解決の自然な順序」に整理し、新規ユーザーが設定の意図を予測しやすくしつつ、既存設定（`tools = ["codex"]` / `tools = []`）も後方互換シムで壊さずに動作させたい

**受け入れ基準**:

- [ ] `skills/aidlc/steps/common/review-routing.md §3` の `tools` 設定説明に `"self"` / `"claude"` が正式な値として記載されている
- [ ] `review-routing.md §4` の `ToolSelection` で以下が成立する:
  - `configured_tools` に `self` または `claude` が含まれる場合: 通常のリスト走査で解決される（特殊分岐なし）
  - `configured_tools` に `self` も `claude` も含まれない場合: 末尾に `self` を暗黙補完（後方互換シム）
  - `configured_tools = []`: 従来通りセルフ直行扱い、シム適用結果（`["self"]` 相当）と等価で動作
  - alias 正規化: `"claude"` は ToolResolver 入口で `"self"` に単純置換される
- [ ] `review-routing.md §5` の `PathSelection` で、`self_review_forced` シグナル（`tools=[]` 由来）の挙動が新仕様と整合し、表が更新されている
- [ ] `review-routing.md §6` の `FallbackPolicyResolution` で `cli_missing_permanent` / `cli_runtime_error` / `cli_output_parse_error` の `fallback_to_self → 2` 分岐が「ツール解決順序の延長として self に降りる」表現に整理されている（必要なら章を縮約 or 注記化）
- [ ] `skills/aidlc/steps/common/review-flow.md` のパス1/パス2記述、Codex セッション管理の「エラー時は §6 の fallback_policy に従う」が新仕様と整合している
- [ ] `skills/aidlc/config/defaults.toml` の `[rules.reviewing].tools` 既定値は現行 `["codex"]` を維持する（暗黙シムにより実質 `["codex", "self"]` 相当で動作）。Construction Phase で `["codex", "self"]` への明示変更を再検討する場合は design.md に変更理由と影響範囲を明記する
- [ ] 既存 `.aidlc/config.toml` および以下のテストパターン全てがマイグレーション不要で動作することを、design.md の I/O 表または `history/construction_unit{NN}.md` に動作確認記録として残す:
  - パターン A: `tools = ["codex"]`（既存・暗黙シム適用）
  - パターン B: `tools = []`（既存・セルフ直行シグナル）
  - パターン C: `tools = ["codex", "self"]`（新規明示）
  - パターン D: `tools = ["self"]`（新規セルフ単独明示）
  - パターン E: `tools = ["claude"]`（alias 正規化）
  - パターン F: `tools` 未設定（デフォルト適用）
- [ ] 上記 6 パターンの動作確認は、`scripts/read-config.sh` 経由 + `review-routing.md §4 ToolSelection` の擬似実行（手順書の動作確認テーブル）または bats 等のテストスクリプトで実施し、結果を実装記録として残す

**技術的考慮事項**:

- 暗黙シムは `ToolSelection` ロジック内に置く方がカプセル化される（`read-config.sh` 利用側ではなく）
- alias 正規化は ToolResolver 入口で `"claude" -> "self"` の単純置換で吸収（複数 alias 対応の汎用化は対象外）
- review-routing.md は純粋参照ファイル（実行手順を持たない）であるため、文書整合性レビューが必要

---

### ストーリー 3: migrate-backlog.sh の UTF-8 対応（#610）

**優先順位**: Must-have

As a ダウンストリーム利用者（バックログ移行を実行する人）
I want to `scripts/migrate-backlog.sh --dry-run` を fullwidth カッコ（`（`）含む日本語タイトルに対して実行しても `tr: Illegal byte sequence` を出さず、slug がタイトル末尾まで保持されてほしい
So that 日本語タイトルの backlog 移行で「カッコ以降の情報が欠落」するデータロスが起きず、移行後の Issue 内容が原本と一致する状態にしたい

**受け入れ基準**:

- [ ] `skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()` 関数の Perl invocation が UTF-8 モード（例: `perl -CSD -Mutf8 -pe ...`）に変更されている
- [ ] 修正後、以下のテスト入力で `Illegal byte sequence` エラーが発生せず、Issue #610 本文の検証結果（既存ロジックの小文字化・空白→ハイフン変換規約に準拠）と一致する slug が生成される:
  - 入力: `テスト分離の改善（並列テスト対応）` → 期待 slug: `テスト分離の改善並列テスト対応`（カッコのみ除去、隣接した日本語間に区切り文字なし）
  - 入力: `SQLite vnode エラー（DB差し替え時の競合アクセス）` → 期待 slug: `sqlite-vnode-エラーdb差し替え時の競合アクセス`（半角英数字部分は小文字化＋空白ハイフン化、日本語接続部はそのまま連結）
  - 入力: `AgencyConfig DDD責務整理` → 期待 slug: `agencyconfig-ddd責務整理`（半角英数字は小文字化＋空白ハイフン化、日本語は連結）
- [ ] テスト記録（実装記録または unit テスト記録）に上記 3 ケースの動作確認結果が含まれている
- [ ] DEPRECATED マークは維持される（削除タイミングの見直しは別 Issue 化、本サイクルでは行わない）
- [ ] `--dry-run` モードでの動作も同様に修正済みであること（`generate_slug()` は両モードで共通利用される前提）

**技術的考慮事項**:

- 修正は実質 1 行（`perl -pe ...` → `perl -CSD -Mutf8 -pe ...`）。Issue #610 本文に修正案として明記済み
- `-CSD` で IO の UTF-8 化、`-Mutf8` で正規表現リテラルの UTF-8 解釈を併用するのが必須（`-CSD` 単独では不十分）
- macOS / Linux 両環境で動作する Perl 5.x 標準機能のみを使用（環境依存リスク低）

---

### ストーリー 4: markdownlint の hook 化と Operations §7.5 削除（#609）

**優先順位**: Must-have

As a メタ開発者 / AI エージェント（Edit/Write を行う側）
I want to Markdown ファイル編集（Edit / Write）直後に PostToolUse hook で `markdownlint-cli2` が自動実行され違反を即時検出してほしい。同時に Operations Phase §7.5 の手動 lint ステップは削除し、CI（必須 Check）と hook の二層に集約してほしい
So that 編集ループ内で違反を発見でき、Self-Healing で対処する手戻りを最小化しつつ、Operations 手順書から重複する lint ステップを除いて手順全体を簡素化したい

**受け入れ基準**:

- [ ] `.claude/settings.json` の `hooks.PostToolUse` に `matcher: "Edit|Write"` の hook が追加されている
- [ ] 新規 hook スクリプト（命名は Construction で確定、例: `bin/markdownlint-on-md-changes.sh`）が以下を満たす:
  - 編集対象ファイルが `*.md` の場合のみ `markdownlint-cli2` を実行する（拡張子で早期 return）
  - `markdownlint-cli2` 未インストール環境ではスキップして `exit 0`（Claude Code 側でブロックされない）
  - 違反検出時は exit code 非 0 で通知し、stderr に違反内容を出力する
  - 既存 PostToolUse hook (`check-utf8-corruption.sh`) と独立に動作し、片方の失敗が他方をブロックしない
- [ ] `skills/aidlc/steps/operations/operations-release.md` から §7.5（Markdownlint 実行）ステップが削除されている
- [ ] `skills/aidlc/steps/operations/02-deploy.md:183` の「7.5 Markdownlint実行」参照が削除されている
- [ ] `skills/aidlc/steps/operations/operations-release.md:63` の「§7.5 で `markdownlint:auto-fix` が発生した場合のみ」分岐記述が削除（または §7.5 削除に整合する形に修正）されている
- [ ] `skills/aidlc/scripts/operations-release.sh` の `lint` サブコマンド本体が削除されている
- [ ] 削除後、`grep -rn "§7\.5\|7\.5 Markdownlint\|operations-release\.sh lint" skills/` の結果が空（または例示・履歴記述のみ）になる
- [ ] CI の `pr-check.yml` `markdown-lint` job は変更なし（必須 Check として継続）
- [ ] hook スクリプトのファイルパス（最終確定値）が Construction Phase の design.md（I/O 表または該当 Unit 設計）に記録され、`.claude/settings.json` の参照と一致している
- [ ] hook 追加による regression 検証として以下が個別に確認されている:
  - 既存 PostToolUse の `check-utf8-corruption.sh` が `*.md` 編集後にも従来通り起動する（hook 連鎖が壊れていない）
  - matcher `Edit|Write` 以外（Bash / Read / Grep など）では新 hook が起動しない
  - 編集対象ファイルが `*.md` 以外（例: `*.toml` / `*.sh`）の場合、新 hook はスキップして exit 0 を返す
- [ ] hook が `markdownlint-cli2` 未インストール環境で正常スキップする動作確認結果が記録されている（`command -v markdownlint-cli2` 等の検出方式は Construction で確定）

**技術的考慮事項**:

- hook スクリプトは Bash で記述（既存 `check-utf8-corruption.sh` と同枠組み）
- PostToolUse の入力（編集対象ファイルパス）の取得方法は Claude Code hook 仕様に従う（環境変数または stdin）
- `markdownlint-cli2` のインストール検出は `command -v markdownlint-cli2` または `npx --no-install markdownlint-cli2 --version` で行う（Construction で確定）
- §7.5 削除に伴い、`operations-release.md` の他セクション（§7.6 / §7.7 のコミット対象列挙など）に `markdownlint:auto-fix` 由来の記述が残らないか grep で全特定する
- hook スクリプトのファイル名・配置（`bin/markdownlint-on-md-changes.sh` 等）は Construction Phase 設計時に確定し、design.md の I/O 表に記録する

---

## 受け入れ基準のチェック観点（自己検査）

| ストーリー | 具体性 | 検証可能性 | 完全性 | 独立性 |
|-----------|-------|-----------|-------|-------|
| 1（#612 ブランチ命名運用） | ◎ rules.md / SKILL.md / 03-migrate.md の対象記述に対応する受け入れ基準 | ◎ grep で残存有無を検証可 | ◎ 過去ブランチ非影響 / aidlc-migrate 整合まで網羅 | ◎ 他ストーリーと独立 |
| 2（#611 self 統合） | ◎ ToolSelection / PathSelection / FallbackPolicyResolution の挙動が条件付きで明示 | ◎ 後方互換テストと新規パターンテストが必須 | ◎ alias / shim / 既定値方針まで網羅 | ◎ 他ストーリーと独立 |
| 3（#610 UTF-8） | ◎ Perl オプション + 3 ケース具体入力 / 出力 | ◎ コマンド実行結果で検証可 | ◎ DEPRECATED 維持 / dry-run 動作含む | ◎ 他ストーリーと独立 |
| 4（#609 hook + §7.5 削除） | ◎ settings.json / hook script / 各手順書の対象箇所が個別に明示 | ◎ grep / 動作確認で検証可 | ◎ 未インストール環境スキップ / regression 非発生まで網羅 | ◎ 他ストーリーと独立 |
