# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit — v3 診断コマンド `doctor` の完全診断化（`[phase]` / `[trace]` 領域追加 / #741）

## 開発の目的

v3 診断コマンド `doctor` に **`[phase]`（フェーズ導出の整合診断）** と **`[trace]`（intent → work items → designs のトレーサビリティ整合チェック）** の 2 診断領域を追加し、v3.0.0-alpha.7（Unit 003）で実装した shallow scope（9 領域）から **完全診断（11 領域）** へ拡張する。

これは Epic #736「v3 リニューアル Phase 4–7 完遂ロードマップ」の **Phase 6 の必須 follow-up**（alpha.7 で意図的に defer した 2 領域）にあたる。alpha.7 では `[phase]` / `[trace]` を「フェーズ導出 / cross-artifact trace の code 化が要るため alpha.8 へ defer」と明記してリリースしており、本サイクルでこの最後の 2 領域を埋めることで、doctor が v3 のフルサイクル（define → develop → release → reflect）の整合性を着手前に診断できる完成状態に到達する。Phase 7（dogfooding + 本流化）の前提を完全に揃える。

設計 SoT は `docs/v3/data-model.md §5（フェーズ導出）/ §6（破損・矛盾）/ §8（size×depth_level）/ §9（trace chain）`、`docs/v3/workflow.md §3.6（doctor 段階スコープ）/ §7.3（trace chain）`、`docs/v3-renewal-plan.md Phase 6`。

## ターゲットユーザー

- **AI-DLC（v3）を使う開発者**: `/aidlc-v3 doctor` で、環境・状態の shallow 診断（alpha.7 の 9 領域）に加えて、(a) 現在どのフェーズに居るか（導出根拠付き）、(b) intent → work items → designs の参照が揃っているか（design 欠落・dependencies 不整合など）を着手前に確認できる。
- **本キットのドッグフーディング開発者（自分）**: Phase 7 で v3 を本流化する前提として、doctor の完全診断（11 領域）を必要とする。

## ビジネス価値

- doctor が「環境・状態の shallow 診断」だけでなく「フェーズ導出の整合」「trace chain の参照整合」まで一括診断できるようになり、Epic #736 Phase 6 を**真に完了**（alpha.7 で残した必須 follow-up を解消）させる。
- フェーズ導出ロジック（`data-model.md §5`）が doctor 内で code 化されることで、状態と work item の組み合わせから導かれるフェーズが SoT と一致しているかを機械的に検証でき、v3 の状態管理の信頼性を高める。
- trace chain の参照欠落（size:normal なのに design がない 等）を診断時点で検出でき、release 直前ではなく着手前に不整合を発見できる。
- v3 設計目標「v2 の分散した診断（preflight + recovery spec）を doctor に集約」を、phase/trace まで含めた完全形で実証する。

## 成功基準

### `[phase]` 領域

- `skills/aidlc-v3/scripts/doctor.sh` に `diagnose_phase` 相当を追加し、`data-model.md §5.1` の first-match 導出規則（評価順: complete → define → develop → release 可能）に**整合**したフェーズを導出して表示する。
- severity は **OK**（導出成功）とし、`report()` 契約（`[area] severity detail`）に従って **detail に導出フェーズと根拠を併記**する。例: `[phase]  OK    develop (derived: define_completed=true, 2 items remaining)`。severity トークン（OK/WARN）が領域ラベル直後に来る既存 doctor 出力契約を厳守する（後述「severity / 出力整合」参照）。
- 入力は既存依存スクリプト経由で取得する（`state-read.sh` の `define_completed` / `release.merge_approved` / `release.pr_number`、work item status は `work-item-status.sh`）。**doctor は診断のみで状態を変更しない**（read-only 維持）。
- **`complete` 導出の PR merged 実態確認**（`data-model.md §5.1` 評価順1 / §9 DG-5「complete 判定の PR merged 確認は core 範囲」）: `release.merge_approved=true` の場合のみ、`release.pr_number` を用いて gh で **read-only に PR が merged 状態か**を確認し、merged のときだけ `complete` を導出する。以下のいずれかで確認不能な場合は **`complete` に導出せず**、§5.1 の評価順2以降（develop / release 可能）にフォールバックする: (a) gh 利用不可（`gh_status != available`）、(b) `release.pr_number` が null、(c) PR 状態取得失敗。`merge_approved=true` かつ PR が未 merged（または確認不能）の不一致は **WARN を併記**する（`data-model.md §6` の `release.merge_approved:true だが未 merged` 行に整合）。
- state.json 不在 / `define_completed=false` 時は define フォールバック（§5.1 評価順2 / workflow §2.3 整合）として扱い、診断不能で落とさない。
- `state.json` と frontmatter の矛盾（例: `define_completed=false` なのに `done` の work item が存在）は導出を**安全側（define / develop 継続可能側）に倒し**、WARN で報告する（`data-model.md §6`、自動解決しない）。

### `[trace]` 領域

