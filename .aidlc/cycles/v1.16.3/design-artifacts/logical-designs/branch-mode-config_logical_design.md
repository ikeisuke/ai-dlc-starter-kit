# 論理設計: ブランチ作成方式の設定固定化

## 概要

read-config.sh の dasel v3 予約語回避修正と、inception.md ステップ7のブランチ方式自動選択機能の設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## コンポーネント構成

### 変更対象ファイル

```text
prompts/package/
├── bin/
│   └── read-config.sh      ← get_value 関数のキーエスケープ修正
└── prompts/
    └── inception.md         ← ステップ7の分岐ロジック変更
```

### コンポーネント詳細

#### read-config.sh: get_value 関数修正

- **責務**: dasel v3 で予約語を含むキーを安全に読み取れるようにする
- **変更箇所**: `get_value` 関数内の dasel 呼び出し部分（現行: 行137付近）
- **修正内容**: dasel に渡す前に、ドット区切りの各セグメントをダブルクォートでラップ
  - 変換例: `rules.branch.mode` → `"rules"."branch"."mode"`
  - 変換方法: `sed 's/\([^.]*\)/"\1"/g; s/\.\././g'` でドット区切りの各セグメントをクォート
- **影響範囲**: 全キー読み取りに適用されるが、クォートは安全な操作であり既存動作に影響なし
- **適用範囲の制約**: 非引用・ドット区切りキーのみ対象。キー名自体にドットを含む引用キー（例: `"foo.bar".baz`）は非対応（AI-DLCの設定では使用しない）

#### inception.md: ステップ7の分岐ロジック

- **責務**: `rules.branch.mode` の値に基づいてブランチ作成方式を自動選択
- **変更箇所**: 「#### 7. ブランチ確認【推奨】」セクション全体
- **追加される処理**: mode 読み取り → 無効値チェック → worktree 有効性チェック → 実行
- **ドメインモデルとの対応**: ドメインモデルの `BranchModeResolver.resolve()` の決定ロジックを、inception.md のステップ7にプロンプト指示として実現する。決定表の全パターンがプロンプト内の分岐条件として記述される

## 処理フロー概要

### ステップ7 変更後のフロー

**ステップ**:

1. 現在のブランチを確認（`git branch --show-current`）
2. main/master でなければ → 次のステップへ進行（変更なし）
3. main/master の場合 → `rules.branch.mode` を読み取り
   ```bash
   docs/aidlc/bin/read-config.sh rules.branch.mode --default "ask"
   ```
4. mode 値の検証と正規化
   - 有効値: `"branch"`, `"worktree"`, `"ask"`
   - 空文字 → `"ask"` として扱う（`--default "ask"` で対応済み）
   - 上記以外 → 警告表示 + `"ask"` にフォールバック
5. mode に応じた分岐:

   **mode = "branch"**:
   ```text
   設定に基づき、ブランチ方式で自動作成します（rules.branch.mode = "branch"）。
   ```
   → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch` を実行

   **mode = "worktree"**:
   - `rules.worktree.enabled` を読み取り
     ```bash
     docs/aidlc/bin/read-config.sh rules.worktree.enabled --default "false"
     ```
   - `true` の場合:
     ```text
     設定に基づき、worktree方式で自動作成します（rules.branch.mode = "worktree"）。
     ```
     → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} worktree` を実行
   - `true` 以外の場合:
     ```text
     【警告】rules.branch.mode = "worktree" ですが、rules.worktree.enabled が true ではありません。
     ブランチ方式にフォールバックします。
     ```
     → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch` を実行

   **mode = "ask"**:
   → 現行通りユーザーに質問（3択を提示）

6. setup-branch.sh の結果を表示（変更なし）

### ステップ7 の現行との差分

| 部分 | 現行 | 変更後 |
|------|------|--------|
| main/master判定 | そのまま質問 | mode読み取り → 条件分岐 |
| 質問表示 | 常に表示 | mode="ask" の場合のみ |
| 実行コマンド | 質問後に実行 | 自動 or 質問後に実行 |
| 結果表示 | 変更なし | 変更なし |
| 非main/master | 次のステップ | 変更なし |

## スクリプトインターフェース設計

### read-config.sh（既存スクリプトの修正）

#### 変更箇所: get_value 関数

**現行**:
```text
get_value() → dasel -i toml "$key"
```

**変更後**:
```text
get_value() → キーをエスケープ → dasel -i toml "$escaped_key"
```

**エスケープ処理**:
- 入力: ドット区切りキー（例: `rules.branch.mode`）
- 出力: セグメントごとにダブルクォートでラップ（例: `"rules"."branch"."mode"`）
- 方法: sed による文字列置換

#### 成功時出力

変更なし（既存と同一の動作）

#### エラー時出力

変更なし（既存と同一の動作）

## 非機能要件（NFR）への対応

### パフォーマンス
- read-config.sh: sed による1回の文字列置換が追加されるのみ。測定可能な影響なし
- inception.md: read-config.sh を最大2回呼び出し（mode + worktree.enabled）。個別呼び出しと同等

### セキュリティ
- 該当なし

### スケーラビリティ
- 該当なし

### 可用性
- 該当なし

## 技術選定

- **言語**: Bash（read-config.sh）、Markdown（inception.md）
- **依存**: dasel v3（既存依存、変更なし）

## 実装上の注意事項

- read-config.sh のエスケープ修正は全キーに適用されるため、既存の全テストケースが通ることを確認する
- inception.md はプロンプト（AI向け指示文書）であるため、AIが正確に解釈できる明確な記述にする
- `rules.branch.mode` のデフォルト値 `"ask"` は defaults.toml に Unit 001 で追加済み

## 不明点と質問（設計中に記録）

現時点で不明点はありません。
