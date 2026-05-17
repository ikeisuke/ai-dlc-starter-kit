# 論理設計: Unit 004 - 振り返り opt-in 基盤導入

## 概要

`aidlc-retrospective` スキルの集約 Issue 起票フローに、`auto_issue_creation` opt-in 基盤フラグを最小差分で導入し、既存の `feedback_mode` 5 値 enum / cap 判定 / 対話必須トークン機構を破壊せず後方互換を担保する論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードは Phase 2 で作成します。

## アーキテクチャパターン

- **採用パターン**: 既存「設定 → 手順書 → 公開 API → 内部実装」の 4 層レイヤードアーキテクチャを維持。本 Unit は新規コンポーネントを追加せず、各層に最小差分のみを挿入する
- **選定理由**:
  - 既存構造は v2.5.0 〜 v2.6.3 で安定運用されており、最小差分が後方互換確保に直結する
  - opt-in 基盤フラグは「設定値の読み取り + 手順書での条件分岐」のみで実現可能であり、新規モジュール追加は不要
  - 公開 API（`retrospective_api_*`）と内部実装（`retrospective-issue.sh` / `predecessor-issue.sh` 等）の契約には触らないため、依存方向の変更も発生しない

## コンポーネント構成

### レイヤー / モジュール構成

```text
config 層
└── skills/aidlc/config/defaults.toml
    └── [rules.retrospective]
        ├── feedback_mode               (既存)
        ├── feedback_max_per_cycle      (既存)
        └── auto_issue_creation         (新規 / v2.6.4 / #710)

手順書層
└── skills/aidlc-retrospective/steps/retrospective.md
    ├── §1.0 mode 確定                  (既存 / 変更なし)
    ├── §1.5 Step 1: mode 復元           (既存 / 変更なし)
    ├── §1.5 Step 2: cap + prefill      (既存末尾に opt-in 判定ブロック追加)
    ├── §1.5 Step 3: 本文構築            (スキップ条件文言のみ拡張)
    ├── §1.5 Step 4: Issue 起票          (既存 / 変更なし)
    └── §1.5 Step 5: update フック       (既存 / 変更なし)

末尾 docs
└── skills/aidlc-retrospective/SKILL.md または steps/retrospective.md 末尾
    └── v2.6.4 サイクル対象外項目 / v2.7.0+ defer 記載  (新規 5〜10 行)

公開 API 層（既存 / 変更なし）
└── skills/aidlc/scripts/lib/retrospective-api.sh
    ├── retrospective_api_check_cap
    ├── retrospective_api_create_issue
    └── ...

内部実装層（既存 / 変更なし）
└── skills/aidlc/scripts/lib/
    ├── retrospective-issue.sh
    ├── feedback-mode.sh
    └── predecessor-issue.sh         (後方互換保護対象)

テスト層
└── tests/
    ├── predecessor-issue-handoff.bats        (既存 / 実行のみ)
    ├── retrospective-*.bats                  (既存 / 実行のみ)
    └── retrospective/opt-in-foundation.bats  (新規 / Phase 2 で追加)
```

### コンポーネント詳細

#### defaults.toml `[rules.retrospective].auto_issue_creation`（新規キー）

- **責務**: 振り返り集約 Issue 起票の opt-in 基盤フラグの SoT 値を提供する
- **依存**: なし（読み取り側 = retrospective.md / read-config.sh）
- **公開インターフェース**:
  - キー名: `rules.retrospective.auto_issue_creation`
  - 型: Boolean
  - デフォルト値: `true`
  - 取得経路: `scripts/read-config.sh rules.retrospective.auto_issue_creation`

#### retrospective.md §1.5 Step 2 末尾の opt-in 判定ブロック（新規）

