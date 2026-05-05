# Unit 001 計画: feedback_mode 5 値拡張 + マイグレーション + 初回 wizard

## 概要

`rules.retrospective.feedback_mode` を v2.5.0 の 3 値（`silent` / `mirror` / `disabled`）から
v2.5.1 の 5 値（`interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled`）へ拡張する。
旧値からの自動マイグレーション（同意プロンプト + 非対話 fallback + rollback 対応）と、
Operations 04-completion §1.5 から呼び出される初回 wizard 関数、および cap 判定 / mode 解決関数を提供する。
本 Unit は他 Unit の前提となる「基盤 Unit」であり、関数 / 設定値の提供のみを責務とする。

## 関連 Issue

- #627: retrospective 自動生成の起票先選択 wizard 化（feedback_mode 拡張）

## 関連サイクル設計判断（Intent 参照）

- §「主要設計判断 1」: 起票先 wizard 実行タイミング（Operations 04-completion §1.5 直前）
- §「主要設計判断 4」: feedback_mode マイグレーション写像表（旧 silent → 新 interactive 等）
- §「主要設計判断 5」: feedback_max_per_cycle のモード別適用範囲（合算 / 単独）
- §「主要設計判断 6.5」: 04-completion §1.5 編集主体は Unit 002（本 Unit は関数 / 設定値の提供のみ）

## 変更対象ファイル

### 新規作成

- `tests/feedback-mode-wizard.bats`（wizard 起動条件・設定保存パスの検証）
- `tests/feedback-mode-migration.bats`（写像表全パターンの verify）
- `tests/feedback-cap-by-mode.bats`（mode 別の cap 適用範囲の verify）
- `skills/aidlc/scripts/feedback-mode.sh`（解決関数 / cap 判定関数 / wizard ヘルパーの shell 実装。最終的なファイル分割は設計フェーズで確定）

### 変更

- `skills/aidlc/config/defaults.toml`（feedback_mode の 5 値 enum 制約コメント / デフォルト値の更新）
- `skills/aidlc/scripts/read-config.sh`（feedback_mode 取得時の 5 値正規化 / 旧値 fallback）
- `skills/aidlc/scripts/write-config.sh`（feedback_mode 書き込み時の 5 値バリデーション）
- `skills/aidlc-migrate/scripts/migrate-apply-config.sh`（**純粋適用層に限定**: 確定済みの新値を受け取り、`.aidlc/config.toml` への書き換えのみを行う。同意プロンプト・対話制御は持たない）
- `skills/aidlc-migrate/scripts/migrate-feedback-mode.sh`（**新規 / 上位オーケストレーション層**: 旧値検出 → 同意プロンプト → 非対話 fallback → 確定値を `migrate-apply-config.sh` へ受け渡し → 失敗時の rollback 発火を担当。設計フェーズで最終的なファイル分割を確定）
- `skills/aidlc-migrate/SKILL.md`（rollback 手順 / 非対話時 fallback / 失敗時の状態遷移の説明追記）

**レイヤー責務分離**:

| レイヤー | スクリプト | 責務 |
|---------|----------|------|
| オーケストレーション（対話） | `migrate-feedback-mode.sh`（新規）/ 既存 `migrate-detect.sh` の延長 | 旧値検出・AskUserQuestion による同意取得・非対話 fallback 判定・rollback 発火条件判定 |
| 純粋適用（非対話） | `migrate-apply-config.sh` | 確定済み新値の `.aidlc/config.toml` 書き換えのみ。意思決定は持たない |
| バックアップ / rollback | 既存 `aidlc-migrate --rollback` 機能を再利用 | `.aidlc/config.toml.backup-<timestamp>` の復元 |

### 編集対象外（境界）

- `skills/aidlc/steps/operations/04-completion.md §1.5` のステップ記述（編集主体は Unit 002）
- retrospective Issue 起票本体の処理（Unit 002）
- LLM 下書きフロー（Unit 003）
- predecessor handoff Issue 検索（Unit 004）

## I/F 契約（cross-unit、設計フェーズで詳細化 / Unit 002 が依存）

各関数は引数・標準出力・終了コード・異常時フォールバックを明文化し、Unit 002 から呼び出される共有契約として固定する。詳細仕様は Phase 1 論理設計で確定するが、本計画段階で以下の骨子を確定する。

### `feedback_mode_resolve(config_value, environment)`

- 入力: `config_value`（5 値 enum 文字列。旧値が来た場合は `read-config.sh` 側で正規化済みである前提）/ `environment`（`interactive` / `non_interactive`）
- 出力: `mirror_only` / `local_only` / `both` / `disabled`（標準出力に 1 行）
- 終了コード: 0=成功 / 1=未知 config 値 / 2=異常
- 異常時フォールバック: 未知値 / `interactive` × 非対話環境 → `disabled` を出力 + stderr に警告（exit 0、保守的に「起票しない」）
- 副作用: なし（純粋関数）

### `feedback_mode_wizard()`

