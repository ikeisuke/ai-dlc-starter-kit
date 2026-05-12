# Construction Phase 履歴: Unit 02

## 2026-05-11T16:40:23+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-aidlc-migrate-traversal（aidlc-migrate manifest 由来パスのトラバーサル検証）
- **ステップ**: AIレビュー完了
- **実行内容**: 計画承認前レビュー (codex / 3 rounds)

**Round 構成**:
- Round 1: 指摘 3 件（中 2 / 低 1）
- Round 2: 指摘 1 件（中・Unit 定義 NFR の exit code 残骸）
- Round 3: 指摘 0 件 → `is_clean()` で completed

**指摘内容と対応**:

| Round | # | 重要度 | 内容 | 対応 |
|-------|---|--------|------|------|
| 1 | 1 | 中 | ヘルパー I/F と realpath shim 方式が計画時点で未確定（手戻りリスク） | 計画段階に確定値（関数シグネチャ・引数仕様・戻り値仕様・shim 採用方針 (a) pure bash + cd -P ループ）を前倒し記載。Phase 1 セクションは「実装詳細を詰める」内容にダウンスコープ |
| 1 | 2 | 中 | エラー識別子 `migrate-apply:path-traversal` が3スクリプト跨ぎで同一（障害発生源識別不可） | ヘルパー第3引数に `script_id` 追加、エラー出力を `error\t<script_id>:path-traversal\t<offending_path>\treason=<code>` に分割。Unit 定義「技術的考慮事項」も同期 |
| 1 | 3 | 低 | exit 2 固定が exit-code-convention.md「拒否=1 / 環境障害=2」と乖離 | 全拒否ケースを exit 1（バリデーションエラー）に統一、realpath shim 自体のシステムエラーのみ exit 2 の二層契約を計画と Unit 定義の両方に明文化。ユーザー確認済み（規約準拠案を選択） |
| 2 | 1 | 中 | Unit 定義 NFR の exit 2 残骸（計画と乖離） | Unit 定義 NFR セキュリティ行を exit 2 → exit 1 に統一、二層契約を明文化 |

**スコープ判断**:
- ユーザー確認済み: aidlc-migrate 配下の書き込み系3ファイル（migrate-apply-config.sh / migrate-apply-data.sh / migrate-cleanup.sh）すべてを対象とする（Issue #680 タイトルと Unit 定義「境界」の範囲内、defer 残骸ゼロ化）

**シグナル**:
- review_detected=true
- resolved_count=4
- deferred_count=0
- unresolved_count=0
- セミオートゲート判定: auto_approved（フォールバック条件非該当）

