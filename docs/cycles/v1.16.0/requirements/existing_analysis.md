# 既存コード分析 - v1.16.0

## 1. フェーズプロンプト構造（スキル化対象）

### 現在の構造

- **プロンプト配置**: `prompts/package/prompts/` → rsyncで `docs/aidlc/prompts/` にデプロイ
  - `inception.md` (~830行): セットアップ + Intentから Unit定義まで
  - `construction.md`: 設計・実装フロー
  - `operations.md` (~930行): デプロイ・リリースフロー
  - `common/` ディレクトリ: 共通モジュール（rules.md, intro.md, review-flow.md, commit-flow.md 等）
- **呼び出し方法**: `AGENTS.md` の簡略指示（「インセプション進めて」等）→ プロンプトファイルをReadツールで読み込み

### 既存スキル構造（参考）

- 配置: `prompts/package/skills/` → rsyncで `docs/aidlc/skills/` → `.claude/skills/` からシンボリックリンク
- 形式: `SKILL.md` にfrontmatter（name, description, argument-hint）+ 本文
- 既存スキル: reviewing-*, upgrading-aidlc, versioning-with-jj

### スキル化の課題

- 各フェーズプロンプトは800-930行と大規模。共通モジュール（`common/`）の参照が多い
- `AGENTS.md` が簡略指示のルーティングを担っている。スキル化後もこの仕組みが必要
- スキルはfrontmatterの `description` でトリガー条件を定義可能
- `~/.claude/skills/` に配置する場合、`docs/aidlc/bin/` のスクリプト群への依存が課題

## 2. aidlc-git-info.sh（#198）

### バグ箇所

`detect_vcs()` 関数（行23-35）:

```bash
if [[ -d ".jj" ]] && command -v jj >/dev/null 2>&1; then
    echo "jj"; return
fi
if [[ -d ".git" ]]; then
    echo "git"; return
fi
echo "unknown"
```

- worktree環境では `.git` はディレクトリではなくファイル（`gitdir: /path/to/.git/worktrees/dev` 形式）
- `-d ".git"` はディレクトリのみチェックするため、worktreeではfalseとなり `unknown` を返す

### 修正方針

- `-d ".git"` を `-e ".git"` に変更（ファイルでもディレクトリでも存在確認）
- または `git rev-parse --is-inside-work-tree` で判定

## 3. suggest-version.sh（#197）

### 問題箇所

`get_latest_cycle()` 関数（行31-41）:

```bash
cycles=$(ls -d docs/cycles/v*/ 2>/dev/null | sort -V | tail -1 || echo "")
```

- `docs/cycles/v*/` にマッチする全ディレクトリを対象とする
- `v` で始まるが SemVer形式でないディレクトリ名（例: `v-temp`, `vtest`）が存在した場合に不正な結果を返す

### 修正方針

- `sort -V` の前にSemVerパターン（`vX.Y.Z` 形式）でフィルタリング
- 例: `grep -E '^docs/cycles/v[0-9]+\.[0-9]+\.[0-9]+/$'`

## 4. Operations Phase push確認ステップ（#196）

### 現在のフロー

- `6.6.5 コミット漏れ確認`: 未コミット変更の確認のみ
- `6.7 PRマージ`: 直接マージ実行に進む
- ローカルとリモートの同期状態を確認するステップがない

### 追加箇所

- `6.6.5` と `6.7` の間に新ステップ `6.6.6 リモート同期確認` を追加
- `git log origin/{branch}..HEAD` でunpushedコミットを確認
- unpushedコミットがある場合: pushを促し、マージをブロック
