# Inception Phase 意思決定記録 - v2.6.4

Inception Phase で行った重要な意思決定を時系列で記録する。Construction / Operations Phase での参照用。

---

## DR-001: サイクルバージョンを v2.6.4（patch）に決定

- **日時**: 2026-05-16
- **判断者**: ユーザー（明示選択）
- **背景**: 前サイクル v2.6.3 完了直後。候補は patch (v2.6.4) / minor (v2.7.0) / major (v3.0.0)
- **意思決定**: v2.6.4 (patch) を採用
- **理由**:
  - 対象 4 Issue のうち #694 / #708 / #709 はいずれも patch 相当（バグ修正・規約整備・docs・refactor・security）
  - 唯一 #710 のみ「minor リリース想定」と Issue 本文に明記されていたが、これは段階的改修の前段として patch スコープ内に収まる範囲（opt-in 基盤導入 + 後方互換確保まで）に限定する DR-002 と組み合わせて patch 採用
- **影響**: Milestone は `v2.6.4` で作成。破壊的変更は本サイクル除外
- **関連**: DR-002

---

## DR-002: #710 を patch サイクルに含める判断（minor 想定 Issue のサブセット適用）

- **日時**: 2026-05-16
- **判断者**: ユーザー（Issue 選択時の明示選択）+ Intent でサブセット適用を AI 設計
- **背景**: #710 本文「対応時期: minor リリース（v2.7.0 以降）を想定。現行ガード（対話必須トークン / cap / mirror）の動作を壊さない範囲での段階的改修が望ましい」
- **意思決定**: #710 を v2.6.4 に含めるが、対象は **opt-in 基盤の導入 + `predecessor_resolve_issue` の 5 経路後方互換確保まで** に限定。破壊的変更（自動起票完全廃止 / `Retrospective:` タイトル運用見直し / API 破壊的変更）は v2.7.0+ に明示除外
- **理由**:
  - Issue 本文の「段階的改修」記載を patch / minor の分割線として活用
  - v2.7.0+ での本格改修に向けた橋頭堡を早期に確保し、後続サイクルの設計余地を広げる
  - デフォルト動作不変を担保することで consumer プロジェクトへの影響ゼロ
- **影響**: Intent「明示的に除外するもの」セクションに対象外項目を明示記載。Construction Phase Unit 004 で「実装するが既定では未発火」の設計指針を採用
- **関連**: DR-001, DR-004

---

## DR-003: #708 の `cmd_pr_ready` 対応を条件付きに分離

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #1 への対応として明示分離）
- **背景**: #708 本文「`cmd_record_release_prep_commit`: 優先度: 中。パストラバーサル経路あり」「`cmd_pr_ready`: 優先度: 低。パス展開と直接結びついていないが下流での扱いを要確認」
- **意思決定**: 必須対応を `cmd_record_release_prep_commit` のみとし、`cmd_pr_ready` は Construction Phase で「下流の `--cycle` がパス展開に使われるかの影響範囲調査」を実施したうえで同サイクル内対応 / 別 Issue 化を判定する条件付き対応とする
- **理由**:
  - `cmd_record_release_prep_commit` はパス展開経路が明確で必須
  - `cmd_pr_ready` は下流の `pr-ops.sh get-related-issues` がパス展開に使うかが Issue 起票時点で未確定。Construction Phase の調査で根拠を確定するのが安全
- **影響**: Unit 002 の責務に「必須対応」「条件付き対応」を明示分離。調査結果は本 decisions.md に追記される予定
- **関連**: DR-004

---

## DR-004: 完了判定 SoT を「Issue 本文」から「Intent 内サブセット受入基準」に変更

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #2 への対応として明示変更）
- **背景**: 当初の Intent は「各 Issue の完了判定は対応する GitHub Issue 本文の受け入れ基準を SoT とする」と記述したが、#710 / #708 が部分対応となるため Issue 本文 SoT と「4 件すべて完了」表現が衝突
- **意思決定**: 完了判定 SoT を **「v2.6.4 範囲で本 Intent が定義したサブセット受入基準」** に変更。Issue 本文の受入基準は参考情報として扱い、本サイクルでは Intent のサブセット定義が優先される
- **理由**:
  - #710 / #708 のサブセット適用と「4 件すべて完了」の意味的整合を確保
  - Construction Phase で Unit が完了基準を判断する際の混乱を排除
  - #709 / #694 は完全充足のためサブセット適用なし（明示記載）
