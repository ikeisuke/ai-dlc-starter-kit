# 論理設計: パス参照問題の修正

## 概要

プラグイン環境で破綻する `../../` パス参照とハードコードされたスキルパスを修正する。スクリプト3ファイルとMarkdown3ファイルの計6ファイルが修正対象。

**重要**: この論理設計では**コードは書かず**、修正方針とインターフェース定義のみを行います。

## コンポーネント構成

### 修正対象コンポーネント

```text
skills/
├── aidlc/
│   ├── steps/common/
│   │   ├── ai-tools.md          ← 修正対象 #1
│   │   └── intro.md             ← 修正対象 #2
│   └── guides/
│       └── skill-usage-guide.md ← 修正対象 #3
└── aidlc-migrate/
    └── scripts/
        ├── migrate-detect.sh      ← 修正対象 #4
        ├── migrate-cleanup.sh     ← 修正対象 #5
        └── migrate-apply-config.sh ← 修正対象 #6
```

## パス解決戦略（migrateスクリプト共通）

migrateスクリプト群は以下の統一方式でパスを解決する:

| 変数 | 提供元 | 解決方式 | フォールバック |
|------|--------|---------|-------------|
| `AIDLC_PROJECT_ROOT` | 環境変数 or `git rev-parse` | スクリプト冒頭で算出（既存） | `git rev-parse --show-toplevel` |
| `AIDLC_PLUGIN_ROOT` | 環境変数注入 | 呼び出し元が設定 | `${AIDLC_PROJECT_ROOT}/skills/aidlc`（従来互換） |

**契約**: スクリプトは `AIDLC_PROJECT_ROOT` を基本とし、`AIDLC_PLUGIN_ROOT` は環境変数で受け取る。逆方向算出（`/../..`）は使用しない。

## Markdown参照のCanonical Format

スキル内のMarkdownファイル（`steps/`, `guides/` 等）における他ファイルへの参照は、以下の規約に従う:

- **形式**: スキルベース相対パスのインラインコード表記（例: `` `guides/skill-usage-guide.md` ``）
- **解決主体**: AIエージェント側がSKILL.mdの「パス解決」ルールに基づいて解決
- **禁止**: `../../` を含むMarkdownリンク形式（プラグイン環境で破綻するため）
- **根拠**: SKILL.mdの「パス解決」ルールを拡張適用。原文は「`steps/` および `scripts/` で始まるパス」だが、`guides/`, `templates/`, `config/`, `references/` も同様にスキルベースディレクトリからの相対パスとして解決する（SKILL.mdのスキル内リソース一覧に準拠）

## 修正詳細設計

### 修正 #1: `steps/common/ai-tools.md:5`

**現状**:

```markdown
**スキル利用ガイド**: [詳細はこちら](../../guides/skill-usage-guide.md)
```

**修正後**:

```markdown
**スキル利用ガイド**: `guides/skill-usage-guide.md` を参照
```

**理由**: AIエージェントが読むプロンプトファイル。`../../` 相対リンクはプラグイン環境でパスが解決できない。スキルベース相対パスのテキスト参照に変更。

### 修正 #2: `steps/common/intro.md:26`

**現状**:

```markdown
- [エラーハンドリングガイド](../../guides/error-handling.md) — ...
```

**修正後**:

```markdown
- エラーハンドリングガイド（`guides/error-handling.md`）— ...
```

### 修正 #3: `guides/skill-usage-guide.md:209-214`

**現状**: シンボリックリンクの説明文で `../../skills/reviewing-*` 形式のパスを使用。

**修正方針**: シンボリックリンク先のパスを `<MARKETPLACE_ROOT>/skills/reviewing-*` のようなプレースホルダー表記に変更。旧レビュースキル名のリネームはUnit 002の責務のため、ここではパス形式のみ修正。

### 修正 #4: `migrate-detect.sh`

**29行目の現状**:

```bash
AIDLC_PLUGIN_ROOT="${AIDLC_PROJECT_ROOT}/skills/aidlc"
```

**修正方針**: パス解決戦略に従い、環境変数注入方式に変更:

```bash
AIDLC_PLUGIN_ROOT="${AIDLC_PLUGIN_ROOT:-${AIDLC_PROJECT_ROOT}/skills/aidlc}"
```

**130行目の現状**:

```bash
_starter_kit_root="$(cd "$AIDLC_PLUGIN_ROOT/../.." && pwd)"
```

**修正後**:

```bash
_starter_kit_root="$AIDLC_PROJECT_ROOT"
```

