# セットアッププロンプトの統合・整理

- **発見日**: 2025-12-20
- **発見フェーズ**: Operations
- **発見サイクル**: v1.5.0
- **優先度**: 中

## 概要

prompts/ 配下のセットアップ関連ファイルを整理・統合する。

## 詳細

現在のセットアップ関連ファイル:
- `prompts/setup-prompt.md` - エントリーポイント
- `prompts/setup-init.md` - 初回セットアップ/アップグレード
- `prompts/setup-cycle.md` - サイクル開始
- `prompts/package/prompts/setup.md` - プロジェクト内のサイクル開始

これらのファイル間で責務が重複・分散しており、統合できる可能性がある。

### 検討事項
- setup-cycle.md と prompts/package/prompts/setup.md の統合
- エントリーポイント（setup-prompt.md）の簡素化
- スターターキット側とプロジェクト側の責務分離の明確化

## 対応案

- ファイル構成を見直し、重複を排除
- 責務を明確に分離
- ドキュメントを更新
