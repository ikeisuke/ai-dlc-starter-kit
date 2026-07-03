# ドメインモデル: Unit 002 — 禁止パースパターンの CI 機械検出（T4）

## 概要

`skills/aidlc-v3/scripts/` の個別 consumer スクリプト（`lib/` と `tests/` を除く）に frontmatter 構造解釈の禁止パターン（生の `grep`/`sed`/`awk`/permissive `jq`）が混入していないかを機械検出するドメイン。Unit 001 で確立した共有 parser 境界からの逸脱を、人手レビューに頼らず CI で自動検出する。

**重要**: 本設計では**コードは書かず**、検出ドメインの構造と責務のみを定義する。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/lib/frontmatter.sh` | 禁止規約 SoT（24-31 行）と共有 parser API の確定。検出が整合すべき境界の根拠 |
| `skills/aidlc-v3/scripts/work-item-validate.sh` | consumer の frontmatter 利用形態（fm_* 経由）と C1（body セクション grep）の実在確認 |
| `skills/aidlc-v3/scripts/work-item-next.sh` | consumer の fm_* 利用形態の確認 |
| `skills/aidlc-v3/scripts/work-item-status.sh` | **C2（atomic write awk / 150-156 行）の実在確認**。誤検出回避の最難関ケース |
| `skills/aidlc-v3/scripts/state-*.sh` | B（JSON/jq 正当用途）の確認。検出対象外であることの根拠 |
| `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh` | 既存 check スクリプト様式（終了コード・違反報告形式・allowlist 統制）の参照 |
| `.github/workflows/skill-reference-check.yml` | CI step 追加先・skip 判定（PATHS_REGEX）の構造確認 |

### (b) 設計時に意識すべき挙動（経験的調査の確定事実）

- **consumer は全て共有 parser に移行済み（frontmatter 構造解釈の生 grep/sed/awk は 0 件）**。よって検出ジョブは現状で緑になるのが完了条件。
- **誤検出してはいけない正当パターン（実在）**:
  - **C1** `work-item-validate.sh:171` `echo "$body" | grep -Eq "^## ${sec}$"` — 抽出済み変数 `$body` に対する **markdown 見出し（`^##`）** 検索。frontmatter フィールドトークン（`^key:`）ではない。
  - **C2** `work-item-status.sh:150-156` `awk ... infm ... /^status:/ { print "status: " newstatus } ... "$file" > "$tmp"` — frontmatter の `status:` 行を **書き換える（atomic write）**。Unit 001 が「atomic write は consumer 責務」と明示的に carve-out 済み（`frontmatter.sh:20`）。値を抽出して logic に使う READ ではない。**これは frontmatter フィールドトークン（`^status:` / `---`）をファイルに対して参照するため、素朴な内容検出では誤検出する → 設計上の最重要分岐点**。
  - **C3** `state-validate.sh:103` `printf '%s' "$schema_version" | tr -d '[:cntrl:]'` — サニタイズ。`tr` は検出コマンド集合外。
  - **B** `state-*.sh` の `jq`（11 箇所）— 全て `.json` ファイル / JSON 値に対する操作。frontmatter（YAML テキスト）ではない。
- **検出すべき違反パターン（consumer には実在しない仮想例 = fixture 化対象）**:
  - ① ファイル直接抽出: `grep '^status:' "$file" | sed 's/^status:[[:space:]]*//'`
  - ② dependencies 生パース: `sed -nE 's/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p' "$file"`
  - ③ frontmatter への permissive jq: `jq -r '.assigned // empty' <<< "$fm"`（frontmatter は YAML であり jq 対象にすること自体が逸脱）
  - ④（R1#1）変数経由 READ: `block="$(fm_extract_block "$f")"; status="$(echo "$block" | sed -n 's/^status:.*//p')"`
  - ⑤（R1#1）複数行パイプ / 関数経由の同型逸脱

### (c) 既存実装に基づく代替案検討（検出アルゴリズムの選定）

| 方針 | 概要 | 既存パターンとの適合 | 採否 |
|------|------|---------------------|------|
| **refactor（既存 check 流用）** | `bin/check-*.sh` の様式（shebang / `set -euo pipefail` / `git rev-parse` / `find -print0` / `<file>:<line>: <message>` / 終了コード 0/1/2）を踏襲 | 高（統一感確保） | **採用**（実装様式） |
| 候補 A（同一行内容ヒントのみ） | `grep`/`sed`/`awk` を含む行に frontmatter トークンが共起したら違反 | 変数経由・複数行・関数経由 READ（④⑤）を取りこぼす（R1#1）。C2 を誤検出 | **却下**（false negative + false positive 両方） |
| 候補 B（行マーカーのみ） | 全 `grep`/`sed`/`awk` を違反とし、allow マーカーで個別許可 | C1/C3/B 等の正当用途が大量にマーカー必要 → 運用負荷大・抜け道リスク | **却下**（過剰適用） |
| **候補 C（トークン検出 + 限定 allow マーカー）** | frontmatter フィールドトークン（`^key:` / `---` ブロック）を参照する生 `grep`/`sed`/`awk`/permissive `jq` を違反とし、C2 のような正当 write のみ allow マーカーで除外 | C1（`^##`）/ B（`.json` jq）/ C3（`tr`）を自然に除外。④⑤ を検出。C2 を marker で制御 | **採用**（検出アルゴリズム） |

