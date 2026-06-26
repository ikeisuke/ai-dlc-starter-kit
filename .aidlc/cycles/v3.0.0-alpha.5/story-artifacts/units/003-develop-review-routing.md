# Unit: develop Step 5（レビュー）+ review routing

## 概要
develop.md Step 5 を実装し、size×depth_level に応じたレビューを既存 reviewing-construction-* スキルへルーティングする。結果を `reviews/<id>-<slug>.md` に perspective 別セクションで記録し、5R 上限・Defer 戦略（自動 Issue 起票）を適用する。

## 含まれるユーザーストーリー
- ストーリー 3: review routing で normal/risky のレビューが既存スキルへ流れる

## 責務
- develop.md Step 5 実装: ストーリー3「develop 内レビュー実行マトリクス」に従いレビューを実行
  - `normal + standard` / `normal + comprehensive`: code review（`reviewing-construction-code`）
  - `risky + standard`: code review（security focus）
  - `risky + comprehensive`: 複数 review = code（security focus）+ design（`reviewing-construction-design`）
  - `normal + minimal`: 実行しない
- plan / design / code の 3 perspective のルーティング能力を実装（実行はマトリクスで制御）
- `reviews/<id>-<slug>.md` への perspective 別セクション記録（`## Code Review` / `## Design Review`、追記・上書き禁止）
- 反復上限 5R、`OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘の自動 Issue 起票（Defer 戦略）
- `deploy` / `premerge` / `integration` を develop で実行しない（release 用）ことの保証

## 境界
- 設計成果物の生成（Unit 002）。design review は Unit 002 が生成した `designs/*.md` を対象とする
- `aidlc-review`（9→1 統合スキル）の新規作成（本サイクル対象外 / 別サイクル）
- release フェーズのレビュー（Phase 5）

## 依存関係

### 依存する Unit
- 001-develop-size-depth-branching（依存理由: size×depth_level 判定結果と reviews/ 出力先配線を利用）
- 002-develop-design-step（依存理由: risky+comprehensive の design review 対象成果物 `designs/*.md` を Unit 002 が生成する）

### 外部依存
- `skills/reviewing-construction-code`（呼び出し名 / args 形式は review-routing.md §7）
- `skills/reviewing-construction-design`（同上）
- レビュー CLI（codex 等）: `[rules.reviewing].tools` 設定に従う

## 非機能要件（NFR）
- **パフォーマンス**: レビュー反復は 5R 上限で打ち切る（無限ループ防止）
- **セキュリティ**: security focus レビューの公開記録はマスク方針（review-flow.md）に従う
- **スケーラビリティ**: 該当なし
- **可用性**: レビュー CLI 不在時は review-routing.md のフォールバック（self/ユーザー）に従う

## 技術的考慮事項
- 既存 reviewing-construction-* への暫定ルーティング（`aidlc-review` 統合は別サイクル）。
- SoT 内不整合（§6.1 vs §6.2/§8）は §6.2/§8 を正本に実装し、§6.1 の plan review 列挙の文言整合を本 Unit の設計で確定（plan review の develop 内実行有無を含む）。
- 「ドッグフーディング特殊処理の禁止」: スキル呼び出しに自リポジトリ判定を埋め込まない。

## 関連Issue
- #736（部分対応 / Phase 4）

## 実装優先度
High

## 見積もり
1〜1.5 セッション

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-26
- **完了日**: 2026-06-27
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
