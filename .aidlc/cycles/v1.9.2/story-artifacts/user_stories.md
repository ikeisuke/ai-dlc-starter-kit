# ユーザーストーリー

## Epic: AI-DLC v1.9.2 パッチリリース

v1.8.2マージ漏れ機能の完了と既存機能の改善を行うパッチリリース。

---

### ストーリー 1: プレリリースバージョンでの履歴記録

**優先順位**: Must-have
**関連Issue**: #105

As a AI-DLCを使用する開発者
I want to プレリリースバージョン（v2.0.0-alpha.6等）でwrite-history.shを使用できる
So that アルファ版やベータ版の開発サイクルでも履歴管理ができる

**受け入れ基準**:

| テストケース | コマンド | 期待結果 |
|-------------|---------|---------|
| alpha形式 | `write-history.sh --cycle v2.0.0-alpha.6 --phase inception --step "test" --content "test"` | 終了コード0、履歴ファイル作成 |
| beta形式 | `write-history.sh --cycle v1.0.0-beta.1 --phase inception --step "test" --content "test"` | 終了コード0 |
| rc形式 | `write-history.sh --cycle v1.0.0-rc.1 --phase inception --step "test" --content "test"` | 終了コード0 |
| 既存形式 | `write-history.sh --cycle v1.9.2 --phase inception --step "test" --content "test"` | 終了コード0（後方互換性） |
| 不正形式1 | `write-history.sh --cycle v1.0 ...` | 終了コード1、エラーメッセージ出力 |
| 不正形式2 | `write-history.sh --cycle 1.0.0 ...` | 終了コード1（vプレフィックス必須） |
| ビルドメタ | `write-history.sh --cycle v1.0.0+build.1 ...` | 終了コード1（ビルドメタは非対応） |

**許可する形式**: `vX.Y.Z`, `vX.Y.Z-alpha.N`, `vX.Y.Z-beta.N`, `vX.Y.Z-rc.N`
**不許可**: ビルドメタデータ(`+build`)、プレフィックスなし、不完全なバージョン

**技術的考慮事項**:
- 正規表現: `^v[0-9]+\.[0-9]+\.[0-9]+(-alpha\.[0-9]+|-beta\.[0-9]+|-rc\.[0-9]+)?$`
- セマンティックバージョニング仕様（SemVer 2.0.0）のサブセットに準拠

---

### ストーリー 2: operations.mdのサイズ最適化

**優先順位**: Should-have
**関連Issue**: #108

As a AI-DLCのメンテナー
I want to operations.mdが1000行以下に収まる
So that ファイルの可読性とメンテナンス性が向上する

**受け入れ基準**:

| 検証項目 | 検証方法 | 期待結果 |
|---------|---------|---------|
| 行数 | `wc -l prompts/package/prompts/operations.md` | 1000以下 |
| 必須セクション存在 | 下記チェックリスト参照 | すべて存在 |
| 重要キーワード保持 | 下記キーワードチェック参照 | すべて存在 |

**必須セクションチェックリスト**（削除禁止）:
- [ ] `## 最初に必ず実行すること` セクション
- [ ] `## フロー` セクション
- [ ] `### ステップ1〜6` の各ステップ
- [ ] `## 完了基準` セクション
- [ ] `## 完了時の必須作業` セクション
- [ ] `## 次のステップ` セクション

**重要キーワードチェック**（grepで存在確認）:
- [ ] `CI/CD` - CI/CD設定に関する記述
- [ ] `監視` - 監視設定に関する記述
- [ ] `rsync` - docs/aidlc/同期に関する記述
- [ ] `CHANGELOG` - リリースノート更新に関する記述
- [ ] `git tag` または `version_tag` - タグ付けに関する記述

**削減対象**（簡略化可能）:
- 冗長な説明文
- 重複する注意書き
- 過度に詳細な例示

**技術的考慮事項**:
- 現在1029行 → 目標1000行以下（約30行削減）
- 改行コード: LF（Unix形式）で測定

