# Unit 004 計画: helper の zsh source 互換性保証

## 概要

`skills/aidlc/scripts/lib/predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 解決が zsh interactive shell から `source` した際に `BASH_SOURCE[0]` が空となり、後続の依存 helper（`aidlc-paths.sh` 等）の source が cwd 起点で失敗する問題を修正する。同時に helper 6 ファイル（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh` / `retrospective-issue.sh`）に対して bash / zsh 両方の `source` 動作確認テストを **6 件以上** 追加し、AI エージェントが Claude Code のデフォルトシェル（zsh）から手順記述通りに source 呼び出ししても helper 群が機能することを保証する。

> **patch スコープ保護**（Inception DR-001 準拠）: 修正対象は **`predecessor-issue.sh` の 1 ファイルに限定**。他 5 ファイルは **テスト追加のみ** で構造変更しない。テスト失敗時は OUT_OF_SCOPE として次サイクル候補とし、本 Unit では fix しない。

## 関連 Issue

- **#659**（[Bug] predecessor-issue.sh の zsh source 互換性問題） — 本 Unit の主対象
- 関連: #643（v2.5.3 Unit 004 で導入した helper 分離）
- 参照: Inception DR-001（修正対象 1 ファイル限定の意思決定）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| SCRIPT_DIR 解決ロジック（必須修正対象） | zsh / bash 両対応の `__PRED_SCRIPT_DIR` 初期化 | `skills/aidlc/scripts/lib/predecessor-issue.sh`（修正） |
| zsh source 互換性検証 | 6 helper 分の bash / zsh 両 source 動作確認 | `tests/aidlc-helpers-zsh-source.bats`（**新規ファイルとして分離**。既存 `tests/aidlc-helpers-migration.bats` は移管契約テスト専用として維持し、責務（移管契約 vs zsh 互換性）の凝集度を保つ） |
| OUT_OF_SCOPE 検出時の証跡 | 同一 SCRIPT_DIR パターンを持つ `retrospective-issue.sh` のテスト失敗時の next-cycle 候補化 | バックログ Issue 起票（実装フェーズで判定） |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit04.md`（新規） |

### ドリフト防止策

- **修正対象は 1 ファイル限定**（patch スコープ保護）。`skills/aidlc/scripts/lib/predecessor-issue.sh` 以外の helper 群は構造変更しない（テスト追加のみ）
- **テスト追加は 6 件以上**（Unit 定義 NFR）。各テストは「`bash -c "source <helper>"` が exit 0」「`zsh -c "source <helper>"` が exit 0」「helper 内の `__*_SCRIPT_DIR` 変数（または同等の SCRIPT_DIR 系変数）が空でない有効パスとして解決される」の 3 観点を確認
- **shell 構文の bash/zsh 両対応**（Unit 定義技術的考慮事項）:
  - `${BASH_SOURCE[0]:-${(%):-%N}}` 形式は zsh の `(%)` パラメータ展開を含むため bash でパースエラーになる懸念がある
  - 設計フェーズで以下 2 案から 1 案を確定する:
    - **案 A**: `${BASH_SOURCE[0]:-${(%):-%N}}` 1 行併記方式 — bash でも `${(%):-%N}` の展開は遅延評価で問題ないことを検証可能なら採用
    - **案 B**: `[[ -n ${ZSH_VERSION:-} ]]` shell 判定分岐方式 — zsh 用に `(%)` 展開を別ブロックに分離し、bash と完全に独立させる
- **`retrospective-issue.sh` の同一バグ問題**: 同 helper も `${BASH_SOURCE[0]}` ベースで SCRIPT_DIR を解決しているため zsh source で同じ症状が出る可能性が高い。本 Unit では **テスト失敗を許容**し、OUT_OF_SCOPE バックログ Issue として起票する。bats テスト側では `skip "OUT_OF_SCOPE: see backlog #XXX"` 等で意図的に skip 化（バックログ Issue 番号は実装フェーズで採番）
- **失敗時ポリシーの統一**（DR-001 不変条件）: `predecessor-issue.sh` 以外の 5 helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-issue.sh`）について、**zsh source テスト失敗時の対応は「skip + OUT_OF_SCOPE バックログ Issue 起票」のみ**。当該 helper への構造変更（コード修正 / 同等 fix の横展開）は本 Unit では一切実施しない（次サイクル以降のバックログ起票を経由した別 Unit で対応）。許可対象ファイルは `predecessor-issue.sh` の 1 ファイル限定の不変条件を維持

### 修正アプローチ確定方針（設計フェーズで決定）

設計フェーズで以下を確定する:

1. **採用案の確定**（案 A / 案 B のいずれか）
   - 検証観点: bash 4+ / bash 3.2（macOS デフォルト）/ zsh 5.9（macOS デフォルト）の 3 環境で構文エラーなく動作するか
   - 後方互換: 既存 bash 呼び出し経路（`retrospective-resend.sh` 経由等）の挙動が exit code / stdout / stderr すべて維持される
