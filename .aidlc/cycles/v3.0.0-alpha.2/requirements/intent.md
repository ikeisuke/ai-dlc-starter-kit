# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit / v3.0.0-alpha.2（Phase 2: aidlc-v3 skeleton）

## 開発の目的

alpha.1 で `docs/v3/*.md`（rfc / workflow / data-model / migration）に固定した v3 設計を、実際の skill 骨組みとして `skills/aidlc-v3/` に具現化する。v2（`skills/aidlc`）と独立して共存する skeleton を作り、v3 のディレクトリ構造・define 手順・status 出力仕様・state.json 操作スクリプト・成果物テンプレートを「最初の試せる形」にする。

本サイクル（alpha.2）は v3 リニューアル全体（7〜8 サイクル）の **Phase 2** に相当し、計画書（`docs/v3-renewal-plan.md`）の **Unit 002: aidlc-v3 skeleton** を実行する。skeleton は「読める手順 + 検証可能な state 操作」までを範囲とし、define / develop / release フローの**実行実装は Phase 3 以降**に委ねる。

なぜ必要か:

- alpha.1 の設計文書（`docs/v3/*.md`）は判断を固定したが、実体（skill ファイル）がまだ存在しない
- Phase 3（define + develop tiny flow 実装）が土台とする skill 構造・state スクリプト・テンプレートを先に確定する必要がある
- v2 と独立した `skills/aidlc-v3/` を早期に置くことで、以降の Phase が v2 を壊さず段階的に v3 を組み上げられる

## ターゲットユーザー

- **直接**: AI-DLC starter kit の開発者（本リポジトリ。ドッグフーディングで v2 を使い v3 を構築）
- **間接**: 将来 v3 を利用する consumer プロジェクト（skeleton が以降のフロー実装・利用体験の土台になる）

## ビジネス価値

- v3 実装フェーズ（Phase 3 以降）が参照する skill 骨組み・state 操作 API・テンプレートを 1 サイクルで確定し、後続の手戻りを防ぐ
- v2 と共存する `skills/aidlc-v3/` を確立し、クリーンカット方針（v2 非影響）を構造として担保する
- define 手順・status 出力仕様を可読な形で固定し、Phase 3 の実装インプットを明確化する

## スコープ

### 含まれるもの（このサイクルの成果物）

- `skills/aidlc-v3/SKILL.md` — ルーティング（**define / develop / release** / reflect / status / doctor + 連続実行ラッパ `express` + 旧名エイリアス inception / construction / operations / retrospective）+ 引数なし実行のフェーズ導出ルーティング + コアルール参照（`docs/v3/workflow.md` §2 / §4 / RFC DG-1）。**コマンド名は確定 RFC（DG-1）準拠で `develop`**（`build` / `implement` は採用せずエイリアスにもしない）
- `skills/aidlc-v3/steps/define.md` — define フロー手順書（Step 1-4: 環境チェック / Intent 定義 / Work Item 分割 / 初期化、`docs/v3/workflow.md` §3.1）。**読める手順**として記述し、フロー実行実装は Phase 3 へ
- `skills/aidlc-v3/steps/status.md` — status 出力仕様（read-only。state.json + work item frontmatter からフェーズを導出して現在地・次アクションを表示、`docs/v3/workflow.md` §3.5）。**complete 判定は `release.merge_approved` と PR の merged 実態の両方を参照**し、PR 実態を確認できない場合は complete とせず release/警告扱いとする旨を含める（`docs/v3/data-model.md` §5）
- `skills/aidlc-v3/scripts/state-read.sh` — state.json の読み取り（フィールド抽出）
- `skills/aidlc-v3/scripts/state-write.sh` — state.json の atomic 書き込み（temp file + mv）。**本サイクルの範囲は schema validation + atomic write + 許可フィールド更新に限定**する。`define_completed` / `release.*` の許可/禁止状態遷移ルールの具体化は Phase 3（flow 実装）で確定する（`docs/v3/data-model.md` §3）
- `skills/aidlc-v3/scripts/state-validate.sh` — state.json schema validation（必須フィールド: `schema_version` / `current_cycle` / `define_completed` / `release` / `updated_at`（ISO 8601 string）、`docs/v3/data-model.md` §3）
- `skills/aidlc-v3/templates/intent.md` — Intent テンプレート
- `skills/aidlc-v3/templates/work-item.md` — work item テンプレート（frontmatter: id/status/size/risk/assigned/dependencies + 本文セクション、計画書 L376-422 準拠）
- `skills/aidlc-v3/templates/journal.md` — journal テンプレート（追記型、計画書 L436-450 準拠）

### 含まれないもの（明示的除外 / 後続フェーズ）

