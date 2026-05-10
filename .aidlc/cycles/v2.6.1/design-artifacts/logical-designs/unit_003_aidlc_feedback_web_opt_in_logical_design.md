# 論理設計: Unit 003 aidlc-feedback の `--web` 強制起動解消（opt-in 化）

## 概要

`/aidlc feedback` の Issue 起票経路選択を、ドメインモデルに従って実装するための論理設計。`feedback.md` 手順書 + 純関数ヘルパー（`resolve-route.sh`）+ bats テストの 3 層構造で真理値表 6 行を表現する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**採用パターン**: 「手順書（AI エージェント向け）+ 純関数ヘルパー + テスト」の 3 層構成（既存スキルパターン踏襲）

**選定理由**:

- `feedback.md` は AI エージェントが解釈する手順書のため、判定ロジックを直接埋めると bats による真理値表 6 行の機械検証が困難（計画レビュー Round 1 指摘 #1 対応）
- 判定ロジックを純関数 `resolve_feedback_route` に抽出することで、AI 解釈経路と機械検証経路を分離する
- 警告ログ（副作用）は呼び出し側（`feedback.md` 内のフロー）に分離することで純関数性を保ち、ユニットテストを単純化（計画レビュー Round 1 指摘 #2 対応）
- 既存 `skills/aidlc/scripts/lib/feedback-mode.sh` 等が同じパターン（純関数 `feedback_cap_check` を bats でテスト）を採用しており、整合性が取れる

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-feedback/
├── SKILL.md                              # スキルエントリポイント（真理値表追記）
├── steps/
│   └── feedback.md                       # 手順書（手順 2 改訂、resolve-route.sh 呼出）
└── scripts/
    └── lib/
        └── resolve-route.sh              # 純関数判定ヘルパー（新規）

skills/aidlc/
└── config/
    └── defaults.toml                     # [rules.feedback].open_in_browser = false 追加

tests/
└── feedback-route-resolution.bats        # 真理値表 6 行 + 入力正規化テスト（新規）

