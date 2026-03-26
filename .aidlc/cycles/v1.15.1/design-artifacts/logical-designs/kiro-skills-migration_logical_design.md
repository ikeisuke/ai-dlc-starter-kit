# 論理設計: Kiro標準スキル呼び出し対応

## 概要

`setup-ai-tools.sh` にKiroスキルのシンボリックリンクセットアップ機能を追加し、`aidlc.json` を標準スキル発見方式に更新する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

シェルスクリプトの関数分離パターン。共通のシンボリックリンク管理ロジックを共通関数に抽出し、各ツール固有の設定は呼び出し側で定義する。

## コンポーネント構成

### ファイル構成

```text
prompts/package/
├── bin/
│   └── setup-ai-tools.sh    ← 拡張対象
├── kiro/
│   └── agents/
│       └── aidlc.json        ← 更新対象
└── ...

prompts/
└── setup-prompt.md           ← ドキュメント更新対象
```

### コンポーネント詳細

#### setup-ai-tools.sh（拡張）

- **責務**: AIツール（Claude Code、KiroCLI）の設定ファイル・シンボリックリンクをセットアップ
- **依存**: `docs/aidlc/skills/` ディレクトリ、`docs/aidlc/kiro/agents/aidlc.json`
- **公開インターフェース**: シェルスクリプトとして直接実行

#### aidlc.json（更新）

- **責務**: KiroCLIエージェントの設定定義
- **依存**: なし（静的JSON設定）
- **変更内容**: `resources` から `skill://` 参照を削除

## スクリプトインターフェース設計

### setup-ai-tools.sh（変更後）

#### 概要

AIツールの設定ファイルとスキルシンボリックリンクを配置する。

#### 引数

なし（引数不要、プロジェクトルートから実行）

#### 成功時出力

```text
=== AI Tools Setup ===

[1/3] Setting up Claude Code skills...
Created: .claude/skills/reviewing-code → ../../docs/aidlc/skills/reviewing-code
...
Done: Claude skills setup complete

[2/3] Setting up KiroCLI skills...
Created: .kiro/skills/reviewing-code → ../../docs/aidlc/skills/reviewing-code
...
Done: KiroCLI skills setup complete

[3/3] Setting up KiroCLI agent...
Skipped: .kiro/agents/aidlc.json (already correct)
Done: KiroCLI agent setup complete

=== Setup Complete ===
```

- 終了コード: `0`

#### エラー時出力

```text
Error: docs/aidlc not found
```

- 終了コード: `1`

## 処理フロー概要

### 共通関数: setup_skill_symlinks()

**パラメータ**:
- `$1`: ターゲットディレクトリ（例: `.kiro/skills`）
- `$2`: ソースディレクトリ（例: `docs/aidlc/skills`）

**ステップ**:
1. ソースディレクトリの存在確認（不在なら警告してreturn）
2. ターゲットディレクトリの親を作成（例: `.kiro`）
3. ターゲットがシンボリックリンクの場合、削除してディレクトリ化（旧形式からの移行）
4. ターゲットディレクトリを作成
5. 壊れたシンボリックリンクを削除
6. ソースディレクトリ内の各サブディレクトリを列挙:
   - `SKILL.md` が存在しない場合: 警告してスキップ
   - リンクが存在しない場合: シンボリックリンクを作成
   - リンクが存在し正しい場合: スキップ
   - リンクが存在し不正な場合（シンボリックリンク）: 削除して再作成（自己修復）
   - リンクが存在しファイル/ディレクトリで置換不可な場合: 警告してスキップ

**関与するコンポーネント**: setup-ai-tools.sh

### setup_claude_skills()（リファクタリング後）

**ステップ**:
1. `setup_skill_symlinks ".claude/skills" "$AIDLC_DIR/skills"` を呼び出す

### setup_kiro_skills()（新規）

**ステップ**:
1. `setup_skill_symlinks ".kiro/skills" "$AIDLC_DIR/skills"` を呼び出す

### setup_kiro_agent()（変更なし）

既存のまま。

### メイン処理（変更）

