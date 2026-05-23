# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.6.6（patch）— aidlc-retrospective skill の T 中心リファクタ + 本質的振り返り化

## 開発の目的

aidlc-retrospective skill の振り返りプロセスを「**KPT は手段、T の Issue 化（K 継続 / P 改善のアクション）が目的**」という構造に焼き直す。同時に、表面的な振り返り（個別チェック追加で逃げる）を構造的に防ぐセルフレビュー機構を skill 内に組み込む。

### 解消したい根本症状

1. **目的化のすり替え** — 現状の skill は「振り返りごとに `Retrospective: {cycle}` 集約 Issue 1 件を作って KPT を全部詰める」設計で、Issue 起票自体が達成基準になっている。本来の目的（K を継続するため / P を改善するための **T を Issue にして実行に繋げる**）が後景に追いやられ、親 Issue（例: #651 v2.5.2 low priority）が積み残されたまま個別 T 起票も散発化。
2. **表面的な振り返り** — Try が「次回から気をつける」「再発防止チェックを 1 項目追加」で済まされ、Problem を構造課題（プロセス / 設計 / 規約 / SoT）に昇格できない。#704 が「Try が個別チェック追加に偏っていないか / Problem を構造課題に昇格できているか」のセルフレビュー観点不在を既に指摘している。

### 期待する成果

- 振り返り skill の出力アーティファクトを **「実行コミットメントとしての T Issue 群」** に統一する（集約 Issue は既定で生成しない）。
- 各 T Issue 本文に **背景（該当 K/P + 主因切り分け + 構造課題への昇格根拠）** を必須セクションとして含め、Issue 単独で意思決定が再現できるようにする。
- Try 起票直前に **「これは個別チェック追加で逃げていないか / Problem を構造課題に昇格させたか」** のセルフレビュー必須ステップを差し込む。
- 振り返りの深さを担保する **一次情報三層検証 helper**（construction docs / history / セッションログ jsonl）を opt-in で skill に組み込み、推測ベース KPT を構造的に予防する。

## ターゲットユーザー

ai-dlc-starter-kit を採用する全プロジェクトの開発者・運用者。とくに本リポジトリ自身（メタ開発）が一次受益者となる。

## ビジネス価値

- 振り返り由来の改善 Issue が「起票しただけ」で滞留せず、実装サイクルに乗る確率が上がる。
- 同型の問題（v2.5.1 メタ振り返りで顕在化した「振り返りプロセス自体の漏れ」が v2.6.5 でも再発している構造）を skill 構造で予防できる。
- 集約 Issue の散在による「振り返りごとに retrospective ラベル Issue が増える」ノイズが解消される。

## patch リリースの妥当性（minor 想定 Issue を patch サブセット適用）

本サイクルが扱う #710（CLOSED / minor 想定）の本体（集約 Issue 廃止 + T 件数分ループ起票）は通常 minor リリース項目だが、以下の構造で patch リリース妥当性を担保する:

- **後方互換オプションで旧動作を復元可能**: `rules.retrospective.aggregate_issue_enabled` フラグ（既定 `false`）を新設。`true` を設定したユーザーは従来通り `Retrospective: {cycle}` 集約 Issue 起票が行われる。consumer プロジェクトは v2.6.5 → v2.6.6 アップグレード時にフラグ未設定なら新動作、明示的に `true` セットすれば旧動作を維持できる。
- **`predecessor_resolve_issue` の経路を破壊しない**: 集約 Issue がない前提でも、retrospective ラベル付き T Issue 群を milestone 単位で集計する解決経路（経路 1/1' に T Issue ヒットを含める）を維持。`Retrospective:` タイトル運用は廃止せず、旧サイクル向けの後方互換解決経路として残す。
- **API 破壊変更なし**: `retrospective_api_*` の公開シグネチャは不変。`retrospective_api_create_issue` の呼び出し回数が「集約 1 回」から「T 件数分のループ」に変わるが、関数自体の入出力は不変。
- **#715 SoT 化テーマの実例**: 本サイクル自体が「minor 想定 Issue の patch サブセット適用」パターンの実証実例となり、`decisions.md` の DR として手順を残す。

### patch として許容する条件（明文化）

本サイクルが既定動作変更（集約 Issue 廃止）を含みつつ patch リリースを採る前提条件として、以下すべてを必須要件とする。1 つでも欠ければ minor (v2.7.0) に格上げする:

1. **非破壊保証対象**: 旧設定（`aggregate_issue_enabled = true` を `config.toml` または `config.local.toml` で明示設定）した場合に、リリース前の v2.6.5 と完全に同等の出力（集約 Issue 起票本文 / Issue タイトル / ラベル / cap 判定動作）が得られる。未設定（既定 `false`）の場合は新動作（T ループ起票）となり、これはアップグレード時のリリースノート（必須要件 2）でユーザーに告知される
2. **アップグレード移行手順**: CHANGELOG / リリースノートに「集約 Issue が既定で生成されなくなる」「旧動作を維持するには `aggregate_issue_enabled = true` を明示設定」「retrospective ラベル付き T Issue 群が集約 Issue の代替として `predecessor_resolve_issue` で解決される」の 3 点を必須記載
3. **互換性テスト観点**: `tests/retrospective_*.bats` に (a) 既定動作 (新: T ループ起票) (b) opt-in 復元動作 (旧: 集約 Issue 起票) の両系統テストを追加し、いずれも CI で pass する
4. **defer 項目の維持**: 本サイクルでは v2.7.0+ defer 項目（`Retrospective: {cycle}` タイトル運用完全廃止 / `retrospective_api_*` 破壊変更 / `predecessor_resolve_issue` 経路再設計 等）に手を出さない
5. **dogfooding 自家検証**: 本サイクル自身の振り返り（v2.6.6 retrospective）を新フローで実施し、後述「成功基準」の dogfooding 条件をすべて満たす

## 含まれるもの

### 1. T 中心アウトプットへの再定義（運用契約レベル）

- `skills/aidlc-retrospective/SKILL.md` と `steps/retrospective.md` 冒頭に **「目的: T を Issue 化して実行に繋げること。KPT は T を導くための手段」** を SoT として明記。
- **集約 retrospective Issue の自動起票を既定 off** に変更（`rules.retrospective.aggregate_issue_enabled = false` 既定）。後方互換 opt-in で `true` 設定時のみ旧動作。
- 起票単位を **1 Try = 1 Issue** に変更。各 T Issue は以下の **必須セクション** を含む:
  - **タイトル**: `[Retrospective: {cycle}] {Try 内容を 1 行で}`（既存 retrospective T Issue 命名と整合）
  - **背景**: 該当する Keep または Problem の要旨
  - **主因切り分け**: §1.2 の 3 分類のいずれか + 根拠
  - **構造課題への昇格根拠**: §1.2.5 セルフレビューで「個別チェック追加で逃げていない」と判定した根拠
  - **想定対策**: Try の具体内容
  - **関連**: サイクル番号 / 親情報（v2.6.6 以降は milestone のみ。集約 Issue がある場合は `Relates: #<集約>`）
- ファイル出力（`operations/retrospective.md` 等）は採用しない。
- `auto_issue_creation = false` の opt-in 基盤（v2.6.4 / Unit 004）は既存挙動を維持。

### 2. セルフレビュー観点の skill 内蔵（#704 Try B 相当）

`steps/retrospective.md` §1.2 主因切り分け後・§1.5 Issue 起票前に **新ステップ §1.2.5「Try 構造性セルフレビュー」** を追加。AskUserQuestion で以下を必須確認（差し戻しループ上限 3 回 / 上限到達時は警告ラベル `selfreview-capped` 付与で起票許可）:

- Try が「次回から気をつける / チェックを 1 項目追加する」で済んでいないか
- Problem を **個別事象から構造課題（プロセス / 設計 / 規約 / SoT）** に昇格できているか
- P → T が **再発防止チェックの追加** で逃げていないか（= 構造の修正に踏み込んでいるか）

各観点で「該当する（= 表面的）」と回答した場合は Try 起草に差し戻し。

### 3. 「個別チェック追加 vs 構造改善」判別ガイドの導入（#704 Try A 一部）

§1.2.5 セルフレビューを補強するための **3 問固定の判別質問テンプレ** を `skills/aidlc-retrospective/templates/try_classification_guide.md` として追加。質問は以下の 3 問（順序固定）:

1. **再発性**: この Problem は同種事象が **直近 3 サイクル**（評価窓: 本サイクルを含まない直前 3 サイクル分の `cycles/v*/operations/` および retrospective Issue）で再発しているか？
2. **対象レイヤ**: Try の対象は「ユーザー / AI の心がけ」か、それとも「skill / プロンプト / SoT / CI ガード」か？
3. **再入余地**: Try 実施後、同じ Problem を別の入り口から踏める余地が残るか？

