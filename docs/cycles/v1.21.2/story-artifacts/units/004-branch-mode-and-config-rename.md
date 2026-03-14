# Unit: ブランチ設定化と個人設定リネーム

## 概要
`rules.branch.mode` 設定をプロンプトに正式追加し、個人設定ファイルを `aidlc.toml.local` から `aidlc.local.toml` にリネームする。

## 含まれるユーザーストーリー
- ストーリー5: ブランチ作成方式の設定化
- ストーリー6: 個人設定ファイルのリネーム

## 関連Issue
なし（バックログ外の改善）

## 責務
- `aidlc.toml` のテンプレートに `[rules.branch]` セクションを追加
- `inception.md` のステップ7のロジックが既存設定を参照することを確認
- `read-config.sh` で `aidlc.local.toml`（新名）を優先、`aidlc.toml.local`（旧名）をフォールバック
- `.gitignore` に新名を追加（旧名も残す）
- プロンプト・ガイド内の旧名参照を新名に更新

## 境界
- `read-config.sh` の設定階層ロジック自体は変更しない（ファイル名のみ変更）
- `aidlc.toml` の既存キーの意味や互換性を壊す再編成は行わない（`[rules.branch]` セクションの新規追加は許容）

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 影響なし
- **セキュリティ**: 影響なし

## 技術的考慮事項
- 更新対象ドキュメント: `inception.md`, `common/rules.md`, `guides/config-merge.md`
- 検証: `grep -r "aidlc.toml.local" prompts/package/` で旧名残存がないこと（`.gitignore` と `read-config.sh` のフォールバック処理を除く）
- 旧名のみ存在時は警告表示: 「aidlc.local.toml へのリネームを推奨します」
- 両方存在時は新名を優先

## 実装優先度
Medium

## 見積もり
中規模（スクリプト1ファイル修正 + プロンプト・ガイド複数ファイル更新）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-03-14
- **完了日**: -
- **担当**: AI
