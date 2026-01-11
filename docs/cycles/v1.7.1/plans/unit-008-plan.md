# Unit 008: jjサポート有効化フラグ - 実装計画

## 概要

aidlc.tomlに`[rules.jj].enabled`設定を追加し、jjサポートの有効/無効を切り替えられるようにする。

## スコープ

### 含まれるもの

- aidlc.tomlに`[rules.jj]`セクション追加
- 設定参照パターンの実装（既存の`[rules.mcp_review]`等に倣う）
- プロンプトでのjj設定参照ガイダンス追加

### 含まれないもの（境界外）

- jjコマンド自体の詳細な使用方法（既存のjj-support.mdで対応済み）
- aidlc.toml.local対応（別サイクルで対応予定）
- プロンプト内のgitコマンドの自動置換

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

設定ドメインにjjサポート設定を追加:
- 既存の`[rules.worktree]`、`[rules.unit_branch]`と同様のパターン
- enabled: true/false（デフォルト: false）

#### ステップ2: 論理設計

設定参照のフロー設計:
- enabled=true時: jjコマンドを優先的に案内、jj-support.md参照を追加
- enabled=false時: 従来のgitコマンドを使用

### Phase 2: 実装

#### ステップ4: コード生成

1. **prompts/package/aidlc.toml.template** に`[rules.jj]`セクション追加
2. **prompts/package/prompts/** 内の関連プロンプトに設定参照ガイダンス追加

#### ステップ5: テスト生成

- 設定ファイルの検証（TOMLフォーマット）

#### ステップ6: 統合とレビュー

- Markdownlint実行
- ビルド確認

## 影響ファイル（予定）

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/aidlc.toml.template` | `[rules.jj]`セクション追加 |
| 関連プロンプト | jj設定参照ガイダンス追加 |

## 注意事項

- **メタ開発**: `docs/aidlc/`は直接編集せず、`prompts/package/`を編集
- 既存のjj-support.mdガイドとの連携を考慮
- バックログ`feature-jj-enabled-flag.md`の内容を反映

## 依存関係

- なし

## 見積もり

1時間
