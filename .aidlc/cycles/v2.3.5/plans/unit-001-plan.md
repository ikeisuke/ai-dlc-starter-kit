# Unit 001 実行計画: Operations 復帰判定の進捗源移行

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/001-operations-recovery-progress-source.md`
- **関連Issue**: #579（[Backlog] Operations復帰判定とマージ前完結ルールの矛盾解消）
- **優先度**: High / 見積もり: L（Large）
- **依存する Unit**: なし

## 背景・目的

Operations Phase のステップ7は「7.7 最終コミットで全判定ソースを確定させる（マージ前完結）」を設計上の契約としているが、現行の復帰判定は `history/operations.md` の記録（7.8 / 7.13 で発生）を参照しているため契約と矛盾する。AI エージェントが「復帰判定のために履歴記録を追加した方がよい」と誤判断し、マージ後の worktree に未コミットの history 変更が残る不具合が v2.3.4 で顕在化した。

本 Unit では、復帰判定の一次ソースを `operations/progress.md`（7.7 のコミットに確実に含まれる）に移行し、GitHub 実態確認（`gh pr view`）との AND で「完了」を判定する二段階方式を導入する。併せて旧形式（v2.3.4 以前）サイクルへの後方互換フォールバック、`undecidable:<reason_code>` 契約準拠、rollback 手順の設計を整備する。

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

## 変更対象ファイル（論理設計でさらに詰める）

- `skills/aidlc/templates/operations_progress_template.md`
  - ステップ7サブステップ欄を自由記述ではなく**安定パース可能な固定スロット**で表現する（`ArtifactsStateRepository.snapshot()` が決定論的に読めるキー行式を採用）
- `skills/aidlc/steps/common/phase-recovery-spec.md`
  - §3（`ArtifactsState` モデル定義 L104 付近: `progressFlags: Map<flag_name, boolean>` と `prNumber: int | null` を明示フィールドとして追加する（確定方針・下記「レイヤー責務確定方針」参照）。既存の `progressMarks: Map<step_key, ProgressStatus>` はステップレベルを維持し、サブステップフラグは別フィールドで管理）
  - §5.3（`release_done` / `completion_done` 判定ロジック）
  - §7.0（必須/オプション集合表 L472-486: `operations.release_done` / `operations.completion_done` の artifact_paths 欄・history 参照記述 L485-486）
  - §7.1（reason_code 分類表 L494-500: `pr_not_found` / `github_unavailable` / `pr_number_missing` / `inconsistent_sources` を blocking カテゴリに追加、判定層と検出条件・期待戻り値を明記）
  - §7.2（排他性評価順 L511-519: 新 reason_code を blocking 優先順位表に組み込む）
  - §12.1 バインディング表（L716-721: Materialized Binding 参照トークン）
  - §12.2 正常系検証（L728-732: `progress.md` フラグ + GitHub 実態確認の適用例）
  - §12.3 異常系例（L737-740: フラグ不在/GitHub 不達/不整合時の `undecidable` 遷移例）
  - §12.4 Operations ファイル境界対応（L743-744: artifact source の境界再定義）
- `skills/aidlc/steps/operations/index.md`
  - §2.2（L59-63: Construction→Operations 遷移表で progress フラグ要件を明示）
  - §3（L167-170: 判定チェックポイント表と解説文、マージ前完結の肯定表現）
  - §4（L205-210: ステップ読み込み契約表の `exit_condition` 欄を新フラグに整合）
- `skills/aidlc/steps/common/compaction.md`
- `skills/aidlc/steps/common/session-continuity.md`
- `skills/aidlc/steps/operations/01-setup.md`
- `skills/aidlc/steps/operations/03-release.md`
- `skills/aidlc/steps/operations/04-completion.md`
- `skills/aidlc/steps/operations/operations-release.md`（§7.8: エッジケース時の PR 番号追加コミット手順）
- 設計ドキュメント（Unit内の設計成果物として rollback 手順・後方互換方針・判定源決定表を整備）

## フラグ命名とデータ契約

既存 spec §5.3.1.3 / §5.3.1.4 の `release_done` / `completion_done` は **判定チェックポイント名**（判定結果を示す論理名）であり、これは従来通り維持する。本 Unit で `progress.md` に追加するのは **ゲート準備フラグ**（7.7 コミット時点で確定する進捗源）であり、命名衝突を避けるため次のデータ契約を導入する:

- **進捗フラグ名**: `release_gate_ready` / `completion_gate_ready`（`progress.md` のステップ7サブステップ欄に配置）
- **データ契約**: 進捗フラグ単独では「判定チェックポイント完了」とは扱わない。`release_done` / `completion_done` の判定は「`progress.md` のゲート準備フラグ == true」AND「GitHub 実態確認（`gh pr view` の checkpoint 別述語）== true」の両方を満たす場合のみ `true` を返す（具体的な GitHub 述語は「GitHub 判定契約」セクションを参照）
- **契約違反時の扱い（一般契約）**: フラグが true で GitHub 実態確認が false（もしくはその逆）の場合は原則として `undecidable:<reason_code>` を返却し、ユーザー確認へ遷移する
- **契約の優先順位【重要】**: 本一般契約は checkpoint 別契約（「GitHub 判定契約」および「PR 識別の永続ソース契約」の各 checkpoint 別振り分け表）より下位の規約として扱う。`release_done` / `completion_done` の具体挙動（GitHub false 時・`pr_number` 未記録時・`pr_not_found` 時・`state=MERGED` 期待時などの戻り値）は checkpoint 別契約の定義を優先し、そこで明示されていないケースのみ一般契約を適用する。これにより「フラグ true × GitHub false = 常に undecidable」の一般則と「release_done で PR 未存在 = false（未到達）」の具体則が衝突しても、後者が優先される構造を保証する
- **抽出契約**: `ArtifactsStateRepository.snapshot()` が `release_gate_ready` / `completion_gate_ready` / `pr_number` を `progress.md` の固定スロットから抽出する責務を持つ。`operations_progress_template.md` は自由記述ではなく**安定パース可能な固定スロット grammar**（下記「固定スロット grammar 仕様」セクション参照）で表現し、パーサ実装が正規表現等で決定論的に読める形式とする
- **モデル整合（レイヤー責務確定方針）**: `phase-recovery-spec.md §3` の `ArtifactsState` に **`progressFlags: Map<flag_name, boolean>` および `prNumber: int | null` を明示フィールドとして追加する**（計画段階で確定）。`operations_progress_template.md` の固定スロット解析は `ArtifactsStateRepository.snapshot()` に閉じ込め、`OperationsStepResolver` は構造化済みの `ArtifactsState` のみを参照する契約とする。これにより template の具象フォーマット変更が Resolver 層へ漏れないレイヤー分離を保証する

上記命名とデータ契約を `phase-recovery-spec.md` §3 / §5.3 に明記し、Materialized Binding（§12）でも同じ名称系を使用する。

## 固定スロット grammar 仕様

`operations_progress_template.md` のステップ7サブステップ欄は、`ArtifactsStateRepository.snapshot()` が決定論的にパースできる固定スロット grammar で記述する。論理設計フェーズで詳細を詰めるが、本計画段階で以下の grammar 契約を固定する:

| スロット名 | キー名 | 値型 | 必須/任意 | 未記録時の解釈 | 記載箇所 |
|-----------|-------|------|---------|--------------|---------|
| ゲート準備（リリース） | `release_gate_ready` | `boolean`（`true` / `false`） | 任意（新形式のみ） | 旧形式扱い（legacy-format 判定へ） | ステップ7サブステップ行 |
| ゲート準備（完了） | `completion_gate_ready` | `boolean`（`true` / `false`） | 任意（新形式のみ） | 旧形式扱い（legacy-format 判定へ） | ステップ7サブステップ行 |
| PR 番号 | `pr_number` | `integer`（正の整数） または 未記載 | 任意 | **checkpoint 別**: `release_done` 判定時は `false`（未到達扱い、初回 PR 未作成状態を許容）／`completion_done` 判定時は `undecidable:<pr_number_missing>`（blocking、「PR 作成済みであるべき状態」の不整合） | ステップ7 または 先頭メタ行 |

**grammar 規則**:

- **キー=値形式**: 固定スロットは `key=value` 形式で表現する（例: `release_gate_ready=true`）。値の前後に空白を許容
- **行の配置**: 1 行内に複数スロットをカンマ区切りで併記可能（例: `- [x] 7.7 最終コミット (release_gate_ready=true, completion_gate_ready=true, pr_number=123)`）。改行分離も許容
- **値型バリデーション**: `boolean` は `true` / `false` の小文字固定。`integer` は `[0-9]+`。型不一致は `undecidable:<format_error>` を返す
- **未知キー**: パーサは未知キーを**無視**する（将来拡張の前方互換性確保）
- **大文字小文字**: キー名は小文字固定。マッチは大文字小文字区別
- **重複キー**: 同一サブステップ内で同じキーが複数出現した場合、**最初の出現値を採用**し残りを無視（警告ログ）
- **コメント**: `#` 以降はコメントとしてパーサが無視する

