## Unit完了時の必須作業【重要】

### 1. 完了条件の確認【必須】

計画ファイル（`.aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`）の「完了条件チェックリスト」を確認。

- **すべて達成**: 次のステップへ（`semi_auto` なら自動承認）
- **未達成項目あり**: ユーザーに説明し、「未達成のまま完了としますか？」と確認。承認時は例外承認として履歴に記録
- **チェックリストなし**: 警告表示してスキップ

### 1b. 残課題の集約提示【必須】

Unit完了前に、レビューサマリからOUT_OF_SCOPE項目を集約し残課題として可視化する。

**処理フロー**:

1. review-summary.mdのパスを構築: `.aidlc/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md`
2. ファイル存在確認:
   - **存在しない場合**: 「⚠ レビューサマリなし（レビュー未実施またはフロー異常の可能性）」と警告表示してスキップ。後続のステップ3（AIレビュー実施確認）で実施状況を確認すること
3. ファイルを読み込み、全Setの指摘一覧テーブルから「対応」列が `OUT_OF_SCOPE(` で始まる行を抽出し、「バックログ」列も併せて取得

**OUT_OF_SCOPE項目がある場合**:

```text
【残課題の集約提示】

| # | 内容 | 対応理由 | バックログ |
|---|------|---------|-----------|
| 1 | [指摘内容] | [OUT_OF_SCOPE理由] | [#NNN / PENDING_MANUAL / SECURITY_PRIVATE] |

合計: {N}件
```

バックログ列が `PENDING_MANUAL` の項目がある場合: `⚠ 未登録の残課題があります。手動でバックログ登録を確認してください。`

**OUT_OF_SCOPE項目がない場合**: `【残課題の集約提示】残課題なし`

**注意**: このステップの責務は可視化のみ。バックログ登録はreview-flow.md側で完了済みの前提。

### 2. 設計・実装整合性チェック【必須】

設計ドキュメント（ドメインモデル・論理設計）が存在する場合、実装との整合性を確認。

**スキップ条件**: 設計ファイル未存在、「設計省略」明記、`depth_level=minimal`。

**チェック項目**: エンティティ実装、インターフェース実装、依存関係、設計ドキュメント更新。

**乖離がある場合**: 実装修正 / 設計更新 / 乖離許容（理由記録）の3択。

### 3. AIレビュー実施確認【必須】

Phase 2の実装レビュー（統合とレビュー）が実施されたか、履歴ファイルで確認。

```bash
HISTORY_FILE=".aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md"
if [ -f "$HISTORY_FILE" ]; then
    awk 'BEGIN{RS="---"} /AIレビュー完了/ && /対象タイミング.*統合とレビュー/{found=1; exit} END{if(found) print "IMPLEMENTED"; else print "NOT_IMPLEMENTED"}' "$HISTORY_FILE"
else
    echo "FILE_NOT_FOUND"
fi
```

未実施の場合: 今からAIレビュー実施（推奨）/ スキップ（理由記録）の2択。

### 3b. 意思決定記録の参照確認【Construction Phase固有】

このUnitの作業中に重要な意思決定（2つ以上の明確な選択肢からユーザーが選択した場面）が発生した場合、`steps/inception/05-completion.md` の「4. 意思決定記録」セクションの手順に従い記録すること。Construction Phase では既存の `decisions.md` への追記を行う。

- **意思決定が発生した場合**: `.aidlc/cycles/{{CYCLE}}/inception/decisions.md` に追記（連番IDを継続）。ファイル未存在の場合はテンプレート（`templates/decision_record_template.md`）から新規作成
- **意思決定が発生しなかった場合**: 「意思決定記録: 対象なし」と明示的に報告してスキップ

### 4. Unit定義ファイルの「実装状態」を更新

状態を「完了」に、完了日を現在日付に更新。

### 5. 履歴記録

`/write-history` スキルで履歴追記。

### 6. Markdownlint実行

```bash
scripts/run-markdownlint.sh {{CYCLE}}
```

`markdown_lint=false`（デフォルト）ならスキップ。エラーあれば修正。

### 7. Squash（コミット統合）【オプション】

> **順序制約**: コミットが存在しない状態でPR作成に進んではいけない。

**【次のアクション】** `steps/common/commit-flow.md` の「Squash統合フロー」を読み込んで実行。

- `squash:success` → ステップ8スキップ
- `squash:skipped` → ステップ8へ
- `squash:error` → エラーリカバリ後ステップ8へ

### 8. Gitコミット

squash実行済み（`squash:success`）なら `git status` 確認のみ。未実行なら `commit-flow.md` の「Unit完了コミット」に従う。

### 9. Unit PR作成・マージ【推奨】

Unitブランチで作業した場合、サイクルブランチへのPR作成/マージ。`semi_auto` なら自動実行。

**既存ドラフトPR**: Ready化 → タイトル更新（`[Draft]`削除） → 本文更新
**新規PR**: `gh pr create --base "cycle/{{CYCLE}}" --title "[Unit {NNN}] {Unit名}" --body-file <一時ファイル>`

**レビューサマリ**: `.aidlc/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md` が存在すればPR本文末尾に追記。

**マージ**: `gh pr merge --squash --delete-branch` → サイクルブランチに復帰。

Unit PRには `Closes #XX` を含めない（IssueクローズはサイクルPRで行う）。

### 10. コンテキストリセット提示【必須】

`semi_auto` の場合はスキップし次のUnit/Phaseを自動開始。`manual` の場合は以下を提示。

**次のUnitあり**: コンテキストリセットして `/aidlc construction` で再開を案内。
**全Unit完了**: Construction Phase完了、`/aidlc operations` でOperations Phaseを案内。

セッションサマリ（サイクル番号、完了Unit、ブランチ/PR状態、次のアクション）を含める。

---

## バックトラック

### Inceptionに戻る場合

`/aidlc inception` でInception Phaseのバックトラック手順に従う。

### Operations Phaseからバグ修正で戻った場合

1. Unit定義の実装状態を「進行中」に変更
2. バグ修正（設計バグ→設計修正→レビュー→実装、実装バグ→コード修正→テスト追加）
3. 実装状態を「完了」に戻す → 履歴記録 → コミット
4. `/aidlc operations` でOperations Phaseに戻る
