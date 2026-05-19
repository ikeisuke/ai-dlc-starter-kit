# Unit: 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)

## 概要

`skills/aidlc/scripts/lib/retrospective-fact-extract.sh`（または同等 API 関数）を新規追加し、(a) decisions.md / (b) construction review-summary / (c) history の 3 source 横断で事実テーブルを構造化抽出する helper を opt-in 提供する。セッションログ jsonl は file path 引数渡しの opt-in のみ（自動検出は対象外）。既存 §1.1.5 手動 Read 経路は破壊せず後方互換維持。

## 含まれるユーザーストーリー

- ストーリー 3: 三層検証 helper (3 source MVP + jsonl 引数 opt-in)

## 充足する Intent 成功基準

- SC-07（helper opt-in 追加 + 既存 §1.1.5 手動経路非破壊 + bats 単体テスト）

## 責務

- `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` 新規追加 or `retrospective-api.sh` 内関数追加
- 3 source の事実抽出関数実装:
  - (a) decisions.md → DR 件数・タイトル・主因 3 分類
  - (b) construction review-summary → review round 数・指摘件数・defer 件数
  - (c) history/*.md → 時系列イベント（タイムスタンプ + 概要）
- jsonl 引数渡し処理（file path 受け取り → 時系列イベント追加抽出）
- 出力形式: markdown 表形式（手動 §1.1.5 と diff 0 で一致）
- bats 単体テスト: 各 source ごとに正常系 / 空ファイル系 / ファイル不在系
- bats 統合テスト: 手動 §1.1.5 経路と helper 経路で同一 cycle データに対し diff 0
- bats jsonl テスト: 引数あり / なし両ケース

## 境界

- セッションログ jsonl の自動検出・ホームディレクトリ走査・パーミッション自動付与は本 Unit 対象外（v2.7.0+ defer）
- 既存 §1.1.5 手動 Read 経路の置き換えは行わない（後方互換維持）
- helper を §1.1.5 のデフォルト経路化する変更は本サイクル対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- スキル間依存ルール: `skills/aidlc/scripts/lib/` 配下に置き、`retrospective-api.sh` 公開 API 経由で呼び出し（内部実装直接 source 禁止）
- jsonl の典型パス: `~/.claude/projects/<repo>/*.jsonl`（任意パス引数指定可能）

## 非機能要件（NFR）

- **パフォーマンス**: 1 cycle 分の 3 source 抽出が 5 秒以内
- **セキュリティ**: jsonl 内の機密情報（API キー / トークン等）が事実テーブルに混入しないこと（抽出時の機密フィルタ）
- **可用性**: source ファイル不在時は warn 出力 + 当該 source をスキップして他 source 処理を継続

## 技術的考慮事項

- 出力 markdown 表形式の列構成は §1.1.5 既定と完全一致
- bats テストの fixture は本 cycle の `.aidlc/cycles/v2.6.5/` を流用可（v2.6.5 サイクル実データ）

## 関連Issue

- #652（OPEN / 本サイクル PR で Closes / 引数 opt-in までの完全実装で Close）
- #634（CLOSED / 参照のみ / 事実テーブル先抽出は v2.5.3 で導入済）

## 実装優先度

Medium

## 見積もり

0.5 営業日

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-19
- **完了日**: 2026-05-19
- **担当**: AI-DLC (Claude Code / codex)
- **エクスプレス適格性**: 適格
- **適格性理由**: 依存なし / 後方互換 opt-in 追加のみ / 既存テスト regression なし
