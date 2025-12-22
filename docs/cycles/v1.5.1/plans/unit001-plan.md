# Unit 001 実行計画: プロジェクトタイプ設定機能の追加

## 概要

初回セットアップ時にプロジェクトタイプを選択・保存し、Operations Phaseで参照できるようにする。

## 仕様

### プロジェクトタイプの値

| 値 | 説明 | 配布ステップ |
|----|------|-------------|
| `web` | Webアプリケーション | スキップ |
| `backend` | バックエンドAPI/サーバー | スキップ |
| `general` | 汎用/未分類 | スキップ |
| `cli` | コマンドラインツール | 実行 |
| `desktop` | デスクトップアプリ | 実行 |
| `ios` | iOSアプリ | 実行 |
| `android` | Androidアプリ | 実行 |

### 動作仕様

- **設定タイミング**: setup.md（サイクル開始時）
- **保存先**: `aidlc.toml` の `project.type` フィールド
- **未設定時**: `general` として扱う（後方互換性）
- **参照タイミング**: Operations Phase のステップ4（配布）のスキップ判断

### 分岐ロジック

```
if project.type in [web, backend, general] or 未設定:
    配布ステップをスキップ
else:
    配布ステップを実行
```

## 対象ファイル（変更予定）

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/setup.md` | プロジェクトタイプ選択ステップを追加 |
| `prompts/package/aidlc.toml` | `project.type` フィールドを追加（デフォルト: general） |
| `prompts/package/prompts/operations.md` | `project.type` を参照し配布ステップの要否を判断 |

**注意**: `docs/aidlc/` は直接編集せず、`prompts/package/` を編集する（メタ開発ルール）

## Phase 1: 設計フェーズ

### ステップ1: ドメインモデル設計

- プロジェクトタイプの概念モデルを定義
- 選択肢の意味と配布ステップとの関係を明確化

### ステップ2: 論理設計

- setup.md への選択ステップ追加方法
- aidlc.toml のスキーマ変更
- operations.md での条件分岐ロジック

### ステップ3: 設計レビュー

- ユーザー承認を得る

## Phase 2: 実装フェーズ

### ステップ4: コード生成

- prompts/package/prompts/setup.md の修正
- prompts/package/aidlc.toml の修正
- prompts/package/prompts/operations.md の修正

### ステップ5: テスト生成

- 本Unitはプロンプト修正のため、手動確認で代替
- 確認手順:
  1. 初回セットアップでタイプ選択が表示されること
  2. aidlc.toml に project.type が保存されること
  3. Operations Phase で配布ステップが正しくスキップ/実行されること

### ステップ6: 統合とレビュー

- 変更内容の確認
- 実装記録の作成

## 完了基準

- [ ] setup.md にプロジェクトタイプ選択ステップが追加されている
- [ ] aidlc.toml に project.type フィールドが追加されている（デフォルト: general）
- [ ] operations.md で project.type を参照し配布ステップの要否を判断できる
- [ ] 未設定時は general 扱いで後方互換性が保たれている

## リスク・考慮事項

- 既存の aidlc.toml との互換性維持 → 未設定時は general 扱いで対応
