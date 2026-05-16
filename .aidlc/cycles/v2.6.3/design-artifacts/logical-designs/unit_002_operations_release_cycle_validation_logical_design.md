# 論理設計: operations-release.sh cmd_squash_712 への --cycle バリデーション導入

## 概要

`skills/aidlc/scripts/operations-release.sh` に `lib/validate.sh` を取り込み、`cmd_squash_712`
の引数パース直後に `validate_cycle` による包括的検証を挿入する。本 Unit は既存スクリプトへの
最小侵襲な変更であり、新規コンポーネントは追加しない。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードは Phase 2（コード生成ステップ）で作成します。

## アーキテクチャパターン

既存の手続き型シェルスクリプト構成を踏襲する。`operations-release.sh` は「サブコマンド
ディスパッチ + サブコマンド関数群 + 下位ヘルパ関数群」というレイヤ構成を持ち、検証共通ロジックは
`lib/validate.sh` に外出しされている。本 Unit はこの既存レイヤ分離（サブコマンド層 → lib 層）を
そのまま利用し、`cmd_squash_712` から `validate.sh` の `validate_cycle` を呼ぶ依存を 1 本追加する。

選定理由: 既存スクリプト（`write-history.sh`）が同一の `lib/validate.sh` を source して
`validate_cycle` を利用する確立済みパターンがあり、それを踏襲することで一貫性と保守性を保つ。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── operations-release.sh        （サブコマンド層 / 本 Unit で変更）
│   ├── source lib/validate.sh   （← 本 Unit で追加する依存）
│   ├── cmd_squash_712           （← 本 Unit で validate_cycle 検証を追加）
│   └── __squash_712_check_history_clean  （既存 / インライン拒否を防御的に維持・変更なし）
└── lib/
    └── validate.sh              （lib 層 / 変更なし・再利用のみ）
        └── validate_cycle       （検証規則の SoT）
```

### コンポーネント詳細

#### operations-release.sh（サブコマンド層）

- **責務**: Operations Phase のリリース系サブコマンドのディスパッチと実行
- **依存**: 本 Unit で `lib/validate.sh` への source 依存を追加（既存は `lib/bootstrap.sh` 等を
  source していない — 現状 lib を一切 source していないため、本 Unit が初の lib source 追加）
- **公開インターフェース**: 変更なし（`cmd_squash_712` の外部から見た CLI シグネチャ・出力契約は
  不変。不正 cycle 時の新規 exit 1 経路のみ追加）

#### cmd_squash_712（サブコマンド関数）

- **責務**: ステップ 7.12.5（PR レビュー反映コミット Squash 統合）の実行。本 Unit で
  「引数パース完了直後の `--cycle` 包括検証」という責務を追加
- **依存**: `validate_cycle`（新規）/ `__squash_712_check_history_clean`（既存）/
  `__operations_release_progress_path`（既存）/ `read-config.sh`（既存）
- **公開インターフェース**: 変更なし

#### validate.sh / validate_cycle（lib 層・再利用のみ）

- **責務**: サイクル名検証規則の Single Source of Truth
- **本 Unit での変更**: なし（呼び出すのみ）

### 関数名衝突確認

`operations-release.sh` への `lib/validate.sh` source 追加にあたり、グローバル名前空間の衝突が
ないことを確認する。

- `validate.sh` 公開関数（6 個）: `emit_error` / `validate_cycle` / `validate_write_history_mode`
  / `validate_non_negative_int` / `validate_round_number` / `validate_unit_slug`
- `operations-release.sh` 既存関数: `cmd_*` / `print_help_*` / `__operations_release_*` /
  `__squash_712_*` / `require_option_value` 等（`validate_*` / `emit_error` と同名のものは無い）
- **判定**: 衝突なし（Phase 1 設計時点の調査結果）。実装時に `declare -F` ベースで再確認する
- `operations-release.sh` から実際に利用するのは `validate_cycle` のみ。source 自体は既存
  スクリプトの慣例どおりファイル全体を取り込む（`validate.sh` はファイル先頭コメントで
  「トップレベルで実行されるコードはない」と明記されており、source による副作用はない）

## スクリプトインターフェース設計

### operations-release.sh squash-712（変更対象サブコマンド）

#### 概要

PR レビュー反映コミットの Squash 統合を実行する。本 Unit で `--cycle` 引数の包括検証を追加する。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <CYCLE>` | 必須 | サイクル名。本 Unit で `validate_cycle` による包括検証を追加 |
| `--dry-run` | 任意 | 実行せず検証のみ |
| `-h` / `--help` | 任意 | ヘルプ表示 |

#### 検証挿入位置

`cmd_squash_712` 内の処理順序（変更後）:

