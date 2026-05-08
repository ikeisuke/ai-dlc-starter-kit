# 論理設計: retrospective-issue.sh SCRIPT_DIR 解決の bash / zsh 両対応

## 概要

`skills/aidlc/scripts/lib/retrospective-issue.sh:43` の SCRIPT_DIR 解決を `ScriptDirResolver`（ドメインモデル参照）に従った形に置換し、`tests/aidlc-helpers-zsh-source.bats:94-105` の skip マーカーを解除して独立契約 C1〜C4 を bash / zsh 両経路で検証する。

**重要**: この論理設計では**コードは書かず**、改修前後の構造と検証手段の定義のみを行います。具体的な改訂後コード文言は Phase 2 で `predecessor-issue.sh:31-40` パターンを参照しつつ確定します。

## アーキテクチャパターン

**インライン手続き型 + shell 判定分岐**（`predecessor-issue.sh` パターン踏襲）。helper 単一ファイル内で SCRIPT_DIR 解決を完結させ、外部依存（共通 helper への切り出し）は本 Unit のスコープ外（計画ファイルのフォローアップ事項として次サイクル以降の検討対象）。

## コンポーネント構成

### レイヤー構成（既存維持）

```text
skills/aidlc/scripts/lib/retrospective-issue.sh
├── 多重 source ガード                    # 既存（line 22-27、変更なし）
├── __RETRO_ISSUE_SCRIPT_DIR 解決         # 本 Unit 改修対象（line 43 周辺）
├── 下流 helper の source                 # 既存（line 45-53、変更なし）
└── retrospective_* 関数群                # 既存、変更なし
```

### コンポーネント詳細

#### `__RETRO_ISSUE_SCRIPT_DIR` 解決部（本 Unit 改修対象）

- **責務**: shell 環境（bash / zsh）を判定し、helper 自身を含む絶対パスを `__RETRO_ISSUE_SCRIPT_DIR` に格納する
- **依存**: `ZSH_VERSION` 環境変数（zsh のみ設定）/ `${BASH_SOURCE[0]}` / `${(%):-%N}`
- **公開インターフェース**: `__RETRO_ISSUE_SCRIPT_DIR` 変数（既存名・既存意味を維持。下流 line 45-53 の `source "${__RETRO_ISSUE_SCRIPT_DIR}/<helper>.sh"` から参照される）

#### 改修前後の `__RETRO_ISSUE_SCRIPT_DIR` 解決部（pseudo）

```text
# 改修前（line 43 周辺）
__RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

# 改修後（predecessor-issue.sh:31-40 と同型）
# Unit 002 (#661): zsh interactive shell からの `source` 経路でも SCRIPT_DIR を解決できるよう、
# ZSH_VERSION で shell 判定し zsh 用に ${(%):-%N} を使用する（bash 経路は既存ロジック維持）。
# v2.5.4 Unit 004 (#659) の predecessor-issue.sh:31-40 と同パターン。
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # shellcheck disable=SC1083,SC2296
    # zsh パラメータ展開（${(%):-%N}）は shellcheck（bash 前提）で警告となるが、ZSH_VERSION 判定下でのみ評価されるため安全
    __RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${(%):-%N}")" >/dev/null 2>&1 && pwd)
else
    __RETRO_ISSUE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
fi
```

> **コメント方針**: 引用元（`predecessor-issue.sh:31-40` / v2.5.4 Unit 004 / #659）と判定理由（zsh での `${BASH_SOURCE[0]}` 不使用 + bash パーサ評価安全性）を併記する。

## インターフェース設計

### スクリプトインターフェース（変更なし）

`retrospective-issue.sh` の公開関数（`retrospective_resolve_issue` 等）/ `__RETRO_ISSUE_SCRIPT_DIR` 変数 / 多重 source ガード変数（`__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED`）はすべて既存定義を維持。本 Unit は SCRIPT_DIR 解決の内部実装のみを差し替える。

### bats テストインターフェース（独立契約 C1〜C4 ベース）

`tests/aidlc-helpers-zsh-source.bats:94-105` を以下構造に書き換える:

```text
@test "zsh-source: retrospective-issue.sh source 動作確認 + SCRIPT_DIR（bash / zsh 両対応）" {
  # bash 経路: C1〜C4 を順に検証
  run bash -c "source '${HELPER_LIB_DIR}/retrospective-issue.sh' && printf '%s' \"\${__RETRO_ISSUE_SCRIPT_DIR}\""
  [ "$status" -eq 0 ]                       # C1
  [ -n "$output" ]                          # C2
  [ -d "$output" ]                          # C3
  [ "$output" = "${HELPER_LIB_DIR}" ]       # C4

  if [ "$AIDLC_ZSH_AVAILABLE" = "true" ]; then
    # zsh 経路: 同じく C1〜C4
    run zsh -c "source '${HELPER_LIB_DIR}/retrospective-issue.sh' && printf '%s' \"\${__RETRO_ISSUE_SCRIPT_DIR}\""
    [ "$status" -eq 0 ]                     # C1
    [ -n "$output" ]                        # C2
    [ -d "$output" ]                        # C3
    [ "$output" = "${HELPER_LIB_DIR}" ]     # C4
  else
    skip "zsh not available"
  fi
}
```

> 構造的に `predecessor-issue.sh` テスト（line 74-92）と同型だが、これは保守性副次効果。検証要件の根拠は計画書の独立契約 C1〜C4 にある（計画レビュー Round 1 指摘 #2 への返答）。

### bats ヘッダコメント更新（line 1-9）

```text
# 改修前（DR-001 OUT_OF_SCOPE 注記）
# Unit 004 (#659): helper の zsh source 互換性テスト
# ...
# DR-001: 修正対象は predecessor-issue.sh の 1 ファイルに限定。
# retrospective-issue.sh は同種バグ（${BASH_SOURCE[0]} ベースの SCRIPT_DIR 解決）を
# 持つ可能性があるが本 Unit のスコープ外のため、zsh 経路は OUT_OF_SCOPE で skip する。

# 改修後（v2.5.5 Unit 002 解消反映）
# Unit 004 (#659) / Unit 002 (#661): helper の zsh source 互換性テスト
# ...
# v2.5.4 Unit 004 (#659) で predecessor-issue.sh の zsh 対応を実装、
# v2.5.5 Unit 002 (#661) で retrospective-issue.sh も同パターンで対応済み。
# 両 helper とも bash / zsh 両経路で SCRIPT_DIR 解決と動作を検証する。
```

## 処理フロー概要

### ユースケース 1: zsh interactive shell から retrospective-issue.sh を source

**改修前のステップ**:
1. ユーザーが zsh で `source skills/aidlc/scripts/lib/retrospective-issue.sh` を実行
2. line 43 の `${BASH_SOURCE[0]}` が空文字に展開される（zsh 環境のため）
3. `dirname -- ""` が `.` を返す
4. `cd -- "."` でカレントディレクトリへ移動
5. `pwd` が **カレントディレクトリ**（helper のディレクトリではない）を返す
6. `__RETRO_ISSUE_SCRIPT_DIR` がカレントディレクトリ（誤値）に設定される
7. line 45-53 の下流 source が `<カレントディレクトリ>/aidlc-paths.sh` 等を検索 → 多くの場合 file-not-found で失敗

**改修後のステップ**:
1. ユーザーが zsh で `source ...` を実行
2. `[[ -n "${ZSH_VERSION:-}" ]]` が真と評価される
3. `${(%):-%N}` が source 元のフルパスを返す
4. `dirname -- "<source 元>"` が helper ディレクトリを返す
5. `cd -- "<helper ディレクトリ>" && pwd` で絶対パスを取得
6. `__RETRO_ISSUE_SCRIPT_DIR` が `${REPO_ROOT}/skills/aidlc/scripts/lib` に正しく設定される
7. line 45-53 の下流 source が正常完了

### ユースケース 2: bash 経路（後方互換）

`[[ -n "${ZSH_VERSION:-}" ]]` が偽と評価される `else` ブロックで既存ロジック（`${BASH_SOURCE[0]}` ベース）が実行される。改修前後で挙動不変。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: shell 判定分岐 1 回追加のため計測対象外（Unit 定義 NFR）
- **対応策**: `[[ ... ]]` の評価は O(1)。helper の source 1 回あたり 1 度のみ実行

### セキュリティ

- **要件**: 該当なし（Unit 定義 NFR）
- **対応策**: SCRIPT_DIR 値は内部用途のみで外部入力を含まない。インジェクション経路なし

### 後方互換

- **要件**: bash 経路で `__RETRO_ISSUE_SCRIPT_DIR` が `${HELPER_LIB_DIR}` を返す挙動を維持（Unit 計画 NFR）
- **対応策**: bash 経路は `else` ブロックで `${BASH_SOURCE[0]}` ベースの既存ロジックをそのまま保持

## 技術選定

- **言語**: Bash 4+ / zsh 5+（既存 helper 群準拠）
- **テストランナー**: bats（既存 `tests/aidlc-helpers-zsh-source.bats` の構造踏襲）

## 実装上の注意事項

