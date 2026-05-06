# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
ai-dlc-starter-kit/
├── skills/aidlc/                # AI-DLC コアスキル（プラグイン）
│   ├── SKILL.md                 # オーケストレーター本体
│   ├── version.txt              # スキルバージョン（2.5.1）
│   ├── steps/
│   │   ├── common/              # 共通ステップ（review-flow / commit-flow / 等）
│   │   ├── inception/           # Inception Phase ステップ
│   │   ├── construction/        # Construction Phase ステップ
│   │   └── operations/          # Operations Phase ステップ（02-deploy.md / operations-release.md / 04-completion.md）
│   ├── scripts/
│   │   ├── lib/                 # 内部 lib（predecessor-issue.sh / retrospective-issue.sh / 等）
│   │   ├── retrospective-*.sh   # 振り返り関連ツール（retrospective-resend.sh はトップレベル）
│   │   └── squash-unit.sh       # Construction Unit 完了時 squash
│   ├── agents/                  # 内蔵エージェント定義
│   ├── templates/               # ドキュメントテンプレート
│   └── config/                  # defaults.toml / retrospective-schema.yml
├── skills/reviewing-*           # レビュー専用スキル群（construction/inception/operations）
├── bin/                         # CI 用スクリプト（check-skill-references.sh / check-bash-substitution.sh / post-merge-sync.sh / 等）
├── .github/workflows/           # CI ワークフロー（pr-check.yml / skill-reference-check.yml / migration-tests.yml / auto-tag.yml）
├── .aidlc/cycles/v2.5.2/        # 本サイクル成果物（本サイクルで作成）
└── .worktree/dev/               # 開発用 worktree（メタ開発のメインワークスペース）
```

## アーキテクチャ・パターン

| 項目 | 値 | 根拠 |
|------|-----|------|
| アーキテクチャ | スキルプラグイン構成（v2.0.5 以降） | `.aidlc/rules.md` L28-31 / `skills/aidlc/SKILL.md` |
| パス解決 | スキルベース相対パス（スキル実行時） / プロジェクトルート相対（メタ開発時、META-001 例外） | `.aidlc/rules.md` L23-31 / SKILL.md「パス解決」 |
| レビュースキル分離 | レビュー種別ごとに独立スキル（reviewing-construction-code / -design / -plan / -integration、reviewing-inception-{intent,stories,units}、reviewing-operations-{deploy,premerge}） | `.aidlc/rules.md` L218-227 |
| シェル lib | `scripts/lib/*.sh` を `source` する `BASH_SOURCE` 自己解決パターン | `scripts/lib/predecessor-issue.sh` L31 / 等 |
| CI 構造チェック | `bin/check-*.sh` を `.github/workflows/*.yml` から呼び出し | `bin/check-skill-references.sh`, `bin/check-bash-substitution.sh` / `.github/workflows/skill-reference-check.yml` |
| Squash 統合 | Construction Unit 完了時のみ実装。Operations Phase 7.12-7.13 間は未実装（#639） | `scripts/squash-unit.sh` / `steps/common/commit-flow.md` L89 / `steps/operations/operations-release.md` L120-126 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash 4+（`#!/usr/bin/env bash`） | `scripts/**/*.sh` |
| TOML パーサ | dasel v3 | `scripts/read-config.sh` |
| GitHub CLI | `gh` v2 系（OAuth スコープ要求あり） | `scripts/check-open-issues.sh` / `scripts/milestone-ops.sh` |
| テストフレームワーク | BATS（Bash Automated Testing System） | `bin/tests/`, `tests/**/*.bats` 想定 |
| CI | GitHub Actions | `.github/workflows/*.yml` |
| エディタ統合 | Claude Code（CLI ハーネス） | `CLAUDE.md` / `.claude/settings.json` |

## 依存関係

### 内部モジュール間（境界単位: ディレクトリ）

- `skills/aidlc/scripts/*.sh` → `skills/aidlc/scripts/lib/*.sh`（多重 source ガード `__AIDLC_*_LOADED` 採用）
- `skills/aidlc/steps/**/*.md` → `skills/aidlc/scripts/*.sh`（ステップが Bash コマンドとして呼び出し）
- `skills/reviewing-*/SKILL.md` → `skills/reviewing-common/`（共通ロジック / `bin/sync-reviewing-common.sh` で同期）
- `bin/check-*.sh` ← `.github/workflows/*.yml`（CI 起点）
- `bin/check-*.sh` ← `scripts/squash-unit.sh`（Unit 完了時。**現状は一部のみ統合**：本サイクル #636 の対象）

### 外部ライブラリの依存関係

- `dasel`（TOML 読み取り）
- `gh`（GitHub CLI）
- `git`
- `curl`（リモートバージョン確認）
- 標準 POSIX ツール（grep, sed, awk, jq）

### エントリポイントとデータフローの概要

- スキル起点: `/aidlc <action>` → `skills/aidlc/SKILL.md` → 共通初期化 → フェーズステップ（`steps/<phase>/index.md` 経由）
- レビュー起点: `Skill skill="reviewing-<stage>"` → `skills/reviewing-<stage>/SKILL.md` → `skills/reviewing-common/`
- CI 起点: `git push` → GitHub Actions → `bin/check-*.sh`

### 循環依存の有無

確認できる範囲では循環依存なし。`scripts/lib/` の lib 間 source 関係は `predecessor-issue.sh → retrospective-issue.sh` の単方向（多重 source ガード `__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED` で保護）。

## 本サイクルで触る主要ファイル（事前マッピング）

| Issue | 主な対象ファイル |
|-------|----------------|
| #638 AIDLC_PROJECT_ROOT 横断 | `scripts/retrospective-resend.sh` L87（cwd 相対の `SPOOL_PATH` を AIDLC_PROJECT_ROOT 対応化） / `scripts/lib/predecessor-issue.sh` L181, L248-249（`compat_path` / `spool_path` の AIDLC_PROJECT_ROOT 対応化） / 共通 helper を `scripts/lib/` 配下に新設 / `scripts/lib/retrospective-issue.sh` L505-510 の既存 `__retro_spool_path` を helper 利用へ移行（producer 側の整合確保） |
| #639 Operations 7.12 squash | `steps/operations/operations-release.md` L116-126（7.12 と 7.13 の間に Squash サブステップ挿入）/ `steps/common/commit-flow.md`（Squash 統合フローの再利用）/ `scripts/operations-release.sh`（pre-flight check との整合確認） |
| #635 review-flow 5R 化 | `steps/common/review-flow.md`（round 上限 / 完了条件）/ reviewing-construction-{code,design,plan,integration} と reviewing-operations-{deploy,premerge} の各 SKILL.md（同期）/ defer 自動 Issue 化フロー / Round 4+ 新領域指摘の自動 backlog 化フロー |
| #636 CI 構造チェック強化 | `bin/check-test-isolation.sh`（新規）/ `scripts/squash-unit.sh`（PostUnitComplete hook 統合）/ `.github/workflows/pr-check.yml` または `skill-reference-check.yml`（CI 反映）/ 既存 `bin/tests/` の自己テスト追加 |

## 特記事項

- **メタ開発の自己適用**: review-flow 5R 化（#635）と CI 構造チェック強化（#636）は本サイクル自身の review / Unit 完了に対しても効力を持つ（Unit ID 順序の依存関係に注意）
- **`AIDLC_PROJECT_ROOT` の既存実装**: `__retro_spool_path`（producer 側、`retrospective-issue.sh` L505-510）は既に対応済み。consumer 側（`retrospective-resend.sh` / `predecessor-issue.sh`）の対応が #638 のスコープ
- **依存テスト**: `predecessor-issue.sh` の zsh 動作不具合（`source` 時の `BASH_SOURCE` 解決失敗）を本サイクル開始時に検証済（明示的 `bash -c` で動作）。横断 helper はこの観点も考慮する
- **Operations Squash の整合**: `merge_method=merge`（プロジェクト設定）と `squash_enabled=true`（同上）の組み合わせで運用しているため、Operations 7.12 squash サブステップは「PR マージ自体は merge commit を作るが、その内部の中間コミット群は事前 squash する」設計が必要（merge_method=squash への変更ではない）
