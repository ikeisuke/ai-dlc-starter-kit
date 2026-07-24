# Design {{id}}: {{title}}

- trace: work item {{id}}-{{slug}}
- matrix_case: {{matrix_case}}
- design_mode: {{design_mode}}   # simple | full

## Goal

{{この work item の設計目的（work item の Goal に対応）}}

## Context

{{既存実装・制約・前提。design_mode=simple は要点のみ / full は詳細に記述}}

## Design

{{設計本体。design_mode=simple: 簡易（要点と方針）/ full: 詳細（コンポーネント構成・インターフェース・処理フロー）。comprehensive ではシーケンス図を本セクション内の任意要素として追加してよい}}

<!-- 条件付きセクション: risk_analysis=true（comprehensive 系）のときのみ含める。false のときは本セクションを出力しない -->
## Risk Analysis

{{リスクと緩和策（comprehensive のリスク分析）}}

<!-- 条件付きセクション: test_plan=true（risky+comprehensive）のときのみ含める。false のときは本セクションを出力しない -->
## Test Plan

{{テスト方針・観点・検証手順}}

<!-- 条件付きセクション: rollback_note=true（risky 系）のときのみ含める。risky では非空必須。false のときは本セクションを出力しない -->
## Rollback Note

{{ロールバック手順・切り戻し方針（risky は非空で記述）}}
