# Unit: スキルリソース移設・重複削除

## 概要
`docs/aidlc/` から `skills/aidlc/` へのリソース移設、非スキルリソースの再配置、および重複ファイル・ディレクトリの削除を一括で行う。

## 含まれるユーザーストーリー
- ストーリー 1: スキル利用リソースの移設
- ストーリー 2: 非スキルリソースの再配置
- ストーリー 3: docs/aidlc/ の重複削除

## 責務
- `docs/aidlc/guides/` → `skills/aidlc/guides/` への移動
- `docs/aidlc/tests/` → `skills/aidlc/scripts/tests/` への移動
- `docs/aidlc/kiro/` → `kiro/` への移動
- `docs/aidlc/prompts/`, `docs/aidlc/templates/`, `docs/aidlc/lib/` の削除（重複）
- `docs/aidlc/AGENTS.md`, `docs/aidlc/CLAUDE.md` の削除（重複）
- `prompts/package/` の削除（docs/aidlc/ のコピー元、重複）
- `docs/aidlc/` ディレクトリ自体の削除

## 境界
- パス参照の更新は行わない（Unit 002の責務）
- `prompts/setup/` 配下の変更は行わない（Unit 003の責務）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `git mv` を使用して履歴追跡を維持
- 移動先に既存ファイルがある場合（テスト等）はマージ検討

## 対応するIntent項目
- 1: docs/aidlc/ の分解・統合

## 関連Issue
- なし（直接対応するIssueはないが、#450/#449/#448の前提作業）

## 実装優先度
High

## 見積もり
中規模（ファイル移動30+件、既存テストとのマージ判断、git mv による履歴維持の確認が必要）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