```text
[1/3] Setting up Claude Code skills...  → setup_claude_skills
[2/3] Setting up KiroCLI skills...      → setup_kiro_skills（新規）
[3/3] Setting up KiroCLI agent...       → setup_kiro_agent
```

### aidlc.json 更新

`resources` 配列から `skill://docs/aidlc/skills/*/SKILL.md` を削除。

変更前:
```json
{
  "resources": [
    "file://AGENTS.md",
    "file://docs/aidlc/prompts/AGENTS.md",
    "skill://docs/aidlc/skills/*/SKILL.md"
  ]
}
```

変更後:
```json
{
  "resources": [
    "file://AGENTS.md",
    "file://docs/aidlc/prompts/AGENTS.md"
  ]
}
```

### setup-prompt.md 更新

セクション8.2.7のディレクトリ構成図に `.kiro/skills/` を追加:

```text
.kiro/skills/                            ← 実ディレクトリ（新規追加）
├── reviewing-code/          → symlink → ../../docs/aidlc/skills/reviewing-code/
├── reviewing-architecture/  → symlink → ../../docs/aidlc/skills/reviewing-architecture/
├── reviewing-security/      → symlink → ../../docs/aidlc/skills/reviewing-security/
├── upgrading-aidlc/         → symlink → ../../docs/aidlc/skills/upgrading-aidlc/
└── versioning-with-jj/      → symlink → ../../docs/aidlc/skills/versioning-with-jj/
```

## べき等性の保証

| 操作 | 初回実行 | 2回目以降 |
|------|---------|----------|
| ディレクトリ作成 | mkdir -p で作成 | 既存なのでスキップ |
| シンボリックリンク作成 | ln -s で作成 | 既存チェック → スキップ |
| 不正リンク修復 | 対象なし | unlink → 再作成で自己修復 |
| 壊れリンク削除 | 対象なし | 壊れたリンクがあれば削除 |
| SKILL.md不在スキップ | 警告出力 | 同じ警告出力 |

## 非機能要件への対応

### パフォーマンス

- シンボリックリンクのため性能影響なし

### セキュリティ

- 該当なし

### スケーラビリティ

- 動的列挙方式のため、新規スキル追加時にスクリプト変更不要

### 可用性

- 該当なし

## 技術選定

- **言語**: Bash（既存スクリプトと統一）
- **コマンド**: mkdir, ln, readlink, rm, basename, test（POSIX互換）

## 依存関係: 2層ソースモデル

このプロジェクトはメタ開発構造を持つため、ファイルソースが2層になる。

| 層 | パス | 役割 |
|----|------|------|
| 実装ソース | `prompts/package/` | 編集対象。変更はここで行う |
| 実行時ソース | `docs/aidlc/` | rsyncコピー。スクリプト実行時に参照される |

**同期ポイント**: Operations Phaseのrsync（`/upgrading-aidlc`）で `prompts/package/` → `docs/aidlc/` に反映される。

## 出力メッセージ規約

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| `Created:` | 新規作成成功 | `Created: .kiro/skills/reviewing-code → ...` |
| `Fixed:` | 不正リンクを修復 | `Fixed: .kiro/skills/reviewing-code (target corrected)` |
| `Skipped:` | 既存で正しいためスキップ | `Skipped: .kiro/skills/reviewing-code (already correct)` |
| `Removed:` | 壊れたリンクを削除 | `Removed: .kiro/skills/old-skill (broken symlink)` |
| `Warning:` | 置換不可な競合 / SKILL.md不在 | `Warning: .kiro/skills/foo (exists as directory/file)` |
| `Error:` | 致命エラー | `Error: docs/aidlc not found` |
| `Done:` | セクション完了 | `Done: KiroCLI skills setup complete` |

**終了コード方針**: `Error:` 出力時のみ非0（exit 1）。`Warning:` は処理続行。

## 実装上の注意事項

- `prompts/package/` を編集する（メタ開発ルール）
- 相対パスの計算: `.kiro/skills/` から `docs/aidlc/skills/` への相対パスは `../../docs/aidlc/skills/`
- `setup_skill_symlinks` の共通関数化により、既存の `setup_claude_skills` もリファクタリングする
