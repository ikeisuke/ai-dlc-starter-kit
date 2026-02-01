# 論理設計: Setup/Inception統合

## 1. ファイル構成

### 1.1 新規作成ファイル

| ファイル | パス | 概要 |
|---------|------|------|
| setup-inception.md | `prompts/package/prompts/setup-inception.md` | 統合版プロンプト |

**デプロイについて**: `prompts/package/prompts/` 配下のファイルは Operations Phase の rsync で `docs/aidlc/prompts/` にコピーされます。リダイレクト先の `docs/aidlc/prompts/setup-inception.md` は rsync 後に存在します。

### 1.2 更新ファイル

| ファイル | パス | 変更内容 |
|---------|------|---------|
| setup.md | `prompts/package/prompts/setup.md` | リダイレクトに置き換え |
| inception.md | `prompts/package/prompts/inception.md` | リダイレクトに置き換え |
| AGENTS.md | `prompts/package/prompts/AGENTS.md` | 簡略指示追加 |

**注意**: `docs/aidlc/prompts/AGENTS.md` は `prompts/package/prompts/AGENTS.md` の rsync コピーです。編集は `prompts/package/prompts/AGENTS.md` のみ行い、rsync で反映されます。

## 2. setup-inception.md の構成

### 2.1 セクション配置

```markdown
# Setup & Inception Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで...
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで...

---

## AI-DLC手法の要約
（setup.mdから移植）

---

## プロジェクト情報
### プロジェクト概要
### 技術スタック
### ディレクトリ構成
### 制約事項
### 開発ルール
### フェーズの責務【重要】
### フェーズの責務分離
### 進捗管理と冪等性
### テンプレート参照

---

## あなたの役割
あなたはプロジェクトセットアップ担当者兼プロダクトマネージャー兼ビジネスアナリストです。

---

## 個人設定（オプション）
（Unit 001の機能案内）

---

## 最初に必ず実行すること

### Part 1: セットアップ

#### 1. 依存コマンド確認
#### 2. デプロイ済みファイル確認
#### 3. スターターキット開発リポジトリ判定
#### 4. バックログモード確認
#### 5. スターターキットバージョン確認
#### 6. サイクルバージョンの決定
#### 7. ブランチ確認【推奨】
#### 8. サイクル存在確認
#### 9. サイクルディレクトリ作成
#### 10. 旧形式バックログ移行（該当する場合）

### Part 2: インセプション準備

#### 11. 追加ルール確認
#### 12. 環境確認
#### 13. Dependabot PR確認
#### 14. GitHub Issue確認
#### 15. バックログ確認
#### 16. 進捗管理ファイル確認
#### 17. 既存成果物の確認

---

## フロー

### ステップ1: Intent明確化【重要】
### ステップ2: 既存コード分析
### ステップ3: ユーザーストーリー作成
### ステップ4: Unit定義【重要】
### ステップ5: PRFAQ作成

---

## 実行ルール

---

## 完了基準

---

## 完了時の必須作業【重要】
（setup.mdとinception.mdをマージ）

---

## 次のステップ【コンテキストリセット必須】

---

## このフェーズに戻る場合【バックトラック】

---

## 補足: git worktree の使用
```

### 2.2 削除・統合される内容

| 元ファイル | セクション | 処理 |
|-----------|-----------|------|
| inception.md | ブランチ確認 | 削除（setup.mdで実施） |
| inception.md | サイクル名決定 | 削除（setup.mdで実施） |
| inception.md | サイクル存在確認 | 削除（setup.mdで実施） |
| inception.md | セットアップコンテキスト確認 | 削除（同一セッションのため不要） |

## 3. リダイレクトファイルのフォーマット

### 3.1 setup.md

```markdown
# Setup Phase

> **注意**: このプロンプトは統合版に移行しました。

## 統合版プロンプト

Setup PhaseとInception Phaseが統合されました。
1回のプロンプト読み込みでサイクル開始からUnit定義まで完了できます。

以下のプロンプトを読み込んでください:

```
docs/aidlc/prompts/setup-inception.md
```

または、「セットアップインセプション」と指示してください。
```

### 3.2 inception.md

```markdown
# Inception Phase

> **注意**: このプロンプトは統合版に移行しました。

## 統合版プロンプト

Setup PhaseとInception Phaseが統合されました。
1回のプロンプト読み込みでサイクル開始からUnit定義まで完了できます。

以下のプロンプトを読み込んでください:

```
docs/aidlc/prompts/setup-inception.md
```

または、「セットアップインセプション」と指示してください。

## 既存サイクルの継続

既にサイクルが作成済みで、Inception Phaseの途中から再開する場合は
統合版プロンプトを読み込んでください。進捗管理ファイルに基づいて
完了済みステップをスキップします。
```

## 4. AGENTS.md の更新箇所

### 4.1 簡略指示テーブル

**変更前**:
```markdown
| 「セットアップ」「start setup」 | Setup（新規サイクル開始） |
| 「インセプション進めて」「start inception」 | Inception Phase |
```

**変更後**:
```markdown
| 「セットアップインセプション」「start setup-inception」 | Setup & Inception Phase（新規サイクル開始、推奨） |
| 「セットアップ」「start setup」 | Setup Phase（リダイレクト） |
| 「インセプション進めて」「start inception」 | Inception Phase（リダイレクト） |
```

### 4.2 推奨ワークフロー

**変更前**:
```markdown
1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `docs/aidlc/prompts/setup.md` でサイクルを作成
3. Inception Phaseで要件定義とUnit分解
```

**変更後**:
```markdown
1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `docs/aidlc/prompts/setup-inception.md` でサイクル作成からUnit定義まで完了
```

### 4.3 新規サイクル開始

**変更前**:
```markdown
### 新規サイクル開始

`docs/aidlc/prompts/setup.md` を読み込んでください。
```

**変更後**:
```markdown
### 新規サイクル開始

`docs/aidlc/prompts/setup-inception.md` を読み込んでください。

Setup PhaseとInception Phaseが統合され、1回のプロンプト読み込みで
サイクル開始からUnit定義まで完了できます。
```

### 4.4 サイクル判定セクション

**変更前**:
```markdown
- mainブランチの場合:
  - 新規サイクル開始: `docs/aidlc/prompts/setup.md`
```

**変更後**:
```markdown
- mainブランチの場合:
  - 新規サイクル開始: `docs/aidlc/prompts/setup-inception.md`
```

## 5. 参照確認対象ファイル

| ファイル | 確認箇所 | 対応 |
|---------|---------|------|
| construction.md | バックトラックセクション | inception.md への参照を維持（リダイレクト経由） |
| operations.md | 次サイクルへの案内 | setup.md への参照を維持（リダイレクト経由） |
| README.md | 使用方法 | 必要に応じて更新 |

## 6. 後方互換性

- 旧版プロンプト（setup.md/inception.md）はリダイレクトとして維持
- 既存の簡略指示（「セットアップ」「インセプション進めて」）は引き続き動作
- 既存のconstruction.md/operations.mdからの参照はリダイレクト経由で動作
