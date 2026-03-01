# Amazon AI-DLC リポジトリ調査レポート

**調査日**: 2026-03-01
**調査者**: @claude
**関連Issue**: #218
**関連Unit**: Unit 005（Amazon AIDLCリポジトリ調査）

---

## セクション1: 対象リポジトリの概要

### リポジトリ情報

| 項目 | 内容 |
|------|------|
| リポジトリ名 | awslabs/aidlc-workflows |
| URL | https://github.com/awslabs/aidlc-workflows |
| ブランチ | main |
| ライセンス | MIT-0 |
| 作成日 | 2025-11-13 |
| 最終更新 | 2026-03-01（調査時点） |
| Stars / Forks | 516 / 115 |
| コミット数 | 約95 |

### 規模

| 項目 | 内容 |
|------|------|
| 総ファイル数 | 約40ファイル |
| プロンプト/ルールファイル数 | 約25ファイル（`aidlc-rules/` 配下） |
| ディレクトリ深さ | 最大6階層（`aidlc-rules/aws-aidlc-rule-details/extensions/security/baseline/`） |

### 技術スタック

Markdownベースのプロンプト定義のみ。プログラミング言語への依存なし。`cliff.toml`（changelog生成ツール設定）を除き、ツール固有の設定ファイルは含まない。

### 目的

AI-Driven Life Cycle（AI-DLC）の適応型ワークフロー制御ルールを提供するリポジトリ。AIコーディングエージェントに対して、ソフトウェア開発ライフサイクル全体を通じた構造化されたワークフローを提供する。

### ディレクトリ構成

```
awslabs/aidlc-workflows/
├── aidlc-rules/
│   ├── aws-aidlc-rules/
│   │   └── core-workflow.md          # 主要ワークフロー定義
│   └── aws-aidlc-rule-details/
│       ├── common/
│       │   ├── process-overview.md
│       │   ├── terminology.md
│       │   ├── depth-levels.md
│       │   ├── session-continuity.md
│       │   ├── overconfidence-prevention.md
│       │   ├── error-handling.md
│       │   ├── content-validation.md
│       │   └── ascii-diagram-standards.md
│       ├── inception/
│       │   ├── workspace-detection.md
│       │   ├── reverse-engineering.md
│       │   ├── requirements-analysis.md
│       │   ├── user-stories.md
│       │   ├── workflow-planning.md
│       │   ├── application-design.md
│       │   └── units-generation.md
│       ├── construction/
│       │   ├── functional-design.md
│       │   ├── nfr-requirements.md
│       │   ├── nfr-design.md
│       │   └── infrastructure-design.md
│       ├── operations/
│       │   └── operations.md
│       └── extensions/
│           └── security/
│               └── baseline/
│                   └── security-baseline.md
├── assets/images/                     # IDE統合のスクリーンショット
├── cliff.toml
└── README.md
```

### 対応プラットフォーム

| プラットフォーム | 統合方法 |
|----------------|----------|
| Kiro（IDE / CLI） | ネイティブサポート |
| Amazon Q Developer | IDEプラグイン |
| Cursor IDE | Project Rules / AGENTS.md |
| Cline | .clinerules ディレクトリ |
| Claude Code | CLAUDE.md |
| GitHub Copilot | .github/copilot-instructions.md |

---

## セクション2: 4軸比較表

### 軸1: プロンプト構成・構造（prompt_structure）