**理由**: `AIDLC_PLUGIN_ROOT` から `/../..` で逆方向にプロジェクトルートを算出しているが、`AIDLC_PROJECT_ROOT` が既に利用可能。直接使用で簡潔かつプラグイン環境でも正しく動作。

### 修正 #5: `migrate-cleanup.sh`

**26行目の現状**:

```bash
AIDLC_PLUGIN_ROOT="${AIDLC_PROJECT_ROOT}/skills/aidlc"
```

**108行目の使用箇所**:

```bash
template_path="${AIDLC_PLUGIN_ROOT}/templates/${path}"
```

**修正方針**: `AIDLC_PLUGIN_ROOT` はテンプレート参照に使用されている。配置構造への直接依存を避けるため、環境変数 `AIDLC_PLUGIN_ROOT` を外部注入として受け取る方式に変更する。

```bash
# AIDLC_PLUGIN_ROOT が環境変数で注入されていればそれを使用
# 未設定の場合はフォールバック: AIDLC_PROJECT_ROOT/skills/aidlc（従来互換）
AIDLC_PLUGIN_ROOT="${AIDLC_PLUGIN_ROOT:-${AIDLC_PROJECT_ROOT}/skills/aidlc}"
```

**エラーハンドリング**: `AIDLC_PLUGIN_ROOT` のテンプレートディレクトリが存在しない場合、既存のフォールバック処理（108-119行目の `template_path` 不在時のWARN出力 + broken symlink削除）がそのまま適用される。新たなエラー処理の追加は不要。

**設計判断**: 配置構造（`SCRIPT_DIR/../../aidlc`）に直接依存するのではなく、環境変数による外部注入を使用。呼び出し元（aidlc-migrateスキルのSKILL.md）が `AIDLC_PLUGIN_ROOT` を設定し、スクリプトはその契約に依存する。未設定時は従来のハードコードパスにフォールバックすることで後方互換性を維持。

### 修正 #6: `migrate-apply-config.sh:143,145`

**現状**:

```bash
grep -q '@docs/aidlc/prompts/\|@skills/aidlc/\|@\.aidlc/' "$ref_file"
grep -v '@docs/aidlc/prompts/\|@skills/aidlc/AGENTS\|@skills/aidlc/CLAUDE\|@\.aidlc/AGENTS\|@\.aidlc/CLAUDE' "$ref_file"
```

**修正方針**: これらのgrepパターンはv1/旧v2時代の参照行を検出・除去するためのもの。`@skills/aidlc/` はv1時代にAGENTS.mdやCLAUDE.mdに記載されていたパターンであり、これを検出して除去するのが目的。パターン自体はv1互換の検出用であるため、**修正不要**。

**結論**: 143,145行目は修正対象から除外。既存の動作が正当。

## 処理フロー概要

### Phase 1: Markdown修正フロー

1. `ai-tools.md` のリンク修正
2. `intro.md` のリンク修正
3. `skill-usage-guide.md` のパス記述修正

### Phase 2: スクリプト修正フロー

1. `migrate-detect.sh` の `AIDLC_PLUGIN_ROOT` 使用箇所修正
2. `migrate-cleanup.sh` の `AIDLC_PLUGIN_ROOT` 算出方法変更
3. `migrate-apply-config.sh` は修正不要（除外）

### Phase 3: 検証フロー

1. grep で `../../` パターンの残存確認（`scripts/tests/` 除外）
2. `bash -n` でスクリプトのシンタックスチェック
3. `AIDLC_PROJECT_ROOT` 未設定時のエラーハンドリング確認
4. `AIDLC_PLUGIN_ROOT` 注入時の動作確認（設定値がそのまま使用されること）
5. `AIDLC_PLUGIN_ROOT` 未設定時のフォールバック確認（`${AIDLC_PROJECT_ROOT}/skills/aidlc` が適用されること）

## 非機能要件への対応

### セキュリティ

- **要件**: ディレクトリトラバーサルが発生しないこと
- **対応策**: `AIDLC_PROJECT_ROOT` の検証は既存の `git rev-parse --show-toplevel` チェックで担保。新たにパス算出方式を追加しない

## 技術選定

- **言語**: Bash（既存スクリプトの修正）
- **ツール**: grep、bash -n（検証）

## 実装上の注意事項

- `migrate-apply-config.sh` の143,145行目は調査の結果、修正不要と判断。v1参照パターンの検出用であり、プラグイン環境非依存
- `migrate-cleanup.sh` の `AIDLC_PLUGIN_ROOT` は環境変数注入方式を正式方針とする。`SCRIPT_DIR` ベースの相対参照案は配置構造依存が残るため不採用
