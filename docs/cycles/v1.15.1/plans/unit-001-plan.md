# Unit 001 計画: Kiro標準スキル呼び出し対応

## 概要

Kiroの `.kiro/skills/` 標準ディレクトリにスキル定義をシンボリックリンクで配置し、Kiroネイティブのスキル発見機能で既存スキルが呼び出し可能になるようにする。

## Kiro標準スキル仕様（調査結果）

- `.kiro/skills/` ディレクトリにスキルフォルダを配置
- 各スキルフォルダに `SKILL.md`（YAML frontmatter付き）が必須
- ワークスペースレベル（`.kiro/skills/`）のスキルはグローバル（`~/.kiro/skills/`）より優先
- 起動時はメタデータ（name, description）のみ読み込み、オンデマンドで本文をロード
- agentskills.io オープン標準準拠 — Claude Code のスキル形式と互換
- 既存のSKILL.mdフォーマット（YAML frontmatter: name, description等）はそのまま利用可能

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/kiro/agents/aidlc.json` | `skill://` リソース参照を削除し、`.kiro/skills/` ネイティブ発見方式に変更 |
| `prompts/package/bin/setup-ai-tools.sh` | `.kiro/skills/` セットアップ関数 `setup_kiro_skills()` を追加 |
| `prompts/setup-prompt.md` | セクション8.2.7のディレクトリ構成図に `.kiro/skills/` を追加 |

## スキル発見の仕様

- `docs/aidlc/skills/` 配下のディレクトリを動的列挙
- 各ディレクトリに `SKILL.md` が存在することを確認（存在しないディレクトリは警告してスキップ）
- 1ディレクトリ = 1スキルの原則

## 後方互換性方針

- `aidlc.json` から `skill://` 参照を削除し、`.kiro/skills/` ネイティブ発見に完全移行
- 理由: `.kiro/skills/` はKiro 1.24.0以降の標準仕様であり、`skill://` は非標準の独自参照。agentskills.ioオープン標準に準拠する方が将来性が高い
- `.kiro/skills/` 非対応の旧Kiroバージョンでは `aidlc.json` の `resources` から直接スキルを読むフォールバックは提供しない（旧バージョンのサポートはスコープ外）

## テスト方針

- `prompts/package/` で編集後、`docs/aidlc/` への反映はOperations Phaseのrsyncで行われる（メタ開発ルール）
- テスト時は `prompts/package/bin/setup-ai-tools.sh` を直接実行して検証（実行時は `docs/aidlc/` を参照するため、事前に手動でrsync同期するか、`docs/aidlc/bin/setup-ai-tools.sh` も同時更新して検証）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: `.kiro/skills/` のシンボリックリンク構成、`aidlc.json` の更新方針、`setup-ai-tools.sh` の拡張設計を定義（共通関数抽出の是非も検討）
2. **論理設計**: スクリプトのフロー設計、べき等性の確保方法、エラーハンドリング、SKILL.md存在チェックを定義
3. **設計レビュー**: AIレビュー + ユーザー承認

### Phase 2: 実装

4. **コード生成**:
   - `prompts/package/kiro/agents/aidlc.json` の更新
   - `prompts/package/bin/setup-ai-tools.sh` に `setup_kiro_skills()` 追加
   - `prompts/setup-prompt.md` のディレクトリ構成図更新
5. **テスト**: 手動検証（シンボリックリンク作成、べき等性確認、SKILL.md未存在ディレクトリのスキップ確認）
6. **統合とレビュー**: AIレビュー + ユーザー承認

## 完了条件チェックリスト

- [x] `.kiro/skills/` ディレクトリの作成とシンボリックリンク配置
- [x] `.kiro/agents/aidlc.json` のKiro標準スキル発見方式への更新
- [x] セットアップスクリプトへの `.kiro/skills/` 作成処理追加
