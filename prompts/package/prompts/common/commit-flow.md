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

`.aidlc/config.toml` の `[rules.commit]` セクションで制御:

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

### 操作順序ルール【重要】

以下の操作は定められた順序で実行すること。AIは各操作の実行前に先行操作の完了を確認し、順序違反を検知した場合は自己修正する。

#### 順序制約テーブル

| # | 先行操作 | 後続操作 | 前提条件 | 違反時アクション |
|---|---------|---------|---------|---------------|
| 1 | コミット完了 | PR作成 | 常時 | 停止→未コミット変更をコミットしてからPR作成を再開 |
| 2 | 中間コミット完了 | スカッシュ実行 | `rules.squash.enabled = true` かつユーザー同意 | 停止→未コミット変更を中間コミットしてからスカッシュを実行（`squash:success` 時はUnit完了コミットをスキップ） |
| 3 | AIレビューフロー完了（実施またはスキップ承認） | ユーザーレビュー依頼 | `rules.reviewing.mode != "disabled"` | 停止→AIレビューフロー（`review-flow.md`）を先に実行。`recommend` モードではユーザーのスキップ承認も「完了」として扱う |

**スコープ外の順序制約**（各フェーズプロンプトで管理）:

- 全Unit完了 → Operations Phase移行: `construction.md` の完了基準を参照
- 設計承認 → 実装開始: `construction.md` のPhase 1/Phase 2分離を参照

#### 順序違反検知時の自己修正フロー

AIが順序違反を検知した場合、以下の手順で自己修正する:

1. **検知**: 後続操作の実行前に、順序制約テーブルを参照し先行操作が完了しているか確認
2. **違反判定**: 先行操作が未完了の場合、順序違反と判定
3. **先行操作の特定**: 違反したルールから実行すべき先行操作を特定
4. **先行操作の実行**: 特定した先行操作を実行（例: 未コミット変更をコミット）
5. **再開**: 先行操作の完了後、元の後続操作を再開

## コミット実行の共通手順

すべてのコミットは以下の手順で実行する:

1. `git status --porcelain` で変更を確認（変更がない場合はスキップ）
2. `mktemp /tmp/aidlc-commit-msg.XXXXXX` で一時ファイルパスを生成
3. Writeツールで一時ファイルにコミットメッセージを書き込む（内容は各セクションのテンプレートを使用）
4. `git add -A`（または指定ファイルのみ）でステージング
5. `git commit -F <一時ファイルパス>` でコミット
6. 一時ファイルを削除
7. `git status` でコミット完了を確認（期待: `nothing to commit, working tree clean`）
8. 変更が残っている場合は追加コミットを実施

## レビューコミット手順

### レビュー前コミット

変更がある場合のみ、共通手順に従いコミット。メッセージテンプレート:

```text
chore: [{{CYCLE}}] レビュー前 - {ARTIFACT_NAME}

Co-Authored-By: {AI_AUTHOR}
```

### レビュー反映コミット

修正があった場合のみ、共通手順に従いコミット。メッセージテンプレート:

```text
chore: [{{CYCLE}}] レビュー反映 - {ARTIFACT_NAME}

Co-Authored-By: {AI_AUTHOR}
```

## フェーズ完了コミット手順

**共通注意**: Squash統合フローでsquashを実行した場合（`squash:success`）、コミットは既に完了しています。`git status` で確認のみ行い、新規コミットは作成しません。

### Inception Phase完了コミット

Inception Phaseで作成・変更したすべてのファイル（**inception/progress.md、履歴ファイルを含む**）をコミット。メッセージテンプレート:

```text
feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}

Co-Authored-By: {AI_AUTHOR}
```

### Unit完了コミット

「コミット前確認チェックリスト」を確認した後、共通手順に従いコミット。メッセージテンプレート:

```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}

Unit-Number: {NNN}
Co-Authored-By: {AI_AUTHOR}
```

### Operations Phase完了コミット

Operations Phaseで作成したすべてのファイル（**operations/progress.md、履歴ファイルを含む**）をコミット。メッセージテンプレート:

```text
chore: [{{CYCLE}}] Operations Phase完了 - {DESCRIPTION}

Co-Authored-By: {AI_AUTHOR}
```

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
skills/aidlc/scripts/read-config.sh rules.squash.enabled
```

- `true` の場合: 以下の手順を実行
- `false`、未設定の場合: このフローをスキップ

### ユーザー確認・中間コミット

1. **ユーザー確認**（中間コミット作成前に実施）:

```text
中間コミット（レビュー前/反映コミット等）を1つの完了コミットにsquashしますか？

