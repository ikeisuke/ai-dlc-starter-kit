# Unit: dasel 直接呼び出しの `read-config.sh` 経由統一 + 規約追記

## 概要

`.aidlc/config.toml` 読取で AI エージェントが `dasel -f <file> '<key>'`（dasel CLI v3 で `unknown flag` エラーになる不正フラグ）を誤生成しがちな問題に対し、(1) `feedback.md` 等の dasel 直接呼び出しを `read-config.sh` 経由に統一、(2) `rules-core.md` に dasel CLI v3 制約と禁止フラグを明文化、の 2 軸で構造的予防を行う。

## 含まれるユーザーストーリー

- ストーリー 4: dasel 直接呼び出しの `read-config.sh` 経由統一

## 責務

- `skills/aidlc-feedback/steps/feedback.md` をはじめとする dasel 直接呼び出し箇所を `scripts/read-config.sh` 経由に置換
- `steps/common/rules-core.md` に「dasel CLI v3 では `-f` フラグ非対応 / 直接呼び出し時は `cat file | dasel -i toml '<key>'` または `dasel -i toml '<key>' < file` のみ許容」を明記
- `rules-core.md` に「禁止呼び出しパターン」セクションを新設し、`dasel -f` / その他 AI エージェントが誤生成しがちな anti-pattern を列挙

## 境界

- `scripts/read-config.sh` 自体の機能拡張は対象外（既存インターフェース維持）
- dasel v3 → v4 へのアップグレード対応は対象外
- 他のスキル（`reviewing-*` など）の dasel 利用は本 Unit のスコープ確認後に必要なら波及修正（対象範囲は Construction 計画レビューで確定）

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- dasel v3
- bash
- `scripts/read-config.sh`（既存）

## 非機能要件（NFR）

- **パフォーマンス**: `read-config.sh` 経由のオーバーヘッドは config 読取 1 回あたり数 ms 程度で許容
- **セキュリティ**: 設定値の読取経路統一により、`.aidlc/config.toml` の変更検出可能性が向上
- **スケーラビリティ**: N/A
- **可用性**: dasel v3 環境で 100% 動作（既存 `read-config.sh` の動作保証範囲）

## 技術的考慮事項

- `rules-core.md` の規約追記は AI エージェントへの誘導効果を最大化するよう、具体例（OK / NG）を併記する形にする
- 「禁止呼び出しパターン」セクションは既存の「## コマンド実行ルール」と整合する位置に配置
- Unit 003（#690）と並行実行可だが、Unit 003 が `[rules.feedback].open_in_browser` 読取で `read-config.sh` 経由を採用するため、本 Unit の規約追記が先行すると整合性が取りやすい

## 関連Issue

- #689

## 実装優先度

Medium（教育的・規約強化、即時のバグ性は低いが再発防止効果大）

## 見積もり

0.5 day（feedback.md 等の置換 + rules-core.md 改訂 + 影響範囲調査 + テスト）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC（Claude Code）
- **エクスプレス適格性**: -
- **適格性理由**: -