**template の責務**: `operations_progress_template.md` は上記 grammar の **materialization（具象表現）** として位置付け、grammar 仕様本体は `phase-recovery-spec.md §5.3` または専用セクションに記載する。将来 template の文言が変更されても grammar が安定していれば判定は破壊されない。

## GitHub 判定契約

`release_done` / `completion_done` の「GitHub 実態確認」部分は、checkpoint ごとに PR 状態述語が異なるため、`phase-recovery-spec.md §5.3.1.3 / §5.3.1.4` のセマンティクス（7.7 = PR Ready 化、7.13 = PR マージ）に従い次のように定義する:

| checkpoint | 進捗フラグ条件 | GitHub 実態述語（`gh pr view --json` 取得フィールド基準） |
|-----------|-------------|-----------------------------------------------------------|
| `release_done` | `progress.release_gate_ready == true` | `isDraft == false` AND `state == "OPEN"` |
| `completion_done` | `progress.completion_gate_ready == true` | `state == "MERGED"` AND `mergedAt != null` |

判定契約:

- **採用フィールド**: `gh pr view <PR識別子> --json isDraft,state,mergedAt,headRefName` で取得したフィールドのみを参照する（他フィールドに依存しない）
- **PR 識別方法**: 下記「PR 識別の永続ソース契約」に従い、`operations/progress.md` の PR 番号固定スロットから取得した `pr_number` を `gh pr view <pr_number>` に渡して PR を特定する。`git branch --show-current` は判定に使用しない
- **PR 未存在時の戻り値**:
  - `release_done` 判定時に PR 未存在: `false`（まだ PR 未作成の未到達状態として扱う）
  - `completion_done` 判定時に PR 未存在: `undecidable:<pr_not_found>`（release_done=true まで到達しているはずなのに PR が消失している不整合として扱う）
