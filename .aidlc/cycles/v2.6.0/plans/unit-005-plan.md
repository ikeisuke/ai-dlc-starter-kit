# Unit 005 計画: /aidlc-retrospective 独立スキル化（破壊的変更）

## Unit 概要

`skills/aidlc-retrospective/` を新設し、`steps/operations/04-completion.md` §1 の振り返りロジック（feedback_mode 解決 / wizard / cap / 本文構築 / Issue 起票 / spool / mirror_state ラベル化 / dialog token ガード）を全量移転する。`/aidlc` parser に `retrospective`（短縮: `r`）アクションを追加し、`setup` / `migrate` / `feedback` 同様に独立スキルへ委譲する。Operations 完了メッセージで `/aidlc i` と同列に `/aidlc r` を案内する。

- 関連 Issue: #667
- 依存 Unit: なし（単独実装可能）
- 見積もり: 8〜12 時間
- 破壊的変更: v2.6.0 で Operations 内の振り返り起動を完全廃止

## 依存関係

- **依存元**: なし（Unit 003 / 004 完了済だが直接の受け渡し契約なし）
- **被依存**: Unit 006（GitHub Projects 移行）には影響しない

## Phase 1 意思決定ゲート（完了条件の前提）

| ゲート | 論点 | 採用案（候補） |
|------|------|-------------|
| GATE-1 | スキル骨格構成 | `aidlc-feedback` を手本に `skills/aidlc-retrospective/{SKILL.md,steps/}` を最小構成で作成。Bootstrap 経路（`source skills/aidlc/scripts/lib/bootstrap.sh`）も `aidlc-feedback` の流儀に揃える |
| GATE-2 | 共有ライブラリ参照方針 | **採用案: 既存 `skills/aidlc/scripts/lib/*.sh` を単方向で `source` するが、利用可能関数を「公開 API」として明文化する**。新規ファイル `skills/aidlc/scripts/lib/retrospective-api.sh`（再エクスポート層 / 既存 `lib/*.sh` を内部 source）を導入し、`aidlc-retrospective` は本ファイルのみを `source` する。公開 API リスト・戻り値・exit code 契約を Phase 1 論理設計で固定し、非公開関数への依存を禁止する（指摘 #2 反映）。コピー方式（第二案）は重複分岐リスクのため不採用 |
| GATE-3 | 対象サイクル特定ロジック | **採用案: `cycle_resolver` を独立コンポーネント化し、各データソースを Strategy として分離する**（指摘 #3 反映）。Strategy: ①引数 / ②カレントブランチ / ③a git log / ③b ディレクトリ最大値。各 Strategy は `{candidate, source_id, confidence: high|medium|low, evidence}` を返す構造化結果を返却する。複数 Strategy が候補を返した場合は ① > ② > ③a > ③b の優先順位で第一候補を採用するが、**`③a` と `③b` の候補が不一致**かつ第一候補が `confidence != high` の場合は AskUserQuestion で必ずユーザー確認（fail-safe）。3 経路全て解決失敗時も AskUserQuestion フォールバック |
| GATE-4 | parser 拡張方針 | `/aidlc` SKILL.md の「引数ルーティング」テーブルに `retrospective` (`r`) を追加し、「独立フロー委譲」セクションで `/aidlc-retrospective` を委譲先として宣言する。短縮形は `r` のみ（`re` / `retro` は採用しない） |
| GATE-5 | Operations Phase §1 削除範囲 | §1.0〜§1.6 の全サブステップ実行ロジックを削除し、案内文「振り返りは `/aidlc r` を実行してください」のみ残す。`feedback_mode=disabled` 時の opt-out スイッチも `aidlc-retrospective` 側へ移転（Operations 側からは feedback_mode 評価ロジックを完全削除）。`predecessor_resolve_issue`（Inception 側）への影響なし |
| GATE-6 | Operations 完了メッセージ | §6「次のサイクル開始」付近で `/aidlc i` と並列に `/aidlc r` を案内する。文言は「振り返り（任意タイミング）: `/aidlc r [cycle]`」 |
| GATE-7 | マージ前完結契約のガード経路（指摘 #1 反映 / fail-closed） | **採用案: `operations-stage` は呼出元の入力値ではなく `write-history.sh` 側での導出値とする**。`write-history.sh` は実行コンテキスト（`git rev-parse --abbrev-ref HEAD` のブランチ名 + GitHub PR マージ状態 + サイクル directory の存在）から `pre-merge` / `post-merge` を再評価する。環境変数 `AIDLC_OPERATIONS_STAGE` を残す場合は **許可値 `pre-merge|post-merge` のみ受容、未検証値は fail-closed で exit 3** とする（許可値外 / 未設定で `cycles/{{CYCLE}}/**` 書き込み時はブロック）。状態遷移表は `pre-merge → post-merge` の単方向遷移のみ許可。`aidlc-retrospective` 経由でも本契約は不変であることを統合テストで確認 |
| GATE-8 | 互換アダプタ層 | v2.6.0 で破壊的変更（互換アダプタ層なし）。`aidlc-migrate` のアップグレード通知メッセージで「Operations 内振り返りは `/aidlc r` に移行されました」を明示。旧 `retrospective-generate.sh` / `retrospective-mirror.sh` の互換アダプタ層（v2.5.1 で残置）は本 Unit のスコープ外（v2.7.x で別 Unit が完全削除予定） |
| GATE-9 | sub-Unit 分割判断 | **単一 Unit 内で完結**を採用候補（Unit 005 のまま）。Phase 別作業範囲（後述「実装スコープ」§Phase 別工程）を計画書で明示することで分割不要と判断。Phase 1 設計レビューで規模が再見積もり 16 時間超に膨らんだ場合のみ Unit 分割を提案する |

