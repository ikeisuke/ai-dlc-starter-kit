# 共通セットアップ処理

このファイルは `prompts/setup-prompt.md` から参照されます。

---

## 変数置換ルール【重要】

### 表記揺れ防止の原則

プロンプトファイル生成時は以下を**厳守**：
1. テンプレート（コードブロック内）を**そのままコピー**する
2. 下記の変数（`{{VAR}}`形式）**のみ**を対応する値に置換する
3. **文章の修正・改善・言い換えは禁止**
4. 変数以外の部分は**一切変更しない**

### 置換対象の変数一覧

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `{{PROJECT_NAME}}` | プロジェクト名 | AI-DLC Starter Kit |
| `{{CYCLE}}` | サイクル識別子 | v1.0.1 |
| `{{BRANCH}}` | ブランチ名 | feature/v1.0.1 |
| `{{DEVELOPMENT_TYPE}}` | 開発タイプ | greenfield / brownfield |
| `{{PROJECT_TYPE}}` | プロジェクトタイプ | ios / android / web / backend / general |
| `{{AIDLC_ROOT}}` | 共通ファイルルート | docs/aidlc |
| `{{CYCLES_ROOT}}` | サイクルルート | docs/cycles |
| `{{ROLE_INCEPTION}}` | Inception役割 | プロダクトマネージャー兼ビジネスアナリスト |
| `{{ROLE_CONSTRUCTION}}` | Construction役割 | ソフトウェアアーキテクト兼エンジニア |
| `{{ROLE_OPERATIONS}}` | Operations役割 | DevOpsエンジニア兼SRE |
| `{{SETUP_PROMPT_PATH}}` | セットアッププロンプトのパス | /path/to/setup-prompt.md |
| `{{PROJECT_SUMMARY}}` | プロジェクト概要（1行） | [セットアップ時に設定] |
| `{{LANGUAGE}}` | 使用言語 | 日本語 |
| `{{DEVELOPER_EXPERTISE}}` | 開発者の専門分野 | ソフトウェア開発 |
| `{{PROJECT_README}}` | プロジェクトREADMEパス | /README.md |
| `{{CYCLE_TYPE}}` | サイクルタイプ | Full / Lite |

### 禁止事項

- テンプレートの文章構造を変更する
- 説明を追加・削除する
- 表現を「より良く」しようとする
- 変数以外の部分を編集する

**理由**: 表記揺れを防ぎ、バージョンアップ時の差分を最小限にするため

---

## 1. ディレクトリ構成の作成

以下の構造を作成：
```
{{AIDLC_ROOT}}/                    # 共通プロンプト・テンプレート
├── prompts/
│   ├── inception.md
│   ├── construction.md
│   ├── operations.md
│   ├── additional-rules.md
│   ├── prompt-reference-guide.md
│   └── lite/                      # Lite版プロンプト
│       ├── inception.md
│       ├── construction.md
│       └── operations.md
├── templates/
│   └── index.md
├── operations/                    # 運用引き継ぎ情報
│   ├── handover.md
│   └── README.md
└── version.txt

{{CYCLES_ROOT}}/{{CYCLE}}/         # サイクル固有成果物
├── .lite                          # Lite版サイクルの場合のみ作成
├── plans/
├── requirements/
├── story-artifacts/
│   └── units/
├── design-artifacts/
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── inception/
├── construction/
│   └── units/
├── operations/
└── history.md
```

**作成手順**:
1. `mkdir -p` で各ディレクトリを作成
2. 各ディレクトリに `.gitkeep` ファイルを配置
3. **Lite版サイクルの場合のみ**: `{{CYCLES_ROOT}}/{{CYCLE}}/.lite` ファイルを作成（内容: 「このサイクルはLite版です。」）

対象ディレクトリ（共通）:
- `{{AIDLC_ROOT}}/prompts/`
- `{{AIDLC_ROOT}}/prompts/lite/`
- `{{AIDLC_ROOT}}/templates/`
- `{{AIDLC_ROOT}}/operations/`

対象ディレクトリ（サイクル固有）:
- `{{CYCLES_ROOT}}/{{CYCLE}}/plans/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/requirements/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/story-artifacts/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/story-artifacts/units/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/domain-models/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/logical-designs/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/architecture/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/inception/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/construction/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/construction/units/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/operations/`

---

## 2. 共通ファイル生成

### history.md（プロンプト実行履歴）

`{{CYCLES_ROOT}}/{{CYCLE}}/history.md` を作成：

