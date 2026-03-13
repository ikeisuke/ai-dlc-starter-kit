# マルチプラットフォーム対応調査

**調査日**: 2026-03-13
**調査者**: @claude
**関連Issue**: #281
**関連Unit**: Unit 006（マルチプラットフォーム対応調査）

---

## 1. 調査概要

### 目的

AI-DLCスターターキットの各AIエージェントにおける対応状況を体系的に調査し、ギャップと優先対応方針を明確化する。

### 調査範囲

**対象エージェント**: Claude Code, KiroCLI, Codex CLI, Gemini CLI, Cursor, Cline, Windsurf

**対象機能**:
- 設定ファイル（プロジェクトレベルの指示注入）
- スキル連携（スキルファイルの読み込み）
- コミット属性（AI著者情報の付与）
- レビュー（AIレビューツールとしての利用）
- サブエージェント（並行タスク実行）
- Plan Mode（計画モード）

### 評価基準

| 判定 | 定義 | 証跡要件 |
|------|------|---------|
| 対応 | AI-DLCの当該機能が動作する仕組みがエージェント側に存在する | プロジェクト内の設定ファイル・スクリプトで確認可能、または公式ドキュメントに記載 |
| 部分対応 | 機能の一部が動作する、または代替手段で実現可能 | 制約内容と代替手段を具体的に記述 |
| 未対応 | 該当機能を実現する仕組みがエージェント側に存在しない | 公式ドキュメントまたはプロジェクト内コードで未確認であることを記述 |

### 調査ソース

1. `docs/cycles/v1.21.0/requirements/existing_analysis.md`（最優先）
2. `docs/aidlc/guides/ai-agent-allowlist.md`
3. `docs/cycles/v1.18.0/requirements/amazon-aidlc-report.md`
4. プロジェクト内設定ファイル・スクリプト

---

## 2. 対応状況マトリクス

| 機能 | Claude Code | KiroCLI | Codex CLI | Gemini CLI | Cursor | Cline | Windsurf |
|------|:-----------:|:-------:|:---------:|:----------:|:------:|:-----:|:--------:|
| 設定ファイル | 対応 | 対応 | 部分対応 | 部分対応 | 部分対応 | 部分対応 | 部分対応 |
| スキル連携 | 対応 | 対応 | 未対応 | 未対応 | 未対応 | 未対応 | 未対応 |
| コミット属性 | 対応 | 対応 | 対応 | 未対応 | 部分対応 | 部分対応 | 部分対応 |
| レビュー | 対応 | 対応 | 対応 | 対応 | 未対応 | 未対応 | 未対応 |
| サブエージェント | 対応 | 未対応 | 未対応 | 未対応 | 未対応 | 未対応 | 未対応 |
| Plan Mode | 対応 | 未対応 | 未対応 | 未対応 | 未対応 | 未対応 | 未対応 |

### エージェント別詳細

#### Claude Code

AI-DLCの主要ターゲット。全機能が対応済み。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 対応 | `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json` |
| スキル連携 | 対応 | `.claude/skills/` ディレクトリ、SKILL.md自動認識 |
| コミット属性 | 対応 | `commit-flow.md` のCo-Authored-By自動検出 |
| レビュー | 対応 | `review-flow.md` の外部CLIレビュー + セルフレビュー |
| サブエージェント | 対応 | Task Tool（TaskCreate/TaskUpdate）による委任 |
| Plan Mode | 対応 | EnterPlanMode/ExitPlanMode機能 |

#### KiroCLI

2番目に充実した対応。スキル連携まで対応。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 対応 | `.kiro/agents/aidlc.json` によるエージェント設定 |
| スキル連携 | 対応 | `.kiro/skills/` ディレクトリ、シンボリックリンク |
| コミット属性 | 対応 | `commit-flow.md` の自動検出対応 |
| レビュー | 対応 | 外部CLIとしてのレビュー実行 |
| サブエージェント | 未対応 | 公式ドキュメント・プロジェクト内設定にTask Tool相当の機能記載なし |
| Plan Mode | 未対応 | 公式ドキュメント・プロジェクト内設定にPlan Mode相当の機能記載なし |

#### Codex CLI

