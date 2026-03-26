# Unit 2: フェーズ遷移ガードレール強化 - 論理設計

## 概要

ドメインモデル設計に基づき、各ファイルの具体的な変更内容を定義する。

## 変更詳細

### 1. prompts/setup-cycle.md

**変更箇所**: セクション8「完了メッセージ」（140-165行目付近）

**現在のコード（150-152行目）**:
```markdown
---

## 次のステップ: Inception Phase の開始
```

**変更後のコード**:
```markdown
**重要**: Inception Phase で計画を立ててから実装してください。
セットアップ完了後すぐに実装コードを書き始めないでください。

---

## 次のステップ: Inception Phase の開始
```

---

### 2. docs/aidlc/prompts/inception.md

**変更箇所**: 「フェーズの責務分離」セクション（103-106行目）

**現在のコード**:
```markdown
### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（このフェーズ）
- **Construction Phase**: 実装とテスト（`docs/aidlc/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（`docs/aidlc/prompts/operations.md`）
```

**変更後のコード**:
```markdown
### フェーズの責務【重要】

**このフェーズで行うこと**:
- 要件の明確化（Intent作成）
- ユーザーストーリー作成
- Unit定義
- Construction用進捗管理ファイル作成

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**

### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（このフェーズ）
- **Construction Phase**: 実装とテスト（`docs/aidlc/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（`docs/aidlc/prompts/operations.md`）
```

---

### 3. docs/aidlc/prompts/construction.md

#### 変更A: バックログ確認ステップ追加

**変更箇所**: 「最初に必ず実行すること」セクション（136行目付近）

ステップ3「進捗管理ファイル読み込み」とステップ4「対象Unit決定」の間に挿入。

**追加内容**（ステップ3の後、ステップ4の前）:
```markdown
### 3.5 バックログ確認

`docs/cycles/{{CYCLE}}/backlog.md` を確認し、対象Unitに関連する気づきがあれば確認する。

Unit定義ファイルに「実装時の注意」セクションがある場合は、そこに記載された関連気づきを優先的に確認する。
```

#### 変更B: Phase 1 禁止事項強調

**変更箇所**: Phase 1 タイトル直後（201行目付近）

**現在のコード**:
```markdown
### Phase 1: 設計【対話形式、コードは書かない】

#### ステップ1: ドメインモデル設計
```

**変更後のコード**:
```markdown
### Phase 1: 設計【対話形式、コードは書かない】

**重要**: このフェーズでは設計ドキュメントのみ作成します。
実装コードは Phase 2 で設計承認後に書きます。
設計レビューで承認を得るまで、コードファイルを作成・編集してはいけません。

#### ステップ1: ドメインモデル設計
```

---

### 4. prompts/package/prompts/inception.md

docs/aidlc/prompts/inception.md と同じ変更を適用。

---

### 5. prompts/package/prompts/construction.md

docs/aidlc/prompts/construction.md と同じ変更を適用。

---

## 変更ファイル一覧

| ファイル | 変更種別 | 変更内容 |
|----------|----------|----------|
| prompts/setup-cycle.md | 追加 | 完了メッセージに警告追加 |
| docs/aidlc/prompts/inception.md | 追加 | 「フェーズの責務【重要】」セクション |
| docs/aidlc/prompts/construction.md | 追加 | バックログ確認ステップ + Phase 1 禁止事項 |
| prompts/package/prompts/inception.md | 追加 | inception.md と同様 |
| prompts/package/prompts/construction.md | 追加 | construction.md と同様 |

## テスト計画

このUnitはプロンプトファイルの修正のため、自動テストは不要。
手動で以下を確認:

1. 各ファイルを読み、禁止事項が明確に記載されているか確認
2. マークダウンの構文エラーがないか確認
3. パッケージ版と本体版の内容が一致しているか確認

## 実装順序

1. prompts/setup-cycle.md（変更が最もシンプル）
2. docs/aidlc/prompts/inception.md
3. docs/aidlc/prompts/construction.md
4. prompts/package/prompts/inception.md（コピー）
5. prompts/package/prompts/construction.md（コピー）
