# Inception Phase セットアップ

このファイルは `prompts/setup-prompt.md` から参照されます。

---

## 生成するファイル

1. **プロンプトファイル**: `{{AIDLC_ROOT}}/prompts/inception.md`
2. **テンプレートファイル**（`{{AIDLC_ROOT}}/templates/` に作成）:
   - `intent_template.md`
   - `user_stories_template.md`
   - `unit_definition_template.md`
   - `prfaq_template.md`
   - `inception_progress_template.md`

---

## inception.md プロンプト生成

`{{AIDLC_ROOT}}/prompts/inception.md` を作成：

```markdown
# Inception Phase プロンプト

> **重要: このプロンプトについて**
> - これはAI-DLC Starter Kitの公式フェーズプロンプトです
> - 独自のプロンプトを作成せず、このファイルを直接読み込んでください
> - プロジェクト固有のルールは `{{AIDLC_ROOT}}/prompts/additional-rules.md` に記載してください
> - 詳細は `{{AIDLC_ROOT}}/prompts/prompt-reference-guide.md` を参照

**セットアッププロンプトパス**: {{SETUP_PROMPT_PATH}}

（このパスはテンプレート生成時に使用します）

---

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

---

## プロジェクト情報

### プロジェクト概要
{{PROJECT_SUMMARY}}

### 技術スタック
Inception Phaseで決定、または既存スタックを使用

### ディレクトリ構成
- `{{AIDLC_ROOT}}/`: 共通プロンプト・テンプレート
- `{{CYCLES_ROOT}}/{{CYCLE}}/`: サイクル固有成果物
- プロジェクトルート: 実装コード

### 制約事項
- **ドキュメント読み込み制限**: ユーザーから明示的に指示されない限り、`{{CYCLES_ROOT}}/{{CYCLE}}/` 配下のファイルのみを読み込む（コンテキスト溢れ防止）
- プロジェクト固有の制約は `{{AIDLC_ROOT}}/prompts/additional-rules.md` を参照

### 開発ルール
- **人間の承認プロセス【重要】**: 計画作成後、必ず ①計画ファイルのパス提示、②「この計画で進めてよろしいですか？」と質問、③承認まで待機、④**承認なしで次のステップを開始しない**
- **質問と回答の記録【重要】**: 独自の判断をせず、不明点は `[Question]` タグで記録し `[Answer]` タグを配置。**一問一答形式で対話**（複数の質問をまとめない）
- **Gitコミットのタイミング【必須】**: セットアップ完了時、Inception Phase完了時、各Unit完了時、Operations Phase完了時
- **プロンプト履歴管理【重要】**: history.mdは必ず追記のみ（既存履歴を削除・上書きしない）。日時は `date '+%Y-%m-%d %H:%M:%S %Z'` で取得

### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（このフェーズ）
- **Construction Phase**: 実装とテスト（`{{AIDLC_ROOT}}/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（`{{AIDLC_ROOT}}/prompts/operations.md`）

### 進捗管理と冪等性
- 各ステップ開始時に既存成果物を確認
- 存在するファイルのみ読み込む（全ファイルを一度に読まない）
- 差分のみ更新、完了済みのステップはスキップ

### テンプレート参照
ドキュメント作成時は `{{AIDLC_ROOT}}/templates/` 配下のテンプレートを参照

---

## あなたの役割

あなたは{{ROLE_INCEPTION}}です。

---

## 最初に必ず実行すること

### 0. サイクル確認【最重要】
- CYCLE変数が設定されているか確認（例: `CYCLE = v1.0.1`）
- **未設定の場合**: `ls -t {{CYCLES_ROOT}}/ | head -5` で既存サイクル一覧を表示し、ユーザーに選択を促す
- **設定済みの場合**: サイクルディレクトリの存在を確認し、存在すれば継続

### 0.5. バックログ確認【重要】
- `{{CYCLES_ROOT}}/backlog.md` が存在するか確認
- 存在する場合: バックログ内容をユーザーに提示（参考情報として）

### 1. 追加ルール確認
`{{AIDLC_ROOT}}/prompts/additional-rules.md` を読み込む

### 2. 進捗管理ファイル確認【重要】
- `{{CYCLES_ROOT}}/{{CYCLE}}/inception/progress.md` が存在するか確認
- **存在する場合**: 読み込んで完了済みステップを確認、未完了から再開
- **存在しない場合**: 初回実行として progress.md を作成（全ステップ「未着手」）

### 3. 既存成果物の確認（冪等性の保証）
- `ls {{CYCLES_ROOT}}/{{CYCLE}}/requirements/ {{CYCLES_ROOT}}/{{CYCLE}}/story-artifacts/` で既存ファイルを確認
- 存在するファイルのみ読み込み、差分のみ更新

---

## フロー（各ステップ完了時にprogress.mdを更新）

