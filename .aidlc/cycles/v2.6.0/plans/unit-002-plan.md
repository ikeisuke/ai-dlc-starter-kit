# Unit 002 計画: migrate-backlog.sh UTF-8 多バイト境界分断バグ修正

## 概要

`skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()`（L70-80）で末尾に使われている `cut -c1-50` を、**`perl -CSD -Mutf8` ベースの UTF-8 安全な切り詰め実装**に置換し、日本語タイトルを含む Issue 移行時に slug 末尾の文字（多バイト境界）が分断されて化ける問題を解消する。`perl` は本スクリプトの既存依存（先行段で `s/[^...]//g` フィルタに利用済み）であり追加コストなし。`-CSD`（標準入出力の UTF-8 化）と `-Mutf8`（ソースコードと文字列リテラルの UTF-8 化）により `length` / `substr` がコードポイント単位で動作し、macOS（BSD perl）/ Linux（perl 5.x）双方で同一挙動になる。本 Unit のテスト容易性のため `main "$@"` 直接実行を `if` ガード化し、`generate_slug` を bats から副作用なく `source` 取り込み可能にする（Unit 境界の最小拡張、補足項目として明示）。新規 bats テストは UTF-8 切り詰め本体・境界条件・既存パイプ整合をカバーする 7 ケース構成とし、CI（`migration-tests.yml`）でトリガーされるよう PATHS_REGEX を拡張する。

> **方針再策定の経緯（Round 4 / DR-007 候補）**: Round 1〜3 では `LC_ALL=C.UTF-8 awk` 実装を採用していたが、Round 3 clean 後の実装着手・ローカル検証で **BSD awk（macOS）が `LC_ALL=C.UTF-8` でも `length()` がバイト数を返す** ことが判明。GNU awk（Linux）では文字数を返すためクロスプラットフォーム挙動分裂となり、本 Unit の「正確性」NFR が満たせない。`perl` は既に本スクリプトの依存であり、`-CSD -Mutf8` で全環境統一動作するため移行コスト最小。詳細は計画ファイル末尾の「方針再策定ログ」セクション参照。

## 関連 Issue