| 比較項目 | 本プロジェクト（AI-DLC Starter Kit） | Amazon（aidlc-workflows） | 差分 | Evidence |
|----------|--------------------------------------|---------------------------|------|----------|
| ファイル構造 | フェーズ別プロンプト（`inception.md` / `construction.md` / `operations.md`）+ `common/` 共有ファイル | 1つの `core-workflow.md` + `rule-details/` 配下にフェーズ別・共通の詳細ルールファイル群 | Amazonは1つのコアファイルから詳細ルールを参照する階層型。本PJはフェーズ毎に独立したエントリポイント | file: `docs/aidlc/prompts/` / url: `aidlc-rules/aws-aidlc-rules/core-workflow.md` |
| プラットフォーム対応 | 現時点でClaude Codeが主要実装先（CLAUDE.md）。設計思想としてはプラットフォーム非依存 | マルチプラットフォーム対応（6プラットフォーム） | Amazonは複数プラットフォームを明示的にサポート。本PJは設計上プラットフォーム非依存だが現在の実装はClaude Code向け | url: `README.md`（セットアップ手順に各プラットフォーム記載） |
| 共通ルール管理 | `common/` ディレクトリに共有ファイル（compaction, review-flow, agents-rules 等） | `common/` ディレクトリに8ファイル（terminology, depth-levels, overconfidence-prevention 等） | 共通ルール分離のアプローチは同一。Amazon側は用語定義やDepth Levelsなど概念的ルールが充実 | file: `docs/aidlc/prompts/common/` / url: `aws-aidlc-rule-details/common/` |
| 拡張機能 | Skill機能（reviewing-*, setup 等）で機能拡張 | `extensions/` ディレクトリでセキュリティ等を拡張 | 拡張アーキテクチャの思想は類似。実装方法が異なる（Skill vs ディレクトリ構造） | file: `docs/aidlc/prompts/common/skills/` / url: `aws-aidlc-rule-details/extensions/` |

### 軸2: フェーズ・ワークフロー設計（workflow_design）

| 比較項目 | 本プロジェクト（AI-DLC Starter Kit） | Amazon（aidlc-workflows） | 差分 | Evidence |
|----------|--------------------------------------|---------------------------|------|----------|
| フェーズ構成 | 3フェーズ: Inception / Construction / Operations | 3フェーズ: Inception / Construction / Operations | 同一の3フェーズ構成 | file: `docs/aidlc/prompts/AGENTS.md` / url: `core-workflow.md` |
| フェーズ内構造 | Phase 1（設計）/ Phase 2（実装）の2段階構成 | 各フェーズ内に複数ステージ。ステージは Always-execute / Conditional に分類 | Amazonはステージ単位のきめ細かい制御（実行/スキップ判定）。本PJは2段階の固定フロー | url: `core-workflow.md`（INCEPTION PHASE セクション） |
| ワークフロー制御 | 固定的な順次実行。ユーザー承認ゲートで制御 | Workflow Planningステージで動的にステージ選択。問題の複雑度に応じてステージを Execute / Skip | Amazonは適応型（問題に応じてステージを取捨選択）。本PJは全ステップ順次実行 | url: `aws-aidlc-rule-details/inception/workflow-planning.md` |
| 詳細度制御 | なし（一律の詳細度） | Depth Levels: Minimal / Standard / Comprehensive。問題の複雑度に応じて成果物の詳細度を適応的に変更 | Amazon独自のDepth Levels概念。シンプルな問題にはMinimal、複雑な問題にはComprehensiveを適用 | url: `aws-aidlc-rule-details/common/depth-levels.md` |
| 作業分割 | Unit単位の逐次実行。Unit定義はInceptionで固定 | Unit of Work（UoW）単位。Workflow Planningで動的に決定 | 類似のUnit概念だが、Amazonはワークフロー計画時に動的生成 | file: `docs/cycles/v1.18.0/story-artifacts/units/` / url: `aws-aidlc-rule-details/inception/units-generation.md` |
| Reverse Engineering | なし | 既存コードベースの解析ステージ（Conditional） | Amazonは既存プロジェクトの構造を自動解析する専用ステージを持つ | url: `aws-aidlc-rule-details/inception/reverse-engineering.md` |

### 軸3: 自動化・ツール連携（automation）