- **shellcheck disable**: `${(%):-%N}` を含む行の直前に `# shellcheck disable=SC1083,SC2296` を追記（`predecessor-issue.sh:35` 同等）。bash パーサ前提の lint で false positive を抑制する
- **zsh 経路の評価安全性**: `${(%):-%N}` を含む式は **`[[ -n "${ZSH_VERSION:-}" ]]` の then ブロック内のみ**で評価する。bash パーサがこの行に到達するのは `[[ ]]` の判定が偽の場合のみで、その時点では `then` ブロックは構文解析後にスキップされる。実際の `${(%):-%N}` 評価は zsh パーサが行うため安全
- **多重 source ガードとの相互作用**: `__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED` ガード（line 24-27）が真の場合、SCRIPT_DIR 解決は実行されない。既存挙動を維持
- **下流参照の互換性**: `__RETRO_ISSUE_SCRIPT_DIR` を参照する line 45-53 は変数名・意味を維持するため変更不要

### 分岐判定の前提と非サポート挙動（設計レビュー Round 1 指摘 #1 対応）

本実装の shell 判定は `[[ -n "${ZSH_VERSION:-}" ]]` のみに依存する（`predecessor-issue.sh:34` と同型）。前提・非サポート挙動はドメインモデル §「分岐前提」を SoT として参照する:

- **対象範囲**: `ZSH_VERSION` 非汚染の bash プロセス、または正常 zsh プロセス
- **非サポート**: bash プロセスに `ZSH_VERSION` が export 注入されたシナリオ（`${(%):-%N}` 評価でエラー、source 失敗で検出可能）
- **強化検討**: `(emulate -L zsh)` 等での zsh 実行実体チェックは `predecessor-issue.sh` の挙動とも整合させる必要があるため、本 Unit では強化せず計画書「フォローアップ事項」セクションの共通化検討と一体で扱う

本実装は `predecessor-issue.sh` と完全同型のため、汚染シナリオ耐性も同等となる（本 Unit で耐性が悪化することはない）。

## 検証クエリ（Phase 2 完了時に実行）

| 検証項目 | コマンド | 期待結果 |
|---------|---------|---------|
| ZSH_VERSION 分岐の存在確認 | `grep -n 'if \[\[ -n "\${ZSH_VERSION:-}" \]\]' skills/aidlc/scripts/lib/retrospective-issue.sh` | 1 行ヒット |
| zsh 用展開の存在確認 | `grep -n '\${(%):-%N}' skills/aidlc/scripts/lib/retrospective-issue.sh` | 1 行ヒット |
| 既存 BASH_SOURCE 残存確認 | `grep -n 'BASH_SOURCE\[0\]' skills/aidlc/scripts/lib/retrospective-issue.sh` | 1 行以上ヒット（else ブロック分） |
| skip マーカー削除確認 | `grep -nE 'skip "OUT_OF_SCOPE: see backlog #661"' tests/aidlc-helpers-zsh-source.bats` | 0 行 |
| bats テスト実行 | `bats tests/aidlc-helpers-zsh-source.bats` | 全件 PASS |
| bash 単独 source | `bash -c "source skills/aidlc/scripts/lib/retrospective-issue.sh && echo \$__RETRO_ISSUE_SCRIPT_DIR"` | `<repo>/skills/aidlc/scripts/lib` |
| zsh 単独 source | `zsh -c "source skills/aidlc/scripts/lib/retrospective-issue.sh && echo \$__RETRO_ISSUE_SCRIPT_DIR"` | `<repo>/skills/aidlc/scripts/lib` |

## 不明点と質問（設計中に記録）

[Question] `predecessor-issue.sh` で使用されている `# shellcheck disable=SC1083,SC2296` を本 Unit でもそのまま流用してよいか
[Answer] **流用可能**。SC1083（cannot resolve include directive）と SC2296（parameter expansion）は `${(%):-%N}` を含む zsh 専用構文で標準的に出力される false positive。`predecessor-issue.sh` で実証済みのため流用する。

[Question] 改修前の line 43 の単一行は line 43 のみで完結しており、改修後は 8 行ブロックに拡張される。コミットによる行番号ズレの影響は
[Answer] **本 Unit 完結内で対処**。改修対象は 1 ファイル 1 箇所のみで、行番号ズレは下流参照（line 45-53 の source 行）に伝播するが、変数名 `__RETRO_ISSUE_SCRIPT_DIR` を維持するため意味整合は崩れない。完了履歴では「改修前 line 43 / 改修後 line 43-50（8 行ブロック）」と新旧の line 範囲を明記する。