- #615

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| `skills/aidlc-setup/scripts/migrate-backlog.sh` L79 の `cut -c1-50` を「`perl -CSD -Mutf8` による UTF-8 安全切り詰め」実装に置換 | 含む |
| 上記置換のため `generate_slug()` のパイプライン構造を最小限調整（最終段のみ） | 含む |
| `migrate-backlog.sh` 末尾 `main "$@"` を `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` ガード化（テスト容易性のための最小拡張、Unit 境界の補足） | 含む |
| 新規 bats テスト `tests/aidlc-setup/migrate-backlog-slug.bats` 追加（7 ケース: 日本語混在 51 文字超 / `LC_ALL=C` 環境 / ASCII 純 51 文字 / 50 文字ちょうど不変 / 49 文字不変 / 空文字 / 記号除去後空 slug） | 含む |
| `.github/workflows/migration-tests.yml` の `PATHS_REGEX` に `skills/aidlc-setup/scripts/migrate-backlog\.sh` を追加（CI トリガー対応） | 含む |
| `cross-platform-review` スキルでの BSD/GNU awk 互換性確認 | 含む |
| `migrate-backlog.sh` のタイトル抽出 / Issue 番号取得 / 出力フォーマット等の **他関数** の処理変更 | 含まない（`main "$@"` ガード化のみ本 Unit 境界の補足として明示許可） |
| 他スクリプトでの `cut -c` 利用調査 / 横断置換 | 含まない（Issue 内容に従い line 79 のみ） |
| `awk` 不在環境でのフォールバック実装 | 含まない（依存追加なし、明示エラーのまま） |
| UTF-8 ロケール（`C.UTF-8` / `en_US.UTF-8`）双方なし環境でのフォールバック | 含まない（明示エラー exit、bats では検出ロジック単体を確認） |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc-setup/scripts/migrate-backlog.sh` | 編集 | (1) L79 の `cut -c1-50` を `perl -CSD -Mutf8` 切り詰め実装に置換 / (2) 末尾 `main "$@"` を `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` ガード化 |
| `tests/aidlc-setup/migrate-backlog-slug.bats` | 新規作成 | 7 ケースの bats テスト |
| `.github/workflows/migration-tests.yml` | 編集 | `PATHS_REGEX` に `skills/aidlc-setup/scripts/migrate-backlog\.sh` を追加 |
| `.aidlc/cycles/v2.6.0/history/construction_unit02.md` | 新規作成 | Unit 002 の進捗履歴（write-history スキル経由） |
| `.aidlc/cycles/v2.6.0/construction/units/002-review-summary.md` | 新規作成 | レビューサマリ |

## 設計（簡略論理設計）

`depth_level=standard` のため Phase 1 を実施するが、本 Unit は単一関数の最終段置換 + bats 追加に限定されるため、ドメインモデルは不要・論理設計は計画ファイル内に統合する。

### 採用実装

#### 切り詰め本体（perl ベース）

```bash
perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'
```

- **採用根拠**: `perl` は本スクリプトの既存依存（`generate_slug` 内の先行段で `s/[^...]//g` フィルタに利用済み、L20-32 の `command -v perl` チェックでも依存検証済み）。`-CSD`（標準入出力の UTF-8 化）と `-Mutf8`（ソースコードと文字列リテラルの UTF-8 化）で `length` / `substr` がコードポイント単位で動作
- **クロスプラットフォーム互換性**: macOS（system perl 5.x）/ Linux（perl 5.x）/ GH Actions ubuntu-latest（perl 5.x）すべてで同一挙動。BSD awk と GNU awk の `length()` 挙動分裂問題（Round 3 後のローカル検証で発覚）を回避
- **既存パイプとの整合**: 既存の `tr | perl -pe 's/...//g' | tr | sed | sed | cut` パイプラインの最終段 `cut -c1-50` のみを差し替え、上流は無変更
- **`chomp` / 改行付け直し**: 入力末尾改行を `chomp` で剥がし、`length` 計算を改行抜きで行い、最後に `\n` を再付与。`-pe` で行単位処理し、stdin から複数行入力されても各行ごとに切り詰める。本スクリプトでは入力 1 行（`echo "$title"` 由来）だが、安全策として行単位処理形式を採用

#### `main "$@"` ガード化（指摘 #1 対応）

