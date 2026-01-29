# 既存コード分析

## 分析対象

本サイクルで変更対象となるファイル構造を分析。

## プロンプトファイル構造

### 通常版（docs/aidlc/prompts/）

| ファイル | サイズ | 役割 | 変更予定 |
|---------|--------|------|----------|
| setup.md | 26KB | サイクル作成 | 統合対象 |
| inception.md | 27KB | 要件定義・Unit分解 | 統合対象 |
| construction.md | 34KB | 実装 | 変更なし |
| operations.md | 35KB | デプロイ・運用 | 変更なし |

### Lite版（docs/aidlc/prompts/lite/）

| ファイル | サイズ | 役割 | 変更予定 |
|---------|--------|------|----------|
| inception.md | 2.5KB | Lite版要件定義 | 統合対象 |
| construction.md | 3.9KB | Lite版実装 | 変更なし |
| operations.md | 3KB | Lite版運用 | 変更なし |

**注**: Lite版にはsetup.mdが存在しない（inception.mdに簡易的なサイクル作成機能を含める必要あり）

## 設定ファイル構造

### docs/aidlc.toml

現在の主要セクション:
- `[project]`: プロジェクト基本情報
- `[paths]`: パス設定
- `[rules.coding]`: コーディングルール
- `[rules.git]`: Git運用ルール
- `[rules.commit]`: コミット設定
- `[rules.mcp_review]`: AIレビュー設定
- `[backlog]`: バックログ管理設定

**追加予定セクション**:
- `[inception.dependabot]`: Dependabot PR確認のオプション設定

## 設定階層化の影響範囲

### 新規ファイル

| ファイル | 役割 |
|---------|------|
| docs/aidlc.toml.local | プロジェクト個人設定（gitignore推奨） |
| ~/.aidlc/config.toml | ユーザー共通設定 |

### 読み込み順序

```
1. ~/.aidlc/config.toml      （ユーザー共通・最低優先）
2. docs/aidlc.toml           （プロジェクト共有）
3. docs/aidlc.toml.local     （プロジェクト個人・最高優先）
```

## Codex Skill関連

### 現在の実装

- `docs/aidlc/skills/codex/SKILL.md`: Codex呼び出しスキル
- resume機能: `codex exec resume <session-id>` で利用可能

### 変更予定

- AIレビューフロー内でセッションIDを保持・再利用するロジックを追加
- Unit単位でセッションを管理

## 結論

- Setup/Inception統合は通常版・Lite版の両方で実施
- 設定階層化はプロンプト内の設定読み込みロジックに影響
- Codex resume機能はreview-flow.mdの変更が必要
