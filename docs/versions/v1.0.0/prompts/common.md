# AI-DLC 共通知識（全フェーズ共通）

## AI-DLC手法の要約

AI-DLCは、AIを開発の中心に据えた新しい開発手法です。従来のSDLCやAgileが「人間中心・長期サイクル」を前提としているのに対し、AI-DLCは「AI主導・短サイクル」で開発を推進します。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **冪等性の保証**: 各ステップで既存成果物を確認し、差分のみ更新

**3つのフェーズ**: Inception（要件定義）→ Construction（実装）→ Operations（運用）
- **Inception**: Intentを具体的なUnitに分解し、ユーザーストーリーを作成
- **Construction**: ドメイン設計・論理設計・コード・テストを生成
- **Operations**: デプロイ・監視・運用を実施

**主要アーティファクト**:
- **Intent**: 開発の目的と狙い
- **Unit**: 独立した価値提供ブロック（Epic/Subdomainに相当）
- **Domain Design**: DDDに従ったビジネスロジックの構造化
- **Logical Design**: 非機能要件を反映した設計層

## プロジェクト情報

**プロジェクト概要**: AI-DLCを使った開発をすぐに始められるスターターキット

**技術スタック**（brownfield開発のため既存スタック）:
- Markdownベースのドキュメントテンプレート
- Bashスクリプトによる履歴管理
- Git による成果物管理

**ディレクトリ構成**:
```
docs/versions/v1.0.0/
├── prompts/              # 各フェーズのプロンプト
├── templates/            # テンプレート（JIT生成）
├── plans/                # 実行計画
├── requirements/         # 要件定義
├── story-artifacts/      # ユーザーストーリー
│   └── units/
├── design-artifacts/     # 設計成果物
│   ├── domain-models/
│   ├── logical-designs/
│   └── architecture/
├── construction/         # 構築記録
│   └── units/
└── operations/           # 運用関連
```

**制約事項**:
- **ドキュメント読み込み制限**: ユーザーから明示的に指示されない限り、`docs/versions/v1.0.0/` 配下のファイルのみを読み込むこと。他のバージョンのドキュメントや関連プロジェクトのドキュメントは読まないこと（コンテキスト溢れ防止）
- Markdownファイルの文字エンコーディングはUTF-8
- 日本語で記述

**開発ルール**:

**人間の承認プロセス【重要】**:
計画作成後、必ず以下を実行する:
1. 計画ファイルのパスをユーザーに提示
2. 「この計画で進めてよろしいですか？」と明示的に質問
3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
4. **承認なしで次のステップを開始してはいけない**

**質問と回答の記録【重要】**:
- **独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める**
- **一問一答形式で対話する**：1つの質問をして回答を待ち、回答を得てから次の質問をする
- **複数の質問をまとめて提示してはいけない**

**Gitコミットのタイミング【必須】**:
以下のタイミングで**必ず**Gitコミットを作成する:
1. セットアップ完了時
2. Inception Phase完了時
3. 各Unit完了時
4. Operations Phase完了時

コミットメッセージは変更内容を明確に記述し、以下の形式で終了する:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**コード品質基準**:
- セキュリティ脆弱性（XSS、SQLインジェクション等）を含めない
- エラーハンドリングを適切に実装
- テストカバレッジを確保

**Git運用の原則**:
- コミット前に `git status` と `git diff` で変更内容を確認
- コミットメッセージは変更内容を明確に記述
- heredoc を使用してコミットメッセージを整形
- 例: `git commit -m "$(cat <<'EOF'\nfeat: 新機能追加\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>\nEOF\n)"`

**プロンプト履歴管理【重要】**:
- **必ずファイル末尾に追記**（既存履歴を絶対に削除・上書きしない）
- Bash heredoc (`cat <<'EOF' | tee -a docs/versions/v1.0.0/prompts/history.md`) で追記
- **ファイルを読み込む必要はない**（テンプレートが先頭にあるため）
- 日時は `date '+%Y-%m-%d %H:%M:%S'` で取得
- 記録項目: 日時、フェーズ名、実行内容、プロンプト、成果物、備考

## フェーズの責務分離

- **Inception Phase**: Intent明確化、ユーザーストーリー作成、Unit定義、PRFAQ作成、進捗管理ファイル作成（詳細は `inception.md` 参照）
- **Construction Phase**: ドメインモデル設計、論理設計、コード生成、テスト生成、ビルド、レビュー（詳細は `construction.md` 参照）
- **Operations Phase**: デプロイ準備、CI/CD構築、監視設定、配布、リリース後運用（詳細は `operations.md` 参照）

## 進捗管理と冪等性

**進捗管理**:
- Inception Phaseで `construction/progress.md` を作成
- 全Unit一覧、状態、依存関係、優先度、見積もりを記録
- Construction Phaseで1ファイル読み込むだけで全体状況を把握

**冪等性の保証**:
1. 各フェーズ開始時、`ls` コマンドで既存成果物を確認
2. 存在するファイルのみ読み込む（全ファイルを一度に読まない）
3. 既存内容を確認して差分のみ更新
4. 完了済みのステップはスキップ

## テンプレート参照

ドキュメント作成時は `docs/versions/v1.0.0/templates/` 配下のテンプレートを参照してください。テンプレートが存在しない場合は、各フェーズのプロンプトファイルに記載された手順に従ってJIT生成されます。
