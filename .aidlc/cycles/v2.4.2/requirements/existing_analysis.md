# 既存コードベース分析（v2.4.2 patch サイクル限定スコープ）

> Intent §「不明点と質問」Q&A の Reverse Engineering 範囲限定方針に従い、本サイクルで修正対象となるファイル群および直接の隣接スクリプト（`bin/post-merge-sync.sh`）に限定して解析する。プロジェクト全体構造解析は v2.4.x で確立済みのため省略（standard 深度の冗長回避）。

## ディレクトリ構造・ファイル構成

本サイクルで参照する主要ディレクトリ:

```text
.
├── bin/
│   ├── post-merge-sync.sh        # cycle/* + upgrade/* マージ後同期スクリプト（参考、変更対象外）
│   ├── update-version.sh          # バージョン更新（リリース時 Operations 7.1）
│   └── check-bash-substitution.sh # Bash $() 検出（CI / Operations 7.5 後）
├── skills/
│   ├── aidlc/
│   │   ├── steps/
│   │   │   └── operations/
│   │   │       ├── operations-release.md  # 修正対象 (#591)
│   │   │       └── 02-deploy.md           # 修正対象 (#591)
│   │   └── templates/
│   │       └── operations_progress_template.md  # 修正対象 (#591 [P2] / #585)
│   ├── aidlc-setup/
│   │   ├── SKILL.md                       # 修正対象 (#607 / #605)
│   │   └── steps/
│   │       ├── 01-detect.md
│   │       ├── 02-generate-config.md
│   │       └── 03-migrate.md              # 修正対象 (#607 / #605, §9 周辺)
│   └── aidlc-migrate/
│       ├── SKILL.md                       # 修正対象 (#607)
│       └── steps/
│           ├── 01-preflight.md
│           ├── 02-execute.md
│           └── 03-verify.md               # 修正対象 (#607, 最終ステップ相当)
└── .aidlc/
    └── cycles/
        └── v2.4.2/                        # 本サイクル成果物
```

ファイル命名規則:
- スキルステップ: `NN-<slug>.md`（2 桁数字プレフィックスで実行順序を表現）
- スクリプト: `<verb>-<noun>.sh`（小文字ハイフン区切り）

## アーキテクチャ・パターン

| 項目 | 値 | 根拠 |
|------|-----|------|
| プラグインモデル | `skills/<name>/SKILL.md` ベースの宣言的スキルプラグイン構成（v2.0.5 以降） | `.aidlc/rules.md` 「プラグイン前提の構成原則」セクション |
| ステップ参照解決 | スキルベースディレクトリ相対パス（`steps/`, `scripts/`, `templates/` 等） | aidlc SKILL.md「パス解決」セクション |
| 設定マージ | `.aidlc/config.toml` + `.aidlc/config.local.toml`（`.local` で上書き、配列は完全置換） | `guides/config-merge.md` |
| Bash スクリプト規約 | `set -euo pipefail` + 終了コード規約（0=成功、1=エラー、2=I/O 失敗 等） | `bin/post-merge-sync.sh` 冒頭、`guides/exit-code-convention.md` |
| 履歴記録 | `/write-history` スキル経由（`scripts/write-history.sh`、Operations post-merge ガード付き） | `skills/write-history/SKILL.md` |
| Operations 進捗管理 | `operations/progress.md` + 固定スロット 3 種（`release_gate_ready` / `completion_gate_ready` / `pr_number`、grammar v1） | `phase-recovery-spec.md` §5.3.5 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash 3.x+ / Markdown | `bin/post-merge-sync.sh` shebang `#!/usr/bin/env bash`、`set -euo pipefail` 利用 |
| フレームワーク | Claude Code Skills プラグインモデル | `skills/<name>/SKILL.md` の構造 |
| 主要ライブラリ | `gh` (GitHub CLI) / `dasel` (TOML 操作) / `git` | プリフライトチェック (`scripts/env-info.sh`) |
| 補助ツール | `markdownlint` (CI / Operations 7.5) / `codex` (AI レビュー、optional) | `.aidlc/config.toml` `rules.linting.enabled=true` / `rules.reviewing.tools=['codex']` |

## 依存関係

### 内部モジュール間（境界単位: スキル）

- **aidlc-setup** ⇨ **aidlc** (共通スキル経由でステップ実行)
- **aidlc-migrate** ⇨ **aidlc** (共通スキル経由でステップ実行)
- **aidlc** ⇨ **write-history** (履歴記録の委譲)
- **aidlc** ⇨ **reviewing-* スキル群** (AIレビュー実行)
- **bin/post-merge-sync.sh** は独立（スキル外、`bin/` 直下のユーティリティ）

### 外部ライブラリ依存

