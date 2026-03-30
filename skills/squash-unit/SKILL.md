---
name: squash-unit
description: "squash-unit.shを実行してUnit完了時またはInception Phase完了時の中間コミットをスカッシュする。commit-flow.mdのスカッシュフロー内で使用。ユーザーが「squash-unit」「squash unit」「スカッシュ」と指示した場合にも使用。"
argument-hint: "cycle [unit_number] [retroactive]"
---

# squash-unit スキル

Unit完了時またはInception Phase完了時の中間コミットを1つの完了コミットにまとめる。

## 引数解決手順

スキル呼び出し時、以下の引数をAIが自動解決する。引数が直接指定されている場合はそちらを優先する。

| 引数 | 解決方法 | 例 |
|------|---------|-----|
| `--cycle` | ブランチ名から抽出（`cycle/` プレフィックス除去） | `v1.20.0`, `waf/v1.0.0` |
| `--unit` | 現在作業中のUnit番号（3桁ゼロ埋め）。Inception Phase完了squashでは省略する | `003` |
| `--vcs` | 常に `git` を指定 | `git` |
| `--base` | コミット履歴からUnit開始コミットの直前を特定（後述） | `cdbf67ab` |
| `--message` / `--message-file` | `mktemp /tmp/aidlc-squash-msg.XXXXXX` でパス生成 → Writeツールで書き込み → `--message-file` で渡す | `/tmp/aidlc-squash-msg.XXXXXX` |

### ブランチ名からの `--cycle` 解決

```bash
git branch --show-current
```

出力が `cycle/v1.20.0` の場合: `--cycle 'v1.20.0'`
出力が `cycle/waf/v1.0.0` の場合: `--cycle 'waf/v1.0.0'`

### 起点コミット（`--base`）の特定

コミット履歴を遡り、以下のいずれかのパターンにマッチする最新コミットを特定する:

- 直前のUnit完了コミット: `feat: [{{CYCLE}}] Unit {NNN-1}完了 -`
- Inception Phase完了コミット: `feat: [{{CYCLE}}] Inception Phase完了 -`
- サイクルブランチの起点: `cycle/{{CYCLE}}` ブランチの分岐元

特定したコミットのハッシュを `--base` に渡す。

## 実行フロー

### 1. dry-run で対象コミット確認

**Unit完了squashの場合**:
```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
  --vcs git --base '<起点コミット>' --dry-run
```

**Inception Phase完了squashの場合**（`--unit` 省略）:
```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' \
  --vcs git --base '<起点コミット>' --dry-run
```

出力例:
```text
target_count:3
squash:dry-run:3
```

### 2. 続行確認

dry-run結果をユーザーに提示し、続行を確認する。

### 3. メッセージファイル作成

Bashツールで `mktemp /tmp/aidlc-squash-msg.XXXXXX` を実行してパスを生成し、Writeツールで生成されたパスに書き込む:

**Unit完了squashの場合**:
```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

Unit-Number: {NNN}
```

**Inception Phase完了squashの場合**:
```text
feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}
```

### 4. squash実行

**Unit完了squashの場合**:
```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
  --vcs git --base '<起点コミット>' --message-file <生成されたパス>
```

**Inception Phase完了squashの場合**（`--unit` 省略）:
```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' \
  --vcs git --base '<起点コミット>' --message-file <生成されたパス>
```

### 5. 一時ファイル削除・結果確認

一時ファイルを削除し、出力を確認:

- `squash:success:<hash>`: squash完了
- `squash:skipped:no-commits`: 対象コミットなし（通常コミットへ進む）
- `squash:error:<type>`: エラー発生（エラーハンドリング参照）

## retroactive モード

過去のUnitを事後squashする場合:

```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
  --vcs git --retroactive --message-file <生成されたパス>
```

`--from` / `--to` でUnit開始・終了コミットを明示的に指定することも可能:

```bash
scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
  --vcs git --retroactive --from '<開始コミット>' --to '<終了コミット>' \
  --message-file <生成されたパス>
```

## エラーハンドリング

| 出力パターン | 対応 |
|-------------|------|
| `squash:success:<hash>` | 正常完了。新しいコミットハッシュを記録 |
| `squash:skipped:no-commits` | 「squash対象のコミットがありません」と表示。通常コミットへ進む |
| `squash:error:dirty-working-tree` | 未コミットの変更あり。コミットまたはstashしてから再実行 |
| `squash:error:base-not-found` | 起点コミットが見つからない。手動で `--base` を指定 |
| `squash:error:*` | エラーメッセージとrecoveryコマンドをユーザーに提示 |

エラー解消が困難な場合は、`commit-flow.md` の手動squashフロー（Squash統合フローセクション）を案内する。

## 注意事項

- 各引数は必ず引用符で囲む（特に `--cycle` と `--base`）
- コマンド内に `$()` を使用しない（AIが値を事前に解決してから組み立てる）
- `--message-file` を使用し、`--message` でのコマンドライン直接埋め込みは避ける
