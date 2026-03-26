# Unit 013 実装計画: フェーズ間連携

## 概要

セットアップで決めた内容をインセプションに引き継ぐ仕組みを実装する。重複質問を回避し、スムーズなフェーズ移行を実現する。

## 関連情報

- **Unit定義**: `docs/cycles/v1.8.0/story-artifacts/units/013-phase-handoff.md`
- **関連Issue**: #37

## 完了条件チェックリスト

Unit定義から抽出した完了条件：

- [x] セットアップで決めたIntent/スコープの保存機能が追加されている
- [x] インセプション開始時の読み込みと確認機能が追加されている
- [x] 重複質問が回避される仕組みが実装されている
- [x] setup.md が更新されている
- [x] inception.md が更新されている
- [x] setup-context.md テンプレートが作成されている
- [x] AIレビューを通過している

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/setup.md` | サイクル作成完了時に setup-context.md を生成するフロー追加 |
| `prompts/package/prompts/inception.md` | 開始時に setup-context.md を読み込むフロー追加 |
| `prompts/package/templates/setup_context_template.md` | setup-context.md のテンプレート新規作成 |

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

このUnitはプロンプト修正が主のため、簡易なドメインモデルを作成。

**成果物**: `docs/cycles/v1.8.0/design-artifacts/domain-models/phase-handoff_domain_model.md`

**主要概念**:

- **SetupContext**: セットアップで決定した情報を保持するドキュメント
- **DecisionItem**: 決定事項（サイクル名、対象Issue、スコープ概要等）
- **ConfirmedQuestion**: 確認済みの質問と回答のペア

#### ステップ2: 論理設計

**成果物**: `docs/cycles/v1.8.0/design-artifacts/logical-designs/phase-handoff_logical_design.md`

**設計内容**:

1. setup-context.md の構造定義
2. setup.md への保存フロー追加箇所
3. inception.md への読み込みフロー追加箇所

### Phase 2: 実装

#### 変更箇所1: setup.md - setup-context.md 生成フロー追加

**場所**: サイクルディレクトリ作成完了後

**追加内容**: setup-context.md を requirements/ に生成するステップ

#### 変更箇所2: inception.md - setup-context.md 読み込みフロー追加

**場所**: 「最初に必ず実行すること」セクション

**追加内容**:

1. setup-context.md の存在確認
2. 存在する場合は内容を読み込み、決定事項を「確認済み」として扱う
3. 追加要件がある場合のみ質問

#### 成果物3: setup-context.md テンプレート作成

**パス**: `prompts/package/templates/setup_context_template.md`

**内容**:

```markdown
# セットアップコンテキスト

## 決定事項

- **サイクル名**: {{CYCLE}}
- **対象Issue**: （Issue番号一覧）
- **スコープ概要**: （スコープの要約）

## 確認済み質問

（セットアップ中にユーザーに確認した質問と回答）

- Q: [質問1]
- A: [回答1]

## インセプションへの引継ぎ事項

- 追加で確認が必要な事項があればここに記載
```

## リスク・考慮事項

- 既存プロジェクトでsetup-context.mdが存在しない場合の後方互換性を考慮
- インセプションでsetup-context.mdが見つからない場合は従来通りの質問フローを実行

## 見積もり

- 設計: 1時間
- 実装: 1時間
- レビュー・修正: 30分
