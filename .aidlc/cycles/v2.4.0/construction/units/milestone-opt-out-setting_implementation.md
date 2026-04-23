# Unit 008 実装記録: Milestone 運用 opt-out 設定の追加

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/008-milestone-opt-out-setting.md`
- **Plan**: `.aidlc/cycles/v2.4.0/plans/unit-008-plan.md`
- **Domain Model**: `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_008_milestone_opt_out_domain_model.md`
- **Logical Design**: `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_008_milestone_opt_out_logical_design.md`
- **担当ストーリー**: 追加ストーリー（v2.4.0 Operations Phase 中の振り返りで浮上）
- **関連 Issue**: #597（追加対応：Unit G）

## 実装内容

### 1. defaults.toml × 2 への opt-out 設定キー追加

- `skills/aidlc/config/defaults.toml`（正本）: 末尾（`[rules.documentation]` の後）に `[rules.milestone]\nenabled = false` を追加（+3 行）
- `skills/aidlc-setup/config/defaults.toml`（同期コピー）: 正本と同じ追記（+3 行）
- `bash bin/check-defaults-sync.sh` 実行 → `sync:ok`（exit 0）で同期確認

### 2. Inception ステップへのガード追加

- `skills/aidlc/steps/inception/02-preparation.md` ステップ 16 の **「Milestone 紐付け」サブセクション直前**（GitHub Issue 確認は本 Unit のスコープ外のため、見出し `### 16. GitHub Issue確認` 全体ではなく Milestone 紐付け部分のみをスキップ対象とする）に opt-in ガード追加（自然文での明示的スキップ指示 + `MILESTONE_ENABLED` 取得 1 行のみ、+11 行）
- `skills/aidlc/steps/inception/05-completion.md` ステップ 1（「### 1. Milestone 作成・Issue 紐付け」見出し直後）にガード追加（+11 行）。エクスプレスモードセクション 2 は本ステップ 1 に委譲しているため自動波及（追加編集不要）

### 3. Operations ステップへのガード追加

- `skills/aidlc/steps/operations/01-setup.md` ステップ 11（「### 11. Milestone 紐付け確認・fallback 判定」見出し直後）にガード追加（+11 行）。`enabled=false` 時は `LINK_FAILED` 集約判定 exit 1 契約も発動しない旨を自然文で明示
- `skills/aidlc/steps/operations/04-completion.md` ステップ 5.5（「### 5.5 Milestone close」見出し直後）にガード追加（+11 行）。`enabled=false` 時は `gh_status != available` 時 exit 1 契約も発動しない旨を自然文で明示

### 4. インデックスファイルへの補足追加

- `skills/aidlc/steps/inception/index.md` L33（ステップ表セル）/ L113（§2.7 表セル）/ L208（4. ステップ読み込み契約）の Milestone 参照箇所に「`[rules.milestone].enabled=true` のみ動作 / 既定 off」の補足追加（インライン編集 3 箇所）
- `skills/aidlc/steps/operations/index.md` §2.8 の `gh_status` 分岐表 3 行目（`available` 以外の例外行）に「`[rules.milestone].enabled=false`（既定）時はステップ 5.5 自体がスキップされ本例外は発動しない」を追記。補助契約見出しを「`gh_status = available` かつ `[rules.milestone].enabled=true` 時の Milestone 紐付け補完失敗」に更新し、本文末尾にも `enabled=false` 時の不発動条件を追記

### 5. 公開ドキュメント更新

- `docs/configuration.md`: 新規セクション `### [rules.milestone] — Milestone 運用（v2.4.0 で追加）` 追加（`### [rules.documentation]` の後、`## カスタマイズ例` の前、+8 行）。カスタマイズ例にも「Milestone 運用を有効化する」を追加（+7 行）
- `skills/aidlc/guides/issue-management.md` L52 「2. Milestone 紐付け」の最初の子項目として「前提（v2.4.0 以降）: 本機能は `[rules.milestone].enabled=true` のときのみ動作する（既定 off / Unit 008 / #597 Unit G）」を追記（+1 行）
- `skills/aidlc/guides/backlog-management.md` L22 「**対応開始時の Milestone 紐付け（v2.4.0 以降）**:」の最初の子項目として同様の追記（+1 行）
- `skills/aidlc/guides/backlog-registration.md` L48 「**Milestone について（v2.4.0 以降）**」の説明文末尾に「ただし、Milestone 機能は `[rules.milestone].enabled=true` のときのみ動作する（既定 off / Unit 008 / #597 Unit G）」を追記（インライン編集）
- `skills/aidlc/guides/glossary.md` L26 Milestone エントリの説明欄に「`[rules.milestone].enabled=true` のとき動作 / 既定 off / Unit 008 / #597 Unit G」を追記（インライン編集）

### 6. CHANGELOG への追記

- `CHANGELOG.md` `[2.4.0]` 節 `### Added` の Operations Phase 追加項目の後に Unit 008 の opt-out 設定追加項目を末尾追加（+1 行）。Keep a Changelog 順序（Added → Changed → Deprecated → Removed）は維持

### 7. メタ開発リポ自身の opt-in 設定追加

- `.aidlc/config.toml` 末尾に `[rules.milestone]\nenabled = true` を明示設定（+8 行、コメント含む）。本リポジトリは v2.3.6 試験運用 + v2.4.0 本採用継続のため明示有効化
- `read-config.sh rules.milestone.enabled` 実行 → `true`（exit 0）で動作確認済み

## レビュー反復履歴

- **Plan 段階 codex AI レビュー round 1**: P1×1（ガード分岐が独立 bash ブロック構造でステップ全体スキップが達成されない）/ P2×2（read-config.sh 終了コード説明ズレ + opt-out 動作検証手順欠落）/ P3×1（ファイル数誤記 12 → 15）。3 ファイル全部に対して以下の修正:
  - ガード分岐を「自然文での明示的スキップ指示 + `MILESTONE_ENABLED` 取得 1 行のみ」の形に統一（既存 `gh_status` 分岐パターンと完全に同じ実行モデル）
  - read-config.sh 終了コード表を実装に正確に整合させた（PROJECT_CONFIG_FILE 不在は exit 2 致命扱い、defaults.toml 不在は警告のみで継続）
  - 動作確認手順に「3. opt-out 時のスキップ動作検証【最重要】」セクション追加（4 箇所のステップで `enabled=false` 時に Milestone 関連処理が一切実行されないことを検証）
  - logical design 概要の「12 ファイル」→「15 ファイル」に修正
- **Plan 段階 codex AI レビュー round 2**: **No findings**（auto_approved 達成、unresolved=0）
- **Implementation 段階 codex AI レビュー round 1**: P2×1（`operations/index.md` L130 の `gh_status = available` 通常行が無条件で「Milestone 紐付け確認・Milestone close をすべて実行」と読める） / P3×1（実装記録の「見出し直後」表現が `02-preparation.md` ステップ 16 と整合しない）。修正:
  - `operations/index.md` L130 を「Issue クローズ・PR 操作・タグ push・GitHub Release 作成を実行。Milestone 紐付け確認 / Milestone close は **`[rules.milestone].enabled=true` のときのみ実行**（既定 off では `01-setup.md` ステップ 11 / `04-completion.md` ステップ 5.5 自体がスキップされる、Unit 008 / #597 Unit G）」に更新
  - 実装記録の「ガード位置の一貫性」を「4 ステップとも『Milestone 関連サブセクション直前 + `gh_status` 判定の前』にガード配置。Inception 02-preparation ステップ 16 のみ内部の『Milestone 紐付け』サブセクション直前に配置」と正確化
- **Implementation 段階 codex AI レビュー round 2**: **No findings**（auto_approved 達成、unresolved=0）。8 観点すべて整合確認済み:
  - Plan / Logical Design と実差分の整合
  - 4 箇所のガードが統一パターン（自然文 + 1 行 bash）
  - Unit 005 / 006 / 007 本体ロジック非干渉
  - defaults.toml 同期（`sync:ok`）
  - メタ開発リポ自己整合性（`.aidlc/config.toml` `enabled = true`）
  - `read-config.sh rules.milestone.enabled` → `true`
  - CHANGELOG セクション順序（Added → Changed → Deprecated → Removed）維持
  - ガード位置一貫性（02-preparation のみ Milestone サブセクション直前、残り 3 箇所は見出し直後で、いずれも `gh_status` 判定の前）

## 完了確認

- [x] `skills/aidlc/config/defaults.toml` に `[rules.milestone]\nenabled = false` を追加
- [x] `skills/aidlc-setup/config/defaults.toml` に同期コピー
- [x] `bash bin/check-defaults-sync.sh` が `sync:ok`
- [x] Inception 2 ステップ + Operations 2 ステップに opt-in ガード追加（4 箇所）
- [x] Inception index.md 3 箇所 + Operations index.md §2.8 表 + 補助契約に `enabled` 条件追加
- [x] `docs/configuration.md` に `[rules.milestone]` セクション + カスタマイズ例追加
- [x] 4 guides に「既定 off + 明示設定で有効化」追記
- [x] `CHANGELOG.md` `[2.4.0]` 節 `### Added` に Unit G の opt-out 設定追加を追記
- [x] `.aidlc/config.toml`（メタ開発リポジトリ）に `[rules.milestone]\nenabled = true` 設定追加
- [x] `read-config.sh rules.milestone.enabled` がメタ開発リポで `true` を返すことを確認
- [x] codex AI レビュー auto_approved 達成（round 2 No findings）

## 実装上の注意（次サイクル以降への引き継ぎ）

- **後方互換性最優先**: `read-config.sh` 終了コード 1（キー不在）/ 2（dasel 不在 / project config 不在 / 読取失敗）でもガード側で `2>/dev/null || echo "false"` フォールバックにより `false` 扱い。defaults.toml 配布前のリポジトリでも安全に動作
- **ガード位置の一貫性**: 4 ステップとも「Milestone 関連サブセクション直前 + `gh_status` 判定の前」にガード配置。Inception 02-preparation ステップ 16 のみ「`### 16. GitHub Issue確認`」全体ではなく内部の「Milestone 紐付け」サブセクション直前に配置（GitHub Issue 確認自体は本 Unit のスコープ外のため）。残り 3 ステップ（Inception 05-completion ステップ 1 / Operations 01-setup ステップ 11 / Operations 04-completion ステップ 5.5）は見出し直後に配置
- **本体ロジック非干渉**: Unit 005 / 006 / 007 で実装した 5 ケース判定 / 冪等補完原則 / 手動復旧 3 パターン分岐 / Keep a Changelog 順序 / `gh_status != available` 時 exit 1 契約 / `LINK_FAILED` 集約判定 exit 1 契約は **一切触らず**、ガード分岐で外側を包む方針を貫徹
- **メタ開発リポ自己整合性**: 本 Unit のコミットに `.aidlc/config.toml` の `[rules.milestone].enabled = true` 設定追加を含めることで、本サイクル後続の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持
- **次サイクル候補**: v2.5.0 以降で opt-out 設定の運用評価 + 既定 true への変更検討（v2.4.0 で本採用 → opt-out 化したが、利用者からのフィードバック次第で再度本採用化を検討する余地あり）

## 関連ファイル

- Unit 005: `inception-milestone-step_implementation.md`（Inception Phase Milestone ステップ実装、Unit 008 のガード対象本体）
- Unit 006: `operations-milestone-close_implementation.md`（Operations Phase Milestone close 実装、Unit 008 のガード対象本体）
- Unit 007: `docs-milestone-rewrite_implementation.md`（公開ドキュメント Milestone 周知、Unit 008 で「既定 off」前提を 1 行追記）
