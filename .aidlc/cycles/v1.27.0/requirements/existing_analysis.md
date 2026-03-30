# 既存コードベース分析

## ディレクトリ構造・ファイル構成

対象ファイル:
- `prompts/package/bin/setup-ai-tools.sh` — AI開発ツールのセットアップスクリプト
- `bin/post-merge-cleanup.sh` — マージ後のクリーンアップスクリプト
- `docs/aidlc/kiro/agents/aidlc.json` — Kiroエージェント設定ファイル（シンボリックリンク先）
- `.kiro/agents/aidlc.json` — Kiroエージェント設定（シンボリックリンク）

## アーキテクチャ・パターン

### setup-ai-tools.sh
- **4フェーズ構成**: (1) Skills symlink (2) Codex skills symlink (3) Kiro agent setup (4) Claude Code permissions
- **テンプレート方式**: `_generate_template()` がClaude Code許可ルールをハードコードしたJSON heredocを出力
- **マージ方式**: `_merge_permissions_jq()` / `_merge_permissions_python()` がset-difference（`$defaults - $existing`）で新規パターンのみ追加。既存ルールは一切削除・上書きしない
- **JSON状態判定**: `_detect_json_state()` で absent/valid/invalid/unknown を判定し、状態に応じた処理分岐
- **原子的書き込み**: `_write_atomic()` でtmpファイル→mvパターン

### post-merge-cleanup.sh
- **7ステップ構成**: step_0a(環境検証) → step_0b(作業状態検証) → step_1(デフォルトブランチ更新) → step_2(fetch) → step_3(ブランチ状態クリーンアップ) → step_4(ローカルブランチ削除) → step_5(リモートブランチ削除)
- **エラー重大度の二層化**: step_0a/0b/1/2/3は`fatal_error`（ハードフェイル）、step_4/5は警告（非致命的）
- **共通関数**: `resolve_remote()` がブランチ設定→origin→最初のリモートの順でリモートを解決

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (POSIX準拠) | setup-ai-tools.sh, post-merge-cleanup.sh |
| JSON操作 | jq (優先) / python3 (フォールバック) | setup-ai-tools.sh:237, 273 |
| 設定形式 | JSON (.claude/settings.json, .kiro/agents/aidlc.json) | setup-ai-tools.sh:192 |

## 依存関係

### setup-ai-tools.sh
- `docs/aidlc/kiro/agents/aidlc.json` — Kiroエージェント設定テンプレート（シンボリックリンク先）
- `_generate_template()` → `_merge_permissions_jq()` / `_merge_permissions_python()` — テンプレートから許可ルールを取得してマージ
- 外部依存: jq (推奨) / python3 (フォールバック)

### post-merge-cleanup.sh
- `resolve_remote()` — step_0a, step_4, step_5で共通使用
- `fatal_error()` — step_0a/0b/1/2/3で使用（エラー時即座に終了）

### translate-permissions スキル
- 既存の `translate-permissions` スキルがClaude Code → Kiro許可設定の変換ロジックを持つ
- `translate-permissions.py` にパーミッションパターン解析・正規化・Kiro JSON生成のロジックが実装済み

## 特記事項

### #385 Kiro許可設定拡張に関して
- 現在の `setup_kiro_agent()` はシンボリックリンクの作成・修復のみ。許可設定は含まれていない
- `translate-permissions` スキルにClaude→Kiro変換ロジックが既に存在する。setup-ai-tools.shでの許可設定生成はこれを参考にできる
- Kiroエージェント設定は `aidlc.json` に `tools`, `allowedTools`, `toolsSettings` として記述する形式

### #384 setup-ai-tools.sh パーミッション管理改善に関して
- 現在のマージロジック（`$defaults - $existing`）は完全一致のset-differenceのみ
- ワイルドカードルール（例: `Bash(docs/aidlc/bin/:*)`）が既に存在する場合、そのパターンに包含される個別ルール（例: `Bash(docs/aidlc/bin/read-config.sh:*)`）の追加をスキップするロジックは未実装
- テンプレートのハードコードは現行のまま維持（外部設定ファイル化はスコープ外）

### #381 post-merge-cleanup.sh ブランチ不在対応に関して
- step_0a（行224-228）: `git show-ref --verify` でブランチ存在確認 → 不在時 `fatal_error` で即終了
- step_4（行360-377）: ローカルブランチ削除失敗時は `warning` として後続処理を継続
- 修正方針: step_0aのブランチ不在チェックを `fatal_error` → `warning` に変更し、後続ステップ（リモートブランチ削除等）を続行可能にする
