# レビューサマリ: Unit 002 — 禁止パースパターンの CI 機械検出（T4）

## 基本情報

- **サイクル**: v3.0.0-alpha.4
- **フェーズ**: Construction
- **対象**: Unit 002（frontmatter-parse-ci-guard）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-06-23（設計レビュー）

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘対応判断完了（全 10 件 修正済み / unresolved 0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - 「文字列リテラル除外」が検出対象（`grep '^status:'` のクォート内 regex 引数）と衝突し違反①②④を取りこぼす | 修正済み（除外を「実行されないデータ文字列のみ」に限定し regex 引数は検出対象と明示。`is_excluded_context` に区別責務を追加） | - |
| 2 | 高 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - 複数行検出不足（backslash/pipe 継続で command 行と token 行が分離し検出根拠不成立） | 修正済み（`build_logical_units` 新設・論理コマンド単位連結規則を明文化・T-10 を具体 fixture 化） | - |
| 3 | 中 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - allow マーカー統制が計画の「Issue 必須/stale」より弱い | 修正済み（issue `#NNN` 構文強制 + stale 検出 T-17〔marker 除去で違反再現〕追加 + expiry 不採用差分明記） | - |
| 4 | 高 | `design-artifacts/domain-models/unit_002_frontmatter_parse_ci_guard_domain_model.md` - 論理設計更新後もドメインモデルが旧仕様（`各 Line` / 文字列リテラル除外）残存で矛盾 | 修正済み（`LogicalUnit` 化・除外条件をデータ文字列限定に統一・ViolationDetector を unit 単位に） | - |
| 5 | 中 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - allow マーカー構文 `issue: <#NNN\|ref>` が必須構文 `<#NNN>` と不一致 | 修正済み（`issue: <#NNN>` に統一） | - |
| 6 | 中 | `design-artifacts/domain-models/unit_002_frontmatter_parse_ci_guard_domain_model.md` - 末尾 Q&A が旧統制（reason のみ / 既知集合固定=stale 代替）で上部 VO・論理設計と矛盾 | 修正済み（Q&A を reason/issue 必須・T-11/T-16/T-17・expiry 不採用差分に更新） | - |
| 7 | 低 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - 経験的検証テーブル ⑤ 行に旧「行スキャン」表現残存 | 修正済み（`build_logical_units` 連結表現に統一・NFR も同様） | - |
| 8 | 中 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - `is_excluded_context` コンポーネント概要に旧「文字列リテラル」残存 | 修正済み（データ文字列限定・regex 引数は検出対象に統一） | - |
| 9 | 低 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - 冒頭パイプライン図・本体責務に旧「行スキャン」残存 | 修正済み（論理コマンド単位スキャンに統一 / grep 一括掃討で残存ゼロ確認） | - |
| 10 | 低 | `design-artifacts/logical-designs/unit_002_frontmatter_parse_ci_guard_logical_design.md` - `issue: <#NNN>` プレースホルダ表記の整形 | 修正済み（`issue: #NNN` に正規化 / 意味変更なし） | - |

### Round 4 新領域判定

```json
{
  "K_old": ["cycle-artifacts"],
  "K_new": ["cycle-artifacts"],
  "K_diff": [],
  "rounds_executed": 5
}
```

全ラウンドの指摘対象は設計成果物（`.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/**` = 領域キー `cycle-artifacts`）のみであり、Round 4 以降の新領域指摘は発生していない（K_diff 空）。新領域判定の境界条件・判定手順は `skills/aidlc/steps/common/review-flow.md` の「Round 4 以降の新領域指摘の自動 backlog 化フロー」を参照。

> Round 別指摘件数閾値（設計レビュー早期 defer ガイド）: Round 3 = 2 件（<5）/ Round 4 = 2 件（<3）のため OUT_OF_SCOPE 化アラートは未発火。Round 2〜5 の指摘は全て同一 2 ファイルの整合性修正（substantive な R1 の 3 件を反映した後の波及整合）であり、全件 resolved。

---

