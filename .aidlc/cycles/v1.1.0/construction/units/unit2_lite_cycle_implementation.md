# Unit 2: 軽量サイクル（Lite版）実装記録

## 概要

バグ修正や軽微な変更向けの簡略化されたAI-DLCサイクル（Lite版）を実装した。

## 実装方式

**Full版参照+差分指示**方式を採用：
- Lite版プロンプトはFull版を参照し、スキップ/簡略化する箇所のみを記述
- Full版が唯一の真実（Single Source of Truth）
- `.lite`ファイルでサイクルタイプを識別

## 作成・変更したファイル

### 新規作成

| ファイル | 内容 |
|---------|------|
| `docs/aidlc/prompts/lite/inception.md` | Inception Phase Lite版プロンプト |
| `docs/aidlc/prompts/lite/construction.md` | Construction Phase Lite版プロンプト |
| `docs/aidlc/prompts/lite/operations.md` | Operations Phase Lite版プロンプト |

### 変更

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-prompt.md` | `CYCLE_TYPE`変数追加、完了メッセージにLite版案内追加 |
| `prompts/setup/common.md` | `CYCLE_TYPE`変数追加、liteディレクトリ・`.lite`ファイル作成指示追加、完了メッセージ更新 |

### 設計ドキュメント

| ファイル | 内容 |
|---------|------|
| `docs/cycles/v1.1.0/design-artifacts/domain-models/unit2_lite_cycle_domain_model.md` | ドメインモデル設計 |
| `docs/cycles/v1.1.0/design-artifacts/logical-designs/unit2_lite_cycle_logical_design.md` | 論理設計 |

## 各フェーズのLite版差分

### Inception-Lite

- **スキップ**: PRFAQ作成
- **簡略化**: Intent、ユーザーストーリー、Unit定義

### Construction-Lite

- **スキップ**: Phase 1全体（ドメインモデル設計、論理設計、設計レビュー）
- **簡略化**: 直接実装、最小限テスト

### Operations-Lite

- 全ステップ任意（必要な場合のみ実施）

## サイクルタイプ識別

`.lite`ファイル方式を採用：
- Lite版サイクルの場合、`docs/cycles/vX.X.X/.lite` ファイルを作成
- ファイルの有無で判定可能

```bash
test -f docs/cycles/vX.X.X/.lite && echo "Lite" || echo "Full"
```

## 完了

- [x] ドメインモデル設計
- [x] 論理設計
- [x] 設計レビュー
- [x] コード生成（Lite版プロンプト作成）
- [x] テスト生成（整合性確認）
- [x] 統合とレビュー
