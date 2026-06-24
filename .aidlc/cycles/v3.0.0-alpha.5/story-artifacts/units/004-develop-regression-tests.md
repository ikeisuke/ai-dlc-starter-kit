# Unit: develop normal/risky 回帰テスト + 全マトリクス統合検証

## 概要
`skills/aidlc-v3/scripts/tests/test-develop-flow.sh` を拡張し、normal/risky フローと `data-model.md` §8 の全有効 size×depth_level 組合せを検証する。tiny 非回帰と既存テスト緑を保証する。

## 含まれるユーザーストーリー
- ストーリー 4: 全 size×depth_level 組合せが回帰テストで保証される

## 責務
- `test-develop-flow.sh` に normal/risky 経路テストを追加
- §8 全有効組合せの検証: tiny×{minimal,standard,comprehensive} / normal×{minimal,standard,comprehensive} / risky×{standard,comprehensive}
  - `tiny + comprehensive` は「短い理由記録」が追加され、`tiny + {minimal,standard}` は Phase 3 挙動から不変であることを検証（Unit 001 の実装に対応）
- `risky + minimal` のエラー停止（副作用なし）テスト
- 成果物生成有無の検証: design（Unit 002）/ review（Unit 003）が size×depth_level に従って生成/スキップされる
- 既存テスト（define / develop tiny / state / next / activation / frontmatter / cycle-resolution）が全て緑であることの確認
- 外部レビュー CLI 呼び出しのモック/スタブ化（テストが実 CLI に依存しない）

## 境界
- 機能本体の実装（Unit 001 / 002 / 003）
- CI ワークフローへのジョブ追加（必要なら別途。本 Unit はローカルテストハーネス拡張に限定）

## 依存関係

### 依存する Unit
- 001-develop-size-depth-branching（依存理由: 分岐基盤の動作を検証する）
- 002-develop-design-step（依存理由: design 生成有無を検証する）
- 003-develop-review-routing（依存理由: review 実行有無を検証する）

### 外部依存
- bash テストハーネス（既存 `scripts/tests/`）

## 非機能要件（NFR）
- **パフォーマンス**: テストは実 CLI 非依存で短時間に完了する
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 既存 bash unit test の規約・アサーション様式に合わせる。
- レビュー呼び出しはスタブ化し、ルーティング判定（どの perspective が実行されるか）と成果物生成有無を検証対象とする。
- テスト分離規約（`bin/check-test-isolation.sh` 等）に違反しないこと。

## 関連Issue
- #736（部分対応 / Phase 4）

## 実装優先度
High

## 見積もり
0.5〜1 セッション

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