§1.2.5 セルフレビュー時に本テンプレを参照する。質問数の増減（4 問以降の追加 / 1 問への絞り込み）は本サイクル対象外。

### 4. 一次情報三層検証 helper の skill 化（#652 / opt-in / 既定動作不変）

`skills/aidlc/scripts/lib/retrospective-fact-extract.sh` を新規追加（または既存 `retrospective-api.sh` に関数登録）。3 source 横断の事実テーブル生成 helper:

- (a) `cycles/{cycle}/inception/decisions.md` から DR 件数・タイトル・主因
- (b) `cycles/{cycle}/construction/units/*-review-summary.md` から review round 数・指摘件数・defer 件数
- (c) `cycles/{cycle}/history/*.md` から時系列イベント

§1.1.5 事実テーブル先抽出ステップを **helper 呼び出し経由** に統一（既存手動 Read 手順は後方互換として残す）。

**patch スコープ制限**: opt-in helper として追加し、既存 §1.1.5 の手動 Read 手順を破壊しない。セッションログ jsonl（#652 (c)）は file path 引数渡しでの opt-in のみ（パーミッション・存在検出の自動化は v2.7.0+ 防衛）。

### 5. §1.5 Issue 起票フロー再設計（Try 件数分ループ + cap 判定再定義）

- §1.5 Step 4 起票を **Try 件数分ループ** に変更。各 T Issue を個別起票。
- `cap` 判定（`rules.retrospective.feedback_max_per_cycle`）の意味を「集約 Issue 1 件」から「**サイクル内 T Issue 起票合計の上限**」に再定義。
- `aggregate_issue_enabled = true`（後方互換 opt-in）の場合のみ、旧 §1.5 集約 Issue 起票フローを実行（cap 判定も旧定義に従う）。

### 6. 関連 Issue クローズ予定

- #710 (CLOSED, 振り返り Issue 起票方針見直し / minor 想定) — 本サイクルが minor 想定の本体を patch サブセット適用で先取りすることを `Comment` で記録（CLOSED のままで再 OPEN しない）
- #704 (OPEN, Retrospective skill セルフレビュー観点不在) — §1.2.5 + 判別ガイド導入で `Closes`
- #652 (OPEN, 振り返り 3層検証 helper skill 化) — opt-in helper 追加部分で `Closes`（破壊的部分は除外明記）
- #715 (OPEN, minor 想定 Issue の patch サブセット適用パターン SoT 化) — 本サイクルが実例提供。`decisions.md` に手順記録し、SoT 化本体は別サイクル defer の旨を comment

## 明示的に除外するもの（v2.7.0+ defer / 本サイクル外）