| 比較項目 | 本プロジェクト（AI-DLC Starter Kit） | Amazon（aidlc-workflows） | 差分 | Evidence |
|----------|--------------------------------------|---------------------------|------|----------|
| 状態管理 | シェルスクリプト群（28個）+ GitHub Issue/PR連携 | `aidlc-state.md` ファイルベースの状態管理 + `audit.md` 監査ログ | 本PJはスクリプト駆動型、AmazonはMarkdownファイルベース | file: `docs/aidlc/bin/` / url: `core-workflow.md`（State Management セクション） |
| 進捗追跡 | バックログ管理、Issue管理、PRフロー | チェックボックス完了追跡（`[x]` マーク即時更新） | 本PJはGitHub統合の高度な管理、Amazonはシンプルなチェックボックス方式 | file: `docs/aidlc/bin/issue-ops.sh` / url: `core-workflow.md`（Checkbox Enforcement） |
| 質問管理 | テキストベース + AskUserQuestion機能 | 専用 `.md` ファイルに `[Answer]:` タグ形式で記録 | Amazonは質問と回答をファイルに永続化。セッション再開時に参照可能 | url: `aws-aidlc-rule-details/common/session-continuity.md` |
| セッション継続 | compaction指示による部分的サポート | `session-continuity.md` で詳細な再開テンプレートを提供。`aidlc-state.md` を読み込み前回の状態を復元 | Amazonはセッション中断・再開を正式にサポート | url: `aws-aidlc-rule-details/common/session-continuity.md` |
| GitHub統合 | 充実: Issue作成・クローズ、PR作成・マージ、バックログ管理、ラベル管理 | なし（VCS非依存） | 本PJの大きな優位性。GitHubワークフローとの深い統合 | file: `docs/aidlc/bin/issue-ops.sh`, `docs/aidlc/bin/squash-unit.sh` |
| スクリプト | 28個のシェルスクリプト（write-history.sh, issue-ops.sh, squash-unit.sh 等） | なし（プロンプトルールのみ） | 本PJはシェルスクリプトによる自動化が充実。Amazonはスクリプト非依存 | file: `docs/aidlc/bin/` |

### 軸4: 品質管理・レビュープロセス（quality_management）

| 比較項目 | 本プロジェクト（AI-DLC Starter Kit） | Amazon（aidlc-workflows） | 差分 | Evidence |
|----------|--------------------------------------|---------------------------|------|----------|
| レビュー方式 | reviewing-* Skills（code/architecture/security/inception）による多面的AIレビュー | Content Validation（ファイル作成前の内容検証） | 本PJはレビューSkillによる多段レビュー、Amazonはファイル作成時の事前検証 | file: `docs/aidlc/prompts/common/review-flow.md` / url: `aws-aidlc-rule-details/common/content-validation.md` |
| レビューフロー | 反復最大3回、指摘対応判断、千日手検出 | 定義なし（Content Validationは作成時のみ） | 本PJのレビューフローは高度に構造化されている | file: `docs/aidlc/prompts/common/review-flow.md` |
| セキュリティ | reviewing-security Skill（OWASP準拠） | Security Extension: 15個のSECURITYルール（OWASP準拠）。拡張機能として組み込み | 両者ともOWASP準拠。Amazonは拡張機能（Extension）アーキテクチャ、本PJはSkillとして実装 | file: `docs/aidlc/prompts/common/skills/reviewing-security.md` / url: `aws-aidlc-rule-details/extensions/security/baseline/security-baseline.md` |
| 過信防止 | 明示的な定義なし | Overconfidence Prevention: 「迷ったら質問する」原則を明文化 | Amazon独自の概念。AIの過信によるエラーを防止する仕組み | url: `aws-aidlc-rule-details/common/overconfidence-prevention.md` |
| コンテンツ品質 | 明示的な定義なし | ASCII図・Mermaid図の検証ルール。ファイル作成前の必須バリデーション | Amazon独自のContent Validation。図の品質を保証 | url: `aws-aidlc-rule-details/common/content-validation.md`, `aws-aidlc-rule-details/common/ascii-diagram-standards.md` |
| エラーハンドリング | 暗黙的（レビュー指摘への対応） | 明示的なエラーハンドリング定義。重大度レベル（Critical/High/Medium/Low）と各フェーズの復旧手順 | Amazonはエラーの分類と復旧手順を体系化 | url: `aws-aidlc-rule-details/common/error-handling.md` |
| 監査証跡 | write-history.sh による履歴記録 | `audit.md` に ISO 8601 タイムスタンプ付きで完全な入力ログを記録 | 両者とも履歴管理あり。Amazonはユーザー入力の完全ログを重視 | file: `docs/aidlc/bin/write-history.sh` / url: `core-workflow.md`（Audit Trail セクション） |

---

## セクション3: 差分・共通点の分析

### 主要な共通点

