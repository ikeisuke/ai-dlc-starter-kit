# 既存コードベース分析（ミニマルスコープ）

本サイクル（v2.4.1 patch）は影響範囲が明確な patch 5 件に絞っているため、分析は対象 Unit に関連するファイルの現状把握に限定する。フル 4 セクション分析（ディレクトリ構造 / アーキテクチャ / 技術スタック / 依存関係）は本サイクル外。

## 分析範囲

| Unit | 対象ファイル | 現状把握の目的 |
|------|------------|--------------|
| A (#601) | `skills/aidlc/steps/operations/operations-release.md` L91-118（§7.13）、`skills/aidlc/steps/operations/04-completion.md` L42、`skills/aidlc/steps/operations/02-deploy.md` L133-184、`skills/aidlc/steps/operations/03-release.md` L31、`skills/aidlc/steps/operations/index.md` L107-109 | 7.13 の設定保存フロー位置とガード挿入ポイント特定 |
| B (#598) | `.github/workflows/pr-check.yml`、`.github/workflows/migration-tests.yml`、`.github/workflows/skill-reference-check.yml` | 3 workflow の paths フィルタ・Draft skip 構成と required check 名の抽出 |
| C (#594) | `skills/aidlc/steps/construction/04-completion.md` L92-100 / L102-108 / L136-147、`skills/aidlc/steps/common/commit-flow.md` L72-78 | Squash ステップの現行ラベル・分岐ロジックの不在箇所特定 |
| D (#600) | `skills/aidlc-setup/steps/01-detect.md`（セクション1早期判定） | 3 条件チェックの現行記述と独立実行指針の不足箇所特定 |
| E (#602) | `skills/aidlc/steps/inception/02-preparation.md`（§16）、`skills/aidlc/steps/inception/05-completion.md`（§1）、`skills/aidlc/steps/operations/01-setup.md`（§11）、`skills/aidlc/steps/operations/04-completion.md`（§5.5） | 4 step.md の現状構造と改善対象箇所の抽出 |

## Unit A: #601 対象箇所

### `skills/aidlc/steps/operations/operations-release.md` §7.13（L91-118）

- **マージ方法確定**: `gh_status != available` / `merge_method=ask` / 固定値の 3 分岐
- **設定保存フロー**（L97-106）: `merge_method=ask` でユーザー選択後、`AskUserQuestion` で「この選択を設定に保存しますか？」を問い、`scripts/write-config.sh rules.git.merge_method <値> --scope <local|project>` を実行
- **ガード挿入候補ポイント**: `write-config.sh` 実行直後（L106 以降）
- **注釈**: マージ方法確定と設定保存の時点ではマージは実行しない。後段で `operations-release.sh merge-pr` を呼ぶ構造（Ready 化済みの PR に対してマージ実行）

### `skills/aidlc/steps/operations/04-completion.md` L42

「PR マージ（7.13）完了後は `.aidlc/cycles/{{CYCLE}}/**` 配下のいかなるファイルも改変してはならない」と明記されており、**マージ後の tracked ファイル変更は既に禁止されている**。問題は 7.13 内の `write-config` が `.aidlc/config.toml` を書き換えた段階で既に tracked ファイル変更が PR に反映されずに残るケース（`.aidlc/config.toml` は cycles 配下ではないが tracked ファイル）。

### `skills/aidlc/steps/operations/index.md` L107-109

7.13 は `automation_mode` に関わらずユーザー確認必須（破壊的・不可逆操作）と既に明記。Unit A のガード追加はこの方針と整合。

## Unit B: #598 対象 workflow の現状

### `.github/workflows/pr-check.yml`

- `paths` フィルタ: `**.md` / `**.toml` / `.markdownlint.json` / `.github/workflows/pr-check.yml` / `bin/check-bash-substitution.sh` / `bin/check-defaults-sync.sh` / `version.txt` / `skills/**/version.txt`
- 3 job: `markdown-lint` / `bash-substitution-check` / `defaults-sync-check`
- 各 job に `if: github.event.pull_request.draft == false` ガード
- **required check 名（推定）**: `Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check`

### `.github/workflows/migration-tests.yml`

- `paths` フィルタ: `skills/aidlc-migrate/scripts/migrate-*.sh` / `skills/aidlc-migrate/scripts/lib/**` / `tests/migration/**` / `tests/fixtures/**` / `.github/workflows/migration-tests.yml`
- 1 job: `migration-tests`
- `if: github.event.pull_request.draft == false` ガード
- **required check 名（推定）**: `Migration Script Tests`

### `.github/workflows/skill-reference-check.yml`

- `paths` フィルタ: `skills/**` / `bin/check-skill-references.sh` / `.github/workflows/skill-reference-check.yml`
- 1 job: `skill-reference-check`
- `if: github.event.pull_request.draft == false` ガード
- **required check 名（推定）**: `Skill Reference Check`

### 観察

- 3 workflow ともに `paths` フィルタと `draft == false` ガードが独立に存在し、両方の組み合わせで required check が無応答になる可能性
- `pr-check.yml` は `paths` に `skills/**/version.txt` を含むが、`skills/aidlc/scripts/*.sh` のみの変更では発火しない（paths 非該当）
- `skill-reference-check.yml` は `skills/**` を含むため `skills/aidlc/scripts/*.sh` 変更時は発火するが、Draft 中は skipped

## Unit C: #594 対象箇所

### `skills/aidlc/steps/construction/04-completion.md` L92-100

- L92: `### 7. Squash（コミット統合）【オプション】`
- L96: `**【次のアクション】** steps/common/commit-flow.md の「Squash統合フロー」を読み込んで実行。`
- L98-100: `squash:success` / `squash:skipped` / `squash:error` の分岐は記述済み

### `skills/aidlc/steps/common/commit-flow.md` L72-78

- L72: `## Squash統合フロー`
- L74: `rules.git.squash_enabled=true の場合、フェーズ完了時に中間コミットを1つにまとめる。`
- L76: `**/squash-unit スキルを使用する**。スキルが利用できない場合は squash-unit.sh を直接実行する。`
- **前提チェックの明示的な分岐記述が不在**。`squash_enabled=false` 時の明示スキップ指示がない

### `skills/squash-unit/SKILL.md`

- `skills/squash-unit/SKILL.md` は設定チェックを行わず呼ばれたら無条件 squash する設計（#594 本文より）
- 本サイクルでは呼び出し側責任を維持し、SKILL.md 側の分岐ロジック追加は行わない

## Unit D: #600 対象箇所

### `skills/aidlc-setup/steps/01-detect.md` セクション1「早期判定」

- 3 条件を「順に確認」と記載。各条件を独立評価する具体コマンド例と `&&` / `||` チェーン禁止の注意書きが不在
- ikeisuke/norigoro での誤判定事例（`.aidlc/` 不在時に `&&` 短絡評価で後続スキップ）は本サイクル内で reference として追記予定

## Unit E: #602 対象箇所の構造

### `skills/aidlc/steps/inception/02-preparation.md` §16

- 「Issue確認」「Milestone 機能 opt-in ガード」「Milestone 紐付け」の 3 サブセクション
- `SELECTED_ISSUES` 構築手順が暗黙。`MILESTONE_ENABLED` 取得後の値捕捉方法が明示されていない
- `early-link` スクリプトのスキップ条件（5 ケース判定）は明示済み、`SELECTED_ISSUES` が空のときの挙動が曖昧

### `skills/aidlc/steps/inception/05-completion.md` §1

- `MILESTONE_NUMBER` の抽出方法（grep/sed/awk いずれも）が未定義

### `skills/aidlc/steps/operations/01-setup.md` §11

- `11-1 / 11-2 / 11-3` のサブ見出しが TOC で「3 個別 subcommand」に見える誤読リスクあり
- 実体は `setup-step11` 1 回呼び出しで内部処理として実行される構造

### `skills/aidlc/steps/operations/04-completion.md` §5.5

- 構造審査上 all OK、不明瞭点なし
- 他 3 ファイルの改訂に伴う引用・相互参照の整合確認のみ

## 依存関係

本サイクル内 Unit 間の依存はなし。Unit A-E は独立並列に実装可能。ただし同一ファイル（例: `skills/aidlc/steps/operations/04-completion.md` は Unit A と Unit E の両方が触れる）のコンフリクトに注意が必要。

## 特記事項

- 本サイクルは Markdown 手順書 + GitHub Actions workflow + aidlc-setup スキル docs の改訂が主体。シェルスクリプトや判定仕様（phase-recovery-spec.md 等）には影響を与えない
- Unit B は CI ワークフロー変更のため本サイクル自体の PR で動作検証可能（`skills/aidlc/scripts/*.sh` のみ変更する小さなテスト PR、または本 PR 内で必要変更をまとめる）
- Unit A は `jailrun v0.3.1` の実例（Feedback 報告者）を reference ケースとして活用
- `skills/aidlc/steps/operations/04-completion.md` L42 の「PR マージ後の `.aidlc/cycles/**` 改変禁止」ルールは既存のものであり、本サイクルでは拡張しない
