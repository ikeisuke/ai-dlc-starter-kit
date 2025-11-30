# Inception Phase: Unit 8 追加計画

## 背景
Construction Phase（Unit 2実行準備中）にて、`prompts/setup-prompt.md` が1746行に達し、Claude Codeでの読み込みに支障が出ていることが判明しました。セットアップファイルは全フェーズの起点であり、読み込めないと今後の作業に大きな影響があるため、**緊急性が高い**と判断し、専用Unitを作成して対応します。

## 目的
- セットアップファイルを適切なサイズに分割
- 可読性と保守性の向上
- Claude Codeでの確実な読み込みを保証

## 作業内容

### ステップ3: ユーザーストーリー追加
`docs/cycles/v1.0.1/story-artifacts/user_stories.md` に新しいEpicとストーリーを追加

**Epic: プロンプトファイルの構造最適化**

**ストーリー 8.1: セットアップファイルの分割**
- 優先順位: Critical（緊急）
- 1746行のセットアップファイルを複数ファイルに分割
- 各ファイルは500行以内を目安に
- 分割後も既存の機能・動作を維持

### ステップ4: Unit定義追加
`docs/cycles/v1.0.1/story-artifacts/units/unit8_setup_file_split.md` を作成

**Unit 8: セットアップファイル分割**
- 責務: セットアップファイルを読み込み可能なサイズに分割
- 依存関係: なし（独立）
- 優先度: Critical
- 見積もり: 3時間

### ステップ6: Construction用進捗管理ファイル更新
`docs/cycles/v1.0.1/construction/progress.md` にUnit 8を追加
- 状態: 未着手
- 優先度: Critical（最優先）
- 見積もり: 3時間

## 完了基準
- [ ] user_stories.md に Epic と ストーリー 8.1 追加
- [ ] unit8_setup_file_split.md 作成
- [ ] construction/progress.md にUnit 8追加
- [ ] inception/progress.md 更新（バックトラック記録）
- [ ] history.md 追記
- [ ] Gitコミット

## 次のステップ
Inception Phase完了後、Construction Phaseに戻り、Unit 8を最優先で実施
