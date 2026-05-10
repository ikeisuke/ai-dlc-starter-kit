# Unit: aidlc-feedback の `--web` 強制起動解消（opt-in 化）

## 概要

`/aidlc feedback` のデフォルト経路を `gh issue create --web`（ブラウザ強制起動）から `gh issue create --body-file ...`（直接起票）へ変更する。`[rules.feedback].open_in_browser` 設定または明示的フラグでのみ `--web` 経路を選ぶ opt-in 構造に再設計し、非 TTY / CI 環境では常に直接起票を採用する。

## 含まれるユーザーストーリー

- ストーリー 3: `aidlc-feedback` のブラウザ強制起動を解消

## 責務

- `skills/aidlc-feedback/steps/feedback.md` の手順を「直接起票を主経路、`--web` を opt-in」に書き換える
- `[rules.feedback].open_in_browser`（または等価キー）の追加と、優先順位 **TTY 状態 > 設定 > フラグ** の明文化（**非 TTY は常に直接起票（`--web` 無効 + 警告ログ）**、TTY では設定 > フラグ）。ユーザーストーリー 3 の「優先順位真理値表」を SoT とする
- 非 TTY 判定（`[[ -t 0 ]]` 等）による CI 安全動作の組込み
- 起票内容のユーザー承認フロー（feedback.md 手順 1 のヒアリング）の維持

## 境界

- feedback Issue 本体のテンプレート（`.github/ISSUE_TEMPLATE/feedback.yml`）構造変更は対象外（本 Unit ではテンプレート参照経路のみ調整）
- 他の `/aidlc *` スキルでの `--web` 利用は対象外
- `aidlc-feedback` スキルが扱うラベル付与・タイトル整形ロジックは変更しない

## 依存関係

### 依存する Unit

- Unit 004（dasel 直接呼び出しの `read-config.sh` 経由統一）（推奨依存 / 強制依存ではない）
  - 理由: 本 Unit で `[rules.feedback].open_in_browser` 設定を読み出す際、Unit 004 の `read-config.sh` 経由統一規約に従って実装するのが望ましい
  - 強制依存にしない理由: 本 Unit 単独でも `read-config.sh` を呼ぶだけで完結するため、Unit 004 の規約追記が無くても実装可能。並行実行可

### 外部依存

- gh CLI（`gh issue create --body-file` 経路）
- bash（`[[ -t 0 ]]` 判定）

## 非機能要件（NFR）

- **パフォーマンス**: 直接起票の場合、ブラウザ起動コスト分（数秒）の改善
- **セキュリティ**: feedback 本文に機密情報が混入しないよう、ヒアリング時のレビュー継続。マスクポリシーは review-flow.md 既定に従う
- **スケーラビリティ**: 複数件連続起票時の摩擦をゼロにする（auto mode 一括起票も成立）
- **可用性**: gh CLI 経由のため変化なし

## 技術的考慮事項

- TTY 状態 / 設定 / フラグの優先順位はユーザーストーリー 3 の「優先順位真理値表」を SoT とする（intent.md 成功基準と整合）
- `--web` opt-in は CHANGELOG で「破壊的変更ではないがデフォルト挙動変更」として明示
- 非 TTY 判定は実装時に `command -v test` ではなく bash builtin の `[[ -t 0 ]]` で実装

## 関連Issue

- #690

## 実装優先度

Medium（UX 退行、影響範囲は feedback コマンドに限定）

## 見積もり

0.5 day（feedback.md 改訂 + 設定キー追加 + 非 TTY 判定実装 + bats テスト更新）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC（Claude Code）
- **エクスプレス適格性**: -
- **適格性理由**: -
