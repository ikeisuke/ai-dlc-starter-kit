# ドメインモデル設計: ルール責務分離とフェーズ簡略指示

**Unit**: 001-rules-separation
**作成日**: 2026-01-10

---

## 1. ルール責務の分類

### 1.1 AI-DLC共通ルール（AGENTS.mdに配置）

全プロジェクト・全サイクルで適用されるルール：

| カテゴリ | ルール内容 |
|----------|------------|
| 実行前検証 | MCPレビュー推奨、指示の妥当性検証 |
| フェーズ責務 | Inception=要件定義、Construction=設計実装分離、Operations=デプロイ運用 |
| 禁止事項 | 履歴削除禁止、承認なしの進行禁止、独自判断禁止 |

### 1.2 プロジェクト固有ルール（`docs/cycles/rules.md` に配置）

プロジェクトごとにカスタマイズされるルール：

| カテゴリ | 内容 |
|----------|------|
| コーディング規約 | 命名規則、フォーマット等 |
| ライブラリ制約 | 使用禁止/推奨ライブラリ |
| セキュリティ要件 | 認証・認可方針等 |
| パフォーマンス要件 | レスポンスタイム等 |
| カスタムワークフロー | レビュープロセス等 |

### 1.3 スターターキット固有ルール（このプロジェクトのrules.md）

AI-DLCスターターキット開発に特有のルール：

| ルール | 説明 |
|--------|------|
| メタ開発の意識 | ツール側(prompts/)と成果物側(docs/)の区別 |
| docs/aidlc/編集禁止 | rsyncで上書きされるため、prompts/package/を編集 |

---

## 2. フェーズ簡略指示のマッピング

### 2.1 キーワードとプロンプトの対応

| 簡略指示キーワード | 対応プロンプト |
|-------------------|----------------|
| `インセプション進めて`、`start inception` | `docs/aidlc/prompts/inception.md` |
| `コンストラクション進めて`、`start construction` | `docs/aidlc/prompts/construction.md` |
| `オペレーション進めて`、`start operations` | `docs/aidlc/prompts/operations.md` |
| `セットアップ`、`start setup` | `docs/aidlc/prompts/setup.md` |

**後方互換性**: 単語のみ（`inception`等）も引き続き有効とする

### 2.2 サイクル判定ロジック

```
1. ブランチ名から判定
   - pattern: cycle/vX.X.X → サイクル vX.X.X
   - pattern: cycle/vX.X.X/unit-NNN → サイクル vX.X.X

2. mainブランチの場合
   - 初期セットアップ: 「prompts/setup-prompt.md を読み込んでください」
   - 新規サイクル開始: 「docs/aidlc/prompts/setup.md を読み込んでください」
   - ユーザーにどちらかを確認

3. コンテキストなしで「続けて」の場合
   - ユーザーに確認: 「どのフェーズを継続しますか？」
```

### 2.3 完了時メッセージの簡略化

現在の冗長なメッセージ:
```
以下のファイルを読み込んで、サイクル vX.X.X の Construction Phase を継続してください：
docs/aidlc/prompts/construction.md
```

簡略化後:
```
「コンストラクション進めて」と指示してください。
```

### 2.4 フェーズごとの完了時メッセージ

| 完了フェーズ | 次のステップ | 簡略指示 |
|-------------|-------------|----------|
| Inception Phase | Construction Phase | 「コンストラクション進めて」 |
| Construction Phase (Unit完了) | 次のUnit or Operations | 「コンストラクション進めて」or「オペレーション進めて」 |
| Operations Phase | 次のサイクル | 「start setup」 |
| Setup | Inception Phase | 「インセプション進めて」 |

---

## 3. エンティティ定義

### 3.1 PhaseCommand（値オブジェクト）

フェーズ簡略指示コマンド

| 属性 | 型 | 説明 |
|------|-----|------|
| keywords | string[] | トリガーキーワード一覧 |
| promptPath | string | 対応プロンプトファイルパス |
| phaseName | string | フェーズ名 |

### 3.2 RuleCategory（列挙型）

```
- COMMON: AI-DLC共通ルール（全プロジェクト適用）
- PROJECT_SPECIFIC: プロジェクト固有ルール（ユーザーカスタマイズ）
```

**注**: スターターキット固有ルール（メタ開発の意識等）は `PROJECT_SPECIFIC` の一種として、
このプロジェクトの `docs/cycles/rules.md` に記載する。他プロジェクトでは不要

---

## 4. 責務の分離方針

### 4.1 ファイル配置

| ファイル | 責務 |
|----------|------|
| `AGENTS.md` | AI-DLC共通ルール + フェーズ簡略指示 |
| `docs/cycles/rules.md` | プロジェクト固有ルールのみ |
| `rules_template.md` | 新規プロジェクト用テンプレート |

### 4.2 参照関係

```
AGENTS.md (読み込み必須)
    ├── 共通ルール（全プロジェクト共通）
    ├── フェーズ簡略指示機能
    └── docs/cycles/rules.md への参照

rules.md (プロジェクトごとにカスタマイズ)
    └── プロジェクト固有ルール
```

### 4.3 AGENTS.md展開フロー

```
prompts/package/prompts/AGENTS.md (ソース)
    ↓ Operations Phase の rsync
docs/aidlc/prompts/AGENTS.md (プロジェクト内コピー)
    ↓ 参照
ルート AGENTS.md (docs/aidlc/prompts/AGENTS.md への参照のみ)
```

**変更対象**: `prompts/package/prompts/AGENTS.md` のみ
**自動反映**: Operations Phase で rsync により `docs/aidlc/` に反映
**ルート AGENTS.md**: 参照元のため変更不要
