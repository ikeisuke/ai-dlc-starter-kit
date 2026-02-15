# 論理設計: Skills化方針策定

## 概要

ドメインモデル（プロンプト構造分析）に基づき、各フェーズプロンプトをKiroCLI Skills形式で提供するための整理方針を策定する。アプローチBを採用し、共通部分の抽出を行った上でSkill化を実施する。

## 分離ポイント一覧

### SP-1: AGENTS.mdの責務分離

**現状**: AGENTS.md（273行）が5つの責務を混在して保持

| 分離対象 | 行範囲(概算) | 移動先 | 理由 |
|---------|------------|--------|------|
| ナビゲーション | 1-70 | AGENTS.mdに残す | エントリポイントとしての本来の責務 |
| 共通ルール（実行前検証、質問、禁止事項） | 73-127 | common/agents-rules.md（新規） | フェーズ非依存の共通ルールであり、Skill単独利用時にも必要 |
| コンテキスト要約時の情報保持 | 128-150 | common/agents-rules.md に統合 | 共通ルールの一部 |
| フィードバック送信 | 154-210 | common/feedback.md（新規） | 独立機能。フェーズから独立して呼び出し可能 |
| AIツール対応（Skills/KiroCLI） | 213-273 | common/ai-tools.md（新規） | ツール設定情報。Skill定義の参照情報 |

### SP-2: フェーズプロンプト内の重複セクション抽出

**現状**: 3つのフェーズプロンプトに同一/類似内容が重複

| 抽出対象 | 重複ファイル | 移動先 | 行数削減見込み |
|---------|-----------|--------|-------------|
| プロジェクト情報（概要、スタック、ディレクトリ、制約） | inception, construction, operations | common/project-info.md（新規） | 各20行 × 3 = 約60行 |
| フェーズの責務/責務分離 | inception, construction, operations | common/phase-responsibilities.md（新規） | 各10行 × 3 = 約30行 |
| 進捗管理と冪等性 | inception, construction, operations | common/progress-management.md（新規） | 各5行 × 3 = 約15行 |
| テンプレート参照 | inception, construction, operations | common/project-info.md に統合 | 各2行 × 3 = 約6行 |
| コンテキストリセット対応 | construction, operations | common/context-reset.md（新規） | 各30行 × 2 = 約60行 |
| コンパクション時の対応 | inception, construction, operations | common/compaction.md（新規） | 各10行 × 3 = 約30行 |

**削減見込み合計**: 約200行（全体の約5%）

### SP-3: フェーズプロンプトの固有部分の明確化

抽出後、各フェーズプロンプトに残る固有部分:

| ファイル | 固有の責務 | 抽出後の推定行数 |
|---------|----------|---------------|
| inception.md | セットアップ手順、Intent明確化、ストーリー作成、Unit定義、PRFAQ | 約790行 |
| construction.md | 初期チェック、Unit選択、設計フロー、実装フロー、Unit完了処理 | 約1000行 |
| operations.md | 運用チェック、デプロイ、CI/CD、監視、配布、リリース、サイクル完了 | 約900行 |

### SP-4: Lite版の扱い

**現状**: Lite版はFull版を前提として差分定義（71-117行）

**方針**: Lite版は別Skillとして独立させず、Full版Skillのパラメータとして扱う

- Skill呼び出し時に `mode=lite` パラメータで切り替え
- Lite版固有の変更点はFull版プロンプト末尾にインライン化
- これにより lite/ ディレクトリの3ファイルを廃止可能

**代替案**（Lite版を独立Skillとして維持）:
- 既存のFull版読み込み + 差分適用パターンを維持
- Skill定義で `dependencies: [inception]` のように参照
- 変更量が少ない分、移行リスクも低い

## ファイル単位変更リスト

### 新規作成するファイル

| ファイル | 責務 | 推定行数 |
|---------|------|---------|
| `common/agents-rules.md` | AGENTS.mdから抽出した共通ルール（実行前検証、質問ルール、禁止事項、コンテキスト保持） | 約80行 |
| `common/feedback.md` | フィードバック送信機能 | 約60行 |
| `common/ai-tools.md` | AIツール対応情報（Skills、KiroCLI） | 約60行 |
| `common/project-info.md` | プロジェクト情報テンプレート（概要、スタック、ディレクトリ、制約、テンプレート参照） | 約25行 |
| `common/phase-responsibilities.md` | フェーズの責務定義と責務分離ルール | 約15行 |
| `common/progress-management.md` | 進捗管理と冪等性のルール | 約10行 |
| `common/context-reset.md` | コンテキストリセット対応の共通テンプレート | 約30行 |
| `common/compaction.md` | コンパクション時の対応手順 | 約15行 |

