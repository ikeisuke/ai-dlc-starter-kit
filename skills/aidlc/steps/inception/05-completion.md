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

```bash
skills/aidlc/scripts/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "Inception Phase完了（エクスプレスモード）" \
    --content "エクスプレスモードによるInception Phase完了。Construction Phaseに自動遷移。"
```

### 4. Squash（コミット統合）【オプション】

「完了時の必須作業」のステップ6と同じ手順を実行する。

- `squash:success` の場合: ステップ5をスキップ
- `squash:skipped` の場合: ステップ5に進む
- `squash:error` の場合: commit-flow.md のエラーリカバリ手順に従い、ステップ5に進む

### 5. Gitコミット

ステップ4で squash を実行した場合（`squash:success`）、コミットは既に完了しています。`git status` で確認のみ行ってください。

squash を実行していない場合は、`steps/common/commit-flow.md` の「Inception Phase完了コミット」手順に従ってください。

**コミット失敗時のエラーハンドリング**:

コミットが失敗した場合、以下のメッセージを表示し、`commit-flow.md` の手順に沿った手動コミットを案内する。

```text
【エラー】コミットの作成に失敗しました。
commit-flow.md の「Inception Phase完了コミット」手順に従い、手動でコミットを作成してください。
```

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
skills/aidlc/scripts/cycle-label.sh "{{CYCLE}}"

# 関連Issueへのサイクルラベル一括付与
skills/aidlc/scripts/label-cycle-issues.sh "{{CYCLE}}"
```

**出力例**:

```text
label:cycle:v1.8.0:created
issue:81:labeled:cycle:v1.8.0
issue:72:labeled:cycle:v1.8.0
```

**注**: Issue番号が見つからない場合は出力なしで正常終了する。

### 2. iOSバージョン更新【project.type=iosの場合のみ】

`.aidlc/config.toml` の `[project].type` が `ios` の場合のみ実行。詳細手順は `{{aidlc_dir}}/guides/ios-version-update.md` を参照。

### 3. 履歴記録
`.aidlc/cycles/{{CYCLE}}/history/inception.md` に履歴を追記（write-history.sh使用）

### 4. 意思決定記録【オプション】

Inception Phase 中に重要な意思決定（AIが複数の選択肢を提示し、ユーザーが選択した場面）があった場合、`.aidlc/cycles/{{CYCLE}}/inception/decisions.md` に記録する。

**記録対象**:
- 2つ以上の明確な選択肢からユーザーが選択した場面
- 技術選定、設計方針、スコープ決定などの重要な判断

**記録対象外**:
- Yes/No の単純な承認確認
- 手続き的な選択（ブランチ方式、ファイル名等）

**手順**:
1. セッション中に発生した意思決定を振り返る
2. 記録対象に該当するものがあれば、テンプレート（`skills/aidlc/templates/decision_record_template.md`）に従い `decisions.md` を作成
3. 記録IDは連番（DR-001, DR-002, ...）
4. 記録対象がなければスキップ（ファイル未作成で問題なし）

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

1. Writeツールで一時ファイルを作成（内容: PR本文）:

```text
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
[Unit定義ファイルから一覧を生成]

## Closes
[Unit定義ファイルの関連Issueから抽出]
- Closes #[Issue番号1]
- Closes #[Issue番号2]
```

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

**注意**: ステップ6でsquashを実行した場合（`squash:success`）、コミットは既に完了しています。`git status`で確認のみ行ってください。

squashを実行していない場合は、`steps/common/commit-flow.md` の「Inception Phase完了コミット」手順に従ってください。

### 8. コンテキストリセット提示【必須】

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、コンテキストリセット提示をスキップし、Construction Phaseを自動開始する。`automation_mode=manual` の場合は以下の従来フローを実行する。

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、以下のメッセージを**必ず提示**してください。デフォルトはリセットです。

**セッションサマリの生成**: メッセージ提示前に、AIが以下の情報を収集してセッションサマリを生成してください:
1. サイクル番号（{{CYCLE}}）と「Inception Phase」
2. 現在のブランチ名（`git branch --show-current`）とPR/コミット状態（`git log --oneline -1` でコミット確認、ghが利用可能な場合は `gh pr view --json state,url 2>/dev/null` でPR状態確認）
3. 次に実行すべきアクション

````markdown
---
## Inception Phase 完了

コンテキストをリセットしてConstruction Phaseを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: {{CYCLE}} / Inception Phase
- **リポジトリ**: [ブランチ名]、[コミット済み/ドラフトPR作成済み等の状態]
- **次のアクション**: Construction Phaseを開始

**次のステップ**:
- Claude Code: `/aidlc construction` と指示
- その他: `steps/construction/01-setup.md` からステップファイルを順に読み込み
---
````
