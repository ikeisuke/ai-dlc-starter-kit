# ドメインモデル: Unit 007 公開ドキュメントのサイクル運用記述を Milestone 参照に書き換え

## 概要

GitHub Milestone 運用本採用（#597）の周知側として、公開ドキュメント（guides 4 ファイル + CHANGELOG）のサイクル運用記述を Milestone 参照に書き換える。Unit 005 (Inception Phase) / Unit 006 (Operations Phase) で実装済みの Milestone 手順と整合させ、`cycle:v*` ラベル運用との切り替えを明示する。本 Unit はドキュメント編集のみのため、**ドキュメント間の整合性 + 責務委譲の透明性 + 過剰修正回避** を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 007: 公開ドキュメント Milestone 周知書き換え

- **責務**: Unit 005 / 006 で確定した Milestone 手順を公開ドキュメントに正確に反映し、旧サイクルラベル運用との切り替えを CHANGELOG 経由で利用者に周知する
- **入力**:
  - Unit 005 完了状態の Inception Phase ステップ（`02-preparation.md` / `05-completion.md` / `index.md`）
  - Unit 006 完了状態の Operations Phase ステップ（`01-setup.md` / `04-completion.md` / `index.md` §2.8）
  - 既存の公開ドキュメント（`skills/aidlc/guides/issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`）と CHANGELOG
- **出力**:
  - Milestone 参照に書き換えられた guides 4 ファイル
  - `[2.4.0]` 節に `### Added` / `### Changed` / `### Deprecated` セクションを併記した CHANGELOG（Keep a Changelog 順序準拠: Added → Changed → Deprecated → Removed）
  - サイクルラベル運用の deprecation 周知（CHANGELOG `### Deprecated` + `glossary.md` deprecated エントリ）

## ファイル所有関係

| ファイル | Unit 007 所有範囲 | 他 Unit との関係 |
|---------|----------------|---------------|
| `skills/aidlc/guides/issue-management.md` | サイクルラベル付与記述 → Milestone 紐付け書き換え（**排他所有**） | Unit 005 が実装した `gh issue edit --milestone` 主経路を参照 |
| `skills/aidlc/guides/backlog-management.md` | ラベル構成 / Inception Phase / トラブルシューティング / 関連機能の現状 セクションの書き換え（**排他所有**） | Unit 005 / 006 完了後の最終形を反映 |
| `skills/aidlc/guides/backlog-registration.md` | 出力テンプレートに Milestone 未割当初期状態の注記追加（**排他所有**） | 既存テンプレート構造は維持 |
| `skills/aidlc/guides/glossary.md` | 用語一覧表に「Milestone」「サイクルラベル（deprecated）」の 2 エントリ追加（**排他所有**） | 既存エントリは触らない |
| `CHANGELOG.md` `[2.4.0]` 節 `#597` 関連記述 | `### Added` / `### Changed` / `### Deprecated` 節への追記（**排他所有**） | `#596` / `#595` / `#588` 節は他 Unit の所有（触らない） |
| `docs/configuration.md` / `README.md` / `.aidlc/rules.md` | **no-op 扱い**（実態調査で書き換え対象記述が空集合と確認） | Unit 003 所有部分 / Unit 005 / 006 範囲外部分は触らない |
| `skills/aidlc/steps/inception/**` / `operations/**` / `cycle-label.sh` / `label-cycle-issues.sh` | **対象外**（Unit 005 / 006 所有） | Unit 005 / 006 完了済み |

## 責任分離（Unit 005 / 006 / 007）

| 責務 | 担当 Unit | 出力先 |
|------|---------|-------|
| Inception Phase Markdown ステップに Milestone 作成・関連 Issue 紐付けを実装 | Unit 005 | `skills/aidlc/steps/inception/**` + `cycle-label.sh` / `label-cycle-issues.sh` の DEPRECATED 注記 |
| Operations Phase Markdown ステップに Milestone close + 紐付け確認 + fallback 作成を実装 | Unit 006 | `skills/aidlc/steps/operations/**` + `index.md` §2.8 補助契約 |
| 公開ドキュメントの Milestone 周知書き換え + CHANGELOG `#597` 節整備（cycle-label 系の deprecation 記載は Unit 005 から委譲、Operations Phase 追加機能記載は Unit 006 から委譲） | **Unit 007** | guides 4 ファイル + CHANGELOG |

責任分離の根拠:

- 実装ファイル（steps / scripts）と公開ドキュメント（guides / CHANGELOG）の編集権限を分離することで、Unit 完了の独立性を確保
- CHANGELOG `#597` 節を Unit 007 排他所有とすることで、Unit 005 / 006 完了時には CHANGELOG 編集を発生させず、各 Unit のスコープを純粋に保つ
- Unit 005 / 006 の実装記録「Unit 007 への引き継ぎ事項」セクションが委譲契約として機能する