2. **修正後の `__PRED_SCRIPT_DIR` 初期化コードの確定文言**（diff レベル）
3. **bats テストの fixture 構造**（6 helper 分の cwd / sourcing 起動方式）
4. **shellcheck 警告対応方針**（zsh 構文混入時の `# shellcheck disable=SC*` 抑制方針）

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/lib/predecessor-issue.sh` | 改修（1 ファイル限定） | `__PRED_SCRIPT_DIR` 初期化を zsh / bash 両対応に修正 |
| `tests/aidlc-helpers-zsh-source.bats` | 新規（移管契約テスト `tests/aidlc-helpers-migration.bats` から分離） | 6 helper 分の bash / zsh 両 source 動作確認テスト（6 件以上） |
| `.aidlc/cycles/v2.5.4/story-artifacts/units/004-helper-zsh-source-compat.md` | 改修（実装状態のみ） | 実装状態を `未着手 → 進行中 → 完了` に更新 |
| `.aidlc/cycles/v2.5.4/history/construction_unit04.md` | 新規 | Unit 004 進捗履歴 |

> 設計フェーズ成果物: `design-artifacts/domain-models/unit_004_helper_zsh_source_compat_domain_model.md` / `design-artifacts/logical-designs/unit_004_helper_zsh_source_compat_logical_design.md`

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 は通常実行する。設計成果物として以下を作成:

- **ドメインモデル** (`design-artifacts/domain-models/unit_004_helper_zsh_source_compat_domain_model.md`): ドメイン語彙（ShellRuntime / SourceResolutionStrategy / HelperCompatibilityContract / ScriptDirInitPattern / OutOfScopeDetection）を整理
- **論理設計** (`design-artifacts/logical-designs/unit_004_helper_zsh_source_compat_logical_design.md`):
  - `__PRED_SCRIPT_DIR` 初期化の修正案確定（案 A / 案 B）と採用根拠
  - 修正後コードの diff レベル
  - bats テスト fixture 構造（6 helper 分）と各テストの assertion ロジック
  - `retrospective-issue.sh` テスト失敗時の OUT_OF_SCOPE handling 手順（skip マーカー文言・バックログ Issue 起票テンプレート）
  - shellcheck 抑制が必要な行の特定

設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 初期化を確定案で修正
2. `bash -c "source predecessor-issue.sh"` / `zsh -c "source predecessor-issue.sh"` で手動動作確認
3. bats テスト 6 件以上を追加（6 helper 分）
4. bats 実行 → Self-Healing ループ（最大 `max_retry=3`）
   - `predecessor-issue.sh` テスト pass を必須条件
   - `retrospective-issue.sh` テスト失敗時はバックログ Issue を起票し、テストを `skip` 化
5. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
6. markdownlint 実行（変更対象 markdown ファイル）/ 履歴補足

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 案 A（`${(%):-%N}` 1 行併記）が bash でパースエラー | 設計フェーズで案 B（`ZSH_VERSION` 判定分岐）に切り替え |
| zsh での `__PRED_SCRIPT_DIR` 解決後も依存 helper の source が失敗 | helper 内 SCRIPT_DIR が `/some/other/path` を指していないか debug print で確認、case study に追記 |
| `retrospective-issue.sh` の zsh source テストが失敗 | OUT_OF_SCOPE 判定 → バックログ Issue 起票 → bats `skip "OUT_OF_SCOPE: see backlog #XXX"` で skip 化（実装フェーズ）。**`retrospective-issue.sh` 自体への構造変更は禁止**（DR-001） |
| `aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` のテストが失敗 | これら 4 helper は SCRIPT_DIR を持たない leaf helper のため通常は失敗しない想定。**仮に失敗しても DR-001 準拠で当該 helper への構造変更は禁止**。`skip "OUT_OF_SCOPE: see backlog #XXX"` でテストを skip 化 + バックログ Issue 起票で next-cycle 候補化のみ実施する（修正対象は `predecessor-issue.sh` の 1 ファイルに限定の不変条件を維持） |
| bats `zsh -c` 起動環境で zsh コマンドが利用不可 | macOS / Linux 両環境で zsh は標準搭載のため通常発生しない。テスト fixture で `command -v zsh` を確認し、不在時は `skip "zsh not available"` |
| shellcheck SC2154 / SC1090 等が新規発生 | 該当行に `# shellcheck disable=SC<num>` を最小限の範囲で付与し理由を明記 |
| markdownlint 失敗 | 該当ルール（MD013 line-length / MD031 等）を調整 |

## NFR

