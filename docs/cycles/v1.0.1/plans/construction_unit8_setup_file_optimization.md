# Construction Phase: Unit 8 実行計画

## Unit概要
**Unit名**: セットアップファイルの最適化
**優先度**: Critical（最優先）
**見積もり**: 3.5時間

## 背景・目的
- `prompts/setup-prompt.md` が1746行に達し、Claude Codeでの読み込みに支障
- セットアップファイルは全フェーズの起点であり、緊急対応が必要
- フェーズ別に分割し、メンテナンス性を向上

---

## Phase 1: 設計（コードは書かない）

### ステップ1: ドメインモデル設計（0.5時間）
- セットアップファイルの構造分析
- 責務の分類（共通処理、フェーズ別処理）
- 境界の明確化

**成果物**: `docs/cycles/v1.0.1/design-artifacts/domain-models/unit8_domain_model.md`

### ステップ2: 論理設計（0.5時間）
- 分割後のファイル構成設計
- ファイル間の参照関係定義
- 圧縮方針の具体化

**成果物**: `docs/cycles/v1.0.1/design-artifacts/logical-designs/unit8_logical_design.md`

### ステップ3: 設計レビュー
- 設計内容をユーザーに提示
- 承認を得てから実装フェーズへ

---

## Phase 2: 実装

### ステップ4: コード生成（2時間）

#### 4.1 新規ファイル作成
```
prompts/setup-prompt.md (メイン、300行目安)
├── 変数定義
├── MODE判定
└── セットアップフロー（各フェーズファイルを参照）

prompts/setup/inception.md (500行目安)
├── inception.mdプロンプト生成
└── Inception用テンプレート

prompts/setup/construction.md (500行目安)
├── construction.mdプロンプト生成
└── Construction用テンプレート

prompts/setup/operations.md (500行目安)
├── operations.mdプロンプト生成
└── Operations用テンプレート

prompts/setup/common.md (200行目安)
├── ディレクトリ作成
├── 共通ファイル生成
└── 完了処理
```

#### 4.2 圧縮作業
- 冗長な説明・コメントの簡潔化
- 繰り返し表現の統合
- テンプレート内の空行削減

### ステップ5: テスト（0.5時間）
- 分割後のファイルでセットアップが正常に完了することを確認
- 既存機能の動作確認

### ステップ6: 統合とレビュー
- 実装記録作成
- コードレビュー

**成果物**: `docs/cycles/v1.0.1/construction/units/unit8_implementation.md`

---

## 完了基準
- [ ] ドメインモデル設計完了
- [ ] 論理設計完了
- [ ] 設計レビュー承認
- [ ] ファイル分割実装完了
- [ ] 各ファイル500行以内
- [ ] セットアップ動作確認完了
- [ ] 実装記録作成
- [ ] progress.md更新
- [ ] history.md追記
- [ ] Gitコミット

---

## リスクと対策
| リスク | 対策 |
|--------|------|
| 分割による動作不良 | 段階的に分割、各段階で動作確認 |
| テンプレート参照の破損 | 分割前後で出力内容を比較 |
| 行数目安オーバー | 優先度をつけて圧縮を追加実施 |

---

## 作成日時
2025-11-28
