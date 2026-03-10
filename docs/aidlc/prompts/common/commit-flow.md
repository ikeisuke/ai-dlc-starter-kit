# コミットフロー

## コミットポリシー

### コミットタイミング

以下のタイミングで**必ず**コミットを作成する:

1. セットアップ完了時
2. Inception Phase完了時
3. 各Unit完了時
4. Operations Phase完了時

加えて、レビューフロー内で以下のタイミングでもコミットする:

- AIレビュー/ユーザーレビュー前（変更がある場合のみ）
- レビュー反映後（修正があった場合のみ）

### コミットメッセージフォーマット一覧

| ID | prefix | テンプレート | 使用場面 |
|-----|--------|------------|---------|
| REVIEW_PRE | `chore:` | `chore: [{{CYCLE}}] レビュー前 - {ARTIFACT_NAME}` | AIレビュー/ユーザーレビュー前 |
| REVIEW_POST | `chore:` | `chore: [{{CYCLE}}] レビュー反映 - {ARTIFACT_NAME}` | レビュー修正反映後 |
| INCEPTION_COMPLETE | `feat:` | `feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}` | Inception Phase完了時 |
| UNIT_COMPLETE | `feat:` | `feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}` + `Unit-Number: {NNN}` trailer | Unit完了時（標準パス） |
| UNIT_SQUASH_PREP | `chore:` | `chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備` + `Unit-Number: {NNN}` trailer | Unit完了squash前の中間コミット |
| INCEPTION_SQUASH_PREP | `chore:` | `chore: [{{CYCLE}}] Inception Phase完了 - 完了準備` | Inception Phase完了squash前の中間コミット |
| OPERATIONS_COMPLETE | `chore:` | `chore: [{{CYCLE}}] Operations Phase完了 - {DESCRIPTION}` | Operations Phase完了時 |

### Co-Authored-By 設定

コミットメッセージに追加する Co-Authored-By 情報は自動検出または手動設定で決定する。

#### 自動検出の有効化/無効化

`docs/aidlc.toml` の `[rules.commit]` セクションで制御:

```toml
[rules.commit]
ai_author_auto_detect = true  # デフォルト: true（自動検出有効）
ai_author = ""                # 手動設定（自動検出無効時に使用）
```

- `ai_author_auto_detect = false`: 自動検出をスキップし、`ai_author`の値を使用
- `ai_author_auto_detect = true`（デフォルト）: 以下の検出フローを実行

#### 検出フロー

以下の優先順位でAI著者情報を決定:

1. **設定確認**: `ai_author`が有効値で設定済み → その値を使用
2. **自己認識**: AIツールが自身を認識 → 対応するai_author値を使用
3. **環境変数**: AIツール固有の環境変数を検出 → 対応するai_author値を使用
4. **ユーザー確認**: 上記すべて失敗 → ユーザーに質問

**「未設定」の定義**: キー不存在、空文字(`""`)、空白のみ(`"   "`)

#### AIツールマッピングテーブル

| AIツール | 自己認識キーワード | 環境変数 | ai_author値 |
|---------|-------------------|---------|-------------|
| Claude Code | Claude Code | `CLAUDE_CODE` | `Claude <noreply@anthropic.com>` |
| Cursor | Cursor | `CURSOR_EDITOR` | `Cursor <noreply@cursor.com>` |
| Cline | Cline | `CLINE_*` | `Cline <noreply@cline.bot>` |
| Windsurf | Windsurf | `WINDSURF_*` | `Windsurf <noreply@codeium.com>` |
| Codex CLI | Codex | `CODEX_*` | `Codex <noreply@openai.com>` |
| KiroCLI | Kiro | `KIRO_*` | `Kiro <noreply@aws.com>` |

#### マイグレーション（既存設定の削除）

v1.9.1以前で`ai_author`が設定されている場合、初回コミット時に以下を確認:

