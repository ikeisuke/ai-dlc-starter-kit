# Deprecation一覧

このドキュメントは、AI-DLC Starter Kitで非推奨（deprecated）となった機能を一覧管理します。

## 方針

- **非推奨化（Deprecated）**: 将来のバージョンで削除予定であることを宣言
- **削除（Removed）**: 実際にコードを削除
- 新規プロジェクトへの影響はありません（後方互換性のためのコードです）

---

## progress-md-fallback-v1.9.0 progress.md後方互換参照

- **非推奨バージョン**: v1.9.0
- **削除予定バージョン**: v2.0.0
- **説明**: Unit定義ファイルに「実装状態」セクションがない場合に、旧形式の`docs/cycles/{{CYCLE}}/construction/progress.md`ファイルから状態を読み取る後方互換性ロジック（Construction Phaseの進捗確認ステップ）
- **影響ファイル**:
  - `prompts/package/prompts/construction.md`（後方互換性セクション）
- **移行ガイド**: 対応不要。v1.6.0以降で作成されたUnitには「実装状態」セクションが含まれています

---

## backlog-md-migration-v1.9.0 旧形式バックログ移行コード

- **非推奨バージョン**: v1.9.0
- **削除予定バージョン**: v2.0.0
- **説明**: 旧形式の単一ファイル`docs/cycles/backlog.md`から新形式のディレクトリ構造`docs/cycles/backlog/`への移行処理。setup.md内の「旧形式バックログ移行」セクション全体が対象
- **影響ファイル**:
  - `prompts/package/prompts/setup.md`（ステップ11「旧形式バックログ移行」セクション）
- **移行ガイド**: 対応不要。v1.6.0以降でセットアップされたプロジェクトは新形式を使用しています

---

## 削除済み

（v2.0.0で削除された項目をここに記載予定）