- **影響**: Intent「含まれるもの」「成功基準」両セクションが「サブセット受入基準」表現に統一
- **関連**: DR-002, DR-003

---

## DR-005: markdown lint 統一化の正本を `package.json` の `scripts.lint:md` に固定

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #4 への対応として明示固定）
- **背景**: #709 本文「`package.json` または `Makefile` に `lint:md` 統一エントリポイントを定義」— 選択肢の自由度が高く、Construction で揺れるリスク
- **意思決定**: **正本は `package.json` の `scripts.lint:md`** に固定。`Makefile` ラッパーは任意 / 必要時のみ追加
- **理由**:
  - npm エコシステムが既にリポジトリで使われている（既存 `npx markdownlint-cli2` 経路）
  - AI レビュー / CI / ローカル開発で同一の `npm run lint:md` コマンドが使える
  - `Makefile` 追加は consumer プロジェクトの環境多様性（make 未インストール等）にも影響するため、必須化を避ける
- **影響**: Unit 003 の責務節で `package.json` を正本と明示。`Makefile` ラッパー追加は本サイクル対象外
- **関連**: なし

---

## DR-006: AI レビュー（Intent / Stories + Units）を 1 codex セッションで連続実施

- **日時**: 2026-05-16
- **判断者**: AI 実行判断（review-flow.md「Codex セッション管理」セクション「初回後 session id を記録、2 回目以降 codex exec resume <session-id>」に基づく）
- **背景**: 本 Inception Phase は 3 ゲート（Intent 承認 / ストーリー承認 / Unit 定義承認）がある
- **意思決定**: Intent レビュー（Round 1-3）とストーリー + Unit 連続レビュー（Round 1-2）を **同一 codex セッション (id: 019e312b-3fb0-7d83-a2cf-f81a3c7d3c67)** で実施。ストーリーと Unit のレビューは 2 ゲートを 1 セッションで連続実行
- **理由**:
  - Intent の文脈を引き継ぐことでストーリー / Unit のレビュー精度が向上
  - codex セッション継続によるコンテキスト保持で重複説明を回避
  - レビューサマリは 2 ゲート分離（intent-review-summary.md / stories-units-review-summary.md）として独立性を維持
- **影響**: codex セッション id を decisions.md に記録（後続サイクルでの再現性確保）。レビューサマリ 2 ファイルが共通 session id を参照する形となる
- **関連**: なし

---

## DR-007: Unit 002 `cmd_pr_ready` を同サイクル内で必須対応化（DR-003 の結論）

- **日時**: 2026-05-17
- **判断者**: AI 設計（Unit 002 Construction Phase 計画策定時の影響範囲調査結果）
- **背景**: DR-003 で `cmd_pr_ready` の `--cycle` 対応を条件付きに分離し、Construction Phase での影響範囲調査結果に基づき同サイクル内対応 / 別 Issue 化を判定するとした
- **意思決定**: `cmd_pr_ready` も同サイクル内で必須対応化し、`validate_cycle` 検証を導入する
- **理由（調査結果）**:
  - `cmd_pr_ready` の `--cycle` は `pr-ops.sh get-related-issues "$cycle"` に渡される（`skills/aidlc/scripts/operations-release.sh` L437）
  - `pr-ops.sh` の `cmd_get_related_issues` 内で `local units_dir="${AIDLC_CYCLES}/${cycle}/story-artifacts/units"` というパス展開に使用される（`skills/aidlc/scripts/pr-ops.sh` L209）
  - したがって `cmd_pr_ready` も `cmd_record_release_prep_commit` と同種のパストラバーサル経路を持つ（Issue 起票時点の「下流での扱いを要確認」という記述が同サイクル対応の妥当性を満たす）
- **挿入位置の採用根拠**:
  - body-file 検証（`_pr_ready_validate_body_file`）直後・`resolve_cycle_from_branch` での解決直後・`get-related-issues` 呼び出し直前を採用
  - 理由: (1) body-file 検証は cycle 解決より前に位置しており既存契約を維持する、(2) `--cycle` 未指定時のブランチ解決経路もカバーする、(3) 下流のパス展開発火前で最も早い fail-fast ポイント
  - `pr-ops.sh` 側ではなく呼び出し側（`cmd_pr_ready`）で検証する責務分担を採用。`pr-ops.sh` は他スクリプト（`cycle-pr-check.sh` 等）からも呼ばれる汎用ライブラリのため中立性を保つ