**成果物パス**:
- 計画ファイル: `.aidlc/cycles/v2.6.2/plans/unit-002-plan.md`
- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/002-fix-aidlc-migrate-traversal.md`

**コミット**: `1dba7648 chore: [v2.6.2] レビュー反映 - Unit 002 計画ファイル + Unit 定義（codex R1/R2 指摘 4件）`

**Codex セッション**: 019e1568-fb5c-7c72-8584-4f76a0dd0c48（Round 2 / Round 3 で resume 使用）
- **成果物**:
  - `.aidlc/cycles/v2.6.2/plans/unit-002-plan.md`
  - `.aidlc/cycles/v2.6.2/story-artifacts/units/002-fix-aidlc-migrate-traversal.md`

---
## 2026-05-11T16:53:53+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-aidlc-migrate-traversal（aidlc-migrate manifest 由来パスのトラバーサル検証）
- **ステップ**: AIレビュー完了
- **実行内容**: 設計レビュー（ドメインモデル + 論理設計 / codex 2R）

**Round 構成**:
- Round 1: 指摘 3 件（高 2 / 中 1）
- Round 2: 指摘 0 件 → `last_round_clean=true` で completed

**指摘内容と対応**:

| Round | # | 重要度 | 内容 | 対応 |
|-------|---|--------|------|------|
| 1 | 1 | 高 | `if ! _aidlc_migrate_validate_path ...; then exit $?; fi` が bash `!` パイプライン反転で戻り値 1/2 契約を喪失 | 論理設計 L158-178 を `rc=$?; if [[ $rc -ne 0 ]]; then exit "$rc"; fi` パターンに修正、bash `!` 挙動の注意書き追加 |
| 1 | 2 | 高 | 「シェル実装内では `$()` 使用可」記述が `.aidlc/rules.md` コマンド置換禁止および Unit 定義 Intent 制約と衝突 | 論理設計 L395-406 を規約準拠（新規 lib で `$()` 不使用）に統一、代替パターン 4 種（関数戻り値 / 一時ファイル+read / mapfile / 再諮問エスケープ）明記 |
| 1 | 3 | 中 | `validate` が AIDLC_PROJECT_ROOT を毎回再解決し NFR（10ms 未満）とテスタビリティ低下 | `_aidlc_migrate_path_guard_init` 初期化関数を新設、`_AIDLC_MIGRATE_PATH_GUARD_ROOT` スクリプトスコープ変数で境界を保持、validate は注入済み境界のみ参照 |

**シグナル**:
- review_detected=true
- resolved_count=3
- deferred_count=0
- unresolved_count=0
- セミオートゲート判定: auto_approved（フォールバック条件非該当）

**成果物パス**:
- ドメインモデル: `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_002_fix_aidlc_migrate_traversal_domain_model.md`
- 論理設計: `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_002_fix_aidlc_migrate_traversal_logical_design.md`
- レビューサマリ: `.aidlc/cycles/v2.6.2/construction/units/002-review-summary.md`

**コミット**: `54bede0f`（レビュー前）→ `5d6b6efe`（レビュー反映）

**Codex セッション**: `019e1602-7932-7a63-b7a0-6a9dc261b081`（Round 2 で resume 使用）
- **成果物**:
  - `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_002_fix_aidlc_migrate_traversal_domain_model.md`
  - `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_002_fix_aidlc_migrate_traversal_logical_design.md`
  - `.aidlc/cycles/v2.6.2/construction/units/002-review-summary.md`

---
## 2026-05-11T17:08:22+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-aidlc-migrate-traversal（aidlc-migrate manifest 由来パスのトラバーサル検証）
- **ステップ**: AIレビュー完了
- **実行内容**: コードレビュー（path-guard lib + 3 スクリプト組込 + cleanup bats / codex 2R）

**Round 構成**:
- Round 1: 指摘 3 件（高 1 / 中 1 / 低 1）
- Round 2: 指摘 0 件 → `last_round_clean=true` で completed

**指摘内容と対応**:

| Round | # | 重要度 | focus | 内容 | 対応 |
|-------|---|--------|-------|------|------|
| 1 | 1 | 高 | security | 固定パス一時ファイル `/tmp/...-$$-*.tmp` で TOCTOU/symlink 競合（CWE-59/CWE-377）の余地 | `path-guard.sh` 全箇所で一時ファイルを完全廃止し、process substitution `<(...)` + `IFS= read -r` で中間結果を直接受信。realpath -m / pwd -P / cd -P のすべてが TOCTOU フリー |
| 1 | 2 | 中 | security | cleanup bats が CWE-22 攻撃 4 シナリオのうち 2 シナリオしか検証していない | `migrate-cleanup.bats` に `symlink_escape` ケース追加（外部ターゲット symlink + exit 1 + stderr アサート）。`outside_project_root` は raw_path レベル発火不能を実装にコメントで明記し defense-in-depth として残す |
| 1 | 3 | 低 | code | `_aidlc_migrate_validate_path` の `_field_name` 引数が未使用 | エラー出力第4フィールド末尾を `reason=<code>;field=<name>` 形式に拡張。tab 区切り 4 フィールド契約は維持。論理設計 `unit_002_..._logical_design.md` のエラー時出力仕様セクションも同期更新 |

**シグナル**:
- review_detected=true
- resolved_count=3
- deferred_count=0
- unresolved_count=0
- セミオートゲート判定: auto_approved（フォールバック条件非該当）

**回帰確認**:
- shellcheck -x path-guard.sh / 3 スクリプト: pass
- tests/migration 全 6 ファイル: 37 件 pass（cleanup bats は 9 件に拡張、新 symlink_escape ケース含む）

**成果物パス**:
- 実装: `skills/aidlc-migrate/scripts/lib/path-guard.sh`, `migrate-apply-config.sh`, `migrate-apply-data.sh`, `migrate-cleanup.sh`
- テスト: `tests/migration/migrate-cleanup.bats`（拡張）
- 論理設計同期: `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_002_fix_aidlc_migrate_traversal_logical_design.md`
- レビューサマリ: `.aidlc/cycles/v2.6.2/construction/units/002-review-summary.md`（Set 2 追記）

**コミット**: `9388903b`（レビュー前）→ `fe60327d`（レビュー反映）

**Codex セッション**: `019e160d-ffb3-7481-b3d6-68c2f453b9c4`（Round 2 で resume 使用）
- **成果物**:
  - `skills/aidlc-migrate/scripts/lib/path-guard.sh`
  - `skills/aidlc-migrate/scripts/migrate-apply-config.sh`
  - `skills/aidlc-migrate/scripts/migrate-apply-data.sh`
  - `skills/aidlc-migrate/scripts/migrate-cleanup.sh`
  - `tests/migration/migrate-cleanup.bats`

---
## 2026-05-11T17:46:41+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-aidlc-migrate-traversal（aidlc-migrate manifest 由来パスのトラバーサル検証）
- **ステップ**: AIレビュー完了
- **実行内容**: 統合レビュー（設計乖離 / レビュー・テスト実施 / 完了条件 / codex 2R）

**Round 構成**:
- Round 1: 指摘 3 件（高 1 / 中 1 / 低 1）
- Round 2: 指摘 0 件 → completed

**指摘内容と対応**:

| Round | # | 重要度 | 内容 | 対応 |
|-------|---|--------|------|------|
| 1 | 1 | 高 | `_aidlc_migrate_realpath` 公開 I/F 不一致（設計 `<input> [base]` vs 実装 `<result_var> <input> [base]`） | 論理設計を実装シグネチャに同期、関数仕様セクションも printf -v ベースに統一 |
| 1 | 2 | 中 | `;field=<name>` 形式がドメインモデル・Unit 定義に未反映 | 両方を `reason=<code>;field=<name>` 形式に同期、4 フィールド契約維持を明記 |
| 1 | 3 | 低 | 計画§完了条件チェックリスト未更新、Unit 定義§実装状態未更新 | 計画 16 項目すべて [x] 化（達成根拠補足）、Unit 定義§実装状態を 完了 / 2026-05-11 に更新 |

**シグナル**:
- review_detected=true
- resolved_count=3
- deferred_count=0
- unresolved_count=0
- セミオートゲート判定: auto_approved（フォールバック条件非該当）

**Construction Phase 全体サマリ**:
- 計画レビュー (Set 1): codex 3R / 高2 中1 低1 → completed
- 設計レビュー (Set 2 in summary / Set 1 in history): codex 2R / 高2 中1 → completed
- コードレビュー: codex 2R / 高1 中1 低1 → completed
- 統合レビュー: codex 2R / 高1 中1 低1 → completed
- 合計指摘: 13 件（高 6 / 中 5 / 低 3）すべて修正済み、defer 0、技術的ブロッカー 0

**回帰確認**:
- shellcheck -x: pass
- bats migration 全 49 件 pass（新 migrate-path-traversal.bats 12 件含む / cleanup bats 拡張 3 件含む）
- bats プロジェクト全 406 件 pass

**成果物**:
- 計画: `.aidlc/cycles/v2.6.2/plans/unit-002-plan.md`
- ドメインモデル: `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_002_fix_aidlc_migrate_traversal_domain_model.md`
- 論理設計: `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_002_fix_aidlc_migrate_traversal_logical_design.md`
- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/002-fix-aidlc-migrate-traversal.md`
- 実装: `skills/aidlc-migrate/scripts/lib/path-guard.sh`（新規）, `migrate-apply-config.sh`, `migrate-apply-data.sh`, `migrate-cleanup.sh`
- テスト: `tests/migration/migrate-path-traversal.bats`（新規 / 12 件）, `tests/migration/migrate-cleanup.bats`（拡張）
- レビューサマリ: `.aidlc/cycles/v2.6.2/construction/units/002-review-summary.md`（Set 3 追記）

