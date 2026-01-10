# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.6.1 - ルール責務分離

## 開発の目的
`rules.md` に混在しているAI-DLC共通ルールとプロジェクト固有ルールを分離し、それぞれ適切な場所（AGENTS.md / rules.md）に配置する。

## ターゲットユーザー
- AI-DLC Starter Kit を使用する開発者
- AIエージェント（Claude Code、Cursor等）

## ビジネス価値
- **明確な責務分離**: AGENTS.md = 共通ルール、rules.md = プロジェクト固有ルール
- **メンテナンス性向上**: 共通ルールの変更が全プロジェクトに反映される
- **新規プロジェクトのセットアップ簡素化**: rules.md がプロジェクト固有の内容のみになる

## 成功基準
- `prompts/package/templates/AGENTS.md.template` に共通ルールセクションが追加されている
- `prompts/setup/templates/rules_template.md` からAI-DLC共通ルールが削除されている
- 既存プロジェクトの `docs/cycles/rules.md` が更新されている
- AskUserQuestionツールの使用ルール「不明点がなくなるまで繰り返し質問すること」が追加されている
- フェーズ簡略指示機能が追加されている（「コンストラクション進めて」で自動的にプロンプト読み込み）

## 期限とマイルストーン
- パッチリリースとして1セッション内で完了

## 制約事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集）
- 既存の動作を壊さない後方互換性を維持

## 不明点と質問（Inception Phase中に記録）

なし（バックログで詳細が定義済み）
