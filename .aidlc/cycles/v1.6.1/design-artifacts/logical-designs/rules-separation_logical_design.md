# 論理設計: ルール責務分離とフェーズ簡略指示

**Unit**: 001-rules-separation
**作成日**: 2026-01-10

---

## 1. ファイル変更一覧

| # | ファイル | 変更種別 | 概要 |
|---|----------|----------|------|
| 1 | `prompts/package/prompts/AGENTS.md` | 追記 | 共通ルール + フェーズ簡略指示 |
| 2 | `prompts/setup/templates/rules_template.md` | 確認 | 既にプロジェクト固有のみ（変更不要） |
| 3 | `prompts/package/prompts/inception.md` | 修正 | 完了時メッセージ簡略化 |
| 4 | `prompts/package/prompts/construction.md` | 修正 | 完了時メッセージ簡略化 |
| 5 | `prompts/package/prompts/operations.md` | 修正 | 完了時メッセージ簡略化 |
| 6 | `prompts/package/prompts/setup.md` | 修正 | 完了時メッセージ簡略化 |
| 7 | `docs/cycles/rules.md` | 修正 | スターターキット固有ルールのみに整理 |

---

## 2. 詳細設計

### 2.1 AGENTS.md への追記内容

現在の内容の末尾に以下を追加：

```markdown
## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます：

| 指示 | 対応フェーズ |
|------|-------------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup |

**後方互換性**: 単語のみ（`inception`等）も引き続き有効

### サイクル判定

- ブランチ名 `cycle/vX.X.X` からサイクルを自動判定
- mainブランチの場合: 初期セットアップ or 新規サイクル開始を確認
  - 初期セットアップ: `prompts/setup-prompt.md`
  - 新規サイクル: `docs/aidlc/prompts/setup.md`
- コンテキストなしで「続けて」: ユーザーに確認

## AI-DLC共通ルール

### 実行前の検証

- **MCPレビュー推奨**: Codex MCP利用可能時は重要な変更前にレビュー
- **指示の妥当性検証**: 実行前に指示が明確か、リスクはないか確認

### フェーズ固有のルール

- **Inception Phase**: Intent作成は対話形式、Unit定義では依存関係を明確化
- **Construction Phase**: 設計と実装を分離（Phase 1で設計、Phase 2で実装）
- **Operations Phase**: デプロイ前にチェックリスト確認、ロールバック手順必須

### 禁止事項

- 既存履歴の削除・上書き（historyは追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）
```

### 2.2 完了時メッセージの簡略化

#### 現在のパターン（各フェーズ共通）

```markdown
**次のUnitを開始するプロンプト**:
\`\`\`
以下のファイルを読み込んで、サイクル vX.X.X の Construction Phase を継続してください：
docs/aidlc/prompts/construction.md
\`\`\`
```

#### 簡略化後のパターン

```markdown
**次のステップ**: 「コンストラクション進めて」と指示してください。
```

#### フェーズごとの次ステップメッセージ

| ファイル | 次のフェーズ | メッセージ |
|----------|-------------|-----------|
| inception.md | Construction | 「コンストラクション進めて」 |
| construction.md (Unit完了) | 次Unit or Operations | 「コンストラクション進めて」or「オペレーション進めて」 |
| operations.md | 次サイクル | 「start setup」 |
| setup.md | Inception | 「インセプション進めて」 |

### 2.3 変更箇所特定（各プロンプト）

| ファイル | 変更対象セクション |
|----------|-------------------|
| inception.md | 「次のステップ」セクション（Construction Phase案内） |
| construction.md | 「Unit完了時の必須作業」「次のステップ」セクション |
| operations.md | 「次のステップ」セクション |
| setup.md | 完了時のフェーズ案内メッセージ |

### 2.4 rules.md の整理

#### 削除対象（AGENTS.mdへ移動済み）

- 実行前の検証ルール
- フェーズ固有のルール
- 一般的な禁止事項

#### 残す内容（スターターキット固有）

- メタ開発の意識
- `docs/aidlc/` 編集禁止ルール
- カスタムワークフロー（テンプレート部分）
- コーディング規約（テンプレート部分）
- その他プロジェクト固有セクション

---

## 3. 実装順序

1. **AGENTS.md** - 共通ルールとフェーズ簡略指示を追加
2. **rules.md** - スターターキット固有ルールのみに整理
3. **inception.md** - 完了時メッセージ簡略化
4. **construction.md** - 完了時メッセージ簡略化
5. **operations.md** - 完了時メッセージ簡略化
6. **setup.md** - 完了時メッセージ簡略化

---

## 4. 非機能要件

- **後方互換性**: 既存の詳細な指示も引き続き有効
  - 詳細な指示（例: `docs/aidlc/prompts/construction.md を読み込んで`）も動作する
  - 簡略指示と詳細指示は共存可能
  - AGENTS.mdのフェーズ簡略指示セクションに後方互換性について明記
- **拡張性**: 新しいフェーズやキーワードを追加可能
- **可読性**: 簡略指示は直感的で覚えやすい形式

---

## 5. テスト観点

- 各プロンプトが正しく読み込めること
- フェーズ簡略指示のキーワードが一貫していること
- AGENTS.mdとrules.mdの責務が明確に分離されていること
