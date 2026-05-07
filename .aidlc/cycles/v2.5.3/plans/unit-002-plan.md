# Unit 002 計画: write-history skill にモード追加（unit-complete-short-note + operations-round）

## 概要

`aidlc:write-history` skill / `skills/aidlc/scripts/write-history.sh` に 2 つの新モードを追加する。Unit 完了時の short note と Operations PR マージ前レビュー round エントリを構造的に記録できるようにし、v2.5.1 で発生した履歴漏れの再発を防ぐ。

ストーリー 2A（Unit 完了 short note）と 2B（Operations round エントリ）は同一スクリプト改修のため 1 Unit に統合（Intent DR-005）。

## 関連 Issue

- #637（履歴記録の構造改善 - Unit short note + Operations round 1 エントリ）
- 関連（実装済参考）: #616 (write-history マージ前ガード)

## Unit 001 申し送り受け入れ条件の影響

`AC-U003-RETRO-GUARD-IMMUTABLE-1〜3` / `AC-U004-RETRO-GUARD-IMMUTABLE-1〜2` は同一ファイル `04-completion.md` §1 / `retrospective-issue.sh` を編集する Unit 003 / Unit 004 への申し送り。本 Unit 002 は `write-history.sh` のみを編集するため、Unit 001 の対話必須ガードに影響しない（受け入れ条件の取り込みは不要）。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/scripts/write-history.sh` | 改修 | `--mode <unit-complete-short-note\|operations-round>` オプション追加。モード未指定時は既存動作完全互換 |
| `skills/write-history/SKILL.md` | 改修 | 引数表に新モード説明を追記（500 行制限内） |
| `skills/aidlc/scripts/lib/validate.sh` | 改修（必須） | 新モード値（mode 列挙 / round 数値 / count 数値）の検証関数を追加。既存 `validate_phase` / `validate_unit` / `validate_operations_stage` パターンとの一貫性維持（検証責務集約） |
| `tests/write-history-modes.bats`（新規） | 新規作成 | unit-complete-short-note / operations-round 両モードの単体テスト + 既存互換テスト |
| `.aidlc/cycles/v2.5.3/history/construction_unit02.md` | 新規作成 | Unit 002 の進捗履歴 |

## 実装計画

### Phase 1（設計）

設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_002_write_history_modes_domain_model.md`）: モード値・履歴エントリの種別境界（base / short_note / operations_round）を整理
- 論理設計（`design-artifacts/logical-designs/unit_002_write_history_modes_logical_design.md`）: 引数パース仕様 / テンプレ仕様 / 既存互換維持の論理設計

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施。

### Phase 2（実装）

#### 1. `skills/aidlc/scripts/write-history.sh` の `--mode` 追加

- `--mode <unit-complete-short-note|operations-round>` オプション追加（未指定時は既存動作）
- モード別の追加引数:
  - `unit-complete-short-note`: `--short-note "<3-5 行の短文>"`（必須）
  - `operations-round`: `--round R --findings F --critical C --high H --medium M --low L --resolved-count X --deferred-count Y`（全必須）
- モード別の追記処理:
  - `unit-complete-short-note`: `history/construction_unitNN.md` 末尾に固定テンプレ「## 補足（short note）」セクション + 自由記述行を追記
  - `operations-round`: `history/operations.md` に round R エントリ（指摘件数 / 重要度内訳 / 対応判定の集計テーブル）を追記
- 既存挙動完全互換: `--mode` 未指定時は既存処理に分岐
- post-merge ガード（既存）: 新モードでも有効（exit 3 維持）
- エラーハンドリング（SoT統一 / 計画レビュー Round 1 指摘 #2 + コードレビュー Round 1 指摘 #1 反映）:
  - 不正モード値 → exit 1 / `error:invalid-mode`
  - `unit-complete-short-note` を `--phase construction` 以外で指定 → exit 1 / `error:invalid-mode-phase-combination`
  - `operations-round` を `--phase operations` 以外で指定 → exit 1 / `error:invalid-mode-phase-combination`
  - `unit-complete-short-note` で `--short-note` 未指定 → exit 1 / `error:missing-short-note`
  - `operations-round` で必須引数（`--round` / `--findings` / `--critical` / `--high` / `--medium` / `--low` / `--resolved-count` / `--deferred-count`）の **いずれか欠落** → exit 1 / `error:missing-round-args`
  - `--round` が 1-5 の整数以外 / count が非負整数以外 → exit 1 / `error:invalid-numeric-arg`
  - 上記エラーコードの SoT は本セクション。テストおよび実装の期待値はすべて本表に準拠する

#### 2. テンプレ仕様（実装詳細は Phase 1 で確定）

**unit-complete-short-note テンプレ**:

```markdown
## 補足（short note）

<3-5 行の自由記述>
```

**operations-round テンプレ**（`user_stories.md` ストーリー 2B「技術的考慮事項」セクションの「Operations round エントリは『## Round R: YYYY-MM-DD HH:MM:SS』+ 指摘件数 / 重要度内訳 / 対応判定の標準集計テーブル」記述を SoT として参照 / レビュー Round 1 指摘 #3 反映、行番号参照は脆いため見出し参照に変更）:

```markdown
## Round {R}: {YYYY-MM-DD HH:MM:SS}

| 項目 | 値 |
|------|-----|
| 指摘総数 | {findings} |
| 重要度: critical | {critical} |
| 重要度: high | {high} |
| 重要度: medium | {medium} |
| 重要度: low | {low} |
| 修正対応 | {resolved-count} |
| defer 化 | {deferred-count} |
```

タイムスタンプは見出し行に埋め込み（既存 history テンプレと同様の形式）、別途「記録時刻:」行は持たない。

