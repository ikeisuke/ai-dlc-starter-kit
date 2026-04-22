# 既存コードベース分析（v2.4.0 影響範囲限定ミニマル）

本ドキュメントは v2.4.0 サイクルの影響範囲に限定したミニマル分析である。フル4セクション網羅は本サイクル外（メタ開発リポジトリで構造既知のため、Issue 本文と本ドキュメントを合わせて影響範囲を補完する位置づけ）。

## ディレクトリ構造・ファイル構成（影響範囲）

`ai-dlc-starter-kit` は v2.0.5 以降スキルプラグイン構成。本サイクルが触れるのは以下に限定する。

| パス | 役割 | 本サイクルでの主な変更 |
|------|------|---------------------|
| `skills/aidlc/steps/operations/{01-setup,02-deploy,03-release,04-completion,operations-release}.md` | Operations Phase ステップファイル | Unit A: Milestone close・紐付け確認・不在時 fallback 作成手順を組み込み（通常作成責務は Unit B のみ） |
| `skills/aidlc/steps/inception/{01-setup,02-preparation,03-intent,04-stories-units,05-completion}.md` | Inception Phase ステップファイル | Unit B: サイクルバージョン確定時の Milestone 作成ステップ追加、サイクルラベル付与停止判断 |
| `skills/aidlc/steps/inception/index.md` / `steps/operations/index.md` | フェーズインデックス（ステップ読み込み契約） | Unit B / A の追加ステップ反映 |
| `skills/aidlc/scripts/cycle-label.sh` / `label-cycle-issues.sh` | サイクルラベル作成・付与スクリプト | Unit B: deprecated として残置（CHANGELOG / スクリプト先頭コメントで非推奨明記、物理削除は Unit E（後続サイクル）） |
| `skills/aidlc/scripts/pr-ops.sh:216-245` | PR Ready 化補助スクリプト | #588: `closes_list[@]` / `relates_list[@]` 空配列展開を `set -u` 環境で安全化 |
| `bin/update-version.sh:14, 87, 109-114, 138, 151, 163, 178, 185` | リリース時バージョン一括更新スクリプト | #596: `.aidlc/config.toml.starter_kit_version` を更新対象から除外 |
| `skills/aidlc-setup/steps/01-detect.md:89-91` | aidlc-setup 環境判定 | #595: `prompts/package/` 遺物記述削除（または現行構成への書き換え） |
| `docs/configuration.md` / `README.md` | 利用者向けドキュメント | Unit C: サイクル運用記述を Milestone 参照に書き換え |
| `skills/aidlc/guides/{backlog-management,issue-management,glossary}.md` | 運用ガイド | Unit C: サイクルラベル参照 → Milestone 参照 |
| `skills/aidlc/rules.md` | 共通ルール | Unit C: サイクル運用ルール更新 |

`.aidlc/cycles/{{CYCLE}}/` 配下の本サイクル成果物は通常通り `requirements/`, `story-artifacts/units/`, `design-artifacts/`, `construction/`, `operations/`, `history/` を使用する。

## アーキテクチャ・パターン（関連箇所のみ）

### スキルベース相対パス参照（v2.0.5 以降）

- 根拠: `skills/aidlc/rules.md`「プラグイン前提の構成原則」、`SKILL.md`「パス解決」
- メタ開発時の編集は `skills/aidlc/**`（プロジェクトルート相対、例外META-001）、スキル実行時はスキルベースディレクトリ相対
- 本サイクルでも Unit C のドキュメント側（`docs/configuration.md` / `README.md`）はプロジェクトルート相対、`skills/aidlc/guides/` 配下はスキルベース相対で扱う

### サイクル管理の現行設計

- 根拠: `skills/aidlc/scripts/cycle-label.sh`、`scripts/label-cycle-issues.sh`、`steps/inception/02-preparation.md` ステップ16
- 現行: Issue 選択後に `cycle:vX.Y.Z` ラベルを `cycle-label.sh` で作成し、`label-cycle-issues.sh` で対象 Issue へ一括付与
- 移行先: GitHub Milestone（`gh api repos/OWNER/REPO/milestones`）。1 サイクル = 1 Milestone（Kubernetes/release モデル）
- v2.3.6 試験運用で Milestone #1 + 6 件紐付けを実施済み（`https://github.com/ikeisuke/ai-dlc-starter-kit/milestone/1`）

### バージョン三角検証モデル

- 根拠: `skills/aidlc/guides/version-check.md`、`steps/inception/01-setup.md` ステップ5、`skills/aidlc-setup/steps/01-detect.md`
- 3点ソース: `remote`（`https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt`）、`skill`（`skills/aidlc/version.txt`）、`local`（`.aidlc/config.toml.starter_kit_version`）
- 想定: `local` は setup/migrate 時のみ更新され、リリースで上書きされない設計
- 現状不具合: `bin/update-version.sh` が `local` を毎リリース上書きしており、メタ開発時の三角検証が常に一致判定（#596）

### Bash 配列展開と `set -u`

