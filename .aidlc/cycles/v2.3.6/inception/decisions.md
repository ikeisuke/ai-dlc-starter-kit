# 意思決定記録 - v2.3.6

## DR-001: post-merge 判定の補助シグナル設計

- **ステップ**: Unit 定義レビュー（指摘 #1 対応）
- **日時**: 2026-04-19

### 背景

`#583-B`（Unit 002）の拒否判定は `--operations-stage=post-merge` を第一条件とし、未指定時は `.aidlc/cycles/{{CYCLE}}/operations/progress.md` の `completion_gate_ready=true` を補助シグナルとする初期案だった。しかし AI レビューで「`completion_gate_ready=true` は pre-merge（§7.6–§7.7 でスロット反映を完了した時点）でも真になり得るため、post-merge 固有の識別子として不十分」と指摘を受けた。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | `--operations-stage` 必須化（未指定の operations 呼び出しは exit 1） | 識別が確実。pre/post 混同が起きない | 既存呼び出し元（AI/手動）の全面改修が必要。後方互換性を損なう |
| 2 | 補助シグナルを「`completion_gate_ready=true` AND `gh pr view` で `state=MERGED`」の AND 条件に変更 | 後方互換を維持しつつ post-merge を確実に識別。`--operations-stage` 未指定のフォールバックでも誤検出しない | GitHub 実態確認が必要（`gh` 実行失敗時の扱いを要規定 → 本決定で「undecidable 扱い → 従来動作継続」に確定） |
| 3 | 別の post-merge 専用シグナル（例: `post_merge_done=true`）を progress.md に追加 | 明示的で解釈が単純 | 固定スロット仕様を拡張する必要があり、patch サイクルの範囲を超える |

### 決定

**選択肢 2（AND 条件）** を採用。`--operations-stage=post-merge` を第一条件、AND 条件（`completion_gate_ready=true` かつ `gh pr view` で PR が `state=MERGED`）を第二条件、両方に該当しない `operations` 呼び出しは従来動作とする。

### トレードオフと判断根拠

- **得たもの**: 後方互換性（`--operations-stage` 未指定でも安全に動作）、post-merge 識別の確実性（pre-merge ですり抜ける偽陰性を排除）。
- **犠牲にしたもの**: `gh pr view` 実行が 1 回追加されるわずかな処理コスト。`gh` 実行失敗時（`cli_runtime_error` 等）は第二条件を undecidable 扱いとし、従来動作（appended / created）を継続する（本決定で確定）。
- **判断根拠**: 選択肢 1 は patch サイクルの「破壊的変更しない」制約に反する。選択肢 3 は固定スロット仕様の拡張となり #581（Operations 復帰判定 new_format 完成）のスコープを侵す。選択肢 2 は既存 `phase-recovery-spec.md` §5.3 の判定源選択（new_format / legacy_format）と整合する AND 評価であり、現在の契約を超えない範囲で誤検出を排除できる。

---

## DR-002: CHANGELOG / release-notes 更新の担当 Unit

- **ステップ**: Unit 定義レビュー（指摘 #2 対応）
- **日時**: 2026-04-19

### 背景

Intent 成功基準 8 および「含まれるもの」で CHANGELOG / release-notes への `v2.3.6` エントリ追加を要件化しているが、Unit 001/002/003 のいずれにも対応責務が記載されておらず、受け皿が存在しない状態だった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 独立 Unit 004 として CHANGELOG 更新を追加 | 責務が明確、単一責任 | Unit 数が増え、PR 数も増える。patch サイクルの予算を超える |
| 2 | Unit 001〜003 各自が自分の変更分を CHANGELOG に追記 | 各 Unit PR が自己完結 | 複数 PR で CHANGELOG が競合しやすい。マージ順序依存が発生 |
| 3 | Unit 003 の責務に CHANGELOG 更新を集約（最終 Unit として担当） | 追加 Unit 不要。最終 Unit で全変更がマージ済みの状態で記載できる | Unit 003 の責務が表記統一 + CHANGELOG の 2 種類になり凝集性がやや落ちる |

### 決定

**選択肢 3（Unit 003 に集約）** を採用。Unit 003 の責務に「CHANGELOG.md への v2.3.6 エントリ追加」を追加する。実装順序としては Unit 001 / 002 のマージ後、Unit 003 を最後に着手し、Unit 001–003 の変更を束ねて CHANGELOG にまとめる。

### トレードオフと判断根拠

- **得たもの**: Unit 数維持（予算小）、PR マージ競合の回避、変更内容の一括記載。
- **犠牲にしたもの**: Unit 003 の見積もりが `0.5〜1 日` から `1 日` へ増加。凝集性が「Inception progress 表記統一」と「CHANGELOG 管理」の 2 責務に分散。
- **判断根拠**: 「スコープ大 / 予算小」のトレードオフスライダーに従い、Unit 追加を避ける。CHANGELOG は Unit 001–003 全体のまとめであり、単一 Unit に集約する運用上の整合性もある。凝集性低下は軽微（両者とも「リリース成果物整合」に寄与する作業）。

---

## DR-003: Inception progress の進捗ステップ構造を 6 ステップで確定

- **ステップ**: Unit 定義レビュー（指摘 #4 対応）
- **日時**: 2026-04-19

### 背景