- **責務**: `auto_issue_creation` フラグを読み取り、`/tmp/aidlc-opt-out.txt` に opt-out シグナルを出力する
- **依存**: `scripts/read-config.sh`（read 経路）/ Step 3 直前のスキップ判定文（書き経路）
- **公開インターフェース**:
  - 入力: `scripts/read-config.sh rules.retrospective.auto_issue_creation` の終了コードと stdout
  - 出力: `/tmp/aidlc-opt-out.txt`（非空 = opt-out 成立 / 空 = opt-out 未成立）
  - 副作用: 取得失敗時 warn 出力（stderr）

#### retrospective.md §1.5 Step 3 直前のスキップ判定文（既存修正）

- **責務**: cap 超過と opt-out のいずれかが成立した場合、Step 3/4/5 をスキップする条件文を提供する
- **依存**: `/tmp/aidlc-over.txt`（既存 / cap 超過シグナル）/ `/tmp/aidlc-opt-out.txt`（新規 / opt-out シグナル）
- **インターフェース**: 自然言語の手順記述文（実装はメインフロー内 if 文相当）

#### v2.6.4 対象外項目 defer 記載（新規）

- **責務**: v2.6.4 で対応した範囲と v2.7.0+ で対応予定の項目を明示し、本サイクルが「段階的改修の前段」であることを SoT 化する
- **配置候補**: `skills/aidlc-retrospective/SKILL.md` 末尾 または `skills/aidlc-retrospective/steps/retrospective.md` 末尾
- **配置選定基準**:
  - SKILL.md 末尾: スキル説明の対象範囲明示として自然 / SKILL.md 行数 500 行制限内に収まること
  - steps/retrospective.md 末尾: 実行手順との接続が良い / SKILL.md 行数制限を考慮しなくてよい
  - **Phase 2 で実測判断**: SKILL.md 改訂後の行数が制限を超えないなら SKILL.md 末尾、超えるなら steps/retrospective.md 末尾

#### 新規 bats テスト `tests/retrospective/opt-in-foundation.bats`

- **責務**: `auto_issue_creation=true/false` 双方の経路で集約 Issue 起票が期待通り実行 / スキップされることを自動検証する
- **依存**: 既存 `tests/retrospective/helpers/setup.bash`（環境セットアップ）
- **テストシナリオ**:
  - シナリオ 1: `auto_issue_creation` 未設定 → defaults.toml の `true` が適用 → 既存動作（起票）
  - シナリオ 2: `auto_issue_creation=true` 明示 → 既存動作（起票）
  - シナリオ 3: `auto_issue_creation=false` → opt-out シグナル成立 / Step 3-5 スキップ判定が真
  - シナリオ 4: `auto_issue_creation` の不正値（例: `"yes"`, `"1"`）→ `true` 既定にフォールバック（fail-open）+ warn
  - シナリオ 5: `feedback_mode=disabled` + `auto_issue_creation=false` → §1.0 で先に exit 0（opt-in 判定に到達しない）

## インターフェース設計

### スクリプトインターフェース設計

本 Unit では新規スクリプトを作成しない。ただし以下の既存スクリプトインターフェースの呼び出し契約を明示する。

#### `scripts/read-config.sh rules.retrospective.auto_issue_creation`（既存スクリプト / 新規呼び出し用途）

##### 概要

`auto_issue_creation` フラグの取得を 4 階層マージ後の値で実施する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `rules.retrospective.auto_issue_creation` | 必須（positional） | 取得対象キー名 |

##### 成功時出力

```text
true
```

または

```text
false
```

- 終了コード: `0`
- 出力先: stdout

##### キー不在時出力

```text
（空文字）
```

- 終了コード: `1`
- 出力先: stdout / stderr に診断情報なし
- **defaults.toml に値が存在する前提下では通常発生しない**（保険として扱う）

##### 取得失敗時出力

```text
（エラーメッセージは stderr へ）
```

- 終了コード: `2` 以上
- 出力先: stderr

##### 呼び出しパターン（手順書側）