```bash
# 旧: main "$@"
# 新:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

- bats から `source skills/aidlc-setup/scripts/migrate-backlog.sh` で `generate_slug` を取り込んでも `main` が走らないため、テストの副作用ゼロを担保
- 直接実行（`bash migrate-backlog.sh ...`）の挙動は完全互換

### bats テストケース（Round 1 指摘 #3 対応で 7 ケースに拡張）

> **入力選定の補足**: `generate_slug` は `tr | perl s/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g | tr | sed | sed` を経由するため、フィルタによって入力長が減少する。「(a)(b) 51 文字超で切り詰め発火」を検証するためには、`tr [:upper:] [:lower:]` と先行 perl フィルタを通過した後でも 51 文字以上残る入力を選定する必要がある。例: 「あ × 51」やカタカナ「ア × 51」のような単一文字反復、または「これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ」のような既存例（フィルタ後 44 文字、本ケースは「切り詰め非発火」テストとして利用可能）。各テストの実入力は実装時に `bash -c 'source ...; generate_slug "<入力>" | perl -CSD -Mutf8 -ne "chomp; print length"' ` でフィルタ後文字数を確認して確定する。

| # | 入力例 | 期待出力（slug 部分） | 検証観点 |
|---|------|---------------------|---------|
| (a) 日本語切り詰め発火 | 例: `あ` × 51（フィルタ通過後も 51 文字） | コードポイント単位で 50 文字に切り詰めた文字列（`あ` × 50）。末尾文字が多バイト境界で分断されていない（`?` / 文字化けなし） | UTF-8 安全切り詰め本体 |
| (b) `LC_ALL=C` 環境 | (a) と同じ入力を `LC_ALL=C` 環境下で投入 | (a) と同一の出力（perl `-CSD -Mutf8` がロケール非依存に動作） | 呼び出し側ロケール非依存性 |
| (c) ASCII 純 51 文字 | `'a' × 51`（フィルタ通過後 51 文字） | 先頭 50 文字（従来 `cut -c1-50` と完全一致） | 既存動作の回帰なし |
| (d) 50 文字ちょうど不変 | `'b' × 50`（フィルタ通過後 50 文字） | 入力そのまま（50 文字、変更なし） | 境界条件: 切り詰め発火境界 |
| (e) 49 文字不変 | `'c' × 49`（フィルタ通過後 49 文字） | 入力そのまま（49 文字、変更なし） | 境界条件: 切り詰め非発火 |
| (f) 空文字 | 空文字列 `""` | 空文字列（既存パイプ `tr → perl → tr → sed → sed → perl` の整合維持） | 入力境界: 既存ガード連携 |
| (g) 記号除去後空 slug | `"!!!"` 等、先行 `perl -pe 's/[^...]//g'` で全削除される入力 | 空文字列（既存パイプの `sed 's/^-//;s/-$//'` 直後で空、最終段 perl 切り詰めも空のまま通過） | パイプ整合性 |

### bats テスト構造（最終）

```text
@test "(a) generate_slug は日本語切り詰め発火入力を UTF-8 コードポイント 50 文字で切る" {
  # main ガード化済みのため source は副作用なし
  source "$BATS_TEST_DIRNAME/../../skills/aidlc-setup/scripts/migrate-backlog.sh"
  # フィルタ通過後 51 文字以上残る入力（実装時に確定。例: "あ" を 51 個並べた文字列）
  input="<実装時に確定: フィルタ通過後 51 文字以上の日本語入力>"
  result="$(generate_slug "$input")"
  # 文字数（codepoint）が 50 ちょうどであること
  actual_len="$(printf '%s' "$result" | perl -CSD -Mutf8 -ne 'chomp; print length($_)')"
  [ "$actual_len" -eq 50 ]
  # 末尾化け検証: 不正 UTF-8 シーケンスが含まれない
  printf '%s' "$result" | iconv -f UTF-8 -t UTF-8 >/dev/null
}
```

> bats からの `source` 取り込みは、`main "$@"` ガード化により副作用なく成功する（Round 1 指摘 #1 対応の核心）。`source ... || true` のような fallback 構文は使用しない。

### CI トリガー設計

- 既存の bats 実行行 `bats ... tests/aidlc-setup/ ...` は `tests/aidlc-setup/migrate-backlog-slug.bats` を自動的に拾うため、実行行追記は不要
- `PATHS_REGEX` に `skills/aidlc-setup/scripts/migrate-backlog\.sh` を追加しないと、`.sh` のみ変更した PR で CI が起動しないため必ず追加する
- bats のみ変更した PR は既存の `tests/aidlc-setup/.+` で起動する

## 実装計画

### Phase 1（設計）

論理設計として上記「採用実装」「bats テストケース」「CI トリガー設計」を確定。設計レビューは「計画承認前レビュー」と統合する（変更規模が小さいため）。

### Phase 2（実装）

1. `migrate-backlog.sh` L79 の `cut -c1-50` を `perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'` に置換
2. `migrate-backlog.sh` 末尾 `main "$@"` を `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` ガード化
3. `tests/aidlc-setup/migrate-backlog-slug.bats` を作成し 7 ケース（(a)〜(g)）を実装。各テストは `source` で関数取り込み（main ガード化により副作用なし）。テスト入力は実装時にフィルタ通過後の文字数を確認して確定する
4. ローカル bats 実行（`bats tests/aidlc-setup/migrate-backlog-slug.bats`）で 7 ケース PASS を確認
5. `tests/aidlc-setup/` 全体 bats 回帰実行で既存 PASS 維持
6. `.github/workflows/migration-tests.yml` の `PATHS_REGEX` を編集し `skills/aidlc-setup/scripts/migrate-backlog\.sh` を追加
7. `cross-platform-review` スキルで `migrate-backlog.sh` を perl `-CSD -Mutf8` の互換性 + 既存 BSD/GNU 互換観点でレビュー
8. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
9. 履歴記録（`/aidlc:write-history` スキル）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `perl` 不在環境 | 既存の依存チェック（L20-32 の `command -v perl`）で明示エラー exit（既存挙動）。フォールバック実装は設けない |
| `perl` の `-CSD` / `-Mutf8` 未対応バージョン | macOS system perl 5.18+ / Linux perl 5.x で標準サポート済み。Perl 5.6 以下の極端に古い環境のみが対象外で、cross-platform-review で検出した場合は対応方針を計画修正 |
| BSD awk と GNU awk での `length()` 動作差 | **本実装では awk を使わないため非該当**（Round 3 後のローカル検証で発覚した問題は perl 実装で完全回避） |
| 既存テストの regression | `bats tests/aidlc-setup/` 全体で PASS を維持。fail 時は実装を見直す |
| `main "$@"` ガード化による既存 CLI 実行への影響 | `bash skills/aidlc-setup/scripts/migrate-backlog.sh ...` のように直接実行された場合は `${BASH_SOURCE[0]} == ${0}` が真となり main が走るため互換 |

