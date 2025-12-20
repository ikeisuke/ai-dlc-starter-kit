# ユーザーストーリー

## Epic 1: ルール強化

### ストーリー 1: 予想禁止・一問一答質問ルール
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to AIが予想で方針を決めず、不明点を一問一答で質問してくれる
So that ユーザーの意図と乖離するリスクを低減できる

**受け入れ基準**:
- [ ] 各フェーズプロンプトに「予想禁止・質問ルール」が追加されている
- [ ] 質問は事前に全体リストを提示し、その後一問ずつ行うフローが定義されている
- [ ] 「不明な場合は質問」が明示的にルール化されている

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`

---

### ストーリー 2: コード記述制限ルール
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to Construction Phase以外でのコード記述が制限される
So that 計画なしに実装が進むリスクを防げる

**受け入れ基準**:
- [ ] 各フェーズプロンプトに「コード記述制限ルール」が追加されている
- [ ] 許容されるケース（調査時、Operations Phase）が明記されている
- [ ] Construction Phase以外でコードを書く場合は承認フローが定義されている

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`

---

### ストーリー 3: 外部入力検証ルール
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to AI MCPやユーザー入力を検証してAIの判断を提示してくれる
So that 外部入力の誤りによる問題を防げる

**受け入れ基準**:
- [ ] 各フェーズプロンプトに「外部入力の検証ルール」が追加されている
- [ ] AI MCPからの応答に対しても批判的に評価し、自己判断を併記するルールがある
- [ ] ユーザー入力に曖昧さがある場合は解釈を明示して確認するルールがある

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`

---

## Epic 2: プロンプトリファクタリング

### ストーリー 4: サイクルセットアップ分離
**優先順位**: Should-have

As a AI-DLCを使用する開発者
I want to サイクルセットアップ処理が専用プロンプトに分離されている
So that inception.mdの責務が明確になる

**受け入れ基準**:
- [ ] サイクルディレクトリ作成処理が専用プロンプトに移動されている
- [ ] inception.mdからはサイクル存在確認のみ行い、存在しない場合は専用プロンプトを案内する
- [ ] 既存の動作と互換性が維持されている

**技術的考慮事項**:
- 変更対象: `prompts/package/prompts/inception.md`, 新規プロンプト作成

---

## Epic 3: セットアップ改善

### ストーリー 5: グリーンフィールドセットアップ改善
**優先順位**: Should-have

As a 新規プロジェクトでAI-DLCを使用する開発者
I want to セットアップ時により詳細な質問でプロジェクト情報を収集してほしい
So that aidlc.tomlの設定がより適切になる

**受け入れ基準**:
- [ ] グリーンフィールド向けに質問項目が増やされている
- [ ] ブラウンフィールド向けは可変設定のみ確認するシンプルなフローになっている
- [ ] デフォルト値やテンプレートが充実している

**技術的考慮事項**:
- 変更対象: `prompts/package/setup-prompt.md` または `setup-init.md`

---

## Epic 4: リポジトリ固有対応

### ストーリー 6: セルフアップデート廃止
**優先順位**: Should-have

As a AI-DLCスターターキットの開発者
I want to Operations Phaseのセルフアップデート処理を廃止する
So that 他のリポジトリと同じアップグレードフローに統一できる

**受け入れ基準**:
- [ ] `docs/cycles/operations.md`から「メタ開発特有の完了時作業」セクションが削除または簡素化されている
- [ ] 通常のセットアップフロー（setup-prompt.md → アップグレード選択）でアップデートを行うように変更されている

**技術的考慮事項**:
- 変更対象: `docs/cycles/operations.md`（リポジトリ固有ファイル、prompts/package/には影響しない）
