# ユーザーストーリー

## Epic: AI-DLC v3 define + develop tiny フロー実行実装（Phase 3）

alpha.2 で「読める手順」として固定した `skills/aidlc-v3/` を、実際に動作する実行実装へ進める。define を実行可能にし、develop の tiny フローと依存解決を実装し、`/aidlc-v3` 起動を有効化する。あわせて前フェーズ defer の #731（state-validate.sh の schema_version 値互換性検証 + state-write.sh の未知 schema_version 更新防止ガード）を解消する。

---

### ストーリー 1: define を実行して新しい v3 cycle を作成する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to `/aidlc-v3 define` を実行して、新しい v3 cycle の成果物（cycle ディレクトリ配下の `intent.md` / `work-items/` / `journal.md`）と cycle レベルの `state.json` を実際に生成したい
So that v3 のサイクルを「読むだけ」でなく実際に開始でき、後続フェーズの実装・ドッグフーディングの土台になる

**受け入れ基準**:
- [ ] define 実行で、v3 形式（フラット構造: `intent.md` / `work-items/` / `journal.md`）の **cycle ディレクトリ**（`.aidlc/cycles/<cycle>/`）が作成される
- [ ] `intent.md`・`work-items/*.md`・`journal.md` が `templates/` を基に **cycle ディレクトリ配下**に実際に生成される
- [ ] `state.json` が **cycle レベルの `.aidlc/state.json`**（cycle ディレクトリ配下ではない / `docs/v3/data-model.md` §2）に `state-write.sh` 経由の atomic 書き込みで初期化され（`define_completed: true`、必須フィールド `schema_version` / `current_cycle` / `release` / `updated_at` を含む）、`state-validate.sh` で valid と判定される
- [ ] define Step 4 で指定 cycle ブランチが作成され、初回 commit が作成される（`git status` / `git log` で確認できる）
- [ ] Intent 承認ゲート・Work Item 承認ゲートが手順に明示されている（`docs/v3/workflow.md` §3.1 準拠）
- [ ] 生成・更新する Markdown が markdownlint を通過する

**技術的考慮事項**:
cycle ディレクトリ作成ロジックは本ストーリーの範囲。state.json 書き込みは alpha.2 の `state-write.sh` を利用する。検証は v2 ドッグフーディング用 `.aidlc/` を破壊しないサンドボックス／テストハーネスで行う。

---

### ストーリー 2: 依存解決で次に着手すべき work item を選定する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to `work-item-next.sh` で work item の依存関係を解決し、次に着手可能な work item を選定したい
So that develop フローが「どの work item から着手するか」を依存グラフに基づいて自動提示できる

**受け入れ基準**:
- [ ] `work-item-next.sh` が `work-items/*.md` の frontmatter（status / dependencies）を走査して次候補を選定する
- [ ] 新規着手候補の対象 status は **`pending` のみ**とし、`done` / `withdrawn` / `blocked` は候補から除外する。`in_progress` の work item が存在する場合は新規選定より resume を優先（または WARN）する旨が定義されている
- [ ] (a) `status: pending` かつ依存がすべて `done` の work item が選定される
- [ ] (b) `status: pending` でも依存が未完了（依存先が `pending` / `in_progress` / `blocked`）の work item は候補から除外される
- [ ] (c) 依存先が `withdrawn` の work item は自動充足とせず候補外（`blocked` 相当）とする（`done` のみ自動充足 / `docs/v3/data-model.md` §5.2 準拠）
- [ ] (d) 存在しない dependency ID を持つ work item は WARN を出して候補外とする（§6 trace 整合エラー）
- [ ] (e) 候補が複数ある場合の選定順（または提示方式）が定義されている
- [ ] `bash -n` および shellcheck（利用可能時）を通過する
- [ ] 上記候補 status 規約と (a)〜(e) それぞれに対応するテストがある

**技術的考慮事項**:
frontmatter のパースは安全境界が必要なため、tiny フローで status 更新に必要な最小範囲の frontmatter 操作を含む。

---

### ストーリー 3: develop tiny フローで tiny work item を完了する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to `/aidlc-v3 develop` を実行して、tiny サイズの work item を design / review なしで完了したい
So that 最小作業単位を軽量に回せ、v3 の「size に応じた厚み調整」の最小形が動作する

