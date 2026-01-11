# 実装記録: セットアッププロンプトパス記録

## 概要

スターターキットセットアップ時に使用したプロンプトのパスを環境非依存の形式で記録し、Operations Phase完了時に参照できるようにする機能を実装。

## 実装内容

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | tomlテンプレートの`setup_prompt`を動的設定に変更、セクション7.2.1追加 |
| `prompts/package/prompts/operations.md` | 完了メッセージで`setup_prompt`パスを参照・表示 |

### 主な変更点

#### 1. prompts/setup-prompt.md

**tomlテンプレート（403-407行目）**:
- `setup_prompt = "prompts/setup-prompt.md"` → `setup_prompt = "[setup_prompt パス]"`
- 動的設定のためのプレースホルダーに変更

**新規セクション 7.2.1**:
- パス形式の判定ロジック（優先順位順）を追加
  1. 同一リポジトリ内: 相対パス
  2. 外部リポジトリ: ghq形式 `ghq:{host}/{owner}/{repo}/{path}`
  3. フォールバック: 絶対パス（非推奨）
- 判定補助コマンド例を追加
- アップグレードモードでの挙動（既存値保持）を明記

#### 2. prompts/package/prompts/operations.md

**完了メッセージ（830-852行目）**:
- パス取得用bashコマンドを追加
- `[setup-promptのパス]` → `${SETUP_PROMPT}`（実際の値を表示）
- ghq形式の展開方法を案内に追加

## 動作確認シナリオ

### シナリオ1: 初回セットアップ（同一リポジトリ内）

**前提条件**:
- プロジェクトルート配下にsetup-prompt.mdが存在

**期待結果**:
- `[paths].setup_prompt = "prompts/setup-prompt.md"`（相対パス）

### シナリオ2: 初回セットアップ（外部リポジトリ）

**前提条件**:
- setup-prompt.mdが別のghq管理リポジトリにある

**期待結果**:
- `[paths].setup_prompt = "ghq:github.com/owner/repo/prompts/setup-prompt.md"`

### シナリオ3: アップグレード

**前提条件**:
- 既存の`docs/aidlc.toml`に`[paths].setup_prompt`が設定済み

**期待結果**:
- 既存値を保持（上書きしない）

### シナリオ4: Operations Phase完了

**前提条件**:
- `docs/aidlc.toml`に`[paths].setup_prompt`が設定済み

**期待結果**:
- 完了メッセージに実際のパスが表示される
- ghq形式の場合は展開方法も案内される

## 状態

- **状態**: 完了
- **開始日**: 2026-01-11
- **完了日**: 2026-01-11
