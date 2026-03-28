# ドメインモデル: Lite版ルーティング廃止

## 概要

本Unitはルーティングテーブル行の削除とファイル削除が主体であり、新規エンティティの追加はない。

## 影響するドメイン概念

### ルーティングテーブル（SKILL.md）
- **変更前**: `lite inception` / `lite construction` / `lite operations` の3エントリが存在
- **変更後**: 3エントリを完全削除。argument-hintからも除去

### フェーズ簡略指示テーブル（CLAUDE.md / AGENTS.md）
- **変更前**: 「Lite版を使用する場合」セクションが存在（3行テーブル）
- **変更後**: セクションごと削除

### Liteプロンプトファイル
- **変更前**: `lite/inception.md`, `lite/construction.md`, `lite/operations.md` が存在
- **変更後**: ファイル・ディレクトリごと削除

### セットアップドキュメント
- **変更前**: Liteファイルへの例示参照が存在
- **変更後**: 例示参照を削除

## 不変条件

- 通常フェーズコマンド（inception / construction / operations / setup / express / feedback / migrate）の動作に変更なし
- `.aidlc/cycles/` 配下のInception成果物（履歴的なLite記述）は変更しない
