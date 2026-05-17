# Unit: §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証

## 概要

Unit 001 で定義した `aggregate_issue_enabled` 仕様と cap 仕様を**利用する側**として、§1.5 Issue 起票フローを Try ループ化し、各 T Issue 本文に 5 セクション（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）を必須化する。`predecessor_resolve_issue` の既存 5 経路を破壊せず、集約 Issue 不在時の retrospective ラベル付き T Issue 群集計経路を追加する。最後に本サイクル自身の振り返りを新フローで dogfooding 検証し、CI green と後方互換 fixture pass、PR Closes/Comment 運用までを完了させる。

## 含まれるユーザーストーリー

- ストーリー 4A: §1.5 Issue 起票フロー Try ループ化 + T Issue 本文 5 セクション必須化
- ストーリー 4B: `predecessor_resolve_issue` 5 経路回帰 + 新動作経路追加
- ストーリー 4C: dogfooding 検証 + CI / 後方互換 + PR 運用証跡

## 充足する Intent 成功基準

- SC-02 / SC-03（T ループ起票 + 5 セクション必須）
- SC-08 / SC-09（predecessor 5 経路回帰 + 新動作経路）
- SC-10 / SC-11 / SC-12（dogfooding / CI green + 後方互換 / PR Closes・Comment）
- SC-04 の**検証責務のみ** (一次責務: fixture 整備 / 同等性テスト実装は Unit 001。本 Unit は Unit 001 で整備された fixture を最終 CI で再 pass 確認する責任のみを持つ)

## サブ責務ごとの完了ゲート（チェックリスト）

Unit 4 は Unit 内独立性を高めるため、サブ責務 4A / 4B / 4C ごとに完了ゲートを設ける。**実行順序ルール**: 4A と 4B は実装独立で**並列実行可**、4C は 4A + 4B の完了ゲート全項目 pass 後に着手する（検証フェーズ依存）。

### 4A 完了ゲート（実装独立）

- [ ] §1.5 Step 4 が Try ループ化されている
- [ ] 各 T Issue タイトル形式が確定
- [ ] 5 見出し非空 bats テスト pass
- [ ] cap 判定境界 bats テスト pass

### 4B 完了ゲート（実装独立 / 4A と並列可）

- [ ] `predecessor-issue.sh` 新動作経路追加
- [ ] サブ分岐名（`t_issue_milestone_scope` / `t_issue_label_fallback`）正式名称確定
- [ ] 既存 5 経路回帰 bats pass
- [ ] 新動作経路 bats pass
- [ ] 旧サイクル維持 bats pass

### 4C 着手条件 + 完了ゲート（検証フェーズ依存）

**着手条件**: 4A + 4B の完了ゲート全項目 pass、かつ Unit 001 / Unit 002 / Unit 003 完了

**完了ゲート**:

- [ ] dogfooding (a) (b) (c) 3 条件達成
- [ ] CI green
- [ ] 後方互換 fixture 再 pass 確認（fixture 自体は Unit 001 で整備済）
- [ ] PR Closes / Comment 4 項目記載
- [ ] CHANGELOG / リリースノート 3 項目記載

## 責務

### サブ責務 4A: §1.5 ループ起票

- `steps/retrospective.md` §1.5 Step 4 を Try 件数分ループに変更
- 各 T Issue のタイトル `[Retrospective: {cycle}] {Try 内容を 1 行で}` 生成ロジック
- 各 T Issue 本文に 5 見出し（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）+ 配下本文非空保証
- `templates/retrospective_template.md` の Try セクション再構成（5 セクション必須形式に合わせる）
- bats: 起票件数観測テスト（既定動作で集約 = 0、T = Try 件数）+ 各見出し配下非空チェック + cap 判定境界テスト

### サブ責務 4B: predecessor 互換 + 新動作経路

