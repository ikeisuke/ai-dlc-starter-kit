# コミットフロー

## コミットタイミング

以下のタイミングで**必ず**コミットを作成する:

1. セットアップ完了時
2. Inception Phase完了時
3. 各Unit完了時
4. Operations Phase完了時

レビューフロー内でも以下でコミットする:

- AIレビュー/ユーザーレビュー前（変更がある場合のみ）
- レビュー反映後（修正があった場合のみ）

## コミットメッセージフォーマット

| ID | テンプレート | 使用場面 |
|-----|------------|---------|
| REVIEW_PRE | `chore: [{{CYCLE}}] レビュー前 - {ARTIFACT_NAME}` | レビュー前 |
| REVIEW_POST | `chore: [{{CYCLE}}] レビュー反映 - {ARTIFACT_NAME}` | レビュー反映後 |
| INCEPTION_COMPLETE | `feat: [{{CYCLE}}] Inception Phase完了 - {DESCRIPTION}` | Inception完了 |
| UNIT_COMPLETE | `feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}` | Unit完了 |
| UNIT_SQUASH_PREP | `chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備` | squash前中間コミット |
| INCEPTION_SQUASH_PREP | `chore: [{{CYCLE}}] Inception Phase完了 - 完了準備` | squash前中間コミット |
| OPERATIONS_COMPLETE | `chore: [{{CYCLE}}] Operations Phase完了 - {DESCRIPTION}` | Operations完了 |

Unit関連コミットには `Unit-Number: {NNN}` trailerを付与する。

### プレースホルダ

| プレースホルダ | 説明 |
|-------------|------|
| `{{CYCLE}}` | サイクル番号（`vX.X.X`） |
| `{NNN}` | Unit番号（3桁ゼロパディング） |
| `{DESCRIPTION}` | コミットの説明文 |
| `{ARTIFACT_NAME}` | 成果物名 |

## Co-Authored-By

AIツールを自動検出し、`Co-Authored-By` trailerを付与する。

| AIツール | ai_author値 |
|---------|-------------|
| Claude Code | `Claude <noreply@anthropic.com>` |
| Cursor | `Cursor <noreply@cursor.com>` |
| Cline | `Cline <noreply@cline.bot>` |
| Windsurf | `Windsurf <noreply@codeium.com>` |
| Codex CLI | `Codex <noreply@openai.com>` |
| KiroCLI | `Kiro <noreply@aws.com>` |

`rules.git.ai_author` が設定済みならその値を使用。未設定なら自己認識→環境変数→ユーザー確認の順で検出。

## 操作順序ルール【重要】

| 先行操作 | 後続操作 | 違反時 |
|---------|---------|--------|
| コミット完了 | PR作成 | 先にコミットする |
| 中間コミット完了 | スカッシュ実行 | 先にコミットする |
| AIレビューフロー完了 | ユーザーレビュー依頼 | 先にAIレビューを実行 |

順序違反を検知した場合、先行操作を実行してから再開する。

## コミット実行

1. `git status --porcelain` で変更を確認（なければスキップ）
2. `git add` でステージング
3. `git commit -m "メッセージ"` でコミット（複数行の場合は `-m "1行目" -m "2行目"`）
4. `git status` で完了確認

## Squash統合フロー

`rules.git.squash_enabled=true` の場合、フェーズ完了時に中間コミットを1つにまとめる。

### 前提チェック【必須】

`scripts/read-config.sh rules.git.squash_enabled` を実行し、結果に応じて分岐する:

| `read-config.sh` の結果 | 動作 | 戻り値 |
|------------------------|------|--------|
| exit 0 + stdout が `true` | 「Squash の実行」へ進む（次のセクション） | （実行結果次第） |
| exit 0 + stdout が `false` | Squash 実行せずフロー終了 | `squash:skipped`（ログ: `reason: squash_enabled=false`） |
| exit 1（キー不在） | Squash 実行せずフロー終了 | `squash:skipped`（ログ: `reason: squash_enabled=unset`） |
| exit 2 / その他のエラー | Squash 実行せずフロー終了（安全側） | `squash:skipped`（ログ: `reason: read-config.sh failed`） |

**判定上の注意**: `read-config.sh` は `false` を返した場合も exit 0 で終了する。`if scripts/read-config.sh ... ; then` のような exit code のみの判定は誤実行を招くため禁止。**exit code と stdout の両方を併せて評価する**こと。

**シグナル設計**: 既存の `squash:skipped` 文字列をそのまま使う（新シグナル文字列は導入しない）。呼び出し元（`04-completion.md` ステップ 7 / `inception/05-completion.md` ステップ 6）の既存 `squash:skipped` 分岐がそのまま機能する。`reason: ...` ログは前提チェック由来の `squash:skipped` でのみ出力され、`/squash-unit` 由来の `squash:skipped:no-commits` には付かない。

**判定パターン例**（`$(...)` コマンド置換禁止のプロジェクトルール準拠、ファイル経由 + `grep -Fxq`）:

```bash
scripts/read-config.sh rules.git.squash_enabled > /tmp/aidlc-squash-enabled.out 2>/dev/null
ec=$?
if [ "$ec" = "0" ] && grep -Fxq 'true' /tmp/aidlc-squash-enabled.out; then
    : # 「Squash の実行」へ進む
else
    case "$ec" in
        0) echo "reason: squash_enabled=false" ;;
        1) echo "reason: squash_enabled=unset" ;;
        *) echo "reason: read-config.sh failed" ;;
    esac
    echo "squash:skipped"
fi
rm -f /tmp/aidlc-squash-enabled.out
```

### Squash の実行

**`/squash-unit` スキルを使用する**。スキルが利用できない場合は `squash-unit.sh` を直接実行する。

| 呼び出し元 | squashメッセージID |
|-----------|-------------------|
| Construction（Unit完了時） | UNIT_COMPLETE |
| Inception（Phase完了時） | INCEPTION_COMPLETE |

## コミット前確認チェックリスト

コミット前に `git status` で以下が含まれているか確認:

- [ ] Unit定義ファイル
- [ ] 履歴ファイル
- [ ] 設計ファイル（作成した場合）
- [ ] 実装ファイル（作成した場合）