- 入力: なし（環境 / 既存 config を内部で参照）
- 出力: 選択された 5 値を標準出力に 1 行（`disabled` 含む）
- 終了コード: 0=成功（保存済み）/ 1=ユーザー中断 / 2=非対話環境（呼び出し側のミス）
- 異常時フォールバック: 非対話環境では呼び出し側でガード（本関数は対話前提。`feedback_mode_resolve` 経由で `disabled` 解決を行うパスとは別）
- 副作用: `.aidlc/config.toml`（個人設定優先）への保存

### `feedback_cap_check(mode, current_count)`

- 入力: `mode`（5 値 enum 文字列）/ `current_count`（整数。現在のサイクル内 起票済み数）
- 出力: `over` / `within`（標準出力 1 行）+ `scope=combined` / `scope=local` / `scope=mirror` / `scope=none`（標準出力 2 行目 or `key=value` 形式）
- 終了コード: 0=成功 / 1=未知 mode / 2=異常
- 異常時フォールバック: 未知 mode → `over` + `scope=none`（保守的に「起票させない」）+ stderr 警告（exit 1）
- 副作用: なし

> 上記は計画段階の骨子。最終的な exit code 体系・stderr フォーマット・key=value vs JSON は Phase 1 論理設計で確定する。

## マイグレーション失敗時の状態遷移

| 失敗点 | 検出箇所 | 動作 | rollback 発火 |
|--------|---------|------|--------------|
| 同意取得失敗（ユーザー拒否） | `migrate-feedback-mode.sh`（オーケストレーション層） | `disabled` を確定値として `migrate-apply-config.sh` に受け渡し（適用継続） | なし（適用は成功するため） |
| 同意取得失敗（非対話環境で要対話） | `migrate-feedback-mode.sh` | `disabled` 自動 fallback + stderr 警告（適用継続） | なし |
| 書込み失敗（`.aidlc/config.toml` 書込み中エラー） | `migrate-apply-config.sh`（純粋適用層） | exit ≥ 1 で上位に伝播 | 上位 orchestrator が既存 `aidlc-migrate --rollback` を発火し `.aidlc/config.toml.backup-<timestamp>` を復元 |
| ユーザー中断（SIGINT） | 任意のレイヤー | trap で適用中なら部分書込みを検出 | 部分書込みありなら rollback 発火、なしなら no-op で終了 |
| `mirror` → `mirror-only` 適用失敗 | `migrate-apply-config.sh` | exit ≥ 1 | 上記書込み失敗と同経路で rollback |

> rollback の発火粒度: 「`.aidlc/config.toml` 書き換え単位」。bats テストでは「書込み失敗時に rollback で元に戻ること」を verify する。

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**（`design-artifacts/domain-models/unit_001_feedback_mode_config_and_wizard_domain_model.md`）
   - `FeedbackMode` 値オブジェクト（5 値 enum）
   - `LegacyFeedbackMode` 値オブジェクト（3 値 enum）
   - `FeedbackModeMigration` 集約（旧→新写像 + 同意状態 + 非対話 fallback の状態遷移）
   - `FeedbackModeResolution` 値オブジェクト（config 値 + 環境 → 実行モード `mirror_only` / `local_only` / `both` / `disabled`）
   - `FeedbackCapDecision` 値オブジェクト（mode + 現在の起票数 → 超過判定 + 適用範囲 `合算` / `単独`）
2. **論理設計**（`design-artifacts/logical-designs/unit_001_feedback_mode_config_and_wizard_logical_design.md`）
   - 関数 I/F 仕様（`feedback_mode_resolve()` / `feedback_mode_wizard()` / `feedback_cap_check()`）
   - defaults.toml の enum 制約記述方針
   - read-config.sh / write-config.sh の 5 値対応化アルゴリズム（旧値 fallback ロジック含む）
   - aidlc-migrate の写像処理アルゴリズム（同意プロンプト + 非対話 fallback + 既存 rollback 機能再利用）
   - wizard の AskUserQuestion 呼び出しフォーマット + 設定保存先（個人設定優先）
   - BATS テストケース一覧（写像表全パターン / wizard 起動条件 / cap 適用範囲）
3. **設計レビュー**（`reviewing-construction-design` スキル / 優先ツール codex）
4. **設計承認**（semi_auto → 自動承認 or fallback）

### Phase 2: 実装

5. **コード生成**
   - defaults.toml の enum 制約コメント + デフォルト値の更新
   - read-config.sh / write-config.sh の 5 値対応化 + 旧値 fallback
   - feedback-mode.sh（解決 / cap 判定 / wizard ヘルパー関数）
   - aidlc-migrate の写像処理（同意プロンプト + 非対話 fallback + rollback 対応）
6. **コードAIレビュー**（`reviewing-construction-code` スキル / 優先ツール codex）
7. **テスト生成**（**Unit 001 のテストスコープは関数 / スクリプト単体に限定**。04-completion §1.5 経由の統合テストは Unit 002 が実装する）
   - tests/feedback-mode-wizard.bats（`feedback_mode_wizard()` 単体: 起動条件 / AskUserQuestion 引数 / 設定保存先 / 戻り値。**04-completion §1.5 ステップ自体には依存しない**）
   - tests/feedback-mode-migration.bats（写像表全パターン: silent→interactive 同意/拒否/非対話、mirror→mirror-only 無警告、disabled→disabled、未設定→interactive、rollback、書込み失敗時 rollback 復元）
   - tests/feedback-cap-by-mode.bats（`feedback_cap_check()` 単体: local-issue-only / mirror-only / local-and-mirror / interactive / disabled / 未知 mode の cap 適用範囲と出力契約）
