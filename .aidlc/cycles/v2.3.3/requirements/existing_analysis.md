# 既存コードベース分析

## ディレクトリ構造・ファイル構成

修正対象ファイルの配置:

```
skills/aidlc/
├── SKILL.md                          # パス解決ルール修正対象
├── scripts/
│   ├── write-config.sh               # レガシーエイリアス修正対象
│   ├── read-config.sh                # 参照（エイリアス解決実装済み）
│   └── lib/
│       └── key-aliases.sh            # エイリアスマッピング定義
├── steps/inception/
│   └── 05-completion.md              # 設定保存フロー構造改善対象
├── config/
├── templates/
���── guides/
└── references/

.github/workflows/
├── pr-check.yml                      # permissions追加対象
├── migration-tests.yml               # permissions追加対象
├── skill-reference-check.yml         # permissions定義済み（参考）
└── auto-tag.yml                      # permissions定義済み（参考）
```

## アーキテ���チャ・パターン

### パス解決（SKILL.md L238）
- 現在: `steps/` と `scripts/` で始まるパスのみスキルベースディレクトリ相対として解決
- 不足: `config/`, `templates/`, `guides/`, `references/` が未定義
- 根拠: プリフライトで `config/defaults.toml` がCWD相対で解決され偽陰性警告が発生

### write-config.sh のキー解決
- read-config.sh: `lib/key-aliases.sh` の `aidlc_normalize_key()` と `aidlc_get_legacy_key()` を使い正規キー/レガシーキー両方を評価（L305-393 `resolve_with_aliases()`）
- write-config.sh: レガシーエイリアス処理が完全に欠落（L111-120はドット区切りの単純分解のみ）
- エイリアスマッピング（key-aliases.sh L13-55）:
  - `rules.branch.mode` → `rules.git.branch_mode`
  - `rules.unit_branch.enabled` → `rules.git.unit_branch_enabled`
  - `rules.squash.enabled` → `rules.git.squash_enabled`
  - `rules.commit.ai_author` → `rules.git.ai_author`
  - `rules.commit.ai_author_auto_detect` → `rules.git.ai_author_auto_detect`

### 05-completion.md ステップ5d構造
- L146-177: ステップ5d「actionに応じた実行」
  - action分岐（skip_never / ask_user / create_draft_pr）と設定保存フローが同一ステップに同居
  - L166-174: 設定保存フロー（`write-config.sh rules.git.draft_pr`）
  - PR作成（ステップ5e）に意識が移ると設定保存フローが読み飛ばされる

### GitHub Actions permissions
- `pr-check.yml`: 3ジョブ（markdown-lint, bash-substitution-check, defaults-sync-check）すべてpermissions未定義
- `migration-tests.yml`: 1ジョブ（migration-tests）permissions未定義
- `skill-reference-check.yml`: `contents: read` 定義済み（参考モデル）
- `auto-tag.yml`: `contents: write` 定義済み（参考モデル）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト), Markdown | scripts/*.sh, steps/**/*.md |
| ツール | dasel v3 (TOML操作), gh CLI | scripts/read-config.sh, scripts/write-config.sh |
| CI/CD | GitHub Actions | .github/workflows/*.yml |

## 依存関係

- write-config.sh → lib/key-aliases.sh（エイリアスマッピング、現在未使用・追加が必要）
- write-config.sh → lib/bootstrap.sh（環境変数設定）
- read-config.sh → lib/key-aliases.sh（エイリアス解決、実装済み）
- 05-completion.md → write-config.sh（設定保存フローでの呼び出し）
- SKILL.md → 全ステップファイル（パス解決ルールの適用）

## 特記事項

- write-config.shの修正はread-config.shの `resolve_with_aliases()` パターンを参考にできるが、書き込み側はレガシーキーの検出・削除（または更新）のロジックが追加で必要
- 05-completion.mdの構造改善は、設定保存フローを独立ステップ（5d'や5f）に分離する案Aが最も構造的
