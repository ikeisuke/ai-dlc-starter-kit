# Unit 6: ファイル構成整理 - 実装計画

## 概要
docs/aidlc/ をスターターキット由来のファイルのみにし、rsync --delete で完全同期可能にする

## 背景・目的
- **現状**: `docs/aidlc/` にユーザー固有ファイル（project.toml, additional-rules.md）が混在
- **問題**: rsync --delete でスターターキットと同期すると、ユーザー固有ファイルが削除される
- **解決**: ユーザー固有ファイルを `docs/aidlc/` の外に移動し、完全同期可能にする

## 変更後のファイル構成
```
docs/
├── aidlc.toml              # プロジェクト設定（旧 docs/aidlc/project.toml）
├── aidlc/                  # rsync --delete で完全同期可能
│   ├── prompts/
│   └── templates/
└── cycles/
    ├── rules.md            # プロジェクト固有ルール（移動・リネーム）
    ├── operations.md
    ├── backlog.md
    └── v1.2.2/
```

---

## 実装内容

### 1. aidlc.toml への移行（setup-init.md）
- `docs/aidlc/project.toml` → `docs/aidlc.toml` に変更
- `starter_kit_version` フィールドを追加（version.txtの内容を統合）
- version.txt は作成しない

**変更箇所**:
- モード判定: `docs/aidlc/project.toml` → `docs/aidlc.toml`
- project.toml 生成セクションのパス変更
- バージョン情報の統合

### 2. additional-rules.md → rules.md への移動・リネーム
- `docs/aidlc/prompts/additional-rules.md` → `docs/cycles/rules.md`

**変更ファイル**:
- `prompts/setup-init.md` - コピー先パスの修正
- `prompts/package/prompts/construction.md` - 参照パスの修正
- `prompts/package/prompts/inception.md` - 参照パスの修正
- `prompts/package/prompts/operations.md` - 参照パスの修正

### 3. setup-prompt.md のパス参照修正
- `docs/aidlc/project.toml` → `docs/aidlc.toml`
- `docs/aidlc/version.txt` → `docs/aidlc.toml` の `starter_kit_version`

### 4. 既存プロジェクトの移行処理（setup-init.md）

アップグレード時に旧ファイルが存在する場合、自動的に移動し通知する。

**移行処理**:
```bash
# 1. project.toml の移行
if [ -f docs/aidlc/project.toml ] && [ ! -f docs/aidlc.toml ]; then
  mv docs/aidlc/project.toml docs/aidlc.toml
  echo "MIGRATED: docs/aidlc/project.toml → docs/aidlc.toml"
fi

# 2. additional-rules.md の移行
if [ -f docs/aidlc/prompts/additional-rules.md ] && [ ! -f docs/cycles/rules.md ]; then
  mv docs/aidlc/prompts/additional-rules.md docs/cycles/rules.md
  echo "MIGRATED: docs/aidlc/prompts/additional-rules.md → docs/cycles/rules.md"
fi

# 3. version.txt の情報を aidlc.toml に統合後、削除
if [ -f docs/aidlc/version.txt ]; then
  # バージョン情報を aidlc.toml に追記（存在する場合）
  rm docs/aidlc/version.txt
  echo "REMOVED: docs/aidlc/version.txt (バージョン情報は aidlc.toml に統合)"
fi
```

**移行通知メッセージ**:
```
ファイル構成の変更に伴い、以下のファイルを移行しました：

| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | docs/aidlc.toml |
| docs/aidlc/prompts/additional-rules.md | docs/cycles/rules.md |
| docs/aidlc/version.txt | （削除: aidlc.toml に統合） |

これにより、docs/aidlc/ ディレクトリはスターターキットと完全同期可能になりました。
```

---

## 対象ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | aidlc.toml移行、パス修正、version.txt廃止、移行処理追加 |
| `prompts/setup-prompt.md` | パス参照修正 |
| `prompts/package/prompts/construction.md` | rules.mdパス修正 |
| `prompts/package/prompts/inception.md` | rules.mdパス修正 |
| `prompts/package/prompts/operations.md` | rules.mdパス修正 |
| `prompts/package/prompts/additional-rules.md` | rules.mdにリネーム |

---

## ビルド・テスト
- このUnitはドキュメント（プロンプト）の修正のみ
- ビルド・テストは不要

---

## 注意事項
- このUnit完了後、Unit 3（rsync対応）を実施可能になる
- 既存プロジェクトの移行手順はsetup-init.mdの後方互換性セクションで対応

---

## 作成日
2025-12-06
