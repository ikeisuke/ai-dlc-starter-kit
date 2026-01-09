# Unit 002 計画: Claude Code機能活用

## 対象Unit
- Unit番号: 002
- Unit名: Claude Code機能活用
- 優先度: Medium
- 見積もり: 1時間

## 現状分析

### 確認済みファイル
| ファイル | 状態 |
|---------|------|
| CLAUDE.md | AskUserQuestion/TodoWrite活用ルール記載済み |
| AGENTS.md | プロンプト自動解決構造記載済み |
| prompts/package/templates/CLAUDE.md.template | **存在（移動対象）** |
| prompts/package/templates/AGENTS.md.template | **存在（移動対象）** |
| prompts/setup/templates/ | rules_template.md, operations_handover_template.mdのみ |

### Unit 002 責務
1. CLAUDE.mdにAskUserQuestion活用ルールを追記 - **既存内容で充足**
2. AGENTS.mdによるプロンプト自動解決の検証と文書化 - **未実施**
3. CLAUDE.md/AGENTS.mdテンプレートの配置場所修正とコピー処理追加 - **未実施**

## ユーザー決定事項

### マージ方式: 必須セクション自動追記
- テンプレートに定義された必須セクションが既存ファイルに存在しなければ自動追記
- 既存の内容は保持（上書きしない）
- 新規プロジェクトの場合はテンプレートをそのままコピー

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- CLAUDE.md/AGENTS.mdテンプレートの構造定義
  - 必須セクションの識別
  - セクション単位でのマージロジック
- テンプレート配置場所（prompts/setup/templates/）の設計

#### ステップ2: 論理設計
- テンプレートファイルの内容設計
  - CLAUDE_template.md: Claude Code固有の設定（必須セクションをマーカーで識別）
  - AGENTS_template.md: プロンプト自動解決の基本構造
- setup-prompt.mdの変更設計
  - セクション8.2.3にCLAUDE.md/AGENTS.mdコピー処理を追加
  - 必須セクション自動追記ロジック

#### ステップ3: 設計レビュー
- ユーザー承認

### Phase 2: 実装

#### ステップ4: コード生成
1. `prompts/package/templates/CLAUDE.md.template` → `prompts/setup/templates/` に移動
2. `prompts/package/templates/AGENTS.md.template` → `prompts/setup/templates/` に移動
3. `prompts/setup-prompt.md` にコピー・マージ処理追加

#### ステップ5: テスト生成
- 新規セットアップ時: テンプレートがコピーされること
- 既存プロジェクト: 必須セクションが追記されること

#### ステップ6: 統合とレビュー
- 実装記録作成
- コミット

## 変更予定ファイル
| ファイル | 変更種別 |
|---------|---------|
| prompts/package/templates/CLAUDE.md.template | 削除（移動元） |
| prompts/package/templates/AGENTS.md.template | 削除（移動元） |
| prompts/setup/templates/CLAUDE.md.template | 移動先 |
| prompts/setup/templates/AGENTS.md.template | 移動先 |
| prompts/setup-prompt.md | 修正（コピー・マージ処理追加） |
| docs/cycles/v1.6.0/design-artifacts/domain-models/unit-002_domain_model.md | 新規作成 |
| docs/cycles/v1.6.0/design-artifacts/logical-designs/unit-002_logical_design.md | 新規作成 |
| docs/cycles/v1.6.0/construction/units/unit-002_implementation.md | 新規作成 |

## 依存関係
- なし（独立して実装可能）

## リスク
- セクション識別の精度（マーカー/見出しでの識別）
- 既存内容との整合性確認

## 備考
- rules.mdと同様のパターン（存在しない場合のみコピー）を基本としつつ、必須セクション追記機能を追加
