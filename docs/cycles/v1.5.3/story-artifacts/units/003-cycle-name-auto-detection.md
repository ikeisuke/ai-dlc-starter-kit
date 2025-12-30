# Unit: サイクル名の自動検出と引き継ぎ

## 概要
セットアップからInceptionへサイクル名を自動で引き継ぐ機能を実装する。ブランチ名からサイクルバージョンを自動推測し、ユーザーの入力負担を軽減する。

## 含まれるユーザーストーリー
- ストーリー 1.3: サイクル名の自動引き継ぎ
- ストーリー 2.3: ブランチ名からのバージョン自動推測

## 責務
- ブランチ名 (cycle/vX.Y.Z) からバージョンを抽出
- setup.md完了メッセージにサイクル名を含める
- inception.md でサイクル名を自動認識

## 境界
- バージョン形式のバリデーションは厳密に行わない（セマンティックバージョニング形式のみ対応）
- 既存のサイクルとの重複チェックは別途実施

## 依存関係

### 依存する Unit
- なし

### 外部依存
- git (ブランチ名取得)

## 非機能要件（NFR）
- **パフォーマンス**: git branch コマンドの実行速度に依存
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: git リポジトリ内でのみ動作

## 技術的考慮事項

### ブランチ名からのバージョン抽出
```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ $CURRENT_BRANCH =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  SUGGESTED_VERSION="v${BASH_REMATCH[1]}"
  echo "BRANCH_VERSION_DETECTED: ${SUGGESTED_VERSION}"
else
  echo "BRANCH_VERSION_NOT_DETECTED"
fi
```

### 完了メッセージの改善
```markdown
Inception Phase を開始するには、以下のプロンプトを読み込んでください：
docs/aidlc/prompts/inception.md

サイクル: {{CYCLE}}
```

### inception.md での認識
1. ユーザーが明示的に指定した場合、その値を使用
2. 現在のブランチ名が cycle/vX.Y.Z 形式の場合、そこから抽出
3. docs/cycles/ 配下の最新サイクルディレクトリを使用
4. 上記いずれも該当しない場合、ユーザーに質問

## 対象ファイル
- prompts/setup-prompt.md
- prompts/package/prompts/setup.md
- prompts/package/prompts/inception.md

## 実装優先度
High

## 見積もり
ブランチ名抽出ロジックと完了メッセージの修正

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-30
- **完了日**: 2025-12-30
- **担当**: AI
