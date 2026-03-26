# 論理設計: $()パターン排除

## コンポーネント構成

### 1. write-history.sh --content-file実装

引数解析に`--content-file`を追加。バリデーション後にファイルを読み込み、既存の`CONTENT`変数に格納する。

```text
入力: --content-file <filepath>
処理:
  1. --content と --content-file の排他チェック
  2. ファイル存在チェック
  3. 空ファイルチェック
  4. ファイル内容を CONTENT 変数に読み込み
出力: 従来と同じ（CONTENT変数経由で処理）
```

### 2. squash-unit.sh --message-file実装

同様のパターンで`--message-file`を追加。

```text
入力: --message-file <filepath>
処理:
  1. --message と --message-file の排他チェック
  2. ファイル存在チェック
  3. 空ファイルチェック
  4. ファイル内容を MESSAGE 変数に読み込み
出力: 従来と同じ（MESSAGE変数経由で処理）
```

### 3. プロンプト置換方式

各プロンプトファイルで以下のパターンに統一:

#### 3a. commit-pattern

**Before (commit-flow.md)**:
```bash
git commit -m "$(cat <<'EOF'
message
EOF
)"
```

**After**:
```text
1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）
2. 以下を実行:
   git commit -F <一時ファイルパス>
3. 一時ファイルを削除
```

#### 3b. jj-pattern

**Before (commit-flow.md jj環境)**:
```bash
jj describe -m "$(cat <<'EOF'
message
EOF
)"
```

**After**:
```text
1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）
2. 以下を実行:
   jj describe --stdin < <一時ファイルパス>
3. 一時ファイルを削除
```

#### 3c. content-pattern

**Before (review-flow.md)**:
```bash
write-history.sh --content "$(cat <<'CONTENT_EOF'
content
CONTENT_EOF
)"
```

**After**:
```text
1. Writeツールで一時ファイルを作成（内容: 履歴コンテンツ）
2. 以下を実行:
   write-history.sh --content-file <一時ファイルパス>
3. 一時ファイルを削除
```

#### 3d. body-pattern

**Before (inception.md, construction.md等)**:
```bash
gh pr create --body "$(cat <<'EOF'
PR body content
EOF
)"
```

**After**:
```text
1. Writeツールで一時ファイルを作成（内容: PR本文）
2. 以下を実行:
   gh pr create --body-file <一時ファイルパス>
3. 一時ファイルを削除
```

注: `--body-file`は`gh` CLI組み込み機能であり、Phase Aのスクリプト変更は不要。

#### 3e. squash-pattern

**Before (commit-flow.md squash)**:
```bash
SQUASH_MESSAGE="$(cat <<'EOF'
message
EOF
)"
squash-unit.sh --message "$SQUASH_MESSAGE"
```

**After**:
```text
1. Writeツールで一時ファイルを作成（内容: squashメッセージ）
2. 以下を実行:
   squash-unit.sh --message-file <一時ファイルパス>
3. 一時ファイルを削除
```

#### 3f. var-pattern

`VAR=$(command)`パターンはスクリプト変更や新インターフェースを必要としない。プロンプト内のBashコードブロックで`$(command)`を含まない2ステップ形式に書き換える。

**Before**:
```bash
gh pr list --head "$(git branch --show-current)" --state open --json number --jq '.[0].number'
```

**After**:
```text
1. 事前にBashで `git branch --show-current` を実行し結果を変数に格納
2. 格納した変数値を使って次のコマンドを実行:
   gh pr list --head "<取得したブランチ名>" --state open --json number --jq '.[0].number'
```

注: インラインコードや説明文中のリテラル`$()`（例: `$(ghq root)`のパス説明）は対象外。Bashコードブロック内の実行例のみ変換する。

## 実装順序

1. Phase A: write-history.sh, squash-unit.sh のスクリプト変更
2. Phase B-1: commit-flow.md（最多変更、基準パターン確立）
3. Phase B-2: review-flow.md
4. Phase B-3: rules.md（呼び出し例更新 + `$()`禁止ルール新設）
5. Phase B-4: inception.md, construction.md, operations.md, operations-release.md, feedback.md
6. Phase B-5: skills/upgrading-aidlc/SKILL.md
7. Phase C: 横断検証
