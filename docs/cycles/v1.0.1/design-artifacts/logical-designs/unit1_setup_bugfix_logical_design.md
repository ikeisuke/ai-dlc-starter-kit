# 論理設計: Unit 1 - セットアップバグ修正

## 概要
このUnitでは、セットアッププロンプトと各フェーズプロンプトの修正を行う。具体的には、ディレクトリ作成リストへの追加と、履歴記録の日付取得方法の明確化を実施する。

**重要**: この論理設計では**コードは書かず**、修正対象ファイルと修正方針のみを定義します。具体的な修正内容はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン
該当なし（ドキュメント修正のため）

## 修正対象ファイルと修正方針

### ファイル1: `prompts/setup-prompt.md`

#### 修正箇所1: ディレクトリ作成リスト（行188-198付近）

**現状**:
```
対象ディレクトリ（サイクル固有）:
- `{{CYCLES_ROOT}}/{{CYCLE}}/plans/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/requirements/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/story-artifacts/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/story-artifacts/units/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/domain-models/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/logical-designs/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/design-artifacts/architecture/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/construction/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/construction/units/`
- `{{CYCLES_ROOT}}/{{CYCLE}}/operations/`
```

**修正方針**:
`construction/` と `operations/` の間に以下を追加：
```
- `{{CYCLES_ROOT}}/{{CYCLE}}/inception/`
```

**追加位置**: `construction/` の直前（論理的な順序: inception → construction → operations）

#### 修正箇所2: history.md記録ルール（行457-467付近）

**現状**:
```
- 日時取得：`date '+%Y-%m-%d %H:%M:%S'` コマンドを必ず使用
```

**修正方針**:
日付取得方法を以下のように明確化（タイムゾーン情報を含む）：

```
- 日時取得：以下の方法を推奨
  - **推奨方法**: heredoc外で日付（タイムゾーン付き）を取得し、変数に格納
    ```bash
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
    cat <<EOF | tee -a {{CYCLES_ROOT}}/{{CYCLE}}/history.md
    ---
    ## ${TIMESTAMP}
    ...
    EOF
    ```
  - **代替方法**: heredocでダブルクォート（`<<EOF`）を使用し、コマンド置換を有効化
    ```bash
    cat <<EOF | tee -a {{CYCLES_ROOT}}/{{CYCLE}}/history.md
    ---
    ## $(date '+%Y-%m-%d %H:%M:%S %Z')
    ...
    EOF
    ```
  - **注意**: heredocでシングルクォート（`<<'EOF'`）を使用すると、コマンド置換が無効化されるため避ける
  - **タイムゾーン**: `%Z` でタイムゾーン略称（JST, UTC等）を表示
```

### ファイル2: `docs/aidlc/prompts/inception.md`

#### 修正箇所: 履歴記録の指示（行309付近）

**現状**:
```
1. **履歴記録**: `{{CYCLES_ROOT}}/{{CYCLE}}/history.md` に履歴を追記（heredoc使用、日時は `date '+%Y-%m-%d %H:%M:%S'` で取得）
```

**修正方針**:
以下のように具体的な実装例を追加：

```
1. **履歴記録**: `{{CYCLES_ROOT}}/{{CYCLE}}/history.md` に履歴を追記
   - **推奨方法**: heredoc外で日付（タイムゾーン付き）を取得
     ```bash
     TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
     cat <<EOF | tee -a {{CYCLES_ROOT}}/{{CYCLE}}/history.md
     ---
     ## ${TIMESTAMP}

     ### フェーズ
     Inception

     ### 実行内容
     [内容]

     ### プロンプト
     docs/aidlc/prompts/inception.md

     ### 成果物
     [成果物リスト]

     ### 備考
     [備考]
     EOF
     ```
```

### ファイル3: `docs/aidlc/prompts/construction.md`

#### 修正箇所: 履歴記録の指示（行367付近）

**現状**:
```
4. **履歴記録**: `{{CYCLES_ROOT}}/{{CYCLE}}/history.md` に履歴を追記（heredoc使用、日時は `date '+%Y-%m-%d %H:%M:%S'` で取得）
```

**修正方針**:
以下のように具体的な実装例を追加：

```
4. **履歴記録**: `{{CYCLES_ROOT}}/{{CYCLE}}/history.md` に履歴を追記
   - **推奨方法**: heredoc外で日付（タイムゾーン付き）を取得
     ```bash
     TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
     cat <<EOF | tee -a {{CYCLES_ROOT}}/{{CYCLE}}/history.md
     ---
     ## ${TIMESTAMP}

     ### フェーズ
     Construction

     ### 実行内容
     [Unit名]の実装完了

     ### プロンプト
     docs/aidlc/prompts/construction.md

     ### 成果物
     [成果物リスト]

     ### 備考
     [備考]
     EOF
     ```
```

### ファイル4: `docs/aidlc/prompts/operations.md`

#### 修正箇所: 履歴記録の指示（行425付近）

**修正方針**: construction.mdと同様に具体的な実装例を追加

## 処理フロー概要

### 修正の実施フロー

**ステップ**:
1. `prompts/setup-prompt.md` を読み込み
2. ディレクトリ作成リストに `inception/` を追加
3. history.md記録ルールを明確化
4. `docs/aidlc/prompts/inception.md` を読み込み
5. 履歴記録の指示に具体例を追加
6. `docs/aidlc/prompts/construction.md` を読み込み
7. 履歴記録の指示に具体例を追加
8. `docs/aidlc/prompts/operations.md` が存在する場合、同様に修正
9. 各ファイルの修正を保存

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: セットアップ時間への影響は最小限（数秒以内）
- **対応策**: ディレクトリ作成は `mkdir -p` で一括実行、影響なし

### セキュリティ
- **要件**: 特別な要件なし
- **対応策**: テキストファイルの修正のみ、セキュリティリスクなし

### スケーラビリティ
- **要件**: 特別な要件なし
- **対応策**: ドキュメント修正のみ、スケーラビリティ不要

### 可用性
- **要件**: セットアップが100%成功すること
- **対応策**: `inception/` ディレクトリを確実に作成することで、Inception Phase実行時のエラーを防ぐ

## 技術選定
- **編集ツール**: Edit tool（Claude Codeの編集機能）
- **検証ツール**: Bash（ディレクトリ作成の確認、履歴記録のテスト）

## 実装上の注意事項
- 既存の行番号が変動する可能性があるため、Edit toolで正確な文字列マッチングを使用
- `inception/` ディレクトリの追加位置は、論理的な順序（inception → construction → operations）を維持
- 日付取得方法は「推奨方法」と「代替方法」の2つを記載し、柔軟性を持たせる

## テスト方法

### 手動テスト1: ディレクトリ作成の確認
1. 新しいサイクルディレクトリを仮作成
2. セットアッププロンプトの指示に従ってディレクトリを作成
3. `inception/` ディレクトリが存在することを確認

### 手動テスト2: 履歴記録の確認
1. 推奨方法で履歴を追記
2. history.mdを確認し、日付が正しく展開されていることを確認
3. シングルクォートheredocとダブルクォートheredocで動作の違いを検証（オプション）

## 不明点と質問（設計中に記録）

**現時点で不明点はありません。**

修正対象ファイル、修正箇所、修正方針がすべて明確になりました。次のステップ（設計レビュー）に進むことができます。