### 変更するファイル

| ファイル | 変更内容 |
|---------|---------|
| `AGENTS.md` | フィードバック、AIツール対応、共通ルールを外部参照に変更。ナビゲーション部分のみ残す |
| `inception.md` | 重複セクション（プロジェクト情報、責務分離、進捗管理等）をcommon/への読み込み指示に置換 |
| `construction.md` | 同上。加えてコンテキストリセット対応をcommon/への参照に置換 |
| `operations.md` | 同上。加えてコンテキストリセット対応をcommon/への参照に置換 |

### 変更しないファイル

| ファイル | 理由 |
|---------|------|
| `CLAUDE.md` | Claude Code固有設定であり、共通化の対象外 |
| `common/intro.md` | 既に適切に分離済み |
| `common/rules.md` | 既に適切に分離済み |
| `common/review-flow.md` | 既に適切に分離済み |
| `setup.md` | リダイレクトのみ。変更不要 |

### 将来の廃止候補（次サイクル以降で判断）

| ファイル | 理由 |
|---------|------|
| `lite/inception.md` | Lite版インライン化（SP-4）を採用する場合 |
| `lite/construction.md` | 同上 |
| `lite/operations.md` | 同上 |

## マイグレーションルール

### 抽出時の原則

1. **内容の完全一致**: 抽出する内容は現行の内容と完全一致させる。意味を変えない
2. **読み込み指示の追加**: 抽出した箇所には `【次のアクション】今すぐ common/xxx.md を読み込んで` の指示を追加
3. **既存の読み込み順序を維持**: common/intro.md → common/rules.md → 新規common/* → common/review-flow.md
4. **フェーズ固有の変数は維持**: `{{CYCLE}}` 等のプレースホルダーはフェーズプロンプト側で解決

### 移行の段階

#### 段階1: common/ 新規ファイル作成（Unit 005で実施）

- 新規ファイルを作成し、抽出対象の内容を移動
- 変更前後で同一の動作になることを確認

#### 段階2: フェーズプロンプトの重複削除（Unit 005で実施）

- 各フェーズプロンプトから抽出済みセクションを削除
- common/ への読み込み指示に置換

#### 段階3: AGENTS.md の責務分離（Unit 005で実施）

- フィードバック、AIツール対応、共通ルールを外部ファイル化
- AGENTS.md をナビゲーション + 共通ルール参照のスリム化

#### 段階4: Skills化（次サイクル以降）

- 各フェーズプロンプトをSKILL.md形式でラップ
- `prompts/package/skills/` に配置
- KiroCLIからの直接呼び出しを実現

### 段階4の想定ディレクトリ構造

```
prompts/package/skills/
├── inception/
│   └── SKILL.md         # Inception Phase Skill
├── construction/
│   └── SKILL.md         # Construction Phase Skill
├── operations/
│   └── SKILL.md         # Operations Phase Skill
└── (既存のレビュースキル等)
```

各SKILL.mdは:
- フェーズプロンプトを参照（`resources`で読み込み）
- common/* モジュールへの読み込み指示を含む
- Skill固有のメタデータ（name, description, argument-hint等）を定義

## Lite版整合性方針

### 現行のLite版パターン

```
Lite版 → Full版を読み込み → 差分を適用
```

### 整理後のLite版パターン（2案）

#### 案1: インライン化（推奨）

Lite版の差分情報をFull版プロンプトの末尾に統合:

```markdown
## Lite版での変更点【Lite版使用時のみ適用】

以下はLite版（`start lite xxx`）で起動された場合にのみ適用する変更点です。
Full版で起動された場合は無視してください。

### スキップするステップ
...
### 簡略化するステップ
...
```

**メリット**: ファイル数削減、Skill化時にFull/Lite版の切り替えが容易
**デメリット**: Full版プロンプトの行数増加（各70-120行程度）

#### 案2: 独立維持

Lite版を独立ファイルとして維持し、Skills化時にも独立Skillとする:

```
prompts/package/skills/
├── inception/SKILL.md
├── inception-lite/SKILL.md
├── construction/SKILL.md
├── construction-lite/SKILL.md
...
```

**メリット**: 変更量が少ない、既存パターン維持
**デメリット**: ファイル数が増える、Full/Lite間の同期が必要

### 推奨

段階1-3（Unit 005）では**案2（独立維持）**を採用し、段階4（次サイクル、Skills化）で**案1（インライン化）**への移行を検討する。

理由: Unit 005のスコープはリファクタリングであり、Lite版のインライン化は追加リスクを伴う。Skills化の段階で一括して対応する方が安全。

## 不明点と質問

（方針策定段階では不明点なし。レビューで確認予定。）