- **GitHub API 不達時**: 「判定源選択の決定表」の `github-unavailable` カテゴリに該当し、`undecidable:<github_unavailable>` を返す（API 呼び出しとリトライ方針は論理設計フェーズで確定）
- **マージ方式非依存**: `merge_method=squash` / `merge` / `rebase` のいずれでも `state == "MERGED"` で判定する（`mergedAt != null` の冗長チェックは `state` 値の整合性検証として機能）

### PR 識別の永続ソース契約

`completion_done` 判定はサブステップ 7.13（PR マージ）後のセッション再開時にも評価対象となる。この復帰局面では `operations.04-completion` の手順により:

- 通常環境: `git checkout main` 実行済み（現在ブランチ = `main`）かつ cycle ブランチ削除済み
- worktree 環境: `post-merge-cleanup.sh` により detached HEAD 化 + cycle ブランチ削除済み

となり、**`git branch --show-current` では当該サイクルの PR を一意に識別できない**（`main` 表示 or 空文字列）。このため PR 識別はブランチ名非依存の永続ソースに基づく必要がある:

- **PR 番号確定タイミング（現行フロー調査結果）**: `operations-release.md §7.8` の `find-draft` / `gh pr create` の挙動を前提に、PR 番号が確定するタイミングは次の 2 系統に分かれる:
  - **通常系**: Inception Phase 05-completion でドラフト PR 作成済み → **7.1 開始時点で PR 番号は既に確定**している。`progress.md` の固定スロットには 7.1 初期化時または 7.6 progress 更新時までに記録可能
  - **エッジケース**: Inception で `draft_pr=never` / `gh_status` 不可などでドラフト PR が未作成 → **7.8 の `gh pr create` で初回 PR 作成**される。この場合、7.7 コミット時点では PR 番号未確定となる
- **永続化タイミング契約（エッジケース対応）**: 上記 2 系統に対応するため、永続化タイミングを次のように定義する:
  1. **7.6 progress 更新時に PR 番号が確定している場合**: 7.7 最終コミットに `pr_number` 固定スロットを含める（マージ前完結）
  2. **7.8 で初回 PR 作成されるエッジケース**: 7.8 の `gh pr create` 直後に `operations/progress.md` の `pr_number` スロットを更新し、**追加コミット**（`commit-flow.md` の「pr-number 追記」として明記）を行う。この追加コミットは 7.8 〜 7.13 の間に発生する正規のコミットとして扱い、マージ前に必ず main に取り込まれる構造とする
