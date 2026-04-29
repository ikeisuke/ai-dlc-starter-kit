# 実装記録: Unit 002 aidlc-setup ウィザードの個人好み推奨案内

## 実装日時

2026-04-29（Unit 001 完了直後の Construction 継続） 〜 2026-04-29（Unit 002 完了）

## 作成ファイル

### ソースコード（差分）

- `skills/aidlc-setup/steps/03-migrate.md` — `## 9. Git コミット` の直後 / `## 10. 完了メッセージ` の直前に新セクション `## 9b. 個人好み user-global 推奨案内` を追加。直前行に HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->`（Unit 003 から参照する安定 ID）を配置。本文構成: 4 階層マージ仕様の説明 / 代表 3 キー（`rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`）の例示 / `~/.aidlc/config.toml` 記述例 / TeamImpactNote / ModeApplicabilityNote（初回セットアップ + automation_mode 全モード） / StderrRoutingNote（`--non-interactive` フォワード互換 + `>&2` リダイレクト） / IdempotencyNote（1 回のみ表示）
- `.github/workflows/migration-tests.yml` — `PATHS_REGEX` に `tests/aidlc-setup/.+` および `skills/aidlc-setup/steps/.+` を追加。実行コマンドを `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/` に拡張

### テスト（新規）

- `tests/aidlc-setup/setup-prefs-guidance.bats` — 観点 A（セクション存在 + 構造 / 3 ケース）+ B（代表 3 キー / 3 ケース）+ C（非対話モード対応指示 / 3 ケース）+ D（冪等性 + スコープ + 単一ソース / 4 ケース）+ R（既存セクション破壊回帰検出 / 2 ケース）+ S（安定 ID 契約: 直前位置 + 一意性 / 2 ケース）= 計 17 ケース
- `tests/aidlc-setup/helpers/setup.bash` — 共通ヘルパ。定数（`STEP_FILE_PATH` / `OTHER_STEP_FILES`）と関数（`assert_section_exists` / `assert_section_count` / `assert_section_between` / `extract_section_body` / `assert_body_contains_token` / `assert_body_contains_any` / `assert_other_files_no_token`）を分離。`grep -F --` 使用で `--non-interactive` 等 dash 始まりトークンに対応

### Fixture

- なし（静的検証のみで動的環境構築不要のため `tests/fixtures/aidlc-setup/` は作成しない）

### 設計ドキュメント

- `.aidlc/cycles/v2.5.0/design-artifacts/domain-models/unit_002_setup_wizard_prefs_guidance_domain_model.md`
- `.aidlc/cycles/v2.5.0/design-artifacts/logical-designs/unit_002_setup_wizard_prefs_guidance_logical_design.md`
- `.aidlc/cycles/v2.5.0/plans/unit-002-plan.md`
- `.aidlc/cycles/v2.5.0/construction/units/002-review-summary.md`

### Unit 定義の更新

- `.aidlc/cycles/v2.5.0/story-artifacts/units/002-setup-wizard-prefs-guidance.md` — 状態を「未着手」→「完了」、開始日 / 完了日を 2026-04-29、担当を Claude Code に更新

## ビルド結果

成功（ビルド成果物なし、markdown と bash と YAML のみ）

## テスト結果

成功

- 実行テスト数: 87
- 成功: 87
- 失敗: 0

```text
bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/
1..87
ok 1..36   # tests/migration/ 既存テスト（回帰なし）
ok 37..70  # tests/config-defaults/ Unit 001 テスト（回帰なし）
ok 71..87  # tests/aidlc-setup/ Unit 002 新規テスト（A 3 + B 3 + C 3 + D 4 + R 2 + S 2 = 17）
```

加えて以下の検証を実施:

- `bin/check-defaults-sync.sh` が `sync:ok` を返し、Unit 001 で確認した正本／コピーの一致が引き続き維持されていることを確認
- `npx markdownlint-cli2` で対象 4 ファイル（03-migrate.md / unit-002-plan.md / unit_002_..._domain_model.md / unit_002_..._logical_design.md）が 0 errors

## コードレビュー結果

- [x] セキュリティ: N/A（markdown ステップファイル + 静的検証 bats テスト + CI 設定変更のみで通信・認証・データフロー系の影響なし）
- [x] コーディング規約: OK（`.aidlc/rules.md` のコマンド置換禁止ルールを bats / awk で遵守 / `grep -F --` で dash 始まりトークン対応）
- [x] エラーハンドリング: OK（ヘルパ関数の exit code 規約: 0 = 成功, 1 = 検証失敗, 2 = 対象不在 を文書化済み）
- [x] テストカバレッジ: OK（観点 A / B / C / D / R / S を 17 ケースでカバー）
- [x] ドキュメント: OK（計画 / ドメインモデル / 論理設計 / レビューサマリ / Unit 定義責務を相互整合させて更新）

## 技術的な決定事項

- **markdown-driven 検証原則**: aidlc-setup が LLM 解釈実行型のため、テストは「ステップファイル markdown に必要な指示文字列が含まれているか」を静的に検証する形態を採用。動的実行テスト（実際に LLM を走らせて案内が出るか）は範囲外として将来 Unit に委譲
- **stable_id 契約の導入**: 案内本文の見出し文言は将来変更される可能性が高いため、Unit 003 から参照する識別子は HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->` の安定 ID とした。S1（直前位置検証） + S2（一意性検証）でこの契約を bats テストで担保
- **AC「`--non-interactive` でもログ記録」の実動作再定義**: aidlc-setup は markdown-driven skill のため CLI フラグ受理の実体が無い。AC を「automation_mode 全モード（manual / semi_auto / full_auto）対応 + stderr リダイレクト指示」に**実動作レベルで再定義**し、観点 C で 3 要素（`--non-interactive` 文字列フォワード互換参考 / stderr 指示 / automation_mode 全モード対応）を検査することで AC 文言と実動作保証の両面を担保
- **「初回セットアップ限定」と「automation_mode 全モード対応」の直交スコープ条件**: 「初回セットアップ経路の内側で automation_mode によらず案内を表示」というネスト関係を計画書 / 論理設計 / 案内本文で一貫して明記し、衝突を回避
- **`grep -F --` の使用**: `--non-interactive` のような dash 始まりトークンを `grep -F` に渡すと `grep` が CLI フラグとして解釈する罠を、`--` 区切りで回避。bats ヘルパ全体で統一適用
- **CI PATHS_REGEX の最小拡張**: 既存 `migration-tests.yml` を流用し、新規 workflow ファイルは作成しない（Unit 001 と同じ最小差分方針）。Unit 001 で残置した「ジョブ表示名の意味乖離」は本 Unit でもリネームしない（CI 履歴連続性優先）