`inception_progress_template.md` は 6 ステップ（Intent明確化 / 既存コード分析 / ユーザーストーリー作成 / Unit定義 / PRFAQ作成 / Construction用progress.md作成）を、`verify-inception-recovery.sh` のフィクスチャは 5 ステップ（セットアップ / インセプション準備 / Intent明確化 / ストーリー・Unit定義 / 完了処理）を使っており、どちらを正にするか未決だった。Unit 003 は「リファクタのみ。仕様変更は扱わない」と境界設定しているが、未決事項が残ると責務が曖昧になる。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | テンプレートの 6 ステップを正にする。verify フィクスチャを 6 ステップに合わせる | 現行テンプレート（Inception 実運用の正本）と一致。テンプレートと実行結果の整合性が直感的 | verify フィクスチャの大幅書き換え。既存サイクル（5 ステップ）のフィクスチャと命名が変わる |
| 2 | verify フィクスチャの 5 ステップを正にする。テンプレートを 5 ステップに縮退 | フィクスチャ変更が最小 | テンプレートから PRFAQ / Construction progress 作成の独立ステップが消えて可読性が下がる |
| 3 | 両方を残し、テンプレートと verify を別モデルで維持 | 既存変更最小 | 本 Unit の目的（統一）と矛盾。旧命名残存で #565 の本質的解消にならない |

### 決定

**選択肢 1（6 ステップを正）** を採用。`inception_progress_template.md` の 6 ステップを正本とし、`verify-inception-recovery.sh` のフィクスチャ生成関数（`gen_progress_md_*`）を 6 ステップ構造に追従更新する。既存サイクル（v1.x〜v2.3.5）の旧 5 ステップ / `Part` 表記 progress.md は**読み取り互換のみ**維持する（Intent 成功基準 7 および Story 2.2 の後方互換検証にて担保）。

### トレードオフと判断根拠

- **得たもの**: テンプレートと実運用の整合、Inception ステップ構造の明示性、#565 命名統一の意味的完結。
- **犠牲にしたもの**: verify フィクスチャの書き換えコスト、フィクスチャテストの検証時間増。
- **判断根拠**: テンプレートは Inception の正本であり、AI エージェントが生成する progress.md はテンプレート準拠が自然。verify はその検証器なので、正本（テンプレート）に追従するのが設計階層として正しい。選択肢 2 はテンプレート機能縮退を伴い、選択肢 3 は統一目的と矛盾する。この決定は `phase-recovery-spec.md` の checkpoint 名称（`completion_done` 等）には影響せず、意味論層と表現層の分離は維持される。

---

## DR-004: Draft PR 時の GitHub Actions スキップ方式

- **ステップ**: Unit 定義承認後の追加要件（ユーザーからの直接要望で Intent 拡張）
- **日時**: 2026-04-19

### 背景

ドラフト PR の期間中でも `pull_request` トリガーの 3 ワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）が毎コミットで起動し、Actions 分単位を消費していた。Inception Phase 時点の差分はレビューが確定しておらず、CI 結果を参照するタイミングも `ready_for_review` 以降のため、Draft PR 中の起動は実質的に無駄。GitHub の Actions 起動抑止には複数の実現方法が存在する。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | ジョブレベル `if: github.event.pull_request.draft == false` のみ付与（`types` は既定のまま） | 最小変更 | GitHub デフォルトの `types` に `ready_for_review` が含まれないため、Draft → Ready 遷移で発火しないケースが発生 |
| 2 | `types: [opened, synchronize, reopened, ready_for_review]` を明示し、さらにジョブレベル `if` で Draft スキップ（二段ガード） | Draft 中は 0 起動、Ready 遷移で初回起動、既存 `paths` フィルタを変更不要 | 3 本のワークフロー YAML 全てに同形の変更を加える必要がある |
| 3 | Required status checks 側で Draft を許容する運用に切り替え（CI は動くが必須扱いしない） | ワークフローの変更は不要 | Actions 分単位消費は解消されない。リソース最適化という目的に反する |
| 4 | Draft と Ready で別々のワークフローを用意 | ワークフローごとの関心が分離される | メンテナンス対象のファイル数が増える。今回のスコープに対して過剰 |

### 決定

**選択肢 2（`types` 明示 + ジョブレベル `if` の二段ガード）** を採用。

### トレードオフと判断根拠

- **得たもの**: Draft PR 中の runner 分単位消費を 0 にし（ジョブが `skipped` ステータスで完了、runner 割当なし）、Ready 遷移で確実に初回実行（runner 起動 → `in_progress` → `completed`）される構成を 3 ワークフロー共通で実現。既存 `paths` / `branches` フィルタと併存可能。workflow run レコード自体は `types` 該当イベントで作成され得るが、分単位消費はジョブが runner を割り当てた場合にのみ発生する。
- **犠牲にしたもの**: 3 本の YAML を同形で編集する必要があり、将来的に新しい `pull_request` トリガーのワークフローを追加する際は同パターンの適用を忘れないよう注意が必要（レビューコストの微増）。
- **判断根拠**: 選択肢 1 は `ready_for_review` イベントが既定の `types` に含まれず、Draft → Ready 遷移で初回発火しないケースがあり信頼できない。選択肢 3 はリソース最適化という本来目的に反する。選択肢 4 はスコープ過剰（patch サイクルで新ワークフロー追加はオーバーエンジニアリング）。選択肢 2 は GitHub 公式ドキュメントでも Draft PR スキップの標準形として紹介されている構成で、既存ワークフロー内の変更量も許容範囲。