.aidlc/cycles/v2.6.1/plans/
└── unit-003-plan.md                      # CHANGELOG 草案セクション（既存ファイル末尾追記）
```

### コンポーネント詳細

#### feedback.md（手順書、改訂）

- **責務**: AI エージェントに対し、設定読取 → TTY 判定 → `resolve_feedback_route` 呼出 → 採用経路に応じた `gh issue create` 実行という手順を提示する
- **依存**:
  - `skills/aidlc/scripts/read-config.sh`（設定読取、Unit 004 規約準拠）
  - `skills/aidlc-feedback/scripts/lib/resolve-route.sh`（経路判定）
  - `gh` CLI（Issue 起票実行）
- **公開インターフェース**: `/aidlc feedback` 経由で AI エージェントが本ファイルを読み込み手順を実行する
- **警告ログ責務**: `resolve_feedback_route` の入力と判定結果の差分を見て、必要時に stderr へ 1 行出力（純関数の責務外）

#### resolve-route.sh（新規、純関数ヘルパー）

- **責務**: 3 値（setting / explicit_web / is_tty）から採用経路（`web` / `direct`）を導出する純関数 `resolve_feedback_route` を提供
- **依存**: bash builtin のみ（外部コマンド呼び出しなし）
- **公開インターフェース**: `resolve_feedback_route` 関数（後述「スクリプトインターフェース設計」参照）
- **副作用**: なし（stderr / ファイル / ネットワーク I/O 全てなし）

#### SKILL.md（改訂）

- **責務**: スキルエントリポイントとして、変更概要・優先順位真理値表・opt-in 手順を AI エージェントとユーザーに提示
- **依存**: `steps/feedback.md`
- **公開インターフェース**: スキル description（`/aidlc feedback` 起動経路）

#### feedback-route-resolution.bats（新規、テスト）

- **責務**: `resolve_feedback_route` 関数の真理値表 6 行 + 入力正規化境界ケースを検証
- **依存**: `skills/aidlc-feedback/scripts/lib/resolve-route.sh`、bats-core
- **公開インターフェース**: `bats tests/feedback-route-resolution.bats`

## インターフェース設計

### API エンドポイント

該当なし（CLI スキルのため）。

### コマンド

#### `/aidlc feedback` 実行フロー（feedback.md 改訂後）

- **トリガー**: ユーザーが `/aidlc feedback` を実行
- **手順 1（既存維持）**: フィードバック内容のヒアリング
- **手順 2（改訂）**:
  1. **enabled 確認**（既存維持）: `bash skills/aidlc/scripts/read-config.sh rules.feedback.enabled` の結果が `false` なら無効化メッセージで終了
  2. **open_in_browser 設定読取**: `bash skills/aidlc/scripts/read-config.sh rules.feedback.open_in_browser`
     - exit 0 + 値 `true` → `setting=true`
     - exit 0 + 値 `false` → `setting=false`
     - exit 0 + 上記以外（型不一致）→ `setting=unset_or_invalid` + 警告（stderr）
     - exit 1（キー不在）→ `setting=unset_or_invalid`（警告なし、デフォルトケース）
     - exit 2（エラー）→ `setting=unset_or_invalid` + 警告（stderr）
  3. **TTY 判定**: `[[ -t 0 ]]` で `is_tty` を確定
  4. **明示フラグ判定**: 環境変数 `${AIDLC_FEEDBACK_WEB:-}` を入力正規化規則（後述）に従って `explicit_web` を確定
  5. **経路判定**: `bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve "$setting" "$explicit_web" "$is_tty"`（または `source` してから関数呼出）
  6. **警告ログ**（**呼び出し側責務**、設計レビュー Round 1 #1 反映）: 以下のいずれかの条件を満たす場合に stderr へ警告 1 行を出力
     - **強制無効化警告**: `is_tty=false` ∧ (`setting=true` ∨ `explicit_web=true`) → `warning: open_in_browser/AIDLC_FEEDBACK_WEB is overridden by non-TTY environment; using direct route`
     - **設定値型不一致警告**: `read-config.sh` exit 0 で値が `true`/`false` 以外 → `warning: rules.feedback.open_in_browser has invalid value; falling back to direct route`
     - **設定読取エラー警告**: `read-config.sh` exit 2 → `warning: failed to read rules.feedback.open_in_browser (exit 2); falling back to direct route`
     - 上記いずれにも該当しない場合は警告なし（無音動作）
  7. **Issue 作成**:
     - `route=web` → `gh issue create --web --repo ikeisuke/ai-dlc-starter-kit --template feedback.yml --title "[Feedback] タイトル" --body-file <一時ファイル>`（既存挙動。GitHub Issue Form `feedback.yml` をブラウザ UI で表示）
     - `route=direct` → `gh issue create --repo ikeisuke/ai-dlc-starter-kit --label feedback --title "[Feedback] タイトル" --body-file <一時ファイル>`（`--web` / `--template` なし。本文構造は **`.github/ISSUE_TEMPLATE/feedback.yml` を SoT として AI が `body[*].attributes.label` を Markdown 見出しに展開**して `<一時ファイル>` に書き込む。詳細は本ファイル §「`feedback.yml` テンプレート参照ルール」参照）
  8. **一時ファイル削除**（既存維持）

#### `resolve_feedback_route` 関数

- **パラメータ**:
  - `$1: setting` - `"true"` / `"false"` / `"unset_or_invalid"` の 3 値
  - `$2: explicit_web` - `"true"` / `"false"` の 2 値（呼び出し側で正規化済み）
  - `$3: is_tty` - `"true"` / `"false"` の 2 値（呼び出し側で `[[ -t 0 ]]` 結果から正規化）
- **戻り値**: stdout に `"web"` または `"direct"` を出力 + exit 0
- **エラー**: 入力が許容値以外 → exit 1（stderr に `"error: invalid input: ..."`）

### クエリ

該当なし。

## スクリプトインターフェース設計

### resolve-route.sh

#### 概要

feedback Issue 起票経路を判定する純関数 `resolve_feedback_route` を提供するシェルスクリプトライブラリ。

#### 引数（`source` 経由でのライブラリ利用が主）

主な利用形態は `source skills/aidlc-feedback/scripts/lib/resolve-route.sh` 後の関数呼出だが、CLI モードもテスト便宜のため提供する。

**CLI モード**:

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (subcommand) | 必須 | `resolve` 固定 |
| `$2` (setting) | 必須 | `true` / `false` / `unset_or_invalid` |
| `$3` (explicit_web) | 必須 | `true` / `false` |
| `$4` (is_tty) | 必須 | `true` / `false` |

**ライブラリモード（推奨）**:

```bash
source skills/aidlc-feedback/scripts/lib/resolve-route.sh
route="$(resolve_feedback_route "$setting" "$explicit_web" "$is_tty")"
```

#### 成功時出力

```text
web
```

または

```text
direct
```

- 終了コード: `0`
- 出力先: stdout（改行付き）

#### エラー時出力

CLI モードのエラー仕様（設計レビュー Round 1 #4 反映）:

| エラー種別 | 終了コード | stderr メッセージ例 |
|----------|----------|------------------|
| 引数 0 個 / `subcommand` 不在 | `1` | `usage: resolve-route.sh resolve <setting> <explicit_web> <is_tty>` |
| 不明な `subcommand`（`resolve` 以外） | `1` | `error: unknown subcommand: '<value>' (expected 'resolve')` + 上記 usage 行 |
| `subcommand=resolve` 指定だが引数 < 4（不足） | `1` | `error: missing arguments for 'resolve'` + 上記 usage 行 |
| `setting` が許容値外 | `1` | `error: invalid input: setting='<value>' (expected: true / false / unset_or_invalid)` |
| `explicit_web` が許容値外 | `1` | `error: invalid input: explicit_web='<value>' (expected: true / false)` |
| `is_tty` が許容値外 | `1` | `error: invalid input: is_tty='<value>' (expected: true / false)` |

- 終了コード: `1`（入力不正、すべて統一）
- 出力先: stderr
- 上記すべてのエラーケースは bats テストで網羅する

#### 使用コマンド（テスト・デバッグ用）

```bash
# CLI モード
bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve true false true   # → "web"
bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve true false false  # → "direct"
bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve unset_or_invalid true true   # → "web"
bash skills/aidlc-feedback/scripts/lib/resolve-route.sh resolve false false true  # → "direct"