外部レビューツールとして活用。エージェントホストとしての利用も可能。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 部分対応 | `~/.codex/rules/*.rules` でプロンプトルール注入可能。プロジェクトレベルの `AGENTS.md` も読み込み対応 |
| スキル連携 | 未対応 | Codex CLI公式ドキュメントにスキルファイル読み込み機能の記載なし |
| コミット属性 | 対応 | `commit-flow.md` の自動検出対応 |
| レビュー | 対応 | `codex exec` でAIレビュー実行、`review-flow.md` の優先ツール |
| サブエージェント | 未対応 | Codex CLI公式ドキュメントにサブタスク委任機能の記載なし |
| Plan Mode | 未対応 | Codex CLI公式ドキュメントに計画モード機能の記載なし |

#### Gemini CLI

外部レビューツールとして利用可能。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 部分対応 | `AGENTS.md` 読み込み対応。専用設定ファイルなし |
| スキル連携 | 未対応 | Gemini CLI公式ドキュメントにスキルファイル読み込み機能の記載なし |
| コミット属性 | 未対応 | Gemini CLI公式ドキュメント・`commit-flow.md` に自動検出設定の記載なし |
| レビュー | 対応 | `gemini -p` でAIレビュー実行 |
| サブエージェント | 未対応 | Gemini CLI公式ドキュメントにサブタスク委任機能の記載なし |
| Plan Mode | 未対応 | Gemini CLI公式ドキュメントに計画モード機能の記載なし |

#### Cursor

IDE統合型。専用設定ファイル未整備。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 部分対応 | `.cursorrules` 対応可能だがプロジェクト内未作成。AGENTS.md読み込み対応 |
| スキル連携 | 未対応 | Cursor公式ドキュメントにスキルファイル読み込み機能の記載なし |
| コミット属性 | 部分対応 | 環境変数による検出（`commit-flow.md`） |
| レビュー | 未対応 | IDE統合型のためCLIとしての外部レビュー実行不可 |
| サブエージェント | 未対応 | Cursor公式ドキュメントにサブタスク委任機能の記載なし |
| Plan Mode | 未対応 | Cursor公式ドキュメントに計画モード機能の記載なし |

#### Cline

VSCode拡張。設定反映に問題あり。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 部分対応 | `.clinerules` 対応可能だがプロジェクト内未作成。設定反映に問題報告あり（`ai-agent-allowlist.md`） |
| スキル連携 | 未対応 | Cline公式ドキュメントにスキルファイル読み込み機能の記載なし |
| コミット属性 | 部分対応 | 環境変数による検出（`commit-flow.md`） |
| レビュー | 未対応 | VSCode拡張のためCLIとしての外部レビュー実行不可 |
| サブエージェント | 未対応 | Cline公式ドキュメントにサブタスク委任機能の記載なし |
| Plan Mode | 未対応 | Cline公式ドキュメントに計画モード機能の記載なし |

#### Windsurf

最小限の対応。

| 機能 | 判定 | 証跡 |
|------|------|------|
| 設定ファイル | 部分対応 | `.windsurfrules` 対応可能だがプロジェクト内未作成 |
| スキル連携 | 未対応 | Windsurf公式ドキュメントにスキルファイル読み込み機能の記載なし |
| コミット属性 | 部分対応 | 環境変数による検出（`commit-flow.md`） |
| レビュー | 未対応 | IDE統合型のためCLIとしての外部レビュー実行不可 |
| サブエージェント | 未対応 | Windsurf公式ドキュメントにサブタスク委任機能の記載なし |
| Plan Mode | 未対応 | Windsurf公式ドキュメントに計画モード機能の記載なし |

---

## 3. ギャップ分析

### 3.1 機能カバレッジ

| エージェント | 対応 | 部分対応 | 未対応 | カバレッジ |
|------------|:----:|:-------:|:-----:|:---------:|
| Claude Code | 6 | 0 | 0 | 100% |
| KiroCLI | 4 | 0 | 2 | 67% |
| Codex CLI | 2 | 1 | 3 | 42% |
| Gemini CLI | 1 | 1 | 4 | 25% |
| Cursor | 0 | 2 | 4 | 17% |
| Cline | 0 | 2 | 4 | 17% |
| Windsurf | 0 | 2 | 4 | 17% |

### 3.2 機能別ギャップ

#### 設定ファイル（全エージェント何らかの対応あり）

**ギャップ**: Codex CLI, Gemini CLI, Cursor, Cline, Windsurfは専用設定ファイルがプロジェクト内に未作成。

**代替手段**:
- `AGENTS.md` がCodex CLI, Gemini CLI, Cursorで読み込み可能（共通プロンプトとして機能）
- `.cursorrules`, `.clinerules`, `.windsurfrules` を作成すれば個別対応可能

**影響度**: 中。`AGENTS.md` で基本的な指示注入は可能だが、エージェント固有の設定（許可リスト等）は未対応。