## Set 2: 2026-06-23（コードレビュー）

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘対応判断完了（全 9 件 修正済み / unresolved 0）
- **セキュリティ N/A 判定**: ネットワーク/認証/HTTP 系観点は N/A（ローカル CI ガード・NW 通信なし・読み取り専用走査）。mktemp + trap cleanup、サンドボックス安全削除は確認済み。

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `bin/check-frontmatter-parse-guard.sh` - 末尾インラインコメント中の apostrophe が単一引用符パリティを崩し違反取りこぼし / END で末尾 acc 未評価 | 修正済み（strip_comment 簡易 lexer 追加・marker は原文判定・END で末尾 acc 評価 / T-18,T-18b 追加） | - |
| 2 | 中 | `bin/check-frontmatter-parse-guard.sh` - 複数行 jq が論理単位連結されず permissive jq 取りこぼし | 修正済み（has_quote_cmd で jq を継続ゲートに追加 / T-19 追加） | - |
| 3 | 中 | `bin/check-frontmatter-parse-guard.sh` - is_fm_token が既知キー whitelist 限定で汎用/将来キー取りこぼし | 修正済み（汎用 ^key: を frontmatter 文脈シグナル付きで検出 / T-20,T-20b 追加） | - |
| 4 | 低 | `bin/check-frontmatter-parse-guard.sh` - find がプロセス置換で失敗が捕捉されず exit 2 にならない | 修正済み（find を一時ファイル経由化・失敗時 exit 2） | - |
| 5 | 低 | `bin/tests/check-frontmatter-parse-guard.sh` - stale 検出が status.sh のみで他ファイルの新規 marker を検出しない | 修正済み（T-21 でリポジトリ全体の許可 marker 集合を固定アサート） | - |
| 6 | 中 | `bin/check-frontmatter-parse-guard.sh` - 汎用 ^key: 文脈が `$file` 等 work item パス変数で抜ける | 修正済み（文脈シグナルに work item パス変数追加・語境界で $logfile 等は誤一致せず / T-20c 追加） | - |
| 7 | 中 | `bin/check-frontmatter-parse-guard.sh` - is_fm_token の .md 境界が `[" \t]` のみで `'foo.md'`/未引用符/行末を取りこぼし | 修正済み（.md 境界を `([]"')]\|[[:space:]]\|$)` に拡張 / T-20d,T-20e 追加） | - |
| 8 | 中 | `bin/check-frontmatter-parse-guard.sh` - has_jq_coerce の .md 境界が is_fm_token と非対称 | 修正済み（同型境界に統一 / T-19b,T-19c 追加） | - |
| 9 | 中 | `bin/check-frontmatter-parse-guard.sh` - heredoc 検出が `<<"EOF"` のみで `<<'EOF'`/`<<-'EOF'` を扱えず本文を false positive | 修正済み（引用符付きタグの両クォート対応 / T-22,T-22b 追加） | - |

### Round 4 新領域判定

```json
{
  "K_old": ["bin", "skills"],
  "K_new": ["bin", "skills"],
  "K_diff": [],
  "rounds_executed": 5
}
```

全ラウンドの指摘対象は検出スクリプト本体 `bin/check-frontmatter-parse-guard.sh`（領域キー `bin`）とテスト（同 `bin`）に集中。Round 4 以降の新領域指摘なし（K_diff 空）。

> Round 別指摘件数: R1=5 / R2=1 / R3=1 / R4=1 / R5=1。R2 以降は heuristic linter の long tail（コメント/quote/heredoc/`.md` 境界の edge case）の段階的精緻化で、いずれも全件 resolved。R5（5R 上限）の heredoc false-positive は指摘対応判断フローで「修正する」を選択し、T-22/T-22b で検証のうえ resolved。

---

## Set 3: 2026-06-23（統合レビュー）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus: code）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘対応判断完了（全 6 件 修正済み / unresolved 0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `bin/check-frontmatter-parse-guard.sh` - 継続判定が単一引用符のみで二重引用符複数行 sed/jq プログラムを連結できず false negative | 修正済み（当初 `$(` paren net 深さ → 後に R5 でスタックベース字句解析 unit_incomplete に置換 / T-23,T-23b,T-23c 追加） | - |
| 2 | 中 | `bin/check-frontmatter-parse-guard.sh` - marker の READ 誤用判定が is_extraction 偏重で redirect 型 READ（grep > tmp）を許可 | 修正済み（marker 除外を awk atomic write idiom に限定・grep/sed/jq は除外不可 / T-24,T-24b 追加） | - |
| 3 | 中 | `bin/check-frontmatter-parse-guard.sh` - marker awk 限定が `cmd==awk && !is_extraction` のみで非 atomic awk READ を許可 | 修正済み（is_atomic_write シグネチャ判定導入 / T-25,T-25b,T-25c 追加） | - |
| 4 | 中 | `bin/check-frontmatter-parse-guard.sh` - is_atomic_write が `print "key:"` のみ要求し passthrough 未検証 | 修正済み（全行 passthrough `{print}` + key 書き換えの両方を要求 / T-25d 追加） | - |
| 5 | 中 | `bin/check-frontmatter-parse-guard.sh` - passthrough 判定が条件付き `/^title:/{print}` も誤認 | 修正済み（無条件既定ルール `{print}`〔直前が `}`/`;`/`'`〕に厳密化 / T-25e 追加） | - |
| 6 | 中 | `bin/check-frontmatter-parse-guard.sh` - `$()` 継続の `)` 総数カウントが regex 内括弧で誤完成し取りこぼし | 修正済み（スタックベース字句解析 unit_incomplete に置換・引用符内の `)` を無視 / T-23c 追加） | - |

### Round 4 新領域判定

```json
{
  "K_old": ["bin"],
  "K_new": ["bin"],
  "K_diff": [],
  "rounds_executed": 5
}
```

全ラウンドの指摘対象は検出スクリプト本体・テスト（領域キー `bin`）に集中。Round 4 以降の新領域指摘なし（K_diff 空）。

> Round 別指摘件数: R1=2 / R2=1 / R3=1 / R4=1 / R5=1。継続判定（複数行プログラム連結）と allow marker の atomic write idiom 厳密化の long tail で、いずれも全件 resolved。R5（5R 上限）の `$()` regex-paren 取りこぼしは指摘対応判断フローで「修正する」を選択し、スタックベース字句解析（unit_incomplete）への置換 + T-23c で検証のうえ resolved。T-21（リポジトリ全体の許可 marker 集合 = status.sh の 1 件のみ固定）が新規 marker 追加を検出する多層防御のバックストップ。
