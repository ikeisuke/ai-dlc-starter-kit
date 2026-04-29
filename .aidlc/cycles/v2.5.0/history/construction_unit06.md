# Construction Phase 履歴: Unit 06

## 2026-04-29T17:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 06-flood-mitigation（氾濫緩和: 重複検出 + サイクル毎上限）
- **ステップ**: 計画AIレビュー完了
- **実行内容**: 計画レビュー（reviewing-construction-plan / codex / 3 ラウンド）で指摘 5→3→0 件に収束。

- ラウンド 1（5 件 / 高 2・中 2・低 1）:
  - (高/依存関係) `_filter_dedup_and_cap` のフィルタ入力契約が classify 4 列出力では quote/title 不足
  - (高/パターン) 純粋関数とするのに Pass B が title 抽出のためファイル I/O を要する設計矛盾
  - (中/数値境界) Jaccard `*100` 整数化の丸め規則未定義で境界誤差リスク
  - (中/NFKC 依存) Python 不在時の degrade が Story 7 要件不成立を招く
  - (低/完了条件) 終了コード回帰検証項目欠落
- ラウンド 2（3 件 / 中 1・低 2）: 旧キー名（dedup_jaccard_threshold）残存 / 完了条件のテストケース番号未更新 / 影響ファイル表のテスト内訳未更新
- ラウンド 3: 指摘ゼロ

主な反映:
- §2「classify 出力 TSV の拡張」を新設し candidate 行を 4 列 → 6 列（kind/idx/state/sc/+title/+normalized_quote）拡張
- フィルタ本体 `_filter_dedup_and_cap` を「ファイル I/O 禁止 / 入出力のみ」と明記、6 ヘルパー（`_normalize_text` / `_jaccard_bigram_milli` / `_edit_distance_ratio_pct` / `_dedup_pass_a` / `_dedup_pass_b` / `_cap_filter`）に分解
- スキーマキー名を `dedup_jaccard_threshold_milli`（整数 700）/ `dedup_edit_distance_ratio_pct`（整数 30）に統一、丸め規則「切り捨て + >= / <= 比較」を明記
- NFKC 不可時方針: Python 3 必須、不在時は **fatal**（exit 2 + `error\tnfkc-unavailable\tpython3-required`）。CI（ubuntu-latest）で標準同梱を確認、iconv フォールバックは却下
- 完了条件チェックリストに「Unit 005 終了コード契約の維持」と「F4b/F5b 境界テスト」「DI6 Python 3 不在テスト」を追加

Codex Session: 019dd820-3026-7061-bee0-2b83a196c585

---
## 2026-04-29T18:00:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 06-flood-mitigation
- **ステップ**: 設計AIレビュー完了
- **実行内容**: 設計レビュー（reviewing-construction-design / codex / 3 ラウンド）で指摘 3→1→0 件に収束。

- ラウンド 1（3 件 / 中 2・低 1）:
  - (中/API) `_classify_candidates(extracted_tsv)` のIFと「title 抽出のため retrospective.md 読み込み」記述が自己矛盾
  - (中/構造) `_resolve_flood_mitigation_config()` が「環境変数 / グローバル変数経由」で IF が暗黙化
  - (低/パターン) `NormalizationService` の純粋性定義が曖昧（python3 サブプロセスありで「副作用なし」を主張）
- ラウンド 2（1 件 / 低）: モジュール一覧の `_filter_dedup_and_cap(rows, config)` 旧シグネチャ残存
- ラウンド 3: 指摘ゼロ

主な反映:
- `_classify_candidates(extracted_tsv, retrospective_path)` にシグネチャ拡張、title 抽出と _normalize_text 適用を明示
- `_resolve_flood_mitigation_config()` を「stdout 1 行 TSV 構造化出力」に変更（`config\t<max>\t<jaccard_milli>\t<edit_pct>\t<nfkc_policy>\t<cap_strategy>`）。呼び出し側で read 解析 → `_filter_dedup_and_cap(max, jaccard_milli, edit_dist_pct)` へ明示渡しに固定
- 「純粋性の定義」セクションを新設: 完全純粋（bash 整数演算 / 文字列操作のみ）vs ビジネス副作用なし（python3 / dasel / awk / ファイル読み込みあり）の 2 段階定義
- ドメインモデルの NormalizationService / FilterDedupAndCapService に純粋性レベルを明記

Codex Session: 019dd850-12a3-76b3-a052-8e625ba557a9（設計レビューは Round 1 と統合セッション）

---
## 2026-04-29T18:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 06-flood-mitigation
- **ステップ**: コードAIレビュー完了
- **実行内容**: コードレビュー（reviewing-construction-code / codex / 2 ラウンド）で指摘 4→0 件に収束。

