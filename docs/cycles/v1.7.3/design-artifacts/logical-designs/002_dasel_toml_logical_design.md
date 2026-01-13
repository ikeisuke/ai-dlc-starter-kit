# 論理設計: daselによるTOML読み込み対応

## 概要

プロンプトファイル群でのTOML設定値の読み込みをdasel対応化し、可読性と保守性を向上させる。

## アーキテクチャパターン

**パターン**: dasel優先 + AI読み込みフォールバック

既存の `inception.md` / `construction.md` / `operations.md` で採用されているパターンに統一する。

## 変更対象

### 対象箇所一覧

| # | ファイル | 行番号 | 対象フィールド | 現在の手法 |
|---|----------|--------|----------------|------------|
| 1 | prompts/setup-prompt.md | 56 | starter_kit_version | grep + sed |
| 2 | prompts/package/prompts/setup.md | 122 | project.name | awk + gsub |
| 3 | prompts/package/prompts/setup.md | 233 | starter_kit_version | grep + sed |
| 4 | prompts/package/prompts/operations.md | 1057 | paths.setup_prompt | grep + sed |

### スコープに関する注記

- **`docs/aidlc/prompts/`**: `prompts/package/` のrsyncコピーであり、Operations Phaseで自動同期される（直接編集対象外）
- **本Unitの編集対象**: `prompts/setup-prompt.md` と `prompts/package/prompts/` 配下のみ

## 変更詳細

### 変更1: setup-prompt.md:56 - starter_kit_version取得

**現在のコード**:

```bash
grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' || echo "VERSION_NOT_FOUND"
```

**変更後のコード**:

```bash
if command -v dasel >/dev/null 2>&1; then
    VERSION=$(dasel -f docs/aidlc.toml -r toml '.starter_kit_version' 2>/dev/null || echo "")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    VERSION=""
fi
[ -z "$VERSION" ] && VERSION="VERSION_NOT_FOUND"
echo "$VERSION"
```

**フォールバック指示（dasel未インストール時）**:

> AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。
> 値が取得できない場合は「VERSION_NOT_FOUND」として扱ってください。

### 変更2: setup.md:122 - project.name取得

**現在のコード**:

```bash
PROJECT_NAME=$(awk '/^\[project\]/{found=1} found && /^name *= *"/{gsub(/.*= *"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null)
```

**変更後のコード**:

```bash
if command -v dasel >/dev/null 2>&1; then
    PROJECT_NAME=$(dasel -f docs/aidlc.toml -r toml '.project.name' 2>/dev/null || echo "")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    PROJECT_NAME=""
fi
```

**フォールバック指示（dasel未インストール時）**:

> AIは `docs/aidlc.toml` を読み込み、`[project]` セクションの `name` 値を取得してください。

### 変更3: setup.md:233 - starter_kit_version取得

**現在のコード**:

```bash
CURRENT_VERSION=$(grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' || echo "")
```

**変更後のコード**:

```bash
if command -v dasel >/dev/null 2>&1; then
    CURRENT_VERSION=$(dasel -f docs/aidlc.toml -r toml '.starter_kit_version' 2>/dev/null || echo "")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    CURRENT_VERSION=""
fi
```

**フォールバック指示（dasel未インストール時）**:

> AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。

### 変更4: operations.md:1057 - paths.setup_prompt取得

**現在のコード**:

```bash
SETUP_PROMPT=$(grep -E '^\s*setup_prompt\s*=' docs/aidlc.toml | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
```

**変更後のコード**:

```bash
if command -v dasel >/dev/null 2>&1; then
    SETUP_PROMPT=$(dasel -f docs/aidlc.toml -r toml '.paths.setup_prompt' 2>/dev/null || echo "")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    SETUP_PROMPT=""
fi
[ -z "$SETUP_PROMPT" ] && SETUP_PROMPT="prompts/setup-prompt.md"
```

**フォールバック指示（dasel未インストール時）**:

> AIは `docs/aidlc.toml` を読み込み、`[paths]` セクションの `setup_prompt` 値を取得してください（デフォルト: `prompts/setup-prompt.md`）。

## 共通パターン

### daselコマンド形式

```bash
dasel -f <file> -r toml '<path>'
```

- `-f`: 対象ファイル
- `-r toml`: 入力形式をTOMLに指定
- `'<path>'`: ドット区切りのパス（例: `.project.name`）

### フォールバックの統一形式

```bash
if command -v dasel >/dev/null 2>&1; then
    VALUE=$(dasel -f docs/aidlc.toml -r toml '<path>' 2>/dev/null || echo "<default>")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    VALUE=""
fi
[ -z "$VALUE" ] && VALUE="<default>"
```

## 非機能要件への対応

### パフォーマンス

- daselは高速（単一値取得は数ms）
- AI読み込みフォールバックは既存動作と同等

### 可用性

- dasel未インストール環境でも動作（AI読み込みフォールバック）

## 実装上の注意事項

1. **パスの正確性**: daselのパスはTOML構造に依存。セクション名を含める（例: `.project.name`）
2. **エラーハンドリング**: `2>/dev/null` でstderrを抑制、`|| echo ""` でエラー時は空文字
3. **デフォルト値**: 空値チェック後にデフォルト値を適用

## 不明点と質問

（なし - 計画策定時に解決済み）