- **パフォーマンス**: SCRIPT_DIR 解決ロジック変更のみで関数実行時の性能影響なし（1 行の構文置換相当）
- **セキュリティ**: 既存の path traversal ガード等を維持。`__PRED_SCRIPT_DIR` 解決パスは必ず絶対パス化（`pwd` 経由）
- **後方互換**: bash での既存呼び出し経路（`retrospective-resend.sh` 等）は完全互換（exit code / stdout / stderr すべて維持）。bash 3.2（macOS デフォルト）でもパースエラーなく動作
- **可用性**: zsh / bash 両対応により AI エージェントの実行環境依存性が解消
- **スケーラビリティ**: 影響なし
- **macOS / Linux 互換**: macOS（zsh 5.9 系）/ Ubuntu（zsh 環境依存）両対応。`tools:cross-platform-review` 観点で確認

## 完了条件チェックリスト

### 機能要件

- [ ] `skills/aidlc/scripts/lib/predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 初期化が zsh / bash 両対応に修正されている
- [ ] `bash -c "source skills/aidlc/scripts/lib/predecessor-issue.sh"` が exit 0 を返す（cwd 任意で実行可能）
- [ ] `zsh -c "source skills/aidlc/scripts/lib/predecessor-issue.sh"` が exit 0 を返す（cwd 任意で実行可能）
- [ ] zsh 経由の source 後に `__PRED_SCRIPT_DIR` が空でない有効な絶対パスとして解決される（`/Users/.../skills/aidlc/scripts/lib` または同等）
- [ ] bash 経由の source 経路の挙動（exit code / stdout / stderr）が修正前と完全互換（手動回帰テスト pass）
- [ ] `__PRED_SCRIPT_DIR` 解決後、依存 helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）の source が成功する

### 自動テスト

- [ ] helper 6 ファイル（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh` / `retrospective-issue.sh`）に対する bats テストが **6 件以上** 追加されている
- [ ] 各テストは以下 3 観点を含む:
  - [ ] `bash -c "source <helper>"` が exit 0
  - [ ] `zsh -c "source <helper>"` が exit 0（または OUT_OF_SCOPE で `skip` 済み）
  - [ ] helper 内の SCRIPT_DIR 系変数（存在する場合）が空でない有効パス
- [ ] `predecessor-issue.sh` のテストが pass する（修正により bash / zsh 両方で exit 0 / SCRIPT_DIR 有効）
- [ ] `aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` のテストが pass する（leaf helper のため修正不要で pass する想定）
- [ ] `retrospective-issue.sh` のテストは pass、または `skip` 化されてバックログ Issue が起票されている（OUT_OF_SCOPE）
- [ ] `bats tests/aidlc-helpers-zsh-source.bats` の全 case が pass（既存 `tests/aidlc-helpers-migration.bats` は本 Unit の必須実行対象外として責務分離を維持）

### 既存ガード仕様との論理整合

- [ ] `predecessor-issue.sh` の多重 source ガード（`__AIDLC_PREDECESSOR_ISSUE_SH_LOADED=1`）への影響なし（既存ガード文字列が grep で 1 件以上）
- [ ] 既存公開関数 `predecessor_resolve_issue` のシグネチャ・出力 NDJSON フォーマット・stderr 診断フォーマットに変更なし
- [ ] `predecessor-issue.sh` 以外の 5 helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-issue.sh`）への構造変更なし（`git diff --name-only` で 1 ファイル＋テストファイル＋進捗ファイルのみ変更を確認）

### スコープ保護

- [ ] 修正対象は `skills/aidlc/scripts/lib/predecessor-issue.sh` の 1 ファイルに限定されている（DR-001 準拠）
- [ ] helper の責務分離（v2.5.3 Unit 004 の延長）への変更なし
- [ ] Inception / Construction Phase の他 helper（`feedback-mode.sh` / `validate-git.sh` 等）への zsh 互換性確認・修正なし
- [ ] ステップファイル（手順記述）の `source` コマンド表記の bash 強制（`bash -c "source ..."` への統一）への変更なし（次サイクル候補）
- [ ] `retrospective-issue.sh` テスト失敗時に同 helper への「同じ修正の適用」を行っていない（DR-001 準拠、OUT_OF_SCOPE バックログ起票で対応）

### 履歴

- [ ] `.aidlc/cycles/v2.5.4/history/construction_unit04.md` が新規作成され、変更ファイル一覧 / 採用した修正案（A / B）と根拠 / レビュー round / `retrospective-issue.sh` の OUT_OF_SCOPE 判定結果（pass / skip + バックログ Issue 番号）/ 検証結果が追記されている

### 品質ゲート

- [ ] cross-platform 互換（macOS BSD / Linux GNU 両対応）が `tools:cross-platform-review` 観点で確認されている
- [ ] markdownlint（`markdown_lint=true` 設定）が変更対象 markdown ファイル（plan / 設計成果物 / 履歴）で pass する
- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（v2.5.4 新ルール: `last_round_clean`）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み

## 見積もり

- 設計フェーズ: 0.5 日（修正アプローチ確定 / shell 判定方針 / fixture 設計）
- 実装フェーズ: 1.5 日（`predecessor-issue.sh` 修正 + bats テスト 6 件以上追加 + Self-Healing + 検証）
- 合計: **2 日**（Unit 定義の見積もりと一致）
