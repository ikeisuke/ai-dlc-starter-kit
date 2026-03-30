# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit

## 開発の目的
プラグイン環境（Kiro CLI等）でスキルを利用した際に発生するパス参照問題を調査・修正し、スキル間の内部依存を除去する。併せてレビュースキルを種別ベースからレビュータイミングベースに再構成し、レビュー観点も整理する。400行超えのMarkdownファイルを分割してメンテナビリティを向上させる。migrationスクリプトのエッジケースも対応する。

## ターゲットユーザー
AI-DLC Starter Kitの利用者（プラグインとして外部プロジェクトにインストールして使うユーザー）

## ビジネス価値
- プラグイン環境での動作信頼性向上（パス参照問題の解消）
- スキル名からレビュータイミングが明確になり、拡張・保守が容易になる
- レビュー観点の整理により、コードレビューと統合レビューの役割が明確化
- 大きなMarkdownファイルの分割により、AIエージェントのコンテキスト効率が向上
- migrationの堅牢性向上

## 成功基準
- `skills/` 配下のスクリプト・Markdownファイル内に `../../` 等の相対パス参照がゼロ（`scripts/tests/` 配下はメタ開発固有の例外として除外）
- スキル間の内部ファイル参照（`scripts/`, `steps/`, `templates/` 等への直接パス参照）がゼロ
- 新スキル名が `marketplace.json` に登録済みで、`review-flow.md` および `rules.md` 内の旧スキル名参照がゼロ
- スキル配下（`skills/aidlc/`）のMarkdownファイルが全て400行以内（過去cycleのアーカイブ・生成物・履歴ファイルは対象外）
- migrationスクリプトの部分移行後の再実行で重複作成や欠落が発生しない。失敗後リトライで最終状態が初回成功時と一致する
- reviewing-construction-code が旧 code + security の観点を統合し、reviewing-construction-integration が設計乖離・レビュー/テスト実施確認の観点に変更されている

## 期限とマイルストーン
マイナーリリース（v2.1.0）※ レビュースキル名の破壊的変更を含むため、パッチではなくマイナーリリースとする

## 制約事項
- `rules.md` のスキル間依存ルールに準拠する（公開呼び出しインターフェイスのみに依存）
- 旧レビュースキル名（`reviewing-code`, `reviewing-architecture`, `reviewing-security`, `reviewing-inception`）は廃止し、新タイミングベース名に完全移行する。エイリアス・後方互換は設けない（破壊的変更）。`marketplace.json` および `review-flow.md` の参照を一括更新する

## 含まれるもの
- #486 レビュースキルのタイミングベース化（名前衝突防止 + 観点整理）
- #483 migrationスクリプトの部分移行・リトライ時のエッジケース対応
- スクリプトのパス参照問題の調査・修正（プラグイン環境対応）
- スキル間の内部依存の確認・除去
- 400行超えMarkdownファイルの分割（対象: `skills/aidlc/` 配下。過去cycleアーカイブ・生成物・履歴ファイルは除外）
- Construction Phase のレビュー観点変更（code に security 統合、integration は設計乖離・レビュー/テスト実施確認に変更）
- review-flow.md のレビュー完了条件修正（作業者判断の「指摘ゼロ=完了」→ レビュワー承認ベースに変更。再レビュー時はレビュワーが承認/未解消を返し、承認で完了とする）

## 含まれないもの
- 新機能の追加（Operations Phase自律実行モード、並列実装サポート等）

## レビュースキル一覧（新構成）

| スキル名 | タイミング | 主な観点 |
|---------|-----------|---------|
| `reviewing-inception-intent` | Intent承認前 | 目的・スコープの明確さ、妥当性 |
| `reviewing-inception-stories` | ユーザーストーリー承認前 | INVEST準拠、受け入れ基準の具体性 |
| `reviewing-inception-units` | Unit定義承認前 | 分割の適切さ、依存関係、見積もり妥当性 |
| `reviewing-construction-plan` | 計画承認前 | アーキテクチャ整合性、実装計画の妥当性 |
| `reviewing-construction-design` | 設計レビュー | 設計品質、パターン適用、API設計 |
| `reviewing-construction-code` | コード生成後 | コード品質 + セキュリティ（旧 code + security 統合） |
| `reviewing-construction-integration` | 統合とレビュー | 設計との乖離、レビュー/テスト実施状況の確認 |
| `reviewing-operations-deploy` | デプロイ計画承認前 | デプロイ計画の妥当性、ロールバック手順 |
| `reviewing-operations-premerge` | PRマージ前レビュー | PR全体の品質確認 |

## 不明点と質問（Inception Phase中に記録）

[Question] レビュースキルのタイミング一覧として、上記の粒度で正しいか？
[Answer] OK。Operations Phase のデプロイ計画承認前、PRマージ前レビューも含めて承認済み。

[Question] 統合とレビュー（現在 code + security の2種別実行）は1つのスキルに統合するか、別々に維持するか？
[Answer] code レビューに security を含めて統合。統合レビュー（integration）は設計との乖離チェック、適切なレビュー・テストが実施されたかの確認に役割変更。
