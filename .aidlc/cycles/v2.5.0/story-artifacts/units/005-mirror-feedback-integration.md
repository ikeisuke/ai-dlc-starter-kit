# Unit: mirror モードの /aidlc-feedback 連動

## 概要

`feedback_mode = "mirror"` 設定下で、retrospective.md の `skill_caused = true` 項目について「Issue 下書き生成 → AskUserQuestion で承認取得 → /aidlc-feedback 経由で upstream Issue 起票」のフローを実装する。送信時に Issue URL を retrospective.md に追記する。

## 含まれるユーザーストーリー

- ストーリー 6: feedback_mode=mirror の /aidlc-feedback 連動

## 責務

- retrospective.md パーサー: `skill_caused` フラグと引用箇所・問題本文を抽出
- Markdown スニペット形式の Issue 下書き生成（タイトル / 本文 / 検出元: サイクル・Unit / 引用箇所）
- `AskUserQuestion` で「送信する / 送信しない / 後で判断（保留）」の 3 択提示
- 「送信する」選択時: `/aidlc-feedback` スキル経由で Issue 起票し、Issue URL を retrospective.md の該当項目に追記
- 「送信しない / 保留」選択時: ローカル記録のみで Issue 起票しない
- `feedback_mode = "silent"` (デフォルト) の場合は本フロー全体スキップ

## 境界

- retrospective テンプレートと Operations サブステップは Unit 004 が責務
- 重複検出・上限ガードは Unit 006 が責務（本 Unit は単純に「skill_caused=true なら下書き生成 → 承認 → 送信」まで）
- `feedback_mode = "on"`（自動起票）は v2.5.0 スコープ外

## 依存関係

### 依存する Unit

- Unit 004（前提: retrospective テンプレート と skill 起因判定が実装されている）

### 外部依存

- 既存スキル: `/aidlc-feedback`（送信先設定を流用）
- `gh` CLI（Issue 起票時に利用）

## 非機能要件（NFR）

- **誤起票防止**: ユーザー承認なしに Issue 起票しない（AskUserQuestion 必須）
- **送信失敗ハンドリング**: `gh` エラー時は retrospective.md に「PENDING_MANUAL: Issue 起票失敗（理由）」を記録、再試行可能な状態を残す
- **トレーサビリティ**: 起票成功時、retrospective.md の該当項目に Issue URL を追記する

## 技術的考慮事項

- 下書き Markdown スニペット形式は upstream Issue テンプレートと整合（`/aidlc-feedback` の既存出力に揃える）
- `--reason mirror` フラグを `/aidlc-feedback` に渡し、誰がどのフローから送ったか分かるようにする（送信先側のラベル/リード文に反映する想定）
- 保留選択時は retrospective.md に「保留」フラグを追加し、次サイクルで再度提示できる状態を残す（具体実装は v2.6.x で改善余地）

## 関連Issue

- #590（部分対応: 実装スコープ 5 を担当）

## 実装優先度

High（mirror モードの体験を v2.5.0 で確認するための中核）

## 見積もり

1.0 セッション（パーサー + 対話 + 起票 + URL 追記）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-29
- **完了日**: 2026-04-29
- **担当**: Construction Phase Unit 005
- **エクスプレス適格性**: -
- **適格性理由**: -
