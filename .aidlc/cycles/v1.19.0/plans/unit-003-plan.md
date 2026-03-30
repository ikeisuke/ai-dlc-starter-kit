# Unit 003 計画: Depth Levelsフェーズプロンプト反映

## 概要

Unit 002で定義したDepth Level仕様（`rules.md`のSoT）を各フェーズプロンプトに組み込み、成果物詳細度の実際の制御を実装する。

## 前提: SoTの補完（Unit 002成果物への追記）

Unit 002で作成した`rules.md`の成果物要件テーブルにPRFAQの行が欠落している。Unit定義の責務に「minimal設定時: PRFAQ作成スキップ」と明記されているため、本Unitの実装に先立ちSoTを補完する。

**追加する行**（minimalテーブルに追加）:

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | PRFAQ | スキップ可能 |

**standardテーブルに追加**:

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | PRFAQ | 通常通り |

**comprehensiveテーブルに追加**:

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | PRFAQ | 通常通り |

## 設計方針

### SoT参照原則

`rules.md`のDepth Level仕様セクションが唯一の定義源（SoT）であるため、各フェーズプロンプトでは:

- バリデーション仕様・成果物要件テーブルを**重複記述しない**
- `rules.md`の「Depth Level仕様」セクションを**参照**する形で判定ロジックを記述
- 各ステップでの具体的な分岐指示のみ記載（「minimalの場合は○○をスキップ」等）

### 判定ロジックの配置

各プロンプトの初期チェック（「最初に必ず実行すること」）にDepth Level読み込みステップを追加し、以降のステップで参照する。

### 各プロンプトに記述する内容の統一テンプレート

**初期チェックステップ（各プロンプト共通）**:

```text
### X.X Depth Level確認

`common/rules.md` の「Depth Level仕様」セクションに従い、成果物詳細度を確認する。

read-config.sh rules.depth_level.level --default "standard"

取得した値をコンテキスト変数 `depth_level` として保持する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。
```

**各ステップでの分岐指示**:

```text
**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: [このステップ固有の簡略化指示]
- `comprehensive`: [このステップ固有の追加指示]
- `standard`: 変更なし（現行動作）
```

この統一テンプレートにより、バリデーション仕様やレベル定義は`rules.md`に一元化され、各プロンプトにはステップ固有の分岐指示のみが記載される。

## 変更対象ファイル

1. **`prompts/package/prompts/common/rules.md`** - PRFAQの成果物要件行を追加（SoT補完）
2. **`prompts/package/prompts/inception.md`** - Depth Level判定ロジック組み込み
3. **`prompts/package/prompts/construction.md`** - Depth Level判定ロジック組み込み
4. **`prompts/package/prompts/operations.md`** - Depth Level判定ロジック組み込み

## 実装計画

### ステップ0: SoT補完（rules.md）

`rules.md`のレベル別成果物要件テーブル3つにPRFAQ行を追加する。

### ステップ1: inception.md の変更

1. **初期チェック**: ステップ11（環境確認）の後にDepth Level読み込みステップを追加（統一テンプレートに従う）
2. **ステップ1（Intent明確化）**: minimal時の簡潔な記述指示、comprehensive時のリスク分析・代替案検討セクション追加指示
3. **ステップ3（ユーザーストーリー作成）**: minimal時の受け入れ基準簡略化指示、comprehensive時のエッジケース網羅指示
4. **ステップ4（Unit定義）**: minimal時の最小限記述指示、comprehensive時の技術的リスク評価追加指示
5. **ステップ5（PRFAQ作成）**: minimal時のスキップ可能指示（SoTのPRFAQ要件を参照）

### ステップ2: construction.md の変更

1. **初期チェック**: ステップ2.6（セッション判別設定）の後にDepth Level読み込みステップを追加（統一テンプレートに従う）
2. **Phase 1 ステップ1（ドメインモデル設計）**: minimal時のスキップ可能指示（設計省略を明記）、comprehensive時のドメインイベント定義追加指示
3. **Phase 1 ステップ2（論理設計）**: minimal時のスキップ可能指示（設計省略を明記）、comprehensive時のシーケンス図・状態遷移図追加指示
4. **Phase 2 ステップ5（テスト生成）**: comprehensive時の統合テスト強化指示
5. **Unit完了ステップ0.5（設計・実装整合性チェック）**: 設計省略時の整合性チェックスキップ条件を追加。`depth_level=minimal` で設計をスキップした場合、既存のスキップ条件（「『設計省略』と明記されている場合」）に「`depth_level=minimal` でドメインモデル・論理設計がスキップされた場合」を追加する

### ステップ3: operations.md の変更

1. **初期チェック**: ステップ2.6（セッション判別設定）の後にDepth Level読み込みステップを追加（統一テンプレートに従う）
2. **ステップ6（リリース準備）**: comprehensive時のロールバック手順詳細化指示

**operations.mdでステップ6のみが変更対象である理由**: SoTの成果物要件テーブルに基づき、Operations Phaseではcomprehensive時の「ロールバック手順の詳細化」のみがstandard比での差分であるため。ステップ0-5（デプロイ準備、CI/CD構築、監視・ロギング、配布、バックログ整理）はレベルによらず同一の手順を実行する。

## Lite版の除外

Unit定義に明記のとおり、Lite版プロンプト（`prompts/package/prompts/lite/*.md`）は本Unitの対象外。

## 完了条件チェックリスト

- [x] `prompts/package/prompts/common/rules.md` のSoTにPRFAQ成果物要件を追加
- [x] `prompts/package/prompts/inception.md` にDepth Level判定ロジックを組み込み（ステップ1, 3, 4, 5の成果物詳細度調整）
- [x] `prompts/package/prompts/construction.md` にDepth Level判定ロジックを組み込み（Phase 1-2の設計・実装詳細度調整、設計省略時の整合性チェック連携）
- [x] `prompts/package/prompts/operations.md` にDepth Level判定ロジックを組み込み（リリース準備ステップのロールバック手順詳細度調整）
- [x] minimal設定時: PRFAQ作成スキップ、受け入れ基準簡略化（主要エラーケースは維持）
- [x] comprehensive設定時: リスク分析・代替案検討等の追加セクション
