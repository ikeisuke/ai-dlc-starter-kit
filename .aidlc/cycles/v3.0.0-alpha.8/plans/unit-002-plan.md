# Unit 002 実装計画: doctor 完全診断の SoT ドキュメント反映 + 用語整合

## 対象 Unit

- **Unit**: 002-doctor-sot-docs-update
- **関連 Issue**: #741（Epic: #736 / Phase 6 完了条件）
- **depth_level**: standard
- **実装優先度**: High / 見積もり: 小（ドキュメント 3 ファイル + 用語整合）
- **依存**: Unit 001（完了済み。実装の実出力に出力例を揃えるため）

## 目的

doctor が `[phase]` / `[trace]` を含む 11 領域の完全診断になったことを SoT ドキュメント 3 種へ反映する。「alpha.8 defer」注記を「実装済み」へ更新し、領域カウント表記を「11 領域」で統一、出力例を Unit 001 の実出力に揃える。**ドキュメントのみ編集**（コード非編集）。

## 編集対象ファイルと変更内容

### 1. `skills/aidlc-v3/steps/doctor.md`

| 箇所 | 現状 | 変更 |
|------|------|------|
| 冒頭位置づけ（行 4 付近） | `doctor は v3 環境の 9 領域を診断し` | `11 領域` |
| 「診断領域」見出し（行 26 付近） | `## 診断領域（9 領域 / alpha.7 = shallow scope）` / `以下 9 領域を順に診断` | `（11 領域）` / `以下 11 領域`、shallow scope 表記撤去 |
| 診断領域テーブル（行 35-45） | 9 行（phase/trace 欠落） | `[phase]` / `[trace]` 行を実出力順（`[pr]` の後）に追加 |
| 出力例（行 88-100） | 9 行 | `[phase]` / `[trace]` を実出力の固定幅・順序で 2 行追加 |
| 末尾「## alpha.8 defer」（行 102-110） | defer セクション全文 | 実装済み記述へ置換（`[trace]` と `[work-items]` の役割分担を明示） |

### 2. `docs/v3/workflow.md`

| 箇所 | 現状 | 変更 |
|------|------|------|
| §3.1 コマンド体系（行 31） | `config / state / cycle / work-items / git / gh / pr / scripts の問題を診断（alpha.7 shallow scope。[phase]/[trace] は alpha.8 defer / §3.6 参照）`（現状 parse-guard も欠落） | 診断対象を 11 領域全体（`config / state / cycle / work-items / git / gh / pr / phase / trace / scripts / parse-guard`、または「11 領域（§3.6 参照）」）へ更新し defer 注記を撤去（レビュー#1: parse-guard 欠落も同時解消） |
| §3.6 段階スコープ注記（行 160-161） | `alpha.7 では shallow scope（8 領域 + [parse-guard]）...alpha.8 の必須 follow-up へ defer` | 11 領域実装済みへ書き換え |
| §3.6 チェック項目テーブル（行 176-177） | phase/trace 段階列 `**alpha.8 defer**` | `実装済み` へ |
| §3.6 出力例（行 181, 195-200） | 2 ブロック（shallow / defer） | 1 ブロックへ統合、`# alpha.8` 除去、実出力に整合 |

### 3. `docs/v3-renewal-plan.md`

| 箇所 | 現状 | 変更 |
|------|------|------|
| §doctor 段階スコープ（行 905） | `alpha.7 = shallow scope（8 領域 + [parse-guard]）。...alpha.8 必須 follow-up へ defer` | 11 領域実装済みへ |
| §doctor チェック項目（行 917-918） | phase/trace `# alpha.8 defer` | `# 実装済み`（alpha.8）へ |
| §doctor 出力例（行 923, 940-945） | 2 ブロック（shallow / defer） | 統合、`# alpha.8` 除去、実出力に整合 |
| Phase 6 完了条件（行 1092） | `doctor が alpha.7 の shallow scope（8 領域 + [parse-guard]）を診断できる（... alpha.8 defer）` | `doctor が 11 領域（... [phase] / [trace] 含む）を診断できる` |

## 設計判断（Unit 001 実出力に基づく）

- **出力例の順序**: 実装（doctor.sh）が正本。出力例は実出力順 `... [pr] → [phase] → [trace] → [scripts] → [parse-guard]` に揃える。
- **出力例の文言**: defer 時の想定文言（`develop (derived: ...)` / `WARN: work_item 003 ...`）は実出力（`[phase] OK define（...）` / `[trace] SKIP （state なし）` 等）と異なるため、実出力に合わせる。
- **用語統一**: 「8 領域 + parse-guard」「9 領域」「shallow scope」の揺れを「11 領域」に統一。
- **段階メタ（`# alpha.7` コメント / 段階列）**: 全領域実装済みだが、列・コメント構造の全撤去はスコープ拡大のため行わず、phase/trace の defer 表記のみ「実装済み」に更新する（最小差分）。
- **バージョン位置づけヘッダ（alpha.7 / Phase 6）**: 領域カウント・defer 注記に直接紐づかない版数表記は本 Unit のスコープ外として温存する。

## 完了条件チェックリスト

Unit 定義「責務」+ Issue #741 受け入れ基準（SoT の alpha.8 defer 注記を実装済みに更新）より抽出:

- [ ] `doctor.md`: 領域カウント「9 領域」→「11 領域」、shallow scope 表記撤去
- [ ] `doctor.md`: 診断領域テーブルに `[phase]` / `[trace]` 行を追加
- [ ] `doctor.md`: 出力例に `[phase]` / `[trace]` 2 行を実出力の固定幅・順序で追加
- [ ] `doctor.md`: 末尾「## alpha.8 defer」を実装済み記述へ置換し、`[trace]` と `[work-items]` の役割分担を明示
- [ ] `workflow.md`: §3.1 コマンド体系の診断対象を 11 領域全体へ更新（parse-guard 欠落も解消 / レビュー#1）+ §3.6（段階スコープ注記 / チェック項目テーブル / 出力例）の alpha.8 defer を実装済みへ更新
- [ ] `v3-renewal-plan.md`: doctor セクション（段階スコープ / チェック項目 / 出力例）と Phase 6 完了条件の alpha.8 defer を実装済みへ更新
- [ ] 領域カウント表記を全 3 ファイルで「11 領域」に統一（「8 領域 + parse-guard」「9 領域」の揺れ解消）
- [ ] 出力例が Unit 001 の実出力（severity トークン位置・順序）と一致
- [ ] markdownlint 整合（markdown_lint=true）/ SoT 二重定義回避（data-model.md §5 が導出規則の正本 / 他は参照のみ）を維持

## スコープ外（境界）

- `doctor.sh` / `test-doctor.sh` のコード変更（Unit 001 で完了）
- フェーズ導出規則・size×depth 規則そのものの記述変更（段階スコープ注記のみ更新）
- 段階メタ列・`# alpha.7` コメントの全面撤去、バージョン位置づけヘッダの改訂
- `default branch / remote は alpha.8+` 等の doctor 未実装領域の別件注記
