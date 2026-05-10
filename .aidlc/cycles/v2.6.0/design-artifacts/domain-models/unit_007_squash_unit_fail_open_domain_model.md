# ドメインモデル: squash-unit.sh の CI 構造チェック opt-in 化

## 概要

`squash-unit.sh` の Unit 完了時必須 CI 構造チェック（3 種）について、「**チェックスクリプトの存在を opt-in シグナルとして扱う**」汎用論理に変更する。当該リポジトリの `bin/check-*.sh` が存在すれば実行し、存在しなければ自然に skip する。本体スクリプトに「starter kit / consumer 判定」のドッグフーディング特殊処理は埋め込まない（CLAUDE.md「設計原則」§ ドッグフーディング特殊処理を本体に埋めない 準拠）。

本 Unit は「シェル内 1 ループの判定強化」相当の小規模変更のため、本モデルは Decision Table + Invariants 中心の最小構成で記述する。

## 境界（Bounded Context）

`Internal CI Check Opt-in Context`:

- リポジトリルートに対する「3 種 CI 構造チェック（check-skill-references / check-bash-substitution / check-test-isolation）の opt-in シグナル」の検出
- 個別チェックスクリプトの存在 / 不在に応じた実行 / skip 決定
- 全チェックが skip された場合の info ログ出力

**Unit 境界外**:

- 3 種チェックスクリプト本体（`bin/check-*.sh`）の振る舞い
- starter kit / consumer の概念的判定（本体スクリプトに持たせない）
- consumer プロジェクト向け代替チェックの提供
- squash-unit.sh の他チェック（commit count / dirty working tree / main branch protection 等）

## Decision Table（中核責務）

opt-in シグナル方式: 各チェックスクリプトの存在を個別に判定し、存在するもののみ実行する。

| 入力条件（個別 check） | 当該 check の挙動 | stdout（機械可読トークン） | stderr（人間向け文言） |
|---------------------|------------------|--------------------------|----------------------|
| `${repo_root}/bin/${check}.sh` 存在 + 実行 pass | 実行成功 | （なし） | 各チェックの stderr |
| 同上 + 実行 fail | 実行失敗 | `squash:error:${check}-failed` | （実行ログ） |
| `${repo_root}/bin/${check}.sh` 不在 | opt-in 不在 → skip | （なし / 個別 skip は無音） | （なし） |

集約挙動（3 種チェック全体に対するまとめ）:

| 集約条件 | 関数 return | 追加 stdout | 追加 stderr |
|---------|------------|------------|-----------|
| 1 つ以上が実行され、すべて pass | 0 | （なし） | （なし） |
| 1 つ以上が実行され、いずれかが fail | 2 | （fail 時のトークン / 上記） | （実行ログ） |
| 3 つすべて不在（opt-in 全不在） | 0 | `squash:info:internal-ci-checks-skipped` | `info: no internal CI check scripts present in bin/ (skipping)` |

### 設計選択（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」反映）

- **採用**: `bin/${check}.sh` 個別存在による opt-in 判定。`starter kit / consumer` の概念は本体スクリプトに持たない
- **不採用 1**: `skills/aidlc/` ディレクトリ存在判定 → consumer 側偶然同名ディレクトリでの誤検知 + ドッグフーディング特殊処理に該当
- **不採用 2**: `skills/aidlc/scripts/squash-unit.sh` ファイル存在判定 → 誤検知リスクは下がるがドッグフーディング特殊処理に該当
- **不採用 3**: 環境変数 / オプションでの明示 enable → 既存呼び出し側変更が必要で後方互換が崩れる（opt-in シグナル方式の方が無変更で適用可能）

## ローカル責務（squash-unit.sh 内）

判定ロジックと分岐は squash-unit.sh の既存関数内ローカル責務として閉じる（外部スクリプト化しない / DDD 集約は立てない）。実装上は以下のローカル変数で表現する:

| ローカル変数 | 型 | 由来 |
|------------|---|------|
| `repo_root_for_checks` | 絶対パス | 既存（`git rev-parse --show-toplevel`） |
| `check_script` | string | 既存ループ変数 |
| `executed_count` | integer | 実行されたチェック数（0 → all skip 判定用） |

## ドメインルール（Invariants）

1. **opt-in シグナル不変ルール**: 各 `bin/${check}.sh` の存在 / 不在のみが当該チェックの実行 / skip を決める。リポジトリ種別判定は行わない
2. **既存挙動互換ルール**: 3 種すべて存在する環境（starter kit 自身など）では 3 種チェックがすべて実行され、出力・exit code は既存と完全一致
3. **ログ位置ルール**: 人間向け文言は stderr、機械可読トークンは stdout（既存 squash-unit.sh の `squash:error:*` 出力規約に揃える）
4. **集約 skip トークン規約**: 3 種すべてが skip された場合のみ集約レベルの info トークン `squash:info:internal-ci-checks-skipped` を stdout 出力する（個別 skip は無音 / トークン濫立を避ける）
5. **実行順序ルール**: チェックスクリプトの実行順序は `check-skill-references` → `check-bash-substitution` → `check-test-isolation` の固定順（既存通り）
6. **判定純粋性ルール**: 各 check の実行 / skip 判定はファイル存在確認のみで決まり、外部状態に依存しない

## 不変条件（Invariants 補足）

- 3 種すべての `bin/${check}.sh` が存在する環境では、実行有無・順序・exit code 規約は既存と完全一致
- 3 種すべての `bin/${check}.sh` が不在の環境では、stdout に `squash:info:internal-ci-checks-skipped`、stderr に `info: no internal CI check scripts present in bin/ (skipping)` が出力され、squash-unit.sh は当該ブロックで exit せず後続処理へ進む
- 3 種のうち一部のみ存在する環境では、存在分のみ実行され、不在分は無音 skip される（部分実行）。本ケースは starter kit が誤って bin/check-*.sh を欠いた場合に発生し得るが、別途 starter kit 側 CI / pre-commit で「3 種揃いの保証」を行う責務とし、本体スクリプトでは検査しない
- stdout には `squash:` プレフィックストークン以外を混入させない（既存規約維持）
