# 論理設計: リポジトリ構造基盤

## 概要

既存スキル6つを `prompts/package/skills/` から `skills/` へ移動し、正本と2つの独立消費パスを確立する。

## 構造方針

```text
skills/ (正本)
├──→ .claude/skills/ (SymlinkLayer: ローカルClaude Code消費用、直接リンク)
└──→ docs/aidlc/skills/ (MirrorLayer: v1外部プロジェクト互換、sync-package.sh同期)
```

SymlinkLayerとMirrorLayerはチェーンではなく、独立して正本を参照する。

## コンポーネント構成

### 1. skills/ ディレクトリ（正本）

```text
skills/
├── reviewing-code/
│   ├── SKILL.md
│   └── references/
├── reviewing-architecture/
│   ├── SKILL.md
│   └── references/
├── reviewing-inception/
│   ├── SKILL.md
│   └── references/
├── reviewing-security/
│   ├── SKILL.md
│   └── references/
├── squash-unit/
│   ├── SKILL.md
│   └── references/
├── aidlc-setup/
│   ├── SKILL.md
│   ├── bin/
│   └── references/
└── aidlc/                    ← 骨格のみ（後続Unit用）
    ├── scripts/              ← Unit 003で移行
    └── steps/                ← Unit 004-008で配置
```

### 2. .claude/skills/ シンボリックリンク（消費者リンク層）

正本 `skills/` を直接参照する。

**変更前**:

```text
.claude/skills/reviewing-code -> ../../docs/aidlc/skills/reviewing-code
```

**変更後**:

```text
.claude/skills/reviewing-code -> ../../skills/reviewing-code
```

相対パスの基点: `.claude/skills/` → `../../` でリポジトリルートへ → `skills/<slug>`

### 3. .claude-plugin/marketplace.json

**変更前**:

```json
"skills": [
  "./prompts/package/skills/aidlc-setup",
  "./prompts/package/skills/reviewing-architecture",
  "./prompts/package/skills/reviewing-code",
  "./prompts/package/skills/reviewing-inception",
  "./prompts/package/skills/reviewing-security",
  "./prompts/package/skills/squash-unit"
]
```

**変更後**:

```json
"skills": [
  "./skills/aidlc-setup",
  "./skills/reviewing-architecture",
  "./skills/reviewing-code",
  "./skills/reviewing-inception",
  "./skills/reviewing-security",
  "./skills/squash-unit"
]
```

### 4. .claude/settings.json パーミッション更新

**Unit 002に含める理由**: パーミッション設定はスキルのbin実行の許可ルール。ディレクトリ移動後、旧パスのパーミッションでは新パスのスクリプト実行が許可されないため、配置移動と不可分。

**変更が必要な行**:

- `Bash(prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh:*)` → `Bash(skills/aidlc-setup/bin/aidlc-setup.sh:*)`
- `Bash(docs/aidlc/skills/*/bin/*)` → `Bash(skills/*/bin/*)`

### 5. docs/aidlc/skills/ 互換ミラーの扱い

**方針**: v1外部プロジェクト互換のために維持する。廃止はUnit 010で検討。

sync-package.shは `prompts/package/` → `docs/aidlc/` の全体同期。スキルが `skills/` に移動した後：

- `prompts/package/skills/` は削除される → sync-package.shの同期で `docs/aidlc/skills/` は同期元を失う
- **本Unitでの対応**: sync-package.shの同期元変更はUnit 003のスコープ。本Unitでは `docs/aidlc/skills/` の既存内容をそのまま残す（次回sync-package.sh実行まで旧内容が維持される）
- **注意**: Unit 002完了後、Unit 003でsync-package.shを更新するまで、`--delete` オプション付きでsync-package.shを実行しないこと（`prompts/package/skills/` が削除済みのため、`docs/aidlc/skills/` の内容が消失する）
- **Unit 003での対応**: sync-package.shに `skills/` → `docs/aidlc/skills/` の同期を追加、または別の同期手段を実装

## 実装手順の詳細

### 手順1: skills/ ディレクトリ作成

```bash
mkdir -p skills/aidlc/scripts skills/aidlc/steps
```

### 手順2: 既存スキルの移動（git mv）

```bash
git mv prompts/package/skills/reviewing-code skills/reviewing-code
git mv prompts/package/skills/reviewing-architecture skills/reviewing-architecture
git mv prompts/package/skills/reviewing-inception skills/reviewing-inception
git mv prompts/package/skills/reviewing-security skills/reviewing-security
git mv prompts/package/skills/squash-unit skills/squash-unit
git mv prompts/package/skills/aidlc-setup skills/aidlc-setup
```

移動後、`prompts/package/skills/` が空であれば削除。

### 手順3: marketplace.json更新

パス参照を `./prompts/package/skills/<slug>` → `./skills/<slug>` に変更。

### 手順4: シンボリックリンク更新

既存リンクを削除して正本への直接リンクを再作成:

```bash
cd .claude/skills
rm -f reviewing-code reviewing-architecture reviewing-inception reviewing-security squash-unit aidlc-setup
ln -s ../../skills/reviewing-code reviewing-code
ln -s ../../skills/reviewing-architecture reviewing-architecture
ln -s ../../skills/reviewing-inception reviewing-inception
ln -s ../../skills/reviewing-security reviewing-security
ln -s ../../skills/squash-unit squash-unit
ln -s ../../skills/aidlc-setup aidlc-setup
```

### 手順5: settings.json更新

パーミッション内の旧パス参照を新パスに更新。

### 手順6: 検証

1. 各シンボリックリンクのターゲットが存在すること
2. marketplace.jsonの全パスが実在すること
3. SKILL.mdが各スキルディレクトリに存在すること
4. settings.jsonのパーミッションが新パスを参照していること

## エラーハンドリング

- git mvの失敗: コミット済みの変更をリバートし、手動対応
- シンボリックリンク作成の失敗: リンク先ディレクトリの存在を再確認

## 後続Unitへの影響

- **Unit 003**: `skills/aidlc/scripts/` にシェルスクリプトを移行。sync-package.shの同期元を `skills/` に変更
- **Unit 004-008**: `skills/aidlc/steps/` にフェーズステップを配置
- **Unit 010**: `docs/aidlc/skills/` 互換ミラーの廃止を検討（v1互換不要時）
