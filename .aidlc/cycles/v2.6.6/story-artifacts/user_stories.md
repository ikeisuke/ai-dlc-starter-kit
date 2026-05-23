# ユーザーストーリー

## Epic: aidlc-retrospective skill の T 中心リファクタ + 本質的振り返り化（v2.6.6 patch）

KPT を手段、T の Issue 化を目的として skill 構造を再定義し、表面的振り返りを構造的に防ぐセルフレビュー機構を内蔵する。後方互換オプション `aggregate_issue_enabled` で旧動作（集約 Issue 起票）を opt-in 復元可能とする patch リリース。

関連 Issue: 本命 #704 / #652（Close 対象）、方針親 #710（Comment）、実例パターン #715（Comment）。

### ストーリー / Unit マッピング

| ストーリー | Unit | 充足する Intent 成功基準 |
|----------|------|--------------------------|
| 1. T 中心アウトプット仕様 + フラグ + cap 仕様 SoT | Unit 1 | SC-01 / SC-04 |
| 2. §1.2.5 セルフレビュー + 判別ガイド | Unit 2 | SC-05 / SC-06 |
| 3. 三層検証 helper (3 source MVP + jsonl 引数 opt-in) | Unit 3 | SC-07 |
| 4A. §1.5 ループ起票実装 + T Issue 本文 5 セクション | Unit 4 | SC-02 / SC-03 |
| 4B. `predecessor_resolve_issue` 5 経路回帰 + 新動作経路追加 | Unit 4 | SC-08 / SC-09 |
| 4C. dogfooding 検証 + CI/後方互換 + PR 運用証跡 | Unit 4 | SC-10 / SC-11 / SC-12 |

ストーリー 4A/4B/4C はいずれも Unit 4 配下で並列・順次に実装する。Unit 4 内のサブストーリー分割は失敗時の切り分け単位を細かくするため。

---

### ストーリー 1: T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

**優先順位**: Must-have

As a AI-DLC を採用するプロジェクトのメンテナ
I want to 振り返り skill の出力形態（集約 Issue vs T ループ起票）を `aggregate_issue_enabled` フラグで切り替えられ、cap 判定の意味も同フラグに連動して定義されること
So that v2.6.5 までの旧動作を後方互換オプションとして残しつつ、新規ユーザーには T 中心の新動作を既定として提供できる

**受け入れ基準**:

- [ ] `skills/aidlc-retrospective/SKILL.md` 冒頭に「目的: T を Issue 化して実行に繋げること。KPT は T を導くための手段」が SoT として記載されている → SC-01
- [ ] `skills/aidlc-retrospective/steps/retrospective.md` 冒頭にも同 SoT が記載されている → SC-01
- [ ] `config/defaults.toml` (aidlc / aidlc-setup 両方) に `rules.retrospective.aggregate_issue_enabled = false` が追加され、defaults 二重 SoT CI ガードが pass
- [ ] `skills/aidlc-retrospective/SKILL.md` または `steps/retrospective.md` 内に **「`aggregate_issue_enabled` の意味と cap 判定への影響」の仕様節** が存在し、以下を明示する（本ストーリーが当該仕様の単一 SoT）:
  - `true`: 集約 Issue 1 件起票（v2.6.5 同等動作）、`feedback_max_per_cycle` は「集約 Issue 件数上限」として作用
  - `false` (既定): T 件数分ループ起票、`feedback_max_per_cycle` は「サイクル内 T Issue 起票合計上限」として作用
- [ ] `skills/aidlc/scripts/lib/retrospective-api.sh` に `retrospective_api_aggregate_enabled` 判定 helper が追加され、既存関数シグネチャは不変
- [ ] `tests/fixtures/retrospective_v265_aggregate.json` が新規追加され、v2.6.5 同等出力の同等性オラクル（タイトル / 本文見出し集合 / ラベル集合 / cap 判定結果）を保持する → SC-04 の比較対象
- [ ] `aggregate_issue_enabled = true` 明示時の集約起票が上記 fixture と差分 0 で一致する bats テストが pass → SC-04

**技術的考慮事項**:

- `aggregate_issue_enabled` は `auto_issue_creation`（v2.6.4 / 起票そのものの ON/OFF）とは独立した別軸
- `config.toml` / `config.local.toml` / `defaults.toml` の 4 階層マージで正しく解決
- 本ストーリーは「仕様 SoT 定義 + 同等性オラクル fixture 整備」までを担い、実装利用（ループ起票実体 / 既定動作の cap 判定）はストーリー 4A に委譲

---

### ストーリー 2: §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

**優先順位**: Must-have

As a 振り返り skill 実行者（AI エージェント or 人間）
I want to Try を Issue 化する直前に「これは個別チェック追加で逃げていないか / Problem を構造課題に昇格させたか」のセルフレビューを必須実施できること
So that 振り返りが「次回から気をつける」「再発防止チェックを 1 項目追加」で済む表面的なものに留まらず、構造改善寄りの Try に収束する

**受け入れ基準**:

- [ ] `steps/retrospective.md` §1.2 主因切り分け後・§1.5 Issue 起票前に **新ステップ §1.2.5「Try 構造性セルフレビュー」** が追加される（ステップ番号 §1.2.5 が新規セクション見出しとして存在）→ SC-05
- [ ] §1.2.5 内で AskUserQuestion 経由で以下 3 観点を必須確認する手順が記載される:
  - Try が「次回から気をつける / チェックを 1 項目追加する」で済んでいないか
  - Problem を個別事象から構造課題（プロセス / 設計 / 規約 / SoT）に昇格できているか
  - P → T が再発防止チェックの追加で逃げていないか
- [ ] 「該当する（= 表面的）」回答時に Try 起草に差し戻すループが定義され、上限 3 回。上限到達時は T Issue 起票時に `selfreview-capped` ラベルが付与される（bats: 表面的 Try 入力時のラベル付与を観測）→ SC-05
- [ ] `skills/aidlc-retrospective/templates/try_classification_guide.md` が新規追加され、以下 3 問固定の判別質問テンプレを含む → SC-06:
  1. 再発性（直近 3 サイクル / 評価窓: 本サイクルを含まない直前 3 サイクル分の `cycles/v*/operations/` + retrospective Issue）
  2. 対象レイヤ（心がけ vs skill/プロンプト/SoT/CI ガード）
  3. 再入余地（別の入り口から踏める余地）
- [ ] §1.2.5 から `try_classification_guide.md` への参照リンクが存在する → SC-06
- [ ] bats テストで以下 2 ケースが pass:
  - 陽性: Try 文言に「気をつける」のみを含む入力 → 必ず差し戻しが発生
  - 陰性: 構造改善寄り Try（具体的な skill / プロンプト変更を含む） → 差し戻し発生しない
- [ ] `selfreview-capped` GitHub ラベルが事前定義されていることを確認するスクリプト or 手順が整備される（ラベル未定義時の起票失敗を防止）
- [ ] AskUserQuestion 必須記述が `skills/aidlc/SKILL.md` の「ユーザー選択（振り返り内容の決定）」種別に整合する

**技術的考慮事項**:

- セルフレビュー差し戻し履歴は retrospective 実行ログ（`history/operations.md` 等）に記録
- §1.2.5 の AskUserQuestion は dialog token TTL（300 秒）に干渉しないよう、§1.5 Step 4 直前の `retrospective_dialog_token_verify` 呼び出し前に完了させる

---

### ストーリー 3: 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)

**優先順位**: Should-have