**コミット**: `4eb1be81`（レビュー前）→ `3ed1fe09`（レビュー反映）

**Codex セッション**: `019e1633-5173-73d2-aede-75475a368159`（Round 2 で resume 使用）
- **成果物**:
  - `.aidlc/cycles/v2.6.2/construction/units/002-review-summary.md`
  - `tests/migration/migrate-path-traversal.bats`

---
## 2026-05-11T17:49:15+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-fix-aidlc-migrate-traversal（aidlc-migrate manifest 由来パスのトラバーサル検証）
- **ステップ**: Unit完了
- **実行内容**: Unit 完了処理

**完了条件チェック**: 計画ファイル§完了条件チェックリスト 16/16 達成
**設計・実装整合性チェック**: 統合レビュー Set 3 で codex により検証済（指摘 0 件）
**意思決定記録**: DR-007（スコープ拡張 / aidlc-migrate 書き込み系3ファイル）, DR-008（exit code 規約準拠 / exit 1 統一）を `.aidlc/cycles/v2.6.2/inception/decisions.md` に追記
**AI レビュー実施**: 計画 / 設計 / コード / 統合の 4 レビュー completed（合計 codex 9 ラウンド / 12 件指摘すべて修正済み / defer 0）
**Markdownlint**: pass

**Construction Phase Unit 002 全体サマリ**:

