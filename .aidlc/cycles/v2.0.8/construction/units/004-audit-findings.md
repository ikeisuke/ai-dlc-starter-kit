# Construction Phase 総点検 - 乖離リスト

## 重大な乖離

なし。

エージェントが検出した候補を精査した結果、全て以下のいずれかに該当:
- 設計通りの参照構造（commit-flow.mdへの委譲等）
- awkパターンがwrite-history.shの出力と正しくマッチ
- プロジェクト固有のため汎用記載不可

## 軽微な改善提案（Issue化）

### F-001: issue-ops.sh の出力形式が01-setup.mdに未記載
- **箇所**: steps/construction/01-setup.md ステップ11
- **内容**: issue-ops.sh の成功/失敗出力形式が記述に含まれていない
- **Issue**: #474

### F-002: implementation_record_template.md のプレースホルダ不統一
- **箇所**: templates/implementation_record_template.md
- **内容**: `<unit>` と `{{UNIT_SLUG}}` のプレースホルダ形式が混在
- **Issue**: #475

### F-003: run-markdownlint.sh の出力フォーマット未標準化
- **箇所**: steps/construction/04-completion.md ステップ6
- **内容**: スキップ/成功/エラーの出力が標準化されておらず判別困難
- **Issue**: #476
