# Unit 002: jjサポート - 設定とドキュメント 論理設計

## 概要

jjサポートのための設定テンプレート修正とドキュメント改善の論理設計。

## 要件トレーサビリティ

| ストーリー | 変更箇所 |
|-----------|---------|
| 2-1: setup-prompt.mdへの[rules.jj]追加 (#40) | 変更1, 変更1.1 |
| 2-3: jj-support.mdへの説明追加 (#43) | 変更2 |

## 変更1: setup-prompt.md への [rules.jj] 追加（新規セットアップ用）

### 対象ファイル

`prompts/setup-prompt.md`

### 変更箇所

セクション7.2「aidlc.toml の内容」内のテンプレート

### 挿入位置

`[rules.history]` セクションの後、`[rules.custom]` セクションの前

### 追加内容

```toml
[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
```

### 設計判断

- デフォルト値は `false`（従来のGitコマンドを維持）
- jjは実験的機能のため、明示的に有効化する必要がある
- コメントでv1.7.2で追加されたことを明記

## 変更1.1: setup-prompt.md への [rules.jj] マイグレーション追加（既存プロジェクト用）

### 対象ファイル

`prompts/setup-prompt.md`

### 変更箇所

セクション7.4「設定マイグレーション【アップグレードモードのみ】」

### 追加内容

```bash
# [rules.jj] セクションが存在しない場合は追加
if ! grep -q "^\[rules.jj\]" docs/aidlc.toml; then
  echo "Adding [rules.jj] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
EOF
  echo "Added [rules.jj] section"
else
  echo "[rules.jj] section already exists"
fi
```

### 設計判断

- 既存プロジェクトがアップグレードした際に自動的に設定が追加される
- 既存の `[backlog]` マイグレーションと同様のパターンを使用

## enabled=true の動作について

**注意**: このUnitの責務は「設定テンプレートとドキュメント」の追加のみ。

`enabled=true` 時にプロンプト内でjj-support.mdへの参照を案内する動作は、各フェーズプロンプト（construction.md等）の修正が必要であり、**別Unitまたは今後のサイクルで対応**する。

現時点では:
- 設定の追加と説明ドキュメントの充実を行う
- プロンプトの動作変更は行わない
- ユーザーは手動でjj-support.mdを参照してGitコマンドを読み替える

## 変更2: jj-support.md への「gitとjjの考え方の違い」セクション追加

### 対象ファイル

`prompts/package/guides/jj-support.md`

### 挿入位置

「## 前提条件」セクションの後、「## jjの特徴と利点」セクションの前

### 追加内容の構成

1. **ワーキングコピーの扱いの違い**
   - Git: 明示的な `git add` が必要
   - jj: ワーキングコピーの変更が自動的に追跡される

2. **コミットタイミングの違い**
   - Git: `git commit` でコミットを作成
   - jj: 常にワーキングコピーがコミット状態、`jj new` で次のコミットを開始

3. **ブランチ vs ブックマークの概念**
   - Git: ブランチはコミットへのポインタ、HEADがブランチを指す
   - jj: ブックマークはラベル、作業は匿名で開始可能

4. **フロー比較図**
   - Git: edit → add → commit のフロー
   - jj: edit（自動追跡）→ describe → new のフロー

### 設計判断

- 既存ユーザー（Git経験者）が理解しやすいよう、比較形式で説明
- 抽象的な概念説明より、具体的なコマンドとワークフローの違いにフォーカス
- ASCII図で視覚的に理解を助ける

## 影響範囲

- `prompts/setup-prompt.md`: 新規プロジェクトセットアップ時のaidlc.tomlテンプレート
- `prompts/package/guides/jj-support.md`: jjガイドドキュメント
- Operations Phaseのrsyncにより `docs/aidlc/guides/jj-support.md` に反映

## 非機能要件

- **後方互換性**: デフォルト値が `false` のため、既存プロジェクトへの影響なし
- **ドキュメント品質**: markdownlintでのチェックを実施
