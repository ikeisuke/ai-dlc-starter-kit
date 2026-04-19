# Unit 001 実装計画 - operations-release.md 固定スロット反映ステップ追加

## Unit 概要

`skills/aidlc/steps/operations/operations-release.md` §7.2〜§7.6 に、`release_gate_ready` / `completion_gate_ready` / `pr_number` の固定スロットを §7.7 最終コミットに含めるための明示的手順を追加する。マージ前完結契約（`phase-recovery-spec.md` §5.3）を手順書単体で導出可能にする（#583-A / DR-001）。

## 完了条件チェックリスト

**Unit 定義「責務」由来**:

- [ ] `skills/aidlc/steps/operations/operations-release.md` §7.6（§7.2〜§7.6 の節構成内）に、`release_gate_ready=true` を progress.md に反映して §7.7 最終コミットに含めるステップが明示される。
- [ ] 同節に `completion_gate_ready=true` および `pr_number=<PR 番号>` の反映タイミング（§7.6 で記入、§7.7 でコミット）が明確に指定される。**通常系（Inception で draft PR 作成済み）**の前提で `pr_number` を §7.6 で反映すると明記し、**7.8 で初回 PR 作成されるエッジケース**（Inception で `draft_pr=never` / `gh_status` 不可だった場合等、既存 L44〜L46 の契約）は従来どおり 7.8 の追加コミットで `pr_number` を永続化する契約を維持することを明文化する。
- [ ] 固定スロット名・値形式の主参照先は `phase-recovery-spec.md` §5.3.5（固定スロット grammar の正規定義）とし、§7 は異常系・判定源整合の補助参照として記述される。
- [ ] 固定スロット既設定時の扱い（上書き不要 or 再確認）が一文以上で記述される。
- [ ] §7 冒頭または §7.6 の説明文から `phase-recovery-spec.md` §5.3.5 への相互参照を設け、§7.6 と §7.7 の記述不整合を検知可能にする。

**関連 Issue「受け入れ基準」由来（#583 / Story 1.1）**:

- [ ] `operations-release.md` §7.6 を読むだけで `release_gate_ready=true` を §7.7 最終コミットに含めるべきだと判断できる（手順書単体での導出性）。
- [ ] 手順書の修正後、**通常系** release フローを実行するユーザー（AI）が追加コミットを作らずに固定スロットを main に反映できる（**エッジケース**は従来の追加コミット契約を許容）。
- [ ] 旧パス参照 0 件の検証: Unit 001 完了処理で `rg "guides/operations-release"` と `rg "steps/operations/operations-release"` を実行し、前者が 0 件（旧 guides/ パスへの参照が残っていない）、後者が期待箇所数以上の結果を示すことを確認する（Story 1.1「付随条件・限定」要件）。結果は Unit 001 完了処理で作成・追記される Unit 001 履歴ファイル `.aidlc/cycles/v2.3.6/construction/units/001-operations-release-fixed-slot-reflection.md`（Git 管理下の Construction Unit 履歴ノート）に必ず記録し、監査証跡をリポジトリ単独で成立させる。補助的に PR 本文にも併記してよいが、主たる記録先はリポジトリ内ファイルとし、Claude Code 内 TaskList 等のリポジトリ外オブジェクト単独への依存は不可。

## 実装方針

### Phase 1（設計）の扱い

本 Unit はドキュメント（Markdown）1 ファイルの追記のみであり、新規ドメインモデル・論理設計は不要。以下のとおり扱う（ユーザー承認済み）:

- **ドメインモデル**: N/A（新規ドメインロジックなし）。計画ファイル本節にその旨を記録して終了する。
- **論理設計**: N/A。本計画内で「追記する文面骨子」を示すことで代替する。
- **設計レビュー**: スキップ（成果物なし）。
- **設計承認**: スキップ。

> 注: `depth_level=standard` だが、変更がテキスト編集のみのため実質的に `minimal` 相当の扱いで妥当と判断する。本計画の AI レビューでこの扱いの妥当性も検証済み。

### Phase 2（実装）の作業内容

