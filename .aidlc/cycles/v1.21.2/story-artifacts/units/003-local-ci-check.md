# Unit: ローカルCIチェック組み込み

## 概要
Operations PhaseにBash Substitution Checkのローカル実行を組み込み、PRオープン前にCIエラーを検出する。

## 含まれるユーザーストーリー
- ストーリー4: ローカルCIチェック組み込み (#311)

## 関連Issue
- #311

## 責務
- `operations-release.md` のステップ6.4にBash Substitution Check実行手順を追加
- 違反検出時のエラー報告と修正フロー

## 境界
- `bin/check-bash-substitution.sh` 自体の修正は行わない（既存のまま使用）
- CI側（GitHub Actions）の設定は変更しない

## 依存関係

### 依存する Unit
なし

### 外部依存
- `bin/check-bash-substitution.sh`（既存スクリプト）

## 非機能要件（NFR）
- **パフォーマンス**: 実行時間がMarkdownlintと同程度であること

## 技術的考慮事項
- `prompts/package/prompts/operations-release.md` を編集
- ステップ6.4の既存Markdownlintチェックの後に追加

## 実装優先度
Medium

## 見積もり
小規模（プロンプト1ファイルへの追記）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-14
- **完了日**: 2026-03-14
- **担当**: AI
