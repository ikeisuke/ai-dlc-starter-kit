# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit / v3.0.0-alpha.1（Phase 1: RFC・data model 固定）

## 開発の目的

AI-DLC を v2 の漸進的改善ではなく、モダン AI モデル（Opus 4.x 等）を前提に **v3 としてゼロから再設計** する。その第一歩として、設計判断を確定する RFC 群（`docs/v3/`）と、後続実装の土台となる **state.json schema 初版**・**work item template 初版**を文書化する。

本サイクル（alpha.1）は v3 リニューアル全体（7〜8 サイクル）の **Phase 1** に相当し、成果物は実行可能物ではなく設計文書である。ここで固定する設計判断が Phase 2 以降（skeleton → define/develop → release → reflect/doctor）の全実装の土台になる。

なぜ必要か:

- v2 のステップ Markdown 6,436 行の約 60% が Claude 3.5 時代の防御ロジックで、モダンモデルには冗長
- 推論ベースの復帰判定（819 行）が過剰に複雑
- 10 個のレビュースキルが同一構造の複製（DRY 違反）
- 設計を先に固定しないまま実装に入ると、Phase 2 以降で設計ブレが波及する

## ターゲットユーザー

- **直接**: AI-DLC starter kit の開発者（本リポジトリ。ドッグフーディングで v2 を使い v3 を開発）
- **間接**: v3 を利用する consumer プロジェクト（RFC が将来のマイグレーション・利用体験の前提になる）

## ビジネス価値

- v3 実装全体の設計判断を 1 箇所に確定し、後続フェーズの手戻りを防ぐ
- core / extension 境界を明文化し、保守対象を約 71% 削減する設計根拠を残す
- consumer 向け v2 → v3 移行方針を早期に提示する

## スコープ

### 含まれるもの（このサイクルの成果物）

- `docs/v3/rfc.md` — v3 全体設計の正本（principles / core・extension 境界 / アーキテクチャ / 削減目標）
- `docs/v3/workflow.md` — コマンド設計（define/develop/release/reflect/status/doctor）、v2 対応、引数なし実行、フェーズ詳細設計
- `docs/v3/data-model.md` — ディレクトリ構造、state.json schema、work item frontmatter、フェーズ導出ロジック、journal、size×depth マトリクス
- `docs/v3/migration.md` — v2 → v3 移行方針・移行モード・データ変換・非互換点
- **state.json schema 初版**（data-model.md 内に確定例示として記載）
- **work item Markdown template 初版**（data-model.md 内に確定例示として記載）

### 含まれないもの（明示的除外 / 後続フェーズ）

- 既存 `skills/aidlc`（v2）の変更（クリーンカット、v3 は別系統で構築）
- `skills/aidlc-v3/` skeleton 実装（Phase 2 / alpha.2）
- define / develop / release フロー実装（Phase 3〜5）
- aidlc-review への 10 スキル統合の実装（Phase 4 以降。RFC では方針のみ）
- v2 → v3 migration スクリプト実装（migration.md は方針のみ、実装は別フェーズ）
- reflect / doctor 実装（Phase 6）
- 既存 v2 オープン Issue（#692/#693/#722/#723 等）の対応（v3 RFC の設計インプットとしては参照するが work item 化しない）

## 成功基準（受け入れ基準）

- [ ] v3 core / extension 境界が `docs/v3/rfc.md` に明記されている
- [ ] define / develop / release / reflect / status / doctor の責務が `docs/v3/workflow.md` に明記されている
- [ ] state.json schema が `docs/v3/data-model.md` に確定例示され、**必須フィールド集合・各フィールドの型・`schema_version` の値・各 enum の取りうる値**が明示されている（validator 実装は本サイクル対象外）
- [ ] work item Markdown template が `docs/v3/data-model.md` に確定例示され、**必須 frontmatter キー（id/status/size/risk/assigned/dependencies）・各 enum の取りうる値・本文必須セクション**が明示されている
- [ ] v2 から v3 への移行方針が `docs/v3/migration.md` に明記されている
- [ ] 計画書「判断が必要なポイント」6 件の設計判断が、RFC 内で各案の trade-off 分析 + 結論（理由付き）として記録されている
- [ ] **v2 共存方針が記録されている**: v2 `skills/aidlc` を変更しない前提での共存、コマンド名衝突の扱い（コマンド名自体は設計判断 #1 で検討するため「方針」として記録）、移行前 consumer への runtime 非影響が RFC または `docs/v3/migration.md` に記載されている
- [ ] **スコープ逸脱がない**: 本サイクルで実行可能コード（スクリプト / `skills/aidlc-v3/` 等）を生成しておらず、成果物が `docs/v3/*.md` および `.aidlc/cycles/` 配下に限定されている
- [ ] markdownlint を通過する

## 設計判断（RFC で一から検討する 6 点）

計画書「判断が必要なポイント」6 件を、RFC 執筆時に **一から検討** する。計画書の推奨案は検討材料の一入力として扱い、事前確定はしない。各論点について複数案の trade-off を評価し、結論と理由を RFC に記録する。

| # | 論点 | 計画書が挙げた案（参考） |
|---|------|------------------------|
| 1 | 表面コマンド名 | A: 新名称を正式名 / B: 旧名称維持 / C: 両対応 |
| 2 | Express モード | A: 維持 / B: 廃止 |
| 3 | v2 サポート期間 | A: 即 EOL / B: 条件付き EOL |
| 4 | review 統合粒度 | A: 1 skill + perspective / B: 3 skills / C: v2 維持 |
| 5 | GitHub 前提の強さ | A: git のみ / B: Issue/PR まで core / C: GitHub 前提強化 |
| 6 | state format | A: JSON / B: TOML / C: Markdown frontmatter / ハイブリッド |

**進め方**: RFC 執筆（Construction Phase）で各論点を順に検討し、結論が分かれうるものは承認ゲートでユーザー確認する。

## 期限とマイルストーン

- 本サイクル（alpha.1）= Phase 1。後続は alpha.2（skeleton）, alpha.3（define+develop tiny）... と段階進行
- 全 alpha 完走後に統合ブランチ `v3.0.0` を `main` へマージ

## 制約事項

- **ドッグフーディング**: v2 starter kit（2.6.6）の Inception/Construction を使って v3 設計を進める
- **docs-only**: 本サイクルは実行可能コードを生成しない（設計文書のみ）
- **ブランチ**: 作業は `cycle/v3.0.0-alpha.1`（`v3.0.0` ベース、`v3.0.0` は `v3/renewal-plan` 起点）。release で `cycle/v3.0.0-alpha.1 → v3.0.0` の PR
- **入力**: `docs/v3-renewal-plan.md`（v3 フルリニューアル計画書）を設計の正本入力かつ Reverse Engineering 成果として参照する
- **Reverse Engineering**: 計画書が v2 の定量分析（行数・スクリプト本数・復帰仕様等）を内包するため、別途 `existing_analysis.md` は作成せず計画書を参照する

## 不明点と質問（Inception Phase中に記録）

[Question] 計画書「判断が必要なポイント」6 件は、RFC でベースライン（計画書推奨）をそのまま正式結論として固定してよいか。それとも一部を再検討としてオープンにするか。
[Answer] 全てオープン。6 件とも RFC で一から検討し、各案の trade-off を評価して結論を出す。計画書推奨は一入力に留める。結論が分かれうる論点は承認ゲートでユーザー確認する。
