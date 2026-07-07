# v2 → v3 migration フロー（実行手順）

v2 環境（`.aidlc/config.toml` あり / `.aidlc/state.json` なし）を v3 へ移行する。
手順方針の正本は `docs/v3/migration.md` §6、変換規則の正本は同 §3.1、変換先 schema の
正本は `docs/v3/data-model.md` §11 / §3。

人間確認ゲート（★）は 2 箇所（Step 2 モード選択 / Step 4 変換結果確認）。
**スクリプトは非対話・決定的**であり、ゲートと対話は本 step（AI エージェント）の責務である。
**本フローは commit を行わない**（適用結果の commit はユーザーが確認してから行う）。

## パス解決

`scripts/` はスキルベースディレクトリからの相対パス。`state-init.sh` のみ他スキルの
スクリプトを再利用する（Step 5 の 2 候補フォールバック解決を参照）。

## Step 0: preflight

```bash
scripts/migrate-v3-preflight.sh
```

- stdout `status:ok`（exit 0）→ Step 1 へ。
- exit 1（`error:config-not-found` / `error:already-v3` / `error:dirty-worktree` /
  `error:v1-markers-present`）→ エラー内容を提示して**終了**（書き込みなし）。
  `v1-markers-present` の場合は v1→v2 migration（steps/01〜03）を先に完了するよう案内する。
- exit 2（git リポジトリ外 / jq 不在）→ 環境エラーを提示して**終了**。

## Step 1: 片方向移行警告の明示

モード選択の**前に**、以下の警告をユーザーに明示する（preflight も stderr に
`warn:one-way-migration:...` を出力するが、本 Step の明示は省略しない）:

```text
⚠ v2 → v3 移行は片方向です（rollback 不可）。
  - 適用後、v2 runtime 互換（v2 スキルでの継続運用）は保証されません。
  - ファイル自体は git 履歴から復元できますが、v2 への巻き戻し運用はサポート対象外です。
  - 適用前の状態は clean worktree を前提に git で復元可能です（本フローは commit しません）。
```

## Step 2: ★ 移行モード選択（人間確認ゲート）

以下の 3 択を提示し、ユーザーに選択させる（migration.md §2 / §6 手順 2）:

| モード | 内容 | 推奨 |
|--------|------|------|
| `new-cycle-only` | v2 config → v3 config 生成 + state.json 初期化。過去資産は残置 | **推奨** |
| `archive-only` | 上記に加え、v2 cycles の所在 index（`.aidlc/v2-archive.md`）を生成 | 所在記録を残したい場合 |
| `best-effort` | 過去資産の実データ変換 | **未実装** |

- `best-effort` が選択された場合: 未実装である旨と、後続サイクルで提供予定
  （v2 EOL 3 条件の consumer テストとセット / Epic #736）を案内し、**書き込みゼロで安全に
  中断する**（正常終了扱い）。
- `new-cycle-only` / `archive-only` → Step 3 へ。

## Step 3: 変換プラン生成

1. config 変換プランを生成する（書き込みなし）:

   ```bash
   scripts/migrate-v3-config.sh --plan
   ```

   出力（`keep:` / `default:` / `warn:` / `drop:` 行）を人間向けの表に整形して提示する:
   - `keep:` — v2 の明示値を引き継ぐキー（維持 7 キー）
   - `default:` — v3 既定値を適用するキー（新規キー `required_ci_zero_fallback` を含む）
   - `warn:invalid-value:` — v2 の値が v3 enum / 型に不適合のため既定値へフォールバック
   - `drop:` — v3 で未サポートのため移行しないキー（**警告のみ / エラーにしない**）

2. 新しい v3 cycle 識別子をユーザーに確認する（state.json の `current_cycle` になる値）。
   形式は `^[A-Za-z0-9][A-Za-z0-9._-]*$`（`/`・空白・制御文字を含まない）。この検証は
   Step 5 の `state-init.sh` でも強制されるが、ここで事前検証して早期に指摘する。

3. `archive-only` の場合は index のプレビュー（対象 cycle 件数と生成先
   `.aidlc/v2-archive.md`）を提示する。

## Step 4: ★ 変換結果確認（人間確認ゲート）

適用内容の全体をユーザーに提示し、承認を得る（migration.md §6 手順 4 /
完全自動変換は目指さない）:

- v3 config.toml の生成内容（8 キーの確定値）
- drop されるキーの一覧（再掲）
- state.json の初期値（`current_cycle` = Step 3 で確認した cycle id / `define_completed: false`）
- `archive-only` の場合: index の生成先と対象件数
- **片方向移行の再掲**: 「適用後は v2 への巻き戻しを保証しない」

承認が得られない場合は修正点を確認して Step 3 に戻る（または中断 / 書き込みなし）。

## Step 5: 適用

承認後、以下の順で適用する。**state.json 生成を最後に置く**（途中失敗時に
「v3 移行済みマーカーだけが存在する部分状態」を作らないため）:

1. v3 config を適用する:

   ```bash
   scripts/migrate-v3-config.sh --apply
   ```

   stdout 末尾 `status:applied`（exit 0）を確認する。

2. `archive-only` の場合のみ、index を生成する:

   ```bash
   scripts/migrate-v3-archive-index.sh
   ```

   stdout `status:generated:count=<n>`（exit 0）を確認する。

3. state.json を初期化する。`state-init.sh` は以下の 2 候補を順に解決して実行する
   （前者が現行配置 / 後者は v3 本流化後の配置。存在した方を使う）:

   - `<スキルベースディレクトリ>/../aidlc-v3/scripts/state-init.sh`
   - `<スキルベースディレクトリ>/../aidlc/scripts/state-init.sh`

   ```bash
   <解決した state-init.sh> "<cycle>"
   ```

   stdout `status:initialized`（exit 0）を確認する。exit 非 0 の場合はエラーを提示し、
   切り戻し手順（下記 Step 6 の注記）を案内して終了する。

## Step 6: サマリと次アクション

1. 適用結果のサマリを提示する: 書き込んだファイル（`.aidlc/config.toml` /
   `.aidlc/state.json` / `archive-only` 時は `.aidlc/v2-archive.md`）、drop 警告の一覧、
   片方向移行警告の再掲。
2. 変更の commit はユーザーの責務であることを伝え、確認のうえ commit するよう案内する。
3. 次アクションとして `/aidlc-v3 define` を案内する（state.json は初期化済みのため、
   define は `current_cycle` 一致 + `define_completed: false` の resume 経路で
   state 初期化を skip して進む）。

> **切り戻し（適用後に取り消したい場合）**: `git checkout -- .aidlc/config.toml` +
> `rm -f .aidlc/state.json .aidlc/v2-archive.md`（未 commit 時）。commit 済みなら revert。
> ただしファイル復元後も v2 runtime 互換の継続サポートは保証されない（片方向移行）。
