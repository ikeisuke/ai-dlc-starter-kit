# Unit: develop Step 2（計画+設計）+ design template

## 概要
develop.md Step 2 を実装し、normal/risky の work item で size×depth_level に応じた設計成果物を `designs/<id>-<slug>.md` に生成する。`skills/aidlc-v3/templates/` に design テンプレートを新設し、リスク分析・test plan・rollback note を depth_level 別に含める。Step 2 完了時に Design 承認ゲートを発火させる。

## 含まれるユーザーストーリー
- ストーリー 2: normal/risky で設計成果物が生成され承認できる

## 責務
- `skills/aidlc-v3/templates/design.md`（仮称）の新設（design 本体 + 条件付きセクション: `## Risk Analysis` / `## Test Plan` / `## Rollback Note`）
- develop.md Step 2 実装: Unit 001 の size×depth_level 判定結果に基づき設計成果物を生成
  - `normal + standard`: 簡易 design
  - `normal + comprehensive`: design + リスク分析
  - `risky + standard`: design + rollback note（`## Rollback Note` 非空）
  - `risky + comprehensive`: design + リスク分析 + test plan + rollback note
- `designs/<id>-<slug>.md` の生成（Unit 001 が配線したパスへ）
- Design 承認ゲート発火（`automation_mode` に従う / semi_auto は条件付き auto）

## 境界
- size×depth_level 判定ロジック本体（Unit 001 で実装済みを利用）
- レビュー（reviewing-construction-design 等）の実行（Unit 003）
- `normal + minimal` での本 Step スキップ（Unit 001 の分岐で制御）

## 依存関係

### 依存する Unit
- 001-develop-size-depth-branching（依存理由: size×depth_level 判定結果と designs/ 出力先配線を利用する）

### 外部依存
- なし（テンプレートとファイル生成のみ）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 設計文書に機密情報を含めない（review-flow.md のマスク方針準用）
- **スケーラビリティ**: 該当なし
- **可用性**: テンプレート不在時は明示エラー（暗黙のデフォルト生成をしない）

## 技術的考慮事項
- rollback note は別ファイルを作らず `designs/*.md` 内の必須セクション `## Rollback Note`（v3 の成果物数を増やさない方針）。
- `workflow.md` §3.2（risky 一般 = design+risk analysis+test plan）と §8（risky+standard は含まない）の文言差は §8 を正本として実装し、§3.2 に depth_level 注記を補う（SoT 二重定義回避）。
- comprehensive でのシーケンス図追加（§3.2）は design テンプレートの任意セクションとして扱う。

## 関連Issue
- #736（部分対応 / Phase 4）

## 実装優先度
High

## 見積もり
1 セッション

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-26
- **完了日**: 2026-06-26
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
