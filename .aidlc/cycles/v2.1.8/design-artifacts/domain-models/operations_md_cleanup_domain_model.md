# ドメインモデル: operations.mdの構成整理

## 概要

`.aidlc/operations.md` のセクションを「共通」と「メタ開発固有」に分類し、明示的なマーキングで分離する。

## エンティティ

### OperationsSection（operations.mdセクション）

- **ID**: セクション見出し（例: `デプロイ方針`、`メタ開発特有のOperations Phase手順`）
- **属性**:
  - name: string - セクション名
  - scope: enum(common, meta_dev) - 共通 or メタ開発固有
  - marker: string | null - マーキングコメント（`<!-- META-DEV -->` or null）

## ユビキタス言語

- **共通セクション**: どのプロジェクトでも使う運用情報。マーキング不要
- **メタ開発固有セクション**: AI-DLCスターターキット自体の開発にのみ必要な手順。`<!-- META-DEV -->` マーキング必須