- **影響**: Unit 002 の責務（必須対応 2: `cmd_pr_ready` への validate_cycle 検証導入）として実装。別 Issue 化は不要
- **関連**: DR-003

---

## 追記予定

- **Construction Phase で追加されうる DR**:
  - Unit 004: 振り返り opt-in フラグの最終命名（**DR-009 で確定**: `[rules.retrospective].auto_issue_creation`）
  - 既存ガード（対話必須トークン / cap / mirror）の挙動維持確認（**DR-010 で記録**: 既存 bats 全 pass で代替）
  - `predecessor_resolve_issue` 5 経路の挙動維持確認（**DR-009 で記録**: 既存 bats `predecessor-issue-handoff.bats` で全 5 経路網羅 pass）

---

## DR-008: `scripts.lint:md` の glob を `**/*.md` から CI と同一値に変更

- **日時**: 2026-05-17
- **判断者**: AI Agent（Construction Phase Unit 003 ビルド・テスト実行時に発見、整合性のため自主判断）
- **背景**: 当初 `package.json` の `scripts.lint:md` に `npx markdownlint-cli2 "**/*.md" "#node_modules"` を採用したが、smoke 実行で過去サイクル成果物（`.aidlc/cycles/v1.0.1/` 等）の lint 違反を多数巻き込むことが判明。本 Unit の目的「AI レビュー / CI / ローカル開発で同一の lint 結果」と矛盾。
- **意思決定**: glob を `.github/workflows/pr-check.yml` の `markdownlint-cli2-action` の `globs`（`docs/translations/**/*.md` / `prompts/**/*.md` / `*.md`）と同一値に変更
- **理由**:
  - DR-005「正本は `package.json` の `scripts.lint:md`」を満たしつつ、scope が CI と一致することで「同一の lint 結果」を担保
  - 既存 `run-markdownlint.sh` は別 scope（`.aidlc/cycles/<current>/**/*.md` 含む）を持つが、これは AI-DLC サイクル作業の局所 lint 用途であり統一エントリポイントの責務とは分離
  - 過去サイクル成果物の lint 違反は本 Unit のスコープ外（別途必要なら別 Issue）
- **影響**:
  - `npm run lint:md` は 14 ファイル lint で 0 errors を達成
  - 計画 / ドメインモデル / 論理設計の該当箇所も同 glob で同期更新
- **代替案と却下理由**:
  - 過去サイクル成果物を全 lint 対応 → スコープクリープ。本 Unit の責務外
  - `**/*.md` を採用し ignores を拡張 → ignores 配置の SoT が `.markdownlint-cli2.jsonc` に偏り、glob と ignores の二箇所 SoT 管理リスク
- **関連**: DR-005（SoT 確定）、Unit 003、Issue #709、Issue #713（将来の版固定）

---

## DR-009: Unit 004 opt-in 基盤フラグ命名・挙動・`predecessor_resolve_issue` 5 経路後方互換確認

- **日時**: 2026-05-17
- **判断者**: AI 設計（Construction Phase Unit 004 設計時に確定 / 計画レビュー Round 1 指摘反映後の最終形）
- **背景**: Unit 定義は「config フラグ名は Construction Phase 設計で確定」としていた。また 5 経路後方互換は bats か手動再現で確認する方針だった
- **意思決定**:
  1. **フラグ命名**: `[rules.retrospective].auto_issue_creation`（boolean、デフォルト `true`）
  2. **配置**: `skills/aidlc/config/defaults.toml` の `[rules.retrospective]` セクション（既存 `feedback_mode` / `feedback_max_per_cycle` と同階層）
  3. **失敗時の挙動**: `read-config.sh` exit 0=値あり / 1=キー不在（`true` fallback）/ 2+=取得失敗（warn + `true` fallback / fail-open）。診断可能性は warn ログで担保
  4. **`predecessor_resolve_issue` 5 経路の後方互換確認**: 既存 bats `tests/predecessor-issue-handoff.bats` が 5 経路すべてを網羅しているため、手動再現は実施せず bats pass で代替確認
- **理由**:
  1. 命名は既存 `rules.retrospective.*` 体系との整合性を最優先（read-config.sh の key alias 追加不要）
  2. fail-open は「集約 Issue 起票を既存通り継続」方向であり、後方互換性を最優先する v2.6.4 サイクル方針と一致
  3. 既存 bats による網羅確認は手動再現より再現性が高く、CI でも継続的に保護される
