# 論理設計: 複合コマンド廃止

## 概要

各プロンプトファイル内の複合コマンドを単純コマンドに変換し、AIがReadツールで設定を直接読み取り、コマンド出力を解釈する方式に移行する。

**重要**: この論理設計では**コードは書かず**、変換ルールと変換箇所の特定のみを行います。具体的な修正はPhase 2で実施します。

## アーキテクチャパターン

**採用パターン**: AI主導の解釈パターン

- 複合コマンドの論理（条件分岐、エラー処理）をAIの責務に移行
- 単純コマンドの実行結果をAIが解釈して後続処理を決定
- 設定ファイルはReadツールで直接読み取り

**選定理由**:

- シェルの複合構文を避けることで許可リスト管理が容易になる
- AIの解釈能力を活用してロジックを柔軟に処理
- デバッグ・トレースが容易になる

## 変換対象ファイル構成

```text
prompts/package/
├── prompts/
│   ├── operations.md      [重点対象: 多数の複合コマンド]
│   ├── setup.md           [重点対象: 多数の複合コマンド]
│   ├── inception.md       [対象: 複数の複合コマンド]
│   ├── construction.md    [対象: 少数の複合コマンド]
│   └── common/
│       └── review-flow.md [対象: git status チェック]
└── guides/
    └── backlog-management.md [対象: BACKLOG_MODE取得]
```

## ファイル別変換詳細

### 1. prompts/package/prompts/operations.md

#### 変換箇所1: サイクル存在チェック（154行目付近）

**変換前**:

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

**変換後**:

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

**説明文の調整**: 「出力があれば存在、エラーなら不存在」をAIが判断（`-d`オプションで空ディレクトリでもパス名を出力）

#### 変換箇所2: PROJECT_TYPE読み取り（295-299行目付近）

**変換前**:

```bash
PROJECT_TYPE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'project.type' 2>/dev/null | tr -d "'" || echo "general")
[ -z "$PROJECT_TYPE" ] && PROJECT_TYPE="general"
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `type` 値を確認。
> **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `general` として扱う。

#### 変換箇所3: PROJECT_FILES/PROJECT_COUNT（330-335行目付近）

**変換前**:

```bash
PROJECT_FILES=$(find . -name "project.pbxproj" ... )
PROJECT_COUNT=$(echo "$PROJECT_FILES" | grep -c . 2>/dev/null || echo 0)
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが Claude Code の Glob ツールでプロジェクトファイル（project.pbxproj, Package.swift等）を検索し、数を確認。
> 代替手段: `find . -name "project.pbxproj" -o -name "Package.swift" 2>/dev/null` でも可。

#### 変換箇所4: DEFAULT_BRANCH取得（378-380行目付近）

**変換前**:

```bash
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"
git rev-parse --verify origin/${DEFAULT_BRANCH} >/dev/null 2>&1 || DEFAULT_BRANCH="master"
```

**変換後**:

```bash
git remote show origin 2>/dev/null
```

**説明文**:
> 1. AIが出力から「HEAD branch」行を確認しデフォルトブランチ名を取得
> 2. 取得できない場合は `main` を候補とする
> 3. 候補ブランチの存在確認: `git show-ref --verify "refs/remotes/origin/{branch}" 2>/dev/null`
> 4. 存在しない場合は `master` を試行

#### 変換箇所5: CHANGELOG存在チェック（593行目付近）

**変換前**:

```bash
ls CHANGELOG.md 2>/dev/null && echo "CHANGELOG_EXISTS" || echo "CHANGELOG_NOT_EXISTS"
```

**変換後**:

```bash
ls CHANGELOG.md 2>/dev/null
```

#### 変換箇所6: SETUP_PROMPT取得（876-881行目付近）

**変換前**:

```bash
SETUP_PROMPT=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'paths.setup_prompt' 2>/dev/null | tr -d "'" || echo "")
[ -z "$SETUP_PROMPT" ] && SETUP_PROMPT="prompts/setup-prompt.md"
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが `docs/aidlc.toml` をReadツールで読み取り、`[paths]` セクションの `setup_prompt` 値を確認。
> **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `prompts/setup-prompt.md` を使用。

### 2. prompts/package/prompts/setup.md

#### 変換箇所1: デプロイ済み確認（76行目付近）

**変換前**:

```bash
[ -f docs/aidlc/prompts/setup.md ] && echo "DEPLOYED_EXISTS" || echo "DEPLOYED_NOT_EXISTS"
```

**変換後**:

```bash
ls docs/aidlc/prompts/setup.md 2>/dev/null
```

#### 変換箇所2: PROJECT_NAME読み取り（97行目付近）

**変換前**:

```bash
PROJECT_NAME=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'project.name' 2>/dev/null | tr -d "'" || echo "")
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `name` 値を確認。
> **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

#### 変換箇所3: バージョン比較（179-183行目付近）

**変換前**:

```bash
LATEST_VERSION=$(curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null | tr -d '\n' || echo "")
CURRENT_VERSION=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'starter_kit_version' 2>/dev/null | tr -d "'" || echo "")
```

**変換後**:

```bash
curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null
```