- `Retrospective: {cycle}` タイトル運用の完全廃止（後方互換解決経路として残す）
- `retrospective_api_*` の破壊的シグネチャ変更
- `predecessor_resolve_issue` の経路再設計（既存 5 経路 + retrospective ラベル T Issue 群集計を維持）
- 過去サイクル振り返り Issue（#651 / #722-#724 等）の遡及書き換え
- `auto_issue_creation` デフォルト値の `false` 化（v2.6.4 で導入された opt-in 基盤の挙動を維持）
- aidlc-retrospective SKILL.md の単方向境界変更（`/aidlc` 呼出禁止 / operations/** 読込禁止）
- セッションログ jsonl の自動検出・パーミッション自動付与（file path 引数渡しの opt-in のみ）

## 既存機能との関連

- **`skills/aidlc-retrospective/`**: 改修対象（SKILL.md / steps/retrospective.md / templates / scripts/lib）
- **`skills/aidlc/scripts/lib/retrospective-api.sh`**: 公開 API 層。関数追加（fact-extract helper、aggregate_issue_enabled 判定 helper）、既存関数シグネチャ不変
- **`skills/aidlc/scripts/lib/predecessor-issue.sh`**: 集約 Issue がない場合の T Issue 群集計経路を追加（既存 5 経路の補強、破壊変更なし）
- **`skills/aidlc/templates/retrospective_template.md`**: T Issue 単独運用に合わせて Try セクションを再構成
- **v2.6.4 opt-in 基盤** (`rules.retrospective.auto_issue_creation`): 既存挙動を維持。本サイクルの新規フラグ `aggregate_issue_enabled` は別軸の opt-in
- **テスト**: `tests/retrospective_*.bats` 系を更新（T 件数ループ起票 / aggregate_issue_enabled opt-in / セルフレビュー差し戻し）

## 成功基準

すべて binary（達成 / 未達成）で判定可能な基準のみ列挙する。各項目に SC-ID を付与し、user_stories.md / units/*.md からトレース可能とする。

- [ ] **SC-01**: `skills/aidlc-retrospective/SKILL.md` および `steps/retrospective.md` 冒頭に「目的: T を Issue 化して実行に繋げること。KPT は T を導くための手段」が SoT として明記される（grep 検出は補助、必須条件は文字列存在）
- [ ] **SC-02**: 既定動作（`aggregate_issue_enabled = false`）で 1 サイクル振り返り実行時に集約 retrospective Issue 起票件数 = 0、かつ T Issue 起票件数 = サイクル内 Try 件数（bats: 起票件数を観測値として比較）
- [ ] **SC-03**: 既定動作で起票された各 T Issue 本文に「背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連」の 5 セクションが**非空**で含まれる（bats: 生成本文の各見出し配下に 1 行以上の本文がある）
- [ ] **SC-04**: `rules.retrospective.aggregate_issue_enabled = true` opt-in で旧 v2.6.5 と完全に同等の集約 Issue 起票結果が得られる。**同等性オラクル**: 固定 fixture (`tests/fixtures/retrospective_v265_aggregate.json` を新規追加) との比較で、以下 5 項目すべて差分 0:
  - 集約 Issue タイトル（完全一致）
  - 本文見出し集合（順序・重複含めた一致）
  - **各見出し配下の本文の正規化比較**（タイムスタンプ / セッション ID / 環境固有パス等のゆらぎ項目を `normalize_volatile()` で除外した上で完全一致 / または本文全体の正規化ハッシュ一致）
  - ラベル集合（順不同の集合一致）
  - cap 判定結果（`current_count` / `over` フラグ）
- [ ] **SC-05**: `steps/retrospective.md` に §1.2.5「Try 構造性セルフレビュー」ステップが追加され、AskUserQuestion 経由で 3 観点を必須確認する。差し戻し上限 3 回、上限到達時は T Issue に `selfreview-capped` 警告ラベルが付与されて起票される（bats: 表面的 Try 入力時のラベル付与確認）
- [ ] **SC-06**: `skills/aidlc-retrospective/templates/try_classification_guide.md` が追加され、3 問固定の判別質問テンプレ（再発性 / 対象レイヤ / 再入余地）を含む。§1.2.5 から本テンプレへの参照リンクが存在する
- [ ] **SC-07**: 一次情報三層検証 helper（`retrospective-fact-extract.sh` または同等 API 関数）が opt-in で追加され、(a) decisions.md (b) construction review-summary (c) history の 3 source + (d) セッションログ jsonl の file path 引数渡しを処理可能。既存 §1.1.5 手動 Read 経路は破壊されず後方互換 fixture テストで動作維持
- [ ] **SC-08**: `predecessor_resolve_issue` 既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）それぞれの bats 回帰テストで `resolution_path` 出力が期待値と一致
- [ ] **SC-09**: `predecessor_resolve_issue` の新動作（集約 Issue 不在時の retrospective ラベル付き T Issue 群集計経路）の内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback`（実装上の正式名称は Construction Phase で確定 / 既存 5 経路名と衝突しない名前空間）いずれでも T Issue を 1 件以上検出して正常な NDJSON を返す（bats: T Issue 集計テスト / `candidates` 配列件数 ≥ 1）
- [ ] **SC-10**: **dogfooding 検証**: 本サイクル v2.6.6 自身の振り返りを新フローで実施し、以下 3 条件すべて満たす:
  - (a) 起票された全 T Issue で「主因切り分け」「構造課題昇格根拠」セクションが非空
  - (b) §1.2.5 セルフレビュー 3 観点の AskUserQuestion 応答が retrospective 実行ログ（`history/operations.md` 等）に記録される
  - (c) §1.2.5 差し戻し機構の動作検証は **bats 陽性ケース pass で担保**（dogfooding 実運用での差し戻し発生件数は 0 件以上を許容、誘発的な差し戻しは不要）
- [ ] **SC-11**: 全 CI green、後方互換テスト pass（`aggregate_issue_enabled=true` で v2.6.5 fixture と同等出力）
- [ ] **SC-12**: 本サイクル PR で #704 / #652 を `Closes` 記載、#710 / #715 を `Comment` 記録

## 期限とマイルストーン

patch 1 サイクル（典型 1〜2 営業日）。**Unit 数: 4 固定**（本 Intent 時点で確定。変更時は Construction Phase 開始前に DR 起票必須）。Unit 分割の本 Intent 確定案:

- Unit 1: T 中心アウトプット再定義 + `aggregate_issue_enabled` opt-in 切替（SKILL.md / steps 冒頭 SoT 化 + フラグ導入）
- Unit 2: §1.2.5 セルフレビュー観点新ステップ + `try_classification_guide.md`（3 問固定）追加
- Unit 3: 一次情報三層検証 helper の opt-in skill 化（`retrospective-fact-extract.sh` / 既存 §1.1.5 手動経路を破壊しない）
- Unit 4: §1.5 起票フロー Try ループ化 + cap 再定義 + `predecessor_resolve_issue` 5 経路回帰テスト + dogfooding 検証

**超過時の defer 条件**: Unit 4 を超える追加要求が発生した場合、「破壊的変更を伴わないもののみ取り込み可、それ以外は v2.7.0+ defer」を適用する。

## 制約事項

- patch リリースだが、既定動作変更（集約 Issue 廃止）を含む。**後方互換オプション (`aggregate_issue_enabled`) で旧動作復元可能性を担保することが必須条件**
- `automation_mode=semi_auto` 運用での dialog token / dialog bypass ガードを壊さない
- Bash ツール経由のコマンド置換禁止（CLAUDE.md「Bash ツール経由の安全パターン」遵守）
- スキル間依存ルール: 内部 lib への直接 source 禁止（`retrospective-api.sh` 公開 API 経由のみ）
- `predecessor_resolve_issue` の既存 5 経路を破壊しない（経路追加のみ許可）

## 関連 Issue

- **本命 Close 対象**: #704 (OPEN, Retrospective skill セルフレビュー観点不在), #652 (OPEN, 三層検証 helper skill 化)
- **方針親 Issue (Comment)**: #710 (CLOSED / 振り返り Issue 起票方針見直し / minor 想定 — 本サイクル v2.6.6 で本体「集約 Issue 廃止 + Try ループ起票」を patch サブセット適用で先取り。CLOSED のままで再 OPEN しない。本サイクル PR で `Comment` 記録)
  - 注: v2.6.4 で導入された `rules.retrospective.auto_issue_creation` opt-in 基盤は **本 Intent の `aggregate_issue_enabled` とは別軸の opt-in**（auto_issue_creation = 起票そのものの ON/OFF / aggregate_issue_enabled = 起票形態の集約 vs T ループ）。v2.6.4 opt-in 基盤の親 Issue は同じ #710 だが、本サイクルでは「v2.6.4 opt-in 基盤の挙動は維持しつつ、本 Intent では `aggregate_issue_enabled` 軸を新設して T ループ起票を既定化する」という関係
- **実例パターン (Comment)**: #715 (OPEN, minor 想定 Issue の patch サブセット適用パターン SoT 化 — 本サイクル自体が実例提供。SoT 化本体は別サイクル defer の旨を Comment)
- **既対応参照**: #634 (CLOSED, v2.5.1 メタ振り返り由来 / 事実テーブル先抽出は v2.5.3 で導入済 / 本サイクルは helper 化のみ追加)
- **別件・本サイクル対象外**: #716 / #718 / #722 / #723 / #724

## 不明点と質問（Inception Phase中に記録）

[Question Q1] ✅ ユーザー回答済: 「T Issue のみ (親廃止) + patch のまま + T Issue に背景をしっかり書く」。本 Intent はこの方針で構築。

[Question Q2] ✅ 確定: §1.2.5 セルフレビューの差し戻しループ上限は **3 回**、上限到達時は T Issue に `selfreview-capped` 警告ラベルを付与して起票を許可する（強制ブロックなし）。差し戻し上限値の設定可能化（config からの調整）は本サイクル対象外であり、必要なら v2.7.0+ defer とする。本 Intent の成功基準・除外項目はこの確定方針に整合済。