## エンティティ（Entity）

### ScanTarget（走査対象スクリプト）

- **ID**: リポジトリ相対ファイルパス（例: `skills/aidlc-v3/scripts/work-item-validate.sh`）
- **属性**:
  - path: String — 対象スクリプトの相対パス
  - logicalUnits: List<LogicalUnit> — 物理行を論理コマンド単位（backslash/pipe 継続・`$(...)`・awk プログラムを連結）に束ねた集合（各 unit は先頭物理行番号を保持）
  - isInAllowlistDir: Boolean — `lib/` または `tests/` 配下か（true なら走査対象外）
- **振る舞い**:
  - isScannable(): `skills/aidlc-v3/scripts/` 配下かつ `lib/` `tests/` 配下でない `*.sh` なら true
  - scan(): 各 LogicalUnit を ViolationDetector にかけ Violation 集合を返す（**物理行単位ではない** = 継続行・複数行 idiom の取りこぼし防止 / R-design#2）

### Violation（検出された違反）

- **属性**:
  - file: String — リポジトリ相対パス
  - line: Integer — 違反行番号
  - command: Enum{grep, sed, awk, jq} — 検出されたコマンド種別
  - matchedToken: String — 違反の根拠となった frontmatter トークン（`^status:` / `---` 等）
  - message: String — 違反理由（共有 parser 利用を促す文言）
- **振る舞い**:
  - render(): `<file>:<line>: <message>` 形式の 1 行を生成

## 値オブジェクト（Value Object）

### ForbiddenPattern（禁止パターン定義）

- **属性**:
  - command: Enum{grep, sed, awk, jq}
  - frontmatterTokenRegex: ERE — frontmatter 構造解釈を示すトークン（`^[A-Za-z_][A-Za-z0-9_]*:` のフィールドキー抽出 / `---` delimiter ブロック処理）
  - jqCoerceRegex: ERE（jq のみ）— permissive coerce（`//` 既定値 / `?` 型エラー抑制 / 暗黙型変換）
- **不変性**: 検出ルールはスクリプト起動時に固定。実行中に変化しない
- **等価性**: command + 正規表現の組で等価

### FrontmatterContext（frontmatter 文脈判定）

- **属性**:
  - tokenSet: Set<ERE> — frontmatter フィールドトークン群（`^status:` `^id:` `^dependencies:` `^size:` `^risk:` `^assigned:` および汎用 `^[a-z_]+:` frontmatter キー、`---` ブロック）
- **不変性**: 文脈判定の語彙は固定
- **責務**: 「frontmatter 構造解釈の文脈か否か」を判定し、C1（`^##` markdown 見出し）/ B（`.json` jq）/ C3（`tr` サニタイズ）を文脈外として除外する境界を体現する

### AllowMarker（限定 allow マーカー）

- **属性**:
  - reason: String（必須・非空）— allow の理由
  - issue: String（必須・`#NNN` 形式）— tracking reference（R-design#3 / 計画「Issue 必須」を構文強制）
  - ref: String — 根拠参照（例: `Unit 001 frontmatter.sh:20 atomic-write carve-out`）
- **不変性**: マーカーは行に固定付与
- **責務（R1#2 + R-design#3 統制）**: **非構造用途（atomic write 等）の false positive のみ** allow 可。frontmatter 構造解釈の READ（スカラー抽出・配列パース）そのものは allow 不可。reason / issue 必須。stale 検出 = marker 除去で違反が再現することをテストで機械検証。現行で許可される唯一のマーカーは `work-item-status.sh` の atomic write awk
- **等価性**: 付与行 + reason で識別

## 集約（Aggregate）

### GuardCheck（検出チェック集約）

