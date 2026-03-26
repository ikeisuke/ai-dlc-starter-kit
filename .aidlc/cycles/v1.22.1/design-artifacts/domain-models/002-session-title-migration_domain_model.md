# ドメインモデル: session-titleスキル移行

## 概要

session-titleスキルをスターターキット同梱からオプショナル外部スキルへ変更。スキルの実体削除と参照更新のみ。

## 影響する概念

### スキルカタログ（ai-tools.md）
- session-titleエントリを削除（スターターキット同梱でなくなるため）

### フェーズプロンプト（inception/construction/operations）
- session-title呼び出しセクションを「オプショナル」として表現更新
- 既存の「エラー時もスキップして続行」仕様は維持

### スキル利用ガイド（skill-usage-guide.md）
- スターターキット同梱スキルからsession-titleを除外
- 外部リポジトリからのインストール手順を追加
