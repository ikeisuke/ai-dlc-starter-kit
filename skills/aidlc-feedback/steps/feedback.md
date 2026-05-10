# フィードバック送信

「AIDLCフィードバック」「aidlc feedback」と言われた場合、以下の手順でフィードバック送信を案内する。

> **v2.6.1（Unit 003 / #690）以降**: feedback Issue の起票デフォルト経路をブラウザ自動起動（`gh issue create --web`）から直接起票（`gh issue create --body-file`）に変更した（opt-in 化）。経路判定の優先順位は **TTY 状態 > 設定 > フラグ**。詳細真理値表は `SKILL.md` 参照。テンプレート構造は `.github/ISSUE_TEMPLATE/feedback.yml` を SoT として参照する。

## 設定確認

最初に `.aidlc/config.toml` の設定を確認する：

```bash
# .aidlc/config.toml が存在しない場合は true（デフォルト有効）として続行
# read-config.sh は aidlc プラグイン側に存在するため、リポジトリルート相対の絶対参照で呼び出す
if [[ ! -f .aidlc/config.toml ]]; then
  echo "true"
else
  bash skills/aidlc/scripts/read-config.sh rules.feedback.enabled
fi
```

**エラーハンドリング**:

- `.aidlc/config.toml` 不在（事前 `[[ -f ]]` チェック）: `true`（デフォルト有効）として続行。初回セットアップ前の正常ケース
- `read-config.sh` exit 0（標準出力に値あり）: 値が `false` なら無効化メッセージ表示で終了、それ以外は続行
- `read-config.sh` exit 1（キー不在）: デフォルト値 `true` として続行（`[rules.feedback]` 未設定の正常ケース）
- `read-config.sh` exit 2（エラー: dasel 未インストール / TOML 破損等）: ユーザーに送信可否を対話確認（自動判定しない）

**`false` の場合**:

以下のメッセージを表示して終了する（ヒアリング・Issue作成・URL案内は行わない）。

```text
【フィードバック送信機能 無効】
この機能は無効化されています。
`.aidlc/config.toml` の `[rules.feedback].enabled` を `true` に設定することで有効化できます。
```

**`false` 以外の場合（デフォルト: `true`）**:

以下の手順に進む。

## 手順

### 1. フィードバック内容のヒアリング

- 改善提案、要望、バグ報告、感想などを自由に入力してもらう
- 必要に応じて詳細を質問する

### 2. 起票経路の判定（v2.6.1 / Unit 003 / #690）

経路判定の SoT は `.aidlc/cycles/v2.6.1/story-artifacts/user_stories.md` ストーリー 3 真理値表 6 行（および本スキルの `SKILL.md` に再掲）。判定ロジックは純関数 `resolve_feedback_route` に集約しており、AI エージェントは以下の手順でこの関数を呼び出して採用経路を確定する。

#### 2-1. `open_in_browser` 設定の取得 + 正規化

```bash
# 設定値を取得（exit 0 で値、exit 1 で未設定、exit 2 でエラー）
# set +e で囲んで read-config.sh の本来の exit code を保持する
# （`|| true` で繋ぐと true の exit 0 が $? に入って exit 1/2 判定が壊れるため禁止）
set +e
raw_value="$(bash skills/aidlc/scripts/read-config.sh rules.feedback.open_in_browser 2>/dev/null)"
exit_code=$?
set -e

# 正規化（型不一致 / exit 2 のときヘルパー内で警告 1 行 stderr 出力）
setting="$(bash skills/aidlc-feedback/scripts/lib/resolve-route.sh normalize-setting "$exit_code" "$raw_value")"
```

`setting` は `true` / `false` / `unset_or_invalid` のいずれか。正規化規則は以下（`normalize_setting` ヘルパーで一元化、bats でテスト網羅済）:

| `exit_code` | `raw_value` の値 | `setting` 正規化結果 | 警告ログ（stderr / ヘルパーが出力） |
|-------------|------------------|-------------------|----------------------------------|
| 0 | `"true"` | `true` | なし |
| 0 | `"false"` | `false` | なし |
| 0 | 上記以外（型不一致） | `unset_or_invalid` | `warning: rules.feedback.open_in_browser has invalid value; falling back to direct route` |
| 1（キー不在） | -（空） | `unset_or_invalid` | なし（未設定の正常ケース） |
| 2（エラー） | -（空） | `unset_or_invalid` | `warning: failed to read rules.feedback.open_in_browser (exit 2); falling back to direct route` |

#### 2-2. TTY 状態の判定

```bash
if [[ -t 0 ]]; then
  is_tty=true
else
  is_tty=false
fi
```

#### 2-3. 明示フラグ（`AIDLC_FEEDBACK_WEB`）の正規化

明示フラグの SoT は環境変数 `AIDLC_FEEDBACK_WEB`（`1` / `true` / `yes`（大小文字無視・前後空白除去後）で真）。`resolve-route.sh` の `normalize_explicit_web` ヘルパーで正規化する:

```bash
explicit_web="$(bash skills/aidlc-feedback/scripts/lib/resolve-route.sh normalize-explicit-web "${AIDLC_FEEDBACK_WEB:-}")"
```

#### 2-4. 採用経路の判定

```bash
route="$(bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve "$setting" "$explicit_web" "$is_tty")"
```

