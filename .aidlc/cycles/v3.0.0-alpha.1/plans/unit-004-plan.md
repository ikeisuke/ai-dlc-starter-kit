# Unit 004 計画: v3 移行方針（migration.md 確定）

## 対象 Unit

- Unit 004: v3-migration
- 成果物: `docs/v3/migration.md`
- 依存:
  - Unit 001 v3-rfc-core（完了）。core/extension 境界・非互換点の前提を入力とする
  - Unit 003 v3-data-model（完了）。v3 ディレクトリ構造・state.json schema・work item frontmatter を入力とし、v2 → v3 データ変換マッピングの確定根拠とする
- 入力参照:
  - `docs/v3/rfc.md`（確定済み RFC。core/extension 境界・設計判断）
  - `docs/v3/data-model.md`（Unit 003 完了。v3 ディレクトリ構造 / state.json schema / work item frontmatter template = 変換先の正本）
  - `docs/v3/workflow.md`（Unit 002 完了。コマンド名 `develop` 統一 / `/aidlc-migrate` の位置付け）
  - `docs/v3-renewal-plan.md`（v2 → v3 移行セクション L941-983: 移行方針・移行モード・データ変換表・移行コマンド手順 / v2 との非互換点 L1338-1350 / リスクと対策 L1241-1245）
- 見積もり: docs 1 ファイル（中）。比較表・変換マッピング表を含む。**方針のみ（スクリプト実装は対象外）**

## アプローチ

docs-only の設計文書のため、Phase 1（設計）/ Phase 2（実装）を Unit 002 / 003 と同様にマッピングする:

- **Phase 1（設計）**: migration.md の論理設計（章立て + 各セクションの確定内容の骨子）を `design-artifacts/logical-designs/unit_004_v3_migration_logical_design.md` に記録する。ドメインモデルは docs-only のため N/A。
- **Phase 2（実装）**: 確定設計に基づき `docs/v3/migration.md` を執筆。

## SoT・整合方針（重要）

- 本 Unit は v2 → v3 **移行方針**の正本（SoT）を確定する。`renewal-plan` の移行セクションは計画段階の下書きであり、本 Unit 確定をもって正本化される。
- **変換先構造の整合**: データ変換マッピングの変換先（v3 ディレクトリ構造 / state.json / work item frontmatter）は Unit 003 `data-model.md` を正本として参照する。本書は変換**規則**を定義し、変換先 schema 自体を二重定義しない（drift 防止）。
- **config 変換の SoT ガード（重要）**: v3 config.toml のキー終端設計（34→8 のキー集合・命名）は RFC §6.4 と data-model.md §8 が相互委譲しており、現時点でどの確定文書にも存在しない（既知の SoT ギャップ）。migration.md の config 変換は **キーマッピング方針と不要キー警告の挙動のみ**を記述し、v3 config 終端 schema（8 キーの具体集合）を本書で新規定義しない（二重定義・drift 回避）。終端 schema 未確定の事実を migration.md に注記し、確定は別途（RFC §6 / data-model.md `defaults.toml` 設計）に委ねる。data-model.md §8 が確定済みの `depth_level`（保存場所 / enum / 既定値）のみは確定参照可。
- **コマンド名整合**: RFC / workflow.md 確定の `develop`（旧表記 `build` 不採用）を使用する。`renewal-plan` の移行セクション例示が旧表記を含む場合は確定名に補正する。
- **非互換点の整合**: 非互換点リストは RFC（Unit 001）が確定した core/extension 境界と矛盾しないこと。GitHub Projects 廃止 / Milestone の extension 化等、core 責務縮小に伴う非互換は RFC の結論に追従する。

## 成果物の責務（Unit 定義由来）

- `docs/v3/migration.md` の作成
- 移行モード（new-cycle-only / best-effort / archive-only）の定義 + 比較表（推奨対象 / 前提条件 / 変換有無 / 既知リスク）
- v2 → v3 データ変換マッピング（config / units / progress / history / release_notes）
- v2 との非互換点の列挙
- 推奨移行モード（new-cycle-only）と片方向移行（rollback 不可）の明記
- **DG-3 条件付き EOL の引き継ぎ受け（RFC §7 由来）**: RFC（Unit 001）§7 引き継ぎマトリクスが DG-3 → migration.md に渡す「EOL 3 条件・移行期間中 v2 非変更・consumer runtime 非影響・片方向移行」の相互関係を方針レベルで記述する（条件付き EOL の前提として移行が成立する関係性の明示。実際の EOL 宣言・告知の実施作業は対象外）

