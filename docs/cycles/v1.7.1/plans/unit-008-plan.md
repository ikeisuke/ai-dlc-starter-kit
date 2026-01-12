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

## フォールバック動作

- **設定が未指定の場合**: `enabled = false` として扱う（従来のgitを使用）
- `[rules.mcp_review]`の設定パターンに倣い、設定がない場合のデフォルト動作を明確化

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

#### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

### Phase 2: 実装

#### ステップ4: コード生成

1. **prompts/package/aidlc.toml.template** に`[rules.jj]`セクション追加
2. **影響プロンプトに設定参照ガイダンス追加**（詳細は下記「影響ファイル」参照）

#### ステップ5: テスト生成

- 設定ファイルの検証: TOMLフォーマット確認（手動確認）
- Markdownlint実行による構文検証

#### ステップ6: 統合とレビュー

- 全影響ファイルの確認
- ビルド確認（rsyncによる`docs/aidlc/`更新）

## 影響ファイル（予定）

| ファイル | 変更内容 |
|---------|---------|
| `docs/aidlc.toml` | `[rules.jj]`セクション追加 |
| `prompts/package/prompts/setup.md` | jj設定参照ガイダンス追加 |
| `prompts/package/prompts/inception.md` | jj設定参照ガイダンス追加 |
| `prompts/package/prompts/construction.md` | jj設定参照ガイダンス追加 |
| `prompts/package/prompts/operations.md` | jj設定参照ガイダンス追加 |

## 依存関係

### 文書依存

- `docs/aidlc/guides/jj-support.md`: enabled=true時に参照を案内

### Unitブロッカー依存

- なし

## 注意事項

- **メタ開発**: `docs/aidlc/`は直接編集せず、`prompts/package/`を編集
- 既存のjj-support.mdガイドとの連携を考慮
- バックログ`feature-jj-enabled-flag.md`の内容を反映

## 見積もり

1時間
