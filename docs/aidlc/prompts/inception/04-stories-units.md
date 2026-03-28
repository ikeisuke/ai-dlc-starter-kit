# Inception Phase - ストーリー・Unit定義

## ステップ3: ユーザーストーリー作成

**タスク管理機能を活用してください。**

- Intentに基づいてユーザーストーリーを作成

**受け入れ基準の書き方【重要】**:

受け入れ基準は「何が実現されていれば完了とみなせるか」を具体的に記述する。

**良い例**（具体的で検証可能）:

- 「ログインボタンをクリックすると、ダッシュボード画面に遷移する」
- 「エラー時に赤色の警告メッセージが3秒間表示される」
- 「検索結果が100件を超える場合、ページネーションが表示される」

**悪い例**（曖昧で検証困難）:

- 「ユーザーが使いやすいこと」
- 「パフォーマンスが良いこと」
- 「適切に処理されること」

**記述のポイント**:

- 主語・動詞・結果を明確にする
- 数値や状態を具体的に記述する
- テスト可能な形で書く

**受け入れ基準のチェック観点【必須】**:

ユーザーストーリー作成時に、以下の観点で受け入れ基準をチェックする：

| チェック項目 | 確認内容 |
|-------------|---------|
| 具体性 | 数値、状態、動作が具体的に記述されているか |
| 検証可能性 | テストで確認できる形式になっているか |
| 完全性 | 正常系・異常系の両方が網羅されているか |
| 独立性 | 他の条件と重複や矛盾がないか |

- `.aidlc/cycles/{{CYCLE}}/story-artifacts/user_stories.md` を作成（テンプレート: `skills/aidlc/templates/user_stories_template.md`）

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: 受け入れ基準を主要ケースのみに簡略化（主要エラーケースは維持）
- `comprehensive`: 完全な受け入れ基準に加え、エッジケースを網羅
- `standard`: 変更なし（現行動作）

**AIレビュー**: ユーザーストーリー承認前に `steps/common/review-flow.md` に従ってAIレビューを実施すること。

**Inception固有のレビュー観点**:
- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

### ステップ4: Unit定義【重要】

**タスク管理機能を活用してください。**

- ユーザーストーリーを独立した価値提供ブロック（Unit）に分解
- **各Unitの依存関係を明確に記載**（どのUnitが先に完了している必要があるか）
- 依存関係がない場合は「なし」と明記
- 依存関係は Construction Phase での実行順判断に使用される
- 各Unitは `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/{NNN}-{unit-name}.md` に作成（テンプレート: `skills/aidlc/templates/unit_definition_template.md`）

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: 最小限の責務・境界記述。依存関係と優先度のみ記載
- `comprehensive`: 完全な記述に加え、技術的リスク評価セクションを追加
- `standard`: 変更なし（現行動作）

**Unit定義ファイルの命名規則**:
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- NNN: 3桁の0埋め番号（001, 002, ..., 999）
- unit-name: Unit名のケバブケース
- 番号は依存関係に基づく実行順序を表す
- 連番の重複は禁止
- 依存関係がないUnitは任意の順番でよいが、優先度順に番号付けを推奨
- **実装状態セクション**: 各Unit定義ファイルの末尾に以下のセクションを含める（テンプレートに含まれている）
  ```markdown
  ---
  ## 実装状態

  - **状態**: 未着手
  - **開始日**: -
  - **完了日**: -
  - **担当**: -
  - **エクスプレス適格性**: -
  - **適格性理由**: -
  ```

**AIレビュー**: Unit定義承認前に `steps/common/review-flow.md` に従ってAIレビューを実施すること。

**Inception固有のレビュー観点**:
- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

### ステップ4b: エクスプレスモード判定

**スキップ条件**: `express_enabled` が `false` の場合、このステップをスキップする。

`express_enabled=true` の場合、`common/rules.md` の「エクスプレスモード仕様」セクションに従い判定を実施する。

**判定手順**:

1. Unit定義ファイルの数をカウントする:

```bash
ls .aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md 2>/dev/null | wc -l
```

2. Unit数が0の場合: フォールバック。`common/rules.md` の「エクスプレスモード仕様」セクションのフォールバック通知メッセージ（Unit数0用）を表示し、通常フローを継続（ステップ5へ進む）

3. Unit数が1以上の場合: 各 Unit に対して複雑度判定を実施する。`common/rules.md` の「複雑度判定ルール」に従い、Unit 定義ファイルの内容に基づいて4項目（受け入れ基準の明確さ、依存関係の複雑さ、技術的リスク、変更影響範囲）を評価する。

4. 判定結果に応じた分岐:

- **全 Unit が eligible**: エクスプレスモード有効。各 Unit 定義ファイルの「実装状態」セクションに `エクスプレス適格性: eligible` を記録する。以下のメッセージを表示:

  ```text
  【エクスプレスモード有効】全Unit（N件）が複雑度条件を満たしたため、Inception→Construction統合フローを適用します。
  ```

  → `depth_level=minimal` の場合: ステップ5（PRFAQ）をスキップし、「エクスプレスモード完了処理」セクションへ進む
  → `depth_level=standard/comprehensive` の場合: ステップ5（PRFAQ）へ進み、PRFAQ作成完了後に「エクスプレスモード完了処理」セクションへ進む

- **1つでも ineligible**: フォールバック。`common/rules.md` の「エクスプレスモード仕様」セクションのフォールバック通知メッセージ（複雑度不適格用）を表示し、通常フローを継続（ステップ5へ進む）。該当 Unit 定義ファイルに `エクスプレス適格性: ineligible` と理由を記録する。

**フォールバック時の履歴記録**:

フォールバック発生時、以下を履歴に記録する:

```bash
skills/aidlc/scripts/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "エクスプレスモード判定" \
    --content "エクスプレスモードフォールバック: [理由]"
```

### ステップ5: PRFAQ作成

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: このステップをスキップ可能（progress.mdで「スキップ」に更新し、完了時の必須作業へ）
- `comprehensive` / `standard`: 通常通り実行

- プレスリリース形式でプロジェクトを説明
- `.aidlc/cycles/{{CYCLE}}/requirements/prfaq.md` を作成（テンプレート: `skills/aidlc/templates/prfaq_template.md`）

---