- **抽出契約**: `ArtifactsStateRepository.snapshot()` は PR 番号スロットを `progress.md` から決定論的に抽出し、`ArtifactsState.prNumber` に含める
- **フォールバック非依存**: `git branch --show-current` は PR 識別には使用しない（ブランチ削除後・`main` checkout 後・worktree detached HEAD 後のいずれでも判定が成立することを契約とする）
- **PR 番号スロット欠損時の checkpoint 別振り分け契約**: `pr_number` 未記録時の戻り値は checkpoint ごとに次のとおり振り分ける（「PR 作成済みであるべき状態」かどうかで区別）:
  - **`release_done` 判定時**: `pr_number` 未記録 → `false`（未到達として扱う。エッジケースでは 7.8 で初回 `gh pr create` を実行するまで正常に PR 未作成であり、ユーザーは `operations.03-release` の継続が期待される）
  - **`completion_done` 判定時**: `pr_number` 未記録 → `undecidable:<pr_number_missing>`（`release_done=true` まで到達していれば PR は必ず存在しているべきであり、欠損は不整合として blocking 扱い）
- **`operations-release.md §7.8` への反映**: 「初回 PR 作成前（7.8 実行前）のセッション再開では `pr_number` 欠損は正常状態」と読める文言を追加し、`release_done` 判定が `false` を返してユーザーを 7.8 継続に誘導する流れを明示する

上記契約は `phase-recovery-spec.md §5.3.1.3 / §5.3.1.4` の該当セクション、`operations-release.md §7.8`（PR 番号追加コミット手順＋pr_number 欠損時の正常解釈）、および §12.2（正常系: マージ後シナリオ／エッジケース再開シナリオを含む）/ §12.3（異常系: `pr_not_found` / `github_unavailable` / `pr_number_missing`）に反映する。

## 判定源選択の決定表（後方互換フロー）

旧形式サイクル（v2.3.4 以前）との後方互換を決定論的に実現するため、判定源選択を次の決定表で定義する（`phase-recovery-spec.md` §7 の 4 カテゴリ決定表パターンに整合）:

| 優先順位 | カテゴリ | `progress.md` | `history/operations.md` | GitHub 実態確認 | 採用判定源 | 戻り値 |
|---------|---------|---------------|------------------------|----------------|----------|-------|
| 1（最優先） | github-unavailable | 任意 | 任意 | 不達（タイムアウト / 認証失敗 / レート制限） | なし（実態確認不可） | `undecidable:<github_unavailable>` |
| 2 | invalid-mixed-format | 新フラグ存在 **かつ** history に矛盾エントリ存在 | 矛盾あり | 可達 | なし（不整合検出） | `undecidable:<inconsistent_sources>` |
| 3 | new-format | 新フラグ存在 **かつ** history 矛盾なし | 矛盾なし | 可達 | 新方式（progress フラグ AND GitHub） | `release_done` / `completion_done` / `false` |
| 4 | legacy-format | 新フラグ不在（history の有無は問わない） | 任意（旧エントリありなら旧判定、なしなら未到達として `false`） | 可達 | 旧方式（history 参照へフォールバック） | 旧判定ロジックの結果（旧エントリ不在時は `false`） |

- **評価順の排他性保証**: GitHub 不達は最優先（可達前提の他カテゴリより先に評価）、次に新フラグと history の矛盾検出、その後 new-format → legacy-format の順で評価する。各カテゴリの述語は相互排他的に定義し、上位カテゴリに該当した時点で下位は評価しない
- **述語の真理値表記**: `has_new_flags := progress に新フラグあり` / `has_legacy_entry := history に旧エントリあり` / `has_conflict := 新フラグと history の判定結果が矛盾` / `github_reachable := gh API 応答成功`。各カテゴリは (github_reachable, has_new_flags, has_legacy_entry, has_conflict) の 4 述語で一意に特定される
- **全状態被覆の明示**: 真理値空間 `(github_reachable, has_new_flags, has_legacy_entry, has_conflict)` の全組み合わせを次のように被覆する:
  - `github_reachable=false` → 常に github-unavailable（優先順位 1）
  - `has_new_flags=true ∧ has_conflict=true` → invalid-mixed-format（優先順位 2）
  - `has_new_flags=true ∧ has_conflict=false` → new-format（優先順位 3）
  - `has_new_flags=false` → legacy-format（優先順位 4、`has_legacy_entry` の有無に関わらず包含）。内部で `has_legacy_entry=true` なら旧 history ロジック評価、`has_legacy_entry=false` なら旧エントリ未到達として `false` を返す
  - これにより `(github_reachable=true, has_new_flags=false, has_legacy_entry=false, has_conflict=false)` のような「新形式未導入 × 旧 history 記録前」のサイクル初期状態も legacy-format 配下で正しく `false` として処理される