As a 振り返り skill 実行者
I want to construction docs / history / セッションログ jsonl の 3 source 横断で事実テーブルを構造化抽出できる helper を使えること
So that 推測ベース KPT（「約 N round」等）の混入を構造的に予防し、振り返りの深さを担保できる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/lib/retrospective-fact-extract.sh`（または `retrospective-api.sh` 内関数）が新規追加され、以下 3 source の事実抽出をサポートする → SC-07:
  - (a) `cycles/{cycle}/inception/decisions.md` から DR 件数・タイトル・主因（3 分類）
  - (b) `cycles/{cycle}/construction/units/*-review-summary.md` から review round 数・指摘件数・defer 件数
  - (c) `cycles/{cycle}/history/*.md` から時系列イベント（タイムスタンプ + 概要）
- [ ] helper の出力は markdown 表形式の事実テーブル（手動 §1.1.5 と同形式）
- [ ] セッションログ jsonl の処理は **file path 引数渡しの opt-in のみ**（自動検出・パーミッション自動付与・ホームディレクトリ走査はすべて本サイクル対象外）
- [ ] 既存 §1.1.5 事実テーブル先抽出ステップの手動 Read 経路は破壊されず、後方互換 fixture テストで動作維持
- [ ] helper を経由した場合と手動 Read した場合で、同一 cycle データ入力に対し生成される事実テーブルが diff 0 で一致（bats）
- [ ] helper の単体 bats テスト（3 source ごとに正常系 + 空ファイル系 + ファイル不在系を網羅）が pass
- [ ] jsonl 引数が指定された場合、引数で示されたファイルから時系列イベントを追加抽出し、3 source 出力に統合する（bats: jsonl 引数あり / なし両ケース）

**技術的考慮事項**:

- スキル間依存ルール: helper は `skills/aidlc/scripts/lib/` 配下に置き、`retrospective-api.sh` 公開 API 経由で `aidlc-retrospective` から呼び出す（内部実装直接 source 禁止）
- jsonl 自動検出・パーミッション付与の自動化は #652 完全 Close 範囲だが、本サイクルでは「引数渡しの opt-in 経路までで Close」として #652 にコメント記録

---

### ストーリー 4A: §1.5 Issue 起票フロー Try ループ化 + T Issue 本文 5 セクション必須化

**優先順位**: Must-have

As a 振り返り skill 実行者
I want to §1.5 Issue 起票フローが「集約 Issue 1 件」から「T 件数分のループ起票」に切り替わり、各 T Issue 本文に背景・主因切り分け・構造課題昇格根拠・想定対策・関連の 5 セクションが必須で含まれること
So that T Issue 単独で意思決定が再現でき、親 retrospective Issue がなくても実行追跡が完結する

**受け入れ基準**:

- [ ] `steps/retrospective.md` §1.5 Step 4 起票が Try 件数分のループに変更される → SC-02
- [ ] 各 T Issue は以下のタイトル形式: `[Retrospective: {cycle}] {Try 内容を 1 行で}`
- [ ] 既定動作（`aggregate_issue_enabled = false`）で 1 サイクル振り返り実行時に集約 Issue 起票件数 = 0、T Issue 起票件数 = サイクル内 Try 件数（bats: 起票件数を観測値として比較）→ SC-02
- [ ] 起票された各 T Issue 本文に **「背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連」** の 5 見出しが存在し、それぞれ配下に 1 行以上の本文がある（bats: 生成本文の各見出し配下非空チェック）→ SC-03
- [ ] cap 判定（`feedback_max_per_cycle`）の意味がストーリー 1 で定義された通り `aggregate_issue_enabled = false` 時は「T Issue 起票合計上限」として動作する（bats: cap 直前 / 超過の境界テスト）
- [ ] 本ストーリーはストーリー 1 で定義された `aggregate_issue_enabled` 仕様と cap 仕様を**利用する側**であり、仕様変更はしない

**技術的考慮事項**:

- Try ループ起票は `retrospective_api_create_issue` を T 件数分繰り返し呼び出す形態（API シグネチャ不変）
- 各 T Issue 起票直前に dialog token 検証（`retrospective_dialog_token_verify`）を行い、TTL 300 秒内で完了する
- 5 セクション必須化は `templates/retrospective_template.md` の Try セクション再構成と連動

---

### ストーリー 4B: `predecessor_resolve_issue` 5 経路回帰 + 新動作経路追加

**優先順位**: Must-have

As a 次サイクル Inception §4a で前サイクル振り返りを参照する利用者
I want to 集約 Issue が無くなった新動作環境でも、retrospective ラベル付き T Issue 群を milestone 単位で集計して前サイクル振り返りを解決できること、かつ既存 5 経路の解決が壊れないこと
So that v2.6.5 以前のサイクルと v2.6.6 以降のサイクルが混在しても前サイクル参照が破綻しない

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/lib/predecessor-issue.sh` に「集約 Issue が存在しない場合に retrospective ラベル付き T Issue 群を集計する経路」が追加される → SC-09
- [ ] `predecessor_resolve_issue` 既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）それぞれの bats 回帰テストが pass し、`resolution_path` 出力が期待値と一致する → SC-08
- [ ] 新動作経路の内部サブ分岐 `t_issue_milestone_scope`（milestone + retrospective ラベル両一致）/ `t_issue_label_fallback`（milestone 不一致 + retrospective ラベル一致）いずれでも T Issue を 1 件以上検出して正常な NDJSON を返す（bats: `candidates` 配列件数 ≥ 1）。**サブ分岐名は既存 5 経路名（`milestone_and_label` / `label_fallback`）と衝突しない名前空間で実装する**。実装上の正式名称は Construction Phase で確定し、本ストーリーの AC は確定名で参照する → SC-09
- [ ] 旧サイクル（v2.6.5 以前 / 集約 Issue 存在）では**新動作経路に入らず**既存 `milestone_and_label` 経路で解決されること（bats: 旧サイクル fixture で `resolution_path = milestone_and_label` 維持確認、`candidates` に新動作経路由来の T Issue 群が混入しないこと）
- [ ] 回帰テストは v2.6.4 Unit 004 の手動再現手順を bats 化したもの（fixture 含む）として `tests/predecessor_*.bats` 系に追加される

**技術的考慮事項**:

- 既存 5 経路の挙動変更は禁止（経路追加のみ）
- 新経路の発火条件: 集約 Issue 検出 0 件 + retrospective ラベル付き T Issue 1 件以上

---

### ストーリー 4C: dogfooding 検証 + CI / 後方互換 + PR 運用証跡

**優先順位**: Must-have

As a 本サイクルのレビュアー / リリース判定者
I want to v2.6.6 自身の振り返りを新フローで実施し、CI green と後方互換 fixture pass を確認した上で、関連 Issue の Close / Comment 運用が正しく PR に反映されること
So that リリース時点で「新フローが動くこと」「旧設定で v2.6.5 と同等の挙動が得られること」「Issue 追跡が破綻しないこと」の 3 点が一括検証される

**開始条件（INVEST Independent 明記）**:

- 本ストーリーは「実装独立ではなく検証フェーズ依存」の位置付け
- 着手前に以下 SC が満たされていること: SC-02 (T ループ起票) / SC-03 (5 セクション必須) / SC-08 (predecessor 5 経路回帰) / SC-09 (predecessor 新動作経路)
- 上記未達時は 4C 着手を保留し、4A/4B の完了を待つ

**受け入れ基準**:

- [ ] **dogfooding 検証**: 本サイクル v2.6.6 自身の振り返りを新フローで実施し、以下 3 条件すべて満たす → SC-10:
  - (a) 起票された全 T Issue で「主因切り分け」「構造課題昇格根拠」セクションが非空
  - (b) §1.2.5 セルフレビュー 3 観点の AskUserQuestion 応答が retrospective 実行ログ（`history/operations.md` 等）に残る
  - (c) §1.2.5 差し戻し機構の動作検証は bats 陽性ケース pass で担保（実運用での差し戻し発生件数は 0 件以上を許容、誘発的な差し戻しは不要）
- [ ] 全 CI green、後方互換テスト pass（`aggregate_issue_enabled=true` で v2.6.5 fixture と同等出力） → SC-11
- [ ] PR 本文で以下 Issue 運用が記録されている → SC-12:
  - `Closes #704`（Retrospective skill セルフレビュー観点不在）
  - `Closes #652`（三層検証 helper skill 化 / 引数 opt-in までで Close）
  - `Comment #710`（patch サブセット適用で minor 想定本体を先取り）
  - `Comment #715`（minor 想定 Issue の patch サブセット適用パターン実例）
- [ ] CHANGELOG / リリースノートに以下 3 点が必須記載 → SC-11 / SC-12:
  - 「集約 Issue が既定で生成されなくなる」
  - 「旧動作を維持するには `aggregate_issue_enabled = true` を明示設定」
  - 「retrospective ラベル付き T Issue 群が集約 Issue の代替として `predecessor_resolve_issue` で解決される」

**技術的考慮事項**:

- dogfooding 実施タイミング: Construction Phase 全 Unit 完了後、Operations Phase §1 retrospective ステップで実施
- 後方互換テストは Unit 4 内 fixture (`tests/fixtures/retrospective_v265_aggregate.json`) を使う
- PR Closes 記載は Operations Phase §7 のリリース準備ステップで確認
