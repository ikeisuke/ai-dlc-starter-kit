# ステップ2: 既存コード分析 計画

## 作成するファイル

`docs/cycles/v1.3.1/requirements/existing_analysis.md`

## 分析対象ファイル

今回の改修に関連するファイル:

1. **prompts/package/prompts/inception.md** - Inception Phase本体
2. **prompts/setup-cycle.md** - サイクル開始（セットアップ）

## 分析結果（ドラフト）

### 1. prompts/package/prompts/inception.md

**現状の「最初に必ず実行すること（5ステップ）」**:
1. サイクル存在確認 - サイクルが存在しなければエラー
2. 追加ルール確認
3. バックログ確認（共通・サイクル固有）
4. 進捗管理ファイル確認
5. 既存成果物の確認

**改修ポイント**:

| 機能 | 改修箇所 | 内容 |
|------|----------|------|
| バックログ対応済みチェック | ステップ3 | バックログ確認時にbacklog-completed.mdと過去history.mdを参照して対応済みかチェックする手順を追加 |
| セットアップスキップ | ステップ1 | サイクルが存在しない場合、自動作成を提案（エラーではなく） |
| 最新バージョンチェック | ステップ1の前後 | prompts/package/とdocs/aidlc/のバージョン差分を確認し、差異があれば通知 |
| Dependabot PR確認 | ステップ3の前後 | gh pr list --labelでDependabot PRの有無を確認 |

### 2. prompts/setup-cycle.md

**現状**:
- セットアップ時にサイクルディレクトリを作成
- history.md、backlog.mdを初期化

**改修ポイント**:
- 改修不要（サイクルディレクトリ作成ロジックをinception.mdに移動するため）

### 影響範囲

- **prompts/package/prompts/inception.md**: 主要改修対象
- **prompts/setup-cycle.md**: 変更なし（ただしinception.mdに機能移動後、整合性確認必要）
- **docs/aidlc/templates/inception_progress_template.md**: ステップ6が残っている（別途修正推奨）
