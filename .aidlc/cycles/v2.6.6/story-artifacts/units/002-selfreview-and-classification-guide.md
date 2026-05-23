# Unit: §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

## 概要

`steps/retrospective.md` に新ステップ §1.2.5「Try 構造性セルフレビュー」を追加し、Try が個別チェック追加で済まされる表面的振り返りを構造的に防ぐ。AskUserQuestion 経由で 3 観点を必須確認し、表面的判定時は最大 3 回まで Try 起草に差し戻す。上限到達時は `selfreview-capped` ラベルを T Issue に付与して起票許可。あわせて 3 問固定の判別質問テンプレを `templates/try_classification_guide.md` として追加する。

## 含まれるユーザーストーリー

- ストーリー 2: §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

## 充足する Intent 成功基準

- SC-05（§1.2.5 ステップ追加 + 差し戻し + `selfreview-capped` 警告ラベル）
- SC-06（`try_classification_guide.md` 追加 + 3 問固定 + §1.2.5 からの参照）

## 責務

- `steps/retrospective.md` §1.2 主因切り分け後・§1.5 Issue 起票前に **新ステップ §1.2.5** を挿入
- §1.2.5 内に AskUserQuestion 必須 3 観点（「気をつける」逃げ / 個別→構造昇格 / 再発防止チェック逃げ）を記述
- 差し戻しループ上限 3 回 / 上限到達時 `selfreview-capped` ラベル付与ロジックを定義
- `skills/aidlc-retrospective/templates/try_classification_guide.md` 新規追加（3 問固定: 再発性 / 対象レイヤ / 再入余地）
- §1.2.5 から `try_classification_guide.md` への参照リンク追加
- `selfreview-capped` GitHub ラベル存在保証機構の実装（**本サイクル必達**）:
  - **設計**: §1.5 起票直前に `retrospective_api_ensure_label "selfreview-capped"` を呼び、ラベル不在時は `gh label create selfreview-capped --color BFD4F2 --description "Try 構造性セルフレビュー上限到達"` で自動作成する fail-safe 経路
  - **権限不足時**: `gh label create` が失敗（permission denied 等）した場合、当該 T Issue 起票を中断し warn 通知（ラベル付与なしの起票は許可しない / fail-fast）
  - bats テスト: ラベル既存ケース（自動作成スキップ）/ ラベル不在ケース（自動作成成功）/ 権限不足ケース（fail-fast）
- bats テスト追加: 表面的 Try 陽性ケース（必ず差し戻し）+ 構造改善 Try 陰性ケース（差し戻しなし）

## 境界

- 本 Unit は §1.2.5 ステップ追加と判別ガイド整備まで
- §1.2.5 で得た「構造課題昇格根拠」を T Issue 本文の必須セクションに反映する処理は Unit 004 (ストーリー 4A) に委譲
- セルフレビュー差し戻し履歴の retrospective ログ記録形式は本 Unit で定義（Unit 004 で利用）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `skills/aidlc/SKILL.md`「AskUserQuestion 使用ルール」の「ユーザー選択（振り返り内容の決定）」種別仕様
- 既存 dialog token 機構（`retrospective_dialog_token_verify` / TTL 300 秒）

## 非機能要件（NFR）

- **パフォーマンス**: セルフレビュー 1 回あたりの追加対話 ≤ 3 質問 × Try 件数 + 差し戻し時 再質問。dialog token TTL 内で完了
- **セキュリティ**: セルフレビュー回答ログに機密情報を含めない（履歴記録時の機密除外チェック）
- **可用性**: AskUserQuestion 失敗時はセルフレビュー結果を `undecidable` 扱いとして差し戻し不可（ユーザー判断待ち）

## 技術的考慮事項

- AskUserQuestion は dialog token TTL（300 秒）に干渉しないよう、§1.5 Step 4 直前の token verify 前に完了させる
- 3 問固定判別ガイドは markdown テンプレとしてそのままユーザーに提示可能な形式で記述
- 本 Unit でラベル自動作成 fail-safe を実装するため、`aidlc-setup` フロー側への組み込み（事前定義スクリプト追加）は**本サイクル対象外**（別 Issue で defer）。本サイクルでは runtime 自動作成で必ず成立を保証

## 関連Issue

- #704（OPEN / 本サイクル PR で Closes / Try B 相当の Retrospective skill セルフレビュー観点不在を解消）

## 実装優先度

High

## 見積もり

0.5 営業日

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-18
- **完了日**: 2026-05-18
- **担当**: AI-DLC (Claude Code / codex)
- **エクスプレス適格性**: 適格
- **適格性理由**: depth_level=standard / 設計レビュー 2R clean / コードレビュー 3R clean / 統合レビュー 1R clean / bats 全 452 件 pass (Unit 002 新規 29 件 + 既存 423 件) / markdownlint 6 ファイル 0 error
