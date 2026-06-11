# Unit 002 計画: v3 成果物テンプレート

- **Unit**: 002-v3-templates（v3 成果物テンプレート）
- **サイクル**: v3.0.0-alpha.2（Phase 2: aidlc-v3 skeleton）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required
- **関連 Issue**: なし

## 1. 目的

`skills/aidlc-v3/templates/` に v3 成果物テンプレート 3 種を作成する。設計正本は `docs/v3/data-model.md` §4（work item frontmatter / 本文必須セクション）・§7（journal 形式）。

- `templates/intent.md`: v3 Intent 構成（目的 / スコープ（含む・含まない）/ 受け入れ基準等）
- `templates/work-item.md`: frontmatter（必須キー id/status/size/risk/assigned/dependencies + 各 enum）+ 本文必須 6 セクション
- `templates/journal.md`: 追記型 journal 形式（日付見出し + 箇条書き）

## 2. スコープ

### 含むもの

- `skills/aidlc-v3/templates/intent.md`
- `skills/aidlc-v3/templates/work-item.md`
- `skills/aidlc-v3/templates/journal.md`
- テンプレートの構造検証（frontmatter キー/enum・必須セクションの存在確認）

### 含まないもの（後続フェーズへ defer）

- テンプレートを使ってファイルを実生成する define フロー実装（Phase 3）
- frontmatter/journal の正本定義（`docs/v3/data-model.md` が正本。本 Unit は準拠する）
- SKILL.md / steps（Unit 003）
- v2（`skills/aidlc`）への一切の変更

## 3. 設計方針（Phase 1 で詳細化）

### 3.1 work-item.md（`docs/v3/data-model.md` §4 準拠）

- **frontmatter 必須キー・型・enum**:
  - `id`: string（3 桁ゼロ埋め推奨）
  - `status`: enum `pending` / `in_progress` / `blocked` / `done` / `withdrawn`
  - `size`: enum `tiny` / `normal` / `risky`
  - `risk`: enum `low` / `medium` / `high`
  - `assigned`: string or null
  - `dependencies`: array（空配列可）
- **本文必須 6 セクション**: `Goal` / `Scope` / `Acceptance Criteria` / `Traceability` / `Size / Risk`（単一見出し）/ `Dependencies`。`Implementation Notes` は任意

### 3.2 journal.md（`docs/v3/data-model.md` §7 準拠）

- 追記型。タイトル `# Journal: {cycle}` + 日付見出し `## YYYY-MM-DD` 配下に箇条書き

### 3.3 intent.md

- v3 Intent 構成（目的 / スコープ（含む・含まない）/ 受け入れ基準 等）。work-item への trace 起点となる構成

### 3.4 共通方針

- placeholder 記法を統一（`{{...}}` または説明コメント）。テンプレートとして自然な形にする
- enum 値・キー名を `docs/v3/data-model.md` §4 と**完全一致**させる（表記揺れ・取りこぼしを避ける）
- markdownlint 通過

## 4. 完了条件チェックリスト

- [ ] `skills/aidlc-v3/templates/intent.md` が存在し、目的 / スコープ（含む・含まない）/ 受け入れ基準を含む
- [ ] `skills/aidlc-v3/templates/work-item.md` が存在し、frontmatter 必須キー（id/status/size/risk/assigned/dependencies）+ 本文必須 6 セクション（Goal/Scope/Acceptance Criteria/Traceability/Size / Risk/Dependencies）を含む
- [ ] **構造検証（grep 単位ではなく構造的確認）**: work-item.md の frontmatter を YAML として parse し、(a) 必須キー集合が `id/status/size/risk/assigned/dependencies` と**過不足なく一致**、(b) `status`/`size`/`risk` の値または候補列挙が SoT（status 5 値 `pending/in_progress/blocked/done/withdrawn` / size 3 値 `tiny/normal/risky` / risk 3 値 `low/medium/high`）と一致、(c) 本文見出し `## Goal` / `## Scope` / `## Acceptance Criteria` / `## Traceability` / `## Size / Risk` / `## Dependencies` がすべて存在、を検証する。検証は再現可能な手順（テンプレートのコメント等に enum 候補を明示し、検証スクリプト or 手順で確認）として担保する
- [ ] `skills/aidlc-v3/templates/journal.md` が存在し、トップレベルタイトル `# Journal: {{cycle}}` 相当 + 日付見出し `## YYYY-MM-DD` + 配下の箇条書き、の追記型形式（`docs/v3/data-model.md` §7 の確定例示に準拠）
- [ ] 3 テンプレートが `docs/v3/data-model.md` の確定仕様（§4 / §7）に準拠
- [ ] **v2 非影響**: `skills/aidlc/` 配下に変更がない（`git diff` で確認）
- [ ] スコープ逸脱がない（成果物が `skills/aidlc-v3/templates/` および `.aidlc/cycles/` 配下に限定、define フロー実装を含まない）
- [ ] markdownlint を通過する
- [ ] `skills/**` 配下で `skills/aidlc/` プロジェクトルート相対参照を含まない（CI 構造チェック準拠）

## 5. 想定リスク

- **enum/キーの表記揺れ**: SoT（data-model §4）との不一致 → 設計レビューで照合 + 検証ステップで YAML parse による構造検証（必須キー集合 / enum 値・候補 / 本文見出しの一致確認。完了条件 §4 と同方針）
- **placeholder 記法の混在** → 記法を統一し設計で明示

## 6. 進め方

1. Phase 1（設計）: ドメインモデル（work item ドキュメントモデル）→ 論理設計（3 テンプレート構造）→ 設計 AI レビュー → 承認
2. Phase 2（実装）: テンプレート 3 種生成 → コード AI レビュー → 構造検証 → 統合 AI レビュー → 承認
3. 完了処理: 完了条件チェック → Unit 状態更新 → 履歴記録 → markdownlint → squash → コミット