1. 引数パースループ（`--cycle` / `--dry-run` / `-h|--help` / 不明オプション）— 既存
2. `-z "$cycle"` チェック（cycle 未指定 → `squash-712:error:cycle-required` + exit 1）— 既存
3. **`validate_cycle "$cycle"` 検証（← 本 Unit で追加）** — 不正値 → exit 1
4. Step 1: `squash_enabled` 取得 — 既存
5. `__squash_712_check_history_clean "$cycle"` — 既存（インライン拒否を防御的に維持）
6. Step 2 以降: `__operations_release_progress_path` でのパス解決 — 既存

検証は「`-z "$cycle"` チェック直後・Step 1 の前」に挿入する。これにより
`__operations_release_progress_path` / `__squash_712_check_history_clean` を含む全ての
`--cycle` 利用経路が検証後の値を参照することが保証される。

#### 成功時出力（正常 cycle）

変更なし。従来どおり Step 1 以降の処理に進み、既存の出力契約（`squash:skipped` /
`squash:done` 等）を維持する。

- 終了コード: 既存どおり（0 = success / skipped、1 = failed）
- 出力先: stdout（シグナル）/ stderr（info・error）

#### エラー時出力（不正 cycle / 本 Unit で追加）

```text
error	squash-712:invalid-cycle	<value>
```

- tab 区切り（`\t`）。既存 `__squash_712_check_history_clean` のインライン拒否時の
  出力フォーマット（`printf 'error\tsquash-712:invalid-cycle\t%s\n' "$cycle" >&2`）と完全一致
- 終了コード: `1`
- 出力先: stderr

#### 使用コマンド

```bash
# 正常系
operations-release.sh squash-712 --cycle v2.6.3

# 異常系（exit 1 + error\tsquash-712:invalid-cycle\t... を stderr に出力）
operations-release.sh squash-712 --cycle "../etc"
```

## データモデル概要

該当なし（永続データ・ファイル形式の新規定義なし）。

## 処理フロー概要

### cmd_squash_712 起動時の --cycle 検証フロー

**ステップ**:

1. 引数パースで `--cycle` の値を `cycle` 変数に格納
2. `cycle` が空 → `squash-712:error:cycle-required` を stderr 出力、exit 1（既存）
3. `validate_cycle "$cycle"` を呼ぶ（本 Unit で追加）
4. `validate_cycle` が return 1（不正）→ `error\tsquash-712:invalid-cycle\t<value>` を
   stderr 出力、exit 1
5. `validate_cycle` が return 0（正常）→ Step 1（`squash_enabled` 取得）以降の既存処理へ

**関与するコンポーネント**: `cmd_squash_712` / `validate_cycle`

## テスト設計

### テストファイル配置

新規 bats ファイル **`tests/operations-release-squash712-cycle-validation.bats`**（リポジトリ
ルートの `tests/` 配下）を追加する。

配置先の根拠: 本リポジトリには 2 系統のテストハーネスが併存する。

| ハーネス | 配置 | 形式 | 用途 |
|---------|------|------|------|
| bats | リポジトリルート `tests/` | `*.bats` | `operations-release.sh` 等のサブコマンド統合テスト。CI（`.github/workflows/migration-tests.yml`）が `bats tests/...` で実行。トリガパス `PATHS_REGEX` に `operations-release.sh` を含む |
| shell | `skills/aidlc/scripts/tests/` | `test_*.sh` | lib 層関数の単体テスト（`test_validate_cycle.sh` 等） |

本 Unit の新規 bats ファイルは前者（リポジトリルート `tests/`）に置く。既存の同系統ファイル
`tests/operations-release-squash712-dirty-history.bats` /
`tests/operations-release-squash712-integration.bats`（両者とも実在）と同じ場所であり、
CI の migration-tests workflow に自動的に乗る。

選定理由: 既存 squash712 bats 2 ファイルはそれぞれ「dirty history 検出」「squash 統合」
という別観点に閉じている。`--cycle` バリデーションは独立した観点であり、新規ファイルに分離する
ことでテストの凝集度を保つ（既存 dirty-history bats の `setup()` パターンを流用する）。

### テストケース

| # | ケース | 入力 `--cycle` | 期待 exit | 期待出力 |
|---|--------|---------------|-----------|----------|
| 1 | 正常 cycle（1 セグメント） | `v2.6.3` | 検証通過後の既存挙動 | 既存の `squash:skipped` 等（回帰なし） |
| 2 | パストラバーサル（`..` 含む） | `../etc` | 1 | stderr に `error\tsquash-712:invalid-cycle\t../etc` |
| 3 | 先頭スラッシュ | `/abs/path` | 1 | stderr に `error\tsquash-712:invalid-cycle\t/abs/path` |
| 4 | 空白を含む | `v2.6 3` | 1 | stderr に `error\tsquash-712:invalid-cycle\t...` |
| 5 | 制御文字を含む | tab を含む値 | 1 | stderr に `error\tsquash-712:invalid-cycle\t...` |
| 6 | 形式不一致（大文字等） | `V2.6.3` | 1 | stderr に `error\tsquash-712:invalid-cycle\t...` |