**説明文**:
> AIがcurl出力から最新バージョンを取得（エラー時は空として扱う）。
> 現在のバージョンは `docs/aidlc.toml` の `starter_kit_version` をReadツールで確認。

#### 変換箇所4: worktree存在チェック（350行目付近）

**変換前**:

```bash
git worktree list | grep "cycle/{{CYCLE}}" && echo "WORKTREE_EXISTS" || echo "WORKTREE_NOT_EXISTS"
```

**変換後**:

```bash
git worktree list --porcelain
```

**説明文**:
> AIが `--porcelain` 出力から `worktree` 行を確認し、パスに `cycle/{{CYCLE}}` が完全一致で含まれるかを判定。

#### 変換箇所5: ブランチ存在チェック（364, 429行目付近）

**変換前**:

```bash
git show-ref --verify --quiet "refs/heads/cycle/{{CYCLE}}" && echo "BRANCH_EXISTS" || echo "BRANCH_NOT_EXISTS"
```

**変換後**:

```bash
git show-ref --verify "refs/heads/cycle/{{CYCLE}}" 2>/dev/null
```

#### 変換箇所6: 旧バックログ存在チェック（513行目付近）

**変換前**:

```bash
[ -f docs/cycles/backlog.md ] && echo "OLD_BACKLOG_EXISTS" || echo "OLD_BACKLOG_NOT_EXISTS"
```

**変換後**:

```bash
ls docs/cycles/backlog.md 2>/dev/null
```

#### 変換箇所7: サイクル存在チェック（474, 623行目付近）

**変換前**:

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
[ -f "docs/cycles/{{CYCLE}}/requirements/setup-context.md" ] && echo "EXISTS" || echo "NOT_EXISTS"
```

**変換後**:

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
ls docs/cycles/{{CYCLE}}/requirements/setup-context.md 2>/dev/null
```

### 3. prompts/package/prompts/inception.md

#### 変換箇所1: サイクル存在チェック（200, 243行目付近）

**変換前**:

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
[ -f "docs/cycles/{{CYCLE}}/requirements/setup-context.md" ] && echo "CONTEXT_EXISTS" || echo "CONTEXT_NOT_EXISTS"
```

**変換後**:

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
ls docs/cycles/{{CYCLE}}/requirements/setup-context.md 2>/dev/null
```

#### 変換箇所2: 最新サイクル取得（176行目付近）

**変換前**:

```bash
LATEST_CYCLE=$(ls -d docs/cycles/*/ 2>/dev/null | sort -V | tail -1 | xargs basename)
```

**変換後**:

```bash
ls -d docs/cycles/*/ 2>/dev/null
```

**説明文**:
> AIが出力からセマンティックバージョン順（v1.9 < v1.10）で最新のサイクルを判定。

#### 変換箇所3: PROJECT_TYPE読み取り（650-654行目付近）

**変換前**:

```bash
PROJECT_TYPE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'project.type' 2>/dev/null | tr -d "'" || echo "general")
[ -z "$PROJECT_TYPE" ] && PROJECT_TYPE="general"
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `type` 値を確認。
> **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `general` として扱う。

### 4. prompts/package/prompts/construction.md

#### 変換箇所1: サイクル存在チェック（214行目付近）

**変換前**:

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

**変換後**:

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

### 5. prompts/package/prompts/common/review-flow.md

#### 変換箇所1-4: 条件付きgitコミット（51, 78, 111, 120行目付近）

**変換前**:

```bash
[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
```

**変換後**:

```bash
git status --porcelain
```

**説明文**:
> AIが出力を確認し、変更がある場合は以下を順次実行:
>
> ```bash
> git add -A
> git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
> ```

### 6. prompts/package/guides/backlog-management.md

#### 変換箇所1: BACKLOG_MODE取得（106-107行目付近）

**変換前**:

```bash
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
```

**変換後**: 削除（説明文で対応）

**説明文**:
> AIが `docs/aidlc.toml` をReadツールで読み取り、`[backlog]` セクションの `mode` 値を確認。
> **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `git` として扱う。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 該当なし（Unit定義より）
- **対応策**: 単純コマンドへの変換により実行オーバーヘッドを削減

### セキュリティ

- **要件**: 該当なし（Unit定義より）
- **対応策**: 複合コマンドを排除することで意図しないコマンド連鎖を防止

### スケーラビリティ

- **要件**: 該当なし（Unit定義より）
- **対応策**: 変更なし

### 可用性

- **要件**: 該当なし（Unit定義より）
- **対応策**: エラー時のフォールバックをAIの判断に委ねることで柔軟に対応

## 実装上の注意事項

1. **説明文の調整**: コマンド変換後、周辺の説明文も「AIが判断する」形式に調整
2. **heredocは維持**: `$(cat <<'EOF' ... EOF)` 形式のheredocは許可リストで対応済みのため変更不要
3. **jj-support.mdは対象外**: リファレンスとしての複合コマンドは意図的に維持
4. **daselのオプション**: Unit定義に記載の`-r toml`オプション削除は既に対応済み（dasel v2ではオプション不要）

## 不明点と質問

なし（Unit定義と計画で方針確定済み）
