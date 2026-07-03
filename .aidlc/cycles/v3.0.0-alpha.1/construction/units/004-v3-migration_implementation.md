# 実装記録: Unit 004 v3-migration（v3 移行方針 確定）

## 実装日時

2026-06-10（Phase 2 = docs/v3/migration.md 執筆〜統合レビュー完了）

## 作成ファイル

### ソースコード（docs-only 成果物）

- `docs/v3/migration.md` - v2 → v3 移行方針の正本。全 8 章（概要/目的 / 移行モード比較表 / データ変換マッピング / v2 との非互換点 / 条件付き EOL と v2 共存方針 / 移行コマンドの方針概要 / 推奨移行モードと片方向移行 / RFC・data-model.md との整合）

### テスト

- markdownlint（`npx markdownlint-cli2 docs/v3/migration.md`）- docs-only のためビルド/テストは markdownlint で代替

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.1/design-artifacts/logical-designs/unit_004_v3_migration_logical_design.md`（ドメインモデルは N/A: docs-only）
- `.aidlc/cycles/v3.0.0-alpha.1/plans/unit-004-plan.md`
- `.aidlc/cycles/v3.0.0-alpha.1/construction/units/004-review-summary.md`（Set 1 設計 / Set 2 コード / Set 3 統合）

## ビルド結果

成功（docs-only / markdownlint をビルド相当として扱う）

```text
markdownlint-cli2: docs/v3/migration.md
Summary: 0 error(s)
```

## テスト結果

成功（markdownlint）

- 実行テスト数: 1（markdownlint 1 ファイル）
- 成功: 1
- 失敗: 0

## コードレビュー結果

- [x] セキュリティ: OK（docs-only / 機密情報・ホーム配下絶対パス・破壊的コマンド・外部スクリプト実行手順の混入なしを codex 確認 = N/A 妥当）
- [x] コーディング規約: OK（markdownlint 0 errors / documentation.language=日本語）
- [x] エラーハンドリング: N/A（実行可能コードなし。migration スクリプト実装は対象外 / 方針記述のみ）
- [x] テストカバレッジ: OK（markdownlint で検証 / 統合レビューで完了条件 15 項目充足確認）
- [x] ドキュメント: OK（移行モード比較表・データ変換マッピング・非互換点・EOL 方針・config SoT ガード・推奨モード/片方向移行を網羅）

レビュー内訳（`004-review-summary.md`）:

- Set 1 設計レビュー（codex）: 3R（R1: 3 件 → R2: 1 件 → R3: 0 件）。変換先パスの `.aidlc/` 接頭辞統一・非互換点 #10 への GitHub Release 統合・`/aidlc-migrate` 根拠の RFC §4.3 化。
- Set 2 コード生成後レビュー（codex / docs+security 観点）: 2R（R1: 1 件 → R2: 0 件）。非互換点 #4 を workflow.md §6.1 粒度に補正。security N/A。
- Set 3 統合レビュー（codex）: 2R（R1: 1 件 → R2: 0 件）。完了条件 15 項目すべて充足確認・論理設計 §4 を実装補正に追従。

## 技術的な決定事項

- **変換先 schema の SoT 委譲**: データ変換マッピングの変換先（ディレクトリ構造 / state.json / work item frontmatter）は data-model.md（Unit 003）を正本参照し、migration.md は変換規則のみを定義（schema 二重定義回避）。変換先パスは `.aidlc/` 配下の正本パスで粒度統一。
- **config 変換の SoT ガード**: v3 config.toml キー終端設計（34→8）は RFC §6.4 と data-model.md §8 が相互委譲で未確定（既知ギャップ）。migration.md は「キーマッピング方針 + 不要キー警告の挙動」のみ記述し終端 schema を新規定義せず、未確定を注記して別途確定に委ねた（`depth_level` のみ確定参照可）。
- **DG-3 引き継ぎ受け**: RFC §7 が migration.md に渡す「EOL 3 条件・移行期間中 v2 非変更・consumer runtime 非影響・片方向移行」の相互関係を方針記述（EOL 宣言・告知掲載・メンテナンスモード運用の実施作業は対象外と明示）。
- **非互換点の core/extension 整合**: #9 Projects 廃止 / #10 Milestone・GitHub Release/version_tag を extension 化（opt-in）を DG-5 / RFC §4.3 と整合。各非互換点に consumer 影響（再作成要 / 無視 / マイグレーション対象 等）を付与。
- **非互換点 #4 の粒度補正**: 「reviewing-* 10 → aidlc-review 1 本」を workflow.md §6.1 粒度（perspective を持つ 9 スキル + 共有基盤 reviewing-common の複製解消）に補正。論理設計 §4 も同粒度に追従。
- **コマンド名 develop 統一**: renewal-plan の旧表記 build を使用せず develop に統一（RFC DG-1 / workflow.md）。
- **推奨 new-cycle-only / 片方向移行**: 推奨を new-cycle-only（過去資産を触らない=変換失敗リスクなし）とし、v2→v3 が片方向（rollback 不可）であることを明記。

## 課題・改善点

- migration スクリプトの実装（引数仕様 / 終了コード / 実体コード）は後続フェーズ（本サイクル対象外）。
- v3 config.toml キー終端設計（34→8 の具体集合・命名）は RFC §6 / data-model.md `defaults.toml` 設計で別途確定（本 Unit で検出した SoT 相互委譲ギャップ）。

## 状態

**完了**

## 備考

- すべてのゲート（計画承認・設計承認・コードレビュー承認・統合レビュー承認）は `automation_mode=semi_auto` により auto_approved。
- 完了条件 15 項目すべて充足（統合レビューで codex 確認）。
- 意思決定記録: 本 Unit の Phase 1/2 で新規のユーザー 2 択選択は発生せず（設計判断は Unit 001 RFC で確定済み、レビュー指摘はすべてメインエージェント判断で修正、スコープ縮小なし）。意思決定記録の対象なし。
