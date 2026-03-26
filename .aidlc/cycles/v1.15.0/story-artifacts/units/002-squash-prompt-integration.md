# Unit: プロンプトへのsquash組み込み

## 概要

Unit完了時の手順にsquashスクリプト呼び出しを組み込み、AIプロンプトの指示に従ってsquash処理が自動的に実行されるようにする。

## 含まれるユーザーストーリー

- ストーリー3: プロンプトへのsquash手順組み込み

## 関連Issue

- #187

## 責務

- `prompts/package/prompts/construction.md` のUnit完了時必須作業にsquashスクリプト呼び出しを追加
- git/jj環境の自動判定（`[rules.jj].enabled` 参照）
- ユーザー確認フロー（squash実行前の確認、スキップ可能）
- `docs/aidlc.toml` へのsquash設定追加（必要に応じて）

## 境界

- squashスクリプト自体の実装はUnit 001で完了済み
- Lite版プロンプトへの反映はUnit 005で検討

## 依存関係

### 依存する Unit

- Unit 001: squashスクリプト作成（依存理由: スクリプトが存在しないとプロンプトから呼び出せない）

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

- 変更対象は `prompts/package/prompts/construction.md`（`docs/aidlc/` は直接編集しない）
- jj判定は `docs/aidlc/bin/read-config.sh rules.jj.enabled` で取得
- squashスキップ時は従来の複数コミット動作を維持

## 実装優先度

High

## 見積もり

小規模（プロンプトファイル1箇所の修正）

---

## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-15
- **完了日**: 2026-02-15
- **担当**: Claude