```text
【マイグレーション確認】
aidlc.tomlに ai_author が設定されていますが、v1.9.2から自動検出機能が利用可能です。

現在の設定: ai_author = "{現在値}"

自動検出を有効にするため、この設定を削除しますか？
1. はい - 設定を削除して自動検出を使用（推奨）
2. いいえ - 現在の設定を維持
```

「はい」の場合: `ai_author`行をコメントアウトまたは削除

#### コミットメッセージ形式

```text
{コミットメッセージ}

Co-Authored-By: {AI_AUTHOR}
```

### プレースホルダ定義

| プレースホルダ | 形式 | 説明 |
|-------------|------|------|
| `{{CYCLE}}` | `vX.X.X` | サイクル番号 |
| `{NNN}` | 3桁ゼロパディング | Unit番号（例: 001, 004） |
| `{UNIT_NAME}` | 文字列 | Unit名 |
| `{ARTIFACT_NAME}` | 文字列 | 成果物名（レビュー対象名） |
| `{DESCRIPTION}` | 自由記述 | コミットの説明文 |
| `{AI_AUTHOR}` | `名前 <メール>` | Co-Authored-By値 |

> **テンポラリファイル規約**: 本ドキュメント内の一時ファイル操作は `common/rules.md` のテンポラリファイル規約に従う。パスは `mktemp` で事前に生成すること。コードブロック内の `/tmp/aidlc-*` で始まるパスはパターン例示である。

## レビューコミット手順

### レビュー前コミット

**レビュー前コミット**（変更がある場合のみ）:

```bash
git status --porcelain
```

AIが出力を確認し、変更がある場合は以下を順次実行:

1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

```text
chore: [{{CYCLE}}] レビュー前 - {ARTIFACT_NAME}

Co-Authored-By: {AI_AUTHOR}
```

2. 以下を実行:

```bash
git add -A
git commit -F /tmp/aidlc-commit-msg.txt
```

3. 一時ファイルを削除

### レビュー反映コミット

**レビュー反映コミット**（修正があった場合のみ）:

```bash
git status --porcelain
```

AIが出力を確認し、変更がある場合は以下を順次実行:

1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

```text
chore: [{{CYCLE}}] レビュー反映 - {ARTIFACT_NAME}

Co-Authored-By: {AI_AUTHOR}
```

2. 以下を実行:

```bash
git add -A
git commit -F /tmp/aidlc-commit-msg.txt
```

3. 一時ファイルを削除

## フェーズ完了コミット手順

### Inception Phase完了コミット

**注意**: Squash統合フローでsquashを実行した場合（`squash:success`）、コミットは既に完了しています。以下の確認のみ行い、新規コミットは作成しません:

```bash
# git環境
git status
# jj環境（[rules.jj].enabled = true の場合）
jj status
```

期待される結果: `nothing to commit, working tree clean`（git）または変更なし（jj）

squashを実行していない場合は、以下の通常コミット手順を実行:

Inception Phaseで作成・変更したすべてのファイル（**inception/progress.md、履歴ファイルを含む**）をコミット。

1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

```text
feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}

Co-Authored-By: {AI_AUTHOR}
```

2. 以下を実行:

```bash
git add -A
git commit -F /tmp/aidlc-commit-msg.txt
```

3. 一時ファイルを削除

**コミット実行後の確認**:

```bash
git status
```

**期待される結果**: `nothing to commit, working tree clean`

### Unit完了コミット

**注意**: Squash統合フローでsquashを実行した場合（`squash:success`）、コミットは既に完了しています。以下の確認のみ行い、新規コミットは作成しません:

```bash
# git環境
git status
# jj環境（[rules.jj].enabled = true の場合）
jj status
```

期待される結果: `nothing to commit, working tree clean`（git）または変更なし（jj）

squashを実行していない場合は、以下の通常コミット手順を実行:

「コミット前確認チェックリスト」を確認した後、コミットを実行:

1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}

