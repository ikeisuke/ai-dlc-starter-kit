# Unit: session-title表示順変更

## 概要

session-titleスキルのタイトル表示順を「プロジェクト / バージョン / フェーズ / ユニット」に変更し、ユニット引数を追加する。

## 含まれるユーザーストーリー

- ストーリー 4: session-titleタイトル表示順変更（#287）

## 責務

- `aidlc-session-title.sh` の引数順と表示フォーマットを変更
- ユニット引数（オプショナル）を追加
- SKILL.mdの引数説明・呼び出し例を更新
- 各フェーズプロンプトの呼び出し箇所の引数順を更新

## 境界

- session-titleの表示ロジック（osascript/iTerm2エスケープシーケンス等）は変更しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- macOS（osascript）

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- 変更対象: `prompts/package/skills/session-title/bin/aidlc-session-title.sh`、`prompts/package/skills/session-title/SKILL.md`、各フェーズプロンプトの呼び出し箇所
- バージョンが空/unknownの場合のスキップ処理
- ユニットは Construction Phase でのみ指定（Inception/Operationsでは省略）

## 実装優先度

Medium

## 見積もり

中（シェルスクリプト1ファイル + SKILL.md + 複数フェーズプロンプトの呼び出し箇所変更）

## 関連Issue

- #287

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-08
- **完了日**: 2026-03-08
- **担当**: @ai
