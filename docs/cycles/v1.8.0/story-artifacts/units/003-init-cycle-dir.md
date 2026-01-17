# Unit: サイクルディレクトリ初期化スクリプト

## 概要
サイクル用ディレクトリ構造（plans, requirements, story-artifacts等）を一括で作成するスクリプトを作成する。

## 含まれるユーザーストーリー
- ストーリー 1-3: サイクルディレクトリ初期化

## 関連Issue
- #34

## 責務
- サイクルバージョンを引数で受け取る
- 9個のディレクトリを一括作成
- history/inception.md の初期化
- プロンプト内のmkdirをスクリプト呼び出しに置換

## 境界
- backlog/ ディレクトリは別処理（サイクル固有ではない）

## 依存関係

### 依存する Unit
- なし（独立して実装可能）

### 外部依存
- bash

## 非機能要件（NFR）
- **パフォーマンス**: 即時完了
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: オフライン環境でも動作

## 技術的考慮事項

### 作成するディレクトリ構造

```text
docs/cycles/{{CYCLE}}/
├── plans/
├── requirements/
├── story-artifacts/units/
├── design-artifacts/domain-models/
├── design-artifacts/logical-designs/
├── design-artifacts/architecture/
├── inception/
├── construction/units/
├── operations/
└── history/
```

### 使用方法
```bash
bin/init-cycle-dir.sh v1.8.0
```

### 変更対象ファイル
- `prompts/package/bin/init-cycle-dir.sh`（新規）
- `prompts/package/prompts/setup.md`（呼び出し追加）

## 実装優先度
High

## 見積もり
30分

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-17
- **完了日**: -
- **担当**: -