# ライブラリモード
source skills/aidlc-feedback/scripts/lib/resolve-route.sh
resolve_feedback_route "true" "false" "true"      # → "web"
```

### 入力正規化規則（feedback.md 側責務）

#### `setting` の正規化

`read-config.sh` の出力（exit code + stdout）から `OpenInBrowserSetting.value` を導出:

| read-config.sh 出力 | 正規化結果 | 警告 |
|--------------------|----------|------|
| exit 0 + stdout `"true"` | `true` | なし |
| exit 0 + stdout `"false"` | `false` | なし |
| exit 0 + stdout 上記以外 | `unset_or_invalid` | あり（型不一致） |
| exit 1 | `unset_or_invalid` | なし（未設定の正常ケース） |
| exit 2 | `unset_or_invalid` | あり（エラーフォールバック） |

#### `explicit_web` の正規化

環境変数 `AIDLC_FEEDBACK_WEB` から `ExplicitWebFlag.value` を導出（**SoT**: 計画レビュー Round 1 で確定）:

```bash
# bash 擬似コード（実装は Phase 2）
raw="${AIDLC_FEEDBACK_WEB:-}"
trimmed="${raw#"${raw%%[![:space:]]*}"}"   # 先頭空白除去
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"  # 末尾空白除去
lower="$(printf '%s' "$trimmed" | tr '[:upper:]' '[:lower:]')"
case "$lower" in
  1|true|yes) explicit_web=true ;;
  *) explicit_web=false ;;
esac
```

正規化規則（論点 3 の細部、設計フェーズで確定）:

- 前後空白を除去
- 大文字を小文字に正規化
- `1` / `true` / `yes` のいずれかと完全一致 → `true`
- それ以外（空文字 / `0` / `false` / `no` / `2` / 任意の文字列）→ `false`

#### `is_tty` の正規化

`[[ -t 0 ]]` を実行し、真偽値を文字列 `"true"` / `"false"` に変換:

```bash
if [[ -t 0 ]]; then
  is_tty=true
