# doctor 出力仕様（環境診断）

> **位置づけ（v3.0.0-alpha.7 / Phase 6）**: 本ファイルは doctor コマンドの**出力仕様**である。
> 実行実装は `scripts/doctor.sh`。doctor は v3 環境の 9 領域を診断し、各領域の
> severity（OK / WARN / ERROR / SKIP）を表示して総合終了コードを返す。
>
> **診断のみ（重要）**: doctor は問題を検出・案内するが、**状態を変更せず・自動修正しない**
> （`state.json` / work item / config を書き換えない / read-only）。検出した問題の解決は
> ユーザー（または該当コマンド）が行う。

## 目的

v3 環境が健全かを「既存の安全境界スクリプトの wrap + 軽診断」で確認し、現在の問題点を
一覧提示する。各領域は対応する既存スクリプトの終了コード（および stdout）を severity に
写像するのみで、新規のパースロジックを持たない（`bin/check-frontmatter-parse-guard.sh` の
境界を再実装しない）。

## パス解決

`scripts/` は SKILL.md と同じスキルベースディレクトリからの相対パス
（例: `scripts/state-validate.sh`、`scripts/work-item-validate.sh`）。診断対象はカレント
リポジトリの `.aidlc/`（`state.json` はリポジトリ直下 `.aidlc/state.json`、cycle 成果物は
`.aidlc/cycles/<cycle>/`）。`[config]` は `skills/aidlc/scripts/read-config.sh` を、
`[parse-guard]` は `bin/check-frontmatter-parse-guard.sh` を wrap する。

## 診断領域（9 領域 / alpha.7 = shallow scope）

doctor は以下 9 領域を順に診断する。各 severity の意味:

- **OK**: 健全。
- **WARN**: 問題の可能性はあるが失敗ではない（未開始・未認証・未コミット 等）。総合 exit に影響しない。
- **ERROR**: 修正が必要（破損・不正・必須欠落・違反）。総合 exit 1 を導く。
- **SKIP**: 前提を満たさず診断対象外（state なしで cycle/work-items を見ない 等）。

| 領域 | 診断内容 | severity 写像 |
|------|---------|--------------|
| `[config]` | `.aidlc/config.toml` 存在 + `read-config.sh rules.depth_level.level` | 不在→**ERROR** / rc0→OK / rc1→**WARN** / rc2(config あり=dasel 不在)→**ERROR**（診断不能） |
| `[state]` | `state.json` 存在 + `state-validate.sh`（**stdout prefix で分岐**） | 不在→**WARN**（No active cycle）/ `status:valid`→OK / `status:warn:*`→**WARN** / rc1(破損)→**ERROR** / rc2→ERROR（診断不能） |
| `[cycle]` | `state-read.sh current_cycle` + `.aidlc/cycles/<cycle>` 存在 | state なし→**SKIP** / dir 存在→OK / 取得不能・dir 不在→**WARN** |
| `[work-items]` | 前提（state・cycle・dir）判定後に `work-item-validate.sh` | state なし→**SKIP** / cycle dir 未解決→**SKIP** / work-items dir 不在→**WARN** / 0 件→**WARN** / 1 件以上 + rc0→OK / rc1→**ERROR** / rc2→ERROR（診断不能） |
| `[git]` | `git status --porcelain` | clean→OK / dirty→**WARN** / repo 外→**ERROR**（診断不能） |
| `[gh]` | `gh auth status` | 認証→OK / 未認証・gh 不在→**WARN**（`[pr]` を skip） |
| `[pr]` | `gh pr list`（gh 可用時のみ） | gh 不可→**SKIP** / open PR あり→OK（番号表示）/ 0 件→OK（未作成） |
| `[scripts]` | 必須スクリプト集合の存在（`[[ -f ]]`） | 全存在→OK / 欠落→**ERROR** |
| `[parse-guard]` | `bin/check-frontmatter-parse-guard.sh` | スクリプト不在→**SKIP**（opt-in シグナル / consumer 想定）/ rc0→OK / rc1→**ERROR** / rc2→ERROR（診断不能） |

### `[state]` は rc だけで判定しない（重要）

`state-validate.sh` は未対応 schema_version を **rc0 + `status:warn:unsupported-schema-version:*`**
で返す。doctor は **rc だけでなく stdout の prefix**（`status:valid` / `status:warn:*`）を見て
severity を分岐する（rc0 を一律 OK とすると WARN を OK と誤表示するため）。

### `[work-items]` は doctor 側で前提ゲートする（重要）

`work-item-validate.sh` は **work-items ディレクトリ不在・0 件を rc1（バリデーションエラー）**
として返す。doctor は state 存在・`current_cycle`・dir 存在・件数を**自分で判定**してから
validator を呼ぶ。dir 不在・0 件は validator に渡さず **WARN**（define 前を ERROR と誤判定しない）。

### `[config]` の rc2 区別（重要）

`read-config.sh` の **rc2 は config 不在と dasel 不在が同一**。doctor は config.toml の存在を
**自分で先にチェック**し、config が存在するうえで rc2 が返れば dasel 不在（**依存不足 / 診断不能**）
として扱う。config 不在は rc に依らず ERROR（環境未セットアップ）。

## 必須スクリプト集合（`[scripts]` の正本）

`[scripts]` が存在確認する必須集合（スキルベース `scripts/` 相対 / 計 8 件）:

- `state-read.sh`
- `state-write.sh`
- `state-validate.sh`
- `state-init.sh`
- `work-item-next.sh`
- `work-item-validate.sh`
- `work-item-status.sh`
- `lib/frontmatter.sh`

## 総合終了コード

総合 exit code は `skills/aidlc/guides/exit-code-convention.md`（v3 に複製は持たず v2 ガイドを SoT 参照）準拠で **2 > 1 > 0** の優先順で導出する:

- **2**: いずれかの領域が**診断不能**（jq 欠落 / dasel 欠落で `[config]` 依存不足 / git repo 外）。
- **1**: 上記以外で **ERROR 領域あり**（state 破損・schema 不正 / work-items 不正 / 必須スクリプト不在 / parse-guard 違反）。
- **0**: OK / WARN / SKIP のみ（No active cycle / git dirty / gh 未認証 / schema warn 等）。**警告付き完了は exit 0**（exit 2 にしない）。

doctor は先頭で jq の存在を確認し、欠落していれば診断不能として exit 2 で案内する。

## 出力例

```text
[config]      OK    rules.depth_level.level 取得 OK
[state]       WARN  No active cycle（/aidlc-v3 define で開始）
[cycle]       SKIP  （state なし）
[work-items]  SKIP  （state なし / define 前）
[git]         OK    clean
[gh]          WARN  未認証（gh auth status を確認 / [pr] を skip）
[pr]          SKIP  （gh 不可用）
[scripts]     OK    8/8 present
[parse-guard] OK    違反なし
```

## alpha.8 defer（本 Unit では未実装）

以下 2 領域は **v3.0.0-alpha.8 へ defer** する（alpha.7 の doctor では診断しない）:

- **`[phase]`**: フェーズ導出（define → develop → release → complete）の code 化による整合診断。
- **`[trace]`**: intent → work items → designs のトレーサビリティ整合チェック。

alpha.7 の doctor は shallow scope（上記 9 領域）に限定し、`[phase]` / `[trace]` は alpha.8 の
follow-up で追加する。フェーズ導出の正本は `docs/v3/data-model.md` §5 を参照。
