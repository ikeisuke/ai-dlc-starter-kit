# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的

**主目的**: v2.2.0-v2.2.2で進めたコンテキスト圧縮（#519）の仕上げとして、Tier 1施策（session-state.md廃止、preflight.md圧縮、設定値に応じた条件ロードスキップ）を完了し、初回ロードをさらに削減する。

**副次目的**: バックログに蓄積された構造改善・運用改善を消化する。
- 不要ルール・冗長判定の棚卸し（#544）
- SKILL.mdの構造整理・整形（#549関連）
- adminマージ禁止・auto-merge有効化（#548）

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（自身を含む）

## ビジネス価値
- コンテキストウィンドウの消費削減により、セッション中盤でのcompactionリスクを低減
- 不要ルールの除去によりAIエージェントの判断精度が向上
- adminマージ禁止によりCIチェックのバイパスを防止し、品質ゲートを強化

## 成功基準

計測条件: v2.2.2のInception Phase初回ロード（24,564 tok）を基準とし、tiktoken cl100k_base で同一条件比較。

- session-state.md関連ロジックが廃止され、session-continuity.mdからv2.2.2比で約400tok削減
- preflight.md出力フォーマット簡略化によりv2.2.2比で約1,000tok削減
- 不要ルール・冗長判定が特定・除去される
- SKILL.mdが整形され、セクション構造が明確になる
- adminマージ禁止・auto-merge設定がOperations Phaseフローに反映される

## 含まれるもの（Must/Should分類）

### Must（必須）
1. session-state.md廃止（#547）— session-continuity.mdの簡略化、関連する各ステップファイルからの参照除去
2. preflight.md圧縮（#519 S8）— 出力フォーマット簡略化、冗長な説明の除去
3. 設定値に応じた条件ロードスキップ（#519 Tier 1）— `steps/common/` 配下の必要時ロードファイル（review-flow.md, rules-automation.md等）が対象。`steps/{inception,construction,operations}/` 配下のフェーズステップファイルは不変ルールにより省略不可であり、スキップ対象外
4. SKILL.md構造整理（#549関連）— 整形、セクション整理。再現していないハーネスバグの修正は対象外で、文書構造の明確化のみ

### Should（余力対応）
5. 不要ルール・冗長判定の棚卸し（#544）— ステップファイル・ガイド内の重複除去
6. adminマージ禁止・auto-merge対応（#548）— Operations Phaseマージフローへのauto-merge対応追加

## 含まれないもの
- Tier 2以降の圧縮施策（operations-release.mdスクリプト化、review-flow判定スクリプト化等）
- S4alt（プログレッシブロード）の本格実装
- MCP/ツールベース検索の導入
- ハーネスバグ（#549）自体の修正（再現していないため。SKILL.md構造整理は再発防止を意図せず、文書としての可読性向上のみを目的とする）

## 期限とマイルストーン
patchリリース。1サイクルで完了。

## 制約事項
- メタ開発プロジェクト：ツール側（`skills/aidlc/`）の編集が主
- 不変ルール「ステップファイルの読み込みは省略不可」に抵触しない範囲で圧縮。条件ロードスキップの対象は `steps/common/` 配下の必要時ロードファイルのみであり、フェーズステップファイル（`steps/{inception,construction,operations}/`）は対象外
- 品質劣化リスクマトリクス（#519）に記載のセクションは慎重に扱う

## 互換性・維持条件
- 既存の必須レビュー導線（`review_mode=required` 時のパス1/2フロー）は維持
- 既存設定のデフォルト挙動は不変（条件ロードスキップは明示的な設定変更時のみ発動）
- Operations Phaseの既存マージ条件を緩和しない（auto-mergeは追加オプション）

## 不明点と質問（Inception Phase中に記録）

なし（対話で確認済み）