- `doctor.sh` に `diagnose_trace` 相当を追加し、**本サイクルでは「design 必須の work item に対応する design ファイルが存在するか」の確認に限定**する。intent.md の存在検証、work item 本文 Traceability セクション（Intent refs / Acceptance refs 等）の意味的妥当性検証は**本サイクルのスコープ外**とする（trace chain 後段や意味検証は将来サイクル）。
- **design 必須判定**は `data-model.md §8` の size×depth_level マトリクスを**唯一の正本**とする。design 要否は以下のとおり（§8 表を正確に反映）:
  - **design 必須**: `normal × standard` / `normal × comprehensive` / `risky × standard` / `risky × comprehensive`
  - **design 不要**: `tiny × minimal` / `tiny × standard` / `tiny × comprehensive` / `normal × minimal`
  - **不正組み合わせ**: `risky × minimal`（§8 で「risky は minimal 不可」）。design 欠落としてではなく**設定不整合として WARN（exit 0 維持）**で報告する（ERROR にはしない。診断不能ではなく設定上の不整合のため）。複数判定が増える場合も §8 の表を直接参照して網羅する。
- size は共有パーサ `lib/frontmatter.sh`（`fm_scalar`）経由で取得し、depth_level は `read-config.sh rules.depth_level.level` で取得する。**`read-config.sh` がキー未設定（rc1）を返す場合は `data-model.md §8` の既定値に従い `depth_level=standard` として要否判定する**。
- design 必須の work item に対し `designs/<id>-<slug>.md`（work item と同一ファイル名 / `develop.md:139-147,202`）が**存在しない場合は WARN**（`workflow.md:199` / `data-model.md §6` の方針）。
- 既存の `work-item-validate.sh` が担う **dependencies 実在検証とは役割を分担**し、`[trace]` は cross-artifact trace（design ファイル存在）に焦点を当てる（重複診断を避ける旨を doctor.md に明示）。
- severity は design 存在 = **OK**、欠落 / 不正組み合わせ = **WARN** とし、`report()` 契約（`[area] severity detail`）に従う。`[trace]` も read-only。

### severity / 出力整合

- **既存 `report()` 契約の厳守**: 新領域 `[phase]` / `[trace]` も既存 doctor と同じ `report <name> <severity> <detail>` 経由で出力し、`report()` の整形（`printf '%-14s%-6s%s'`）により **`[area]` の直後に severity トークン（OK / WARN / ERROR）が来る**形式を守る。`workflow.md` の defer 出力例（`[phase] develop (...)` / `[trace] WARN: ...`）は severity トークン位置が曖昧なため、**実装・テストとも `[phase]  OK  develop (derived: ...)` / `[trace]  WARN  <detail>` のように severity トークンを領域ラベル直後に固定**し、出力例ドキュメントも本形式へ揃える。
- `[phase]` は導出成功時 OK（detail に導出フェーズ + 根拠）、`complete` 不一致など矛盾時は WARN。`[trace]` は design 存在 OK / 欠落・不正組み合わせ WARN。
- `report()` の固定幅出力（`%-14s`）に新ラベル `[phase]`（7 文字）/ `[trace]`（7 文字）が問題なく収まることを確認する（最長は既存 `[parse-guard]`）。
- 総合 exit code 集約ロジック（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > OK）に新領域の severity を正しく反映する（WARN は exit 0 を維持、診断不能のみ exit 2）。
- 契約テスト（`test-doctor.sh`）は `assert_area <area> <severity>` で **severity トークンを検証**する既存パターンに合わせ、`[phase]` / `[trace]` の severity を機械的にアサートできる形式とする。

### テスト（契約テスト必須）

- `skills/aidlc-v3/scripts/tests/test-doctor.sh` を拡張し、`[phase]` / `[trace]` の両領域を契約テストで検証する。少なくとも以下を網羅する:
  - `[phase]`: define（state 不在 / `define_completed=false`）、develop（`define_completed=true` かつ未完 work item あり）、release 可能（全 work item が done/withdrawn）、complete（`merge_approved=true` かつ PR merged）の各導出ケース + 根拠文字列の検証。
  - `[trace]`: design 必須かつ design 存在（OK）、design 必須かつ design 欠落（WARN）、design 不要（`normal × minimal` / `tiny × *`）で design なし（OK）、`normal × comprehensive` で design 必須（欠落 → WARN）、不正組み合わせ `risky × minimal`（WARN 固定）、`depth_level` 未設定（rc1）で `standard` として要否判定される各ケース。
- 「全領域 OK 正常系」テストを **9 領域 → 11 領域**へ拡張する。
- 既存 v3 テスト（`skills/aidlc-v3/scripts/tests/`）が green を維持する。

### SoT 注記の更新（alpha.8 defer → 実装済み）

- `skills/aidlc-v3/steps/doctor.md`: 「9 領域」→「11 領域」、診断領域テーブルに `[phase]` / `[trace]` 追加、出力例に 2 行追加、末尾「## alpha.8 defer」セクションを実装済み記述へ置換。`[trace]` と `[work-items]` の役割分担（dependencies 実在検証 vs design 存在）を明示。
- `docs/v3/workflow.md`: §3.6 段階スコープ注記（`:160-161`）、チェック項目テーブル（`:176-177`）、出力例（`:195-200`）、コマンド体系テーブル（`:31`）の「alpha.8 defer」を「実装済み」へ更新。
- `docs/v3-renewal-plan.md`: doctor セクション（`:905` / `:917-918` / `:940-944`）と Phase 6 完了条件（`:1092`）の「alpha.8 defer」を「実装済み」へ更新。