- `gh`: Issue / Milestone / PR 操作（Operations Phase / Inception Phase 02-preparation）
- `dasel`: `.aidlc/config.toml` 読み書き（`scripts/read-config.sh` / `write-config.sh`）
- `git`: ブランチ管理 / マージ後同期 / コミット履歴

### エントリポイントとデータフロー

- ユーザー操作: `/aidlc inception` / `/aidlc construction` / `/aidlc operations` / `/aidlc-setup` / `/aidlc-migrate`
- `aidlc` スキル → フェーズインデックス読み込み → ステップ詳細を on_demand ロード
- `aidlc-setup` / `aidlc-migrate` は独立スキルとして実行（`aidlc` から `additional_context` 透過委譲）

### 循環依存の有無

- `aidlc-setup` / `aidlc-migrate` から `aidlc` 内部リソースへの依存禁止（`.aidlc/rules.md` 「スキル間依存ルール」）
- ✓ 循環依存なし（公開呼び出し名 + SKILL.md 入出力引数のみ依存）

## 修正対象ファイルの現状把握（要点のみ）

### `skills/aidlc-setup/steps/03-migrate.md`（126 行、修正対象 #607 / #605）

- §9 = "Git コミット" セクション（現状: マイグレーション設定変更のコミットで処理終了）
- §9 直後に新規セクション（§9.5 または §10）として `chore/aidlc-v*-upgrade` 一時ブランチ削除案内 + マージ後 HEAD 同期手順を追加する想定
- `aidlc-setup` 起動経路: `/aidlc-setup` 単独 or `/aidlc setup` 経由委譲

### `skills/aidlc-migrate/steps/03-verify.md`（74 行、修正対象 #607）

- 最終ステップ相当（`01-preflight` → `02-execute` → `03-verify`）
- `chore/aidlc-v*-upgrade` ブランチ削除案内を追加する想定（migrate スキル独自フローで verify 後の post-merge 手順として配置）

### `skills/aidlc/steps/operations/operations-release.md`（288 行、修正対象 #591）

- §7.2〜§7.6 = リリース準備（バージョン更新 / CHANGELOG / progress.md 更新）
- 修正方針: [P1] 最小完成例 inline / [P3] 状態ラベル列挙 / [P4] §7.7 コミット対象列挙 を追記

### `skills/aidlc/steps/operations/02-deploy.md`（188 行、修正対象 #591）

- §7 デプロイ・リリースステップ概要
- 修正方針: [P3] 状態ラベル 5 値（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）を §7 冒頭または注記に明示

### `skills/aidlc/templates/operations_progress_template.md`（37 行、修正対象 #591 [P2] / #585）

- 現状: 固定スロット 3 行が同梱されていない
- 修正方針: `## 固定スロット（Operations 復帰判定用）` セクションを追加し、`<!-- fixed-slot-grammar: v1 -->` コメント + 3 種のキーを `key=` 形式で初期値空で記載

### `bin/post-merge-sync.sh`（変更対象外、参考情報）

- 対応プレフィックス: `cycle/*`, `upgrade/*`
- 未対応プレフィックス: `chore/aidlc-v*-upgrade`（Issue #607 の対象）
- 機能: 親リポ main pull / worktree detached HEAD 化 / マージ済みローカル + リモートブランチ削除（`--yes` で確認スキップ可）
- オプション: `--dry-run` / `--yes` / `--help`

## 特記事項

- **Issue #607 本文の表記揺れ**: Issue 本文では「`scripts/post-merge-cleanup.sh`」と記載されているが実際の実装は `bin/post-merge-sync.sh`。Intent 内では実態に合わせて `bin/post-merge-sync.sh` で統一済み。Issue 本文の更新は本サイクルではスコープ外（Issue close 時のコメントで補足するか、別 PR で訂正）
- **アップグレード一時ブランチ命名規則**: setup/migrate スキルが作成するアップグレード用ブランチは `chore/aidlc-v<version>-upgrade`（例: `chore/aidlc-v2.4.0-upgrade`）。Issue #607 が問題視するプレフィックスはこの形式
- **`.aidlc/config.toml.starter_kit_version` の挙動**: v2.4.0 以降の例外ルールにより、`bin/update-version.sh` は `starter_kit_version` を更新対象から除外する。書き換え経路は `aidlc-setup` / `aidlc-migrate` の正規フローに限定。Intent / 成功基準でこの除外を明示済み
- **Construction Phase の Unit 結合判断材料**: Unit A 案（setup/migrate 統合）vs B 案（分離）の判断は、`skills/aidlc-setup/steps/03-migrate.md` の §9 周辺と `skills/aidlc-migrate/steps/03-verify.md` の修正範囲が重複するか / それぞれ独立して読まれるかで決定。Construction Phase 着手時に再評価する