- `undecidable:<reason_code>` 戻り値は `phase-recovery-spec.md §6/§8` の契約に従い、`automation_mode=semi_auto` でも自動継続せずユーザー確認へ遷移する
- 決定表は設計成果物として `phase-recovery-spec.md §7` 相当の表形式で記載する

## 完了条件チェックリスト

### 機能要件（Unit 責務由来）

- [ ] `operations_progress_template.md` にステップ7のゲート準備フラグ（`release_gate_ready`, `completion_gate_ready`）を追加し、7.7 コミット時点（エッジケース時は 7.8 PR 作成直後の追加コミット時点）で確定する構造にする
- [ ] `operations_progress_template.md` のステップ7サブステップ欄を**安定パース可能な固定スロット grammar**（本計画「固定スロット grammar 仕様」セクション）で記述し、自由記述に依存しないパーサ契約を確立する
- [ ] 固定スロット grammar 仕様（キー名: `release_gate_ready` / `completion_gate_ready` / `pr_number`、値型、必須/任意、未記録時の解釈、未知キー無視、重複キー扱い、コメント扱い）を `phase-recovery-spec.md §5.3` または専用セクションに明記し、`operations_progress_template.md` は grammar の materialization として位置付ける
- [ ] `phase-recovery-spec.md` §3 の `ArtifactsState` モデルに **`progressFlags: Map<flag_name, boolean>` および `prNumber: int | null` を明示フィールドとして追加**する（計画段階で確定方針）。template 依存は `ArtifactsStateRepository` に閉じ込め、`OperationsStepResolver` は構造化済み `ArtifactsState` のみ参照する契約を維持
- [ ] `phase-recovery-spec.md` §5.3 の `release_done` / `completion_done` 判定仕様を、`progress.md` のゲート準備フラグ + GitHub 実態確認の AND 方式に書き換え、「フラグ単独では判定チェックポイント完了と扱わない」データ契約を明記する
- [ ] `phase-recovery-spec.md` §5.3.1.3 / §5.3.1.4 に GitHub 判定契約（`release_done := isDraft=false AND state=OPEN` / `completion_done := state=MERGED AND mergedAt!=null`）を checkpoint 別に明記し、採用フィールド（`isDraft` / `state` / `mergedAt`）と PR 識別方法（`gh pr view <pr_number>`、ブランチ名非依存）、PR 未存在時の戻り値（`release_done=false` / `completion_done=undecidable:<pr_not_found>`）、GitHub 不達時の戻り値（`undecidable:<github_unavailable>`）を定義する
- [ ] PR 識別子を `operations/progress.md` の固定スロット（PR 番号）に永続化する契約が定義されている。通常系（Inception 05-completion で PR 作成済み）では 7.7 最終コミットに含め、エッジケース（7.8 で初回 `gh pr create` 実行）では 7.8 直後に `pr_number` スロット更新＋追加コミットを行う永続化タイミング契約を明記する。`completion_done` 判定が「ブランチ削除後・`main` checkout 後・worktree detached HEAD 後」のいずれの局面でも成立することを、正常系検証ケース（spec §12.2）の新規シナリオとして明記する
- [ ] `operations-release.md §7.8` に PR 番号追加コミット手順（エッジケース時）を明記し、追加コミットがマージ前に必ず main に取り込まれる構造を保証する
- [ ] `ArtifactsStateRepository.snapshot()` が `progress.md` から `release_gate_ready` / `completion_gate_ready` / `pr_number` スロットを決定論的に抽出する責務を持つことを明記する
- [ ] PR 番号スロット欠損時の戻り値（`undecidable:<pr_number_missing>`）が `phase-recovery-spec.md` §5.3.1.4 / §7.1 / §12.3 に定義されている
- [ ] `phase-recovery-spec.md` §7.0（L472-486）の必須/オプション集合表を更新し、`operations.release_done` / `operations.completion_done` の artifact_paths 欄を新フラグ参照に整合させる（L485-486 の history 参照記述は後方互換フォールバック用途に再定義）
- [ ] `phase-recovery-spec.md` §7.1（L494-500）の reason_code 分類表を更新し、新 reason_code（`pr_not_found` / `github_unavailable` / `pr_number_missing` / `inconsistent_sources`）を blocking カテゴリとして追加する。各 reason_code の判定層（ArtifactsState 構築時 / `OperationsStepResolver` / GitHub 呼び出し層）、検出条件、戻り値への反映、および §7.2 排他性評価順（blocking 優先順位）への組み込みを明記する
- [ ] `phase-recovery-spec.md` §7 に 4 カテゴリ決定表（優先順位付き: 1=github-unavailable / 2=invalid-mixed-format / 3=new-format / 4=legacy-format）を追記し、述語の相互排他性と真理値表記（`has_new_flags` / `has_legacy_entry` / `has_conflict` / `github_reachable`）、`undecidable:<reason_code>` 遷移を明文化
- [ ] `phase-recovery-spec.md` §12.1（L716-721）のバインディング表を新フラグ名（`release_gate_ready` / `completion_gate_ready`）に更新
- [ ] `phase-recovery-spec.md` §12.2（L728-732）の正常系検証を新 AND 判定フローの適用例に書き換え
- [ ] `phase-recovery-spec.md` §12.3（L737-740）の異常系例にフラグ不在 / GitHub 不達 / 不整合混在パターンを追加
- [ ] `phase-recovery-spec.md` §12.4（L743-744）の Operations ファイル境界対応を、新方式の artifact source（`progress.md`）に合わせて再定義
- [ ] `steps/operations/index.md` §2.2（L59-63）の Construction→Operations 遷移表に、7.7 コミット時点での progress フラグ要件を明記
- [ ] `steps/operations/index.md` §3（L167-170）の判定チェックポイント表・解説文が新参照先（`progress.md` ゲートフラグ＋GitHub）と整合している
- [ ] `steps/operations/index.md` §4（L205-210）のステップ読み込み契約表 `exit_condition` 欄を新フラグに整合
- [ ] `steps/common/compaction.md` の「Operations 復帰判定」記述を新参照先に合わせて更新
- [ ] `steps/common/session-continuity.md` の「Operations 復帰判定」記述を新参照先に合わせて更新
- [ ] `steps/operations/01-setup.md` / `03-release.md` / `04-completion.md` を確認し、7.8 以降の history 追記を誘導する既存記述がない（あれば削除）ことを保証
- [ ] `steps/operations/index.md` または該当 step に判定ソース確定タイミングを肯定形で明記する（「通常系では 7.7 最終コミット時点、初回 PR 作成エッジケースでは 7.8 `gh pr create` 直後の追加コミット時点で全判定ソースが確定する」旨を書き、AIエージェントによる誤った history 追記を誘発しない文言とする）
- [ ] 後方互換フロー: 決定表に従い、旧形式（v2.3.4 以前のサイクル）で新フラグ不在の場合は `history/operations.md` 参照へ段階的フォールバックする仕様が定義・明文化されている
- [ ] GitHub API 利用不可時および新旧形式混在時の `undecidable:<reason_code>` 戻り値契約への準拠（`phase-recovery-spec.md` §6/§8）を満たし、`automation_mode=semi_auto` でも自動継続せずユーザー確認へ遷移する旨が記述されている
- [ ] Rollback 手順の設計ドキュメント化（「フラグは立っているが実行失敗」「実行成功したがフラグ未記録」両方の不整合パターンの復旧手順）