1. **3フェーズ構造**: 両プロジェクトとも Inception / Construction / Operations の3フェーズでソフトウェア開発ライフサイクルを構造化
2. **Unit単位の作業分割**: 作業をUnit（UoW）単位に分割し、管理可能な粒度で実行する設計思想が共通
3. **ユーザー承認ゲート**: 重要な意思決定ポイントでユーザー承認を必須とするガバナンスモデル
4. **質問駆動型の対話**: AIが不明点を質問し、ユーザーの意図を確認しながら進めるプロセス
5. **OWASP準拠のセキュリティ**: セキュリティレビューにOWASP基準を採用
6. **共通ルールの分離**: フェーズ横断のルールを `common/` ディレクトリに分離する構造

### 主要な差分

| 差分 | Amazon側のアプローチ | 本PJ側のアプローチ | 優位性評価 |
|------|---------------------|--------------------|-----------|
| プラットフォーム対応 | 6プラットフォーム対応（汎用設計） | 現時点でClaude Codeが主要実装先（設計上はプラットフォーム非依存） | **Amazon優位**: 複数プラットフォームを明示的にサポート。本PJは今後の拡張余地あり |
| ワークフロー制御 | Workflow Planning（動的ステージ選択） | 固定フロー（Phase 1→Phase 2） | **Amazon優位**: 問題の複雑度に応じた適応的な制御。不要なステップの省略が可能 |
| 詳細度制御 | Depth Levels（Minimal/Standard/Comprehensive） | 一律の詳細度 | **Amazon優位**: シンプルな問題に過剰な成果物を作らない効率性 |
| 状態管理 | Markdownファイルベース（aidlc-state.md） | シェルスクリプト群 + GitHub連携 | **本PJ優位**: GitHubとの統合による高度な管理。ただし依存度が高い |
| GitHub統合 | なし | 充実（Issue/PR/バックログ/ラベル管理） | **本PJ優位**: 実開発ワークフローとの密な連携 |
| セキュリティ | Extension（拡張機能）として組み込み | Skill（独立機能）として分離 | **同等**: アプローチは異なるが、OWASPカバレッジは同等レベル |
| 過信防止 | 明示的な原則として定義 | 暗黙的 | **Amazon優位**: AIの過信問題を正面から扱い、明文化している |
| セッション継続 | 正式サポート（状態ファイル + 再開テンプレート） | compaction指示による部分的サポート | **Amazon優位**: 長時間タスクのセッション断を正式に考慮 |
| レビューフロー | Content Validation（作成時検証） | 多段AIレビュー（反復3回、千日手検出） | **本PJ優位**: 構造化されたレビュープロセスが充実 |
| Reverse Engineering | 専用ステージとして定義 | なし | **Amazon優位**: 既存プロジェクトへの適用を正式にサポート |

### 設計思想の違い

- **Amazon**: 「概念定義型」 - AI-DLCのコア概念（Depth Levels、Overconfidence Prevention等）を体系的に定義。マルチプラットフォーム対応で汎用的な適応型ワークフローを提供
- **本PJ**: 「ワークフロー基盤型」 - GitHub統合・シェルスクリプト群・レビューフローなど、開発ワークフローの実行基盤に注力。プラットフォーム非依存の設計思想

両アプローチは相互補完的であり、Amazon側の概念定義を参照元として活用しつつ、本PJはワークフロー基盤に集中するという戦略が有効。

---

## セクション4: 取り込み候補リスト

