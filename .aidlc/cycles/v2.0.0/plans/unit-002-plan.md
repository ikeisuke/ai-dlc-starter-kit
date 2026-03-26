# Unit 002: リポジトリ構造基盤 - 計画

## 概要

`skills/` ディレクトリをリポジトリルートに作成し、既存スキルを移動、marketplace.jsonを更新して、v2.0.0のスキルベース配布に適したリポジトリ構造を構築する。

## レイヤー定義（正本・ミラー・リンク層）

v2.0.0では以下の3層構造を採用する：

| レイヤー | パス | 役割 | 更新責務 |
|---------|------|------|---------|
| **正本** | `skills/` | スキルのソースコード。直接編集対象 | 開発者が直接編集 |
| **互換ミラー** | `docs/aidlc/skills/` | v1系互換のrsyncコピー。sync-package.shの同期元を `skills/` に変更 | sync-package.shが自動同期 |
| **消費者リンク層** | `.claude/skills/` | Claude Codeが参照するシンボリックリンク。`skills/` を直接指す | セットアップスクリプトが管理 |

**削除条件**: `docs/aidlc/skills/` はUnit 010（クリーンアップ・マイグレーション）で削除を検討。v1互換が不要になった時点で廃止。

**v1からの変更**: `prompts/package/skills/` → `skills/` に移動。`prompts/package/skills/` は本Unitで削除。

## ディレクトリ命名規約

| パターン | 用途 | 例 |
|---------|------|-----|
| `skills/<slug>/` | 独立スキル（既存6スキル） | `skills/reviewing-code/` |
| `skills/aidlc/` | AI-DLCフェーズスキルの名前空間 | `skills/aidlc/SKILL.md` |

- `skills/aidlc/` はUnit 004以降で `SKILL.md` と `steps/` を配置する名前空間ディレクトリ
- `steps/` はスキル内部実装（公開契約ではない）
- marketplace.jsonの参照単位は `./skills/<slug>` または `./skills/aidlc`

## 現状

- **既存スキル配置**: `prompts/package/skills/` （ソース）→ `docs/aidlc/skills/`（rsyncコピー）→ `.claude/skills/`（シンボリックリンク）
- **対象スキル**: reviewing-code, reviewing-architecture, reviewing-inception, reviewing-security, squash-unit, aidlc-setup
- **marketplace.json**: `.claude-plugin/marketplace.json` が `./prompts/package/skills/` を参照

## 依存先インベントリ

旧パス `prompts/package/skills/` または `docs/aidlc/skills/` を参照している現行ファイル（過去サイクルのドキュメントを除く）：

| ファイル | 参照パス | 本Unit対応 |
|---------|---------|-----------|
| `.claude-plugin/marketplace.json` | `./prompts/package/skills/*` | **更新** |
| `.claude/skills/*` (symlinks) | `../../docs/aidlc/skills/*` | **更新**（`../../skills/*` へ） |
| `.claude/settings.json` | `prompts/package/skills/*` | **確認**（permissions設定） |
| `prompts/setup-prompt.md` | `prompts/package/skills/` | スコープ外（Unit 008 Setup） |
| `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` | 自身のパス | 移動で自動解決 |
| `prompts/package/skills/aidlc-setup/SKILL.md` | `docs/aidlc/skills/` | スコープ外（Unit 003でスクリプト更新） |
| `prompts/package/prompts/common/review-flow.md` | `prompts/package/skills/` | スコープ外（Unit 004で更新） |
| `prompts/package/guides/skill-usage-guide.md` | `docs/aidlc/skills/` | スコープ外（後続Unit） |
| `prompts/package/bin/setup-ai-tools.sh` | `docs/aidlc/skills/` | スコープ外（Unit 003） |
| `prompts/package/kiro/agents/aidlc.json` | パス参照 | スコープ外 |

**スコープ外の対応方針**: Unit 002は「配置移動のみ」が境界。スクリプト・ガイド内のパス参照更新はUnit 003（シェルスクリプト移行）以降で実施。本Unitでは `.claude/skills/` symlink と `marketplace.json` が正しく `skills/` を指すことで、実行時の動作を維持する。

## 変更対象ファイル

### 新規作成

- `skills/` ディレクトリ構造
- `skills/aidlc/` ディレクトリ骨格（後続Unit用、scripts/ と steps/ を含む）

### 移動

- `prompts/package/skills/reviewing-code/` → `skills/reviewing-code/`
- `prompts/package/skills/reviewing-architecture/` → `skills/reviewing-architecture/`
- `prompts/package/skills/reviewing-inception/` → `skills/reviewing-inception/`
- `prompts/package/skills/reviewing-security/` → `skills/reviewing-security/`
- `prompts/package/skills/squash-unit/` → `skills/squash-unit/`
- `prompts/package/skills/aidlc-setup/` → `skills/aidlc-setup/`

### 更新

- `.claude-plugin/marketplace.json` - skillsパスを `./skills/` 配下に更新
- `.claude/skills/` - シンボリックリンクのターゲットを `../../skills/*` に更新
- `.claude/settings.json` - permissions内のパス参照を確認・更新

### 整理

- `prompts/package/skills/` - 移動元ディレクトリの削除
- `docs/aidlc/skills/` - sync-package.shの同期元を `skills/` に変更（互換ミラーとして維持）

## 実装計画

1. `skills/` ディレクトリをリポジトリルートに作成
2. `skills/aidlc/` ディレクトリ骨格を作成（scripts/, steps/ を含む）
3. 既存スキル6つを `prompts/package/skills/` から `skills/` へ移動（git mv）
4. `.claude-plugin/marketplace.json` のskillsパスを更新
5. `.claude/skills/` のシンボリックリンクを `skills/` 配下へ更新
6. `.claude/settings.json` のpermissions内パス参照を確認・更新
7. `docs/aidlc/skills/` の同期元変更（sync-package.sh更新）
8. 動作確認

## 完了条件チェックリスト

- [ ] `skills/` ディレクトリ構造が作成されている
- [ ] 既存スキル（reviewing-code, reviewing-architecture, reviewing-inception, reviewing-security, squash-unit, aidlc-setup）が `skills/` に移動されている
- [ ] `skills/aidlc/` ディレクトリ骨格が作成されている
- [ ] `.claude-plugin/marketplace.json` が `./skills/` を参照している
- [ ] `.claude/skills/` シンボリックリンクが `skills/` を指している
- [ ] `.claude/settings.json` の旧パス参照が更新されている
- [ ] `marketplace.json` のパス解決が正しいこと（スキルディレクトリが存在すること）
- [ ] 旧パス `prompts/package/skills/` が削除されていること
