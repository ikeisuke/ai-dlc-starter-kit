## フロー（1つのUnitのみ）

### Phase 1: 設計【対話形式、コードは書かない】

**重要**: このフェーズでは設計ドキュメントのみ作成します。
実装コードは Phase 2 で設計承認後に書きます。
設計レビューで承認を得るまで、コードファイルを作成・編集してはいけません。

#### ステップ1: ドメインモデル設計

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: このステップをスキップ可能。スキップする場合は「設計省略（depth_level=minimal）」を履歴に記録し、ステップ3（設計レビュー）もスキップしてPhase 2へ進む
- `comprehensive`: 標準的なドメインモデルに加え、ドメインイベント定義を追加
- `standard`: 変更なし（現行動作）

- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら構造と責務を定義（1つの質問をして回答を待ち、複数の質問をまとめて提示しない）
- **成果物**: `.aidlc/cycles/{{CYCLE}}/design-artifacts/domain-models/[unit_name]_domain_model.md`（テンプレート: `skills/aidlc/templates/domain_model_template.md`）
- **重要**: **コードは書かず**、エンティティ・値オブジェクト・集約・ドメインサービスの構造と責務のみを定義

#### ステップ2: 論理設計

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: このステップをスキップ可能。スキップする場合は「設計省略（depth_level=minimal）」を履歴に記録し、ステップ3（設計レビュー）もスキップしてPhase 2へ進む
- `comprehensive`: 標準的な論理設計に加え、シーケンス図・状態遷移図を追加
- `standard`: 変更なし（現行動作）

- **対話形式**: 同様に**一問一答形式**で対話しながらコンポーネント構成とインターフェースを定義
- **成果物**: `.aidlc/cycles/{{CYCLE}}/design-artifacts/logical-designs/[unit_name]_logical_design.md`（テンプレート: `skills/aidlc/templates/logical_design_template.md`）
- **重要**: **コードは書かず**、アーキテクチャパターン、コンポーネント構成、API設計の概要のみを定義

#### ステップ3: 設計レビュー

**タスク管理機能を活用してください。**

1. **AIレビュー実施**（`steps/common/review-flow.md` に従う）
2. レビュー結果を反映
3. **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認しPhase 2へ進む。上記以外は設計内容をユーザーに提示し、承認を得る

**承認なしで実装フェーズに進んではいけない**（`automation_mode=semi_auto` での自動承認を除く）