| Phase | 内容 | レビュー | 完了 |
|-------|------|---------|------|
| 計画 | Issue #680 対応の計画作成 | codex 3R / 高2 中1 低1 | ✓ |
| 設計 | ドメインモデル + 論理設計 | codex 2R / 高2 中1 | ✓ |
| 実装 | lib/path-guard.sh + 3 スクリプト組込 + cleanup bats 拡張 | codex 2R / 高1 中1 低1 | ✓ |
| テスト | migrate-path-traversal.bats（4 attack × 3 script + path-guard 単体 = 12 件） | - | ✓ |
| ビルド・テスト | shellcheck pass / bats 全 49（migration） + 全 406（プロジェクト） pass | - | ✓ |
| 統合 | 設計乖離 / レビュー実施 / 完了条件チェック | codex 2R / 高1 中1 低1 | ✓ |
| 完了 | 完了条件 / decisions 追記 / markdownlint / squash 準備 | - | ✓ |

**主要成果物**:
- 新規: `skills/aidlc-migrate/scripts/lib/path-guard.sh`（256 行 / `$()` 不使用 / TOCTOU フリー）
- 改修: `migrate-apply-config.sh` / `migrate-apply-data.sh` / `migrate-cleanup.sh`（検証フック挿入）
- 新規テスト: `tests/migration/migrate-path-traversal.bats`（12 件）
- 拡張テスト: `tests/migration/migrate-cleanup.bats`（4 attack シナリオを反映）
- 設計: `domain-models/unit_002_..._domain_model.md` / `logical-designs/unit_002_..._logical_design.md`
- レビューサマリ: `construction/units/002-review-summary.md`（Set 1〜3 完備）

**完了サマリ（Issue #680 解消）**:
- aidlc-migrate manifest 由来パスのトラバーサル検証を構造的に予防（CWE-22）
- 拒否 4 シナリオ（absolute_path / parent_traversal / outside_project_root / symlink_escape）すべて fail-closed
- exit-code-convention.md 準拠（バリデーション拒否=1 / shim システムエラー=2 の二層契約）
- CWE-59/CWE-377（TOCTOU/symlink 競合）も process substitution + read で構造的に解消
- 既存 manifest 動作は無破壊（bats 既存 37 件 + 新規 12 件 = 49 件 pass）

**関連 Issue**: #680 解消
**残課題・バックログ**: なし（defer 0 / OUT_OF_SCOPE 0 / TECHNICAL_BLOCKER 0）

---