## NFR

- **正確性**: UTF-8 コードポイント単位で正確に 50 文字を保持（バイト分断による末尾化け 0 件）
- **互換性**: 純 ASCII タイトル時は従来 `cut -c1-50` と完全一致
- **可搬性**: macOS（system perl）/ Linux（perl 5.x）両対応、`LC_ALL=C` 呼び出しでも結果一致（perl `-CSD -Mutf8` がロケール非依存に UTF-8 として動作）

## 完了条件チェックリスト

### 機能整合

- [x] `migrate-backlog.sh` L79 の `cut -c1-50` が `perl -CSD -Mutf8 -pe 'chomp; $_ = substr($_, 0, 50) if length($_) > 50; $_ .= "\n";'` に置換されている
- [x] `main "$@"` が `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` ガード化されている
- [x] `generate_slug()` の他処理（`tr` / 先行 `perl` / `sed`）は変更されていない
- [x] `migrate-backlog.sh` の他関数（`output` / `get_prefix_from_section` 等）は変更されていない（ガード化を除く）

### テスト / lint

- [x] **必須**: `tests/aidlc-setup/migrate-backlog-slug.bats` の 7 ケース（(a) 日本語混在 51 文字超 / (b) `LC_ALL=C` 環境 / (c) ASCII 純 51 文字 / (d) 50 文字ちょうど不変 / (e) 49 文字不変 / (f) 空文字 / (g) 記号除去後空 slug）が全て PASS する
- [x] **必須**: 既存 `tests/aidlc-setup/` 全体 bats が PASS（regression なし）
- [x] **参考**: `markdownlint-cli2` 全体実行で本 Unit のスコープ外既存違反は完了条件に含めない

### CI 接続

- [x] `.github/workflows/migration-tests.yml` の `PATHS_REGEX` に `skills/aidlc-setup/scripts/migrate-backlog\.sh` が追加されている
- [x] bats 実行行は既存の `tests/aidlc-setup/` 経由で新規 bats が拾われることを目視確認

### Cross-platform 検証

- [x] `cross-platform-review` スキル実行結果で BSD/GNU awk 双方の互換性に問題なしと判定される
- [x] 問題判定時は別途対応方針を計画修正に反映