1. はい - squashを実行する（推奨）
2. いいえ - squashをスキップして通常コミットを行う
```

2. **「いいえ」の場合**: フローを終了し、通常コミットに進む（未コミット変更は通常コミットで処理される）

3. **「はい」の場合 - 未コミット変更のコミット**: 変更ファイルが未コミットの場合、中間コミットとして作成（squash-unit.shはclean working treeを前提とするため、先にコミットする）。未コミット変更がない場合はスキップ。

   「適用対象判定」テーブルの中間コミットメッセージテンプレートを使用し、共通手順に従いコミット（ステージングは `git add <変更ファイル>` で対象ファイルのみ）。

   **Unit完了squashのメッセージテンプレート**:

   ```text
   chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

   Unit-Number: {NNN}
   Co-Authored-By: {AI_AUTHOR}
   ```

   **Inception Phase完了squashのメッセージテンプレート**:

   ```text
   chore: [{{CYCLE}}] Inception Phase完了 - 完了準備

   Co-Authored-By: {AI_AUTHOR}
   ```

   **clean状態の検証**（中間コミット後、またはスキップ後）:

   ```bash
   git status --porcelain
   ```

   出力が空であることを確認。空でない場合: 残りの変更を追加コミットする。

### 起点コミット特定・Squash実行

4. **起点コミットの特定（`--base`）**:

   squash対象の範囲を正確に制御するため、AIが起点コミットを判定して `--base` で明示指定する。

   **判定手順**:

   ```bash
   git log --oneline -20
   ```

   ログを確認し、squash対象範囲の起点となるコミットを特定する。

   **フェーズ別の判定基準**:

   | フェーズ | 判定基準 |
   |---------|---------|
   | Unit完了squash | 前Unitの完了コミット（`feat: [{{CYCLE}}] Unit {前のNNN}完了`）、またはサイクル開始コミット（`feat: [{{CYCLE}}] Inception Phase完了`）のハッシュ |
   | Inception Phase完了squash | `git merge-base origin/main HEAD`（サイクルブランチの分岐点）。`origin/main` が存在しない場合はユーザーに起点コミットを確認 |

5. **squash実行**:

   「適用対象判定」テーブルのsquashコミットメッセージテンプレートを使用。`mktemp /tmp/aidlc-squash-msg.XXXXXX` でパスを生成し、Writeツールでメッセージを書き込む。

   **Unit完了squashのメッセージテンプレートとコマンド**:

   ```text
   feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

   Unit-Number: {NNN}
   ```

   ```bash
   skills/aidlc/scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs git --base '<起点コミット>' --message-file <mktemp生成パス>
   ```

   **Inception Phase完了squashのメッセージテンプレートとコマンド**:

   ```text
   feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}
   ```

   ```bash
   skills/aidlc/scripts/squash-unit.sh --cycle '{{CYCLE}}' \
     --vcs git --base '<起点コミット>' --message-file <mktemp生成パス>
   ```

   実行後、一時ファイルを削除。結果に応じた処理:

   - `squash:success` の場合: squash完了。通常コミットをスキップ
   - `squash:skipped:no-commits` の場合: 「squash対象のコミットがありません。通常コミットに進みます。」と表示してスキップ
   - `squash:error` の場合: エラーメッセージと recovery コマンドをユーザーに提示し、対応を確認

### 事後squash（retroactive）

過去のUnit（HEADの最新Unitではない）のコミットを後からsquashする場合に使用する。通常のsquash（`git reset --soft` 方式）では過去のUnitを対象にできないため、`--retroactive` オプションでGIT_SEQUENCE_EDITOR方式の非対話的rebaseを実行する。

**使用条件**:

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
   skills/aidlc/scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs git --retroactive --dry-run --message-file /tmp/aidlc-squash-msg.txt
   ```

   出力の `unit_range` と `unit_commit_count` で対象範囲を確認する。

2. **事後squash実行**:

   前のステップと同じ一時ファイルを再利用（または新たに作成）:

   ```bash
   skills/aidlc/scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
     --vcs git --retroactive --message-file /tmp/aidlc-squash-msg.txt
   ```

   一時ファイルを削除

   - `squash:success` の場合: 事後squash完了
   - `squash:error:unit-not-found` の場合: 対象Unitのコミットが見つからない。コミットメッセージのパターンを確認
   - `squash:error:conflict` の場合: rebase中にコンフリクト発生。自動的に `git rebase --abort` で復帰済み。手動での対応が必要


**`--from`/`--to` によるコミット範囲の手動指定**:

コミットメッセージのパターンやトレーラーによる自動検出が失敗した場合、`--from`/`--to` でUnit境界を手動指定できる。

1. 対象コミットの特定:

```bash
git log --oneline -30
```

2. Writeツールで一時ファイルを作成（内容: squashメッセージ）:

```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {UNIT_NAME}

Unit-Number: {NNN}
```

3. 対象範囲を --from/--to で指定（--base は不要）:

```bash
skills/aidlc/scripts/squash-unit.sh --cycle '{{CYCLE}}' --unit '{NNN}' \
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

- [ ] Unit定義ファイル: `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`
- [ ] 履歴ファイル: `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
- [ ] 設計ファイル（作成した場合）: `.aidlc/cycles/{{CYCLE}}/design-artifacts/`
- [ ] 実装ファイル（作成した場合）

各Unitで作成・変更したすべてのファイル（**Unit定義ファイルと履歴ファイルを含む**）をコミットに含めること。