## 完了条件チェックリスト

### Phase 1 ゲート由来

- [ ] GATE-1〜GATE-9 すべての論点が確定し、設計ドキュメントに記録されている

### Unit 定義「責務」由来

- [ ] **`skills/aidlc-retrospective/` 新設**: `SKILL.md`、必要に応じて `steps/`（振り返りフローのステップファイル）。`aidlc-feedback` の構成を踏襲
- [ ] **`/aidlc` parser 拡張**: `retrospective` (`r`) アクション追加、`/aidlc-retrospective {additional_context}` への委譲（テーブル + 委譲先表）
- [ ] **ロジック全量移転**:
    - feedback_mode 解決ロジック（§1.0 + Step 1）
    - 振り返り wizard（`interactive` モード）
    - cap 判定（`feedback_max_per_cycle` 上限 / Step 2）
    - Issue 本文構築（KPT / 主因切り分け / Try / 事実テーブル / Step 3）
    - `retrospective_issue_create` / `retrospective_prefill_hook` / `retrospective_update_hook`（Step 4 / Step 5）
    - spool fallback（`gh_status != available` 時）
    - mirror_state ラベル化
    - dialog token ガード（`retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify`）
- [ ] **Operations Phase §1 削除**: `04-completion.md` §1.0〜§1.6 から実行ロジックを削除し、案内文（「振り返りは `/aidlc r` を実行してください」）のみ残す
- [ ] **Operations 完了メッセージ更新**: `/aidlc i` 案内と同列で `/aidlc r` を表示
- [ ] **共有ライブラリ公開 API 層追加**: `skills/aidlc/scripts/lib/retrospective-api.sh` を新設。`aidlc-retrospective` は本ファイルのみを `source` する。再エクスポート関数の公開リスト・戻り値型・exit code 契約を logical design に明記（GATE-2 採用案）
- [ ] **対象サイクル特定ロジック新規実装**: `cycle_resolver` 独立コンポーネント + Strategy 分離（引数 / ブランチ / git log / ディレクトリ）+ 構造化結果（`candidate, source_id, confidence, evidence`）+ `③a / ③b` 不一致時 AskUserQuestion ガード（GATE-3）
- [ ] **互換性ドキュメント更新**: README.md / CHANGELOG.md / `aidlc-migrate` 出力に破壊的変更明示
- [ ] **マージ前完結契約の維持（fail-closed）**: `operations-stage` は `write-history.sh` 側で実行コンテキストから導出。`AIDLC_OPERATIONS_STAGE` を渡す場合は許可値 `pre-merge|post-merge` のみ受容、未検証値は fail-closed で exit 3。`aidlc-retrospective` 経由でも有効（GATE-7）

### Issue #667 受け入れ基準由来

- [ ] Operations Phase は「リリース完了 + post-merge cleanup」までで完結
- [ ] `/aidlc r` または `/aidlc retrospective` で独立スキル `aidlc-retrospective` を起動して実行
- [ ] 起動時に対象サイクル（直近完了サイクル）を自動検出 / 明示指定可能
- [ ] 振り返り Issue 作成（v2.5.0+ Issue 一本化方針）はそのまま維持
- [ ] 既存の Operations 内振り返りは v2.6.0 で破壊的変更として完全廃止（GATE-8）

