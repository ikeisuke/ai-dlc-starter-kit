# Unit 001 計画: v3 RFC・core/extension 境界・設計判断確定

## 対象 Unit

- Unit 001: v3-rfc-core
- 成果物: `docs/v3/rfc.md`
- 依存: 他 Unit 成果物への依存なし（RFC は設計判断の起点）。ただし**入力参照依存**として、v2 既存資産（skill / step / script / config / command surface）と計画書 `docs/v3-renewal-plan.md`（7 AI-DLC Principles・削減定量表・core/extension 境界一覧を内包）を参照する
- 見積もり: 本サイクル最大の Unit（設計判断 6 件 + 境界基準 + 承認ゲート複数回）

## アプローチ

docs-only の設計文書のため、AI-DLC の Phase 1（設計）/ Phase 2（実装）を以下のようにマッピングする:

- **Phase 1（設計）**: 以下を行い「設計判断の結論一覧 + RFC アウトライン」を design-artifacts に記録する（ドメインモデル/論理設計の代替）:
  - 入力確認: v2 既存資産の棚卸し（計画書が内包する定量分析を一次参照）と **7 AI-DLC Principles の参照元確認**（正本は計画書「v3 AI-DLC Principles」節。RFC で正式に列挙確定する）
  - RFC の 6 設計判断を一から検討（trade-off 分析）し、結論が分かれうる論点をユーザー承認ゲートで確定
  - **core/extension 境界の分類基準**（境界原則 / 分類基準 / 代表コンポーネント分類 / 例外ルール）を RFC の必須セクションとして設計（6 判断とは別の必須成果物。境界一覧だけでなく分類の判断軸を明文化）
  - RFC の構成（章立て / Decision Gate Log セクション含む）を設計
- **Phase 2（実装）**: 確定した設計判断・境界基準・構成に基づき `docs/v3/rfc.md` を執筆。

## 6 設計判断（Phase 1 で検討 / DR-004: 一から検討）

| # | 論点 | 検討する案 |
|---|------|-----------|
| 1 | 表面コマンド名 | A: 新名称を正式名 / B: 旧名称維持 / C: 両対応 |
| 2 | Express モード | A: 維持 / B: 廃止 |
| 3 | v2 サポート期間 | A: 即 EOL / B: 条件付き EOL |
| 4 | review 統合粒度 | A: 1 skill + perspective / B: 3 skills / C: v2 維持 |
| 5 | GitHub 前提の強さ | A: git のみ / B: Issue/PR まで core / C: GitHub 前提強化 |
| 6 | state format | A: JSON / B: TOML / C: Markdown frontmatter / ハイブリッド |

計画書推奨は一入力として提示するが事前確定しない。各論点の結論はユーザー確認の上で Decision Gate Log に記録する。

**6 判断に加え、core/extension 境界の分類基準を必須設計成果物として確定する**（Phase 1 アプローチ参照。これは 6 判断とは独立。判断 #4 review 統合 / #5 GitHub 前提は境界の個別ケースだが、汎用の分類軸はこの境界基準で定義する）。v2 EOL（判断 #3）の結論は、共存方針セクション（v2 を変更しない前提・consumer runtime 非影響）と**相互参照**させ、EOL 方針と互換保証範囲の関係を明示する。

## 完了条件チェックリスト（Unit 001 責務由来）

- [ ] `docs/v3/rfc.md` が作成されている
- [ ] AI-DLC 7 principles が、参照元（`docs/v3-renewal-plan.md` の「v3 AI-DLC Principles」節）とともに記載されている
- [ ] core に残すもの / extension に分けるものの境界が明記され、かつ**分類基準（境界原則 / 分類軸 / 例外ルール）**が明文化されている
- [ ] v2 → v3 削減目標が、**現状ベースライン値・目標値・削減数および削減率・対象外項目の理由**を伴って記載され、計画書の定量表と整合している（スキル / ステップ行数 / スクリプト / 設定キー）
- [ ] 6 設計判断それぞれに複数案の trade-off 分析 + 結論（理由付き）が記載されている
- [ ] 分岐論点・承認結果・採用判断が Decision Gate Log セクションに実際に記録されている
- [ ] v2 共存方針（変更しない前提・コマンド名衝突の扱い・consumer runtime 非影響）が記録され、v2 EOL 判断（#3）の結論と相互参照されている
- [ ] 成果物が docs/v3 配下に限定され実行可能コードを生成していない
- [ ] markdownlint を通過する

## レビュー方針

- Phase 1（設計）: 計画承認前レビュー（reviewing-construction-plan）、設計レビュー（reviewing-construction-design）
- Phase 2（実装）: コードレビュー（reviewing-construction-code）、統合レビュー（reviewing-construction-integration）。**docs-only のため code レビューは docs 向け観点で適用する**: RFC 内容の整合性 / 設計判断の反映漏れ / markdownlint / 後続 Unit への入力としての明確性
- review_mode=required のためスキップ不可。tools=codex。

## 非スコープ

- workflow.md / data-model.md / migration.md（Unit 002/003/004）
- skeleton / スクリプト実装（後続フェーズ）