- ケース 1（正常系）は、検証追加によって既存挙動が壊れていないこと（回帰なし）を担保する。
  `release_prep_commit` slot 不在で `squash:skipped` 経路に入る既存 dirty-history bats と
  同様のフィクスチャ構成を用いる
- ケース 2〜6 は `validate_cycle` の代表的な拒否パターンを `cmd_squash_712` 経由で検証する。
  計画 Phase 1 で列挙された不正パターン（`..` / 先頭スラッシュ / 空白 / 制御文字）をケース
  2〜5 で網羅し、ケース 6 で形式不一致（大文字）を追加する。`validate_cycle` 単体の網羅
  テストは既存 `skills/aidlc/scripts/tests/test_validate_cycle.sh` に存在するため、本 Unit の
  テストは「`cmd_squash_712` 入口で検証が呼ばれ exit 1 + 正しいエラーフォーマットで停止する」
  という統合観点に絞る
- 制御文字（ケース 5）は bats 内で `$'\t'` 等のシェル展開を用いて `--cycle` 引数に渡す

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 引数検証 1 回追加のみで性能影響なし
- **対応策**: `validate_cycle` は文字列パターンマッチと `git check-ref-format` 1 回のみ。
  起動時 1 回の呼び出しで実行時間への影響は無視できる

### セキュリティ

- **要件**: パストラバーサル文字列による `.aidlc/cycles/<cycle>/...` 参照先逸脱の防止（本 Unit の主目的）
- **対応策**: `cmd_squash_712` 入口で `validate_cycle` を必須化し、`..` / 先頭スラッシュ /
  空白 / 制御文字 / Git ref 不正パターンを一括拒否。検証通過前に `--cycle` 値が
  パスセグメントに展開される経路を排除する。下位関数 `__squash_712_check_history_clean` の
  インライン拒否も防御的に維持し、二層防御を構成する

### スケーラビリティ

- 該当なし

### 可用性

- **要件**: 既存挙動の回帰がないこと（正常 cycle 値で従来どおり動作）
- **対応策**: 検証は「拒否時のみ exit 1」で早期 return し、正常系では既存処理フローに一切
  介入しない。テストケース 1 で回帰がないことを担保する

## 技術選定

- **言語**: Bash（既存スクリプトに準拠）
- **テストフレームワーク**: bats（既存 `tests/` 配下に準拠、`bats_require_minimum_version 1.5.0`）
- **再利用ライブラリ**: `skills/aidlc/scripts/lib/validate.sh` の `validate_cycle`

## 実装上の注意事項

- **セキュリティ**: 検証は必ず `--cycle` 利用経路（パス解決）より前に配置する。
  「`-z "$cycle"` チェック直後」が唯一の正しい挿入位置
- **保守性**: `__squash_712_check_history_clean` のインライン拒否は除去しない（二層防御の
  下位層として防御的に維持。計画「責務境界の確定方針（fixed）」と整合）
- **回帰防止**: source 追加は `operations-release.sh` 全サブコマンドに影響しうるため、
  source 追加後に既存 bats テスト群（`tests/operations-release-*.bats`）全体の pass を確認する
- **エラーフォーマット一貫性**: 新規エラー出力は既存インライン拒否と完全に同一の
  `error\tsquash-712:invalid-cycle\t<value>`（tab 区切り）を使用する
- **下位層 `return 1` の理由多義性（既知の制約・本 Unit のスコープ外）**:
  `__squash_712_check_history_clean` は invalid-cycle 拒否時も dirty 検出時も同じ `return 1` を
  返し、呼び出し元（`cmd_squash_712`）はこれを一律に stdout `squash:failed:reason=dirty_history`
  へ丸める。そのため下位層の invalid-cycle 拒否では stderr（`invalid-cycle`）と stdout
  （`reason=dirty_history`）で理由が食い違う構造的曖昧さが残る。本 Unit で入口層に
  `validate_cycle` を追加した後は、正常な実行経路で下位層の invalid-cycle 分岐へ到達する
  ことはほぼなくなる（下位層は二層防御の防御的維持）。下位関数の失敗理由を呼び出し元へ
  正確に伝播させる責務分割は本 Unit のスコープ外とし、decisions.md に「観測済みの既知制約」
  として記録する
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約）

## 不明点と質問（設計中に記録）

[Question] なし（要件・実装アプローチ・テスト方針ともに一意に確定）
[Answer] -