1. `skills/aidlc/steps/operations/operations-release.md` §7.2〜§7.6 セクションに以下を追記する。
   - progress.md 固定スロット反映手順（§7.6 の新サブ節 or 既存箇条書きへのステップ追加）。
     - `release_gate_ready=true` に更新（通常系・エッジケース共通。grammar は `phase-recovery-spec.md` §5.3.5 に準拠する `key=value` 形式）。
     - `completion_gate_ready=true` に更新（マージ前完結契約により予約的に true を書き、§7.7 最終コミットで main に反映させる。通常系・エッジケース共通）。
     - `pr_number=<PR 番号>`:
       - **通常系**（Inception Phase で draft PR 作成済み、§7.8 が既存 PR を Ready 化する経路）: §7.6 で `gh pr view` により番号を確定し、progress.md に反映。§7.7 最終コミットに含める。
       - **エッジケース**（§7.8 で初回 PR 作成する経路、現行 L44〜L46 契約）: 既存の「7.8 PR 作成直後に `operations/progress.md` の `pr_number=` を更新し追加コミット（`chore: [{{CYCLE}}] PR番号記録 - operations/progress.md`）を行う」フローを維持する。§7.6 では `pr_number` を空欄のままとし、`release_gate_ready` / `completion_gate_ready` のみを §7.7 に含める旨を明記。
     - 既に値がセット済みの場合は上書き不要（再確認のみ）。
   - `phase-recovery-spec.md` §5.3.5（固定スロット grammar の正規定義）への相互参照リンクを §7 冒頭または §7.6 に追加。§7（異常系）は補助参照として位置づける。
2. 記述の整合性手動確認:
   - `rg "release_gate_ready|completion_gate_ready|pr_number" skills/aidlc/steps/operations/operations-release.md` で該当追記を目視確認。
   - `rg "guides/operations-release"` で 0 件（旧 guides/ パスへの参照が残っていない）を確認。
   - `rg "steps/operations/operations-release"` で期待箇所数を確認（相互参照が残っている）。
   - §7.6 と §7.7 のステップ遷移が通常系・エッジケース両方で破綻しないか目視確認。
3. 本 Unit は手順書のみの変更のため自動テストは不要。
4. コードレビュー（AI レビュー）: 追記文言に対して `reviewing-construction-code` スキルで codex レビューを実施。
5. 統合レビュー: ビルド/テスト不要のため `reviewing-construction-integration` スキルで「手順書の整合性」観点でレビュー。

### 境界外（本 Unit では扱わない）

- `write-history.sh` へのガード追加（Unit 002）。
- `04-completion.md` への禁止記述追加（Unit 002）。
- Inception progress.md 命名統一（Unit 003）。
- Draft PR Actions スキップ（Unit 004）。
- CHANGELOG 更新（Unit 003 集約）。

### テンプレート未対応の扱い（明文化）

`skills/aidlc/templates/operations_progress_template.md` には現状 `release_gate_ready` / `completion_gate_ready` / `pr_number` の固定スロット行が含まれていない。本 Unit ではこれをスコープ外とするが、以下の理由で受け入れに影響しないと判断する:

- Unit 001 のスコープは「手順書から固定スロット反映が導出可能であること」であり、テンプレート自体の更新ではない。
- 現行 Operations Phase 実運用（v2.3.5 以前）では手順書に従って AI がその場で固定スロット行を progress.md に追記する運用になっている。Unit 001 で手順書が整備されればこの運用は安定化する。
- テンプレート整備は **follow-up issue** として別途バックログ登録する（バックログタイトル例: `[Backlog] operations_progress_template.md に固定スロット（release_gate_ready / completion_gate_ready / pr_number）を追加`）。
- 本 Unit 完了処理時にバックログ登録を行い、Unit 001 履歴に Issue 番号を記録する。

## 影響範囲

- 変更ファイル: `skills/aidlc/steps/operations/operations-release.md`（1 ファイル）
- コマンド/スクリプト変更: なし
- 下流影響: Operations Phase を次回以降実施する AI エージェントの挙動がガイド経由で変わる（固定スロット反映が確実に行われる）。既存の run 中サイクル（本サイクル v2.3.6 自身）への影響は、マージ後の Operations Phase 実施時点から。

## 見積もり

0.5 日

## 依存関係

- 依存する Unit: なし
- 外部依存: なし
