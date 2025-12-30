# Unit 003 計画: サイクル名の自動検出と引き継ぎ

## 概要

セットアップからInceptionへサイクル名を自動で引き継ぐ機能を実装する。ブランチ名からサイクルバージョンを自動推測し、ユーザーの入力負担を軽減する。

## 関連バックログ

- `feature-auto-detect-version-from-branch.md` - ブランチ名からサイクルバージョンを自動推測
- `bug-cycle-name-not-passed-to-inception.md` - セットアップからInceptionへサイクル名が引き継がれない

## 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-prompt.md` | ブランチ名からバージョン抽出ロジック追加、完了メッセージ改善 |
| `prompts/package/prompts/setup.md` | ブランチ名からバージョン抽出ロジック追加、完了メッセージ改善 |
| `prompts/package/prompts/inception.md` | サイクル名自動認識ロジック追加 |

## Phase 1: 設計

### ドメインモデル設計

このUnitはドキュメント（プロンプトファイル）の修正のため、従来のドメインモデル設計は不要。代わりに以下の概念設計を行う：

**サイクル名決定の優先順位**:
1. ユーザーが明示的に指定した場合 → その値を使用
2. 現在のブランチ名が `cycle/vX.Y.Z` 形式の場合 → そこから抽出
3. `docs/cycles/` 配下の最新サイクルディレクトリを使用
4. 上記いずれも該当しない場合 → ユーザーに質問

**ブランチ名パターン**: `^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$`
- 厳密なセマンティックバージョニング形式のみ対応
- `cycle/v1.5.3-beta` などの拡張形式は対象外

### 論理設計

**setup-prompt.md / setup.md の変更**:

1. 「2. サイクルバージョンの決定」セクションに新規ステップ追加:
   - 2.1（新規）: ブランチ名からバージョン推測
   - 2.2（既存 2.1 から変更）: 既存サイクルの検出
   - 2.3（既存 2.2 から変更）: バージョン提案

2. 完了メッセージに `サイクル: {{CYCLE}}` を追加

**inception.md の変更**:

1. 「0. サイクル名の決定」ステップを「0. ブランチ確認」の直後に追加
2. 上記優先順位に基づくサイクル名決定ロジックを実装

## Phase 2: 実装

### 変更1: setup-prompt.md

セクション「2. サイクルバージョンの決定」に「2.1 ブランチ名からバージョン推測」を追加:

```markdown
#### 2.1 ブランチ名からバージョン推測

現在のブランチ名からサイクルバージョンを推測:

\`\`\`bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ $CURRENT_BRANCH =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  SUGGESTED_VERSION="v${BASH_REMATCH[1]}"
  echo "BRANCH_VERSION_DETECTED: ${SUGGESTED_VERSION}"
else
  echo "BRANCH_VERSION_NOT_DETECTED"
fi
\`\`\`

**判定**:
- **BRANCH_VERSION_DETECTED**: 検出されたバージョンを提案
  \`\`\`
  現在のブランチ名から v{X}.{Y}.{Z} を検出しました。
  このバージョンをサイクルバージョンとして使用しますか？
  1. はい、v{X}.{Y}.{Z} を使用する [推奨]
  2. いいえ、別のバージョンを選択する
  \`\`\`
  - **1 を選択**: 検出されたバージョンを使用（重複チェックへ）
  - **2 を選択**: 既存サイクルの検出へ進む
- **BRANCH_VERSION_NOT_DETECTED**: 既存サイクルの検出へ進む
```

完了メッセージに `サイクル: {{CYCLE}}` を追加。

### 変更2: prompts/package/prompts/setup.md

setup-prompt.md と同様の変更を適用。

### 変更3: prompts/package/prompts/inception.md

「### 0. ブランチ確認」の直後に「### 0.5 サイクル名の決定」を追加:

```markdown
### 0.5 サイクル名の決定【重要】

サイクル名を以下の優先順位で決定:

1. **ユーザーが明示的に指定した場合**: その値を使用
   - 例: 「サイクル v1.5.3 の Inception Phase を開始してください」

2. **現在のブランチ名から推測**:
   \`\`\`bash
   CURRENT_BRANCH=$(git branch --show-current)
   if [[ $CURRENT_BRANCH =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
     DETECTED_CYCLE="v${BASH_REMATCH[1]}"
     echo "CYCLE_DETECTED: ${DETECTED_CYCLE}"
   else
     echo "CYCLE_NOT_DETECTED_FROM_BRANCH"
   fi
   \`\`\`

3. **docs/cycles/ 配下の最新サイクルディレクトリを使用**:
   \`\`\`bash
   ls -d docs/cycles/*/ 2>/dev/null | sort -V | tail -1 | xargs basename
   \`\`\`

4. **上記いずれも該当しない場合**: ユーザーに質問
   \`\`\`
   サイクル名を特定できませんでした。
   どのサイクルで作業しますか？（例: v1.5.3）
   \`\`\`

**決定したサイクル名の確認**:
\`\`\`
サイクル {{CYCLE}} で Inception Phase を開始します。
よろしいですか？
\`\`\`
```

## テスト計画

このUnitはプロンプトファイルの修正のため、自動テストは不要。以下の手動確認を実施:

1. **ブランチ名からのバージョン検出**:
   - `cycle/v1.5.3` ブランチで setup.md を実行 → v1.5.3 が提案されること
   - `main` ブランチで setup.md を実行 → 既存フローが動作すること

2. **完了メッセージの確認**:
   - setup.md 完了時に `サイクル: vX.Y.Z` が表示されること

3. **inception.md のサイクル名認識**:
   - サイクルブランチで inception.md を読み込む → 自動でサイクル名が検出されること
   - 検出されない場合 → ユーザーに質問されること

## 見積もり

- Phase 1（設計）: この計画で設計完了
- Phase 2（実装）: 3ファイルの修正

## 承認依頼

この計画で進めてよろしいですか？