```markdown
# プロンプト実行履歴

このファイルは各フェーズの実行履歴を記録します。
**重要**: 履歴は必ずファイル末尾に追記してください。既存の履歴を削除・上書きしてはいけません。

## 記録フォーマット

\`\`\`
---
## YYYY-MM-DD HH:MM:SS TZ

### フェーズ
[フェーズ名]

### 実行内容
[実行した内容の要約]

### 成果物
- [作成・更新したファイル]

### 備考
[特記事項]
\`\`\`

---

## 実行履歴

（以下に履歴を追記してください）
```

**履歴追記方法**:
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF | tee -a {{CYCLES_ROOT}}/{{CYCLE}}/history.md
---
## ${TIMESTAMP}
...
EOF
```

---

### additional-rules.md（追加ルール）

`{{AIDLC_ROOT}}/prompts/additional-rules.md` を作成：

```markdown
# 追加ルール

このファイルは、AI-DLC Starter Kit プロジェクト固有の追加ルールや制約を記載します。

**重要**: セットアップ完了後、このファイルをプロジェクトに合わせてカスタマイズしてください。

---

## 実行前の検証ルール

### 指示の妥当性検証
実行前に以下を確認：
- 指示が明確で実行可能か
- リスクや副作用はないか
- 既存成果物との整合性

---

## フェーズ固有のルール

### Inception Phase
- Intent作成時は対話形式で不明点を明確化
- ユーザーストーリーはシンプルに保つ（1ストーリー = 1機能）
- Unit定義では依存関係を明確に記載

### Construction Phase
- 設計と実装を明確に分離（Phase 1で設計、Phase 2で実装）
- ドメインモデル設計時はコードを書かない
- テストはBDD/TDDに従う

### Operations Phase
- デプロイ前に必ずチェックリストを確認
- 監視・ロギングを最初から設定
- ロールバック手順を必ず用意

---

## 禁止事項

以下の行為は禁止：
- 既存履歴の削除・上書き（history.mdは必ず追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）
- コンテキスト制限を超える大量のファイル読み込み

---

## カスタムワークフロー

プロジェクト固有のワークフローがあれば、ここに記載してください。

---

## コーディング規約

プロジェクトのコーディング規約を記載してください。

---

## 使用ライブラリ・フレームワークの制約

使用するライブラリやフレームワークの制約を記載してください。

---

## セキュリティ要件

セキュリティに関する要件を記載してください。

---

## パフォーマンス要件

パフォーマンスに関する要件を記載してください。
```

---

### prompt-reference-guide.md（プロンプト参照ガイド）

`{{AIDLC_ROOT}}/prompts/prompt-reference-guide.md` を作成：

```markdown
# プロンプト参照ガイド

このガイドでは、AI-DLC Starter Kitのフェーズプロンプトを正しく活用する方法を説明します。

---

## 1. 概要

### AI-DLCのフェーズ構成

\`\`\`
┌─────────────┐     ┌─────────────────┐     ┌────────────────┐
│  Inception  │ ──▶ │  Construction   │ ──▶ │   Operations   │
│  (要件定義)  │     │    (実装)       │     │    (運用)      │
└─────────────┘     └─────────────────┘     └────────────────┘
       │                                              │
       └──────────────── 次サイクル ◀─────────────────┘
\`\`\`

### プロンプトファイル一覧

| フェーズ | プロンプトファイル | 役割 |
|---------|-------------------|------|
| Inception | `{{AIDLC_ROOT}}/prompts/inception.md` | 要件定義・Unit分解 |
| Construction | `{{AIDLC_ROOT}}/prompts/construction.md` | 設計・実装・テスト |
| Operations | `{{AIDLC_ROOT}}/prompts/operations.md` | デプロイ・運用・監視 |

---

## 2. 各フェーズプロンプトの使い方

### Inception Phase

**開始方法**:
\`\`\`
以下のファイルを読み込んで、サイクル {{CYCLE}} の Inception Phase を開始してください：
{{AIDLC_ROOT}}/prompts/inception.md
\`\`\`

### Construction Phase

**開始方法**:
\`\`\`
以下のファイルを読み込んで、サイクル {{CYCLE}} の Construction Phase を開始してください：
{{AIDLC_ROOT}}/prompts/construction.md
\`\`\`

### Operations Phase

**開始方法**:
\`\`\`
以下のファイルを読み込んで、サイクル {{CYCLE}} の Operations Phase を開始してください：
{{AIDLC_ROOT}}/prompts/operations.md
\`\`\`

---

## 3. フェーズ間の移行方法

各フェーズ完了時、**新しいセッション（コンテキストリセット）** で次フェーズのプロンプトを読み込んでください。

---

## 4. よくある間違いと対策

### 間違い1: 独自プロンプトを作成してしまう

**対策**: 公式のフェーズプロンプトを直接読み込む。プロジェクト固有のルールは `{{AIDLC_ROOT}}/prompts/additional-rules.md` に記載。

### 間違い2: 複数のフェーズプロンプトを同時に読み込む

**対策**: 1つのセッションでは1つのフェーズプロンプトのみ読み込む。

### 間違い3: コンテキストリセットをしない

**対策**: フェーズ移行時は必ず新しいセッションで開始。

---

## 5. プロンプトのカスタマイズ方法

プロジェクト固有のルールは `{{AIDLC_ROOT}}/prompts/additional-rules.md` に記載してください。

---

## 補足

- 各フェーズプロンプトは冪等性を持つよう設計されています（途中から再開可能）
- 不明点があれば、AIに質問してください
```