### 横断要件

- [ ] Inception Phase `predecessor_resolve_issue`（前サイクル振り返り参照）の動作不変を確認
- [ ] `[rules.retrospective] feedback_mode` の 5 値（`silent` / `mirror` / `disabled` / `interactive` / 未設定 silent fallback）が新スキル経由でも従来通り解釈される
- [ ] 移転前後で振り返り Issue 本文の構造（KPT セクション / 主因切り分けマトリクス / 事実テーブル）が一致
- [ ] AskUserQuestion 対話必須ガード（§1.0.5 / Unit 001 / #647）が新スキル経由でも有効
- [ ] codex によるコード AI レビュー実施
- [ ] codex review --base main による統合 AI レビュー実施

## 実装スコープ

### 含む

#### Phase 別工程（sub-Unit 分割の代替）

1. **工程 A: スキル骨格 + parser 拡張**（〜2 時間）
    - `skills/aidlc-retrospective/SKILL.md` 新設
    - `skills/aidlc/SKILL.md` の引数ルーティング / 独立フロー委譲拡張
    - 対象サイクル特定ロジック（GATE-3）の最小実装
2. **工程 B: ロジック全量移転**（〜4 時間）
    - `steps/operations/04-completion.md` §1.0〜§1.6 の対応箇所を `skills/aidlc-retrospective/steps/retrospective.md`（仮）へ移植
    - 公開 API 層 `skills/aidlc/scripts/lib/retrospective-api.sh` を新設（既存 `lib/retrospective-issue.sh` 等を内部 source して再エクスポート）
    - `aidlc-retrospective` からは公開 API 層のみを `source` する単方向境界を確立
3. **工程 C: Operations 側削除 + 完了メッセージ更新**（〜2 時間）
    - `steps/operations/04-completion.md` §1.0〜§1.6 の実行ロジック削除
    - §6「次のサイクル開始」付近で `/aidlc r` 案内追加
4. **工程 D: ドキュメント更新 + 検証**（〜2〜4 時間）
    - README.md / CHANGELOG.md / `aidlc-migrate` 通知メッセージ更新
    - `grep -rn "retrospective_issue_create\|retrospective_prefill_hook\|retrospective_update_hook" skills/aidlc/steps/operations/` で実行ロジック残存ゼロ確認
    - 動作確認（feedback_mode 各値 / spool fallback / dialog token ガード）

### 含まない

- 振り返り Issue の重複統合 workflow（#621）
- `[rules.retrospective].feedback_mode` スキーマの拡張（互換維持）
- 振り返り「内容を判断する責務」の改善（既存 AskUserQuestion ガード移転のみ）
- 旧 v2.5.0 互換アダプタ層（`retrospective-generate.sh` / `retrospective-mirror.sh`）の完全削除（v2.7.x の別 Unit）
- `aidlc-retrospective` 単独 e2e CI の追加（Operations Phase テストの一部として担保）

## 設計考慮事項

### 1. 単方向委譲の維持

`aidlc-retrospective` から `aidlc` 本体スキルへの逆参照を作らない。これは Unit 005 の NFR「責務分離」に対応。具体的には:

- ❌ `aidlc-retrospective` 内から `/aidlc` スラッシュコマンドを呼ばない
- ❌ `aidlc-retrospective` 内から `skills/aidlc/steps/operations/**` を読まない
- ❌ `aidlc-retrospective` 内から `skills/aidlc/scripts/lib/retrospective-issue.sh` / `feedback-mode.sh` 等の内部 lib を直接 `source` しない（公開 API 層経由のみ許可、詳細は §3.2）
- ✅ `aidlc-retrospective` から `skills/aidlc/scripts/lib/retrospective-api.sh`（公開 API 層）の `source` のみ許可
- ✅ `aidlc-retrospective` から `skills/aidlc/templates/retrospective_template.md` の参照（共有テンプレート）

### 2. 対象サイクル特定の優先順位（GATE-3 詳細 / cycle_resolver コンポーネント）

