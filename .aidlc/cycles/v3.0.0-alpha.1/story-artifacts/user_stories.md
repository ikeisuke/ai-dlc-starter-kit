# ユーザーストーリー

## Epic: v3 設計文書化（Phase 1: RFC / data model 固定）

v3 フルリニューアルの設計判断を `docs/v3/` に確定し、Phase 2 以降の実装の土台を作る。成果物は設計文書のみ（docs-only）。

---

### ストーリー 1: RFC で v3 の設計判断を確定する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to v3 の core / extension 境界と 7 principles、削減目標、6 つの設計判断を 1 つの RFC に確定する
So that Phase 2 以降の全実装が一貫した設計判断の上で進められ、手戻りを防げる

**受け入れ基準**:
- [ ] `docs/v3/rfc.md` に v3 の 7 principles が記載されている
- [ ] core に残すもの / extension に分けるものの境界が明記されている
- [ ] v2 → v3 の削減目標（スキル数・ステップ行数・スクリプト本数・設定キー数等）が記載されている
- [ ] 計画書「判断が必要なポイント」6 件（コマンド名 / Express / v2 EOL / review 統合 / GitHub 前提 / state format）について、各案の trade-off 分析と結論（理由付き）が記録されている
- [ ] 分岐論点の扱い（承認ゲート対象とした論点）・承認結果・承認後の採用判断が `rfc.md` の Decision Gate Log 等に実際に記録されている
- [ ] v2 共存方針（v2 skills/aidlc を変更しない前提・コマンド名衝突の扱い・consumer runtime 非影響）が記録されている

**技術的考慮事項**:
6 つの設計判断は計画書推奨を一入力として扱い、一から検討する。コマンド名（判断 #1）は未確定論点のため、共存方針は「方針」として記録する。

---

### ストーリー 2: ワークフロー設計を文書化する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to 4 フェーズコマンド（define/develop/release/reflect）と 2 補助コマンド（status/doctor）の責務とコマンド設計を文書化する
So that Phase 2 の skeleton 実装が、各コマンドの責務とフェーズ遷移を明確な仕様として参照できる

**受け入れ基準**:
- [ ] `docs/v3/workflow.md` に 6 コマンドの責務が明記されている。うち define/develop/release/reflect は**フェーズコマンド**、status/doctor は**補助コマンド（読み取り専用 / 診断）**として区別されている
- [ ] v2 コマンド（inception/construction/operations/retrospective）との対応・エイリアス方針が記載されている
- [ ] 引数なし実行時のフェーズ自動ルーティング仕様が記載されている
- [ ] 各コマンド（define/develop/release/reflect/status/doctor）の Step レベル詳細設計が記載されている
- [ ] Express モードの扱いが記載されている

**技術的考慮事項**:
コマンド名の最終決定は RFC の設計判断 #1 に従う。workflow.md はその結論を反映する。

---

### ストーリー 3: データモデルと state schema を確定する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to ディレクトリ構造・state.json schema・work item frontmatter・フェーズ導出ロジックを確定する
So that Phase 2 以降の state スクリプト・work item 管理・復帰仕様が確定スキーマに基づいて実装できる

**受け入れ基準**:
- [ ] `docs/v3/data-model.md` に v3 ディレクトリ構造が記載されている
- [ ] state.json schema が確定例示され、必須フィールド集合・各フィールドの型・`schema_version` の値・各 enum の取りうる値が明示されている
- [ ] work item Markdown template が確定例示され、必須 frontmatter キー（id/status/size/risk/assigned/dependencies）・各 enum の取りうる値・本文必須セクションが明示されている
- [ ] フェーズ導出ロジック（state.json + frontmatter → フェーズ）が記載されている
- [ ] state.json / frontmatter の破損・不正・矛盾時の扱い（doctor が検知する破損パターンと復帰可否の方針）が方針レベルで記載されている（validator 実装は対象外、仕様記述のみ）
- [ ] journal 形式と size × depth_level マトリクスが記載されている

**技術的考慮事項**:
state format は RFC 設計判断 #6 の結論（ハイブリッド: cycle=JSON / work item=frontmatter）に従う。validator 実装は本サイクル対象外。

---

### ストーリー 4: v2 → v3 移行方針を提示する
**優先順位**: Must-have

As a v3 を利用する consumer プロジェクト
I want to v2 から v3 への移行モードとデータ変換方針、非互換点を事前に把握する
So that v3 採用時の移行コストとリスクを見積もり、安全な移行計画を立てられる

**受け入れ基準**:
- [ ] `docs/v3/migration.md` に移行モード（new-cycle-only / best-effort / archive-only）が記載されている
- [ ] 各移行モードの比較（推奨対象 / 前提条件 / 変換されるもの・されないもの / 既知リスク）が表で記載されている
- [ ] v2 → v3 のデータ変換マッピング（config/units/progress/history 等）が記載されている
- [ ] v2 との非互換点が列挙されている
- [ ] 推奨移行モードと片方向移行（rollback 不可）が明記されている

**技術的考慮事項**:
migration.md は方針のみ。migration スクリプト実装は本サイクル対象外（後続フェーズ）。

---

## 共通受け入れ基準（全ストーリー）

- [ ] 成果物が `docs/v3/*.md` および `.aidlc/cycles/` 配下に限定され、実行可能コード（スクリプト / skills/aidlc-v3 等）を生成していない
- [ ] `docs/v3/rfc.md` の設計判断と `workflow.md` / `data-model.md` / `migration.md` の記述が矛盾していない（文書間整合性）
- [ ] markdownlint を通過する
