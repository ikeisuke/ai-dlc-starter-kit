# ドメインモデル: Unit 001 — 共有 frontmatter parser ライブラリ集約（T1 + T2'）

## 概要

`skills/aidlc-v3/scripts/` の work item frontmatter パース（構造抽出・スカラー抽出・配列パース・malformed guard・body 抽出）を単一の共有「安全境界」ライブラリ `lib/frontmatter.sh` に集約する。本ドメインは「work item Markdown ファイルの frontmatter を堅牢に構造解釈し、malformed を fail-closed で拒否する」責務を中央化することを目的とする。

**重要**: 本設計ではコードは書かず、構造と責務の定義のみを行う。実装は Phase 2 で行う。これは新規ドメインではなく、既存 3 consumer に重複実装されたパース責務の集約（純粋リファクタ + 規約）である。

---

## ステップ0: 事前コード読込み（v2.6.5 / #679 準拠）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/work-item-validate.sh` | 厳格 schema 検証の全パース実装（`read_scalar` token-atom / frontmatter+body 抽出 / 必須キー重複検出 / dependencies 配列検証(8) / assigned 型）を把握し、共有 API に抽出する境界を確定する |
| `skills/aidlc-v3/scripts/work-item-next.sh` | 最小抽出（`wi_scalar` / `wi_deps` fail-closed）と id がファイル名由来である点、enum 非検証の挙動を把握し、共有化で壊さない consumer 境界を確定する |
| `skills/aidlc-v3/scripts/work-item-status.sh` | status 専用パース（`has_closing_frontmatter` / `extract_frontmatter` / `read_status_value` / status 行一意性ガード / atomic write）を把握し、共有部分（抽出系）と consumer 固有部分（一意性・write 遷移）を分離する |
| `skills/aidlc-v3/scripts/tests/test-work-item-next.sh` | 既存自己完結ハーネス（`put_wi` / `assert_rc` / `assert_out` / `assert_stderr_has`）の形式を把握し、conformance test を同形式で実装する |

### (b) 設計時に意識すべき挙動（既存実装のエッジケース・制約）

- **frontmatter ブロック終端ガード**: 3 consumer すべてが先頭行 `---` + 閉じ `---` を必須とし、不在は fail-closed（exit 1）。共有化後も同一挙動を維持（codex premerge R7 P2 由来）。
- **body 抽出の `c>=2` ロジック**: `work-item-validate.sh:129-132` のみが body を抽出。本文中の水平線 `---` で打ち切らない（`c>=2` で 2 番目以降を出力）。`c==2` だと本文 `---` で欠落する既知バグを回避済み。共有 API に移す際もこの非自明ロジックを保存（codex premerge R3 P2 由来）。
- **スカラー抽出の 3 段階の厳格さ**:
  - validate `read_scalar`: token-atom（ERE 単一アトム）を引数で受け、トークン全体一致を要求。引用符なし or 両端引用符のみ許容、片側引用符・空値・余分記号は `return 1`。inline コメント・前後空白除去。
  - next `wi_scalar`: token-atom 検証なしの最小抽出。両端引用符なら剥がす。空値も返す（validate 済み前提）。
  - status `read_status_value`: `wi_scalar` 相当 + **非空ガード**（空は `return 1`）。token-atom 検証なし。