Unit-Number: {NNN}
Co-Authored-By: {AI_AUTHOR}
```

2. 以下を実行:

```bash
git add -A
git commit -F /tmp/aidlc-commit-msg.txt
```

3. 一時ファイルを削除

**コミット実行後の確認**:

```bash
git status
```

**期待される結果**: `nothing to commit, working tree clean`

**変更が残っている場合**: 追加コミットを実施

### Operations Phase完了コミット

Operations Phaseで作成したすべてのファイル（**operations/progress.md、履歴ファイルを含む**）をコミット。

1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

```text
chore: [{{CYCLE}}] Operations Phase完了 - {DESCRIPTION}

Co-Authored-By: {AI_AUTHOR}
```

2. 以下を実行:

```bash
git add -A
git commit -F /tmp/aidlc-commit-msg.txt
```

3. 一時ファイルを削除

**コミット実行後の確認**:

```bash
git status
```

**期待される結果**: `nothing to commit, working tree clean`

## Squash統合フロー

フェーズ完了時の中間コミット（レビュー前/反映コミット等）を1つの完了コミットにまとめる。

> **スキル呼び出し推奨**: `/squash-unit` スキルを使用すると、引数の自動解決・dry-runフロー・エラーハンドリングが統合された形でsquashを実行できます。以下の手順を手動で実行する代わりに、スキル呼び出しを推奨します。スキルが利用できない場合は、以下の手動フローにフォールバックしてください。

### 適用対象判定

呼び出し元フェーズに応じて、以下の手順を参照する:

| 呼び出し元 | 適用対象 | 中間コミットメッセージ | squashコミットメッセージ |
|-----------|---------|---------------------|----------------------|
| Construction Phase（Unit完了時） | Unit完了squash | `UNIT_SQUASH_PREP` | `UNIT_COMPLETE` |
| Inception Phase（Phase完了時） | Inception Phase完了squash | `INCEPTION_SQUASH_PREP` | `INCEPTION_COMPLETE` |

以降の手順では、呼び出し元フェーズに対応するメッセージテンプレートを使用する。

### 設定確認・VCS判定

**設定確認**:

```bash
docs/aidlc/bin/read-config.sh rules.squash.enabled --default "false"
```

- `true` の場合: 以下の手順を実行
- `false`、未設定の場合: このフローをスキップ

**VCS種類判定**:

> **非推奨（v1.19.0）**: jjサポートは非推奨です。`vcs=jj` は将来のバージョンで削除予定です。

```bash
docs/aidlc/bin/read-config.sh rules.jj.enabled --default "false"
```

- `true` → `vcs=jj`（非推奨）
- `false`、未設定 → `vcs=git`

### ユーザー確認・中間コミット

1. **ユーザー確認**（中間コミット作成前に実施）:

```text
中間コミット（レビュー前/反映コミット等）を1つの完了コミットにsquashしますか？

