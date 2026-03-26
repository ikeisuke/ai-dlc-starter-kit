# Unit: Issue駆動統合設計

## 概要
AI-DLCサイクル全体（Inception → Construction → Operations）にIssue駆動な仕組みを組み込む方法を検討し、設計を完了する。

## 含まれるユーザーストーリー
- ストーリー 4.1: Issue駆動開発統合の検討と設計
- ストーリー 4.2: Issue駆動開発統合の実装方針決定

## 責務
- GitHubやGitLabのIssue管理とAI-DLCサイクルの連携方法の検討
- Inception、Construction、Operationsの各フェーズでのIssue活用方法の設計
- Issue → Unit → 実装 → クローズのフローの定義
- Issueテンプレートの設計（Epic用、Unit用、バグ用、等）
- 実装の優先順位と範囲の決定
- 設計文書の作成

## 境界
- 実際の実装は含まない（設計のみ、実装は次サイクル以降）
- CI/CDとの統合は含まない（将来の拡張として検討）
- 複雑な自動化は含まない（まずは基本的な連携のみ）

## 依存関係

### 依存する Unit
- **Unit 4: サイクル管理基盤**（依存理由: サイクル管理の仕組みを理解した上でIssue統合を設計するため）

### 外部依存
- GitHub または GitLab の Issue機能
- GitHub API または GitLab API（将来の自動化で使用）

## 非機能要件（NFR）
- **パフォーマンス**: 設計段階では不要
- **セキュリティ**: APIトークンが必要な場合は環境変数で管理（将来の実装時）
- **スケーラビリティ**: 数百のIssueに対応できる設計
- **可用性**: オフライン環境でも開発可能であること

## 技術的考慮事項
- **Issueテンプレートの種類**:
  - Epic用（複数Unitをまとめる）
  - Unit用（1つのUnitに対応）
  - バグ用（単発のバグ修正）
  - タスク用（小さな改善）

- **IssueとAI-DLCサイクルの対応付け**:
  - Epic → Intent
  - Unit Issue → Unit定義
  - Issue → ユーザーストーリー
  - ラベルでフェーズを管理（`phase:inception`, `phase:construction`, `phase:operations`）
  - マイルストーンでサイクルを管理（`v1.0.1`, `v1.0.2`, 等）

- **Issue駆動フロー**:
  1. Inception Phase: Intentに基づいてEpic Issueを作成
  2. Inception Phase: EpicをUnit Issueに分解
  3. Construction Phase: Unit Issueを実装し、進捗を更新
  4. Construction Phase: 実装完了時にUnit Issueをクローズ
  5. Operations Phase: 運用中に発見したバグや改善点をIssueとして記録
  6. Operations Phase: 次サイクルのEpic Issueを作成

- **自動化の可能性**（将来の拡張）:
  - Unit完了時にIssueを自動クローズ
  - progress.mdとIssueステータスの同期
  - Issueコメントにコミットやプルリクエストをリンク

## 実装優先度
Medium

## 見積もり
- 調査: 1.5時間
- 検討と設計: 3時間
- Issueテンプレート作成: 1.5時間
- フロー定義: 1.5時間
- 設計文書作成: 2時間
- 実装方針決定: 1時間
- 合計: 10.5時間