### 用語整合

- doctor 全体の領域カウント表記を「11 領域」で統一する（`doctor.sh` ヘッダの「9 領域」表記、ドキュメントの「8 領域 + parse-guard」表記の揺れを `[phase]` / `[trace]` 追加に合わせて解消）。

## 期限とマイルストーン

- サイクル: **v3.0.0-alpha.8**（Epic #736 Phase 6 の必須 follow-up / 小〜中規模）。
- 後続: Phase 7（dogfooding + 本流化 / `aidlc-v3 → aidlc` 置換）→ v3.0.0 RC→GA。
- 本サイクルは Inception → Construction → Operations を通常どおり v2（`/aidlc`）で進行する（v3 の dogfooding 適用は Phase 7）。
- 本 Intent は Epic #736 を `Relates to #736`、実装元 Issue を `Closes #741` で紐付け、進捗 SoT のトレースを繋ぐ。

## 含まれるもの（スコープ）

- `skills/aidlc-v3/scripts/doctor.sh` への `[phase]` / `[trace]` 2 診断領域の追加（`diagnose_phase` / `diagnose_trace`、実行順序への組み込み、wrap 契約コメント追記、領域カウント更新）。read-only / 自動修正なしを維持。
- `[phase]` のフェーズ導出 code 化（`data-model.md §5` 整合 / 根拠併記 / 既存 `state-read.sh` ・ `work-item-status.sh` 再利用）。
- `[trace]` の trace 整合チェック（design 必須判定は `data-model.md §8` size×depth マトリクスを正本とし全組み合わせを網羅 / `risky × minimal` 不正組み合わせ報告 / `depth_level` 未設定時 `standard` フォールバック / design ファイル存在チェックに限定 / `lib/frontmatter.sh` 経由の size 取得 / `work-item-validate.sh` との役割分担）。
- `skills/aidlc-v3/scripts/tests/test-doctor.sh` への `[phase]` / `[trace]` 契約テスト追加と「全領域 OK」正常系の 11 領域化。
- `skills/aidlc-v3/steps/doctor.md` の更新（領域数 / テーブル / 出力例 / defer セクション置換 / 役割分担明示）。
- `docs/v3/workflow.md §3.6`・コマンド体系、`docs/v3-renewal-plan.md` doctor セクション・Phase 6 完了条件の「alpha.8 defer」→「実装済み」更新。
- doctor 領域カウント表記の用語整合（11 領域で統一）。

## 含まれないもの（スコープ外）

- doctor の自動修正機能（read-only / 診断のみの原則を維持。修正提案の文言追加は範囲内だが、状態書き換えは実装しない）。
- `[phase]` / `[trace]` 以外の新規診断領域の追加。
- フェーズ導出規則（`data-model.md §5`）そのものの仕様変更（doctor は既存規則を code 化して診断するのみ）。
- trace chain 後段（`reviews/*.md` / `journal.md` / `release.md` / `reflect.md`）の整合診断（本サイクルは intent → work items → designs の前段に限定）。
- `[trace]` における intent.md 存在検証、work item 本文 Traceability セクション（Intent refs / Acceptance refs 等）の**意味的妥当性検証**（本サイクルは design ファイル存在確認に限定）。
- Phase 7 関連作業（本流化 / `aidlc-v3 → aidlc` 置換 / marketplace v3.0.0 化 / v2→v3 migration）。
- 他のオープン backlog（#740 squash-unit range bug、#721 等）の対応。

## 制約事項

- **新規パース禁止規約**: frontmatter は共有パーサ `lib/frontmatter.sh`（`fm_scalar` / `fm_deps` 等）経由で取得し、`[phase]` / `[trace]` 関数が独自パースを書かない（`lib/frontmatter.sh:24-30`）。
- **read-only 厳守**: doctor は state.json / work item / config を一切変更しない（`doctor.sh:11-13`）。
- **既存 wrap パターン踏襲**: 依存スクリプトの exit code / stdout prefix を severity に写像する既存パターンに従い、診断ロジックを領域関数内に閉じる。
- **SoT 整合**: フェーズ導出 / trace 整合の判定は `docs/v3/data-model.md` を正本とし、doctor 側で独自規則を作らない。
- **テスト前提**: `test-doctor.sh` は自己完結ハーネス（fixture + stub / jq 前提 / ネットワーク非依存）の既存方針を維持する。

## 不明点と質問（Inception Phase中に記録）

（現時点で重大な不明点なし。#741 の受け入れ基準と data-model.md §5/§8/§9 が明確なため、設計レベルの細部（`[trace]` と `[work-items]` の境界の具体実装、根拠文字列の正確な書式）は Construction Phase の設計ステップで確定する。）
