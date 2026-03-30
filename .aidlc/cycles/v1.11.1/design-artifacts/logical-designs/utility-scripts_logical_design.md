# 論理設計: 定型コマンドのスクリプト化

## ファイル配置

```text
prompts/package/bin/
├── env-info.sh           # 既存（変更なし）
├── check-gh-status.sh    # 既存（変更なし）
├── aidlc-env-check.sh    # 新規作成
├── aidlc-git-info.sh     # 新規作成
└── aidlc-cycle-info.sh   # 新規作成
```

## 既存スクリプトとの関係

| スクリプト | 役割 | 関係 |
|------------|------|------|
| `env-info.sh` | 依存ツール状態一覧（詳細） | `aidlc-env-check.sh`の上位互換 |
| `check-gh-status.sh` | gh認証状態確認（単体） | `aidlc-env-check.sh`に機能包含 |
| `aidlc-env-check.sh` | 環境チェック（最小限） | 新規。許可リスト用に最適化 |
| `aidlc-git-info.sh` | Git/jj状態一括取得 | 新規 |
| `aidlc-cycle-info.sh` | サイクル情報取得 | 新規 |

**設計方針**: 既存スクリプトは変更せず、新規スクリプトは独立して動作する。

## スクリプト構成

### 共通パターン

```bash
#!/usr/bin/env bash
#
# <script-name> - <説明>
#
# 使用方法:
#   ./<script-name>
#
# 出力形式:
#   key:value
#

set -uo pipefail

# 関数定義（エラー時は || true や明示的ハンドリングで捕捉）
function_name() {
    local result
    result=$(some_command 2>/dev/null) || result="unknown"
    echo "$result"
}

# メイン処理
main() {
    # 出力
}

main
```

**注**: `set -e` を使用しないことで、個別コマンド失敗時もスクリプト全体は exit 0 を維持。

### 1. aidlc-env-check.sh

```text
構造:
├── check_tool()       # 汎用ツール存在確認（env-info.shと同じロジック）
├── check_gh()         # gh認証状態確認（env-info.shと同じロジック）
└── main()             # 出力（gh, dasel, jj, git）

出力順序: gh → dasel → jj → git（env-info.shと同じ）
```

### 2. aidlc-git-info.sh

```text
構造:
├── detect_vcs()          # VCS種類判定（.jj/.git存在確認）
├── get_current_branch()  # 現在ブランチ/ブックマーク取得
├── get_worktree_status() # 変更状態取得（clean/dirty/unknown）
├── get_recent_commits()  # 直近コミット取得
└── main()                # 出力

出力項目:
  - vcs_type:<git|jj|unknown>
  - current_branch:<branch-name|(no bookmark)|(detached)>
  - worktree_status:<clean|dirty|unknown>
  - recent_commits_count:<0-3>
  - recent_commit_1:<hash> <message>  （存在する場合）
  - recent_commit_2:<hash> <message>  （存在する場合）
  - recent_commit_3:<hash> <message>  （存在する場合）

VCS判定ロジック:
  1. .jj 存在 かつ jj コマンド利用可能 → jj
  2. .git 存在 → git
  3. それ以外 → unknown

jjブックマーク対応:
  - 複数ある場合は最初の1つを使用
  - 空の場合は (no bookmark) を出力
  - gitでdetached HEADの場合は (detached) を出力

エラー時:
  - コマンド失敗時は該当項目を unknown として出力
```

### 3. aidlc-cycle-info.sh

```text
構造:
├── get_current_branch()  # 現在ブランチ取得（git/jj）
├── extract_version()     # ブランチ名からバージョン抽出
├── get_latest_cycle()    # 最新サイクル取得（docs/cycles/走査）
├── detect_phase()        # フェーズ判定
└── main()                # 出力

バージョン抽出ロジック:
  ブランチ名: cycle/v1.11.1 → v1.11.1
  正規表現: ^cycle/(v[0-9]+\.[0-9]+\.[0-9]+)$

フェーズ判定ロジック:
  1. サイクルディレクトリなし → unknown
  2. operations/ ディレクトリ存在 → operations
  3. construction/ ディレクトリ存在 → construction
  4. それ以外 → inception
```

## 関数の再利用検討

`env-info.sh` の関数（`check_tool`, `check_gh`, `get_current_branch`, `get_latest_cycle`）と重複する部分がある。

**検討オプション**:

| オプション | メリット | デメリット |
|------------|----------|------------|
| A: 独立実装 | 単体で完結、依存なし | コード重複 |
| B: source で読み込み | 重複なし | env-info.shへの依存 |
| C: 共通ライブラリ化 | 最も整理される | 既存スクリプト変更が必要 |

**採用**: **オプションA（独立実装）**

理由:
- 既存スクリプトを変更しない（Unitの境界条件）
- 各スクリプトが単体で動作可能
- コード重複は許容範囲（各関数は数行程度）

## 許可リストガイド更新

### 更新箇所

`prompts/package/guides/ai-agent-allowlist.md` に以下を追加:

1. **新セクション追加**: 「6.2 aidlc-* スクリプトの活用」
2. **設定例の更新**: Claude Code設定例にスクリプト活用版を追記

### 追加内容

```markdown
## 6.2 aidlc-* スクリプトの活用

AI-DLCには、頻繁に使用する読み取り系コマンドをまとめたスクリプトが用意されています。

### 提供スクリプト

| スクリプト | 機能 | 置換可能なコマンド |
|------------|------|-------------------|
| aidlc-env-check.sh | 環境チェック | command -v, gh auth status |
| aidlc-git-info.sh | Git状態取得 | git status, git branch, git log |
| aidlc-cycle-info.sh | サイクル情報 | ブランチ名解析、ディレクトリ走査 |

### 許可リストでの活用

**従来の設定**:
```json
"allow": [
  "Bash(git status)",
  "Bash(git branch --show-current)",
  "Bash(git log:*)",
  "Bash(command -v:*)",
  "Bash(gh auth status)",
  ...
]
```

**スクリプト活用版**:
```json
"allow": [
  "Bash(prompts/package/bin/aidlc-env-check.sh)",
  "Bash(prompts/package/bin/aidlc-git-info.sh)",
  "Bash(prompts/package/bin/aidlc-cycle-info.sh)",
  ...
]
```

または、ワイルドカードで一括許可:
```json
"allow": [
  "Bash(prompts/package/bin/aidlc-*:*)",
  ...
]
```

### メリット

- 許可リストの行数削減
- 出力形式が統一（パース容易）
- 新しいコマンド追加時もスクリプト修正のみで対応

### 注意事項

スクリプトはPATHに含まれないため、許可リストには相対パスを含める必要があります。

## 実行権限

各スクリプト作成後、実行権限を付与:

```bash
chmod +x prompts/package/bin/aidlc-*.sh
```
