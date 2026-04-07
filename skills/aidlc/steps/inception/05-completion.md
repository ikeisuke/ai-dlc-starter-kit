# Inception Phase - 完了処理

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `.aidlc/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべての成果物作成（Intent、ユーザーストーリー、Unit定義）
- 技術スタック決定（greenfieldの場合）
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）

---

## エクスプレスモード完了処理【ステップ4bでエクスプレスモード有効時のみ】

ステップ4b でエクスプレスモードが有効と判定された場合、以下の簡略完了処理を実行してから Construction Phase に自動遷移する。エクスプレスモードが無効の場合はこのセクションをスキップし、「完了時の必須作業」セクションへ進む。

### 1. progress.md 更新

- `depth_level=minimal` の場合: ステップ5（PRFAQ）を「スキップ」に更新する（Depth Level仕様でスキップ可能のため）
- `depth_level=standard/comprehensive` の場合: ステップ5（PRFAQ）はステップ4bの後に実行され、完了後にこのセクションに到達するため、progress.md で「完了」を確認するのみ

### 2. サイクルラベル作成・Issue紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する。

### 3. 履歴記録

`/write-history` スキルで記録（`--step "Inception Phase完了（エクスプレスモード）"`）。

### 4-5. Squash・Gitコミット

「完了時の必須作業」のステップ6（Squash）・ステップ7（Gitコミット）と同じ手順を実行する。squash結果に応じてコミットをスキップまたは実行。

**コミット失敗時**: `commit-flow.md` の手順に沿った手動コミットを案内する。

### 6. Construction Phase への自動遷移

コンテキストリセット提示を**スキップ**し、Construction Phase に自動遷移する。

```text
【エクスプレスモード】Inception Phase 完了。Construction Phase に自動遷移します。
```

SKILL.md の引数ルーティングに従い、Construction Phase を開始する（`/aidlc construction` を実行）。`automation_mode` の設定はそのまま引き継がれる。

**注意**: エクスプレスモードでの Construction Phase 遷移時、construction.md の「最初に必ず実行すること」は通常通り実行する（サイクル存在確認、進捗状況確認等）。Phase 1（設計）の扱いは depth_level に従う:
- `depth_level=minimal`: Phase 1 スキップ可能（construction.md の既存仕様に従う）
- `depth_level=standard/comprehensive`: Phase 1 は通常実行（設計省略しない）

---

## 完了時の必須作業【重要】

### 1. サイクルラベル作成・Issue紐付け

`gh_status` を参照する。

**判定と処理**:

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、スキップします」と表示してスキップ。

`gh_status` が `available` の場合:

```bash
# サイクルラベル確認・作成（cycle-label.shスクリプトを使用）
scripts/cycle-label.sh "{{CYCLE}}"

