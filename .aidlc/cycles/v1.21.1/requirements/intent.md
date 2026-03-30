# Intent（開発意図）

## プロジェクト名
AI-DLC ブランチ・サイクル管理の堅牢性向上と開発体験の改善

## 開発の目的
AI-DLCのブランチ・サイクル管理における堅牢性を向上させ、開発体験を改善する。具体的には、ブランチ作成時のmain最新化チェックの全フェーズ活用、名前付きサイクル関連の未対応箇所の修正、非正規ブランチでの適切な案内、および環境依存ツールチェックの回避設定を実装する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者

## ビジネス価値
- ブランチ作成時のコンフリクトリスクを早期に検知し、Operations Phaseでの手戻りを防止する
- 名前付きサイクル使用時のバグを解消し、機能の信頼性を向上させる
- 非正規ブランチでの作業開始時に適切なガイダンスを提供し、初回利用者の混乱を防ぐ
- 不要なツールチェックを回避可能にすることで、セッション開始時のUXを改善する

## 成功基準
- Inception Phase（ステップ7）・Construction Phase・Operations Phaseの各ブランチ確認ステップで、setup-branch.shのmain最新化チェック結果（警告出力）が参照・表示されている
- `write-history.sh --cycle name/v1.0.0` 実行時に `docs/cycles/name/v1.0.0/history/` 配下に正しく履歴が書き込まれる
- バックログ登録時（Issue作成・ファイル作成）に、名前付きサイクルの場合はサイクル名（例: `waf`）が発見サイクル情報に含まれる
- `cycle/vX.X.X` 以外のブランチでInception開始時に、AskUserQuestionでサイクルブランチ作成が提案される
- `rules.cycle.mode = "named"` または `"ask"` でInception開始時に、`docs/cycles/` 配下の既存名前付きサイクル名がAskUserQuestionの選択肢に表示される
- `aidlc.toml.local` の `[rules.reviewing].tools = []` 設定時に、対応するツールのwhichチェックがスキップされる

## 期限とマイルストーン
特になし（通常サイクルペース）

## 制約事項
- プロンプト・テンプレートの修正は `prompts/package/` を編集すること（メタ開発ルール）
- `docs/aidlc/` は直接編集禁止（rsyncコピー先）
- 既存の設定ファイルフォーマット（aidlc.toml）との後方互換性を維持する

## 既存機能への影響

### 変更対象
- `prompts/package/prompts/inception.md`: ブランチ確認ステップの拡張（非正規ブランチ対応）、名前付きサイクル候補表示の追加
- `prompts/package/prompts/construction.md`: ブランチ確認ステップでmain最新化チェック参照を追加
- `prompts/package/prompts/operations.md`: ブランチ確認ステップでmain最新化チェック参照を追加（既存のマージ/リベースステップとの整合確認）
- `prompts/package/bin/write-history.sh`: 名前付きサイクルパス解決の修正
- `prompts/package/bin/setup-branch.sh`: main最新化チェック出力の確認（既に実装済みの場合は変更なし）
- バックログ関連のプロンプト記述: 名前付きサイクル情報の付与
- `prompts/package/prompts/common/review-flow.md`: ツールチェック回避設定の反映

### 非変更対象
- aidlc.tomlのスキーマ構造（新規キーの追加はあるが、既存キーの変更・削除はなし）
- 既存のサイクルディレクトリ構造（`docs/cycles/vX.X.X/` 形式は維持）
- gitフック、CI/CD関連の設定

### 互換性方針
- 新規設定キー未設定時はデフォルト値で従来の挙動を維持する
- ツールチェック回避設定は `aidlc.toml.local`（個人設定）で制御するため、チーム共有設定に影響しない

## スコープ

### 含まれるもの
- #307: ブランチ作成時のmain最新化チェックを全フェーズで漏れなく活用
- #306: 環境依存ツールチェックの回避設定（aidlc.toml/aidlc.toml.localで制御）
- #305: バックログへの名前付きサイクル情報の付与
- #303: 非正規ブランチ時にサイクルブランチ作成を提案
- #302: Inception時に名前付きサイクル候補を選択肢表示
- #301: write-history.shが名前付きサイクルに未対応（バグ修正）

### 除外するもの
- #300: 対応済み（claude-skillsリポジトリに公開済み）
- #299: AIDLCフェーズ別レビュースキルの検討
- #304: ナビゲーションモードの追加
- #281: マルチプラットフォーム対応

## 不明点と質問（Inception Phase中に記録）

[Question] #307の再発防止策のスコープ
[Answer] setup-branch.shには既にmain最新化チェック機能が実装済み。プロンプト側でInception Phase・Construction Phase・Operations Phaseの各ブランチ確認ステップから漏れなく利用されるようにする。全フェーズで対応する。

[Question] #300の対応状況
[Answer] claude-skillsリポジトリにjj-workflowとして公開済み。対応済みとしてクローズする。