- ラウンド 1（4 件 / 中 3・低 1）:
  - (中/API) cap-exceeded payload の区切り文字が `count:max`（コロン）で計画契約 `count;max`（セミコロン）と不一致
  - (中/テスト品質) DI5 の warn 検証が `... || true` で実質アサート無効化
  - (中/テスト品質) DI6 が手動再定義した `_check_python3` を検証していて回帰検知力なし
  - (低/security) Python サブプロセス引数を環境変数（A_ENV/B_ENV）経由で渡しており `/proc/*/environ` 露出リスク
- ラウンド 2: 指摘ゼロ

主な反映:
- `_cap_filter` の status 形式を `cap-exceeded:<count>;<max>` に修正、`_detect` 内の TSV 行出力も `mirror\tcap-exceeded\t<idx>\t<count>;<max>` に統一
- DI5: stderr を別ファイル（`${TEST_TMPDIR}/stderr.log`）に分離して `grep -q warn\tfeedback-max-per-cycle-invalid` で厳密アサート
- DI6: `awk` で `MIRROR_SCRIPT` から `_check_python3` 関数定義を一時ファイルへ抽出、`PATH=""` 環境で source 経由実行 → 本物の関数を検証
- Python サブプロセス引数渡しを stdin NUL 区切り（`printf '%s\0%s' "$a" "$b"`）に変更、`sys.stdin.buffer.read().split('\x00', 1)` で分離。`/proc/*/environ` 露出リスク解消

セキュリティ観点:
- パストラバーサル: 本 Unit は読み取り専用フィルタ層 / 新規ファイル書き込みなし
- Python サブプロセス引数: stdin NUL 区切り経由（ローカル他ユーザーへの環境変数露出を排除）
- 通信暗号化: 本 Unit は通信を行わないため N/A
- ログ・監視: ローカル CLI / 監視基盤なしのため N/A

事前ローカル検証:
- bats tests/retrospective-mirror/dedup.bats tests/retrospective-mirror/cap.bats で 17/17 PASS
- bats tests/retrospective-mirror/ で既存 24 + 新規 17 = 41/41 PASS
- bats tests/retrospective/ で 43/43 PASS（回帰なし）
- 全体: migration 36 + config-defaults 34 + aidlc-setup 17 + aidlc-migrate-prefs 32 + retrospective 43 + retrospective-mirror 41 = 203/203 PASS
- shellcheck 警告ゼロ（actionable / SC1091 / SC2016 info のみ残存）
- markdownlint エラーゼロ（.md 対象 3 ファイル）

Codex Session: 019dd850-12a3-76b3-a052-8e625ba557a9（コードレビュー Round 1 + 2）

---
## 2026-04-29T19:00:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 06-flood-mitigation
- **ステップ**: 統合AIレビュー完了
- **実行内容**: 統合レビュー（reviewing-construction-integration / codex / 3 ラウンド）で指摘 2→1→0 件に収束。

- ラウンド 1（2 件 / 中 1・低 1）:
  - (中/設計乖離) `_dedup_pass_b` の純粋性ラベルが論理設計「完全純粋」/ 実装は python3 サブプロセス呼び出し → 不整合
  - (低/設計乖離) `_filter_dedup_and_cap(rows, max, jaccard_milli, edit_dist_pct)` 4 引数表記 vs 実装 stdin + 3 引数の不一致
- ラウンド 2（1 件 / 低）: モジュール一覧 + ASCII 図の `_dedup_pass_b(rows)` / `_cap_filter(rows, max)` 旧表記残存
- ラウンド 3: 指摘ゼロ

主な反映:
- 論理設計の純粋性ラベルを実装に合わせて統一: 完全純粋 = `_dedup_pass_a` / `_cap_filter`（awk のみ）/ ビジネス副作用なし = `_dedup_pass_b` / `_filter_dedup_and_cap` / `_jaccard_bigram_milli` / `_edit_distance_ratio_pct`（python3 サブプロセスあり）
- ドメインモデル `FilterDedupAndCapService` の純粋性レベルを「完全純粋」→「ビジネス副作用なし」に修正
- 関数表 + モジュール一覧 + ASCII 図の全 IF 表記を「stdin + 引数」形式に統一（`_dedup_pass_a()` / `_dedup_pass_b(jaccard_milli, edit_dist_pct)` / `_cap_filter(max)` / `_filter_dedup_and_cap(max, jaccard_milli, edit_dist_pct)`）

事前ローカル検証:
- bats tests/retrospective-mirror/ で 41/41 PASS（変更なし / 設計文書のみ修正）
- bats 全体 203/203 PASS（回帰なし）

Codex Session: 019dd850-12a3-76b3-a052-8e625ba557a9（統合レビュー Round 1 / 2 / 3）

---