- 既存 `skills/aidlc`（v2）への変更（クリーンカット / 共存。v2 は一切触らない）
- define / develop / release フローの**実行実装**（Phase 3 以降。本サイクルの define.md / status.md は手順・出力仕様の記述に留める）
- `steps/develop.md` / `steps/release.md` / `steps/recovery.md` / `steps/rules.md`（Phase 3〜6）
- `aidlc-review` 統合スキル（10→1）の実装（Phase 4 以降）
- `doctor.sh` 実装（Phase 6）
- `work-item-next.sh`（依存解決）/ `work-item-state.sh`（Phase 3 以降）
- v2 → v3 migration スクリプト実装（`aidlc-migrate`、別フェーズ）
- `marketplace.json` への `aidlc-v3` 登録（`/aidlc-v3` 起動の有効化）。完了条件は「手順が読める」であり flow 未実装のため、起動有効化は Phase 3 以降に defer
- 既存 v2 オープン Issue / バックログ（v2 改善）の対応（v3 は別系統で構築）

## 成功基準（受け入れ基準）

- [ ] `skills/aidlc-v3/SKILL.md` に define/develop/release/reflect/status/doctor + 旧名エイリアス + 引数なし実行のルーティングが記述されている
- [ ] `/aidlc-v3 define` 相当の手順が `steps/define.md` に**読める形**（Step 1-4）で記述されている
- [ ] `/aidlc-v3 status` 相当の**出力仕様**が `steps/status.md` に記述されている（フェーズ導出ロジック + 出力例。complete 判定は `release.merge_approved` と PR の merged 実態の両方を参照する旨を含む）
- [ ] state.json の**作成仕様**（schema・必須フィールド `schema_version` / `current_cycle` / `define_completed` / `release`（+ サブフィールド `pr_number` / `ready` / `merge_approved`）/ `updated_at`・型・各 enum・書き込みタイミング）が記述され、`state-validate.sh` で有効/無効な state.json を正しく判定できる（`updated_at` および `release` サブフィールドの欠落・型不正も無効と判定する）
- [ ] `state-read.sh` / `state-write.sh` / `state-validate.sh` の 3 本が存在し、`bash -n` および shellcheck（利用可能時）を通過する
- [ ] `state-write.sh` が atomic 書き込み（temp file + mv）を行い、直接編集を回避する設計になっている
- [ ] テンプレート 3 種（intent / work-item / journal）が `docs/v3/data-model.md` の確定仕様に準拠している
- [ ] **v2 非影響**: `skills/aidlc/` 配下に一切の変更がない（`git diff` で確認）
- [ ] **スコープ逸脱がない**: 成果物が `skills/aidlc-v3/` および `.aidlc/cycles/` 配下に限定され、define/develop/release フローの実行実装を含んでいない
- [ ] markdownlint を通過する

## 期限とマイルストーン

- 本サイクル（alpha.2）= Phase 2。後続は alpha.3（define + develop tiny 実装）, alpha.4（develop normal/risky）... と段階進行（renewal plan 上の "build" 表記は確定 RFC の "develop" に読み替える）
- 全 alpha 完走後に統合ブランチ `v3.0.0` を `main` へマージ

## 制約事項

- **ドッグフーディング**: v2 starter kit（2.6.6）の Inception/Construction を使って v3 skeleton を構築する
- **共存（クリーンカット）**: 成果物は `skills/aidlc-v3/` に隔離し、v2 `skills/aidlc` の runtime / ファイルに影響を与えない
- **ブランチ**: 作業は `cycle/v3.0.0-alpha.2`（`v3.0.0` ベース）。release で `cycle/v3.0.0-alpha.2 → v3.0.0` の PR
- **入力と正本優先順位**: `docs/v3-renewal-plan.md`（Phase 2 / Unit 002）を実行計画の入力とし、`docs/v3/*.md`（alpha.1 で確定した RFC / workflow / data-model / migration）を**設計の正本**とする。**用語・コマンド名・schema・フェーズ導出が両者で食い違う場合は確定 RFC（`docs/v3/*.md`）を優先**する（例: Construction コマンド名は renewal plan の `build` ではなく RFC DG-1 の `develop` を採用）
- **Reverse Engineering**: 計画書 + alpha.1 の `docs/v3/*.md` が設計インプットを内包するため、別途 `existing_analysis.md` は作成しない

## 不明点と質問（Inception Phase中に記録）

[Question] 計画書内で state スクリプト本数が食い違っている（Phase 2 成果物リスト L1012 は read/write/validate の 3 本、Unit 002 スコープ L1157 は validate のみ）。どちらを採用するか。
[Answer] 3 本（state-read.sh / state-write.sh / state-validate.sh）を採用する。status.md は state.json を読む（read）、define 完了は state を書く（write）必要があり「試せる skeleton」には I/O が要る。計画書 L591 の v3 恒久スクリプトリストとも一致する（ユーザー承認済み 2026-06-11）。

[Question] `marketplace.json` への `aidlc-v3` 登録（`/aidlc-v3` 起動の有効化）を alpha.2 に含めるか。
[Answer] 含めない（Phase 3 以降へ defer）。完了条件が「手順が読める」であり、flow 未実装の状態で起動しても動作しないため。skeleton はファイル群として可読・検証可能であれば足りる。
