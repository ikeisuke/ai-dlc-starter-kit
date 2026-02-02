# Unit 001: プロジェクト個人設定 - 実装計画

## 概要

`docs/aidlc.toml.local` ファイルによるプロジェクト個人設定機能を実装する。チーム共有設定（`aidlc.toml`）と個人の好み（`.local`）を分離し、設定コンフリクトを防止する。

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|----------|------|
| `prompts/package/bin/read-config.sh` | 設定マージ＆読み込みスクリプト |
| `prompts/package/guides/config-merge.md` | 設定マージロジックの共通ガイド |

### 修正

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/common/rules.md` | 設定読み込みセクションに.local対応を追加 |
| `.gitignore` | `docs/aidlc.toml.local` を追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - 設定マージのルール定義（キー単位優先、配列置換、ネスト再帰マージ）
   - 読み込み優先順位の明確化
   - スクリプトのインターフェース設計

2. **論理設計**
   - `read-config.sh` の処理フロー
   - 共通ガイド（`config-merge.md`）の構造設計
   - 各プロンプトでの呼び出し方法

### Phase 2: 実装

1. **スクリプト作成**
   - `prompts/package/bin/read-config.sh` を作成
   - daselを使用したTOML読み込み・マージ処理
   - フォールバック処理（.localファイル不在時）

2. **共通ガイド作成**
   - `prompts/package/guides/config-merge.md` を作成
   - マージルールの詳細説明
   - スクリプトの使用方法

3. **rules.md修正**
   - 設定読み込みセクションに.local対応を追加
   - `read-config.sh` の使用を推奨

4. **.gitignore修正**
   - `docs/aidlc.toml.local` エントリを追加

## 完了条件チェックリスト

- [x] `docs/aidlc.toml.local` ファイルの読み込みロジック追加
- [x] `aidlc.toml` と `.local` のマージ処理（キー単位優先、配列置換、ネスト再帰マージ）
- [x] `.gitignore` への `.local` ファイル追加

## 設計判断ポイント

### マージロジックの実装場所

**選択肢**:
1. 各プロンプト内で都度説明
2. 共通ガイド（`config-merge.md`）に集約し、各プロンプトから参照

**推奨**: 選択肢2（保守性向上、DRY原則）

### マージルールの詳細

Unit定義に従い、以下のルールを適用:
- **キー単位優先**: `.local` の値が存在すれば `aidlc.toml` を上書き
- **配列置換**: 配列は置換（マージしない）
- **ネスト再帰マージ**: ネストされたテーブルは再帰的にマージ

## 技術的注意事項

- **メタ開発**: `prompts/package/` を編集し、`docs/aidlc/` は直接編集しない
- **Unit 002との連携**: 本Unitのマージロジックは Unit 002（3階層マージ）で再利用可能な形で設計