## 完了条件チェックリスト（Unit 004 責務由来）

- [ ] `docs/v3/migration.md` が作成されている
- [ ] 移行モード 3 種（new-cycle-only / best-effort / archive-only）が定義され、各モードの比較表（推奨対象 / 前提条件 / 変換有無 / 既知リスク）が記述されている
- [ ] v2 → v3 データ変換マッピングが主要 v2 資産（config / units / progress / history / release_notes）を網羅し、各変換の変換方法（パスコピー / テンプレート差分 / パース+schema 生成 / 要約統合 / キーマッピング）が明示されている
- [ ] データ変換マッピングの変換先（ディレクトリ構造 / state.json / work item frontmatter）が Unit 003 `data-model.md` を正本として参照し、schema を二重定義していない
- [ ] config 変換が「キーマッピング方針 + 不要キー警告の挙動」のみを記述し、v3 config 終端 schema（8 キーの具体集合）を本書で新規定義していない。終端 schema が未確定（RFC §6 / data-model.md `defaults.toml` 設計に委ねる）である旨が注記されている
- [ ] v2 との非互換点が列挙され、各非互換点について consumer への影響（再作成要 / 無視 / マイグレーション対象 等）が明示されている
- [ ] 推奨移行モードが new-cycle-only であることと、その理由（過去資産を触らない）が明記されている
- [ ] v2 → v3 が片方向移行（rollback 不可）であることが明記されている
- [ ] RFC §7（DG-3）が migration.md に引き継ぐ「EOL 3 条件・移行期間中 v2 非変更・consumer runtime 非影響・片方向移行」の相互関係が方針レベルで記述されている（条件付き EOL が移行成立を前提とする関係性の明示。EOL 宣言・告知の実施作業は対象外）
- [ ] 移行コストを consumer が見積もれる粒度で記述されている（NFR: 明確性）
- [ ] migration スクリプトの実装が本サイクル対象外（方針のみ）であることが明示されている
- [ ] コマンド名が RFC / workflow.md 確定の `develop` に整合している（旧表記 `build` を使用していない）
- [ ] RFC（Unit 001）の core/extension 境界・非互換点の前提と矛盾しない
- [ ] Unit の最終成果物が `docs/v3/migration.md`（docs/v3 配下）に限定され、実行可能コード（migrate スクリプト）を生成していない（`design-artifacts/logical-designs/` 配下の論理設計は AI-DLC 設計フェーズのプロセス記録であり、Unit 最終成果物には含めない）
- [ ] markdownlint を通過する

## レビュー方針

- Phase 1（設計）: 計画承認前レビュー（reviewing-construction-plan）、設計レビュー（reviewing-construction-design）
- Phase 2（実装）: コードレビュー（reviewing-construction-code）、統合レビュー（reviewing-construction-integration）。**docs-only のため code レビューは docs 向け観点で適用**: RFC core/extension 境界との整合性 / data-model.md との SoT 二重定義回避 / コマンド名整合（develop） / 変換マッピングの網羅性（config/units/progress/history/release_notes） / 移行モード比較表の確定性 / 片方向移行・推奨モードの明記 / markdownlint / consumer が移行コストを見積もれる明確性
- review_mode=required のためスキップ不可。tools=codex。

## 非スコープ

- migration スクリプトの実装（後続フェーズ、本サイクル対象外）
- core/extension 境界の選定理由（Unit 001 RFC で確定済み・参照のみ）
- v3 データモデル詳細（Unit 003 data-model.md で確定済み・参照のみ）
- v3 config.toml キー終端設計（8 キーの具体集合・命名）の確定（RFC §6 / data-model.md `defaults.toml` 設計に委ねる。本 Unit は変換規則のみ扱い、終端 schema を確定しない）
- v2 EOL の運用実行・告知作業（実際の EOL 宣言 / README・CHANGELOG への告知掲載 / メンテナンスモード運用の実施）は後続の運用判断であり対象外。ただし RFC §7（DG-3）が migration.md に引き継ぐ「EOL 3 条件・メンテナンスモード方針と移行成立の関係性」の**方針記述**は本 Unit のスコープ内（上記責務参照）