| # | タイトル | 概要 | 優先度 | 難易度 | 影響度 | 関連軸 | 補足 |
|---|---------|------|--------|--------|--------|--------|------|
| 1 | Overconfidence Prevention原則 | AIの過信防止を明文化し、「迷ったら質問する」原則をプロンプトに組み込む | P0 | S | 4 | quality_management | プロンプトへの追記のみで適用可能。既存のAskUserQuestion活用と整合性が高い |
| 2 | Depth Levels概念の導入 | Minimal/Standard/Comprehensiveの3段階で成果物の詳細度を適応的に制御する仕組みを導入 | P1 | M | 4 | workflow_design | 全フェーズのプロンプトに判定ロジック追加が必要。シンプルなタスクの効率向上が期待される |
| 3 | Reverse Engineeringステージ | 既存コードベースを解析し、構造・パターンを把握する専用ステージをInceptionに追加 | P1 | M | 3 | workflow_design | 既存プロジェクトへのAI-DLC適用時に有用。新規プロジェクトでは不要（Conditional） |
| 4 | Audit Trail強化 | ユーザー入力のISO 8601タイムスタンプ付き完全ログを記録する仕組みを強化 | P1 | S | 3 | automation | 既存のwrite-history.shの拡張で対応可能。デバッグやトレーサビリティ向上 |
| 5 | Security Extension（ルールベースセキュリティ） | セキュリティルールを拡張機能として体系化。15個のSECURITYルールの構造を参考に本PJのreviewing-securityを強化 | P1 | L | 4 | quality_management | 既存のreviewing-security Skillのルール網羅性を検証・強化。大規模だが段階的に適用可能 |
| 6 | Content Validation（ASCII図・Mermaid検証） | ファイル作成前にASCII図やMermaid図の正確性を検証するバリデーションルールを追加 | P2 | M | 3 | quality_management | 図の品質保証に有効だが、本PJでの図の使用頻度に応じて優先度を判断 |
| 7 | Workflow Planning（動的ステージ選択） | 問題の複雑度に応じてフェーズ内のステップを動的にExecute/Skip判定する仕組み | P2 | L | 5 | workflow_design | アーキテクチャレベルの変更が必要。効果は大きいが、本PJの固定フローの安定性とのトレードオフ |
| 8 | マルチプラットフォーム対応 | Claude Code以外のAIコーディングエージェント（Cursor、Cline等）への対応 | P2 | L | 3 | prompt_structure | 現時点では優先度低。需要が発生した時点で検討。プロンプト構造の抽象化が必要 |
| 9 | Error Handling体系化 | エラーの重大度レベル（Critical/High/Medium/Low）と各フェーズの復旧手順を明示的に定義 | P1 | M | 3 | quality_management | Amazon側の `error-handling.md` を参考に、本PJのエラー対応を体系化 |
| 10 | Session Continuity（セッション継続） | セッション中断・再開を正式にサポートする仕組み。状態ファイル読み込みによる前回状態の復元 | P1 | M | 4 | automation | 長時間タスクのセッション断は実運用で頻発。既存のcompaction指示を発展させる形で実現可能 |
| 11 | Terminology/Glossary（用語集） | プロジェクト横断の用語定義ファイルを整備。AI-DLC固有の用語を統一的に管理 | P2 | S | 2 | prompt_structure | Amazon側の `terminology.md` を参考。本PJではドメインモデルのユビキタス言語で部分的にカバー済み |

### 優先度別サマリ

- **P0（即座に取り込むべき）**: 1件 - Overconfidence Prevention原則
- **P1（次サイクルで検討）**: 6件 - Depth Levels、Reverse Engineering、Audit Trail強化、Security Extension、Error Handling体系化、Session Continuity
- **P2（将来検討）**: 4件 - Content Validation、Workflow Planning、マルチプラットフォーム対応、Terminology/Glossary

### 戦略的方向性

Amazon側のAI-DLCリポジトリはコア概念（Depth Levels、Overconfidence Prevention、Content Validation等）の体系的な定義に強みがある。一方、本PJはワークフロー実行基盤（GitHub統合、シェルスクリプト群、レビューフロー）に強みがある。

**推奨アプローチ**: Amazon側が定義した概念を参照元として活用し、本PJでは車輪の再発明を避ける。本PJの開発リソースはワークフロー基盤の強化に集中する。

具体的には：
- **概念の取り込み**（#1, #2, #3 等）: Amazon側の概念定義を参考に、本PJのプロンプトに自然な形で組み込む
- **ワークフロー基盤の強化**（#10 等）: 本PJ独自の強みであるGitHub統合やスクリプト自動化をさらに発展
- **重複開発の回避**: Amazon側で十分に定義されている概念は、独自に再定義せず参照する方針

---

## 調査制約

- Amazon側リポジトリの情報は2026-03-01時点のスナップショット
- 本プロジェクトとの比較は `cycle/v1.18.0` ブランチ時点の状態
- Operations Phaseの比較はAmazon側の実装が限定的（`operations.md` のみ）なため、深い比較は困難