呼び出し側 retrospective.md §1.5 Step 2 末尾で以下の契約に従い `auto_issue` 変数を確定:

| read-config.sh exit code | 解釈 | 確定後の `auto_issue` 値 | 副作用 |
|--------------------------|------|-------------------------|---------|
| 0 | 値あり | stdout の値（`true` / `false`） | なし |
| 1 | キー不在 | `true`（保険 fallback） | なし |
| 2+ | 取得失敗 | `true`（fail-open） | warn 出力（stderr） |

## データモデル概要

### TOML 設定値

#### `[rules.retrospective].auto_issue_creation`（新規）

- **型**: Boolean
- **デフォルト**: `true`
- **配置**: `skills/aidlc/config/defaults.toml` の `[rules.retrospective]` セクション
- **上書き経路**: 4 階層マージ（project-local / project-shared / user-global / defaults）
- **値域**:
  - `true`: 既存動作（§1.5 Step 3/4/5 を実行して集約 Issue を起票）
  - `false`: opt-out 経路（§1.5 Step 3/4/5 をスキップ）
  - その他（不正値）: `true` で fallback + warn

### 一時ファイル（`/tmp` 配下）

#### `/tmp/aidlc-auto-issue.txt`（新規）

- **形式**: テキスト 1 行（`true` / `false`）
- **生成**: §1.5 Step 2 末尾の opt-in 判定ブロック
- **寿命**: 振り返り 1 回の実行内

#### `/tmp/aidlc-auto-issue.err`（新規）

- **形式**: stderr ログ（取得失敗時のみ非空）
- **生成**: 同上
- **寿命**: 同上

#### `/tmp/aidlc-opt-out.txt`（新規）

- **形式**: テキスト（非空 = opt-out 成立 / 空 = opt-out 未成立）
- **生成**: §1.5 Step 2 末尾の opt-in 判定ブロック
- **寿命**: 同上

## 処理フロー概要

### ユースケース 1: `auto_issue_creation=true`（デフォルト / 既存動作）

**ステップ**:

1. §1.0 で `feedback_mode` が `disabled` 以外として確定
2. §1.5 Step 1: mode 復元
3. §1.5 Step 2: cap 判定 / prefill 実行
4. §1.5 Step 2 末尾（新規）: `read-config.sh auto_issue_creation` → stdout = `true` → `/tmp/aidlc-opt-out.txt` は空のまま
5. §1.5 Step 3 直前: スキップ条件「cap 超過 OR opt-out」を評価 → いずれも非成立 → Step 3 へ進む
6. §1.5 Step 3-5: 本文構築 / Issue 起票 / update フック実行（既存動作）

**関与するコンポーネント**: defaults.toml / read-config.sh / retrospective.md / retrospective_api_*

### ユースケース 2: `auto_issue_creation=false`（opt-out 経路）

**ステップ**:

1. §1.0 で `feedback_mode` が `disabled` 以外として確定
2. §1.5 Step 1: mode 復元
3. §1.5 Step 2: cap 判定 / prefill 実行（既存通り。cap 超過なしを想定）
4. §1.5 Step 2 末尾（新規）: `read-config.sh auto_issue_creation` → stdout = `false` → `/tmp/aidlc-opt-out.txt` に `opt-out=true` を書く
5. §1.5 Step 3 直前: スキップ条件「cap 超過 OR opt-out」を評価 → opt-out 成立 → Step 3/4/5 をすべてスキップ
6. ユーザー向けに「集約 Issue 起票をスキップしました（auto_issue_creation=false / v2.6.4 / #710 opt-in 基盤）。KPT は振り返りローカル記録として保持されます」を info 表示
7. §1.6 次サイクル Intent への反映へ進む（既存通り）

**関与するコンポーネント**: defaults.toml / read-config.sh / retrospective.md

### ユースケース 3: `feedback_mode=disabled` + `auto_issue_creation=false`（優先順位検証）