- **集約ルート**: GuardCheck
- **含まれる要素**: ScanTarget のリスト / ForbiddenPattern 集合 / FrontmatterContext / AllowMarker 集合 / Violation のリスト
- **境界**: 1 回の検出実行（リポジトリルートからの走査〜終了コード決定まで）
- **不変条件**:
  - `lib/` `tests/` 配下は走査しない（allowlist ディレクトリ）
  - 違反 0 件 → exit 0、違反 ≥1 → exit 1（違反箇所報告）、システムエラー → exit 2
  - opt-in シグナル: 走査対象ディレクトリ（`skills/aidlc-v3/scripts/`）が不在なら違反 0 件として exit 0（consumer プロジェクトで自然に skip）
  - allow マーカー付与行は Violation から除外されるが、マーカーは非構造 write のみに限定（構造解釈 READ は marker でも除外不可）

## ドメインサービス

### ViolationDetector（違反検出サービス）

- **責務**: 1 つの **LogicalUnit**（物理行を継続規則で連結した論理コマンド単位）に対し、ForbiddenPattern × FrontmatterContext を適用し Violation を生成する
- **操作**:
  - detect(unit, context): 生 `grep`/`sed`/`awk` が frontmatter トークンを参照し、かつ **除外コンテキスト（フルラインコメント / heredoc / echo・printf の出力データ文字列のみ。grep・sed・awk の regex 引数は除外せず検出対象 / R-design#1）** に該当せず、AllowMarker（非構造 write 限定）も無ければ Violation を返す
  - detectJqCoerce(unit): jq が frontmatter テキスト（`<<< "$fm"` 等）を入力とし permissive coerce を含む場合のみ Violation を返す（`.json` 入力の jq は対象外）

### AllowlistResolver（走査対象判定サービス）

- **責務**: ScanTarget が走査対象か（`lib/` `tests/` 除外 + 自スクリプト除外）を判定
- **操作**: resolve(path): isScannable を返す

### ExitCodeResolver（終了コード決定サービス）

- **責務**: Violation 件数とシステム状態から終了コードを決定（`guides/exit-code-convention.md` 整合）
- **操作**: resolve(violations, systemError): 0 / 1 / 2 を返す

## ユビキタス言語

- **frontmatter 構造解釈**: work item Markdown の YAML frontmatter（`---` 〜 `---`）の delimiter 処理・`key: value` スカラー抽出・`dependencies` 配列パース・malformed guard。Unit 001 で共有 parser `fm_*` に集約済み。**本検出が守る境界**
- **禁止パターン**: 個別 consumer での frontmatter 構造解釈に生 `grep`/`sed`/`awk`/permissive `jq` を直接書くこと（`frontmatter.sh:24-31` SoT）
- **frontmatter フィールドトークン**: `^status:` `^id:` `^dependencies:` `^size:` `^risk:` `^assigned:` 等の frontmatter キー、および `---` delimiter。検出の文脈判定の核
- **permissive jq coerce**: `// 既定値` / `?`（型エラー抑制）/ 暗黙型変換。frontmatter 文脈に限定して検出
- **allowlist ディレクトリ**: `lib/`（共有 parser 本体）/ `tests/`（fixture）。走査対象外
- **opt-in シグナル**: 検出スクリプトの存在自体が opt-in。consumer プロジェクトでは走査対象不在で自然に skip（`CLAUDE.md` ドッグフーディング原則）
- **atomic write carve-out**: frontmatter の書き換え（status 更新等）は Unit 001 が consumer 責務と明示。READ 禁止の対象外（`frontmatter.sh:20`）

## 不明点と質問（設計中に記録）

[Question] C2（work-item-status.sh の atomic write awk）を allow マーカーで除外する方針について、マーカー付与は consumer の挙動変更に当たらないか。
[Answer] コメント 1 行の付与であり実行挙動は不変。計画 §3「含まない: 既存 consumer の挙動変更」に抵触しない（挙動 = 実行結果は変わらない）。マーカーは検出メタデータのみ。

[Question] R1#2 の「既存 allowlist 系チェック同等の統制（理由/Issue/stale）」を、インライン allow マーカー方式でどこまで実装するか。
[Answer] 完全な allowlist ファイル機構（`check-test-isolation.allowlist` の 6 列 + 期限 + stale 検出）はインライン 1 マーカーには過剰。本設計では論理設計 §allow マーカー統制（R1#2 + R-design#3）のとおり次で同等統制を満たす: (1) **reason / issue（`#NNN` 必須）を構文強制**（いずれか欠落・空は無効 = 違反扱い / 計画「Issue 必須」を充足）、(2) marker は非構造 write のみに限定（構造解釈 READ には付与不可 = READ idiom 行に marker があっても別途警告 = T-11）、(3) **stale 検出 = marker 除去で当該行が違反として再現することをテストで機械検証（T-17）**、(4) 許可 marker の既知集合（現行は status.sh の 1 件のみ）をテストで固定（T-16）。計画の「期限（expiry）」は単一インライン例外には過剰のため採用せず、stale を (3) の機械検証で代替する（差分は論理設計に明記）。