else
  is_tty=false
fi
```

## データモデル概要

### 設定キー（既存ファイルへの追加）

#### `skills/aidlc/config/defaults.toml`

`[rules.feedback]` セクションに以下を追加:

- **キー**: `open_in_browser`
- **型**: boolean
- **デフォルト**: `false`
- **説明**: feedback Issue 起票時にブラウザを自動起動するか。`true` で従来挙動（`gh issue create --web`）、`false` で直接起票（推奨）

#### `.aidlc/config.toml`（プロジェクト固有上書き）

本 Unit ではプロジェクトの `.aidlc/config.toml` を直接書き換えない（既存スキルベースの defaults を変更し、ユーザーが必要時に project-local で上書き）。

### ファイル形式

- **形式**: TOML（既存 `.aidlc/config.toml` に追従）
- **新規追加フィールド**: `[rules.feedback].open_in_browser: boolean`

## 処理フロー概要

### `/aidlc feedback` 実行時の処理フロー

**ステップ**:

1. AI エージェントが `feedback.md` を読み込む
2. 手順 1: フィードバック内容ヒアリング（既存維持）
3. 手順 2-1: `feedback.enabled` 確認（既存維持）
4. 手順 2-2: `read-config.sh rules.feedback.open_in_browser` で設定読取 → `setting` 正規化
5. 手順 2-3: `[[ -t 0 ]]` で `is_tty` 判定
6. 手順 2-4: `${AIDLC_FEEDBACK_WEB:-}` 正規化で `explicit_web` 確定
7. 手順 2-5: `resolve_feedback_route "$setting" "$explicit_web" "$is_tty"` 呼出 → `route` 取得
8. 手順 2-6: 必要時に stderr へ警告 1 行出力
9. 手順 2-7: `route` に応じて `gh issue create` 実行（`--web` 付与の有無）
10. 手順 2-8: 一時ファイル削除（既存維持）

**関与するコンポーネント**: `feedback.md`、`read-config.sh`、`resolve-route.sh`、`gh` CLI

### resolve_feedback_route 内部処理フロー

```text
function resolve_feedback_route(setting, explicit_web, is_tty):
    if setting NOT IN {"true", "false", "unset_or_invalid"}:
        emit error to stderr; return exit 1
    if explicit_web NOT IN {"true", "false"}:
        emit error to stderr; return exit 1
    if is_tty NOT IN {"true", "false"}:
        emit error to stderr; return exit 1

    if is_tty == "false":
        echo "direct"; return exit 0

    if setting == "true":
        echo "web"; return exit 0

    # setting in {"false", "unset_or_invalid"} かつ is_tty == "true"
    if explicit_web == "true":
        echo "web"; return exit 0

    echo "direct"; return exit 0
