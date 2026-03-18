# Unit 002 計画: aidlc-setup.sh exit code修正

## 概要

aidlc-setup.shがstatus:success時にexit code 0を返すよう修正する。

## 変更対象ファイル

1. `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` — exit code制御の修正

## 根本原因の分析

`_cleanup` 関数（EXIT trap）内の `[[ -f "$f" ]] && \rm -f "$f"` がバグの原因。

Step 8（バージョン更新）で作成した一時ファイルが `\mv` で移動済みの場合:
1. `exit 0` が呼ばれる
2. EXIT trap が `_cleanup()` を実行
3. `[[ -f "$TMP" ]]` が false (1) を返す（ファイルは移動済み）
4. `&&` が短絡し、compound commandの終了コードが 1 になる
5. `_cleanup` の最後のコマンドの終了コードが 1
6. EXIT trap の終了コードがスクリプトの最終終了コードを上書き → exit code 1

## 実装計画

`_cleanup` 関数を修正し、EXIT trap が常にexit codeを上書きしないようにする。

### 修正内容

`_cleanup` 関数の `[[ -f "$f" ]] && \rm -f "$f"` を `\rm -f "$f" 2>/dev/null || true` に変更。
`rm -f` は存在しないファイルに対しても0を返すため `[[ -f ]]` ガードは不要。
`|| true` で万一の失敗時も明示的に0を保証する。

## 設計省略の根拠

本Unitはシェルスクリプトのバグ修正であり、ドメインモデル・論理設計は不要。

## 完了条件チェックリスト

- [ ] aidlc-setup.shの終了コード制御が修正されている
- [ ] set -eによる意図しない非ゼロ終了が解消されている
- [ ] exit codeの一貫性: success→0, error→1, skip→0
