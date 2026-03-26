# 論理設計: アップグレードパスフォールバック

## 概要

setup-prompt.mdとaidlc-setup.shのスクリプトパス解決にフォールバック機能を追加する。

## コンポーネント図

```text
┌─────────────────────────┐
│   setup-prompt.md       │ ドキュメント（AIへの指示）
│   セクション8.2.7       │
│   3パターン記載方式     │
└────────────┬────────────┘
             │ 参照
             ▼
┌─────────────────────────┐
│   aidlc-setup.sh        │ オーケストレーション
│   Step 7                │
│   ┌───────────────────┐ │
│   │ ScriptPathResolver│ │
│   │ primary → fallback│ │
│   └───────────────────┘ │
└────────────┬────────────┘
             │ 実行
     ┌───────┴───────┐
     ▼               ▼
┌──────────┐  ┌──────────────┐
│ docs/    │  │ prompts/     │
│ aidlc/   │  │ package/     │
│ bin/     │  │ bin/         │
│ (sync後) │  │ (フォールバック) │
└──────────┘  └──────────────┘
```

## 変更詳細

### 1. setup-prompt.md セクション8.2.7

**現状**: `docs/aidlc/bin/setup-ai-tools.sh` のみ記載

**変更後**: 他スクリプト参照（resolve-starter-kit-path.sh, sync-package.sh等）と同一の3パターン記載方式に統一

```text
# スクリプトで実行
# メタ開発モード: prompts/package/bin/setup-ai-tools.sh
# アップグレードモード（同期済み）: docs/aidlc/bin/setup-ai-tools.sh
# 初回セットアップ: [スターターキットパス]/prompts/package/bin/setup-ai-tools.sh
```

### 2. aidlc-setup.sh Step 7

**現状** (L372-390):

```bash
SETUP_AI_TOOLS="docs/aidlc/bin/setup-ai-tools.sh"
if [[ ! -x "$SETUP_AI_TOOLS" ]]; then
    echo "warn:setup-ai-tools-not-found"
```

**変更後**:

```bash
SETUP_AI_TOOLS="docs/aidlc/bin/setup-ai-tools.sh"
SETUP_AI_TOOLS_FALLBACK="${STARTER_KIT_ROOT}/prompts/package/bin/setup-ai-tools.sh"

if [[ -x "$SETUP_AI_TOOLS" ]]; then
    # 同期済み環境: primary使用
elif [[ -x "$SETUP_AI_TOOLS_FALLBACK" ]]; then
    # フォールバック: スターターキット側を使用
    SETUP_AI_TOOLS="$SETUP_AI_TOOLS_FALLBACK"
    echo "info:setup-ai-tools-fallback:${SETUP_AI_TOOLS}"
else
    # 両方不在
    echo "warn:setup-ai-tools-not-found"
fi
```

## インターフェース定義

### aidlc-setup.sh 追加出力

| 出力 | 意味 |
|------|------|
| `info:setup-ai-tools-fallback:{path}` | フォールバックパスを使用した |
| `warn:setup-ai-tools-not-found` | 両方不在（既存出力、変更なし） |