```

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 直接起票の場合、ブラウザ起動コスト分（数秒）の改善（Unit 定義 NFR）
- **対応策**: 直接起票経路では `gh issue create --body-file` を即時実行（ブラウザ起動なし）。判定処理は純関数のため数 ms 以内

### セキュリティ

- **要件**: feedback 本文に機密情報が混入しないよう、ヒアリング時のレビュー継続。マスクポリシーは review-flow.md 既定に従う（Unit 定義 NFR）
- **対応策**: 手順 1 のヒアリングフローは既存維持。`resolve-route.sh` は本文を扱わない（経路判定のみ）。`gh issue create --body-file` 経由のため shell エスケープ問題は最小化（既存 `tests/retrospective-issue-create.bats` 等で実績あり）

### スケーラビリティ

- **要件**: 複数件連続起票時の摩擦をゼロにする（Unit 定義 NFR）
- **対応策**: 直接起票経路ではユーザー操作不要のため、AI エージェントが auto mode で連続起票可能。`AIDLC_FEEDBACK_WEB=1` を 1 回設定すれば従来挙動も再現可能

### 可用性

- **要件**: gh CLI 経由のため変化なし（Unit 定義 NFR）
- **対応策**: 既存 `gh issue create` 経路を維持。失敗時は stderr に exit code を出力し非 0 終了

## 技術選定

- **言語**: bash（既存スキルと統一）
- **フレームワーク**: なし
- **ライブラリ**: bats-core（テスト用、既存導入済）
- **依存ツール**: `gh` CLI（既存依存）、bash 4.0+（builtin `[[ -t 0 ]]` 等）
- **データベース**: なし

## 実装上の注意事項

### セキュリティ

- 環境変数 `AIDLC_FEEDBACK_WEB` の値は文字列比較のみ（コマンド実行・ファイル参照に使わない）。シェルインジェクション余地なし
- `setting` を `read-config.sh` 経由で取得するため、TOML パース由来のエラーは `read-config.sh` で吸収される（exit 2 → `unset_or_invalid` フォールバック）
- `gh issue create --body-file` 経由のため、本文の shell エスケープは不要（既存パターン踏襲）

### パフォーマンス

- 純関数 `resolve_feedback_route` は条件分岐 4 回程度で完結。ブラウザ起動コストの削減（数秒 → ms オーダー）が主な改善
- `read-config.sh` 呼出は 1 回（`open_in_browser` の 1 キーのみ）

### 保守性・拡張性

- 真理値表 6 行を `user_stories.md` SoT として固定。将来の拡張（例: `--web` 以外の経路追加）は別 Unit / 別 Issue で対応
- `resolve_feedback_route` の純関数性を保つため、副作用追加は禁止（警告ログは呼び出し側責務）
- 新規キー `open_in_browser` の値は boolean 限定。enum 化（`always` / `auto` 等）は将来検討

### 論点 1 の確定（実装構造）

- **確定**: `skills/aidlc-feedback/scripts/lib/resolve-route.sh` を新規追加し、純関数 `resolve_feedback_route` を抽出する（計画段階の主案を踏襲）
- **理由**: bats による真理値表 6 行の機械検証を直接的に実現できる。既存 `feedback-mode.sh` パターンとも整合

### 論点 2 の確定（bats 配置）

- **確定**: `tests/feedback-route-resolution.bats` 直下に配置（`tests/feedback/` サブディレクトリ化はしない）
- **理由**: 既存 feedback 系テスト（`feedback-cap-by-mode.bats` / `feedback-mode-migration.bats` / `feedback-mode-wizard.bats`）が `tests/` 直下にあるため整合させる

### 論点 3 の確定（明示フラグ SoT）

計画レビュー Round 1 で確定済み（`AIDLC_FEEDBACK_WEB` 環境変数）。本論理設計では正規化規則（前後空白除去 + 小文字化 + `1` / `true` / `yes` 完全一致）を確定。

### 論点 4 の確定（警告ログ）

計画レビュー Round 1 で確定済み（呼び出し側責務）。設計レビュー Round 1 #1 反映で発火条件を真理値表と整合させた最終仕様:

1. **強制無効化警告**: `is_tty=false` ∧ (`setting=true` ∨ `explicit_web=true`)（真理値表 行 2 と行 4 の両方をカバー）→ stderr に 1 行
2. **設定値型不一致警告**: `read-config.sh` exit 0 で値が `true`/`false` 以外 → stderr に 1 行
3. **設定読取エラー警告**: `read-config.sh` exit 2 → stderr に 1 行

通常の `setting=false` / 未設定（exit 1 ケース）、または TTY での通常経路では警告を出さない（無音動作）。発火条件と非発火条件は本ファイル「コマンド §`/aidlc feedback` 実行フロー §手順 6」および ドメインモデル §`WarningEmitter` の真理値表で明示。

### `feedback.yml` テンプレート参照ルール（設計レビュー Round 1 #2 / #3 反映）

**SoT 一元化方針**: feedback Issue のテンプレート構造は `.github/ISSUE_TEMPLATE/feedback.yml` を**唯一の Source of Truth** とする。`feedback.md` / SKILL.md / direct 経路の本文展開ロジックは、いずれもこの YAML を参照する責務に限定し、テンプレート構造そのものを手順書に再記述しない（SoT 分裂アンチパターンの回避）。

#### `web` 経路（`gh issue create --web --template feedback.yml`）

GitHub Issue Form (`feedback.yml`) をブラウザ UI で表示。テンプレート参照は `gh` CLI が直接行うため、AI エージェント側での本文構造組み立ては不要（既存挙動を維持）。

#### `direct` 経路（`gh issue create --body-file <path>`）

GitHub Issue Form (`feedback.yml`) は `--web` フラグでのみ form として展開される（CLI の `-T/--template` フラグは Markdown テンプレート用であり、YAML form テンプレートには対応しない仕様。Phase 2 着手時に実機検証で再確認、もし `gh issue create -T feedback.yml --body-file ...` が body を上書きする・エラーになる挙動が変わっていれば設計を更新）。

そのため direct 経路では AI エージェントが以下の手順で本文を組み立てる:

1. **`feedback.yml` 読取**: `Read` ツールで `.github/ISSUE_TEMPLATE/feedback.yml` を読み込む
2. **body 配列の抽出**: `body` キー配下の各エントリ（`type: textarea` / `type: input` 等）を順に走査
3. **Markdown 変換ルール**（既知 `type` の範囲）:
   - `type: markdown` → `value` フィールドの内容をそのまま本文に含める
   - `type: textarea` / `type: input` → `attributes.label` を `## ラベル` として Markdown 見出しに変換し、その下にユーザーから手順 1 で得たヒアリング内容を該当する label に対応する形で配置（label の language（英/日併記）は維持）
   - **未知 `type` のフォールバック**（設計レビュー Round 2 #1 反映）: GitHub Issue Forms の他 `type`（例: `dropdown` / `checkboxes` / 将来追加される type）が出現した場合、AI エージェントは以下の手順で fallback する:
     1. `attributes.label` が存在すれば `## ラベル（type=<type>、AI による自動展開非対応）` の Markdown 見出しに変換し、`<未対応 type のため Web 経路での起票を推奨。本フィールドは未記入>` プレースホルダを本文に書く
     2. stderr に警告 1 行を出力: `warning: feedback.yml has unsupported field type '<type>' for direct route; please use AIDLC_FEEDBACK_WEB=1 to file via web UI`
     3. fail-fast はしない（既知 type のフィールドは正常に展開し、未知 type のみプレースホルダ化することで部分的 SoT 追従を維持）