## 過剰修正回避原則

Unit 定義は責務候補として `docs/configuration.md` / `README.md` / `.aidlc/rules.md` を含めているが、Plan 段階の実態調査（grep 全件確認）で対象記述が空集合と判明した場合は **no-op 扱い** とし触らない。Unit 定義側にも「候補として調査対象だが Plan 段階の実態調査で no-op 確認された場合は触らない（過剰修正回避）」の注記を同期反映済み。

**根拠**: Unit 定義の責務記述は予防的に網羅された候補リストであり、実態と乖離するファイルへの不要な編集はリリースノートの過剰評価および設計レビューでの整合性低下を招く。実態調査結果を Plan で明示することで、no-op 判断の透明性を確保する。

## CHANGELOG セクション順序契約

Keep a Changelog 推奨順（Added → Changed → Deprecated → Removed → Fixed → Security）に従う。本サイクルの `[2.4.0]` 節は現状 `### Changed` / `### Removed` のみで `### Added` / `### Deprecated` がないため、本 Unit で以下の順序に再構成する:

1. `### Added` ← **新規追加**（Inception/Operations Milestone ステップ追加）
2. `### Changed` ← 既存（#596 関連） + 本 Unit で `#597` 関連を追加
3. `### Deprecated` ← **新規追加**（cycle-label.sh / label-cycle-issues.sh / cycle:vX.X.X ラベル）
4. `### Removed` ← 既存（#595 関連）

## Milestone 手動復旧契約（gh 利用可能 vs 不可）

`backlog-management.md` トラブルシューティング節および `issue-management.md` 補足説明では、Milestone 手動復旧手順を以下の 3 パターンに分岐させて提示する:

| パターン | 条件 | 手順 |
|---------|------|------|
| A-1 | `gh` 利用可能 + duplicate/closed 混在 | `gh api milestones?state=all` で同名 Milestone 一覧確認 → 不要 duplicate を `title 変更` または `delete` で同名衝突除去（`close` ではない、`closed_count >= 1` 停止条件再発防止）→ 完了条件 `open=1, closed=0` → A-2 で再紐付け |
| A-2 | `gh` 利用可能 + LINK_FAILED の復旧時 | Issue 側: `gh issue edit --milestone` 主経路、フォールバック `gh api PATCH issues/{ISSUE_NUMBER}`。PR 側: GitHub 仕様により Issue API 経由 `gh api PATCH issues/{PR_NUMBER}` または GitHub UI 手動操作 |
| B | `gh` 利用不可時 | OWNER/REPO 確認（リポジトリ URL）→ MILESTONE_NUMBER 取得（GitHub UI Milestones 一覧 / REST API `GET milestones?state=all` + `jq title==vX.X.X && state==open`、1 件でない場合は先に衝突解消）→ Issue/PR 双方を Issue API 経由で紐付け可能。Issue は `curl PATCH issues/{ISSUE_NUMBER}`、PR は `curl PATCH issues/{PR_NUMBER}` を使用し、いずれも GitHub UI 手動操作を代替手段とする |

**根拠**: Plan 段階の codex AI レビュー round 11-13 で「`gh` 利用不可時に `gh` コマンド案内するのは矛盾」「duplicate 復旧で `close` 案内すると `closed_count >= 1` 停止条件で自己矛盾」「`curl` 手順で `MILESTONE_NUMBER` 取得経路欠落」の 3 件を順次解消した結果、3 パターン分岐に集約。実装ステップ（Unit 005 / 006）の停止条件契約と整合性を保つ。

## ユビキタス言語

- **公開ドキュメント書き換え**: Unit 005 / 006 で確定した実装ステップを利用者向けに翻訳・整形し、guides / glossary に反映する Unit 007 の責務範囲
- **責務委譲**: Unit 005 / 006 完了時に CHANGELOG 編集を行わず「Unit 007 への引き継ぎ事項」セクションで委譲明記する契約。Unit 007 の Plan で受領確認 + 実装で反映完了
- **過剰修正回避**: Unit 定義で候補として挙げられたファイルが実態調査で空集合と判明した場合に no-op 扱いとする原則
- **手動復旧 3 パターン分岐**: gh 利用可能/不可、duplicate/closed 混在/LINK_FAILED の組み合わせを 3 パターン（A-1 / A-2 / B）に整理した手動操作契約。実装ステップの停止条件と整合
- **Keep a Changelog 順序準拠**: Added → Changed → Deprecated → Removed → Fixed → Security の節順序。`[2.4.0]` 節を本 Unit で再構成する

## 不明点と質問

なし（plan 段階で codex AI レビュー 14 反復を経て手動復旧 3 パターン分岐 / Keep a Changelog 順序 / 過剰修正回避を確定済み）。
