# Unit 003: jjサポート - 許可リスト 計画

## 概要

AIエージェント許可リスト（ai-agent-allowlist.md）にjjコマンドを追加する。

## 対象ファイル

- `prompts/package/guides/ai-agent-allowlist.md`

## 実施内容

### Phase 1: 設計

このUnitはドキュメント追記のみのため、簡易設計とする。

#### 追加するjjコマンド一覧

| カテゴリ | コマンド | 説明 | allow/ask |
|---------|---------|------|-----------|
| 読み取り系 | `jj status` | 作業ツリー状態表示 | allow |
| 読み取り系 | `jj log` | コミット履歴表示 | allow |
| 読み取り系 | `jj diff` | 差分表示 | allow |
| 読み取り系 | `jj bookmark list` | ブックマーク一覧表示 | allow |
| 読み取り系 | `jj show` | コミット内容表示 | allow |
| 作成系 | `jj git init --colocate` | gitリポジトリでjj初期化 | allow |
| 作成系 | `jj bookmark create` | ブックマーク作成 | allow |
| 作成系 | `jj new` | 新規変更作成 | allow |
| 操作系 | `jj describe -m` | コミットメッセージ設定 | allow（`-m`必須） |
| 操作系 | `jj git push` | リモートにプッシュ | allow |
| 操作系 | `jj bookmark set` | ブックマーク設定 | allow |
| 操作系 | `jj git fetch` | リモートからフェッチ | allow |

**allow/ask方針**: `git push`と同様に`jj git push`も`allow`に含める。jjはgitと共存モードで使用し、同等のリスクレベルと判断。

#### Claude Code設定例の具体パターン

```json
"Bash(jj status:*)",
"Bash(jj log:*)",
"Bash(jj diff:*)",
"Bash(jj bookmark list:*)",
"Bash(jj show:*)",
"Bash(jj git init --colocate)",
"Bash(jj bookmark create:*)",
"Bash(jj new:*)",
"Bash(jj describe -m:*)",
"Bash(jj git push:*)",
"Bash(jj bookmark set:*)",
"Bash(jj git fetch:*)"
```

**パターンの方針**:
- 読み取り系: `:*`で引数・オプション付きも許可（`jj status -v`等に対応）
- `-m`必須: `jj describe -m:*`で`-m`オプション必須（git commit -mと同様）
- `jj git fetch`: `:*`で`--remote`等のオプション付きも許可

#### 挿入位置

jjコマンドはgit/ghコマンドの直後にまとめて配置（グループ化）:

1. **3.1 読み取り専用**: `gh issue list`行の直後にjj読み取り系をまとめて追加
2. **3.2 作成系**: `touch`行の直後にjj作成系をまとめて追加
3. **3.3 Git操作**: `gh pr ready`行の直後にjj操作系をまとめて追加
   - **注意**: `jj git fetch`は読み取り系ではなくネットワーク通信＋ローカル状態更新を伴うため、3.3に配置し「リモート通信」の注意を明記
4. **4.1 Claude Code 設定例**: `allow`配列の`WebSearch`直前にjjコマンドをまとめて追加

### Phase 2: 実装

1. ai-agent-allowlist.md の各セクションにjjコマンドを追加
2. Claude Code設定例のJSON配列にjjコマンドを追加

## 完了基準

- [ ] 3.1 読み取り専用セクションにjjコマンド追加
- [ ] 3.2 作成系セクションにjjコマンド追加
- [ ] 3.3 Git操作セクションにjjコマンド追加
- [ ] 4.1 Claude Code設定例にjjコマンド追加
- [ ] Markdownlintエラーなし

## 注意事項

- セキュリティNFR: 以下の書き込み/状態変更系コマンドは既存Git許可リストと同等のリスク管理を適用
  - `jj git push`: リモートへのプッシュ
  - `jj describe -m`: コミットメッセージ変更
  - `jj new`: 新規変更作成
  - `jj bookmark set`: 参照（bookmark）の移動
  - `jj bookmark create`: 新規bookmark作成
  - `jj git init --colocate`: `.jj`ディレクトリ作成
  - `jj git fetch`: リモートからのフェッチ（ローカル状態更新）
- `prompts/package/` を編集（`docs/aidlc/` は直接編集禁止）
