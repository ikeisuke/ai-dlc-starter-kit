# Unit: Dependabot PR確認オプション

## 概要
Inception PhaseでのDependabot PR確認機能をオプション化し、必要なプロジェクトでのみ有効にできるようにする。

## 含まれるユーザーストーリー
- ストーリー4.1: Dependabot PR確認オプション

## 責務
- aidlc.tomlに`[inception.dependabot].enabled`設定を追加
- 設定に基づくDependabot PR確認の有効/無効切り替え
- 既存のcheck-dependabot-prs.shスクリプトとの連携

## 境界
- Dependabot自体の設定・管理は対象外
- PRのマージ処理は対象外（確認と選択のみ）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub CLI（gh）
- Dependabot設定（プロジェクト側）

## 非機能要件（NFR）
- **パフォーマンス**: GitHub API呼び出しによる遅延（許容範囲）
- **セキュリティ**: GitHub認証が必要
- **スケーラビリティ**: N/A
- **可用性**: gh CLIが利用できない場合は自動スキップ

## 技術的考慮事項
- デフォルトはfalse（既存の挙動を維持）
- 既存のcheck-dependabot-prs.shスクリプトを活用
- inception.mdの該当箇所に設定チェックロジックを追加

## 実装優先度
Low

## 見積もり
小規模（設定追加 + 条件分岐追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
