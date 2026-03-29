# Setup 総点検 - 乖離リスト

## 重大な乖離（修正済み）

### F-001: SKILL.md ステップフロー説明の不正確さ
- **箇所**: skills/aidlc-setup/SKILL.md ステップ実行セクション
- **内容**: ステップ説明が実際のステップファイル内容と不一致（「設定生成」→実際は「ファイル移行・config.toml生成」等）
- **対応**: SKILL.md のステップ説明を実態に合わせて修正

## 軽微な乖離（Issue化）

4件をまとめて #478 に登録:
1. 02-generate-config.md の初回/移行モード分岐フロー明確化
2. setup-ai-tools.sh の不在テンプレート参照
3. config.toml生成時のTOML配列フォーマット明記
4. migrate-config.sh のbootstrap.sh非依存コメント詳細化