---

### templates/index.md（テンプレート一覧）

`{{AIDLC_ROOT}}/templates/index.md` を作成：

```markdown
# AI-DLC テンプレート一覧

このディレクトリには、AI-DLC開発で使用するドキュメントテンプレートが格納されています。

## 利用可能なテンプレート

### Inception Phase
- **intent_template.md**: 開発の目的、ターゲットユーザー、ビジネス価値
- **user_stories_template.md**: ユーザーストーリーとEpic、受け入れ基準
- **unit_definition_template.md**: Unit（独立した価値提供ブロック）の定義
- **prfaq_template.md**: プレスリリース形式での製品説明とFAQ
- **inception_progress_template.md**: Inception Phaseの進捗管理

### Construction Phase
- **domain_model_template.md**: DDDに基づくドメインモデル設計
- **logical_design_template.md**: 非機能要件を反映した論理設計
- **implementation_record_template.md**: 実装記録

### Operations Phase
- **deployment_checklist_template.md**: デプロイ前チェックリストと手順
- **monitoring_strategy_template.md**: 監視とロギングの戦略
- **distribution_feedback_template.md**: 配布とフィードバック収集の記録
- **post_release_operations_template.md**: リリース後の運用とフィードバック分析
- **operations_progress_template.md**: Operations Phaseの進捗管理
- **backlog_template.md**: 次サイクル以降のタスク管理
- **backlog_completed_template.md**: 完了済みバックログタスク
- **test_record_template.md**: テスト記録
```

---

### version.txt（バージョン記録）

`{{AIDLC_ROOT}}/version.txt` を作成：

```
echo "1.0.0" > {{AIDLC_ROOT}}/version.txt
```

---

## 3. 初回の history.md 記録

セットアップ作業自体を history.md に記録：
- 実行日時
- フェーズ：準備
- 実行内容：AI-DLC環境セットアップ
- 作成したファイル一覧

---

## 4. 完了確認と次のステップ

### 完了確認
1. 作成したファイルの一覧を表示
2. 各プロンプトファイルの概要を簡潔に説明
3. **Gitコミットを作成【必須】**: セットアップで作成したすべてのファイルをコミット

### セットアップ完了メッセージ

```
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

共通ファイル（{{AIDLC_ROOT}}/）:
- prompts/inception.md - Inception Phase用プロンプト
- prompts/construction.md - Construction Phase用プロンプト
- prompts/operations.md - Operations Phase用プロンプト
- prompts/lite/inception.md - Inception Phase用プロンプト（Lite版）
- prompts/lite/construction.md - Construction Phase用プロンプト（Lite版）
- prompts/lite/operations.md - Operations Phase用プロンプト（Lite版）
- prompts/additional-rules.md - 共通の追加ルール
- prompts/prompt-reference-guide.md - プロンプト参照ガイド
- templates/index.md - テンプレート一覧
- version.txt - スターターキットバージョン

サイクル固有ファイル（{{CYCLES_ROOT}}/{{CYCLE}}/）:
- history.md - 実行履歴
- 各種ディレクトリ

---

## ⚠️ 重要: カスタマイズが必要です

Inception Phase を開始する前に、**必ず `{{AIDLC_ROOT}}/prompts/additional-rules.md` をプロジェクトに合わせてカスタマイズしてください**。

---

## 次のステップ: Inception Phase の開始

カスタマイズ完了後、**新しいセッション**で以下を実行してください：

【Full版の場合】
以下のファイルを読み込んで、サイクル {{CYCLE}} の Inception Phase を開始してください：
{{AIDLC_ROOT}}/prompts/inception.md

【Lite版の場合】
以下のファイルを読み込んで、サイクル {{CYCLE}} の Inception Phase (Lite) を開始してください：
{{AIDLC_ROOT}}/prompts/lite/inception.md
```

---

## 重要な設計原則

- **フェーズごとに必要な情報のみ**: 各 .md は該当フェーズに必要な情報だけを含める
- **コンテキストリセット前提**: 該当フェーズの .md のみ読み込む設計
- **AI-DLC原則の反映**: 会話の反転、短サイクル、設計技法統合
- **言語統一**: すべてのドキュメント・コメントは {{LANGUAGE}} で記述
