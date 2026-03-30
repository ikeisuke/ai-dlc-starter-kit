# 論理設計: エクスプレスモード再設計

## 概要
エクスプレスモード再設計に伴うプロンプトファイルおよびテンプレートファイルの変更箇所を詳細に定義する。

**重要**: この論理設計では**コードは書かず**、変更仕様の定義のみを行います。

## アーキテクチャパターン
プロンプト駆動アーキテクチャ。正本（rules.md）に仕様を定義し、各フェーズプロンプト（inception.md, construction.md）が参照する。

## コンポーネント構成

```text
prompts/package/
├── prompts/
│   ├── common/
│   │   └── rules.md              # エクスプレスモード仕様（正本）【主要変更】
│   ├── inception.md               # ステップ14b, 4b, 完了処理【主要変更】
│   ├── construction.md            # エクスプレスモード検出【主要変更】
│   ├── CLAUDE.md                  # start express 説明【軽微変更】
│   └── AGENTS.md                  # start express 説明【軽微変更】
└── templates/
    └── unit_definition_template.md  # 適格性判定結果フィールド追加【軽微変更】
```

## 変更仕様: rules.md

### セクション: エクスプレスモード仕様（258行目〜）

**変更1: 冒頭定義の書き換え**
- 変更前: 「`depth_level=minimal` 時に適用条件を満たす場合、Inception Phase と Construction Phase を1つの連続フローで実行する高速パス。」
- 変更後: 「`start express` コマンドで有効化されるフェーズ連続実行モード。depth_level に依存せず、Unit の複雑度判定に基づいて適用可否を決定する。」

**変更2: depth_level 解決優先順位サブセクション**
- 変更前: コマンドオーバーライドで `depth_level=minimal` をセット
- 変更後: コマンドオーバーライドで `express_enabled=true` をセット（depth_level は変更しない）
- 新メッセージ:
  ```text
  【エクスプレスモード】「start express」コマンドによりフェーズ連続実行モードを有効化しました
  ```
- コンテキスト変数: `express_enabled=true`, `express_source=command`

**変更3: 適用条件サブセクション**
- 変更前:
  1. `depth_level=minimal` であること
  2. Unit 数がちょうど1であること
- 変更後:
  1. `express_enabled=true` であること
  2. 全 Unit の複雑度判定が `eligible` であること
  3. Unit 数が1以上であること（0は対象外）

**変更4: 複雑度判定ルールサブセクション（新規追加）**

タイトル: `#### 複雑度判定ルール`

以下の判定ルール表を追加:

| 評価項目 | eligible 条件 | ineligible 条件 |
|----------|--------------|----------------|
| 受け入れ基準の明確さ | 全基準が具体的で検証可能。曖昧な表現なし | 曖昧な基準が1つ以上、または基準が未定義 |
| 依存関係の複雑さ | Unit間依存が線形。循環依存・多段分岐なし | 循環依存、3つ以上からの同時依存、外部双方向依存 |
| 技術的リスク | 使用技術が既知。類似実装あり | 未使用技術導入、外部API新規連携、アーキテクチャ変更 |
| 変更影響範囲 | 変更対象が特定可能で限定的 | 影響範囲不明確、横断的変更 |

判定は AI が Unit 定義ファイルの内容に基づいて実施する。全項目が eligible なら `eligible`、1つでも ineligible なら `ineligible`。

**変更5: 判定タイミングサブセクション**
- 変更前: `depth_level` が `standard` / `comprehensive` の場合、判定自体をスキップ
- 変更後: `express_enabled` が `false` の場合、判定自体をスキップ

**変更6: エクスプレスモード有効時の動作サブセクション**
- 追加: 「depth_level に応じた成果物要件はそのまま適用される（エクスプレスモードは成果物要件を変更しない）」
- 変更: 「minimal の既存成果物要件〜」→ 「現在の depth_level の成果物要件がそのまま適用される」

**変更7: フォールバック条件サブセクション**
- 変更前: `depth_level=minimal` の場合のみ表示
- 変更後: `express_enabled=true` の場合のみ表示
- フォールバックメッセージ変更:
  - Unit数0: 「エクスプレスモード適用不可: Unit定義がないため通常フローに切り替えます」（変更なし）
  - 複雑度不適格: 「エクスプレスモード適用不可: [Unit名] が複雑度条件を満たしません（理由: [項目名]）。通常フローに切り替えます」（新規）

**変更8: 既存モードへの非影響保証サブセクション**
- 変更前: `standard` / `comprehensive` では判定が実行されない
- 変更後: `express_enabled=false` では判定が実行されない。`start express` を使用しない限り既存の動作は一切変更されない

**変更9: フェーズプロンプト実装手順サブセクション**
- 変更前: `depth_level=minimal` の場合のみ判定
- 変更後: `express_enabled=true` の場合のみ判定

**変更10: Depth Level 仕様の minimal セクション（187行目付近）**
- 変更前: 「※1: Unit数がちょうど1の場合、エクスプレスモード（後述「エクスプレスモード仕様」セクション参照）を適用可能」
- 変更後: この注釈を削除（エクスプレスモードは depth_level に依存しないため）
- 変更前: 「**フロー制御（minimalのみ）**: エクスプレスモード適用時は〜」
- 変更後: この行を削除（エクスプレスモード仕様セクションに一元化）

## 変更仕様: inception.md

### ステップ14b（エクスプレスモードインスタント検出）

