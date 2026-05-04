# Unit: feedback_mode 5 値拡張 + マイグレーション + 初回 wizard

## 概要

`rules.retrospective.feedback_mode` を v2.5.0 の 3 値（`silent` / `mirror` / `disabled`）から v2.5.1 の 5 値（`interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled`）へ拡張し、`aidlc-migrate` 経由の自動マイグレーション（破壊的変更の同意プロンプト付き）と初回 04-completion §1.5 直前の wizard を実装する。本 Unit は他 Unit の前提となる **基盤 Unit**。

## 含まれるユーザーストーリー

- ストーリー 2: feedback_mode 5 値拡張 + 初回 wizard + cap 適用範囲
- ストーリー 5: feedback_mode マイグレーション（破壊的動作変更の防止）

## 責務

本 Unit は **関数 / 設定値の提供のみ** に責任を持ち、`steps/operations/04-completion.md §1.5` のステップ記述は編集しない（編集主体は Unit 002 / Intent §「判断 6.5」参照）。

- `config/defaults.toml` に `rules.retrospective.feedback_mode` の 5 値 enum 制約を記載
- `read-config.sh` / `write-config.sh` の feedback_mode 取得・書き込みを 5 値対応化
- `aidlc-migrate` に旧→新写像処理を追加（同意プロンプト + 非対話 fallback + rollback 対応）
- **wizard 関数の提供**: AskUserQuestion を使った 5 値選択 + 設定保存ヘルパー関数（Unit 002 から呼び出される、04-completion §1.5 ステップ自体の改修は Unit 002 が実施）
- **feedback_mode 解決関数の提供**: 現在の config 値 + 環境（対話 / 非対話）から最終的な動作モード（`mirror_only` 等）を返す解決ロジック
- **cap 判定関数の提供**: `feedback_max_per_cycle` の mode 別適用範囲（合算 / 単独）を判定する関数（Unit 002 から呼び出される）
- 関連 BATS テスト（`tests/feedback-mode-wizard.bats`, `tests/feedback-mode-migration.bats`, `tests/feedback-cap-by-mode.bats`）

## 境界

- retrospective Issue 起票本体および `04-completion.md §1.5` ステップ記述の編集は Unit 002 が担う（本 Unit は config + wizard 関数 + マイグレーション + cap 判定関数のみ）
- LLM 下書きは Unit 003 が担う（本 Unit は wizard 結果を config に保存するまで）
- predecessor handoff Issue 検索は Unit 004 が担う

## 提供 I/F（他 Unit から呼び出される関数 / 設定値）

| I/F | 種別 | 利用 Unit | 戻り値 / 入出力 |
|-----|------|----------|----------------|
| `rules.retrospective.feedback_mode` | config キー（5 値 enum） | Unit 002, Unit 003, Unit 004 | 文字列（5 値のいずれか） |
| `feedback_mode_resolve()` | 関数 | Unit 002 | (config 値 + 環境) → 実行モード（`mirror_only` / `local_only` / `both` / `disabled`） |
| `feedback_mode_wizard()` | 関数 | Unit 002（04-completion §1.5 から呼び出し） | wizard 起動 + 設定保存 + 戻り値として実行モード |
| `feedback_cap_check(mode, current_count)` | 関数 | Unit 002 | (mode, 現在の起票数) → cap 超過判定（true/false）+ 適用範囲（合算/単独） |

## 依存関係

### 依存する Unit

- なし（基盤 Unit のため、最初に実装）

### 外部依存

- 既存 `aidlc-migrate` のマイグレーション + rollback 機能
- 既存 `scripts/read-config.sh` / `scripts/write-config.sh`
- AskUserQuestion ツール（Claude Code 環境）

## 非機能要件（NFR）

- **互換性**: v2.5.0 ユーザーが `aidlc-migrate` を実行せずに 04-completion §1.5 を実行しても破壊しない（メモリ内マッピングで no-op 互換動作）
- **安全性**: 非対話環境では常に `disabled` フォールバック（CI で意図しない Issue 起票が起きないことを保証）
- **可観測性**: BATS テストで写像表全パターンを verify

## 技術的考慮事項

- `aidlc-migrate` の rollback 機能を再利用（新規実装は不要）
- wizard は AskUserQuestion を使用、選択結果を `.aidlc/config.toml`（個人設定優先）に保存
- 設定保存後の同一 / 次サイクル以降は wizard をスキップ（`feedback_mode != interactive` を条件とする）

## 関連Issue

- #627（retrospective 自動生成の起票先選択 wizard 化）

## 実装優先度

High

## 見積もり

中規模。aidlc-migrate 改修 + wizard 実装 + cap 判定 + BATS テスト。Construction Phase で 1 イテレーション。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