```text
コンポーネント: CycleResolver（独立 / Phase 1 論理設計で具体化）

Strategy インターフェース:
  resolve() -> ResolutionResult | null
  ResolutionResult: { candidate: string, source_id: enum, confidence: high|medium|low, evidence: string }

Strategy 一覧:
  S1 ArgStrategy        : additional_context（明示指定）→ confidence=high
  S2 BranchStrategy     : カレントブランチが cycle/vX.Y.Z → confidence=high
  S3a GitLogStrategy    : main にマージ済の cycle/* ブランチ最新 → confidence=medium
  S3b CycleDirStrategy  : .aidlc/cycles/ ディレクトリから semver 最大値 → confidence=low

CycleResolver.resolve() 動作:
  1. 全 Strategy を実行し、候補リストを収集
  2. 優先順位 ① > ② > ③a > ③b で第一候補を決定
  3. fail-safe ガード:
       - 候補が空 → AskUserQuestion（経路 ④）
       - 第一候補が confidence != high かつ S3a と S3b の候補が不一致 → AskUserQuestion で必ず確認
       - その他は第一候補を採用し、起動時に確定根拠（source_id + evidence）を表示
```

不一致検出時のユーザー確認は OUT_OF_SCOPE（=ユーザー判断）に委ねるのではなく、誤った cycle で振り返り Issue を起票しないための fail-safe。ユーザー判断に委ねる前に「複数候補がある」「どちらが正しいか」を明示し、誤検出時の障害伝播を最小化する。

### 3. lib 共有経路の bootstrap 方針 + 公開 API 層

#### 3.1 bootstrap

`aidlc-retrospective` の SKILL.md / steps から共有 lib を参照するため、bootstrap で `AIDLC_BASE` を解決する仕組みを `aidlc-feedback` 流儀で揃える。Phase 1 設計で具体的な解決順位（`CLAUDE_PROJECT_DIR` / `${BASH_SOURCE[0]}` 起点 / `gh repo view` フォールバック等）を確定する。

#### 3.2 公開 API 層（GATE-2 採用案 / 指摘 #2 反映）

`aidlc-retrospective` は `skills/aidlc/scripts/lib/*.sh` を**直接 source しない**。代わりに新規 `skills/aidlc/scripts/lib/retrospective-api.sh` を経由する。

```text
公開 API 候補（Phase 1 論理設計で確定）:
  retrospective_api_resolve_feedback_mode  : feedback_mode 解決
  retrospective_api_compose_body           : Issue 本文構築
  retrospective_api_create_issue           : Issue 起票（dialog token verify 内蔵）
  retrospective_api_record_response        : dialog token 発行
  retrospective_api_run_wizard             : interactive wizard
  retrospective_api_check_cap              : cap 判定

非公開（aidlc-retrospective から呼ばない）:
  retrospective-issue.sh の内部関数（_validate_apply_path / _retrospective_*_internal 等）
  feedback-mode.sh の内部正規化関数

戻り値・exit code 契約:
  exit 0: 成功（stdout に key=value 形式で結果）
  exit 1: 警告（recoverable）
  exit 2: fatal（呼出元中断）
  exit 3: マージ前完結契約違反（write-history.sh ガード経路）
  exit 4: dialog-required（対話確認トークン未発行 / 失効 / denied）
```

`retrospective-api.sh` は内部で既存 `lib/retrospective-issue.sh` 等を `source` し、必要関数のみを `retrospective_api_*` プレフィックスで再エクスポートする層。これにより `aidlc-retrospective` が内部実装詳細に依存しない単方向境界を確立する。

### 4. dialog token ガードの責務移転

`retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` は `lib/retrospective-issue.sh` 内に既に実装済み。`aidlc-retrospective` の steps から AskUserQuestion 応答得た直後に `record_response` を呼び、`retrospective_issue_create` 内で `verify` が二段防御として動作することを確認する。本 Unit ではガード経路の検証のみで、ガード自体の改修は行わない（Issue 単独）。

### 4.5 マージ前完結契約のガード経路（GATE-7 詳細 / 指摘 #1 反映）

`operations-stage` は呼出元の入力値ではなく、`write-history.sh` 側で実行コンテキストから導出する fail-closed 設計とする。