8. **ビルド・テスト実行**（BATS / shellcheck / markdownlint。Self-Healing ループで修正）
9. **統合AIレビュー**（`reviewing-construction-integration` スキル）
10. **実装承認**（semi_auto → 自動承認 or fallback）

### 完了処理

11. 完了条件チェック / 設計・実装整合性チェック / 意思決定記録参照確認 / AIレビュー実施確認
12. Unit 定義ファイル状態を「完了」に更新
13. 履歴記録（`/write-history` で `history/construction_unit01.md`）
14. Markdownlint 実行（`markdown_lint=true`）
15. Squash（`squash_enabled=true` / `squash-unit.sh`）
16. Git コミット
17. Issue #627 ステータス更新（done）
18. コンテキストリセット提示

## 完了条件チェックリスト

Unit 定義「責務」セクション + Issue #627 受け入れ基準 + Intent §「成功基準」から抽出。

### Unit 責務由来

- [ ] `config/defaults.toml` に `rules.retrospective.feedback_mode` の 5 値 enum 制約が記載される
- [ ] `read-config.sh` / `write-config.sh` が feedback_mode を 5 値で取得・書き込みできる
- [ ] `aidlc-migrate` に旧→新写像処理が追加され、同意プロンプト + 非対話 fallback + rollback に対応する
- [ ] wizard 関数（`feedback_mode_wizard()`）が AskUserQuestion を使った 5 値選択 + 設定保存ヘルパーとして提供される
- [ ] feedback_mode 解決関数（`feedback_mode_resolve()`）が config 値 + 環境から実行モード（`mirror_only` / `local_only` / `both` / `disabled`）を返す
- [ ] cap 判定関数（`feedback_cap_check(mode, current_count)`）が cap 超過判定 + 適用範囲（合算 / 単独）を返す

### Issue #627 受け入れ基準由来（Unit 001 範囲）

- [ ] feedback_mode の 5 値（interactive / local-issue-only / mirror-only / local-and-mirror / disabled）が選択可能
- [ ] 旧 silent / mirror / disabled が後方互換で動作する（read-config.sh の正規化 + aidlc-migrate の写像処理）
- [ ] wizard 後の選択結果が `.aidlc/config.toml`（個人設定優先）に保存できる

### Intent 成功基準由来（Unit 001 範囲）

- [ ] `scripts/read-config.sh rules.retrospective.feedback_mode` で 5 値のいずれかが取得でき、`config/defaults.toml` に enum 制約が記載される
- [ ] BATS テスト `tests/feedback-mode-wizard.bats` で wizard 起動条件と設定保存パスを検証
- [ ] BATS テスト `tests/feedback-mode-migration.bats` で写像表全パターンを verify（silent→interactive 同意/拒否/非対話、mirror→mirror-only 無警告、disabled→disabled、未設定→interactive、rollback）
- [ ] BATS テスト `tests/feedback-cap-by-mode.bats` で mode 別の cap 適用範囲を verify
- [ ] aidlc-setup または aidlc-migrate 実行時に旧値→新値の自動マッピングが実行され、失敗時は警告 + no-op 動作 + ロールバック手順がドキュメント化される

### NFR 由来

- [ ] 互換性: v2.5.0 ユーザーが aidlc-migrate を実行せずに 04-completion §1.5 を実行しても破壊しない（メモリ内マッピングで no-op 互換動作）
- [ ] 安全性: 非対話環境では常に `disabled` フォールバック（CI で意図しない Issue 起票が起きない）
- [ ] 可観測性: BATS テストで写像表全パターンを verify

### 境界・責務由来

- [ ] `git diff` で `skills/aidlc/steps/operations/04-completion.md` の §1.5 ステップ記述に変更が含まれていない（編集主体は Unit 002。Unit 001 は関数 / 設定値の提供のみ）
- [ ] `migrate-apply-config.sh` に対話制御コード（AskUserQuestion 呼び出し / read 等）が含まれていない（純粋適用層に限定。同意取得は `migrate-feedback-mode.sh` 等の上位層が担う）
- [ ] Unit 001 BATS テストが 04-completion §1.5 の実ステップ呼び出しに依存していない（依存逆転回避。統合テストは Unit 002 範囲）

## 出力先（参考）

- 設計: `.aidlc/cycles/v2.5.1/design-artifacts/domain-models/unit_001_feedback_mode_config_and_wizard_domain_model.md` / `.aidlc/cycles/v2.5.1/design-artifacts/logical-designs/unit_001_feedback_mode_config_and_wizard_logical_design.md`
- 履歴: `.aidlc/cycles/v2.5.1/history/construction_unit01.md`
- 実装記録: `.aidlc/cycles/v2.5.1/construction/units/unit_001_feedback_mode_config_and_wizard.md`（テンプレ `implementation_record_template.md`）
