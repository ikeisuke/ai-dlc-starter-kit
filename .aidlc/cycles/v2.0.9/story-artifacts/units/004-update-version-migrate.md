# Unit: update-version.sh修正・migrate-*.shガイドライン準拠

## 概要
update-version.sh のスキル内 version.txt 更新対応と、migrate-*.sh のパス解決をscript-design-guideline.md準拠に修正する。

## 含まれるユーザーストーリー
- ストーリー 6: update-version.sh のスキル内 version.txt 更新対応
- ストーリー 7: migrate-*.sh のscript-design-guideline準拠確認

## 責務
- update-version.sh に skills/aidlc/version.txt と skills/aidlc-setup/version.txt の更新ロジックを追加（#479）
- migrate-*.sh のパス解決を git rev-parse --show-toplevel ベースに統一（#480）

## 境界
- update-version.sh の既存の引数体系（--version, --dry-run）は変更しない
- migrate-*.sh のインターフェイス（引数・終了コード）は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- update-version.sh: dry-run 時にも新しい対象ファイルが表示されることを確認
- migrate-*.sh: SCRIPT_DIR 変数の定義と AIDLC_PROJECT_ROOT の解決パターンを統一

## 関連Issue
- #479
- #480

## 実装優先度
Medium

## 見積もり
中（スクリプト実装修正2件）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