#### スキル連携（Claude Code, KiroCLIのみ対応）

**ギャップ**: 5エージェントがスキルファイル読み込みメカニズムを持たない。

**代替手段**: なし。スキル連携はClaude Code/KiroCLI固有の機能。

**影響度**: 高。AI-DLCのレビュースキル、セットアップスキル等が利用不可。ただし、レビュー機能は外部CLIとして利用可能なエージェントもある。

#### コミット属性（Gemini CLI未対応）

**ギャップ**: Gemini CLIのみ自動検出・設定メカニズムなし。Cursor/Cline/Windsurfは環境変数検出で部分対応。

**代替手段**: `git commit` 時に手動で `--trailer` を追加。

**影響度**: 低。コミット属性は補助的機能であり、未対応でもワークフローに影響なし。

#### サブエージェント・Plan Mode（Claude Code専用）

**ギャップ**: Claude Code以外のエージェントに同等機能なし。

**代替手段**: なし。プロンプト内の該当機能参照は他エージェントでは無視される。

**影響度**: 中。プロンプト内にTask Tool/Plan Mode参照があっても無害（無視される）だが、AI-DLCの効率的な運用には影響。

---

## 4. Claude Code固有表現の使用箇所一覧

**注記**: 以下は `prompts/package/` 配下の全ファイルを対象に検索した結果。主要な使用箇所を列挙する（同一ファイル内の複数出現は1行にまとめる）。

### カテゴリ別一覧

#### ツール名参照

| 表現 | 主要使用ファイル（`prompts/package/` 配下） | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `Writeツール` | `prompts/common/commit-flow.md`, `common/review-flow.md`, `common/rules.md`, `construction.md`, `CLAUDE.md`, `common/feedback.md`, `inception.md`, `operations-release.md`, `skills/aidlc-setup/SKILL.md`, `skills/squash-unit/SKILL.md` | 10 | 読み替え必要 |
| `Readツール` | `guides/ai-agent-allowlist.md`, `guides/backlog-management.md`, `guides/ios-version-update.md`, `prompts/inception.md`, `prompts/operations.md`, `prompts/operations-release.md` | 6 | 読み替え必要 |
| `Bashツール` | `skills/squash-unit/SKILL.md`, `prompts/common/rules.md` | 2 | 読み替え必要 |
| `Grepツール` / `Globツール` / `Editツール` | `prompts/common/rules.md` 内のツール説明 | 1 | 読み替え必要 |

#### 質問・対話機能

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `AskUserQuestion` | `prompts/CLAUDE.md`, `prompts/inception.md` | 2 | Claude Code専用 |

#### タスク管理機能

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `TaskCreate` / `TaskUpdate` / `TaskList` / `TaskGet` | 現行プロンプト内では未使用（共有プロンプトは「タスク管理機能を活用してください」の汎用表現を採用） | 0 | Claude Code専用（ツール自体は） |
| `TodoWrite` | `prompts/CLAUDE.md` | 1 | Claude Code専用 |

#### 計画モード

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `EnterPlanMode` / `ExitPlanMode` / `Plan Mode` | `guides/plan-mode.md` | 1 | Claude Code専用 |

#### ディレクトリ・設定参照

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `.claude/skills/` | `bin/setup-ai-tools.sh`, `guides/skill-usage-guide.md`, `guides/jj-migration.md` | 3 | 読み替え必要 |
| `.claude/settings.json` / `.claude/settings.local.json` | `guides/ai-agent-allowlist.md` | 1 | Claude Code専用 |
| `CLAUDE.md` | `prompts/CLAUDE.md`（ファイル自体がClaude Code固有） | 1 | 読み替え必要 |

#### スキル実行

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `Skill(reviewing-*)` | `guides/ai-agent-allowlist.md` | 1 | Claude Code専用 |
| `/skill-name` 形式 | `prompts/common/commit-flow.md`, `prompts/operations.md` | 2 | Claude Code専用 |

#### その他

| 表現 | 主要使用ファイル | 出現ファイル数 | 移植性 |
|------|-----------|:---:|--------|
| `$()` 禁止ルール | `prompts/common/rules.md` | 1 | Claude Code専用（他エージェントでは無関係だが無害） |
| `Bash(command:*)` パーミッション | `guides/ai-agent-allowlist.md` | 1 | Claude Code専用 |

### 移植性サマリ

