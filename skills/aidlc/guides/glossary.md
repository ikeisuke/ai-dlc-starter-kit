# AI-DLC用語集

AI-DLC（AI-Driven Development Lifecycle）で使われる固有用語の定義一覧。ドキュメントやプロンプトでの用語の意味を統一する。

## 用語一覧

アルファベット順。各列の定義は以下のとおり。

- **用語**: ドキュメント上の正規表記
- **別名/コード表記**: コード・設定ファイル上の表記（バッククォート付き）やその他の呼称（自然言語の別名はバッククォート不要）。該当なしは `-`
- **説明**: 用語の簡潔な定義
- **関連フェーズ**: `Inception` / `Construction` / `Operations` の組み合わせ、または `全フェーズ`。カンマ+半角スペース区切り、順序固定、重複禁止。`全フェーズ` は単独使用
- **参照**: 用語が最初に定義されている代表ドキュメントへのパス（`prompts/package/` を基準とした相対パス。`guides/`・`prompts/` 等のサブディレクトリ名から開始）

| 用語 | 別名/コード表記 | 説明 | 関連フェーズ | 参照 |
|------|---------------|------|------------|------|
| Backlog | `backlog` | 未対応タスク・課題の管理リスト。GitHub Issueで管理 | 全フェーズ | `guides/backlog-management.md` |
| Construction | - | 設計と実装を行うフェーズ。Phase 1（設計）とPhase 2（実装）で構成 | Construction | `prompts/construction/01-setup.md` |
| Cycle | `cycle/vX.X.X` | 開発の1サイクル。バージョン番号（vX.X.X）で識別される | 全フェーズ | `prompts/common/intro.md` |
| サイクルラベル | `cycle:vX.X.X` | 旧運用での Issue 紐付け方式（**v2.4.0 で deprecated**、Milestone に置換）。物理残置されており過去サイクル追跡用に参照可能 | 全フェーズ | `guides/backlog-management.md` |
| Depth Level | `depth_level` | 設計・実装の詳細度設定。`minimal` / `standard` / `comprehensive` | 全フェーズ | `prompts/common/rules-reference.md` |
| Domain Model | - | DDDに基づくビジネスロジックの構造化 | Construction | `prompts/construction/02-design.md` |
| Inception | - | 要件定義フェーズ。IntentからUnit定義までを作成 | Inception | `prompts/inception/01-setup.md` |
| Intent | - | 開発の目的と狙いを記述した成果物 | Inception | `prompts/inception/03-intent.md` |
| Logical Design | - | 非機能要件を反映した設計層 | Construction | `prompts/construction/02-design.md` |
| Milestone | `vX.X.X`（GitHub Milestone title） | GitHub Milestone を AI-DLC のサイクル管理単位として用いる（v2.4.0 以降）。Inception Phase が自動作成、Operations Phase が自動 close。1 Issue = 1 Milestone 制約 | 全フェーズ | `guides/backlog-management.md` |
| Operations | - | デプロイ・リリース・運用を行うフェーズ | Operations | `prompts/operations/01-setup.md` |
| Phase | - | 開発サイクルの段階。Inception→Construction→Operationsの3段階 | 全フェーズ | `prompts/common/intro.md` |
| PRFAQ | - | Press Release / FAQフォーマット。Intentの記述形式 | Inception | `prompts/inception/03-intent.md` |
| Semi-auto | `semi_auto` | 承認ゲートを自動パスするautomation_mode設定。適用条件と制約は参照先を確認 | 全フェーズ | `prompts/common/rules-automation.md` |
| Squash | `squash` | 中間コミットを1つの完了コミットにまとめる操作 | Construction | `prompts/common/commit-flow.md` |
| Story | User Story | ユーザーストーリー。ユーザー視点の要件を記述 | Inception | `prompts/inception/04-stories-units.md` |
| Unit | - | 独立した価値提供ブロック。Epic/Subdomainに相当 | Inception, Construction | `prompts/inception/04-stories-units.md` |
