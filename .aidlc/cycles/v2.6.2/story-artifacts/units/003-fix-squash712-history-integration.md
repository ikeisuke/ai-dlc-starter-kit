# Unit: Operations §7.12.5 squash-712 と write-history operations-round の整合性

## 概要

Operations Phase §7.12 PR レビュー反映後の `squash-712` 統合 commit に `history/operations.md` の追記を確実に取り込ませる、または unstaged 差分を伴う `squash-712` 実行を fail-fast で検出して止める実装を追加する。Issue #677（振り返り分離関連の致命的バグ）。

## 含まれるユーザーストーリー

- ストーリー 1: Operations §7.12.5 squash-712 と write-history operations-round の不整合解消

## 責務

- 案 A（write-history auto-commit 化）: `write-history.sh --mode operations-round` 実行で history を自動 commit。`--no-commit` opt-out フラグ提供
- 案 B（squash-712 fail-fast 化）: `squash-712` 起動時に `history/operations.md` 等 history 系の dirty 状態を検出して exit 1 + 案内出力
- 案 A / 案 B / A+B 併用のいずれを採用するかは Construction 設計レビューで確定（**案 C「手順書 SoT 明示化のみ」は単独不可、補助併用のみ可**）
- 採用案に応じた integration テスト（`§7.12 → write-history → squash-712 → git log` で 1 squash commit を確認）追加
- bats テストで案 A / 案 B 各 AC を網羅
- CHANGELOG / 関連手順書の更新（採用案次第）

## 境界

- Operations §7.12 / §7.12.5 周辺に閉じる。他フェーズ（Construction Phase の Unit 完了 squash 等）の auto-commit / fail-fast 化は本 Unit 対象外（既存 #654 で構造解決済み）
- 案 C「手順書 SoT 明示化」は本 Unit 内で実施可能だが、案 A/B のいずれかと併用するときのみ意味を持つ

## 依存関係

### 依存する Unit

- なし

### 外部依存

- bash + git（既存 operations-release.sh / write-history.sh の動作環境）
- bats / shellcheck / shellharden（既存テスト環境）
- AI-DLC Operations Phase の standard フロー定義（`steps/operations/operations-release.md`）

## 非機能要件（NFR）

- **可搬性**: 採用案実装は merge_method=merge 時に main に細粒度 commit が残らない効果が確実に得られる
- **後方互換性**: 案 A 採用時は `--no-commit` で従来挙動 opt-out 可能
- **テスタビリティ**: 採用案ごとの専用 AC を bats / integration テストで自動検証可能

## 技術的考慮事項

- 採用案の選択は Construction 設計レビューで判断する。意思決定記録は `inception/decisions.md` に Inception 段階での既知制約（A/B/A+B 必須、C は補助）として記録
- 案 A 採用時の責務切り分け: `write-history.sh` の `--mode` ごとに auto-commit ポリシーを分岐（operations-round 限定で auto-commit、construction / inception 系は append のみ維持）
- 案 B 採用時の dirty 判定対象ファイル: 少なくとも `history/operations.md`、必要に応じて他 history 系。具体的なパターンは設計時に確定
- A+B 併用時は多層防御として機能（write-history が auto-commit を試みた後でも何らかの理由で dirty 残存した場合に squash-712 が fail-fast）

## Intent 制約適合

- **破壊的変更なし**: 案 A 採用時は `--no-commit` で従来挙動 opt-out 可能。案 B 採用時はエラー検出のみ追加で正常系には影響しない
- **ドッグフーディング特殊処理禁止**: 採用案ロジックは consumer プロジェクトでも同一動作。自リポジトリ判定による分岐は導入しない
- **コマンド置換禁止**: 実装内で `$(...)` 形式のコマンド置換を新規導入しない（既存 write-history.sh / operations-release.sh の規約踏襲）

## 関連Issue

- #677（フィードバック / 致命的バグ / 振り返り分離関連 / mirror 由来）

## 実装優先度

High（致命的バグ）

## 見積もり

1〜2 日。Construction 設計レビューで採用案確定後、案 A / 案 B / A+B 併用のいずれを採るかで規模が変動（案 A 単独 0.5〜1 日、案 B 単独 0.5 日、A+B 併用 1.5 日）。integration テスト整備込み。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-11
- **完了日**: 2026-05-12
- **担当**: Claude（AI-DLC AI エージェント）+ Keisuke Isono（ユーザー）
- **エクスプレス適格性**: -
- **適格性理由**: -
