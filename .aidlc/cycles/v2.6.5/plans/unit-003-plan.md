# Unit 003 実装計画: Operations §7.13 直前マージ前完結契約最終確認プロンプト追加

## 対象 Unit

- **Unit**: 003 - Operations §7.13 直前マージ前完結契約最終確認プロンプト追加
- **関連 Issue**: #641（クローズ対象）
- **優先度**: High
- **depth_level**: standard

## 背景・目的

Operations §7.13（PR マージ実行）の AskUserQuestion 直前に「マージ前完結契約最終確認」AskUserQuestion を automation_mode 非依存・例外なしで常時実行。既存 post-merge ガード（`write-history.sh exit 3`）と対称な pre-merge 予防として機能させる。

## スコープ

### 含まれるもの

- `skills/aidlc/steps/operations/operations-release.md` の §7.13 内「マージ実行確認」**直前**（既存「マージ方法の確定」「設定保存フロー」「未コミット差分検出ガード」のすべての完了後）にマージ前完結契約最終確認の AskUserQuestion ステップを挿入。**挿入位置を不変条件として固定**（曖昧挿入禁止 / `merge_method` 決定・config 差分解消後であること）
- `skills/aidlc/steps/operations/02-deploy.md` の §7.13 サブステップ一覧 line 197 には**確認の存在のみ明示**（目次責務）。文言・選択肢・例外条件の SoT は `operations-release.md` のみで管理（二重 SoT 化禁止）
- 提示メッセージ仕様: 凍結対象ファイル一覧（progress.md ステップ7 完了確定済の旨）+ post-merge write-history.sh exit 3 ガード説明 + 選択肢
- 選択肢（choice_id 固定）: `proceed_to_merge`（記録漏れなし、マージに進む）/ `back_to_record`（記録を追加する → §7.6/§7.7 へ戻る）
- automation_mode 非依存（`full_auto` 含む全モードで常時実行 / SKILL.md「AskUserQuestion 使用ルール」のユーザー選択種別として整合）
- 検証ケース (a) 通常 / (b) 修正コミット欠落 / (c) 空 PR / (d) 緊急マージ / (e) semi_auto を計画書末尾に列挙
- 本サイクル自身の Operations Phase で (a) 通常経路をドッグフーディング検証（Operations §7.13 通過時に retrofit で記録）

### 含まれないもの

- post-merge ガード自体（`write-history.sh exit 3`）の改修
- §7.13 以外の AskUserQuestion ポイントへの拡張
- `automation_mode=full_auto` 仕様自体の見直し
- 「記録を追加する」選択時の §7.6/§7.7 戻りロジック自体（既存実装に従う）

## 実装方針

### Phase 1: 設計

- ドメインモデル: `PreMergeFinalConfirmation` 集約 / `ChoiceId` enum / `FrozenFile` 値オブジェクト
- 論理設計: `operations-release.md` §7.13 内「マージ実行確認」直前の挿入位置確定 + 質問文字列・選択肢 SoT 化 + 02-deploy.md サブステップ一覧への明示反映

### Phase 2: 実装

1. `operations-release.md` の「マージ実行確認」直前に「マージ前完結契約最終確認」セクション追加
2. `02-deploy.md` line 197 の §7.13 表記に確認の存在を明示
3. 検証ケース (a)〜(e) を計画書末尾に記載

## 完了条件チェックリスト

### #641 受け入れ基準

- [x] `operations-release.md` §7.13 内「マージ実行確認」直前にマージ前完結契約最終確認 AskUserQuestion セクションが追加されている
- [x] 挿入順序の不変条件（`マージ方法確定 → 設定保存フロー → 未コミット差分検出ガード → 【新規】マージ前完結契約最終確認 → マージ実行確認 → §7.13 マージ実行`）が明示されている
- [x] `02-deploy.md` §7.13 サブステップ一覧に確認の**存在のみ**が明示されている（二重 SoT 化禁止 / 文言・選択肢の SoT は `operations-release.md`）
- [x] `back_to_record` 選択時の再入契約（`§7.6/§7.7 → §7.8〜§7.12.6 再通過 → 新規最終確認 → マージ実行確認 → §7.13`）が記述されている
- [x] 質問文字列に凍結対象ファイル一覧 + post-merge write-history.sh exit 3 ガード説明が含まれる
- [x] 選択肢 `proceed_to_merge` / `back_to_record` が `choice_id` 固定で定義されている
- [x] automation_mode 非依存・例外なし常時実行が明文化されている（`full_auto` を含む全モード対象）
- [x] 検証ケース (a)〜(e) が計画書または実装記録に列挙されている
- [ ] 本サイクル Operations Phase で (a) 通常経路の retrofit ドッグフーディング検証結果が `history/operations.md` または `construction_unit03.md` に記録されている（注: 本サイクル Operations Phase §7.13 通過時に retrofit 記録する。Construction Phase Unit 003 完了時点では未到達のため `[ ]`）

### 共通

- [x] markdownlint で新規エラー 0 件
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている

## 検証ケース定義

| ケース | 説明 | 期待動作 |
|--------|------|---------|
| (a) 通常 | 全工程通過後マージ前確認 | AskUserQuestion 表示 → `proceed_to_merge` 選択 → §7.13 マージ実行へ |
| (b) 修正コミット欠落 | (2c) 履歴コミット忘れでマージ前確認 | AskUserQuestion 表示 → `back_to_record` 選択 → §7.6/§7.7 へ戻り履歴追記 → **§7.8〜§7.12.6 を再通過** → 新規最終確認 → マージ実行確認 → §7.13 マージ実行（再入契約: 段階依存維持のため途中工程スキップ禁止） |
| (c) 空 PR | 差分なし PR でマージ前確認 | AskUserQuestion 表示 → `proceed_to_merge` 選択可（空 PR でも本確認は実施） |
| (d) 緊急マージ | hotfix 等の緊急パスでマージ前確認 | AskUserQuestion 表示 → 例外なし（automation_mode 非依存・全経路で実施） |
| (e) semi_auto | automation_mode=semi_auto でマージ前確認 | AskUserQuestion 表示 → semi_auto でも常時実行（ユーザー選択種別） |

## リスク・考慮事項

- 既存 §7.13「マージ実行確認」と本確認が二重提示にならないか → 役割分担明示: 「マージ前完結契約最終確認」=「記録完了 / 凍結対象確認」、「マージ実行確認」=「マージ方法と PR 番号の最終承認」
- post-merge ガード `write-history.sh exit 3` との対称性: 「pre-merge: 記録漏れ予防」「post-merge: 記録試行検出」の双方向ガード
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない
