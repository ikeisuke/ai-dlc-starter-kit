# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 設定読み込み【重要】

AI-DLCの設定は `docs/aidlc.toml` と `docs/aidlc.toml.local`（個人設定）からマージして取得します。

**読み込み方法**:

```bash
# 単一キーモード（推奨）
docs/aidlc/bin/read-config.sh <key> [--default <value>]

# バッチモード（複数キーを一括取得）
docs/aidlc/bin/read-config.sh --keys <key1> [key2] ...

# 例
docs/aidlc/bin/read-config.sh rules.reviewing.mode
docs/aidlc/bin/read-config.sh rules.jj.enabled --default "false"
docs/aidlc/bin/read-config.sh --keys rules.reviewing.mode rules.jj.enabled rules.squash.enabled
```

**モードの使い分け**:
- 単一キーモード: 1つの設定値を取得。`--default` でフォールバック値を指定可能
- バッチモード: 複数の設定値を `key:value` 形式で一括取得。不在キーはスキップされる
- **注意**: `--keys` と `--default`、`--keys` と位置引数 `<key>` は同時に使用できません

**終了コード**:
- 0: 値あり
- 1: キー不在（単一モード: デフォルトなし / バッチモード: 全キー不在）
- 2: エラー

**マージルール**:
- `.local` の値が存在するキーはベースを上書き
- 配列は完全置換（マージしない）
- 詳細は `docs/aidlc/guides/config-merge.md` を参照

**注意**: `docs/aidlc.toml.local` は `.gitignore` に追加されるため、個人の設定を安全に上書きできます。

## ユーザーの承認プロセス【重要】

計画作成後、必ず以下を実行する:

1. 計画ファイルのパスをユーザーに提示
2. 「この計画で進めてよろしいですか？」と明示的に質問
3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
4. **承認なしで次のステップを開始してはいけない**

## 質問と回答の記録【重要】

独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める。

## 予想禁止・一問一答質問ルール【重要】

不明点や判断に迷う点がある場合、予想や仮定で進めてはいけない。必ずユーザーに質問する。

**質問フロー（ハイブリッド方式）**:

1. まず質問の数と概要を提示する

   ```text
   質問が{N}点あります：
   1. {質問1の概要}
   2. {質問2の概要}
   ...

   まず1点目から確認させてください。
   ```

2. 1問ずつ詳細を質問し、回答を待つ
3. 回答を得てから次の質問に進む
4. 回答に基づく追加質問が発生した場合は「追加で確認させてください」と明示して質問する

**質問すべき場面**:

- 要件が曖昧な場合
- 複数の解釈が可能な場合
- 技術的な選択肢がある場合
- 前提条件が不明確な場合

## Gitコミットのルール

コミットタイミング、メッセージフォーマット、Co-Authored-By設定は `common/commit-flow.md` を参照。

## jjサポート設定

`docs/aidlc.toml`の`[rules.jj]`セクションを確認:

- `enabled = true`: jjを使用。gitコマンドを`docs/aidlc/skills/versioning-with-jj/references/jj-support.md`の対照表で読み替えて実行
- `enabled = false`、未設定、または不正値: 以下のgitコマンドをそのまま使用

## セミオートゲート仕様【重要】

セミオートモード（`rules.automation.mode = "semi_auto"`）が有効な場合、AIレビュー合格時にユーザー承認を省略して自動遷移する。

### 設定読み取り

```bash
docs/aidlc/bin/read-config.sh rules.automation.mode --default "manual"
```

- `manual`: 従来フロー（すべての承認ポイントでユーザー確認）。ゲート判定をスキップ
- `semi_auto`: セミオートゲート判定を実施

**注意**: プロンプト文中では `automation_mode` として参照する（`rules.reviewing.mode`（review_mode）との混同防止）。

### ゲート判定ロジック（全承認ポイント共通）

各承認ポイントで以下の順序で判定する:

1. `automation_mode` を取得
2. `automation_mode=manual` → ゲート判定スキップ、従来フローを実行。**終了**
3. `automation_mode=semi_auto` → グローバルフォールバック条件を先に評価
4. グローバルフォールバックに該当 → `fallback(error)` として従来フローへ。履歴記録
5. 承認ポイント固有のフォールバック条件を優先順位順に評価
6. フォールバック条件に該当 → `fallback` として従来フローへ。履歴記録
7. フォールバック条件に該当しない → `auto_approved` として次ステップへ自動遷移。履歴記録

### グローバルフォールバック条件

すべての承認ポイント（「自動実行」ポイント含む）に適用:

- 設定読取失敗（`read-config.sh` がエラー終了コード2を返した場合）
- 実行エラー（前提となる処理がエラーで終了した場合）
- 前提不成立（ゲート判定に必要なコンテキスト情報が欠落している場合）

### フォールバック条件テーブル（承認ポイント固有）

| 優先度 | reason_code | 条件 | ユーザーへのメッセージ方針 |
|--------|-------------|------|------------------------|
| 1 | `error` | ビルド/テスト失敗またはエラー発生 | エラー内容を提示し対応を求める |
| 2 | `review_issues` | AIレビュー指摘が残っている | 指摘一覧を提示し判断を求める |
| 3 | `incomplete_conditions` | 完了条件に未達成項目がある | 未達成項目を提示し判断を求める |
| 4 | `decision_required` | 技術的判断・選択が必要 | 選択肢を提示し判断を求める |

### 構造化シグナルスキーマ

| semi_auto_result | reason_code | fallback_reason | 条件 |
|------------------|-------------|-----------------|------|
| `auto_approved` | `none`（必須） | 空（使用しない） | フォールバック条件に該当しない |
| `fallback` | 有効値（必須） | 説明文字列（必須） | フォールバック条件に該当 |

**バリデーション規則**:

- `auto_approved` 時: `reason_code=none`、`fallback_reason` は空
- `fallback` 時: `reason_code` は `none` 以外、`fallback_reason` は空でない文字列
- `automation_mode=manual` 時: シグナルを生成しない

### 自動承認時の履歴記録フォーマット

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase {{PHASE}} \
    --unit {N} \
    --unit-name "[Unit名]" \
    --unit-slug "[unit-slug]" \
    --step "セミオート自動承認" \
    --content "【セミオート自動承認】
【承認ポイントID】{承認ポイントID}
【判定結果】auto_approved
【AIレビュー結果】指摘0件"
```

- `--unit`, `--unit-name`, `--unit-slug`: constructionフェーズの場合のみ指定

### フォールバック時の履歴記録フォーマット

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase {{PHASE}} \
    --unit {N} \
    --unit-name "[Unit名]" \
    --unit-slug "[unit-slug]" \
    --step "セミオートフォールバック" \
    --content "【セミオートフォールバック】
【承認ポイントID】{承認ポイントID}
【判定結果】fallback
【reason_code】{reason_code}
【詳細】{fallback_reason}"
```

- `--unit`, `--unit-name`, `--unit-slug`: constructionフェーズの場合のみ指定

### 承認ポイントID命名規則

`{phase}.{context}.{step}` 形式。例:

- `construction.plan.approval`, `construction.design.review`
- `inception.intent.approval`, `inception.stories.approval`
- `operations.plan.approval`

## コード品質基準

コード品質基準、Git運用の原則は `docs/cycles/rules.md` を参照
