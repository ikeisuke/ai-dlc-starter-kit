# 論理設計: skills構成変更

## 変更対象ファイル

1. `prompts/setup-prompt.md`
2. `prompts/package/guides/skill-usage-guide.md`

## 1. setup-prompt.md の変更

### 変更箇所: セクション 8.2.2.4

**変更前**: rsync による同期

```bash
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/skills/ \
  docs/aidlc/skills/
```

**変更後**: シンボリックリンクによる配置

```bash
# 1. skills ディレクトリ作成（実ディレクトリ）
mkdir -p docs/aidlc/skills

# 2. 各スキルをシンボリックリンクとして作成
for skill in codex claude gemini; do
  SKILL_PATH="docs/aidlc/skills/${skill}"
  TARGET_PATH="[スターターキットパス]/prompts/package/skills/${skill}"

  if [ ! -e "$SKILL_PATH" ]; then
    # 新規作成
    ln -s "$TARGET_PATH" "$SKILL_PATH"
  elif [ -L "$SKILL_PATH" ]; then
    # シンボリックリンクの場合: ターゲット確認
    # 同じターゲット → スキップ
    # 異なるターゲット → ユーザーに確認
  else
    # 実ディレクトリの場合: ユーザーに確認
  fi
done
```

### セクションタイトルの変更

**変更前**: `#### 8.2.2.4 スキルファイルの同期（rsync）`

**変更後**: `#### 8.2.2.4 スキルファイルのシンボリックリンク作成`

### 削除する内容

- rsync 関連のコマンドと説明
- ドライラン確認フロー（シンボリックリンク方式では不要）

### 追加する内容

- シンボリックリンク作成のロジック
- 既存パス処理（シンボリックリンク/実ディレクトリ）
- メタ開発モードでの相対パス計算

## 2. skill-usage-guide.md の変更

### 追加セクション: プロジェクト独自スキルの追加

```markdown
## プロジェクト独自スキルの追加

`docs/aidlc/skills/` ディレクトリに独自のスキルを追加できます。

### 追加手順

1. `docs/aidlc/skills/` 配下にディレクトリを作成
2. `SKILL.md` ファイルを作成

### ディレクトリ構成例

\```
docs/aidlc/skills/
├── codex/   → (シンボリックリンク、編集不可)
├── claude/  → (シンボリックリンク、編集不可)
├── gemini/  → (シンボリックリンク、編集不可)
└── my-review/           ← プロジェクト独自スキル
    └── SKILL.md
\```

### 命名規則

- `codex`, `claude`, `gemini` はスターターキット予約名のため使用不可
- 推奨: プロジェクト名やチーム名をプレフィックスに（例: `myproject-lint`）

### アップグレード時の挙動

シンボリックリンク方式のため、プロジェクト独自スキルはアップグレードの影響を受けません。
```

## パス計算ロジック

### メタ開発モード（prompts/package/ が存在）

相対パスを使用:
```bash
# docs/aidlc/skills/codex/ → ../../../prompts/package/skills/codex/
ln -s "../../../prompts/package/skills/${skill}" "docs/aidlc/skills/${skill}"
```

### 通常利用モード

絶対パスまたは ghq パスを使用:
```bash
# ghq 利用時
STARTER_KIT_PATH="$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit"
ln -s "${STARTER_KIT_PATH}/prompts/package/skills/${skill}" "docs/aidlc/skills/${skill}"
```
