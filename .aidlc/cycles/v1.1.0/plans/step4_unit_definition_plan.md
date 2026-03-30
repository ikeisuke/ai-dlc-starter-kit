# ステップ4: Unit定義計画

## 目的
v1.1.0 の4機能をUnitに分解し、依存関係と実行順を定義する

## 作成するファイル
- `docs/cycles/v1.1.0/story-artifacts/units/unit1_operations_reusability.md`
- `docs/cycles/v1.1.0/story-artifacts/units/unit2_lite_cycle.md`
- `docs/cycles/v1.1.0/story-artifacts/units/unit3_branch_check.md`
- `docs/cycles/v1.1.0/story-artifacts/units/unit4_context_reset.md`

## Unit一覧と依存関係

| Unit | 名前 | 依存関係 | 優先度 | 見積もり |
|------|------|---------|--------|---------|
| Unit 1 | Operations Phase再利用性 | なし | High | 2時間 |
| Unit 2 | 軽量サイクル（Lite版） | なし | High | 3時間 |
| Unit 3 | ブランチ確認機能 | なし | Medium | 1時間 |
| Unit 4 | コンテキストリセット提案機能 | なし | High | 1.5時間 |

### 依存関係の説明
- 4つのUnitはすべて独立しており、並行して実装可能
- ただし、Unit 2（Lite版）は複数のプロンプトファイルを新規作成するため、最も作業量が多い
- Unit 4（コンテキストリセット）はUnit 2のLite版プロンプトにも適用が必要なため、Unit 2の後に実装することを推奨

### 推奨実行順序
1. Unit 3（ブランチ確認機能）- 最も小さく独立している
2. Unit 1（Operations再利用性）- 中程度の作業量
3. Unit 4（コンテキストリセット）- Full版プロンプトへの追加
4. Unit 2（Lite版）- 最大の作業量、Unit 4の内容も反映

## 実行手順
1. 各UnitのUnit定義ファイルを作成
2. progress.md のステップ4を「完了」に更新

## 承認
この計画で進めてよろしいですか？