### 整合性・品質要件

- [ ] `phase-recovery-spec.md` と `steps/operations/index.md` の Materialized Binding（spec 参照トークン）整合が保たれている
- [ ] 新旧形式のフォールバック判定がコード/仕様上で決定論的（新フラグ検出→新方式、不在→旧方式）に動作する
- [ ] 設計 / コード / 統合の 3 段階 AI レビューを Codex で実施（`review_mode=required`）
- [ ] markdownlint 実行結果エラー 0
- [ ] Unit 定義ファイルの「実装状態」を「完了」に更新
- [ ] `/write-history` スキルで履歴を記録
- [ ] Construction Phase のコミット規約に従い squash 後にコミット

### 境界（実装対象外）

- Construction Phase 復帰判定のステップレベル化（#554、別サイクル）
- Inception Phase 復帰判定仕様の変更
- `operations-release.sh` / `merge-pr` の動作自体の変更（Unit 002, 003 のスコープ）

## 依存関係・実装順序

- 本 Unit は他 Unit に先行可能（依存なし）
- 本 Unit 完了後に Unit 002 へ着手（別責務だが共通の Operations フロー整合を保つため順序性を意識）
- Unit 004 は Unit 002 で定義される `diverged` ステータスに依存するため本 Unit とは直接の依存関係なし

