# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.1（pre-release / Phase 1）
- **リリース日**: 2026-06-10
- **リリース内容**: AI-DLC v3 フルリニューアルの Phase 1（RFC / data model 固定）。`docs/v3/` 配下に設計判断を確定する RFC 群（rfc.md / workflow.md / data-model.md / migration.md）を文書化した docs-only サイクル。実行可能コードは生成しない
- **マージ先**: `cycle/v3.0.0-alpha.1` → `v3.0.0`（統合ベースブランチ。`main` ではない）

## バックログ整理結果

### 自動クローズ対象（PR #729 の `Closes` 記載）

- なし（PR #729 の `## Closes` は「なし」。本サイクルは v3 設計確定のみで、既存 Issue を解決しない）

### 手動クローズ対象

- なし（open backlog Issue 群はすべて v2 系運用改善 / v3 後続フェーズ向けの作業項目であり、本 docs-only サイクルでは未対応のまま次サイクル以降に残す）

## 運用上の留意点

### docs-only サイクルの位置付け

- 本サイクル（alpha.1）は v3 リニューアル全体の最初の段階。`docs/v3/` の設計ドキュメントを成果物とし、スキル本体・スクリプト・config の挙動は一切変更していない
- consumer プロジェクトへの配布物（`skills/` / `bin/` / `scripts/` / `config/`）に変更はなく、既存 v2.x consumer への影響はゼロ

### ブランチ・バージョニング戦略

- 段階的進行: alpha.1（RFC / data model 固定）→ alpha.2（skeleton）→ alpha.3（define + develop tiny）… と進め、全 alpha 完走後に `v3.0.0` を `main` へマージする
- 本 PR のマージ先は統合ベースブランチ `v3.0.0` であり `main` ではないため、`auto-tag.yml`（main push 時タグ付け）は発火しない。`v3.0.0-alpha.1` のリリースタグは自動付与されない

### CI / チェック

- defaults.toml 同期チェック / size check は Operations ステップで確認（メタ開発特有手順）

## 次期バージョンの計画

### 次フェーズ: v3.0.0-alpha.2（skeleton）

- alpha.1 で固定した RFC / data-model を入力に、v3 ディレクトリ構造・state.json schema・work item template の skeleton を実装する段階へ進む

### 監視ポイント

- `docs/v3/` の設計ドキュメントが後続 alpha フェーズの SoT として参照され、drift が発生しないか
- alpha 系列の各サイクルが `v3.0.0` 統合ブランチへ正しく積み上がっているか

## 備考

本サイクルは AI-DLC スターターキット自身のメタ開発（ドッグフーディング）として実施。v3 リニューアルは複数 alpha サイクルにまたがる長期作業の起点である。
