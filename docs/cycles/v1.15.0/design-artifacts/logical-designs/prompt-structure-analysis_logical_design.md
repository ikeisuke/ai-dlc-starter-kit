# 論理設計: Skills化方針策定

## 概要

ドメインモデル（プロンプト構造分析）に基づき、各フェーズプロンプトをKiroCLI Skills形式で提供するための整理方針を策定する。アプローチBを採用し、共通部分の抽出を行った上でSkill化を実施する。

## パスの基準

| 区分 | パス | 説明 |
|------|------|------|
| **正本（Source of Truth）** | `prompts/package/prompts/` | プロンプトの原本。編集はここで行う |
| **展開先（デプロイコピー）** | `docs/aidlc/prompts/` | `rsync` で正本から同期されるコピー。直接編集禁止 |

本ドキュメントのファイルパスは、特に断りがない限り正本（`prompts/package/prompts/`）を基準とする。フェーズプロンプト内のテキスト内参照（バックトラック案内等）は展開先パス（`docs/aidlc/prompts/`）を使用している。

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

**Unit 005での方針**: Lite版は現行の独立ファイル構造を維持する（変更なし）

- 既存のFull版読み込み + 差分適用パターンをそのまま維持
- lite/ ディレクトリの3ファイルは変更しない
- Unit 005のスコープはcommon/抽出とAGENTS.md分離に限定

**次サイクル以降（Skills化時）の検討事項**:
- Lite版のインライン化（Full版末尾に統合）を検討
- または独立Skillとして `inception-lite/SKILL.md` 等を作成
- Skills化サイクルの設計フェーズで最終判断

## ファイル単位変更リスト

### 新規作成するファイル

| ファイル | 責務 | 推定行数 |
|---------|------|---------|
| `common/agents-rules.md` | AGENTS.mdから抽出したエージェント対話運用ルール（実行前検証、質問ルール、禁止事項、コンテキスト保持） | 約80行 |
| `common/feedback.md` | フィードバック送信機能 | 約60行 |
| `common/ai-tools.md` | AIツール対応情報（Skills、KiroCLI） | 約60行 |
| `common/project-info.md` | プロジェクト情報テンプレート（概要、スタック、ディレクトリ、制約、テンプレート参照） | 約25行 |
| `common/phase-responsibilities.md` | フェーズの責務定義と責務分離ルール | 約15行 |
| `common/progress-management.md` | 進捗管理と冪等性のルール | 約10行 |
| `common/context-reset.md` | コンテキストリセット対応の共通テンプレート | 約30行 |
| `common/compaction.md` | コンパクション時の対応手順 | 約15行 |

### 新規ファイルのインターフェース定義

各新規 `common/*.md` のI/F契約:

| ファイル | 必須セクション | 許可プレースホルダー | 呼び出し文言 | 禁止事項 |
|---------|-------------|-------------------|------------|---------|
| `agents-rules.md` | 実行前の検証、質問と深掘り、禁止事項、コンテキスト要約時の情報保持 | なし | `common/agents-rules.md を読み込んで` | フェーズ固有ロジックの混入禁止 |
| `feedback.md` | 設定確認、手順、注意事項 | なし | `common/feedback.md を読み込んで` | フェーズ固有ロジックの混入禁止 |
| `ai-tools.md` | レビュースキル、ワークフロースキル、KiroCLI対応 | なし | `common/ai-tools.md を読み込んで` | フェーズ固有ロジックの混入禁止 |
| `project-info.md` | プロジェクト概要、技術スタック、ディレクトリ構成、制約事項、テンプレート参照 | `{{CYCLE}}` | `common/project-info.md を読み込んで` | フェーズ固有の制約の混入禁止 |
| `phase-responsibilities.md` | フェーズの責務、フェーズの責務分離 | なし | `common/phase-responsibilities.md を読み込んで` | 個別フェーズの詳細手順の混入禁止 |
| `progress-management.md` | 進捗管理と冪等性 | なし | `common/progress-management.md を読み込んで` | フェーズ固有の進捗項目の混入禁止 |
| `context-reset.md` | コンテキストリセット対応テンプレート | `{{PHASE}}`, `{{CYCLE}}` | `common/context-reset.md を読み込んで` | 継続プロンプトのフェーズ固有部分は呼び出し元で補完 |
| `compaction.md` | コンパクション時の対応手順 | `{{PHASE}}`, `{{CYCLE}}` | `common/compaction.md を読み込んで` | プロンプト再読み込みパスは呼び出し元で指定 |

