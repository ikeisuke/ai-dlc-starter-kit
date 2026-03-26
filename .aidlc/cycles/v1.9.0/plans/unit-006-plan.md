# Unit 006 計画: 複合コマンド廃止

## 概要

プロンプト内の複合コマンド（`&&`, `||`, `|`、変数代入）を単純化し、許可リスト運用を改善する。

## 変更対象ファイル

### 主要対象

| ファイル | 複合コマンド数 | 主なパターン |
|----------|---------------|-------------|
| `prompts/package/prompts/operations.md` | 多数 | 変数代入、パイプ、条件分岐 |
| `prompts/package/prompts/setup.md` | 多数 | ファイル存在チェック、変数代入 |
| `prompts/package/prompts/inception.md` | 複数 | サイクル存在チェック、変数代入 |
| `prompts/package/prompts/construction.md` | 少数 | サイクル存在チェック |
| `prompts/package/prompts/common/review-flow.md` | 4箇所 | git status チェック |
| `prompts/package/guides/backlog-management.md` | 1箇所 | BACKLOG_MODE取得 |

### 対象外（変更しない）

| ファイル | 理由 |
|----------|------|
| `prompts/package/guides/jj-support.md` | jjコマンドの連鎖は意図的なデモ・リファレンス |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 変換パターンの整理（6パターン）
   - Pattern1: ファイル/ディレクトリ存在チェック
   - Pattern2: ブランチ/参照存在チェック
   - Pattern3: 設定値読み取り（変数代入）
   - Pattern4: コマンド出力処理（パイプチェーン）
   - Pattern5: 条件付きgitコミット
   - Pattern6: フォールバック付きバージョン取得

2. **論理設計**: 各パターンの変換ルール定義
   - 単純コマンドへの分解方法
   - AIが解釈する方式への変更
   - 既存スクリプトの活用（Unit 005で作成済み）

### Phase 2: 実装

1. **パターン別変換実施**
   - 各ファイルの複合コマンドを特定
   - 変換ルールに基づいて修正
   - 前後の説明文を適宜調整

2. **動作確認**
   - プロンプトの可読性確認
   - AIが正しく解釈できることを確認

## 変換パターン

### パターン1: ファイル/ディレクトリ存在チェック

**変換前**:

```bash
[ -f docs/aidlc.toml ] && echo "EXISTS" || echo "NOT_EXISTS"
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "EXISTS" || echo "NOT_EXISTS"
```

**変換後**:

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

AIが出力を解釈: 出力があれば存在、エラーなら不存在（`-d`で空ディレクトリも検出）

### パターン2: 変数代入 + 後続処理

**変換前**:

```bash
PROJECT_TYPE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'project.type' 2>/dev/null | tr -d "'" || echo "general")
[ -z "$PROJECT_TYPE" ] && PROJECT_TYPE="general"
```

**変換後**:
AIがReadツールで `docs/aidlc.toml` を読み取り、`[project]` セクションの `type` 値を直接取得。

**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は "general" として扱う。

### パターン3: エラー時フォールバック

**変換前**:

```bash
CURRENT_VERSION=$(cat docs/aidlc.toml 2>/dev/null | dasel ... || echo "")
```

**変換後**:
AIがReadツールで直接読み取り、値を取得。

**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

### パターン4: git status チェック

**変換前**:

```bash
[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "..."
```

**変換後**:

```bash
git status --porcelain
```

AIが出力を確認し、変更がある場合は以下を順次実行:

```bash
git add -A
git commit -m "..."
```

## 完了条件チェックリスト

- [ ] 複合コマンドの単純コマンドへの置き換え完了
- [ ] 変数代入パターンの削除完了（AIがReadツールで直接読み取る方式へ変更）
- [ ] AIがReadツールで直接読み取る方式への変更箇所を明示
- [ ] gh label関連コマンドの許可リスト追加（対象があれば）

## 備考

- Unit 005で作成したスクリプト（`bin/check-settings.sh`等）を活用
- プロンプトの可読性を維持しつつ、複合コマンドを削減
- jj-support.mdのコマンドチェーンは意図的なリファレンスのため変更対象外