```text
write-history.sh 内の operations_stage 評価ロジック（Phase 1 論理設計で確定）:
  入力候補:
    - 環境変数 AIDLC_OPERATIONS_STAGE（任意）
    - 実行コンテキスト: git rev-parse --abbrev-ref HEAD（ブランチ名）
    - GitHub PR マージ状態: gh pr view <branch> --json state,mergedAt
    - サイクル directory の存在: ls .aidlc/cycles/{{CYCLE}}/

  評価:
    1. AIDLC_OPERATIONS_STAGE が設定済 → 許可値 (pre-merge|post-merge) のみ受容、それ以外は exit 3（fail-closed）
    2. 未設定 → 実行コンテキストから自動導出:
        - ブランチ = main かつ PR merged かつ cycle directory 存在 → post-merge
        - ブランチ = cycle/{{CYCLE}} かつ PR not merged → pre-merge
        - その他 → exit 3（fail-closed / 判定不能）
    3. 状態遷移ガード: pre-merge → post-merge は単方向遷移のみ許可（逆遷移は exit 3）

  cycles/{{CYCLE}}/** への書き込み試行時:
    - operations_stage = post-merge → exit 3 でブロック
    - operations_stage = pre-merge → 許可
```

`aidlc-retrospective` は本契約を遵守する。呼出経路でも `AIDLC_OPERATIONS_STAGE` の値を恣意的に上書きせず、未指定で起動して `write-history.sh` 側に判定を委ねるのが原則。

### 5. 異常系フォールバック

- `gh_status != available`: `retrospective_issue_create` 内で spool fallback が動作（既存挙動維持）
- 対象サイクル特定失敗: AskUserQuestion で対話的フォールバック（GATE-3 の経路 ④）
- `feedback_mode=disabled`: 起動メッセージ「振り返り機能は無効化されています（`feedback_mode=disabled`）」を表示して exit 0
- `cap 超過` (`feedback_max_per_cycle` 到達): 既存挙動と同じく Step 3〜5 をスキップして §1.6 相当の処理に進む

### 6. 既存ガイド照合（CLAUDE.md ルール準拠）

設計レビュー時に以下の既存ガイドとの整合性を確認:

- `guides/exit-code-convention.md`: 終了コード規約（exit 0/1/2/3/4 の意味付け維持）
- `guides/error-handling.md`: エラーハンドリング規約
- `guides/backlog-management.md`: 振り返り由来 Issue のバックログ管理

## レビュー戦略

- **設計レビュー**: codex で `reviewing-construction-design`（責務分離 / 単方向委譲 / 共有ライブラリ参照経路 / 対象サイクル特定ロジック）
- **コードレビュー**: codex で `reviewing-construction-code`（シェル安全性 / parser 拡張の一貫性 / lib bootstrap）
- **統合レビュー**: `codex review --base main`（破壊的変更の網羅性 / Operations §1 削除の完全性）

## リスク・トレードオフ

| リスク | 軽減策 |
|------|------|
| 大規模移転で動作差分が発生する | 工程 B（ロジック移転）と工程 C（Operations 削除）を別コミットで実施し、移転だけ完了した状態で動作確認できる中間段階を設ける |
| `feedback_mode=disabled` 時の opt-out 経路を移転漏れする | Phase 2 テスト工程で全 5 値（`silent` / `mirror` / `disabled` / `interactive` / 未設定）を網羅検証 |
| Inception の `predecessor_resolve_issue` が壊れる | `inception/01-setup.md §4a` への影響なしを Phase 1 で構造的に確認（振り返り Issue ラベル/タイトル契約は不変） |
| `lib/*.sh` への単方向依存が密結合になる | Phase 1 設計レビューで「依存する関数の最小集合」を抽出し、依存関係図を残す |
| 破壊的変更でユーザー混乱 | `aidlc-migrate` の v2.5.x → v2.6.0 通知メッセージで `/aidlc r` 案内を明示。CHANGELOG.md「BREAKING CHANGES」セクションに記載 |
| dialog token ガードが新経路で機能しない | 統合レビュー時に `retrospective_dialog_token_verify` 経路の動作確認を必須項目化 |
| sub-Unit 分割判断が後手に回る | Phase 1 設計レビューで再見積もりを実施し、16 時間超なら即座に Unit 分割を提案 |

## 検証コマンド（工程 D）

```bash
# Operations 側に振り返り実行ロジックが残存していないこと
grep -rn "retrospective_issue_create\|retrospective_prefill_hook\|retrospective_update_hook\|retrospective-generate\|retrospective-mirror" skills/aidlc/steps/operations/

# /aidlc r が parser に追加されていること
grep -nE "retrospective|/aidlc r " skills/aidlc/SKILL.md

# aidlc-retrospective スキルが存在すること
ls skills/aidlc-retrospective/SKILL.md

# Inception 側 predecessor_resolve_issue は不変
grep -n "predecessor_resolve_issue\|predecessor_retrospective" skills/aidlc/steps/inception/01-setup.md
```