4. **省略可能フィールド**: `validations.required: false` の field は、ヒアリング内容が無ければ「（任意 / 未記入）」と明記して空セクションとして残す（テンプレートの構造を維持）
5. **一時ファイル書込み**: 上記で組み立てた Markdown 本文を `Write` ツールで一時ファイル（例: `/tmp/aidlc-feedback-direct-<UUID>.md`）に書き出す
6. **Issue 起票**: `gh issue create --label feedback --title "[Feedback] <要約>" --body-file <一時ファイルパス>`（テンプレート由来のラベル `feedback` は明示付与）
7. **一時ファイル削除**

**SoT 改訂時の追従範囲**（設計レビュー Round 2 #1 反映）: `.github/ISSUE_TEMPLATE/feedback.yml` の構造を変更した場合、本変換ルールは **既知 `type`（`markdown` / `textarea` / `input`）の範囲では** 不変（label を見出しに変換するメタロジック）のため `feedback.md` 側の手順は変更不要。既知 type の field 追加・削除は自動的に追従する。一方、**未知 `type` の追加（`dropdown` / `checkboxes` 等）が SoT に発生した場合は、上記「未知 `type` のフォールバック」が発火** し、AI エージェントが警告を出してプレースホルダ化する。完全な SoT 追従を取り戻すには、別 Issue / 別 Unit で本変換ルールに当該 type を「既知」として追加する改修が必要（手順書改訂が必要なケース）。

**SKILL.md / feedback.md への明記事項**:

- `feedback.yml` が SoT であること
- `web` 経路では `gh` CLI が直接 form 展開する
- `direct` 経路では AI エージェントが上記変換ルールに従って本文を組み立てる
- ラベル `feedback` は両経路で付与される

## 不明点と質問（設計中に記録）

論点 1〜4 はすべて本論理設計で確定済み。Phase 2 実装着手時の追加不明点は発生時に `[Question]` / `[Answer]` タグで記録する。