---

### ストーリー 3: 複数AIサービスのレビュー対応

**優先順位**: Must-have
**関連Issue**: #111

As a 複数のAIツールを使い分ける開発者
I want to aidlc.tomlでAIレビューに使用するサービスの優先順位を設定できる
So that 環境に応じて最適なAIサービスでレビューが実行される

**受け入れ基準**:

| 検証項目 | 検証方法 | 期待結果 |
|---------|---------|---------|
| 設定追加 | `grep "ai_tools" prompts/package/prompts/common/review-flow.md` | 設定説明が存在 |
| リスト形式 | 設定例確認 | `ai_tools = ["codex", "claude"]` 形式で記載 |
| 利用可否判定 | review-flow.mdのフロー確認 | 判定ロジックが明文化 |

**利用可否の判定ロジック**:
1. ai_toolsリストの先頭から順に確認
2. 各ツールについて: Skillツール存在確認 → 存在すれば使用
3. Skill不在の場合: MCPツール（mcp__{tool}__*）存在確認 → 存在すれば使用
4. 両方不在の場合: 次のツールへ
5. すべて不在の場合: AIレビュー不可として処理

**対応ツール名リスト**（固定、小文字で指定）:
- `codex` - Codex CLI
- `claude` - Claude Code
- `gemini` - Gemini CLI

**エラーハンドリング**:

| ケース | 期待動作 |
|-------|---------|
| `ai_tools = []`（空配列） | デフォルト `["codex"]` として動作 |
| 未対応ツール名（例: `["unknown"]`） | 該当ツールをスキップし、次のツールへ。すべて未対応ならAIレビュー不可 |
| 不正な型（文字列以外） | デフォルト `["codex"]` として動作 |

**スコープ外（実装時に決定）**:
- 大文字小文字の正規化（現時点では小文字のみ対応）
- 重複ツール名の排除（そのまま順次評価）
- 空文字・空白のみの要素の扱い（スキップ）

**後方互換性テストケース**:

| 既存設定 | 期待動作 |
|---------|---------|
| `mode = "required"` のみ（ai_tools未設定） | デフォルト `["codex"]` として動作 |
| `mode = "disabled"` | ai_tools設定に関係なくAIレビュースキップ |

**実動作テストケース**（Construction Phase実装時に検証）:

| テストシナリオ | 設定 | 期待結果 |
|--------------|------|---------|
| codex優先 | `ai_tools = ["codex", "claude"]` + codex利用可能 | codexでレビュー実行 |
| フォールバック | `ai_tools = ["codex", "claude"]` + codex利用不可 | claudeでレビュー実行 |
| 全不可 | `ai_tools = ["codex"]` + codex利用不可 | AIレビュー不可メッセージ |

**技術的考慮事項**:
- review-flow.mdに「## ai_tools設定」セクションを追加
- 設定例、判定フロー、後方互換性の説明を含める

---

### ストーリー 4: AI著者情報の自動検出

**優先順位**: Must-have
**関連Issue**: #110

As a 複数のAIツールを使い分ける開発者
I want to 使用中のAIツールに応じてCo-Authored-Byが自動設定される
So that コミット履歴に正確な貢献記録が残る

**受け入れ基準**:

| 検証項目 | 検証方法 | 期待結果 |
|---------|---------|---------|
| 自動検出ロジック | rules.mdに記載確認 | 検出ロジックが明文化 |
| 設定優先 | aidlc.tomlでai_author設定時 | 設定値が使用される |
| 無効化オプション | ai_author_auto_detect = false設定時 | 自動検出スキップ |

**自動検出方式**:

AIツール自身が実行コンテキストから自己判断する。