- 根拠: `skills/aidlc/scripts/pr-ops.sh` の `set -euo pipefail`
- `bash` で空配列を `"${arr[@]}"` 形式で展開すると `set -u` 環境では `unbound variable` エラー（macOS の bash 3.2 / GNU bash 共通）
- 修正パターン: `"${arr[@]:-}"` 形式、または `[[ ${#arr[@]} -gt 0 ]]` ガードで囲む

## 技術スタック（関連分のみ）

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash 3.2+ / Markdown | スクリプト先頭 shebang `#!/usr/bin/env bash`、`set -euo pipefail` |
| ランタイム | macOS / Linux（CI: GitHub Actions） | `.github/workflows/*.yml` |
| 設定パーサ | dasel v3+（TOML） | `scripts/read-config.sh`、`scripts/env-info.sh` |
| GitHub 操作 | gh CLI（v2 系）、`gh api`（REST/GraphQL フォールバック） | `skills/aidlc/scripts/issue-ops.sh`、`scripts/cycle-label.sh`、`guides/issue-management.md` |
| AI レビュー | codex（既定） | `.aidlc/config.toml`「rules.reviewing.tools = ['codex']」 |
| プラットフォーム | Claude Code プラグイン（v2.0.5+） | `.claude-plugin/`、`SKILL.md` のスキル定義 |

## 依存関係（影響範囲のみ）

### Unit A（Operations 組込み）が依存する既存資源

- `skills/aidlc/steps/operations/operations-release.md`（リリース手順本体、§7.x 系）
- `skills/aidlc/steps/operations/04-completion.md`（完了処理）
- `skills/aidlc/scripts/operations-release.sh`（CLI ラッパー）
- `gh api repos/OWNER/REPO/milestones --method PATCH -f state=closed`（Milestone close）/ `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N`（紐付け確認・追加紐付けフォールバック）/ `gh api repos/OWNER/REPO/milestones --method POST -f title=vX.Y.Z`（Milestone 不在時 fallback 作成のみ）

### Unit B（Inception 組込み）が依存する既存資源

- `skills/aidlc/steps/inception/02-preparation.md` ステップ16（Issue 選択 → サイクルラベル付与の現行フロー）
- `skills/aidlc/steps/inception/05-completion.md`（完了処理、サイクルラベル運用記述あり）
- `skills/aidlc/scripts/cycle-label.sh` / `label-cycle-issues.sh`（停止判断対象）
- `gh api repos/OWNER/REPO/milestones`（同上）

### Unit C（docs 更新）が依存する既存資源

- `docs/configuration.md`（プロジェクト設定 / 運用記述）
- `README.md`（バッジ・概説）
- `skills/aidlc/guides/{backlog-management,issue-management,glossary,backlog-registration}.md`
- `skills/aidlc/rules.md`（共通ルール、サイクル運用記述）

### patch バンドル（#595 / #596 / #588）の依存関係

- `#595`: `skills/aidlc-setup/steps/01-detect.md` のメタ開発判定条件（`prompts/package/` 遺物 → 現行 `.claude-plugin/` 等への置換要否）
- `#596`: `bin/update-version.sh` の更新対象設計、`skills/aidlc-setup` / `skills/aidlc-migrate` の `starter_kit_version` 書き込み経路、メタ開発時の `.aidlc/config.toml` 取り扱い方針
- `#588`: `skills/aidlc/scripts/pr-ops.sh:216-245` の Bash 配列空展開、`set -euo pipefail` の影響範囲

### 循環依存の有無

なし（影響範囲は単方向で、Operations / Inception / patch スクリプト → ガイド・README のドキュメント側へ伝搬する関係）。

## 特記事項

- **試験運用の本採用扱い**: v2.3.6 で実施した Milestone #1 + 6 件紐付け試験は本採用の一部として維持する。リセット・削除はしない（#597 §「v2.3.6 試験運用結果の扱い」）。
- **トークンスコープ制約**: `gh issue edit --milestone` / `gh pr edit --milestone` がトークンスコープで失敗する場合があり、Unit A / B の組込み手順では `gh api --method PATCH` フォールバックを必ず示す（`skills/tools/gh-api-fallback`「token scope error」参照）。
- **メタ開発時の自己参照**: v2.4.0 サイクル自体には Unit B の Milestone 作成ステップを適用しない（Inception 完了時に手動で Milestone `v2.4.0` を作成、Inception Phase 内で確定）。**v2.5.0 以降の新規サイクルでは、更新済み Inception の Markdown 手順を標準手順として用いる**（専用スクリプト自動実行は本サイクルのスコープ外）。
- **過去サイクル遡及（Unit D-F）は本サイクル外**: blast radius が大きいため、本採用フロー（A-C）の稼働確認後に minor/patch サイクルで段階実施する（v2.5.0 以降の別サイクルで扱う）。
- **未完了箇所**: 本ドキュメントは影響範囲限定のためフル4セクション網羅は意図的に省略している（メタ開発リポジトリで構造既知、Issue 本文と本ドキュメントの合算で十分と判断）。フル分析は後続サイクルで必要になった時点で別途実施する。
