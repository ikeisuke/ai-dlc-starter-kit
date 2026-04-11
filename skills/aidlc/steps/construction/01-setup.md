# Construction Phase セットアップ・Unit 選定（`construction.01-setup`）

> 分岐ロジック・Phase 構成・`automation_mode` / `depth_level` / エクスプレス分岐・AI レビュー分岐・Unit 選定ルールは `steps/construction/index.md`（フェーズインデックス）に集約されている。本ファイルは詳細手順のみを含む。

**記録・割り込み対応**:

- **プロンプト履歴管理**: `/write-history` スキルを使用して `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` にUnit単位で記録
- **気づき記録フロー**: 別Unitや新規課題の気づきはバックログに記録し、現在のUnit作業は中断しない（`guides/backlog-management.md` 参照）
- **Workaround実施時**: 暫定対応を行う場合、本質的な対応をバックログに記録し、コード内に `// TODO: workaround - see backlog (GitHub Issue を参照)` を残す
- **割り込み対応**: 分類1（現Unit/サイクル外）→ バックログ、分類2（別Unit）→ バックログ or 別Unit追加、分類3（現Unit内）→ Unit定義追記 → 設計更新 → 実装

---

## あなたの役割

ソフトウェアアーキテクト兼エンジニア。

---

## 最初に必ず実行すること

### 1. サイクル存在確認

`.aidlc/cycles/{{CYCLE}}/` が存在しなければエラー（Inception Phaseを案内）。

### 2. 追加ルール確認

`.aidlc/rules.md` が存在すれば読み込む。

### 3. プリフライトチェック

結果（`gh_status`, `depth_level`, `automation_mode` 等）をコンテキスト変数として保持。

### 4. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合のみ実行。

### 5. Depth Level確認

プリフライトで取得済みの `depth_level` を確認。`rules-reference.md` の「Depth Level仕様」参照。

### 6. 進捗状況確認【重要】

`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/` の全Unit定義ファイルを番号順に読み込み、「実装状態」セクションを確認。

### 7. 対象Unit決定

**【次のアクション】** `steps/construction/index.md` §2.2「Unit 選定ルール」および §3.1「Stage 1: Unit 識別アルゴリズム」に従い対象 Unit を決定する。判定ロジック本体は `steps/common/phase-recovery-spec.md` §5.2（UnitSelectionRule）に集約されている。

**概要**（詳細は上記参照）:

- `phaseProgressStatus[construction]=completed` は PhaseResolver 側で吸収されるため、本ステップでは扱わない
- 進行中 Unit あり → そのまま継続（複数ある場合は `undecidable:conflict`、ユーザー確認）
- 進行中 0 + 実行可能 Unit あり → 1 個なら自動選択、複数なら `semi_auto` で番号順自動選択 / `manual` でユーザー選択
- 進行中 0 + 実行可能 0 + pending Unit あり → `undecidable:dependency_block`（ユーザー確認必須）
- 実行可能条件: 状態「未着手」かつ依存 Unit 全て「完了」or「取り下げ」

### 7a. タスクリスト作成【必須】

**前提**: ステップ7で対象Unitが決定された場合のみ実行する。実行可能Unit 0個（全Unit完了）の場合はスキップ。

**【次のアクション】** 対象Unit決定後、`steps/common/task-management.md` の「Construction Phase: Unit開始時タスクテンプレート」に従い、Unitのタスクリストを作成してください。**タスクリスト未作成のまま次のステップに進んではいけない。**

### 8. セッションタイトル更新【オプション】

Unit確定後に `session-title` スキルを再実行（利用可能な場合のみ）。

### 9. Issueステータス更新

```bash
scripts/issue-ops.sh set-status <issue_number> in-progress
```

ブロック時は `blocked`、解除時は `in-progress` に更新。

### 10. 実行前確認と完了条件の提示【重要】

計画ファイル `.aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md` を作成し、完了条件チェックリストを含めてユーザーに承認を求める。

**完了条件の抽出**: Unit定義「責務」セクション（必須）+ 関連Issueの受け入れ基準（オプション）。

**AI レビュー**: 計画承認前に `steps/common/review-flow.md` に従って実施（ルーティング判定の詳細は `steps/common/review-routing.md` 参照）。`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行。
**セミオートゲート判定**: `steps/construction/index.md` の「§2.4 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。


### 11. Unitブランチ作成【推奨】

`rules.git.unit_branch_enabled = true` かつ `gh_status=available` の場合、Unitブランチを作成。

```bash
git checkout -b "cycle/{{CYCLE}}/unit-{NNN}"
git push -u origin "cycle/{{CYCLE}}/unit-{NNN}"
gh pr create --draft --base "cycle/{{CYCLE}}" --title "[Draft][Unit {NNN}] {Unit名}" --body-file <一時ファイル>
```

Unit PRには `Closes #XX` を含めない（IssueクローズはサイクルPRで行う）。

---

**エクスプレスモード・Unit 選定・automation_mode 分岐の詳細は `steps/construction/index.md` §2 を参照**。

---
