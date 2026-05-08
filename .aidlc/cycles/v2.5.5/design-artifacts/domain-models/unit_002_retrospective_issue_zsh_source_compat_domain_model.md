# ドメインモデル: retrospective-issue.sh SCRIPT_DIR 解決の bash / zsh 両対応

## 概要

シェル helper スクリプトを `source` する経路において、helper 自身のパスを取得する処理（SCRIPT_DIR 解決）の bash / zsh 両対応ドメイン。bash では `${BASH_SOURCE[0]}` が source 元のパスを返すが、zsh では `${(%):-%N}`（プロンプト展開）を使う必要があり、両者の構文が相互に評価不可。本 Unit は `retrospective-issue.sh` でこのドメインを `predecessor-issue.sh` と統一構造で扱う責務を負う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2 で行います。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| source 経路 | helper を `. <path>` または `source <path>` で読み込み、呼び出し元シェルプロセスのコンテキストに評価する実行経路（サブシェル経由ではない） |
| SCRIPT_DIR 解決 | source された helper 自身が、自身を含むディレクトリの絶対パスを動的に取得する処理。helper が他 helper を相対 source する際の起点として使用 |
| `${BASH_SOURCE[0]}` | bash 配列パラメータ。source された場合は呼び出されたファイルパス、直接実行された場合はスクリプト自身のパスを返す。zsh では未定義（空文字となる） |
| `${(%):-%N}` | zsh パラメータ展開のフラグ修飾。`(%)` でプロンプト文字列展開を有効化し、`%N` は現在実行中のスクリプト名（source 元含む）を展開。bash パーサで直接評価するとシンタックスエラーになる |
| `ZSH_VERSION` | zsh 起動時に設定される環境変数。bash 環境では未定義（`${ZSH_VERSION:-}` で空文字フォールバック）。shell 判定の正準キー |
| 多重 source ガード | helper の冒頭で `__AIDLC_*_LOADED` 等のフラグを確認し、既に読み込まれている場合は再評価せず return する仕組み |
| 独立契約（C1〜C4） | bats テストで検証する `retrospective-issue.sh` の振る舞いの独立契約（status 0 / SCRIPT_DIR 非空 / 実在ディレクトリ / `HELPER_LIB_DIR` 一致） |

## 値オブジェクト（Value Object）

### ShellEnvironment

- **属性**: `kind: Enum { bash, zsh }`, `zsh_version_string: String?`（zsh 時のみ非 null）
- **不変性**: 評価時の `${ZSH_VERSION:-}` の値で一意決定（同一プロセス内で変化しない前提）
- **判定方式**: `[[ -n "${ZSH_VERSION:-}" ]]` の真偽

### ScriptDir

- **属性**: `path: AbsolutePath` — helper を含むディレクトリの絶対パス
- **不変条件**:
  - 空文字でない（C2）
  - 実在するディレクトリである（C3）
  - リポジトリ内 `skills/aidlc/scripts/lib` と一致する（C4: HELPER_LIB_DIR 一致）

## ドメインサービス

### ScriptDirResolver

- **責務**: 現在の `ShellEnvironment` を判定し、対応する手段で SCRIPT_DIR を解決する。bash / zsh 双方で同じ結果（実在ディレクトリの絶対パス）を返す
- **操作**:
  - `resolve(env: ShellEnvironment) -> ScriptDir`
- **手段マトリクス**:

  | env.kind | 手段 | 引用元 |
  |----------|------|--------|
  | bash | `cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd` | bash 配列パラメータ仕様 |
  | zsh | `cd -- "$(dirname -- "${(%):-%N}")" >/dev/null 2>&1 && pwd` | zsh プロンプト展開仕様 |

- **判定の冪等性**: 同一ファイル・同一プロセスで複数回 source されても多重 source ガードにより 1 回のみ評価される

## 不変条件

