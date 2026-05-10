# Construction Phase 履歴: Unit 05

## 2026-05-11T00:25:14+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-squash-unit-ci-checks-config-driven（`squash-unit.sh` の CI 構造チェックスクリプト設定駆動化）
- **ステップ**: Unit完了
- **実行内容**: ## 概要

Unit 005「`squash-unit.sh` の CI 構造チェックスクリプト設定駆動化」を完了。v2.6.0 Unit 007 で opt-in シグナル方式にリファクタした `skills/aidlc/scripts/squash-unit.sh` の CI 構造チェック（`bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`）について、本体スクリプトに 3 種固定でハードコードされていた部分を `.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キー経由に置き換え、CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」原則準拠を実現。

## 主要な変更

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/scripts/squash-unit.sh` | `run_internal_ci_checks_or_skip()` を設定駆動に書き換え。`parse_config_array()`（list literal の厳密パース）/ `is_invalid_check_path()`（4 条件 OR バリデーション）/ `emit_aggregate_skip()`（2 行契約出力）の局所ヘルパ 3 関数を追加 |
| `.aidlc/config.toml` | `[rules.squash.internal_ci_checks]` セクション + `scripts` 配列（既存 3 種）を追加（starter kit リポジトリのみ） |
| `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` | 新規作成（28 ケース: parse_config_array 単体 9 / is_invalid_check_path 単体 6 / config-driven 統合 8 / backward-compat 1 / GATE-8 4） |
| `bin/tests/squash-unit/internal_ci_checks_optin.bats` | 削除（v2.6.0 Unit 007 由来 / 本 Unit の新仕様と挙動が互換でない / GATE-8 ケースは新規ファイルへ移植済み） |
| `.aidlc/cycles/v2.6.1/story-artifacts/units/005-*.md` | 「技術的考慮事項」を計画と同期（fallback default 不採用 / 集約 skip 統一 / config-read-error と invalid-config-format の分離追加） |

## 採用方針

- **設定不在時 = 集約 skip に統一**（CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」原則準拠 / 計画レビュー Round 1 確定）。本体スクリプトに 3 種の知識を残さない（fallback default は不採用）
- **配列パース責務の境界**: 本 Unit では `squash-unit.sh` 内に局所ヘルパ `parse_config_array()` を実装。将来 `read-config.sh` 側に `--format=lines` 等の配列安全出力モードを追加する別 Unit / 別 Issue を起票候補として明記
- **テスト配置**: `bin/tests/squash-unit/` に集約（既存配置ポリシー踏襲）。旧ファイル削除 + GATE-8 4 ケースを新規ファイルへ移植

## 設計上の決定事項

- **2 行契約（既存トークン互換）**: 集約 skip 時は `squash:info:internal-ci-checks-skipped` を 1 行目として常時出力し、reason は別行 `squash:info:internal-ci-checks-skipped:reason=<reason>` で出力。既存 grep ルールは無改修で互換、新規パーサは別行を読み足すだけ
- **reason 5 値分離**: `no-config`（設定不在）/ `config-read-error`（read-config.sh 実行系エラー）/ `invalid-config-format`（parse_config_array エラー）/ `empty-config`（空配列）/ `no-script-present`（全 entry skip 後）。可観測性確保のため設定不在と障害を別 reason に分離
- **パス正規化 4 条件 OR**: 絶対パス reject + `..` traversal reject + 許容文字外 reject + 空エントリ reject。`[A-Za-z0-9_./-]+` だけでは `..` を排除できないため、独立条件で担保
- **parse_config_array の厳密フォーマット検証**: 配列要素を `'<...>'` または `"<...>"` の繰り返しとして bash 正規表現で検証。クオート欠落・区切り不正は exit 1 を返す
- **bash パターン実装上の注意点**:
  - `[[ "$str" == *[$'\x00'-$'\x08']* ]]` の hex range は character class として動作しない（`-` のみリテラルマッチする）→ `LC_ALL=C grep -qE '[\x01-\x08\x0b\x0c\x0e-\x1f]'` を採用
  - `for elem in $body` の glob 展開を回避するため `IFS=',' read -ra arr <<< "$body"` を採用
  - bats から source 時、bootstrap.sh が export した `AIDLC_CONFIG` 等の環境変数が cwd 変更後も保持されるため、テスト内で `env -u` による隔離が必要

## レビュー結果

| レビュー種別 | ツール | round 数 | 指摘解消状況 |
|------------|-------|---------|------------|
| 計画レビュー（reviewing-construction-plan） | codex | 4 | 3 + 3 + 1 + 0 件 / unresolved 0 |
| 設計レビュー（reviewing-construction-design） | codex | 4 | 4 + 3 + 1 + 0 件 / unresolved 0 |
| コードレビュー（reviewing-construction-code） | codex | 3 | 2 + 1 + 0 件 / unresolved 0 |
| 統合レビュー（reviewing-construction-integration） | codex | 1 | 3 件（履歴・チェックリスト・状態 / 完了処理で全対応） |

## 完了条件達成証跡

- markdownlint: 4 files / 0 errors
- 本体ハードコード排除（grep）: 0 件
- 設定キー読取（read-config.sh）: 3 種返却 / exit 0
- bats: `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` 28/28 ok
- 設計と実装の整合性: ドメインモデル 5 概念 / 論理設計 4 関数すべて実装に対応
- 安定トークン契約: 既存 `squash:info:internal-ci-checks-skipped` 後方互換 + reason 別行 5 値分離

## 関連 Issue / 決定

- Issue #687 解消（squash-unit.sh の CI 構造チェックを設定駆動化、starter kit 固有知識を本体から完全排除）
- 関連 Issue: #691（汎用 CI チェックの v2.7.0 設計検討、本 Unit のスコープ外）/ read-config.sh の `--format=lines` モード追加（本 Unit 完了後に backlog 起票候補）
- 関連経緯: v2.6.0 Unit 007（opt-in シグナル方式リファクタ / 起票元）
- 関連原則: CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」

## AIレビュー完了

対象タイミング: 統合とレビュー

---