## 課題・改善点

- **`--non-interactive` フラグの実体実装**: aidlc-setup を CLI スクリプト化または LLM 実行ガード機構に拡張すれば、フラグ受理 + stderr 出力を物理的に保証できる。本 Unit では markdown 内の指示文として実動作保証を表現したが、将来サイクルで「LLM 実行コンテキスト読取 + 出力ストリーム制御」の機構が整備された際に再評価候補
- **動的実行テストの欠如**: 「LLM が markdown を読んで実際に案内を出すか」を保証する動的テストは現状不可能。aidlc-setup の振る舞いを記録・再生する e2e テスト基盤は別 Unit / 別サイクルで対応する
- **`migration-tests.yml` のジョブ表示名乖離**: Unit 001 から継続する課題（リネームは別 PR / 別サイクルで対応）

## 状態

**完了**

## 備考

- 計画 / 設計 / コード / 統合の 4 段階 AI レビューをすべて codex で実施。指摘合計 11 件（計画 4＋2＋0 / 設計 4＋2＋0 / コード 2＋0 / 統合 2＋0）をすべて解消し、unresolved 0 でセミオートゲート auto_approved
- 後続 Unit との境界明示: Unit 003（aidlc-migrate 移動提案）は本 Unit の `## 9b` セクション（stable_id `unit002-user-global`）への**参照のみ**で「user-global 推奨」案内を再表示する設計とする（本文コピー禁止 / 単一ソース原則）
