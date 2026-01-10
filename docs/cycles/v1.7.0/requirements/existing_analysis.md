# 既存コード分析

## 分析対象

バックログ項目に関連するファイル・ディレクトリの現状を分析

## 分析結果

### 1. ガイドディレクトリ (`prompts/package/guides/`)

**状態**: 存在しない

**対応**: 新規作成が必要
- `ai-agent-allowlist.md` - AIエージェント許可リスト
- `jj-support.md` - jj実験的サポート

### 2. Issueテンプレートディレクトリ (`.github/ISSUE_TEMPLATE/`)

**状態**: 存在しない

**対応**: 新規作成が必要
- Epic用テンプレート
- Unit用テンプレート
- バグ用テンプレート
- タスク用テンプレート

### 3. aidlc.toml

**状態**: 既存（`docs/aidlc.toml`）

**現状**:
- `[paths]` セクションに `setup_prompt = "prompts/setup-prompt.md"` が既にある
- ただし、これはデフォルトパスの定義であり、実際に使用されたパスの記録ではない

**対応**:
- `[setup]` セクションを追加し、実際に使用されたパスを記録する仕組みを検討
- または `[paths].setup_prompt` を動的に更新する方式

### 4. バックアップ処理 (`prompts/package/prompts/setup.md`)

**状態**: 455-543行付近にバックアップ処理が存在

**現状**:
- 旧形式バックログ移行時に `.bak.[タイムスタンプ]` ファイルを作成
- バックアップ作成後、終了メッセージで削除を案内

**対応**:
- バックアップ作成ステップ（468-472行）を削除
- 終了メッセージからバックアップ関連の文言を削除
- 移行後は旧ファイルを直接削除

## 影響範囲

| 対象 | 変更種別 | 影響 |
|------|---------|------|
| `prompts/package/guides/` | 新規作成 | 新規ディレクトリ・ファイル追加 |
| `.github/ISSUE_TEMPLATE/` | 新規作成 | 新規ディレクトリ・ファイル追加 |
| `docs/aidlc.toml` | 更新 | 設定セクション追加 |
| `prompts/package/prompts/setup.md` | 更新 | バックアップ処理削除 |
| `prompts/package/prompts/setup.md` | 更新 | パス記録処理追加 |

## 備考

- `prompts/package/` 配下の変更は Operations Phase で `docs/aidlc/` に rsync される
- `.github/ISSUE_TEMPLATE/` はリポジトリ直下なので rsync 対象外