# 関連Issueへのサイクルラベル一括付与
scripts/label-cycle-issues.sh "{{CYCLE}}"
```

**出力例**:

```text
label:cycle:v1.8.0:created
issue:81:labeled:cycle:v1.8.0
issue:72:labeled:cycle:v1.8.0
```

**注**: Issue番号が見つからない場合は出力なしで正常終了する。

### 2. iOSバージョン更新【project.type=iosの場合のみ】

`.aidlc/config.toml` の `[project].type` が `ios` の場合のみ実行。詳細手順は `guides/ios-version-update.md` を参照。

### 3. 履歴記録
`/write-history` スキルで `.aidlc/cycles/{{CYCLE}}/history/inception.md` に追記。

### 4. 意思決定記録【必須チェック】

**このステップのスキップは禁止。記録対象の有無を必ず確認すること。記録対象がなければスキップ（ファイル未作成で問題なし）だが、確認自体を省略してはいけない。**

Inception Phase 中に重要な意思決定（AIが複数の選択肢を提示し、ユーザーが選択した場面）があった場合、`.aidlc/cycles/{{CYCLE}}/inception/decisions.md` に記録する。

**記録対象**:
- 2つ以上の明確な選択肢からユーザーが選択した場面
- 技術選定、設計方針、スコープ決定などの重要な判断

**記録対象外**:
- Yes/No の単純な承認確認
- 手続き的な選択（ブランチ方式、ファイル名等）

**手順**:
1. セッション中に発生した意思決定を振り返る
2. 記録対象に該当するものがあれば、テンプレート（`templates/decision_record_template.md`）に従い `decisions.md` を作成
3. 記録IDは連番（DR-001, DR-002, ...）
4. 記録対象がなければ「意思決定記録: 対象なし」と明示的に報告してスキップ（ファイル未作成で問題なし）

### 5. ドラフトPR作成【推奨】

GitHub CLIが利用可能な場合、mainブランチへのドラフトPRを作成する（ステップ14で確認した `gh_status` を参照）。

**判定**:
- **`gh_status` が `available` 以外**: 以下を表示してスキップ
  ```text
  GitHub CLIが利用できないため、ドラフトPR作成をスキップします。
  必要に応じて、後で手動でPRを作成してください。
  ```
- **`gh_status` が `available`**: 既存PR確認に進む

**既存PR確認**:

1. 事前にBashで `git branch --show-current` を実行し、現在のブランチ名を取得
2. 取得したブランチ名を使って以下を実行:

```bash
gh pr list --head "<取得したブランチ名>" --state open
```

- **既存PRあり**: 既存PRのURLを表示し、新規作成をスキップ
- **既存PRなし**: ユーザーに確認

**ユーザー確認**:
```text
ドラフトPRを作成しますか？

ドラフトPRを作成すると：
- 進捗がGitHub上で可視化されます
- 複数人での並行作業が容易になります
- Unit単位でのレビューが可能になります

1. はい - ドラフトPRを作成する
2. いいえ - スキップする（後で手動で作成可能）
```

**PR作成実行**（ユーザーが「はい」を選択した場合）:

**関連Issue番号の抽出**:
Unit定義ファイルの「関連Issue」セクションから、全Issue番号を抽出し、`Closes #XX` 形式でリスト化します。

1. Writeツールで一時ファイルを作成（テンプレート: `templates/inception_pr_body_template.md` を参照）

2. 以下を実行:

```bash
gh pr create --draft \
  --title "サイクル {{CYCLE}}" \
  --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**注意**: PRがmainにマージされると、`Closes #XX` に記載されたIssueは自動的にクローズされます。

**成功時**:
```text
ドラフトPRを作成しました：
[PR URL]

このPRはOperations Phase完了時にReady for Reviewに変更されます。
```

### 6. Squash（コミット統合）【オプション】

**【次のアクション】** `steps/common/commit-flow.md` の「Squash統合フロー」を読み込んで、Inception Phase完了squashの手順に従ってください。

- `squash:success` の場合: ステップ7をスキップ
- `squash:skipped:no-commits` の場合: ステップ7に進む
- `squash:error` の場合: commit-flow.mdのエラーリカバリ手順に従う。リカバリ後、ステップ7（通常コミット）に進む

### 7. Gitコミット

`squash:success` なら `git status` 確認のみ。それ以外は `commit-flow.md` の「Inception Phase完了コミット」に従う。

### 8. 完了サマリ出力【必須】

以下の完了サマリを出力する。※ 情報源にない内容は出力しない。

```text
【Inception Phase 完了サマリ】
- サイクル: {{CYCLE}}
- 作成した成果物:
  - Intent: [intent.mdの概要（1行）]
  - ユーザーストーリー: [ストーリー数]件
  - Unit定義: [Unit数]件（[Unit名の一覧]）
- 技術スタック: [決定内容。該当しなければ「該当なし」]
- 関連Issue: [Issue番号の一覧。なければ「なし」]
- 残課題・バックログ: [登録したバックログIssue番号。なければ「なし」]
```

### 9. コンテキストリセット提示【必須】

`semi_auto`: スキップしConstruction Phaseを自動開始。`manual`: ユーザーの明示的な連続実行指示（「続けて」等）がない限り、以下を実行（デフォルトはリセット）。

セッションサマリ（サイクル番号、ブランチ/PR状態、次のアクション）を収集し、テンプレート（`templates/context_reset_template.md`）に従い出力する。