- **dependencies 配列パース**: validate(8) と next `wi_deps` は要素検証が同等（`[A-Za-z0-9]+` or 両端引用符付き / 空白区切り `[001 002]`・ハイフン結合 `[001-002]`・片側引用符を拒否）。next は dependencies 行不在 / malformed を `return 1`（fail-closed / out-of-order 実行防止 codex premerge R4/R5 P2）。validate は array 形式必須 + 実在 id 検証まで行う（実在検証は parser 責務外）。
- **必須キー一意性**: validate は 6 キー各「ちょうど 1 回」（重複は曖昧解決防止で拒否）。status は status 行「ちょうど 1 行」。これら一意性検証は consumer 固有（parser はヘルパ提供まで）。
- **id のファイル名由来**: next は frontmatter の id を読まず `${base%%-*}`（ファイル名）を使う。よって frontmatter id の malformed は next の挙動に影響しない（conformance RC マトリクスの consumer 別期待値の根拠）。
- **`set -e` の差異**: validate / next は `set -euo pipefail`、status は `set -uo pipefail`（`-e` なし）。共有ライブラリは **両環境で動作**しなければならない（関数が `return 1` を返しても caller が `|| { }` / `if !` で受ける前提を壊さない）。
- **bash 3.2 互換**: 連想配列を使わない（next は並列インデックス配列で実装）。共有ライブラリも 3.2 互換を維持。
- **出力方式**: 既存関数はすべて **stdout 返却**（`printf '%s'`）+ caller 側 `$(...)` 捕捉。result-out（`printf -v`）は使っていない。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存適合性 | 判断 |
|------|-----------|------|
| **refactor（採用）**: 既存のパース関数を `lib/frontmatter.sh` に移設・統合し、3 consumer は source して呼ぶ | 既存挙動を関数単位で抽出するため受理/拒否境界を保存しやすい。stdout 返却方式・bash 3.2 互換・fail-closed 挙動をそのまま移植可能 | **採用**。Intent の「純粋リファクタ」要件に最も適合 |
| **replace**: パーサを再設計し YAML パーサ（外部）導入 | bash のみ前提・依存追加不可・受理/拒否境界が変わるリスク大。Intent 除外（互換維持） | 却下 |
| **extend**: 共有化せず各 consumer にラッパだけ追加 | DRY 違反が残り #733 の再発防止にならない | 却下 |
| **出力方式: stdout 返却（採用） vs result-out（printf -v）** | stdout 返却は既存と同一で `$()` 捕捉が subshell のため dynamic scope shadowing が原理的に発生しない。result-out は CLAUDE.md 命名規約の遵守コストと shadowing リスクを負う | **stdout 返却を採用**。result-out を使う関数を導入する場合のみ `_local_fm_<fn>_<name>` 規約を適用 |

---

## エンティティ（Entity）

本ドメインはデータ永続化エンティティを持たない（パース処理の安全境界）。概念上の「対象」は以下。

### WorkItemFile（対象ファイル / 概念エンティティ）

- **ID**: ファイルパス（`<id>-<slug>.md`）。frontmatter の `id` ではなくファイル名 prefix が work item 識別子（next の挙動準拠）
- **属性**:
  - path: string - work item Markdown ファイルのパス
  - frontmatterBlock: FrontmatterBlock - 先頭 `---` 〜 次の `---` の領域
  - body: Body - 2 番目の `---` 以降の本文
- **振る舞い**:
  - 構造的に well-formed か（閉じ `---` の存在）を判定対象として持つ

---

## 値オブジェクト（Value Object）

### FrontmatterBlock

- **属性**: text: string - 先頭 `---` と次の `---` の間の行集合
- **不変性**: 抽出後は read-only。パース対象であり変更しない（write は status consumer の責務でファイルに対して行う）
- **等価性**: text の内容一致

### Body

- **属性**: text: string - 2 番目の `---`（frontmatter 終端）以降の全行（本文中 `---` で打ち切らない）
- **不変性**: 抽出後 read-only
- **等価性**: text の内容一致

### Scalar

- **属性**: value: string - frontmatter の 1 キーから抽出した値（inline コメント・前後空白除去）
- **抽出モード**:
  - strict（token-atom 検証あり / 片側引用符・空・余分記号を拒否 / 両端引用符を剥がす）
  - loose（検証なし最小抽出 / 両端引用符を剥がす）
  - **raw（両端引用符を剥がさない / 指摘1 反映）**: `assigned` の型判定（quoted string と bare token の区別）に必要。`fm_scalar_raw` として提供
- **等価性**: value の文字列一致（raw は引用符・括弧を含む構造を保持）

### DependencyList

