# ステップ2: 既存コード分析 計画

## 作成するファイル
- `docs/cycles/v1.2.3/requirements/existing_analysis.md`

## 分析対象

### 1. Lite版プロンプトのパス解決が不安定
- `docs/aidlc/prompts/lite/inception.md`
- `docs/aidlc/prompts/lite/construction.md`
- `docs/aidlc/prompts/lite/operations.md`

### 2. フェーズ遷移のガードレールが不足
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/construction.md`
- `docs/aidlc/prompts/operations.md`
- `prompts/setup-prompt.md`
- `prompts/setup-cycle.md`

### 3. aidlc.toml に starter_kit_version フィールドがない
- `prompts/setup-init.md`
- `prompts/package/aidlc.toml`（テンプレート）
- `prompts/setup-prompt.md`（バージョン参照箇所）

### 4. 旧バージョンからの移行時にファイル削除確認がない
- `prompts/setup-prompt.md`（rsync処理箇所）

### 5. 日時記録時に毎回現在時刻を取得していない
- 各プロンプトの日時記録に関する記述

## 作業内容
1. 上記ファイルの関連箇所を確認
2. 問題の根本原因を特定
3. 修正方針を existing_analysis.md に記録
