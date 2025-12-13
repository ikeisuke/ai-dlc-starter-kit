# ステップ4: Unit定義計画

## 概要
10個のユーザーストーリーを7つのUnitに分割する

## Unit構成

| Unit | 名前 | ストーリー | 優先度 | 依存 |
|------|------|----------|--------|------|
| 1 | サイクルバージョン提案改善 | ストーリー2 | High | なし |
| 2 | GitHub Issue確認とセットアップ統合 | ストーリー3, 4 | High | なし |
| 3 | Operations Phase構造改善 | ストーリー7, 8 | High | なし |
| 4 | 割り込み対応ルール | ストーリー5 | Medium | なし |
| 5 | AI MCPレビュー提案 | ストーリー6 | Low | なし |
| 6 | git worktree提案 | ストーリー1 | Low | なし |
| 7 | 複数人開発時コンフリクト対策 | ストーリー9, 10 | Low | なし |

## グループ化の理由

- **Unit 2**: ストーリー3（GitHub Issue確認）と4（セットアップ統合）は両方とも `inception.md` の「最初に必ず実行すること」セクションを編集するため統合
- **Unit 3**: ストーリー7（完了作業の構造改善）と8（アプリバージョン確認）は両方とも `operations.md` を編集するため統合
- **Unit 7**: ストーリー9（history.md）と10（backlog.md）は同じ問題（コンフリクト）を同じ方針で対応するため統合

## 実装順序（推奨）

1. Unit 1: サイクルバージョン提案改善
2. Unit 2: GitHub Issue確認とセットアップ統合
3. Unit 3: Operations Phase構造改善
4. Unit 4: 割り込み対応ルール
5. Unit 5: AI MCPレビュー提案
6. Unit 6: git worktree提案
7. Unit 7: 複数人開発時コンフリクト対策

## 出力ファイル
- `docs/cycles/v1.4.0/story-artifacts/units/unit1_version_proposal.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit2_issue_and_setup.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit3_operations_improvement.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit4_interruption_handling.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit5_mcp_review.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit6_worktree.md`
- `docs/cycles/v1.4.0/story-artifacts/units/unit7_conflict_prevention.md`

## 次のアクション
承認後、各Unit定義ファイルを作成
