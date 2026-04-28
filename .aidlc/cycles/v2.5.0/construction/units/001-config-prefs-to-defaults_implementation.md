# 実装記録: Unit 001 個人好みキーの defaults.toml 集約

## 実装日時

2026-04-29 06:33（Inception 完了直後の Construction 開始） 〜 2026-04-29（Unit 001 完了）

## 作成ファイル

### ソースコード（差分）

- `skills/aidlc-setup/templates/config.toml.template` — 個人好み 7 キー（`rules.reviewing.mode` / `rules.reviewing.tools` / `rules.automation.mode` / `rules.git.squash_enabled` / `rules.git.ai_author` / `rules.git.ai_author_auto_detect` / `rules.linting.enabled`）を除去。`[rules.linting]` / `[rules.automation]` はセクションごと削除、`[rules.git]` / `[rules.reviewing]` はセクションヘッダ保持
- `skills/aidlc/config/config.toml.example` — template と同等のスタンスで対象 7 キーの実値・コメント例を削除
- `.github/workflows/migration-tests.yml` — `PATHS_REGEX` を Unit 001 関連パスに拡張し、実行コマンドを `bats tests/migration/ tests/config-defaults/` に変更。fixture 過検知防止のため `tests/fixtures/.+` を `tests/fixtures/v1-structure/.+\|tests/fixtures/config-defaults/.+` に絞り込み

### テスト（新規）

- `tests/config-defaults/template-removed-keys.bats` — 観点 A: template / example から 7 キーが除去されていることを section + leaf 検査（template）/ dotted_path 検査（example）の 2 経路で検証。プロジェクト強制カテゴリのキー残存も regression テストで担保
- `tests/config-defaults/defaults-resolution.bats` — 観点 B1（project 欠落 → defaults 値が固定期待値で返る）+ 観点 B2（project 存在 → project 値が defaults を上書き、後方互換 NFR）を 7 キー × 2 ケース + バッチモード 2 ケースで検証
- `tests/config-defaults/helpers/setup.bash` — 共通ヘルパ（`setup_b1_environment` / `setup_b2_environment` / `teardown_environment` / `run_read_config_single` / `run_read_config_batch` / `template_has_section` / `template_has_section_leaf` / `example_has_key` / `b1_expected_for` / `b2_expected_for`）

### Fixture（新規）

- `tests/fixtures/config-defaults/b1-no-keys/.aidlc/config.toml` — 7 キー無しの最小プロジェクト設定
- `tests/fixtures/config-defaults/b2-with-keys/.aidlc/config.toml` — 7 キーを defaults と異なる値で含む既存プロジェクト風設定

### 設計ドキュメント

- `.aidlc/cycles/v2.5.0/design-artifacts/domain-models/unit_001_config_prefs_to_defaults_domain_model.md`
- `.aidlc/cycles/v2.5.0/design-artifacts/logical-designs/unit_001_config_prefs_to_defaults_logical_design.md`
- `.aidlc/cycles/v2.5.0/plans/unit-001-plan.md`
- `.aidlc/cycles/v2.5.0/construction/units/001-review-summary.md`

### `defaults.toml`（編集なし、確認のみ）

- `skills/aidlc/config/defaults.toml`（正本）— 7 キーすべてが既に template 旧値と完全一致で収録済み。本 Unit では編集せず、テストで同等性を検証
- `skills/aidlc-setup/config/defaults.toml`（同期コピー）— 編集なし、`bin/check-defaults-sync.sh` で sync:ok を確認済み

## ビルド結果

成功（ビルド成果物なし、シェルスクリプトと TOML / YAML / Markdown のみ）

## テスト結果

成功

- 実行テスト数: 70
- 成功: 70
- 失敗: 0

```text
bats tests/migration/ tests/config-defaults/
1..70
ok 1..36   # tests/migration/ 既存テスト（回帰なし）
ok 37..70  # tests/config-defaults/ 新規テスト（観点 A 17 件 + B1/B2 17 件）
```