| 移植性 | 表現数 | 説明 |
|--------|:------:|------|
| 他エージェントでも解釈可能 | 0 | なし |
| 読み替え必要 | 7 | ツール名（Writeツール等）、ディレクトリパス（.claude/skills/）等。他エージェントで対応する概念に読み替え |
| Claude Code専用 | 10 | AskUserQuestion, TodoWrite, Plan Mode, Skill(), パーミッション等。他エージェントに同等機能なし |

---

## 5. 次期サイクルへの優先対応提案

### 高優先度

#### 提案1: 共有プロンプトからClaude Code固有ツール名を抽象化

- **優先度**: 高
- **理由**: `Writeツール`/`Readツール`等のツール名参照が共有プロンプト（`rules.md`, `commit-flow.md`）内に存在し、他エージェントでの解釈に支障。6エージェントに影響
- **影響エージェント**: KiroCLI, Codex CLI, Gemini CLI, Cursor, Cline, Windsurf
- **概算規模**: 中規模（共有プロンプトの書き換え + エージェント別の補足ドキュメント作成）
- **対応方針**: ツール名を汎用表現に置き換えるか、エージェント判定による動的切り替えを導入

#### 提案2: 主要エージェント向け設定ファイルの作成

- **優先度**: 高
- **理由**: `.cursorrules`, `.clinerules` 等がプロジェクト内に未作成。ユーザーが対応エージェントを使う場合に初期設定の手間が大きい。3エージェント（Cursor, Cline, Windsurf）に影響
- **影響エージェント**: Cursor, Cline, Windsurf
- **概算規模**: 小規模（`AGENTS.md` の内容を各設定ファイル形式に変換）
- **対応方針**: `setup-ai-tools.sh` で各エージェント向け設定ファイルを自動生成

### 中優先度

#### 提案3: AskUserQuestion のフォールバック機構

- **優先度**: 中
- **理由**: プロンプト内の `AskUserQuestion` 指示は他エージェントで解釈されない。Claude Code以外の全6エージェントに影響（CLI系・IDE系問わず、同名ツールは存在しない）
- **影響エージェント**: KiroCLI, Codex CLI, Gemini CLI, Cursor, Cline, Windsurf
- **概算規模**: 中規模（プロンプトの条件分岐 or 抽象化）
- **対応方針**: 「選択肢がある場合はユーザーに提示する」の汎用指示に置き換え、Claude Code向けには `CLAUDE.md` で具体的なツール名を指定

#### 提案4: Task Tool のフォールバック機構

- **優先度**: 中
- **理由**: タスク管理指示が他エージェントで無視される。進捗管理の可視化が機能しない
- **影響エージェント**: 全エージェント（Claude Code以外）
- **概算規模**: 小規模（汎用的な進捗管理指示に置き換え）
- **対応方針**: 「進捗を可視化する」の汎用指示に置き換え、Claude Code向けにはTask Tool具体指示を `CLAUDE.md` に集約

### 低優先度

#### 提案5: Amazon AI-DLCのマルチプラットフォーム設計パターンの参考適用

- **優先度**: 低
- **理由**: Amazon AI-DLC（awslabs/aidlc-workflows）は6プラットフォーム対応設計。設計パターンを参考にすることでマルチプラットフォーム対応の効率化が可能
- **影響エージェント**: 全エージェント
- **概算規模**: 大規模（プロンプト構造の再設計）
- **対応方針**: Amazon方式の「1ファイル + @include」パターンと現在の「多ファイル分割」パターンの利点を分析し、段階的に適用

#### 提案6: Plan Mode / サブエージェントの汎用化検討

- **優先度**: 低
- **理由**: Claude Code専用機能であり、他エージェントに同等機能がない。現時点では代替手段もないため、対応は将来のエージェント機能拡充を待つ
- **影響エージェント**: 全エージェント（Claude Code以外）
- **概算規模**: 小規模（ドキュメント整理のみ）
- **対応方針**: Plan Mode / サブエージェント関連の指示を `CLAUDE.md` に集約し、共有プロンプトから分離

---

## 6. 参考情報

### 調査ソース一覧

| ソース | パス | 用途 |
|--------|------|------|
| 既存コードベース分析 | `docs/cycles/v1.21.0/requirements/existing_analysis.md` | v1.21.0時点の対応状況 |
| AIエージェント許可リスト | `docs/aidlc/guides/ai-agent-allowlist.md` | エージェント別設定方法 |
| Amazon AI-DLCレポート | `docs/cycles/v1.18.0/requirements/amazon-aidlc-report.md` | プラットフォーム比較 |
| プロジェクト内コード | `prompts/package/` | Claude Code固有表現の実調査 |
