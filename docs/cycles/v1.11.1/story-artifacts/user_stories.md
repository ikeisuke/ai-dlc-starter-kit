# ユーザーストーリー

## Epic A: フェーズ間引き継ぎの強化

### ストーリー A-1: Construction → Operations引き継ぎ (#140)

**優先順位**: Must-have

As a AI-DLC開発者
I want to Construction Phaseで発生した手動作業をOperations Phaseに明確に引き継ぎたい
So that タスク漏れを防止し、確実にリリース作業を完了できる

**受け入れ基準**:
- [ ] 引き継ぎタスクファイルのテンプレートが作成されている
- [ ] Construction Phase完了時に引き継ぎファイルを作成する手順がconstruction.mdに記載されている
- [ ] Operations Phase開始時に引き継ぎファイルを確認する手順がoperations.mdに記載されている
- [ ] 1作業1ファイル形式で、ステータス管理が可能

**技術的考慮事項**:
- `docs/cycles/vX.X.X/operations/tasks/` ディレクトリを使用
- 既存のUnit定義ファイル形式を参考にする

---

### ストーリー A-2: サイクル横断ドキュメント置き場 (#104)

**優先順位**: Should-have

As a AI-DLC開発者
I want to サイクルに依存しない共通資料の置き場を明確にしたい
So that 長期的なプロジェクト運用でドキュメントが散逸しない

**受け入れ基準**:
- [ ] サイクル横断ドキュメントの配置場所が決定している
- [ ] どのような資料をサイクル横断で管理すべきかのガイドラインがある
- [ ] ADR（Architecture Decision Records）の導入方針が決定している

**技術的考慮事項**:
- `docs/aidlc/` との棲み分けを明確にする
- 既存の `docs/cycles/` 構造との整合性を保つ

---

## Epic B: プロンプト・ガイドの改善

### ストーリー B-1: AIレビュー実施タイミングの明示化 (#144)

**優先順位**: Must-have

As a AI-DLC開発者
I want to Construction Phaseの各ステップでAIレビューを実施すべきタイミングを明確に知りたい
So that AIレビューを見落とさず、品質を確保できる

**受け入れ基準**:
- [ ] ステップ3（設計レビュー）にAIレビュー実施指示が明示的に記載されている
- [ ] ステップ5（実行前確認）にAIレビュー実施指示が明示的に記載されている
- [ ] ステップ6（統合とレビュー）にAIレビュー実施指示が明示的に記載されている
- [ ] 各ステップで `review-flow.md` への参照が含まれている

**技術的考慮事項**:
- `prompts/package/prompts/construction.md` を編集

---

### ストーリー B-2: サンドボックス環境ガイド補完 (#141)

**優先順位**: Should-have

As a AI-DLC開発者
I want to 各AIツールの認証方式とサンドボックスの種類を理解したい
So that セキュリティを考慮した適切な環境構築ができる

**受け入れ基準**:
- [ ] 各ツールの認証方式（API vs OAuth）の比較表が追加されている
- [ ] OAuth認証ツールのDocker実行例が追加されている
- [ ] アプリケーションレベル vs OSレベルのサンドボックスの違いが説明されている
- [ ] 各ツールの保護範囲が明確化されている

**技術的考慮事項**:
- `prompts/package/guides/sandbox-environment.md` を編集
- セキュリティ上の注意点を明記する

---

## Epic C: 運用効率化

### ストーリー C-1: 定型コマンドのスクリプト化 (#142)

**優先順位**: Should-have

As a AI-DLC開発者
I want to 頻繁に使用する定型コマンドをスクリプト化したい
So that 許可リスト設定を簡素化し、保守性を向上できる

**受け入れ基準**:
- [ ] `aidlc-env-check.sh`（環境チェック）が作成されている
- [ ] `aidlc-git-info.sh`（Git状態取得）が作成されている
- [ ] `aidlc-cycle-info.sh`（サイクル情報取得）が作成されている
- [ ] 許可リストガイドにスクリプト活用方法が追記されている

**技術的考慮事項**:
- `docs/aidlc/bin/` に配置
- `prompts/package/bin/` にも同様に配置（メタ開発のため）
- 既存スクリプトの命名規則に合わせる