加えて `bin/check-defaults-sync.sh` が `sync:ok` を返し、正本／同期コピーの一致が維持されていることを確認。

## コードレビュー結果

- [x] セキュリティ: OK（設定テンプレート差分のみで通信・認証系の影響なし。ai_author 削除値も機密含まず）
- [x] コーディング規約: OK（`.aidlc/rules.md` のコマンド置換禁止ルールを bats / awk で遵守）
- [x] エラーハンドリング: OK（`aidlc_read_toml` / `read-config.sh` の既存 exit code 規約を踏襲）
- [x] テストカバレッジ: OK（観点 A / B1 / B2 / regression / batch / NFR を 70 ケースでカバー）
- [x] ドキュメント: OK（計画 / ドメインモデル / 論理設計 / レビューサマリ / Unit 定義責務を相互整合させて更新）

## 技術的な決定事項

- **defaults.toml 不変原則**: 既に template 旧値と完全一致で収録済みのため、新規追加・編集を行わない。リスク回避と SoT 重複排除を優先
- **観点 A の検査方式を 2 経路に分割**: template はプロジェクトプレースホルダ（`[プロジェクト名]` / `[[言語リスト]]`）を含む invalid TOML のため、当初設計の dasel 部分木検査では構造解析できないことを実装で発見。template は `grep` + `awk` ベースの section + leaf 検査、example は valid TOML のため `aidlc_read_toml`（dasel v2/v3 互換）で dotted_path 検査と方式を分割
- **B1 期待値のハードコード化**: defaults.toml 値が将来意図せず変わった場合に検知できるよう、観点 B1 では bats テスト内に「user_stories.md ストーリー 1 由来の固定期待値」をハードコードし、固定値と read-config.sh 出力を比較する設計に変更（既定値同等性 NFR の検知力強化）
- **配列値出力フォーマットの正規化**: dasel v3 は配列値を `['codex']` のシングルクォート形式で出力するため、テスト期待値もそのまま採用（defaults.toml では `["codex"]` のダブルクォートで書くが、read-config.sh 経由の出力フォーマットを SoT とする）
- **CI PATHS_REGEX の最小拡張**: 既存 `migration-tests.yml` を流用し、新規 workflow ファイルは作成しない。fixture 過検知を避けるため `tests/fixtures/v1-structure/.+|tests/fixtures/config-defaults/.+` で対象を限定

## 課題・改善点

- **`migration-tests.yml` のジョブ表示名乖離**: 名前が「Migration Script Tests」のままで bats tests/config-defaults/ も同ジョブで走るため、意味的乖離がある。リネーム自体は CI 履歴の連続性を優先して別 PR / 別サイクルで扱う方が安全（本 Unit ではスコープ外として保留）
- **正規 7 キー集合の自動同期**: `user_stories.md` の SoT を bats テストの期待値・ヘルパ・fixture に手動で同期している。将来サイクルで「単一ファイルから生成」する自動化を導入する場合、ドメインモデルの「参考概念: IndividualPreferenceKeyCatalog」が具象化候補となる
- **template の TOML 構造検査強化**: 実装中に template が invalid TOML（プレースホルダ含む）であることが判明。プレースホルダ展開後の生成 config が常に valid TOML であることを保証する自動テスト（aidlc-setup ウィザードのスナップショットテスト）は Unit 002 の責務範囲

## 状態

**完了**

## 備考

- 計画 / 設計 / コード / 統合の 4 段階 AI レビューをすべて codex で実施。指摘合計 11 件（計画 4＋1＋0 / 設計 3＋0 / コード 0 / 統合 3＋1（部分解消）＋0）をすべて解消し、unresolved 0 でセミオートゲート auto_approved
- 後続 Unit との境界明示: Unit 002（aidlc-setup ウィザード案内）/ Unit 003（aidlc-migrate 移動提案）は本 Unit の template 差分を前提に作業可能