#### 3. SKILL.md（`skills/write-history/SKILL.md`）改修

- 引数表に新モード行追加
- 使用例セクションに 2 モードの例追加
- 500 行制限内に収める

#### 4. self-apply（本 Unit 自身の short note 記録）

Unit 002 完了直前に、新モード `--mode unit-complete-short-note` を本 Unit 自身に適用してテストフィクスチャ的に動作検証する。`--mode` 指定時も既存必須引数（`--phase` / `--cycle` / `--step` / `--content` および construction フェーズの `--unit` / `--unit-name` / `--unit-slug`）はすべて引き続き必要（レビュー Round 1 指摘 #1 反映）:

```bash
bash skills/aidlc/scripts/write-history.sh \
  --mode unit-complete-short-note \
  --cycle v2.5.3 \
  --phase construction \
  --unit 2 \
  --unit-slug write-history-modes \
  --unit-name "write-history skill にモード追加" \
  --step "Unit 002 完了 short note 自己適用" \
  --content "Unit 002 (write-history skill モード追加) 完了直前の自己適用検証" \
  --short-note "<3-5 行の本 Unit 振り返り>"
```

> **設計判断**（Phase 1 で確定済 / 設計レビュー Round 1 指摘 #2 反映）: `--mode` 指定時は **base 処理（既存）→ mode 固有の追加追記** の順で動作する。base 処理の出力（`history:<filepath>:<status>`）はそのまま維持され、その直後に mode 固有のセクション（`## 補足（short note）` / `## Round R: timestamp` + テーブル）を同ファイルへ追記する。詳細は `design-artifacts/logical-designs/unit_002_write_history_modes_logical_design.md` 参照。

これにより本 Unit が新モードのドッグフーディング検証となる（Unit 定義「self-apply」要件）。

#### 5. テスト

- `tests/write-history-modes.bats` 新規作成
  - `unit-complete-short-note` モード: 正常系 / 必須引数欠落 / construction_unitNN.md への追記内容
  - `operations-round` モード: 正常系 / round/count 非数値 / operations.md への追記内容
  - 既存互換: `--mode` 未指定時の従来挙動（exit code / 出力フォーマット / 追記位置）が破壊されない
  - post-merge ガード: 新モード時にも `--phase operations --operations-stage post-merge` で exit 3

### 実装順序

1. SKILL.md（規範）改修
2. write-history.sh の `--mode` 引数パース追加
3. モード別バリデーション + 追加引数パース
4. モード別追記処理実装
5. テスト追加（write-history-modes.bats）
6. 既存テスト（write-history 系）の回帰確認
7. AI レビュー
8. self-apply 動作確認

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 不正モード値 | exit 1 + `error:invalid-mode` |
| `unit-complete-short-note` で `--short-note` 未指定 | exit 1 + `error:missing-short-note` |
| `operations-round` で必須引数欠落 | exit 1 + `error:missing-round-args` |
| round / count が非数値 | exit 1 + `error:invalid-numeric-arg` |
| 既存呼出（`--mode` 未指定）の挙動破壊 | 完全互換維持必須（テストで保証） |
| post-merge ガードが新モードを通過 | exit 3 維持必須（テストで保証） |

## NFR

- **パフォーマンス**: O(1) のテンプレ展開 + ファイル append のみで既存性能影響なし
- **セキュリティ**: short note / round エントリに機密情報マスク対象パターンを含めない設計
- **後方互換**: `--mode` 未指定時の従来呼び出しは完全互換（exit code / 出力フォーマット / 追記位置）
- **可用性**: 影響なし

## 完了条件チェックリスト

### 実装

- [x] `skills/aidlc/scripts/write-history.sh` に `--mode <unit-complete-short-note|operations-round>` オプションが追加されている
- [x] `unit-complete-short-note` モードに `--short-note` 引数が追加されている
- [x] `operations-round` モードに必須引数（`--round` / `--findings` / `--critical` / `--high` / `--medium` / `--low` / `--resolved-count` / `--deferred-count`）が追加されている
- [x] `--mode` 未指定時は既存動作完全互換（exit code / 出力フォーマット / 追記位置）
- [x] post-merge ガード（既存）が新モードでも有効（exit 3 維持）
- [x] `unit-complete-short-note` モードが `history/construction_unitNN.md` 末尾に「## 補足（short note）」セクションを追記する
- [x] `operations-round` モードが `history/operations.md` に round R エントリ（指摘件数 / 重要度 / 対応判定）を追記する

### 規範・ドキュメント

- [x] `skills/write-history/SKILL.md` に新モード説明が追記されている
- [x] SKILL.md 全体行数が 500 行制限を超えていない

### テスト

- [x] `tests/write-history-modes.bats` が新規作成されている
- [x] 両モードの正常系テストが pass する
- [x] 不正引数時のエラーハンドリングテストが pass する
- [x] `--mode` 未指定の既存互換テストが pass する
- [x] post-merge ガードテストが新モードでも pass する
- [x] 全 BATS テストが pass する（既存テスト回帰なし）

### self-apply

- [x] Unit 002 完了直前に `--mode unit-complete-short-note` で本 Unit 自身の short note を `construction_unit02.md` に追記する（完了処理ステップで実施完了）

### 品質ゲート

- [x] markdownlint が pass する
- [x] AI レビュー（design / code / integration）が完了条件（最後 2 round 連続 clean）を満たす（design 3R / code 4R / integration 4R すべて連続 clean 達成）
- [x] Codex レビューでも追加指摘なし、または defer 化済み（全 12 件指摘 → 全件修正済み）

## 見積もり

- 設計フェーズ: 0.5 日
- 実装フェーズ: 1 日（write-history.sh 改修 + SKILL.md + 単体テスト）
- 合計: **1.5 日**