- 変更前: `start express` → `depth_level=minimal`, `depth_level_source=command_override`
- 変更後: `start express` → `express_enabled=true`, `express_source=command`（depth_level は変更しない）
- 一致時のメッセージ: rules.md の変更2の新メッセージを参照

### ステップ4b（エクスプレスモード判定）

- 変更前: スキップ条件 = `depth_level が minimal でない場合`
- 変更後: スキップ条件 = `express_enabled が false の場合`
- 判定内容:
  1. Unit 数カウント（変更なし）
  2. Unit 数0: ineligible（変更なし）
  3. **新規**: 各 Unit に対して複雑度判定を実行
  4. 全 Unit eligible: エクスプレスモード有効
  5. 1つでも ineligible: フォールバック（rules.md の新メッセージを使用）
  6. **削除**: Unit 数2以上のフォールバック（複雑度判定で制御するため不要）

### エクスプレスモード完了処理

- 変更: ステップ5（PRFAQ）の扱い
  - `depth_level=minimal`: ステップ5をスキップ（Depth Level仕様でスキップ可能のため）
  - `depth_level=standard/comprehensive`: ステップ4bの判定後にステップ5（PRFAQ）へ進み、PRFAQ作成完了後にエクスプレスモード完了処理に到達する。完了処理では progress.md で「完了」を確認するのみ

## 変更仕様: construction.md

### エクスプレスモード検出セクション（461行目〜）

- 変更前: `depth_level=minimal` かつ Unit数1 → Phase 1 スキップ
- 変更後: `express_enabled=true` かつ `eligibility_result=eligible` → depth_level に応じた処理
  - `depth_level=minimal`: Phase 1 スキップ（従来通り）
  - `depth_level=standard/comprehensive`: Phase 1 は通常実行（設計省略しない）

**複数Unit時のConstruction開始ルール**:
エクスプレスモードで複数Unitが eligible の場合、Construction Phase の通常の Unit 選定ルール（construction.md ステップ9）がそのまま適用される:
- 依存関係に基づく実行順序で最初の実行可能 Unit から開始
- `automation_mode=semi_auto` の場合、番号順で最初のUnitを自動選択
- Unit 完了後、次の実行可能 Unit に自動遷移（コンテキストリセットなし）
- 全 Unit 完了後に Operations Phase へ遷移（またはコンテキストリセット）

**注**: エクスプレスモードは「Inception→Construction のフェーズ間遷移」のコンテキストリセットをスキップするものであり、Construction Phase 内の Unit 間の遷移は既存の仕組み（construction.md のフロー）がそのまま適用される。

## 変更仕様: CLAUDE.md / AGENTS.md

### フェーズ簡略指示テーブル

- 変更前: `「start express」 | Inception Phase（エクスプレスモード、depth_level=minimalで起動）`
- 変更後: `「start express」 | Inception Phase（エクスプレスモード、フェーズ連続実行を有効化）`

## 適格性判定結果の記録

Unit 定義ファイルの「実装状態」セクションに以下を追加:

```markdown
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: eligible | ineligible | - （判定未実施の場合は -）
- **適格性理由**: （ineligible の場合の理由）
```

## 処理フロー概要

### start express 実行時のフロー

1. ユーザーが `start express` を入力
2. `express_enabled=true` をセット（depth_level は変更しない）
3. Inception Phase を通常通り実行（depth_level に応じた成果物を生成）
4. Unit 定義完了後、ステップ4b でエクスプレスモード判定
5. 各 Unit の複雑度を4項目で評価
6. 全 Unit eligible → エクスプレスモード有効化 → コンテキストリセットスキップ → Construction 自動遷移
7. 1つでも ineligible → フォールバック → 通常フロー

## 非機能要件（NFR）への対応

### 後方互換性
- `start express` を使わない限り、既存の全フローに変更なし
- `depth_level=minimal` + `start express` は従来と同等の動作（成果物簡略化 + フェーズ連続実行）

### `start express` コマンドの非互換変更と移行方針

**非互換変更**: v1.27.2 以前では `start express` が暗黙的に `depth_level=minimal` をセットしていた。v1.27.3 では `start express` は `express_enabled=true` のみをセットし、depth_level は変更しない。

**影響範囲**: `start express` を「depth_level=minimal の簡略指示」として使用していたユーザーは、v1.27.3 以降では設定ファイルの `depth_level` 設定がそのまま適用される（デフォルト: standard）。

**移行方針**: 互換モードや別名コマンドは導入しない。理由:
1. `start express` の本来の意図は「フェーズ連続実行」であり、depth_level の暗黙変更は副作用だった
2. 成果物簡略化が必要な場合は `aidlc.toml` で `depth_level=minimal` を明示設定すれば従来と同等の動作になる
3. コマンド体系の複雑化（互換モード/別名）より、明確な分離の方が長期的に保守しやすい

**周知方法**: inception.md のステップ14b で `start express` 検出時に以下のメッセージを表示:
```text
【エクスプレスモード】「start express」コマンドによりフェーズ連続実行モードを有効化しました
※ depth_level は変更されません。現在の depth_level={current_value} で成果物を生成します
```

## 実装上の注意事項
- `docs/aidlc/` は直接編集禁止。全変更は `prompts/package/` に対して行う
- rules.md の変更はエクスプレスモード仕様セクション内に集約し、他セクションへの散在を避ける
- フォールバックメッセージの正本は rules.md に一元管理（各フェーズプロンプトには重複記述しない）
