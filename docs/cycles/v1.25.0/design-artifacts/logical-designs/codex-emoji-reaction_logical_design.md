# 論理設計: Codex PRレビュー絵文字リアクション検出

## 概要

`docs/cycles/rules.md` の「PRマージ前レビューコメント確認」セクション（6.6.7相当）のステップ3に「c. 絵文字リアクション判定」を追加する論理設計。

## 変更箇所

### rules.md の変更

#### 1. Codexボットアカウント定数の追加

「Codex PRレビューの再実行ルール」セクションの冒頭付近に、Codexボットアカウントの定数を追加:

```markdown
**Codexボットアカウント**: `chatgpt-codex-connector[bot]`
```

#### 2. ステップ3への「c. 絵文字リアクション判定」追加

既存のステップ3（未対応指摘の判定）の b（未返信コメント判定）の後に、c（絵文字リアクション判定）を追加:

**c. 絵文字リアクション判定**:

手順:

1. `@codex review` を含むコメントを全件取得し、最新1件を特定:

```bash
gh api --paginate repos/{owner}/{repo}/issues/{PR番号}/comments \
  --jq '[.[] | select(.body | test("@codex review"))]' \
  | jq -s 'add | sort_by(.created_at) | last | .id'
```

**注**: `--paginate` はページ単位で `--jq` を評価するため、`jq -s` で全ページを集約してから最新を選ぶ。

2. API失敗時（コメント取得） → 「⚠ コメント取得に失敗しました」と表示し、既存のエラーハンドリングテーブル（rules.md）に従い手動確認を誘導

3. コメントIDが取得できない場合（`@codex review` コメントが存在しない） → リアクション判定をスキップ（a/b判定のみで続行）

4. コメントのリアクションを取得:

```bash
gh api repos/{owner}/{repo}/issues/comments/{comment_id}/reactions \
  --jq '[.[] | select(.user.login == "chatgpt-codex-connector[bot]")] | map({content: .content})'
```

5. API失敗時（リアクション取得） → 「⚠ リアクション取得に失敗しました。コメントベースの判定結果のみで続行します」と表示し、a/b判定のみで続行

6. 判定（👍優先）:
   - `+1` リアクションが存在（👀の有無に関わらず） → 「✓ Codex PRレビュー: 承認済み（👍）」と表示
   - `eyes` リアクションのみ → 「ℹ Codex PRレビュー: レビュー進行中（👀）。完了を待つか、マージに進むか選択してください」と表示
   - Codexボットからのリアクションなし → リアクション判定をスキップ（a/b判定のみで続行）

#### 3. ステップ4への統合

既存のステップ4（判定結果に応じた処理）の判定ロジックを拡張:

- **未対応指摘なし**: 既存条件（a/bともにクリア）に加え、cが `reviewing` の場合は情報表示を追加
- **未対応指摘あり**: 既存条件に変更なし。cの結果は未対応指摘の有無に影響しない（情報表示のみ）

### operations-release.md の変更

#### 7.13 サブステップ2

現行の `gh:available` 条件チェック箇所に注記を追加:

```markdown
**注**: プロジェクト固有ルール（`docs/cycles/rules.md`）にCodex PRレビューの絵文字リアクション検出が定義されている場合、サブステップ1で自動的に実行されます。
```

この注記のみ追加。ロジック本体は `rules.md` 側に集約する（operations-release.md はルール参照のフレームワーク）。

## API仕様

### Issues Comments API

```
GET /repos/{owner}/{repo}/issues/{PR番号}/comments
```

レスポンス: `[{id, body, user: {login}, created_at, ...}]`

### Reactions API

```
GET /repos/{owner}/{repo}/issues/comments/{comment_id}/reactions
```

レスポンス: `[{content, user: {login}, ...}]`

`content` の値: `+1`, `-1`, `laugh`, `confused`, `heart`, `hooray`, `rocket`, `eyes`

## エラーハンドリング

| エラーパターン | 対応 |
|-------------|------|
| コメント取得API失敗（認証/レート制限等） | 既存のエラーハンドリングテーブル（rules.md）に従い手動確認を誘導 |
| `@codex review` コメントが存在しない | リアクション判定をスキップ。a/b判定のみで続行 |
| リアクションAPI呼び出し失敗（認証/レート制限等） | 警告表示し、a/b判定のみで続行（既存のエラーハンドリングテーブルに準拠） |
| Codexボットからのリアクションなし | リアクション判定をスキップ |
| Codexボットlogin不一致（将来のBot名変更等） | リアクションなしと同様に扱い、a/b判定のみで続行 + 警告表示 |

## 既存フローへの影響

- CHANGES_REQUESTED判定（a）: 変更なし
- 未返信コメント判定（b）: 変更なし
- ステップ1-2（API呼び出し）: 変更なし
- ステップ4（判定結果表示）: cの結果による情報表示を追加（判定ロジックへの影響は「reviewing」時の追加表示のみ）
