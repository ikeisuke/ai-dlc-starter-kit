# 実装記録: Unit 009 アップグレード指示改善

## 概要

アップグレード指示（setup-prompt.md）にメタ開発用のパス参照を追加し、環境に応じた正しいパスを参照できるようにした。

## 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | ガード文修正、環境判定セクション追加、ghqオプションツール追加 |
| `docs/cycles/v1.9.0/design-artifacts/domain-models/009-upgrade-instruction_domain_model.md` | ドメインモデル設計 |
| `docs/cycles/v1.9.0/design-artifacts/logical-designs/009-upgrade-instruction_logical_design.md` | 論理設計 |

## 実装詳細

### 1. ガード文の修正（86-88行目）

メタ開発モード（`prompts/package/`存在時）を許可するように修正。

### 2. セクション8.1.1追加

スターターキットパスの判定ロジックを追加:
- メタ開発環境: `.`（カレントディレクトリ）
- 通常利用（ghq）: `$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit`
- 通常利用（手動）: ユーザー指定のパス

### 3. ghqオプションツール追加

セクション0のオプションツールにghqを追加し、インストールコマンドも追記。

### 4. ghq存在確認ガード

`command -v ghq`でghqの存在を確認し、未インストール時は手動パス入力を促す。

## 完了状態

- **状態**: 完了
- **完了日**: 2026-01-23