### 履歴

- [x] `.aidlc/cycles/v2.6.0/history/construction_unit02.md` が新規作成され、変更ファイル一覧 / 検証結果 / レビュー round が記録される
- [x] 履歴ファイルに **AI レビューの実施証跡**（codex セッション利用の有無、各 round の指摘件数とラウンド結果、最終判定、cross-platform-review 結果）を明記

### 品質ゲート

- [x] AI レビュー（`reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（1R clean 特例または直近 round clean）を満たす

## 見積もり

- 設計フェーズ: 0.05 日（本計画ファイル内に統合 + Round 4 perl 実装方針への再策定）
- 実装フェーズ: 0.35 日（perl 1 行置換 + main ガード化 + bats 7 ケース + CI 編集 + cross-platform-review + 3 段レビュー + 履歴）
- 合計: **0.4 日（約 35〜45 分、Unit 定義見積もり 30〜45 分とほぼ一致。Round 4 方針再策定で総コストはやや拡大したが、単純 1 行置換のため実装フェーズは短縮）**

---

## 方針再策定ログ（Round 4）

### 経緯

- Round 1〜3 では `LC_ALL=C.UTF-8 awk '{ length / substr }'` 実装を採用、Round 3 で codex AI レビュー clean
- Round 3 clean 後、実装着手・ローカル動作確認で **macOS の BSD awk が `LC_ALL=C.UTF-8` でも `length()` をバイト数で返す** ことが判明（70 バイト = 70 文字扱い、`length()` の 50 文字判定が誤る）
- GNU awk（Linux / GH Actions ubuntu-latest）では文字数を返すため、クロスプラットフォーム挙動分裂
- 本 Unit の NFR「正確性: UTF-8 コードポイント単位で正確に 50 文字を保持」「可搬性: macOS / Linux 両対応」が満たせない

### 検証ログ

```text
$ printf '%s' "これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ" \
  | LC_ALL=C.UTF-8 awk '{ print length($0) }'
70   # macOS BSD awk: バイト数（期待: 44）
$ printf '%s' "これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ" \
  | wc -c
70   # バイト数と一致 → BSD awk は length() をバイト数で返している
```

### 再策定内容

| 項目 | Round 3 まで | Round 4 以降 |
|------|------------|-------------|
| 切り詰め実装 | `LC_ALL="$lc" awk '{ length/substr }'` | `perl -CSD -Mutf8 -pe '...'` |
| ロケール検出ヘルパー `_detect_utf8_locale` | 追加 | 不要（perl はロケール非依存に動作するため） |
| `main "$@"` ガード化 | 含む | 含む（変更なし） |
| bats 7 ケース | 含む | 含む（変更なし） |
| CI PATHS_REGEX 拡張 | 含む | 含む（変更なし） |
| cross-platform-review 観点 | BSD/GNU awk + locale | perl `-CSD -Mutf8` の互換性 + 既存 BSD/GNU 観点 |

### 影響範囲

- Round 3 clean を失効させる方針変更ではなく、**Round 3 clean 後の実装中に発覚した cross-platform 互換性問題に対する planの再策定**
- review-flow.md の「is_completed の last_round_clean」基準は再レビュー結果（Round 4）で再評価する
- Round 4 は計画承認前レビューのため、サマリ非生成ルール（review-flow.md「Round 4 以降の新領域指摘の自動 backlog 化フロー > 計画承認前レビューでの扱い（特例）」）が適用される。`K_old` / `K_new` / `K_diff` は本ファイル内の「方針再策定ログ」に手動で記録する

### Round 4 領域キー記録（手動・特例）

```json
{
  "K_old_R1to3": ["cycle-artifacts/plans"],
  "K_new_R4": ["cycle-artifacts/plans"],
  "K_diff": [],
  "rationale": "Round 4 で発生した変更は計画ファイル本体の方針再策定（同一領域内）で、新領域指摘は発生していない"
}
```
