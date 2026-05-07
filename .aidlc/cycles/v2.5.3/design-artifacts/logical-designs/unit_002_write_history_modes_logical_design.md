# 論理設計: Unit 002 write-history skill にモード追加

## 概要

`write-history.sh` への `--mode` オプション追加。base 処理（既存）+ mode 固有追加処理の合成パターンで実装する。

## アーキテクチャパターン

**Decorator パターン的合成**: 既存 base 追記処理を維持し、mode 固有の追加追記を後段で実行する。`--mode` 未指定時は base のみ（完全互換）。

## コンポーネント構成

```text
write-history.sh
├── 引数パース
│   ├── 既存引数（--cycle / --phase / --unit / --step / --content / --artifacts / --operations-stage）
│   ├── --mode <base|unit-complete-short-note|operations-round>（新規 / デフォルト base）
│   ├── --short-note <text>（mode=unit-complete-short-note 時必須）
│   └── --round / --findings / --critical / --high / --medium / --low / --resolved-count / --deferred-count（mode=operations-round 時すべて必須）
├── 検証（validate.sh）
│   ├── 既存（validate_phase / validate_unit / validate_cycle / validate_operations_stage）
│   ├── validate_write_history_mode（新規 / 列挙値検証）
│   └── validate_non_negative_int（新規 / round / count 等の数値検証）
├── post-merge ガード（既存、不変）
│   └── 新モードでも exit 3 維持
├── base 処理（既存、不変）
│   └── 既存 format_entry → ファイル追記
└── mode 固有追加処理（新規）
    ├── unit-complete-short-note
    │   └── 既存 base エントリ追記後、「## 補足（short note）」セクション + 自由記述行を追記
    └── operations-round
        └── 既存 base エントリ追記後、「## Round {R}: {timestamp}」見出し + 集計テーブルを追記
```

## インターフェース設計

### 新規引数

| 引数 | 必須/任意 | 値域 | mode 必須条件 |
|------|----------|------|--------------|
| `--mode` | 任意（デフォルト `base`） | `base` / `unit-complete-short-note` / `operations-round` | - |
| `--short-note` | 条件付き必須 | 任意の文字列（複数行可） | `--mode unit-complete-short-note` 時 |
| `--round` | 条件付き必須 | 1-5 の整数 | `--mode operations-round` 時 |
| `--findings` | 条件付き必須 | 非負整数 | `--mode operations-round` 時 |
| `--critical` / `--high` / `--medium` / `--low` | 条件付き必須 | 各非負整数 | `--mode operations-round` 時 |
| `--resolved-count` / `--deferred-count` | 条件付き必須 | 各非負整数 | `--mode operations-round` 時 |

### エラーコード（計画ファイル SoT 準拠）

| エラーコード | 条件 | exit code |
|-------------|------|-----------|
| `error:invalid-mode` | `--mode` の値が列挙値以外 | 1 |
| `error:invalid-mode-phase-combination` | `unit-complete-short-note` × `operations` または `operations-round` × `construction` の組み合わせ | 1 |
| `error:missing-short-note` | `--mode unit-complete-short-note` で `--short-note` 欠落 | 1 |
| `error:missing-round-args` | `--mode operations-round` で必須引数のいずれか欠落 | 1 |
| `error:invalid-numeric-arg` | `--round` が 1-5 の整数以外 / count が非負整数以外 | 1 |

### 出力フォーマット

base 処理は既存と同じ（`history:<filepath>:<created|appended>`）。mode 固有処理を伴う場合も同じ stdout を返す（mode 固有の追記成功は base 成功と同等扱い）。

## 処理フロー

### unit-complete-short-note モード処理

1. 引数パース: `--mode unit-complete-short-note` + `--short-note "..."` を受理
2. 検証: 既存検証 + `validate_write_history_mode` + `--short-note` 必須確認
3. post-merge ガード（既存）: 通過必須
4. base 処理（既存）: `history/construction_unitNN.md` への通常追記
5. mode 固有追加: 同ファイル末尾に以下を追記
   ```markdown

   ## 補足（short note）

   <short_note 値>
   ```
6. 出力: `history:<filepath>:<created|appended>`

### operations-round モード処理

1. 引数パース: `--mode operations-round` + 9 個の必須数値引数
2. 検証: 既存検証 + mode + 数値非負検証
3. post-merge ガード: 通過必須
4. base 処理: `history/operations.md` への通常追記
5. mode 固有追加: 同ファイル末尾に以下を追記
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
6. 出力: `history:<filepath>:<created|appended>`

## NFR への対応

- **後方互換**: `--mode` 未指定 / `--mode base` は完全互換（既存処理のみ）
- **post-merge ガード**: 全モードで exit 3 維持（既存挙動保持）
- **パフォーマンス**: O(1) のテンプレ展開 + ファイル append のみ
- **セキュリティ**: short note / round エントリに機密情報マスク対象を含めない（運用ルール）

## 実装上の注意

- `--mode` の引数パース順序は他オプションと同等（`while/case` ブロック内追加）
- 本 Unit で**新規追加する**検証関数（`validate_write_history_mode` / `validate_non_negative_int`）は `validate.sh` に置く。既存のローカル定義（`validate_phase` / `validate_unit` / `validate_operations_stage`）の移管は本 Unit のスコープ外（次サイクル候補）。本 Unit は新規追加のみが「`validate.sh` への配置」原則の適用対象（設計レビュー Round 1 指摘 #1 反映）
- 既存テスト（`tests/post-merge-guard*.bats` 等）の post-merge ガードテストは新モードでも回帰確認

## 不明点と質問

[Question] short note の改行保持

[Answer] `--short-note "line1\nline2\nline3"` のようにエスケープ済み改行を渡す運用ではなく、bash の `$'...\n...'` 形式または heredoc で実引数を渡す。テンプレ展開時は `printf '%s\n'` で literal 出力（バックスラッシュ展開なし）。複数行の場合は呼び出し側が `\n` を実改行に変換した文字列を渡す。

[Question] operations.md ファイルが未存在の場合の動作

[Answer] 既存 base 処理が新規ファイル作成（`is_new_file` 分岐）に対応済みのため、mode 固有処理もそのフローに乗る。新規ファイル作成 → ヘッダー追加 → base エントリ追加 → mode 固有追加の順で実行。