- **属性**: ids: string[] - dependencies 配列から抽出した ID トークン列（空配列許容）
- **不変性**: malformed（非配列 / 壊れた要素 / 行不在）は値を生成せず拒否シグナルを返す（fail-closed）
- **等価性**: ids の順序付き一致

### RejectionDecision（拒否の決定 / 指摘3 反映）

- **属性**: rejected: bool - parser が当該入力を「構造解釈不能」と判定したか（`return 1` でシグナル）
- **責務**: parser は **`return 1`（拒否シグナル）のみ** を返し、拒否理由コード文字列は返さない。ユーザー向けエラーメッセージ文言・拒否分類・exit code は consumer が決める（既存 3 consumer の「return 1 + 各自メッセージ」方式を完全保存）
- **「拒否理由の標準化」の意味**: parser が「**どの入力を拒否するか（決定）を中央化**」すること。返り値として理由コード文字列を返すことではない（既存実装に理由コードチャネルは存在せず、stdout は値返却専用 / `set -e`・subshell で壊れる out-of-band チャネルは導入しない）
- **不変性**: 拒否の決定境界は決定的（同一入力 → 同一 rejected）

> **設計判断（指摘3）**: 当初 domain は「parser が拒否理由コードを返す」と定義したが、(1) 既存 3 consumer は理由コードを使わず `return 1` + 各自メッセージ方式、(2) logical 公開 API は stdout 値返却 + return code のみで理由コードチャネルを持たない。既存挙動保存を最優先し、**理由コード返却を設計から除外**。parser は拒否の「決定」を担い、「文言・分類」は consumer に残す。

### TokenAtom

- **属性**: pattern: string - ERE 単一アトム（例 `[A-Za-z_]` / `[^"#[:space:]]` / `[A-Za-z0-9]`）
- **用途**: strict スカラー抽出・dependencies 要素検証で「許容文字クラス」を表現

---

## 集約（Aggregate）

### FrontmatterParse（パース安全境界集約）

- **集約ルート**: FrontmatterParser（ドメインサービス）
- **含まれる要素**: FrontmatterBlock / Body / Scalar（strict/loose/raw）/ DependencyList / RejectionDecision
- **境界**: 「frontmatter の構造解釈」のみ。enum 値の妥当性・必須キー集合・依存実在性・status 遷移規則・write は集約外（consumer 責務）
- **不変条件**:
  - malformed frontmatter（閉じ `---` 不在）は必ず fail-closed で拒否する
  - 抽出は非破壊（対象ファイルを変更しない）
  - 同一入力に対し同一出力（決定的）

---

## ドメインサービス

### FrontmatterParser（= `lib/frontmatter.sh` 共有ライブラリ）

- **責務**: work item frontmatter の構造解釈を一元提供する安全境界。以下の操作を公開する（詳細シグネチャは論理設計で定義）:
  - frontmatter ブロック終端ガード（閉じ `---` の存在判定 / 公開述語）
  - frontmatter ブロック抽出（fail-closed 内包）
  - body 抽出（`c>=2` 保存 / fail-closed 内包）
  - スカラー抽出（**strict / loose / raw の 3 モード**。raw は引用符非剥離で `fm_scalar_raw` として提供 = assigned 用）
  - dependencies 配列パース（fail-closed）
  - キー出現回数カウント（一意性検証ヘルパ）
- **操作**: 上記すべて stdout 返却 + return code でシグナルし、ユーザー向け文言・exit は呼ばない（consumer 責務）
- **namespace**: 公開関数 `fm_` / private `_fm_` / 定数 `FM_`。グローバル enum 定数（`STATUS_ENUM` 等）は **持たない**（衝突回避）

### 消費側の責務（consumer 固有 / 集約外 / 集約しない）

| consumer | 集約外で保持する責務 |
|----------|---------------------|
| validate（SchemaValidator） | enum 検証（status/size/risk）/ 必須 6 キー一意性 / assigned 型 / 本文必須セクション / dependencies 実在 / expected_status |
| next（Selector） | id のファイル名由来解決 / 依存解決規則 / resume 優先 / status 候補判定（enum 非検証）|
| status（StatusTransition） | status 行一意性 / status enum 検証 / 期待現在 status 検証 / atomic write |

