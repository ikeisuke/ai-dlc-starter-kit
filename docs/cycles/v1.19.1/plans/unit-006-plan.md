# Unit 006 計画: Terminology/Glossary作成

## 概要

AI-DLC固有用語の用語集を作成し、ドキュメントやプロンプトで使われる用語の統一的な定義を提供する。

## 変更対象ファイル

- `prompts/package/guides/glossary.md` — 新規作成（用語集、用語定義のみを記載）

## 実装計画

### 1. glossary.md 新規作成

`prompts/package/guides/glossary.md` に以下の構成で作成する。ファイルは用語定義の正本として機能する。

#### 構成

1. **タイトルと概要**
   - AI-DLC用語集の目的と使い方

2. **用語一覧テーブル**

   アルファベット順で整理。各用語に以下の列を設ける:

   | 用語 | 別名/コード表記 | 説明 | 関連フェーズ | 参照 |
   |------|---------------|------|------------|------|

   - **用語**: ドキュメント上の正規表記
   - **別名/コード表記**: コード・設定ファイル上の表記（例: `semi_auto`）やその他の呼称
   - **関連フェーズ**: 固定値の組み合わせ（`Inception` / `Construction` / `Operations` の1つ以上、または `全フェーズ`）。表記規則: `, ` 区切り、`Inception, Construction, Operations` の順、重複禁止、`全フェーズ` は単独使用
   - **参照**: 用語が最初に定義されている代表ドキュメントへのパス（`prompts/package/` を基準とした相対パス）。複数フェーズにまたがる場合も代表1件を記載

   **必須用語セット（最低10用語）**:

   | 用語 | 別名/コード表記 | 説明 | 関連フェーズ | 参照 |
   |------|---------------|------|------------|------|
   | Backlog | `backlog` | 未対応タスク・課題の管理リスト。GitファイルまたはGitHub Issueで管理 | 全フェーズ | `guides/backlog-management.md` |
   | Construction | - | 設計と実装を行うフェーズ。Phase 1（設計）とPhase 2（実装）で構成 | Construction | `prompts/construction.md` |
   | Cycle | `cycle/vX.X.X` | 開発の1サイクル。バージョン番号（vX.X.X）で識別される | 全フェーズ | `prompts/common/intro.md` |
   | Inception | - | 要件定義フェーズ。IntentからUnit定義までを作成 | Inception | `prompts/inception.md` |
   | Intent | - | 開発の目的と狙いを記述した成果物 | Inception | `prompts/inception.md` |
   | Operations | - | デプロイ・リリース・運用を行うフェーズ | Operations | `prompts/operations.md` |
   | Phase | - | 開発サイクルの段階。Inception→Construction→Operationsの3段階 | 全フェーズ | `prompts/common/intro.md` |
   | PRFAQ | - | Press Release / FAQフォーマット。Intentの記述形式 | Inception | `prompts/inception.md` |
   | Story | User Story | ユーザーストーリー。ユーザー視点の要件を記述 | Inception | `prompts/inception.md` |
   | Unit | - | 独立した価値提供ブロック。Epic/Subdomainに相当 | Inception, Construction | `prompts/inception.md` |

   **追加候補用語**:

   | 用語 | 別名/コード表記 | 説明 | 関連フェーズ | 参照 |
   |------|---------------|------|------------|------|
   | Domain Model | - | DDDに基づくビジネスロジックの構造化 | Construction | `prompts/construction.md` |
   | Logical Design | - | 非機能要件を反映した設計層 | Construction | `prompts/construction.md` |
   | Depth Level | `depth_level` | 設計・実装の詳細度設定。`minimal`/`standard`/`detailed` | 全フェーズ | `prompts/common/rules.md` |
   | Squash | `squash` | 中間コミットを1つの完了コミットにまとめる操作 | Construction | `prompts/common/commit-flow.md` |
   | Semi-auto | `semi_auto` | 承認ゲートを自動パスするautomation_mode設定 | 全フェーズ | `prompts/common/rules.md` |

## 完了条件チェックリスト

- [ ] `prompts/package/guides/glossary.md` にAI-DLC固有用語の定義一覧を作成（最低10用語）
- [ ] 必須用語セット（Cycle, Phase, Intent, Unit, Story, PRFAQ, Construction, Operations, Inception, Backlog）をすべて含む
- [ ] 各用語に正規表記・別名・説明・関連フェーズ・参照を記載