**受け入れ基準**:
- [ ] develop 実行で、`size: tiny` の work item が design / review をスキップして完了する
- [ ] **次候補が `size: normal` / `risky` の場合は未サポート案内を出して停止し、frontmatter / journal / commit を一切変更しない**（normal / risky フローは Phase 4。tiny を誤って design / review なしで完了させない）
- [ ] frontmatter `status` が `pending → in_progress`（Step 1 選定時）→ `done`（Step 6 完了時）と遷移する
- [ ] 実装内容が work item 単位で commit される
- [ ] `journal.md` に完了記録が追記される
- [ ] develop 完了後の `state.json` + frontmatter が status 出力仕様（`steps/status.md`）どおりフェーズを導出できる状態になる（未完了残 → `develop` / 全 work item `done`・`withdrawn` → `release 可能`、`docs/v3/data-model.md` §5.1 評価順 3/4）。tiny 1 件のみのサイクル（完了で `release 可能`）と複数 work item の途中完了（`develop` 継続）の両方を検証する
- [ ] 生成・更新する Markdown が markdownlint を通過する

**技術的考慮事項**:
`status` 実行実装自体は Phase 6 / 本サイクル対象外。本ストーリーは「導出できる状態になっていること」を検証対象とする。normal / risky 分岐は Phase 4。

---

### ストーリー 4: 未サポート schema_version を安全に扱う（#731）
**優先順位**: Should-have

As a AI-DLC starter kit の開発者
I want to 未サポートの `schema_version` 値を含む `state.json` が、invalid 即時失敗ではなく WARN / migration・手動対応案内として扱われるようにしたい
So that 非互換 state を `state-write.sh` が誤って更新・保持する事故を防ぎつつ、`docs/v3/data-model.md` §6 の WARN 方針と矛盾しない

**受け入れ基準**:
- [ ] `state-validate.sh` がサポート対象 `schema_version`（初版 `"3.0"`）と未知バージョンを区別する
- [ ] 未知 `schema_version` 値を含む `state.json` が `docs/v3/data-model.md` §6 方針（WARN + migration・手動対応案内、invalid＝exit 1 にはしない）に沿って処理される
- [ ] **`state-write.sh` が、未知 `schema_version` の既存 `state.json` を更新しない**（ファイルを不変のまま保持し、migration・手動対応案内を出す）。これにより #731 の本質リスク（writer が非互換 state を更新・保持する事故）を塞ぐ
- [ ] 型のみ正しく値が未知の場合と、サポート対象値の場合をそれぞれ区別する境界テストが追加されている（validator・writer 両方）
- [ ] 既存の必須フィールド・型検証（alpha.2 実装）の挙動を後退させない

**技術的考慮事項**:
`recovery.md` / migration はまだ存在しないため、`state-validate.sh`（値互換性検証）+ `state-write.sh`（未知 `schema_version` の既存 state 更新防止の最小ガード）のレイヤーで解消する。Issue #731。

---

### ストーリー 5: /aidlc-v3 を起動可能にしてドッグフーディングする
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to `marketplace.json` に `aidlc-v3` を登録して `/aidlc-v3` 起動を有効化したい
So that 実装した define / develop フローを実際に起動してドッグフーディングでき、設計と実装の乖離を早期に検出できる

**受け入れ基準**:
- [ ] `marketplace.json` の plugins に `./skills/aidlc-v3` が追加される
- [ ] `/aidlc-v3 define` / `/aidlc-v3 develop` が起動できる
- [ ] v2（`skills/aidlc` = `/aidlc`）と共存し、`skills/aidlc/` 配下に一切の変更がない（`git diff` で確認）
- [ ] v3 の `state.json`（`.aidlc/state.json`）が v2 ドッグフーディング用 `.aidlc/`（`config.toml` / `cycles/` の v2 成果物）を破壊しない
- [ ] 更新する SKILL.md 等の Markdown が markdownlint を通過する

**技術的考慮事項**:
本ストーリーは define / develop の実行実装（ストーリー 1・3）が機能していることを前提とする。