---

## リポジトリインターフェース

該当なし（永続化リポジトリを持たない）。ファイル I/O は consumer（特に status の atomic write）の責務。

---

## ユビキタス言語

- **frontmatter（フロントマター）**: Markdown 先頭の `---` で囲まれた YAML 様メタデータブロック
- **構造解釈（structural parse）**: frontmatter からキー値・配列・ブロック境界を抽出する処理。enum 妥当性等の「意味検証」とは区別する
- **安全境界（safety boundary）**: malformed 入力を fail-closed で拒否し、partial parse による undefined behavior を防ぐ単一の集約点
- **fail-closed**: 解釈不能な入力に対し「通す」のではなく「拒否（return 1 / exit 1）」に倒す方針
- **consumer**: 共有 parser を source して利用する個別スクリプト（validate / next / status）
- **strict / loose / raw 抽出**: token-atom 検証ありの厳格抽出 / 検証なしの最小抽出（両端引用符を剥がす）/ 引用符を剥がさない raw 抽出（quoted と bare を区別 = assigned 型判定用、`fm_scalar_raw`）
- **拒否理由標準化（rejection decision standardization）**: parser が「どの入力を拒否するか（決定）」を中央化すること。理由コード文字列の返却ではなく、`return 1` で拒否をシグナルし文言・分類は consumer に委ねる責務分離

---

## 不明点と質問（設計中に記録）

[Question] スカラー抽出の返却方式は stdout か result-out（printf -v）か？
[Answer] stdout 返却を採用。既存全関数が stdout 返却であり、`$()` 捕捉は subshell のため dynamic scope shadowing が原理的に発生しない。result-out を導入する関数がある場合のみ CLAUDE.md `_local_fm_<fn>_<name>` 命名規約を適用する。（設計判断 / 既存挙動保存を優先）

[Question] status の `read_status_value` の非空ガードは共有 API に含めるか？
[Answer] 共有スカラー抽出は loose モードで値を返し、非空ガードは status consumer 側で `[[ -n ... ]]` により行う（既存挙動の完全保存）。あるいは loose 抽出に「非空必須」オプションを設けるが、最小差分のため consumer 側ガードを基本とする。論理設計で最終確定する。

[Question] enum 検証ヘルパ（`in_list`）は共有ライブラリに移すか？
[Answer] **移さない（設計レビュー指摘5 で確定）**。`in_list` は frontmatter 構造解釈ではなく汎用メンバシップ判定であり、`fm_` namespace に入れると「parser + general util」へ責務が膨らみ false DRY の入口になる。`frontmatter.sh` は delimiter / scalar / array / key count に責務を限定し、`in_list` は各 consumer（validate / status）に現状どおり残す。enum 値リスト（`STATUS_ENUM` 等）も consumer 保持（namespace 衝突回避）。汎用 util 共有が将来必要になれば別 `lib/common.sh` で扱う（本 Unit 対象外）。

[Question] assigned の構造抽出は共有 API でどう扱うか？（設計レビュー指摘1）
[Answer] `fm_scalar`（loose）は両端引用符を剥がすため `assigned: "a b"` と `assigned: a b` を区別できず、validate の assigned 型判定（null/quoted/bare/array/map/空）を保存できない。**引用符を剥がさない raw 抽出 `fm_scalar_raw` を共有 API に追加**し、validate はこれを使う（個別 consumer に独自 sed を残さない = T1/T4 整合）。

[Question] parser は拒否理由コードを返すか？（設計レビュー指摘3）
[Answer] 返さない。既存 3 consumer は理由コードを使わず `return 1` + 各自メッセージ方式であり、stdout は値返却専用。parser は拒否の「決定」を `return 1` でシグナルし、文言・分類・exit は consumer が決める。「拒否理由の標準化」は「どの入力を拒否するかの決定の中央化」を意味する（RejectionDecision 参照）。