`route` は `web` または `direct` のいずれか。

#### 2-5. 強制無効化警告（`is_tty=false` かつ `setting=true` または `explicit_web=true` の場合）

`resolve_feedback_route` は純関数のため、警告ログの出力は呼び出し側（本手順）の責務である。判定 + 警告出力を `resolve-route.sh` のヘルパーに委譲する（bats でテスト網羅済）:

```bash
if [[ "$(bash skills/aidlc-feedback/scripts/lib/resolve-route.sh should-warn-override "$setting" "$explicit_web" "$is_tty")" == "true" ]]; then
  bash skills/aidlc-feedback/scripts/lib/resolve-route.sh emit-override-warning
fi
```

### 3. Issue の作成

#### 3-A. `route=web` の場合（ブラウザ経路、opt-in）

GitHub Issue Form (`feedback.yml`) をブラウザ UI で表示する。`gh` CLI が直接 form 展開する。

1. Writeツールで一時ファイルを作成（内容: フィードバック本文の素案、ユーザーがブラウザで編集する起点として使用）
2. 以下を実行:

   ```bash
   gh issue create --web \
     --repo ikeisuke/ai-dlc-starter-kit \
     --template feedback.yml \
     --title "[Feedback] タイトル" \
     --body-file <一時ファイルパス>
   ```

3. 一時ファイルを削除

#### 3-B. `route=direct` の場合（直接起票、デフォルト挙動）

GitHub Issue Form (`feedback.yml`) は `--web` フラグでのみ form として展開される（`gh issue create -T` は Markdown テンプレート専用で YAML form には非対応）。そのため AI エージェントは `feedback.yml` を SoT として読み取り、`body[*].attributes.label` を Markdown 見出しに変換して本文を組み立てる:

1. **`feedback.yml` 読取**: Read ツールで `.github/ISSUE_TEMPLATE/feedback.yml` を読み込む
2. **本文の組み立て**:
   - `body` 配列を順に走査
   - `type: markdown` → `value` フィールドの内容をそのまま本文に含める
   - `type: textarea` / `type: input` → `attributes.label` を `## ラベル` として Markdown 見出しに変換し、その下に手順 1 のヒアリング内容を該当 label に対応する形で配置（label の英/日併記は維持）
   - `validations.required: false` の field でヒアリング内容がない場合: 「（任意 / 未記入）」と明記して空セクションとして残す
   - **未知 `type`（`dropdown` / `checkboxes` 等、将来追加分）が現れた場合**: `## ラベル（type=<type>、AI による自動展開非対応）` 見出しに変換し、本文中に `<未対応 type のため Web 経路での起票を推奨。本フィールドは未記入>` プレースホルダを書く。さらに stderr に警告 1 行を出力: `warning: feedback.yml has unsupported field type '<type>' for direct route; please use AIDLC_FEEDBACK_WEB=1 to file via web UI`（fail-fast はしない）
3. **一時ファイル書込み**: 上記で組み立てた Markdown 本文を Write ツールで一時ファイル（例: `/tmp/aidlc-feedback-direct-<UUID>.md`）に書き出す
4. **Issue 起票**:

   ```bash
   gh issue create \
     --repo ikeisuke/ai-dlc-starter-kit \
     --label feedback \
     --title "[Feedback] タイトル" \
     --body-file <一時ファイルパス>
   ```

5. **一時ファイル削除**

### 4. GitHub CLI が利用できない場合

- 以下のURLを案内する
- `https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feedback.yml`

## 注意事項

- ブラウザ経路（`route=web`）では Issue 作成は自動で行わず、必ずブラウザで確認画面を開く（ユーザーが「Submit」ボタンを押すまで Issue は作成されない）
- 直接起票経路（`route=direct`）では AI エージェントが手順 1 のヒアリング内容をユーザーに事前確認した上で起票する（事前確認なしの直接起票は禁止）
- `feedback.yml` の構造を変更した場合、既知 `type`（`markdown` / `textarea` / `input`）の範囲では本手順書の追従不要（自動的に新 label が見出しに変換される）。新 `type` 追加時は別 Issue / Unit で本手順書を更新する
- `gh issue create -T feedback.yml --body-file ...` の挙動が将来変わった場合（YAML form 対応）、本手順書の `direct` 経路を簡素化する余地あり（v2.6.1 設計時点では `--web` 必須）

### `gh issue create` への引数渡しの安全性（コードレビュー Round 1 #3 反映）

ユーザー入力（タイトル・本文）を `gh issue create` に渡す際は、必ず**単一の引数**として渡し、シェルでの再分割を防ぐこと:

- `--title "<タイトル>"` のように常にダブルクォートで囲み、変数に格納する場合も `--title "$title"` のように引用符で囲む
- 本文は `--body` 直接指定ではなく `--body-file "$tmpfile"` を使う（複数行・特殊文字のエスケープを `gh` 側に委ねる）
- 一時ファイルパスはダブルクォートで囲む: `--body-file "<一時ファイルパス>"`
- ヒアドキュメント生成時の `EOF` 終端は引用符付き（`<<'EOF'`）でメタ文字展開を抑止する（必要に応じて）
- ユーザー入力を直接コマンド置換 `$(...)` / バッククォート に渡さない（コマンド注入余地を作らない）