1. はい - squashを実行する（推奨）
2. いいえ - squashをスキップして通常コミットを行う
```

2. **「いいえ」の場合**: フローを終了し、通常コミットに進む（未コミット変更は通常コミットで処理される）

3. **「はい」の場合 - 未コミット変更のコミット**: 変更ファイルが未コミットの場合、中間コミットとして作成（squash-unit.shはclean working treeを前提とするため、先にコミットする）:

   **コミットメッセージ**: 「適用対象判定」テーブルの中間コミットメッセージを使用する。

   **Unit完了squashの場合**:

   git環境:

   1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

   ```text
   chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

   Unit-Number: {NNN}
   Co-Authored-By: {AI_AUTHOR}
   ```

   2. 以下を実行:

   ```bash
   git add <変更ファイル>
   git commit -F /tmp/aidlc-commit-msg.txt
   ```

   3. 一時ファイルを削除

   jj環境（`[rules.jj].enabled = true` の場合）:

   1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

   ```text
   chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

   Unit-Number: {NNN}
   Co-Authored-By: {AI_AUTHOR}
   ```

   2. 以下を実行:

   ```bash
   jj describe --stdin < /tmp/aidlc-commit-msg.txt
   jj new
   ```

   3. 一時ファイルを削除

   **Inception Phase完了squashの場合**:

   git環境:

   1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

   ```text
   chore: [{{CYCLE}}] Inception Phase完了 - 完了準備

   Co-Authored-By: {AI_AUTHOR}
   ```

   2. 以下を実行:

   ```bash
   git add <変更ファイル>
   git commit -F /tmp/aidlc-commit-msg.txt
   ```

   3. 一時ファイルを削除

   jj環境（`[rules.jj].enabled = true` の場合）:

   1. Writeツールで一時ファイルを作成（内容: コミットメッセージ）:

   ```text
   chore: [{{CYCLE}}] Inception Phase完了 - 完了準備

   Co-Authored-By: {AI_AUTHOR}
   ```

   2. 以下を実行:

   ```bash
   jj describe --stdin < /tmp/aidlc-commit-msg.txt
   jj new
   ```

   3. 一時ファイルを削除

   未コミット変更がない場合: このステップをスキップ

   **clean状態の検証**（中間コミット後、またはスキップ後）:

   ```bash
   # git環境
   git status --porcelain
   # jj環境
   jj diff --stat
   ```

   出力が空であることを確認。空でない場合: 残りの変更を追加コミットする。

### 起点コミット特定・Squash実行

4. **起点コミットの特定（`--base`）**:

   squash対象の範囲を正確に制御するため、AIが起点コミットを判定して `--base` で明示指定する。

   **判定手順**:

   ```bash
   # git環境
   git log --oneline -20
   # jj環境
   jj log --limit 20
   ```

   ログを確認し、squash対象範囲の起点となるコミットを特定する。

   **フェーズ別の判定基準**:

   | フェーズ | git | jj |
   |---------|-----|-----|
   | Unit完了squash | 前Unitの完了コミット（`feat: [{{CYCLE}}] Unit {前のNNN}完了`）、またはサイクル開始コミット（`feat: [{{CYCLE}}] Inception Phase完了`）のハッシュ | `jj log` から同様に判定し、change_idを特定 |
   | Inception Phase完了squash | `git merge-base origin/main HEAD`（サイクルブランチの分岐点）。`origin/main` が存在しない場合はユーザーに起点コミットを確認 | `jj log` で `main` ブランチとの分岐リビジョンを特定 |

5. **squash実行**:

   **Unit完了squashの場合**:

   1. Writeツールで一時ファイルを作成（内容: squashメッセージ）:

   ```text
   feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

   Unit-Number: {NNN}
   ```

   2. 以下を実行:

   ```bash
   docs/aidlc/bin/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs <vcs> --base '<起点コミット>' --message-file /tmp/aidlc-squash-msg.txt
   ```

   3. 一時ファイルを削除

   **Inception Phase完了squashの場合**:

   1. Writeツールで一時ファイルを作成（内容: squashメッセージ）:

   ```text
   feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}
   ```

   2. 以下を実行:

   ```bash
   docs/aidlc/bin/squash-unit.sh --cycle '{{CYCLE}}' \
     --vcs <vcs> --base '<起点コミット>' --message-file /tmp/aidlc-squash-msg.txt
   ```

   3. 一時ファイルを削除

   - `squash:success` の場合: squash完了。通常コミットをスキップし、jj環境の場合のみブックマーク更新へ進む
   - `squash:skipped:no-commits` の場合: 「squash対象のコミットがありません。通常コミットに進みます。」と表示してスキップ
   - `squash:error` の場合: エラーメッセージと recovery コマンドをユーザーに提示し、対応を確認

### jjブックマーク更新・エラーリカバリ

6. **(jj環境かつ `squash:success` の場合のみ) bookmark更新**:

   `squash:success` 以外の結果（`skipped` / `error`）では `@-` が期待するsquashedコミットを指さないため、このステップは実行しない。

   ```bash
   # bookmarkが存在する場合
   jj bookmark set cycle/{{CYCLE}} -r @-
   # bookmarkが存在しない場合
   jj bookmark create cycle/{{CYCLE}} -r @-
   ```

   squash後の状態: `@-` = squashedコミット（feat: メッセージ付き）、`@` = working copy（空）。`jj new` は不要。

### 事後squash（retroactive）

過去のUnit（HEADの最新Unitではない）のコミットを後からsquashする場合に使用する。通常のsquash（`git reset --soft` 方式）では過去のUnitを対象にできないため、`--retroactive` オプションでGIT_SEQUENCE_EDITOR方式の非対話的rebaseを実行する。

**使用条件**:

- `--vcs=git` のみ対応（jjは非対応）
- `--unit` の指定が必須（3桁数字形式、例: 003）
- working treeがcleanであること

**使用場面**:

- 通常squashを実行し忘れてUnit完了後に後続のコミットが積まれた場合
- 過去のUnitの中間コミットを事後的にまとめたい場合

**実行手順**:

1. **ドライランで対象確認**:

   1. Writeツールで一時ファイルを作成（内容: squashメッセージ）:

   ```text
   feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

   Unit-Number: {NNN}
   ```

   2. 以下を実行:

   ```bash
   docs/aidlc/bin/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs git --retroactive --dry-run --message-file /tmp/aidlc-squash-msg.txt
   ```

   出力の `unit_range` と `unit_commit_count` で対象範囲を確認する。

2. **事後squash実行**:

   前のステップと同じ一時ファイルを再利用（または新たに作成）:

   ```bash
   docs/aidlc/bin/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs git --retroactive --message-file /tmp/aidlc-squash-msg.txt
   ```

   一時ファイルを削除

   - `squash:success` の場合: 事後squash完了
   - `squash:error:unit-not-found` の場合: 対象Unitのコミットが見つからない。コミットメッセージのパターンを確認
   - `squash:error:conflict` の場合: rebase中にコンフリクト発生。自動的に `git rebase --abort` で復帰済み。手動での対応が必要
   - `squash:error:unsupported-vcs` の場合: jj環境では事後squash非対応

**`--from`/`--to` によるコミット範囲の手動指定**:

コミットメッセージのパターンやトレーラーによる自動検出が失敗した場合、`--from`/`--to` でUnit境界を手動指定できる。

```bash
# 1. 対象コミットの特定
git log --oneline -30
```

2. Writeツールで一時ファイルを作成（内容: squashメッセージ）:

```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