- **5 経路の bats カバレッジ（実測 / commit 7c935a5d 時点）**:

  | 経路 | `resolution_path` | カバレッジ bats |
  |------|-------------------|----------------|
  | 1 | `milestone_and_label` | P1 / P2 / P3 / P15 |
  | 1' | `label_fallback` | P18 / P15 |
  | 2 | `spool_fallback` | P3 / P7 / P19 / P20 / P15 |
  | 3 | `v2_5_0_compat` | P8 / P9 / P15 |
  | 4 | `warn_continue` | P10 / P11 / P15 |

  実行結果: `bats tests/predecessor-issue-handoff.bats` → 17/17 pass（Unit 004 commit 7c935a5d 時点の実測 / `/tmp/unit004-bats-predecessor.log` 参照）

- **影響**:
  - `skills/aidlc/config/defaults.toml` に新規キー追加
  - `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 2 末尾に opt-in 判定ブロック追加
  - `skills/aidlc-retrospective/SKILL.md` 末尾に v2.6.4 サイクル対象外項目 / v2.7.0+ defer 記載追加
  - 新規 bats `tests/retrospective/opt-in-foundation.bats` 10 件追加（OI1〜OI10）
- **関連**: DR-002, DR-010

---

## DR-010: Unit 004 既存ガード（対話必須トークン / cap 判定 / mirror 送信判断）の挙動維持確認

- **日時**: 2026-05-17
- **判断者**: AI 設計（Construction Phase Unit 004 設計・実装時に確定）
- **背景**: Unit 定義は既存ガードの挙動が破壊されていないことを「対話必須トークン / cap 判定 / mirror 送信判断」の 3 観点で確認する手順を規定していた
- **意思決定**: 3 観点すべて、既存 bats による pass で代替確認とする（commit 7c935a5d 時点）
- **確認結果**:

  | ガード | 確認手段 | 結果 |
  |--------|---------|------|
  | 対話必須トークン | `tests/retrospective-dialog-token.bats` 全 pass + `tests/retrospective-issue-create.bats` 内の dialog-required exit 4 ケース全 pass | 挙動維持 |
  | cap 判定 | `tests/retrospective-api-facade.bats` 内の `retrospective_api_check_cap` 関連ケース全 pass + `tests/retrospective-mirror/cap.bats` 全 pass | 挙動維持 |
  | mirror 送信判断 | `tests/retrospective-mirror/send.bats` / `record.bats` / `detect.bats` / `dedup.bats` 全 pass | 挙動維持 |

  実行結果総計（commit 7c935a5d 時点 / Unit 004 完了直前実測）:
  - `predecessor-issue-handoff.bats`: 17/17 pass
  - `retrospective-*.bats`（top-level 9 ファイル）: 123/123 pass
  - `retrospective/*.bats` + `retrospective-mirror/*.bats`（subdir 10 ファイル）: 63/63 pass
  - 新規 `tests/retrospective/opt-in-foundation.bats`: 10/10 pass
  - **合計 213/213 pass / 0 failure**

- **理由（手動再現を実施しない判断根拠）**:
  - 既存 bats は CI で継続実行されるため、Unit 004 改修後も継続的に保護される（再現性が高い）
  - 本 Unit の変更は §1.5 Step 2 末尾の opt-in 判定ブロック追加 + Step 3 直前のスキップ条件拡張のみで、既存ガード機構（§1.0 mode 確定 / Step 2 cap 判定 / Step 4 dialog token 検証 / Step 5 mirror 送信判断）の呼び出し経路自体に変更がない
  - opt-out 経路は Step 4 / 5 をスキップするため、本来評価される token / mirror 経路には到達せず、ガード機構の評価ロジック自体には影響しない
- **既存ガード機構と opt-out の関係（再掲）**:

  | ガード | opt-out 経路での評価 | 説明 |
  |--------|---------------------|------|
  | 対話必須トークン | スキップ | Step 4 `retrospective_api_create_issue` 未呼び出しのため token 記録 / 検証経路に到達しない |
  | cap 判定 | 評価される | Step 2 で既存通り評価。cap 超過と opt-out のいずれが先に成立しても Step 3-5 スキップに収束 |
  | mirror 送信判断 | スキップ | Step 5 未到達のため mirror 送信 AskUserQuestion は呼ばれない |

- **影響**: 本 DR は確認結果の記録のみ。コード変更は DR-009 で確定済
- **関連**: DR-009, Unit 004 Plan §既存ガードへの影響 表
