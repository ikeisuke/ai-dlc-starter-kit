# 既存コード分析 - v1.16.3

## 1. read-config.sh (#221)

**現在のファイル**: `prompts/package/bin/read-config.sh`

### 現状
- 4階層マージ対応済み（defaults.toml → home config → project config → local config）
- 単一キーの取得のみサポート（`read-config.sh <key> [--default <value>]`）
- `defaults.toml` は存在するが、全キーを網羅していない

### defaults.toml の現在のキー
```
rules.squash.enabled, rules.jj.enabled, rules.feedback.enabled,
rules.backlog.mode, rules.reviewing.mode, rules.reviewing.tools,
rules.worktree.enabled, rules.history.level, rules.release.changelog,
rules.release.version_tag, rules.unit_branch.enabled, rules.linting.markdown_lint,
rules.size_check.enabled, rules.size_check.max_bytes, rules.size_check.max_lines,
rules.size_check.target_pattern, rules.commit.ai_author_auto_detect
```

### 変更が必要な箇所
- `read-config.sh`: `--keys` オプション追加（複数キー一括取得、key:value形式出力）
- `defaults.toml`: 不足キーの追加（`rules.commit.ai_author` 等）

---

## 2. コンテキストリセット指示 (#209)

**関連ファイル**:
- `prompts/package/prompts/inception.md` (790-806行)
- `prompts/package/prompts/construction.md` (816-832行, 836-866行)
- `prompts/package/prompts/operations.md` (958-991行)
- `prompts/package/prompts/common/context-reset.md`

### 現状
- 各Phase/Unit完了時にリセットメッセージを提示する指示が存在
- 「**必ず提示**」「デフォルトはリセットです」と記載済み
- しかし長いセッション中にAIがこの指示を無視するケースが発生

### 問題の原因（推定）
- リセット指示がプロンプト末尾に記載されており、長いコンテキストで埋もれる
- Unit完了→次Unit選択の流れが連続的で、リセットステップが飛ばされやすい

### 変更が必要な箇所
- 完了チェックリストにリセット提示を番号付き必須ステップとして追加
- リセット指示の位置・強調を強化

---

## 3. リセット告知のサマリ追加 (#220)

**関連ファイル**: #209 と同じリセット箇所

### 現状
- リセット告知は「コンテキストをリセットしてXXXを開始してください」程度の定型文
- 完了作業の要約、リポジトリ状態、次のアクションの情報なし

### 変更が必要な箇所
- 各リセットメッセージテンプレートにサマリ生成指示を追加
- サマリ内容: 完了作業の要約、リポジトリ状態（ブランチ、未マージPR等）、次アクション

---

## 4. ブランチ作成方式の設定固定化 (#214)

**関連ファイル**:
- `prompts/package/prompts/inception.md` (ステップ7: 280-323行)
- `prompts/package/config/defaults.toml`

### 現状
- ステップ7でmain/masterの場合に毎回3択（worktree/branch/そのまま）を質問
- `[rules.worktree].enabled` はworktree選択肢の表示制御のみ
- ブランチ方式自体を固定する設定なし

### 変更が必要な箇所
- `defaults.toml`: `[rules.branch].mode = "ask"` を追加
- `inception.md` ステップ7: `[rules.branch].mode` の値に応じた分岐を追加
  - `branch`: 質問なしでブランチ作成
  - `worktree`: 質問なしでworktree作成
  - `ask`: 現行動作（質問する）

---

## 5. セルフレビューフォールバック (#216)

**関連ファイル**:
- `prompts/package/prompts/common/review-flow.md` (ステップ6: 342-363行)

### 現状
- Skills利用不可時の処理（ステップ6）:
  - `mode = "required"`: 「スキップして人間承認へ」または「処理中断」の2択
  - `mode = "recommend"`: 自動的に人間レビューフローへ
- セルフレビューの選択肢なし

### 変更が必要な箇所
- `review-flow.md` ステップ6にセルフレビューオプションを追加
- セルフレビュー実行時のレビュー観点・出力フォーマットを定義
- 履歴記録にセルフレビューであることを明記
