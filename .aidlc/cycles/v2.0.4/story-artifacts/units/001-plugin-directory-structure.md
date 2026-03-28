# Unit: プラグインディレクトリ構造構築

## 概要
AI-DLCスターターキットをClaude Codeプラグインリポジトリ構造に変換する。`skills/` ディレクトリに全スキルを配置し、ステップファイルをスキル内に移行する。

## 含まれるユーザーストーリー
- ストーリー 1: プラグインインストール
- ストーリー 2: ステップファイルのパス解決（ファイル配置部分）

## 責務
- `skills/aidlc/` にオーケストレーターSKILL.md とステップファイルを配置
- `docs/aidlc/prompts/` の内容を `skills/aidlc/steps/` に移行
- 既存スキル（reviewing-*, squash-unit, aidlc-setup）を `skills/` 配下に統合
- プラグインルートの CLAUDE.md / README.md を整備

## 境界
- SKILL.md の内容変更（Unit 002で対応）
- v1残存コードの削除（Unit 003で対応）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- Claude Code プラグイン仕様（ikeisuke-skills の実績を参考）

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 既存の `docs/aidlc/skills/` からのシンボリンク（`.claude/skills/`）を新構造に置き換える
- `docs/aidlc/prompts/common/` → `skills/aidlc/steps/common/` のマッピング
- テンプレート・bin スクリプトの配置先も整理する

## 実装優先度
High

## 見積もり
中規模（ファイル移動・リネームが中心）

## 関連Issue
なし（新規作業）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-28
- **完了日**: 2026-03-28
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
