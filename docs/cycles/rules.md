# 追加ルール

このファイルは、AI-DLC Starter Kit プロジェクト固有の追加ルールや制約を記載します。

**重要**: セットアップ完了後、このファイルをプロジェクトに合わせてカスタマイズしてください。

---

## メタ開発の意識【最重要】

このプロジェクトは「AI-DLCスターターキットを使って、AI-DLCスターターキット自体を開発している」というメタ構造を持つ。

**この意識が薄れると起きる問題**:
- スターターキットの改善なのか、利用プロジェクトの実装なのか混同する
- テンプレートの変更が「次回セットアップ時に反映」されることを忘れる
- 自分自身のプロンプトを編集していることの影響範囲を見誤る
- **`docs/aidlc/` を直接編集してしまい、Operations Phase の rsync で変更が消える**

**常に確認すべきこと**:
- 今触っているファイルは「ツール側（`prompts/`）」か「成果物側（`docs/aidlc/`, `docs/cycles/`）」か
- **`docs/aidlc/` は `prompts/package/` の rsync コピーである（直接編集禁止）**
- プロンプト・テンプレートの修正は必ず `prompts/package/` を編集すること
- 変更が即時反映されるか、次回セットアップ時に反映されるか

**スターターキットのパス参照**:
- メタ開発時（同一リポジトリ）: `prompts/` がスターターキット本体
- 外部プロジェクトから参照時: `$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/prompts/`

---

## カスタムワークフロー

### Operations Phase 完了時の必須作業【重要】

このプロジェクトはメタ開発のため、Operations Phase のステップ6（リリース準備）の前に以下を実行すること：

```
/upgrading-aidlc
```

**理由**: `prompts/package/` で変更したプロンプト・テンプレートを `docs/aidlc/` に反映するため。

### バージョンファイル更新【重要】

`/upgrading-aidlc` 実行後、CHANGELOG更新の前にリポジトリルートで以下を実行すること：

```bash
bin/update-version.sh --version {{CYCLE}}
```

dry-runで事前確認する場合:

```bash
bin/update-version.sh --version {{CYCLE}} --dry-run
```

**理由**: AI-DLCスターターキット自体のリリース時にバージョン番号を更新するため。

---

## コーディング規約

### コマンド置換（`$()`）使用禁止【重要】

すべてのBashコマンド実行において、`$()` およびバッククォート（`` ` ``）によるコマンド置換を使用しない。

**理由**:
- プロンプトファイル内: AIエージェントがプロンプトを読み込む際に意図せず展開・実行される可能性がある
- gitコマンド等の実行時: ツール出力に `$()` が表示され、ユーザーの混乱を招く

**対応方法**:
- 動的な値はAIエージェントがコンテキスト変数から直接置換する（例: `{{CYCLE}}`, `{{project.name}}`）
- コマンド出力が必要な場合は別ステップで実行し、結果を変数として保持する
- 複数行のgitコミットメッセージは `-m` フラグを複数回使用する（例: `git commit -m "title" -m "body"`）

（例）
- 命名規則: lowerCamelCase、UPPER_SNAKE_CASE等
- フォーマットルール
- コメント記述ルール

---

## 使用ライブラリ・フレームワークの制約

使用するライブラリやフレームワークの制約を記載してください。

（例）
- 使用禁止ライブラリ
- 推奨ライブラリ
- バージョン制約

---

## セキュリティ要件

セキュリティに関する要件を記載してください。

（例）
- ユーザー入力は必ずバリデーション
- APIキーは環境変数で管理
- 認証・認可の実装方針

---

## パフォーマンス要件

パフォーマンスに関する要件を記載してください。

（例）
- レスポンスタイム目標値
- 負荷分散の考慮
- キャッシュ戦略

---

## AIレビューツールの使用ルール【重要】

AI-DLCプロンプトで「AIレビュー」を実行する際は、以下のルールに従うこと。

### 使用するスキル

**レビュー種別に対応するSkillを使用する**:

| レビュー種別 | Skills呼び出し |
|-------------|----------------|
| code | `skill="reviewing-code"` |
| architecture | `skill="reviewing-architecture"` |
| security | `skill="reviewing-security"` |

### 呼び出し方法

```text
skill="reviewing-[type]", args="[レビュー対象] 優先ツール: [codex|claude|gemini]"
```

- レビュー種別はreview-flow.mdの「レビュー種別の決定」に従い選択する
- 優先ツールは `docs/aidlc.toml` の `[rules.reviewing].tools` の先頭を使用する
- ツール選択の最終決定はスキル内部の責務（優先ツールはヒントのみ）

---

## Codex PRレビューの再実行ルール【重要】

このリポジトリではCodex（GitHub連携）によるPR自動レビューが有効になっている。

**再レビューのトリガー**: 修正をプッシュしただけでは再レビューは実行されない。修正プッシュ後に以下のコメントをPRに投稿すること：

```bash
gh pr comment {PR番号} --body "@codex review"
```

**タイミング**: レビュー指摘への修正コミットをプッシュした直後に実行する。

---

## 開発者向けドキュメント

AI-DLCスターターキット自体の開発・保守に関するドキュメント:

- **依存コマンド追加手順**: `docs/development/dependency-commands.md`

---

## Worktree運用ルール【重要】

このプロジェクトでは `.worktree/dev` で開発を行う。

### ブランチ運用フロー

1. **サイクル開始時**: dev worktree で `cycle/vX.X.X` ブランチを作成して作業
2. **PR作成・マージ**: dev worktree からpush → PRマージ
3. **マージ後**: `bin/post-merge-sync.sh` を実行（main pull + detached HEAD化 + ブランチ削除を自動化）
4. **次サイクル開始時**: dev worktree で最新の `origin/main` から新ブランチを作成

```bash
# マージ後（dev worktreeで実行）
bin/post-merge-sync.sh

# dry-runで事前確認する場合
bin/post-merge-sync.sh --dry-run

# リモートブランチ削除の確認をスキップする場合
bin/post-merge-sync.sh --yes

# 次サイクル開始（dev worktreeで実行）
git fetch origin
git checkout -b cycle/vX.X.X origin/main
```

### 注意事項

- dev worktree から `main` への checkout は不可（メインリポジトリが使用中のため）
- main の更新は `bin/post-merge-sync.sh` が親リポジトリ側で自動実行する
- `cycle/` プレフィックス以外のブランチは削除対象外（安全制約）

---

## その他のプロジェクト固有制約

その他、プロジェクト固有の制約があればここに記載してください。
