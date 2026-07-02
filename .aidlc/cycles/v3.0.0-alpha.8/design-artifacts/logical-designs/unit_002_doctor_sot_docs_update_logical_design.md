# 論理設計: Unit 002 doctor 完全診断の SoT ドキュメント反映

## 概要

3 SoT ドキュメントの doctor 記述を 11 領域・実装済みへ更新するファイル別編集仕様。コードは変更しない。

**重要**: この論理設計では**コードは書かず**、編集対象と編集内容の定義のみを行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/doctor.sh` | 実出力（11 領域 / 順序 pr→phase→trace→scripts→parse-guard / severity 文言 / 固定幅）を正本化し出力例へ写す |
| `skills/aidlc-v3/steps/doctor.md` | 反映対象①の現状文言（行 4 / 26 / 35-45 / 88-100 / 102-110）を確認し置換文字列を確定 |
| `docs/v3/workflow.md` | 反映対象②の現状文言（行 31 / 160-161 / 176-177 / 181,195-200）を確認 |
| `docs/v3-renewal-plan.md` | 反映対象③の現状文言（行 905 / 917-918 / 923,940-945 / 1092）を確認 |
| `docs/v3/data-model.md` §5 | 導出規則の正本。参照のみとし再定義しない（SoT 二重定義回避） |

### (b) 設計時に意識すべき挙動

- 実出力順で `[phase]`/`[trace]` は `[pr]` と `[scripts]` の間。出力例はこの順に統一。
- 実出力文言を採用（例: `[phase] OK define（state.json 不在 → define フォールバック）` / `[trace] SKIP （state なし）`）。旧 defer 想定文言は破棄。
- markdown_lint=true。テーブル列数・コードスパン内パイプ・行長に注意（Unit 001 で MD056/MD038 を踏んだ教訓）。
- 各出力例はそのブロックのシナリオ（未認証 / define_completed=true 等）と整合させる。

### (c) 既存実装に基づく代替案検討

| 論点 | 候補 | 採否 |
|------|------|------|
| 出力例順序 | 実出力順 / 末尾維持 | 実出力順（実装が正本） |
| 段階メタ列・コメント | 全撤去 / defer 表記のみ実装済みへ | defer 表記のみ（最小差分） |
| 導出規則 | 各docに再掲 / §5 参照 | §5 参照維持 |

## アーキテクチャパターン

**文字列置換 + 用語統一**。各ファイルの特定箇所を、実装の実態（doctor.sh 出力 / 11 領域）に一致する記述へ置換する。導出規則は data-model §5 を参照する構造を維持し、二重定義を作らない。

## コンポーネント構成（ファイル別編集仕様）

### 1. `skills/aidlc-v3/steps/doctor.md`

| # | 箇所 | 編集 |
|---|------|------|
| 1-1 | 冒頭位置づけ（行 4） | `9 領域` → `11 領域` |
| 1-2 | 診断領域見出し（行 26, 28） | `（9 領域 / alpha.7 = shallow scope）`→`（11 領域）`、`以下 9 領域`→`以下 11 領域` |
| 1-3 | 領域テーブル（行 35-45） | `[pr]` 行の直後に `[phase]` / `[trace]` の 2 行を追加。内容は既存テーブル同様の severity 写像の要約に留め、導出規則本体は再掲しない（レビュー#2 / SoT 二重定義回避）。[phase]: 導出フェーズを表示（規則は `data-model.md §5` 参照）/ 矛盾・確認不能（complete の PR merged 未確認等）は WARN。[trace]: `data-model.md §8` に基づく design 要否と design ファイル存在の整合を表示 / 欠落・risky×minimal・depth_level enum 外は WARN |
| 1-4 | 出力例（行 88-100） | `[pr]` 行の直後に実出力整形で 2 行追加（当該例は未認証 = state なしシナリオのため `[phase]       OK    define（state.json 不在 → define フォールバック）` / `[trace]       SKIP  （state なし）`） |
| 1-5 | 末尾 alpha.8 defer（行 102-110） | セクションを実装済み記述へ全面置換。`[phase]`/`[trace]` が alpha.8 で実装済みである旨 + `[trace]` と `[work-items]` の役割分担（`[work-items]`=frontmatter schema 検証 / `[trace]`=design 必須 work item の design ファイル存在整合）を明示。導出規則は data-model §5 参照 |

### 2. `docs/v3/workflow.md`

| # | 箇所 | 編集 |
|---|------|------|
| 2-1 | §3.1（行 31） | 診断対象を 11 領域全体（`config / state / cycle / work-items / git / gh / pr / phase / trace / scripts / parse-guard`）へ更新し `alpha.7 shallow scope...alpha.8 defer` 注記を撤去（parse-guard 欠落も解消 / レビュー#1） |
| 2-2 | §3.6 段階スコープ（行 160-161） | `alpha.7 では shallow scope（8 領域 + [parse-guard]）...alpha.8 の必須 follow-up へ defer` 段落を「11 領域を実装」へ書き換え |
| 2-3 | §3.6 チェック項目テーブル（行 176-177） | phase/trace 段階列 `**alpha.8 defer**` → `実装済み` |
| 2-4 | §3.6 出力例（行 181, 195-200） | 2 ブロック（shallow / defer）を 1 ブロックへ統合。`alpha.7（shallow scope）の出力例:` / `alpha.8 で追加予定（defer）:` 前置き削除、`# alpha.8` 除去。当該例は define_completed=true シナリオのため、実出力形式（develop 正常時は detail 括弧なし）で `[phase]       OK    develop` を `[pr]` の後に、`[trace]       OK    design 要否充足（N item(s)）`（design 充足時）を追加（レビュー#1: 括弧付き derived 文言は使わない） |

