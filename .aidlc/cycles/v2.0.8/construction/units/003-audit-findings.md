# Inception Phase 総点検 - 乖離リスト

## 重大な乖離（修正済み）

### F-001: suggest-version.sh の cycle_name 重複計算リスク
- **箇所**: steps/inception/01-setup.md ステップ10-2（行467-480）
- **内容**: 記述では suggest-version.sh 実行後にAIが cycle_name に基づいて再計算する手順があるが、スクリプト自体が既にバージョン計算済みのため二重計算になる可能性
- **対応**: ドキュメント修正 — AIはスクリプト出力を信頼し、名前付きサイクル時のみ all_cycles からフィルタリングすることを明記

### F-002: unit_definition_template.md に「関連Issue」セクション欠落
- **箇所**: templates/unit_definition_template.md
- **内容**: label-cycle-issues.sh と 05-completion.md が「関連Issue」セクションの存在を前提としているが、テンプレートにセクションがない
- **対応**: テンプレートに「関連Issue」セクションを追加

## 軽微な乖離（Issue化）

### F-003: ステップ番号の欠番
- **箇所**: steps/inception/01-setup.md
- **内容**: ステップ5の後にステップ7が続き、ステップ6が欠番
- **Issue**: #470

### F-004: check-open-issues.sh 出力形式の曖昧性
- **箇所**: steps/inception/01-setup.md 行401-410
- **内容**: 記述では「#123 タイトル1」形式を想定するが、スクリプトはgh issue listのデフォルト出力をそのまま返す
- **Issue**: #471

### F-005: init-cycle-dir.sh バックログ出力メッセージ
- **箇所**: steps/inception/01-setup.md 行674-676
- **内容**: 「共通バックログディレクトリを作成」と記述されているが、v2.0.3以降はスキップされている
- **Issue**: #472

### F-006: worktree_path 名前付きサイクル形式未記載
- **箇所**: steps/inception/01-setup.md 行562-563
- **内容**: 名前付きサイクル時のworktree_path形式（スラッシュ→ハイフン置換）が記述されていない
- **Issue**: #473