**ステップ**:

1. §1.0 で `feedback_mode == "disabled"` を確定 → exit 0（以降ステップ未実行）
2. `auto_issue_creation` フラグ判定には**到達しない**

**関与するコンポーネント**: feedback-mode.sh / retrospective.md §1.0

## 非機能要件（NFR）への対応

### 後方互換性

- **要件**: 既存 consumer プロジェクトで `config.toml` を変更しないユーザーは挙動変化を体験しない
- **対応策**:
  - defaults.toml に `auto_issue_creation = true` を明示し、4 階層マージで既定値として確定する
  - `predecessor_resolve_issue` の 5 経路の `resolution_path` 出力契約を変更しない（手動再現 + bats で検証）
  - 既存 `retrospective_api_*` のシグネチャを変更しない

### 段階的改修

- **要件**: 本サイクルでは挙動を変えず、フラグ追加のみで v2.7.0+ への橋頭堡を確保
- **対応策**: 「実装するが既定では未発火」とする。`false` 経路の実装はあるが、デフォルト値 `true` のため明示設定したユーザーのみが体験する

### 診断可能性

- **要件**: 設定取得失敗を silent に隠さない
- **対応策**: `read-config.sh` exit 2+ で warn 出力 + 既定値 fallback（fail-open）

### セキュリティ

- **要件**: 本 Unit は config 値読み取り + 手順書改訂のみで、外部入力は config.toml に閉じる
- **対応策**: 既存 `read-config.sh` の入力検証に委ねる。本 Unit で新規セキュリティ表面は導入しない

## 技術選定

- **言語**: bash 5（既存スクリプト群と同等）
- **設定形式**: TOML（既存 defaults.toml と同形式）
- **テストフレームワーク**: bats-core（既存 `tests/` 配下と同等）
- **設定取得 CLI**: `dasel` v3（既存 read-config.sh が ABI を吸収）

## 実装上の注意事項

- **AI エージェント Bash ツール経由の安全パターン**: コマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（CLAUDE.md SoT 参照）。本 Unit では `read-config.sh` 呼び出しを `set +e ... rc=$? ... set -e` で囲み、結果を一時ファイル経由で取り出す形を採用する
- **printf -v 系 result-out 関数の local 命名規約**: 本 Unit では新規導入なし（手順書改訂と config キー追加のみ）。万一スクリプト追加が発生する場合は v2.6.3 で追加された namespace 規約（`_local_<関数省略名>_<名>`）に従う
- **ドッグフーディング特殊処理の禁止**: starter kit 自身か consumer かを判定する分岐を追加しない。`auto_issue_creation` フラグは config の値で自然に opt-in 判定される
- **SKILL.md 行数制限**: SKILL.md 末尾への defer 記載は 5〜10 行に収め、500 行制限内を維持する。超える場合は steps/retrospective.md 末尾に配置
- **`mode=disabled` との混同回避**: 計画ファイル §retrospective.md 改訂方針 §実行順序の優先関係 で明示済。テストでも優先順位検証シナリオ（ユースケース 3）を必ず含める

## 不明点と質問（設計中に記録）

[Question] 新規 bats `tests/retrospective/opt-in-foundation.bats` を配置するディレクトリは `tests/retrospective/` 配下でよいか（既存命名規約に従う）
[Answer] よい。既存 `tests/retrospective/` に `feedback-mode-resolution.bats` / `template-structure.bats` / `schema-contract.bats` 等が配置されており、サブディレクトリ規約と一致する

[Question] defer 記載の配置先（SKILL.md 末尾 vs steps/retrospective.md 末尾）はどう決定するか
[Answer] Phase 2 のコード生成段階で SKILL.md 改訂後の行数を実測し、500 行制限内に収まれば SKILL.md 末尾、超えるなら steps/retrospective.md 末尾とする。本論理設計では両者を許容範囲として明示する
