# 実装記録: Unit 002 v3 成果物テンプレート

## 実装日時

2026-06-11（Construction Phase / Unit 002）

## 作成ファイル

### ソースコード（テンプレート）

- `skills/aidlc-v3/templates/work-item.md` - work item 雛形。frontmatter（id 引用符付き / status / size / risk / assigned / dependencies + 各 enum をコメント明示）+ 本文必須 6 セクション（Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies）+ 任意 Implementation Notes
- `skills/aidlc-v3/templates/intent.md` - Intent 雛形（目的 / スコープ（含む・含まない）/ 受け入れ基準 / 制約・前提）
- `skills/aidlc-v3/templates/journal.md` - journal 雛形（`# Journal: {{cycle}}` + 日付見出し `## YYYY-MM-DD` + 箇条書き）

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/domain-models/unit_002_v3_templates_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/logical-designs/unit_002_v3_templates_logical_design.md`

## ビルド結果

成功（静的テンプレートのためビルドは構造検証で代替）

```text
markdownlint-cli2: 3 ファイル 0 errors
CI 構造チェック: skills/aidlc/ プロジェクトルート相対参照なし
```

## テスト結果（構造検証 / 再現可能手順）

成功。以下の再現可能な手順で構造を検証（計画 §4 完了条件に対応）:

```text
1. work-item.md frontmatter 必須キー: id/status/size/risk/assigned/dependencies → 6/6 存在
2. enum 候補（コメント明示）: status=pending/in_progress/blocked/done/withdrawn,
   size=tiny/normal/risky, risk=low/medium/high → SoT(data-model §4)と一致
3. 本文必須6セクション: ## Goal / ## Scope / ## Acceptance Criteria /
   ## Traceability / ## Size / Risk / ## Dependencies → 6/6 存在
4. YAML parse(ruby): keys={assigned,dependencies,id,risk,size,status},
   id=String"{{id}}"(引用符付き), dependencies=Array[], assigned=nil → 妥当
5. journal.md: # Journal: タイトル + ## 日付見出し → 存在
6. intent.md: ## 目的 / ### 含むもの / ### 含まないもの / ## 受け入れ基準 → 存在
```

## コードレビュー結果

- [x] セキュリティ: OK（機密情報・ローカル絶対パス混入なし）
- [x] コーディング規約: OK（placeholder `{{...}}` 統一、`skills/aidlc/` 参照なし）
- [x] 整合性: OK（frontmatter キー/型/enum・本文6セクション・journal形式が SoT と完全一致）
- [x] テストカバレッジ: OK（構造検証 6 項目を再現可能手順で確認）
- [x] ドキュメント: OK（enum 候補・記述ガイドをコメント明示）

## 技術的な決定事項

- **雛形ソース**: data-model §4.2 / §7 の確定例示を雛形化し SoT との完全一致を担保
- **id の引用符付き**: `id: "{{id}}"` とし、未引用展開での YAML 数値化・parse 不整合を防止（設計レビュー指摘 #1 反映）
- **placeholder 記法**: `{{...}}` で統一（v2 テンプレートと整合）。enum 候補・記述ガイドは YAML コメント / 注記で明示
- **検証方式**: 静的テンプレートのため実行テストではなく構造検証（frontmatter キー/enum・本文見出し・YAML 妥当性）を再現可能手順で実施

## 課題・改善点

- テンプレートを使った実ファイル生成（define フロー）は Phase 3 へ defer（intent スコープに整合）

## 状態

**完了**

## 備考

- v2 非影響を全コミットで確認（`skills/aidlc/` 配下の変更なし）。成果物は `skills/aidlc-v3/templates/` および `.aidlc/cycles/` 配下に限定
