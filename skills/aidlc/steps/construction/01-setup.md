# Construction Phase プロンプト

---

## プロジェクト情報

### 開発ルール

**共通ルールは `steps/common/rules-core.md` を参照**

- **プロンプト履歴管理【重要】**: `/write-history` スキルを使用して `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` にUnit単位で記録。詳細はスキルのSKILL.mdを参照。

- **気づき記録フロー【重要】**: 別Unitや新規課題の気づきはバックログに記録し、現在のUnit作業は中断しない。ただしIntentの「含まれるもの」に該当する場合は現サイクル内で処理する（`guides/backlog-management.md` 参照）。

- **Workaround実施時【重要】**: 暫定対応を行う場合、本質的な対応をバックログに記録し、コード内に `// TODO: workaround - see backlog (GitHub Issue を参照)` を残す。

- **割り込み対応フロー【重要】**:

  | 分類 | 判定基準 | 対応 |
  |------|----------|------|
  | 1 | 現在のサイクル・Unitと無関係 | バックログに記録 |
  | 2 | 関係あるが別Unitに属する | バックログ or 別Unit定義に追加 |
  | 3 | 現在のUnitに関係 | Unit定義追記 → 設計更新 → 実装 |

  **AIレビュー対象タイミング**: 計画ファイル承認前、設計レビュー前、コード生成後、テスト完了後

### フェーズの責務【重要】

**Phase 1（設計）**: ドメインモデル設計、論理設計、設計レビュー。探索的調査のためのコードは許可（成果物としてのコードは禁止）。
**Phase 2（実装）**: コード生成、テスト作成、統合とレビュー。
**設計レビューで承認を得るまでPhase 2に進んではいけない。**

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

### 6. セッション状態の復元

`.aidlc/cycles/{{CYCLE}}/construction/session-state.md` があれば読み込み、中断時点から再開。なければステップ7で復元。

### 7. 進捗状況確認【重要】

`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/` の全Unit定義ファイルを番号順に読み込み、「実装状態」セクションを確認。

### 8. バックログ確認

`gh_status=available` の場合、Unit定義の関連Issueの詳細と、バックログIssueを確認。

### 9. 対象Unit決定

| 状況 | 動作 |
|------|------|
| 進行中Unitあり | そのUnitを継続 |
| 実行可能Unit 0個 | 全Unit完了 |
| 実行可能Unit 1個 | 自動選択 |
| 実行可能Unit 複数 + `semi_auto` | 番号順で最初を自動選択 |
| 実行可能Unit 複数 + `manual` | ユーザーに選択提示 |

実行可能条件: 状態「未着手」かつ依存Unit全て「完了」or「取り下げ」。

### 9a. タスクリスト作成【必須】

**前提**: ステップ9で対象Unitが決定された場合のみ実行する。実行可能Unit 0個（全Unit完了）の場合はスキップ。

**【次のアクション】** 対象Unit決定後、`steps/common/task-management.md` の「Construction Phase: Unit開始時タスクテンプレート」に従い、Unitのタスクリストを作成してください。**タスクリスト未作成のまま次のステップに進んではいけない。**

### 10. セッションタイトル更新【オプション】

Unit確定後に `session-title` スキルを再実行（利用可能な場合のみ）。

### 11. Issueステータス更新

```bash
scripts/issue-ops.sh set-status <issue_number> in-progress
```

ブロック時は `blocked`、解除時は `in-progress` に更新。

### 12. 実行前確認と完了条件の提示【重要】

計画ファイル `.aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md` を作成し、完了条件チェックリストを含めてユーザーに承認を求める。

**完了条件の抽出**: Unit定義「責務」セクション（必須）+ 関連Issueの受け入れ基準（オプション）。

**AIレビュー**: 計画承認前に `review-flow.md` に従って実施。
**セミオート**: フォールバック条件非該当なら自動承認。


### 13. Unitブランチ作成【推奨】

`rules.git.unit_branch_enabled = true` かつ `gh_status=available` の場合、Unitブランチを作成。

```bash
git checkout -b "cycle/{{CYCLE}}/unit-{NNN}"
git push -u origin "cycle/{{CYCLE}}/unit-{NNN}"
gh pr create --draft --base "cycle/{{CYCLE}}" --title "[Draft][Unit {NNN}] {Unit名}" --body-file <一時ファイル>
```

Unit PRには `Closes #XX` を含めない（IssueクローズはサイクルPRで行う）。

---

## エクスプレスモード検出

`express_enabled=true` かつ全Unitの適格性が `eligible` の場合に適用。

| depth_level | 動作 |
|-------------|------|
| `minimal` | Phase 1（設計）スキップ → Phase 2のコード生成に直行 |
| `standard` / `comprehensive` | Phase 1から通常実行 |

複数Unit時は通常のUnit選定ルール（ステップ9）を適用。全Unit完了後にOperationsへ遷移。

---