## 非機能要件（NFR）

Unit 定義の NFR を踏襲:

- パフォーマンス: `gh pr view` 1 回の追加のみ。応答時間は現行と同等
- セキュリティ: 新規機密情報なし。`gh` トークンは既存と同じ扱い
- スケーラビリティ: N/A（シングル PR 想定）
- 可用性: GitHub API 不可時は `undecidable:<reason_code>` を返し、ユーザー確認フローへ安全にフォールバック

## リスクと緩和策

| リスク | 影響 | 緩和策 |
|-------|------|--------|
| 後方互換フォールバック漏れ | 旧サイクル再開時に誤判定 | 4 カテゴリ決定表に従った新フラグ不在時の旧 history 参照をテスト観点に含め、仕様ドキュメントで決定論的挙動を明示 |
| フラグ命名衝突（判定チェックポイント名と進捗フラグ名の混同） | データ契約の解釈ブレ / 実装齟齬 | 進捗フラグを `*_gate_ready` に命名分離し、spec §5.3 にデータ契約（フラグ単独 ≠ 判定完了）を明記 |
| 新旧形式混在（invalid-mixed-format） | 誤判定による「マージ前完結契約（通常系=7.7 / エッジケース=7.8 追加コミット）」の破綻 | 決定表で `undecidable:<inconsistent_sources>` への遷移を定義し、ユーザー確認を強制 |
| `undecidable` 契約未遵守 | `semi_auto` で自動継続してしまう | `phase-recovery-spec.md §6/§8` を引用して自動継続禁止を明文化 |
| Materialized Binding の齟齬 | spec と index.md のズレで判定が乖離 | 変更後に spec §12.1-12.4 の参照トークン一覧を突き合わせる確認手順を設計成果物に含める |
| レイヤー分離崩れ（サブステップフラグ抽出責務の未定義） | `OperationsStepResolver` が `operations_progress_template.md` の詳細に直接依存する | 計画段階で確定済み: `ArtifactsState` に `progressFlags`／`prNumber` を明示フィールドとして追加、`ArtifactsStateRepository.snapshot()` が固定スロット grammar からこれらを抽出する責務を持つ。`OperationsStepResolver` は構造化済み `ArtifactsState` のみ参照する契約を spec §3 / §5.3 に明記 |
| GitHub 判定述語の checkpoint 間混同 | `release_done` に `state=MERGED` を適用する等の誤実装 | checkpoint 別の GitHub 判定契約表を spec §5.3.1.3 / §5.3.1.4 に明記、コードレビュー観点にも追加 |
| PR 識別子のブランチ名依存 | 04-completion 実行後（`main` checkout / detached HEAD / cycle ブランチ削除後）の `completion_done` 復帰判定が `undecidable:<pr_not_found>` へ退行 | PR 番号を `operations/progress.md` の固定スロットに永続化し、`git branch --show-current` には依存しない識別契約を採用。spec §12.2 の正常系検証にマージ後シナリオを追加 |
| 7.8 以降の history 追記が再発 | マージ後の未コミット変更が再発 | ステップファイル全件を grep し、history 追記を誘導する文言がないことを確認 |

## AI レビュー計画

- ツール: `codex`（`rules.reviewing.tools[0]`）
- `review_mode=required` のためスキップ不可。設計 / コード / 統合の 3 段階で実施
- 各レビューはフォールバック条件（`review_issues` / `error`）該当時にユーザー確認へ遷移

## 完了後の遷移

- Unit 定義「実装状態」を「完了」に更新
- `/write-history` で履歴記録
- markdownlint → squash → commit
- 次 Unit（Unit 002: リモート同期チェックの squash 後 divergence 対応）へ

## 承認要求

本計画に基づき Unit 001 を開始します。計画に過不足がないか確認してください。