### `common/rules.md` と `common/agents-rules.md` の責務境界

| 項目 | `common/rules.md` | `common/agents-rules.md` |
|------|-------------------|-------------------------|
| **責務領域** | 開発実務ルール | エージェント対話運用ルール |
| **対象** | コード・ドキュメント作成時の手順 | AIとユーザーの対話・意思決定プロセス |
| **内容例** | 設定読み込み方法、承認プロセス、コミットタイミング、Co-Authored-By、jjサポート | 実行前検証、質問と深掘りテクニック、禁止事項、コンテキスト要約保持 |
| **読み込み元** | フェーズプロンプト（直接） | AGENTS.md（間接）→ フェーズプロンプト |

**優先順位**: 両ファイルに重複する記述がある場合、`common/rules.md`（開発実務）が優先。`common/agents-rules.md` は対話運用に特化し、開発実務ルールを含めない。

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
| `common/rules.md` | 既に適切に分離済み（agents-rules.mdとの責務境界は上記参照） |
| `common/review-flow.md` | 既に適切に分離済み |
| `setup.md` | リダイレクトのみ。変更不要 |
| `lite/inception.md` | SP-4方針により変更なし |
| `lite/construction.md` | SP-4方針により変更なし |
| `lite/operations.md` | SP-4方針により変更なし |

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
- Lite版の扱い（インライン化 or 独立Skill）を最終判断

### 段階4の想定ディレクトリ構造

```text
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

## To-Be依存マトリクス（段階3完了後）

### 新規common/ファイルを含む依存構造

```mermaid
graph TD
    subgraph エントリポイント
        AGENTS[AGENTS.md<br/>スリム化]
    end

    subgraph 共通モジュール（既存）
        INTRO[common/intro.md]
        RULES[common/rules.md]
        REVIEW[common/review-flow.md]
    end

    subgraph 共通モジュール（新規）
        AG_RULES[common/agents-rules.md]
        FEEDBACK[common/feedback.md]
        AI_TOOLS[common/ai-tools.md]
        PROJ_INFO[common/project-info.md]
        PHASE_RESP[common/phase-responsibilities.md]
        PROGRESS[common/progress-management.md]
        CTX_RESET[common/context-reset.md]
        COMPACT[common/compaction.md]
    end

    subgraph フェーズプロンプト
        INCEPTION[inception.md]
        CONSTRUCTION[construction.md]
        OPERATIONS[operations.md]
    end

    AGENTS -->|参照| AG_RULES
    AGENTS -->|参照| FEEDBACK
    AGENTS -->|参照| AI_TOOLS
    AGENTS -->|ナビゲーション| INCEPTION
    AGENTS -->|ナビゲーション| CONSTRUCTION
    AGENTS -->|ナビゲーション| OPERATIONS

    INCEPTION -->|読み込み| INTRO
    INCEPTION -->|読み込み| RULES
    INCEPTION -->|読み込み| PROJ_INFO
    INCEPTION -->|読み込み| PHASE_RESP
    INCEPTION -->|読み込み| PROGRESS
    INCEPTION -->|読み込み| COMPACT
    INCEPTION -->|読み込み| REVIEW

    %% ctx-reset は inception では不要（SP-2参照）

    CONSTRUCTION -->|読み込み| INTRO
    CONSTRUCTION -->|読み込み| RULES
    CONSTRUCTION -->|読み込み| PROJ_INFO
    CONSTRUCTION -->|読み込み| PHASE_RESP
    CONSTRUCTION -->|読み込み| PROGRESS
    CONSTRUCTION -->|読み込み| CTX_RESET
    CONSTRUCTION -->|読み込み| COMPACT
    CONSTRUCTION -->|読み込み| REVIEW

    OPERATIONS -->|読み込み| INTRO
    OPERATIONS -->|読み込み| RULES
    OPERATIONS -->|読み込み| PROJ_INFO
    OPERATIONS -->|読み込み| PHASE_RESP
    OPERATIONS -->|読み込み| PROGRESS
    OPERATIONS -->|読み込み| CTX_RESET
    OPERATIONS -->|読み込み| COMPACT
    OPERATIONS -->|読み込み| REVIEW
