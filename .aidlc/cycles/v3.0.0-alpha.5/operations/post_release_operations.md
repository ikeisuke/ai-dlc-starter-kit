# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.5
- **リリース日**: 2026-06-27
- **リリース内容**: v3 リニューアル **Phase 4 = develop normal/risky 分岐**（Epic #736）。`/aidlc-v3 develop` を tiny 専用から、work item の `size`（tiny/normal/risky）× cycle の `depth_level` に応じて設計・レビュー・テストプラン・rollback note の厚みを変える分岐へ拡張。成果物要否の正本は `docs/v3/data-model.md` §8。

### 含まれる Unit

- **001 develop-size-depth-branching**（develop size×depth_level 分岐基盤）
- **002 develop-design-step**（develop Step 2 設計生成 + design テンプレート / 依存: 001）
- **003 develop-review-routing**（develop Step 5 review routing + 境界ガード解除 / 依存: 002）
- **004 develop-regression-tests**（回帰テスト + 全マトリクス統合検証 / 依存: 001-003）

## 運用状況

本プロジェクトは AI-DLC スターターキット（配布物）であり、稼働率・レスポンスタイム・アクティブユーザー数等のサービス運用メトリクスは適用対象外（N/A）。配布は GitHub リポジトリ公開 + タグ作成で行う。

## インシデント対応

- なし

## バグ対応

### 修正済みバグ

- なし（本サイクルは機能拡張サイクル。develop の size×depth_level 分岐を新規追加）

### 未修正バグ

- なし（本サイクルスコープ内）

## ユーザーフィードバック

- Epic #736（v3 リニューアル Phase 4–7 完遂ロードマップ）の Phase 4 を本サイクルで対応。Epic #736 は cross-cycle トラッカーのため本 PR ではクローズせず継続。
- #733 T1（共有 parser 集約）は alpha.4 で完了済みのため本サイクル対象外。

## 改善点の洗い出し

### 次サイクル候補

- Epic #736 の残 Phase（Phase 5–7）
- バックログ Issue（次サイクル以降で優先度に応じて対応）

## 次期バージョンの計画

### 対象バージョン

- v3.0.0-alpha.6（または v3.0.0 GA 仕上げ）

### 主要な改善・新機能

- Epic #736 Phase 5–7 の develop フロー拡張継続

## 備考

- メタ開発: 本サイクルは AI-DLC スターターキット自身の開発。`skills/aidlc-v3/` 配下の develop size×depth_level 分岐が成果物。