1. **bash 経路の挙動不変**: bash で `source retrospective-issue.sh` した時の `${__RETRO_ISSUE_SCRIPT_DIR}` の値は本 Unit 改修前後で同一（`HELPER_LIB_DIR` の絶対パス）。**前提**: `ZSH_VERSION` 環境変数が bash プロセスに注入されていない（後述「分岐前提」参照）
2. **zsh 経路の正常化**: zsh で `source retrospective-issue.sh` した時の `${__RETRO_ISSUE_SCRIPT_DIR}` は空文字でなく、実在ディレクトリで、`HELPER_LIB_DIR` と一致する（本 Unit で新規担保）
3. **API 不変**: `__RETRO_ISSUE_SCRIPT_DIR` という変数名 / 公開関数群（`retrospective_resolve_issue` 等）/ helper 多重 source ガード（`__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED`）に変更を加えない
4. **bash パーサ評価安全性**: `${(%):-%N}` を含む式は `[[ -n "${ZSH_VERSION:-}" ]]` ブロック内に閉じ込め、bash パーサが当該行を直接評価する経路を発生させない

## 分岐前提（設計レビュー Round 1 指摘 #1 対応）

本ドメインの shell 判定は `ZSH_VERSION` 環境変数の有無のみで行う。これは以下の前提に依存する:

- **前提 P1**: `ZSH_VERSION` は zsh が起動時に設定する変数であり、bash プロセスでは未設定であること（POSIX shell 仕様には含まれないが、bash / zsh 双方の事実上の慣習）
- **前提 P2**: 利用者が bash プロセスに `ZSH_VERSION` を **明示的に export して注入する** ことは正常運用ではない（汚染シナリオ）

**汚染シナリオでの挙動**: bash プロセスで `ZSH_VERSION=5.0` が export されている場合、本ドメインの判定は zsh 経路（`${(%):-%N}` 評価）に進む。bash パーサで `${(%):-%N}` を評価しようとしてシンタックスエラー（`bad substitution`）となり、`__RETRO_ISSUE_SCRIPT_DIR` の解決が失敗する。これは **非サポート挙動** とし、計画書の独立契約 C1〜C4 はあくまで「ZSH_VERSION 非汚染の bash プロセス」「正常 zsh プロセス」を対象範囲とする。

**判定強化の検討**: より厳密な判定（例: `[[ -n "${ZSH_VERSION:-}" ]] && (emulate -L zsh) >/dev/null 2>&1` での zsh 実行実体確認）は `predecessor-issue.sh:31-40`（v2.5.4 Unit 004）でも同じ課題を抱えており、本 Unit 単独では強化しない（pattern 整合性優先）。判定強化は別タスク（共通 helper 化フォローアップ事項、計画書「フォローアップ事項」セクション参照）と一体で扱う。

**前提逸脱の検出手段**: bash プロセスでの `ZSH_VERSION` 注入は実際には発生しない前提だが、もし発生した場合は `${(%):-%N}` の bash 評価エラーが stderr に出力されるため、`source` 失敗として検出可能。計画書 C1（status 0）が偽になることでテスト失敗として顕在化する（ただし本 Unit のテスト fixture では汚染シナリオは検証しない）。

## 関連する意思決定（DR）

- **v2.5.4 Inception DR-001**（OUT_OF_SCOPE 解消）: v2.5.4 サイクルでは `retrospective-issue.sh` の zsh 対応を OUT_OF_SCOPE とし `predecessor-issue.sh` 1 ファイルに修正対象を限定した。v2.5.5 Unit 002 で本 OUT_OF_SCOPE を解消し、`predecessor-issue.sh` と同じパターンを `retrospective-issue.sh` に展開する

## 不明点と質問（設計中に記録）

[Question] `${(%):-%N}` を zsh interactive shell 以外（zsh script 直実行 / zsh -c 経由 source）でも安定動作するか
[Answer] **動作する**。`%N` プロンプト展開は zsh が source / 直接実行いずれの経路でも現在のスクリプト名を保持する仕様。`predecessor-issue.sh` の v2.5.4 Unit 004 で実証済み（`tests/aidlc-helpers-zsh-source.bats:74-92` の zsh 経路アサーションが GA 後 PASS 維持）。

[Question] 多重 source ガード（`__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED`）と SCRIPT_DIR 解決の順序関係
[Answer] **既存実装維持**。多重 source ガードが先（line 24-27）、SCRIPT_DIR 解決が後（line 43）の順序を維持する。本 Unit は line 43 のみ改修し、ガード部は変更しない。