```

### To-Be依存マトリクス表

| 依存元 ＼ 依存先 | AGENTS | 既存common/* | 新規common/* | フェーズ | Lite/* |
|:-:|:-:|:-:|:-:|:-:|:-:|
| **AGENTS** | - | - | Ref(agents-rules, feedback, ai-tools) | Nav | - |
| **既存common/*** | - | - | - | - | - |
| **新規common/*** | - | - | - | - | - |
| **inception** | - | Read(intro, rules, review) | Read(project-info, phase-resp, progress, compact) | - | - |
| **construction** | - | Read(intro, rules, review) | Read(project-info, phase-resp, progress, ctx-reset, compact) | - | - |
| **operations** | - | Read(intro, rules, review) | Read(project-info, phase-resp, progress, ctx-reset, compact) | - | - |
| **Lite/*** | - | - | - | Read(対応Full版) | - |

**注**: `ctx-reset`（コンテキストリセット対応）は `construction` と `operations` のみ。`inception` は対象外（SP-2参照）。

### 各段階での循環依存チェック

| 段階 | 変更内容 | 循環依存リスク | 判定 |
|------|---------|-------------|------|
| 段階1 | common/新規ファイル作成 | なし（新規ファイルは他に依存しない） | OK |
| 段階2 | フェーズプロンプト → common/読み込み追加 | なし（フェーズ → common方向のみ） | OK |
| 段階3 | AGENTS.md → common/参照追加 | なし（AGENTS → common方向のみ） | OK |
| 段階4 | Skills化（ラッパー追加） | なし（Skill → プロンプト方向のみ） | OK |

**結果: 全段階で循環依存なし**。依存は常に上位 → 下位の単方向を維持。

## Lite版整合性方針

### 現行のLite版パターン

```text
Lite版 → Full版を読み込み → 差分を適用
```

### Unit 005での方針（確定）

**Lite版は変更しない**。現行の独立ファイル構造を維持する。

理由:
- Unit 005のスコープはcommon/抽出とAGENTS.md分離に限定
- Lite版はFull版を読み込む構造のため、Full版の内部構造変更（common/への分割）はLite版に影響しない
- Lite版のインライン化は追加リスクを伴うため、別スコープとして扱う

### 次サイクル以降（Skills化時）の検討事項

Skills化サイクルの設計フェーズで以下を最終判断:

1. Lite版をFull版末尾にインライン化するか
2. 独立Skillとして `inception-lite/SKILL.md` 等を作成するか
3. Skillパラメータ（`mode=lite`）で切り替えるか

## 完了条件チェックリスト

| # | 条件 | 状態 | エビデンス |
|---|------|------|-----------|
| 1 | Skills化に必要な分離ポイントの特定 | 完了 | [分離ポイント一覧](#分離ポイント一覧): SP-1〜SP-4 |
| 2 | 各ファイルに対する具体的な変更内容 | 完了 | [ファイル単位変更リスト](#ファイル単位変更リスト): 新規8ファイル、変更4ファイル、変更なし8ファイル |
| 3 | 新規ファイルのI/F定義 | 完了 | [新規ファイルのインターフェース定義](#新規ファイルのインターフェース定義): 8ファイル分のI/F契約 |
| 4 | マイグレーションルール | 完了 | [マイグレーションルール](#マイグレーションルール): 4段階の移行計画 |
| 5 | To-Be依存マトリクス | 完了 | [To-Be依存マトリクス（段階3完了後）](#to-be依存マトリクス段階3完了後): Mermaid図 + マトリクス表 |
| 6 | 各段階での循環依存チェック | 完了 | [各段階での循環依存チェック](#各段階での循環依存チェック): 全段階OK |
| 7 | Lite版整合性方針 | 完了 | [Lite版整合性方針](#lite版整合性方針): Unit 005で変更なし（確定） |
| 8 | パスの基準明示 | 完了 | [パスの基準](#パスの基準): 正本 vs 展開先 |

**承認**: ユーザー承認済み（2026-02-15、設計レビュー時）

## 不明点と質問

（方針策定段階では不明点なし。）