1. **Intent明確化【重要】**: 対話形式で作成、不明点は `[Question]`/`[Answer]` で記録、**一問一答形式**
2. **既存コード分析**（brownfieldのみ、greenfieldはスキップ）
3. **ユーザーストーリー作成**
4. **Unit定義【重要】**: 各Unitの依存関係を明確に記載
5. **PRFAQ作成**
6. **Construction用進捗管理ファイル作成【重要】**: `{{CYCLES_ROOT}}/{{CYCLE}}/construction/progress.md` を作成

（各ステップはテンプレートを参照）

---

## 実行ルール
計画作成 → 人間の承認【重要: 計画ファイルのパス提示、「進めてよろしいですか？」と質問、承認を待つ】→ 実行

---

## 完了基準
- すべての成果物作成
- 技術スタック決定（greenfieldの場合）
- 進捗管理ファイル作成

---

## 完了時の必須作業【重要】

1. **履歴記録**: `{{CYCLES_ROOT}}/{{CYCLE}}/history.md` に追記（heredoc使用、日時は `date '+%Y-%m-%d %H:%M:%S %Z'`）
2. **Gitコミット**: 作成したすべてのファイルをコミット

---

## 次のステップ
Construction Phase へ移行:
\`\`\`
以下のファイルを読み込んで、Construction Phase を開始してください：
{{AIDLC_ROOT}}/prompts/construction.md
\`\`\`

---

## このフェーズに戻る場合【バックトラック】

1. progress.md確認
2. 既存成果物読み込み
3. ステップ3（ユーザーストーリー）またはステップ4（Unit定義）から再開
4. construction/progress.mdに新しいUnitを追加
5. 履歴記録とコミット

完了後、Construction Phaseに戻る: `{{AIDLC_ROOT}}/prompts/construction.md` を読み込み
```

---

## Inception Phase テンプレート

### intent_template.md

```markdown
# Intent（開発意図）

## プロジェクト名
[プロジェクト名]

## 開発の目的
[なぜこのプロジェクトを開発するのか]

## ターゲットユーザー
[誰のために開発するのか]

## ビジネス価値
[このプロジェクトが提供する価値]

## 成功基準
- [測定可能な成功の指標]

## 期限とマイルストーン
[スケジュール情報]

## 制約事項
[技術的制約、予算、リソース等]

## 不明点と質問（Inception Phase中に記録）

[Question] 不明点や確認したい内容
[Answer] ユーザーからの回答
```

---

### user_stories_template.md

```markdown
# ユーザーストーリー

## Epic: [大きな機能グループ]

### ストーリー 1: [ストーリー名]
**優先順位**: Must-have / Should-have / Could-have / Won't-have

As a [ユーザー種別]
I want to [やりたいこと]
So that [得られる価値]

**受け入れ基準**:
- [ ] [条件1]
- [ ] [条件2]

**技術的考慮事項**:
[必要に応じて記載]
```

---

### unit_definition_template.md

```markdown
# Unit: [Unit 名]

## 概要
[この Unit の責務と目的]

## 含まれるユーザーストーリー
- [ストーリー1]
- [ストーリー2]

## 責務
[この Unit が担当する機能]

## 境界
[この Unit が扱わない範囲]

## 依存関係

### 依存する Unit
- [Unit名1]（依存理由: [...]）
- なし（依存がない場合）

### 外部依存
- [外部 API、ライブラリ等]

## 非機能要件（NFR）
- **パフォーマンス**: [期待される性能]
- **セキュリティ**: [セキュリティ要件]
- **スケーラビリティ**: [拡張性の要件]
- **可用性**: [稼働率等]

## 技術的考慮事項
[アーキテクチャパターン、設計方針等]

## 実装優先度
[High / Medium / Low]

## 見積もり
[期間や工数の見積もり]
```

---

### prfaq_template.md

```markdown
# PRFAQ: [プロジェクト名]

## Press Release（プレスリリース）

**見出し**: [魅力的な見出し]
**副見出し**: [一文でプロダクトを説明]
**発表日**: [想定リリース日]

**本文**:
[背景] このプロダクトを作った理由、解決する課題
[プロダクト] 何を作ったのか、どう使うのか
[顧客の声] 想定される顧客の反応
[今後の展開] 将来の展望

## FAQ（よくある質問）

### Q1: [質問]
A: [回答]

### Q2: [質問]
A: [回答]
```

---

### inception_progress_template.md

```markdown
# Inception Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. Intent明確化 | 未着手 | requirements/intent.md | - |
| 2. 既存コード分析 | 未着手 | requirements/existing_analysis.md | - |
| 3. ユーザーストーリー作成 | 未着手 | story-artifacts/user_stories.md | - |
| 4. Unit定義 | 未着手 | story-artifacts/units/*.md | - |
| 5. PRFAQ作成 | 未着手 | requirements/prfaq.md | - |
| 6. Construction用progress.md作成 | 未着手 | construction/progress.md | - |

## 現在のステップ
次回: 1. Intent明確化

## 完了済みステップ
なし

## 次回実行時の指示
Intent明確化から開始してください。

## 最終更新
日時: [自動設定]
```

**注意**: greenfieldの場合、ステップ2を「スキップ」に設定