- `skills/aidlc/scripts/lib/predecessor-issue.sh` に新動作経路（集約 Issue 0 件 + retrospective ラベル付き T Issue 1 件以上で発火）を追加
- 内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback`（既存 5 経路名と衝突しない名前空間 / 正式名称は本 Unit で確定）の実装
- bats 回帰テスト 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）追加（v2.6.4 Unit 004 手動再現を bats 化）
- bats 新動作テスト: 新サブ分岐 2 種で `candidates` 配列 ≥ 1
- bats 旧サイクル維持テスト: 旧サイクル fixture で `resolution_path = milestone_and_label` 維持 + 新動作経路に入らない

### サブ責務 4C: dogfooding + CI/後方互換 + PR 運用証跡

- **開始条件**: SC-02/03/08/09 達成後に着手（実装独立ではなく検証フェーズ依存）
- 本サイクル v2.6.6 自身の振り返りを新フローで実施
  - (a) 全 T Issue で「主因切り分け」「構造課題昇格根拠」セクション非空
  - (b) §1.2.5 セルフレビュー 3 観点の AskUserQuestion 応答が retrospective 実行ログに残る
  - (c) §1.2.5 差し戻し機構動作検証は bats 陽性ケース pass で担保（実運用での差し戻し 0 件以上許容）
- CI green + 後方互換テスト pass の最終確認（fixture 整備 / 同等性テスト実装は Unit 001 の一次責務 / 本 Unit は最終 CI ジョブで全テスト pass を確認する検証責務のみ）
- PR 本文記載:
  - `Closes #704`
  - `Closes #652`
  - `Comment #710`（patch サブセット適用で minor 想定本体を先取り）
  - `Comment #715`（patch サブセット適用パターン実例）
- CHANGELOG / リリースノート 3 点必須記載:
  - 「集約 Issue が既定で生成されなくなる」
  - 「旧動作を維持するには `aggregate_issue_enabled = true` を明示設定」
  - 「retrospective ラベル付き T Issue 群が集約 Issue の代替として `predecessor_resolve_issue` で解決される」

## 境界

- `aggregate_issue_enabled` フラグ仕様 / cap 仕様の SoT 定義は Unit 001 に集約（本 Unit は利用側）
- §1.2.5 セルフレビュー観点と判別ガイド整備は Unit 002 に集約
- 三層検証 helper の実装は Unit 003 に集約
- 既存 5 経路の挙動変更は禁止（経路追加のみ）

## 依存関係

### 依存する Unit

- Unit 001（依存理由: `aggregate_issue_enabled` 仕様 SoT と同等性オラクル fixture が必要）
- Unit 002（依存理由: §1.2.5 セルフレビューが §1.5 起票直前に発火する前提）

### 外部依存

- 既存 `retrospective_api_create_issue` / `retrospective_dialog_token_verify` API
- v2.6.4 で導入された `auto_issue_creation` opt-in 基盤（挙動維持 / 干渉しないこと）
- GitHub Issue API（gh CLI 経由 / 既存経路）

## 非機能要件（NFR）

- **パフォーマンス**: T 件数 N に対し O(N) 起票時間（dialog token TTL 300 秒内に N ≤ cap 値の起票が完了）
- **セキュリティ**: 各 T Issue 本文に機密情報を含めない（既存機密スキャン経路を維持）
- **後方互換性**: `aggregate_issue_enabled = true` 明示時に v2.6.5 fixture と差分 0 の出力（SC-04 の同等性 5 項目 / fixture は Unit 001 で整備済 / 本 Unit は最終 CI 再 pass のみを担う）
- **可用性**: cap 上限到達時の追加起票拒否動作が新旧両仕様で正しく機能

## 技術的考慮事項

- Try ループ起票は `retrospective_api_create_issue` を T 件数分繰り返し呼び出す（API シグネチャ不変）
- 各 T Issue 起票直前に dialog token 検証 / TTL 300 秒以内で完了
- dogfooding 実施タイミング: Construction 全 Unit 完了後、Operations Phase §1 retrospective ステップ
- 5 セクション必須化に伴う既存 `templates/retrospective_template.md` 改修は本 Unit で実施

## 関連Issue

- #710（CLOSED / 方針親 / 本サイクル PR で Comment）
- #715（OPEN / 実例パターン / 本サイクル PR で Comment）
- #704 / #652（Unit 002 / Unit 003 で Closes 対応 / 本 Unit は PR 記載の確認のみ）

## 実装優先度

High（リリース判定の最終 Unit）

## 見積もり

1.5 営業日（4A: 0.4 / 4B: 0.4 / 4C: 0.5 + バッファ 0.2）。

**最低限必達（SC 直結）**: 4A 完了ゲート + 4B 完了ゲート + 4C 完了ゲート（全 SC-02/03/08/09/10/11/12 達成）

**余裕があれば**: bats テストの追加カバレッジ（cap 境界の追加ケース、jsonl 引数の異常系等）、リリースノート文言推敲。これらは未達でも patch リリース可能だが、品質向上に寄与する。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