| 検出方法 | 判定基準 | 検出結果 |
|---------|---------|---------|
| AIツール自己認識 | AIエージェントが自身のツール名を認識 | 対応するai_author値 |
| 環境変数（補助） | CLAUDE_CODE, CURSOR_EDITOR等 | 対応するai_author値 |
| 検出失敗時 | 自己認識も環境変数もない | ユーザーに確認 |

**AIツールとai_author値のマッピング**:

| AIツール | ai_author値 |
|---------|-------------|
| Claude Code | `Claude <noreply@anthropic.com>` |
| Cursor | `Cursor <noreply@cursor.com>` |
| Cline | `Cline <noreply@cline.bot>` |
| Windsurf | `Windsurf <noreply@codeium.com>` |
| Codex CLI | `Codex <noreply@openai.com>` |
| KiroCLI | `Kiro <noreply@aws.com>` |

**検出失敗時の動作**:
- 固定デフォルト値は使用しない（誤った情報をコミットに残さないため）
- ユーザーに「どのAIツールを使用していますか？」と確認
- または aidlc.toml で明示的に ai_author を設定することを促す

**aidlc.toml設定との優先順位**:
1. `ai_author` が有効な値で設定されている → その値を使用（自動検出しない）
2. `ai_author` 未設定/空/空白のみ → AIツール自己認識で検出
3. 自己認識できない場合 → 環境変数から検出
4. 環境変数もない場合 → ユーザーに確認（固定デフォルト値は使用しない）

**「未設定」の定義**:
- キーが存在しない
- `ai_author = ""`（空文字）
- `ai_author = "   "`（空白のみ）
- 上記はすべて「未設定」として扱い、自動検出を試みる

**実動作テストケース**（Construction Phase実装時に検証）:

| テストシナリオ | 実行環境 | aidlc.toml設定 | 期待Co-Authored-By |
|--------------|---------|---------------|-------------------|
| Claude Code自己認識 | Claude Code | ai_author未設定 | `Claude <noreply@anthropic.com>` |
| Cursor自己認識 | Cursor | ai_author未設定 | `Cursor <noreply@cursor.com>` |
| 設定優先 | Claude Code | ai_author="Custom <x@y.com>" | `Custom <x@y.com>` |
| 検出失敗時 | 不明なツール | ai_author未設定 | ユーザーに確認ダイアログ |

**技術的考慮事項**:
- rules.mdの「## Co-Authored-By の設定」セクションを拡張
- 検出ロジックのフローチャートまたは疑似コードを記載

---

### ストーリー 5: KiroCLI Skills対応

**優先順位**: Should-have
**関連Issue**: #107

As a KiroCLIを使用する開発者
I want to AI-DLCのスキルをKiroCLIで利用できる
So that KiroCLI環境でもAI-DLCの機能が活用できる

**受け入れ基準**:

| 検証項目 | 検証方法 | 期待結果 |
|---------|---------|---------|
| 調査レポート | `ls docs/cycles/v1.9.2/research/kirocli-skills.md` | ファイル存在 |
| スキルファイル | `ls prompts/package/skills/kiro/SKILL.md` | ファイル存在 |
| KiroCLI読み込み | `kiro skill list` でスキル表示 | AI-DLCスキルが一覧に表示 |
| 共存確認 | `ls prompts/package/skills/` | claude/, codex/, gemini/, kiro/ の4ディレクトリ存在 |

**調査レポートの必須項目**:
- [ ] KiroCLI Skills機能の概要
- [ ] スキルファイルの形式（フロントマター、必須セクション）
- [ ] resources指定方法
- [ ] 既存AI-DLCスキル（codex等）との違い
- [ ] 実装方針の決定

**共存の定義**:
- 各スキルディレクトリ（claude/, codex/, gemini/, kiro/）が独立して存在
- 名前衝突なし（各ディレクトリ内のSKILL.mdは独立）
- 読み込み順序の制御はKiroCLI側の仕様に依存（調査で確認）

**技術的考慮事項**:
- KiroCLI v1.24.0以降が対象
- 調査結果に基づきスキルファイル形式を決定
