# Unit: `.claude/settings.json` セットアップ生成

## 概要

`/aidlc setup` 実行時に `.claude/settings.json` を自動生成し、AI-DLCスキル実行に必要なパーミッション設定を含める。

## 含まれるユーザーストーリー

- ストーリー 7: `.claude/settings.json` のセットアップ生成（#416関連）

## 関連Issue

- #416

## 責務

- `/aidlc setup` のフロー（`steps/setup/`）に `.claude/settings.json` 生成ステップを追加
- パーミッションテンプレートの定義（`Bash(skills/aidlc/scripts/*)`, `Bash(skills/*/bin/*)`, `Skill(aidlc)`, `Skill(reviewing-*)`, `Skill(squash-unit)` 等）
- 既存 `.claude/settings.json` とのマージロジック（既存設定を保持しつつAI-DLC必要分を追加）
- 不正JSON検出時の警告とスキップ処理

## 境界

- `settings.json` のスキーマ定義や全キーの管理はスコープ外
- グローバル設定（`~/.claude/settings.json`）は対象外

## 依存関係

### 依存する Unit

なし

### 外部依存

なし

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: 既存設定を破壊しないこと
- **スケーラビリティ**: スキル追加時にテンプレートへのエントリ追加のみで対応可能
- **可用性**: N/A

## 技術的考慮事項

- JSONのマージには `jq` を使用（preflight で `jq` 利用可否を確認）
- `jq` が利用不可の場合のフォールバック（新規生成のみ対応、マージはスキップ）

## 実装優先度

Medium

## 見積もり

小規模（テンプレート定義 + マージスクリプト + セットアップフロー修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