Unit-Number: {NNN}
```

3. 対象範囲を --from/--to で指定（--base は不要）:

```bash
docs/aidlc/bin/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
  --vcs git --retroactive \
  --from '<Unit開始コミット>' --to '<Unit終了コミット>' \
  --message-file /tmp/aidlc-squash-msg.txt
```

4. 一時ファイルを削除

- `--from`: Unit開始コミットのハッシュ（このコミットを含む）
- `--to`: Unit終了コミットのハッシュ（このコミットを含む）
- `--from`/`--to` は両方同時に指定する必要がある（片方のみはエラー）
- `--from`/`--to` と `--base` は排他（同時指定はエラー）

**注意事項**:

- 事後squashはgit rebaseを使用するため、コミットハッシュが変更される（対象Unitだけでなく、それ以降のコミットも新しいハッシュになる）
- rebase中にコンフリクトが発生した場合は自動的にabortされ、元の状態に復帰する
- squash前後のツリーハッシュを検証し、内容が変わっていないことを確認する（不一致時は警告を出力）
- dry-run実行後に同一履歴で本実行する場合、ハッシュは同じまま使用可能
- rebase後はすべてのコミットハッシュが変更されるため、`--from`/`--to` で指定するハッシュは再取得が必須

## コミット前確認チェックリスト

コミット前に以下のコマンドで変更ファイルを確認:

```bash
git status
```

**重要ファイルの確認**（以下が含まれているか確認）:

- [ ] Unit定義ファイル: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
- [ ] 履歴ファイル: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
- [ ] 設計ファイル（作成した場合）: `docs/cycles/{{CYCLE}}/design-artifacts/`
- [ ] 実装ファイル（作成した場合）

各Unitで作成・変更したすべてのファイル（**Unit定義ファイルと履歴ファイルを含む**）をコミットに含めること。
