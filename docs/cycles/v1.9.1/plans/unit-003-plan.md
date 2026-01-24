# Unit 003 計画: 確認系処理のスクリプト化

## 概要

setup-prompt.md 内の確認系処理（バージョン比較、セットアップ種類判定）をスクリプト化し、プロンプトを簡素化する。

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|----------|------|
| `prompts/package/bin/check-version.sh` | バージョン比較スクリプト |
| `prompts/package/bin/check-setup-type.sh` | セットアップ種類判定スクリプト |

### 変更

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | セクション2のインライン処理をスクリプト呼び出しに置換 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - スクリプトの入出力仕様を定義
   - 既存スクリプト（check-backlog-mode.sh等）との一貫性を確保

2. **論理設計**
   - check-version.sh: バージョン比較ロジック
   - check-setup-type.sh: 設定ファイル存在確認 + バージョン情報に基づく判定

### Phase 2: 実装

1. **check-version.sh の作成**
   - 入力: なし（docs/aidlc.toml と version.txt を読み取り）
   - 出力形式: `version_status:{状態}`
   - 状態値:
     - `current`: 同じバージョン
     - `upgrade_available:{project}:{kit}`: アップグレード可能
     - `project_newer:{project}:{kit}`: プロジェクトが新しい
     - `not_found`: バージョン情報なし

2. **check-setup-type.sh の作成**
   - 入力: なし
   - 出力形式: `setup_type:{種類}`
   - 種類値:
     - `initial`: 初回セットアップ
     - `cycle_start`: サイクル開始（同じバージョン）
     - `upgrade`: アップグレード可能
     - `warning_newer`: プロジェクトが新しい
     - `migration`: 旧形式からの移行

3. **setup-prompt.md の修正**
   - セクション2のインライン処理を削除
   - スクリプト呼び出しに置換
   - ケース判定ロジックはプロンプト内に残す（スクリプト出力を解釈）

## 完了条件チェックリスト

- [ ] check-version.sh が作成され、バージョン比較が正しく動作する
- [ ] check-setup-type.sh が作成され、セットアップ種類判定が正しく動作する
- [ ] setup-prompt.md からインライン処理が削除され、スクリプト呼び出しに置換されている

## 技術的考慮事項

- 既存スクリプトの出力形式（`key:value`）を踏襲
- dasel未インストール時のフォールバック処理
- version.txt のパス: スクリプトのディレクトリ基準で `../version.txt`