### 3. `docs/v3-renewal-plan.md`

| # | 箇所 | 編集 |
|---|------|------|
| 3-1 | §doctor 段階スコープ（行 905） | `alpha.7 = shallow scope（8 領域 + [parse-guard]）。...alpha.8 必須 follow-up へ defer` を「11 領域実装済み」へ |
| 3-2 | §doctor チェック項目（行 917-918） | phase/trace の行末コメント `# alpha.8 defer` → `# alpha.8 実装済み`（defer 解除と実装済み状態を明示 / workflow.md §3.6 の「実装済み」表記と統一 / レビュー#3） |
| 3-3 | §doctor 出力例（行 923, 940-945） | 2 ブロックを統合。`（alpha.7 / shallow scope）` 撤去、`alpha.8 で追加予定（defer）:` 削除、`# alpha.8` コメント除去、実出力形式（develop 正常時は detail 括弧なし）で `[phase]       OK    develop` / `[trace]       OK    design 要否充足（N item(s)）` を `[pr]` の後に組み込み |
| 3-4 | Phase 6 完了条件（行 1092） | `doctor が alpha.7 の shallow scope（8 領域 + [parse-guard]）を診断できる（... alpha.8 defer）` → `doctor が 11 領域（config〜parse-guard に [phase] / [trace] を含む）を診断できる` |

## インターフェース設計

該当なし（ドキュメント編集のみ / CLI・API 変更なし）。

## データモデル概要

編集対象はすべて Markdown。doctor 出力例の各行は `[area]` + 固定幅 + severity + detail の形式（doctor.sh の report 契約に準拠）。

## 処理フロー概要

1. 各ファイルの現状文言を Read で確認（Explore 調査で取得済み）
2. 上記編集仕様に従い文字列置換（Edit）
3. markdownlint 実行 → エラー修正
4. doctor.sh を実行し出力例と実出力の整合を目視確認

## 非機能要件（NFR）への対応

- **パフォーマンス / セキュリティ / スケーラビリティ / 可用性**: 該当なし（ドキュメント）。ローカル絶対パス・機密情報を含めない（公開ドキュメント）。

## 技術選定

- Markdown（markdownlint-cli2 準拠）。

## 実装上の注意事項

- SoT 二重定義回避: 導出規則本体は data-model §5。workflow.md / v3-renewal-plan.md / doctor.md は結果参照のみ。
- 出力例の severity トークン位置・順序を doctor.sh 実出力に一致させる。
- テーブルセル内でパイプ（`|`）を含むコードスパンを書かない（MD056 回避 / Unit 001 の教訓）。
- 領域数表記の揺れ（8 領域 + parse-guard / 9 領域 / shallow scope）を残さず「11 領域」に統一。

## ガイド照合（`.aidlc/rules.md`「設計レビュー時のガイド照合ルール」）

- 対象は公開ドキュメント編集。exit-code / error-handling ガイドは非該当。SoT 二重定義回避原則（data-model §5 正本）を遵守。

## 不明点と質問（設計中に記録）

[Question] workflow.md / v3-renewal-plan.md の出力例は define_completed=true シナリオ。phase/trace の具体 severity をどう書くか。
[Answer]（設計判断）当該シナリオ（define_completed=true + 複数 work item）では phase=develop（未完了 item あり）。develop 正常時は実装が detail 括弧を出さないため出力例も `[phase]       OK    develop`（括弧なし / レビュー#1）。trace は design 充足なら `[trace]       OK    design 要否充足（N item(s)）`。旧 defer 想定の括弧付き derived 文言・WARN 固定例は使わず、実出力の severity トークン位置・整形に一致させる。
