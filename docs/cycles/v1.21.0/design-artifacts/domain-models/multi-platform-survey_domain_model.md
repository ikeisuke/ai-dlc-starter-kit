# ドメインモデル: マルチプラットフォーム対応調査

## 概要

マルチプラットフォーム対応状況の調査・分析・提案に関するドメイン概念を定義する。本Unitは調査ドキュメントの作成に特化しており、新たなエンティティや集約は導入しない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

本Unitでは新規エンティティの導入はなし。

## 値オブジェクト（Value Object）

### PlatformCapability

- **属性**:
  - agentName: String - AIエージェント名（例: `Claude Code`, `KiroCLI`）
  - featureName: String - 機能名（例: `設定ファイル`, `スキル連携`）
  - supportLevel: Enum - 対応レベル（`supported`, `partial`, `unsupported`）
  - evidence: String - 判定根拠（設定ファイルパス、公式ドキュメント参照等）
  - constraint: String | null - 制約内容（部分対応時の制限事項）
  - alternative: String | null - 代替手段（部分対応・未対応時の回避策）
- **不変性**: 調査時点のスナップショットとして固定（バージョン間で変化しうるが、本サイクルのドキュメントとしては不変）
- **等価性**: agentName + featureName の組み合わせで一意

### PlatformSpecificExpression

- **属性**:
  - expression: String - 固有表現（例: `Writeツール`, `AskUserQuestion`）
  - category: String - 分類（例: `ツール名`, `機能名`, `ディレクトリ参照`）
  - filePaths: List<String> - 使用箇所のファイルパス
  - portability: Enum - 移植性（`portable`: 他エージェントでも解釈可能, `adaptation_needed`: 読み替え必要, `claude_only`: Claude Code専用機能）
- **不変性**: 調査時点のスナップショットとして固定
- **等価性**: expression が同一であれば同一の固有表現を指す

### PriorityProposal

- **属性**:
  - title: String - 提案タイトル
  - priority: Enum - 優先度（`high`, `medium`, `low`）
  - rationale: String - 理由
  - affectedAgents: List<String> - 影響を受けるエージェント
  - estimatedEffort: String - 概算規模（例: `小規模`, `中規模`, `大規模`）
- **不変性**: 提案時点の評価として固定
- **等価性**: title が同一であれば同一の提案を指す

## 集約（Aggregate）

本Unitでは新規集約の導入はなし。調査結果は静的ドキュメントとして出力される。

## ドメインサービス

### PlatformAnalyzer

- **責務**: 収集された事実データ（PlatformCapability一覧）から、ギャップ分析を行い、未対応・部分対応項目の影響度を評価する
- **操作**:
  - analyzeGaps(capabilities: List<PlatformCapability>) → ギャップ分析結果
- **I/O責務の分離**: 分析ロジックのみを担い、ドキュメントのフォーマッティングは出力層が担う

### ProposalGenerator

- **責務**: ギャップ分析結果とClaude Code固有表現データから、次期サイクルへの優先対応提案を生成する
- **操作**:
  - generateProposals(gaps: ギャップ分析結果, expressions: List<PlatformSpecificExpression>) → List<PriorityProposal>

## リポジトリインターフェース

本Unitでは不要（永続化対象なし。調査結果は静的ドキュメントとして出力）。

## ユビキタス言語

- **対応状況マトリクス（Capability Matrix）**: AIエージェント × 機能の対応レベルを一覧化した表
- **ギャップ（Gap）**: AI-DLCの機能が特定のエージェントで未対応または部分対応である状態
- **固有表現（Platform-Specific Expression）**: 特定のAIエージェントでのみ意味を持つツール名・機能名・設定パス
- **移植性（Portability）**: 固有表現が他のエージェントでどの程度そのまま利用可能かの度合い
- **優先対応提案（Priority Proposal）**: ギャップを解消するための次期サイクルでの作業提案

## 不明点と質問（設計中に記録）

なし
