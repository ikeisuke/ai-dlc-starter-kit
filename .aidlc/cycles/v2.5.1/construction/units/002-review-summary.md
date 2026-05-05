# レビューサマリ: Unit 002 retrospective Issue 一本化 + spool + mirror_state ラベル化

## 基本情報

- **サイクル**: v2.5.1
- **フェーズ**: Construction
- **対象**: Unit 002 retrospective Issue 一本化 + spool + mirror_state ラベル化

---

## Set 1: 2026-05-05

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex
- **反復回数**: 5（指摘 7 → 4 → 2 → 1 → 0 件 / 千日手検出なし、各 round で別系統の指摘を順次解消）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto / unresolved_count=0）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | 設計 round 1: §1.5 で Unit 003 フックを起票前 prefill と起票後 update の 2 段に分離する責務境界 | 修正済み（plan §1.5 改修案に Step 6 追加 + `human_reviewed` 付与責任 Step 別分離テーブル / domain model `RetrospectiveIssue` 集約に状態遷移追加） | - |
| 2 | 高 | 設計 round 1: スプールフォーマット（Markdown 区切り + body-start/end マーカー）が脆弱で曖昧性ゼロを担保できない | 修正済み（plan / domain / logical で NDJSON + base64 + SHA256 + UUID + flock 排他に変更） | - |
| 3 | 中 | 設計 round 1: 互換アダプタ層（retrospective-generate.sh / retrospective-mirror.sh）の保証 / 非保証 / 廃止予定が未固定 | 修正済み（plan に保証範囲表 + 旧→新 意味マッピング表追加 / logical design に同期） | - |
| 4 | 中 | 設計 round 1: retrospective_issue_create() の exit code が `failed` でも 0 で上位が失敗を正常扱いしやすい | 修正済み（exit code 規約を `failed → exit 1` / `created/skipped/spooled → exit 0` に分離 + §1.5 改修案で必須分岐明記） | - |
| 5 | 中 | 設計 round 1: mirror_state 状態語彙の旧→新正規化責務が不明確 | 修正済み（plan に canonical 一覧 + 旧語彙正規化規則表 + 正規化責務 1 箇所集約 `_normalize_mirror_state` 仕様追加） | - |
| 6 | 低 | 設計 round 1: 完了条件チェックリストで Unit 003/004 への consumer モック固定の逆方向非依存検証観点が弱い | 修正済み（plan 完了条件に「逆方向非依存テスト」「逆方向非依存検証」項目を追加） | - |
| 7 | 高 | 設計 round 2: retrospective_body_compose / retrospective_issue_create の I/F が plan / 論理設計で path/string/2引数/3引数 の混在 | 修正済み（plan §「I/F 正本の統一規則」を新設し、path 渡し 3 引数 + 純粋関数 `_pure_compose_body` を内部公開する形で 3 資料統一） | - |
| 8 | 高 | 設計 round 2: spool エントリに partial 起票識別子（local 二重起票防止）が不足 | 修正済み（spool スキーマに `id` / `retry_target` / `partial_state.{local_created,mirror_created}` を追加 / partial 時 `retry_target=mirror` で local 再起票回避） | - |
| 9 | 中 | 設計 round 2: ドメイン純粋層と Orchestration 層の境界が論理設計で曖昧 | 修正済み（`_pure_compose_body(string,string,string)` を純粋関数として内部公開し、`retrospective_body_compose(path,path,string)` は薄い wrapper として分離） | - |
| 10 | 中 | 設計 round 2: 互換アダプタ層 `recorded:pending` の意味マッピング未確定 | 修正済み（canonical を `created` 互換扱い + warn 必須に確定 / `legacy-deferred` は導入せず / 非保証として明示） | - |
| 11 | 中 | 設計 round 2: Unit 003 フック未定義時 / 失敗時の契約が未固定 | 修正済み（plan / logical design に「未定義時 no-op / prefill 失敗 → 空 YAML / update 失敗 → 警告のみで §1.5 継続」の契約を明文化） | - |
| 12 | 中 | 設計 round 2: NDJSON パース・追記・削除の堅牢性で同一エントリ識別子・排他更新・部分書込時の整合戦略が不足 | 修正済み（UUID v4 + `id` ベース削除 + `flock` 5 秒タイムアウト + 一時ファイル + 原子的 `mv` 置換を設計） | - |
| 13 | 低 | 設計 round 2: 擬似コードに `$(...)` が多数残存（プロジェクト規約違反を誘発） | 修正済み（擬似コードをリダイレクト + `read` 形式に書換 + 「禁止 vs 採用」対応表を実装注意事項に追加） | - |
| 14 | 高 | 設計 round 3: retrospective_issue_create I/F 正本未統一（plan 内に旧 2 引数記述が混在） | 修正済み（plan の旧見出し・§1.5 テーブル・完了条件チェックリストの 3 箇所を path 渡し 3 引数に統一） | - |
| 15 | 高 | 設計 round 3: recorded:pending canonical マッピング矛盾（plan 内に `pending` と `created` 互換の両方が併存） | 修正済み（plan 旧語彙正規化規則表を `created` 互換扱い + warn 必須に確定 / 3 資料同期） | - |
| 16 | 中 | 設計 round 3: spool NDJSON サンプルが必須フィールド欠落版（id / retry_target / partial_state なし） | 修正済み（v1 必須 11 キー完全版サンプルに差し替え + partial 起票例も併記） | - |
| 17 | 中 | 設計 round 3: domain model の Q/A が SSOT 凍結状態でない（recorded:pending で論理設計と食い違い） | 修正済み（domain model 「不明点と質問」を「確定事項（SSOT）」セクションに昇格し、plan / logical の決定と完全同期） | - |
| 18 | 中 | 設計 round 4: retrospective-validate.sh --apply の I/F 不一致（stdout 返却 vs ファイル書換） | 修正済み（`--apply` を「常に stdout 返却 / 呼出側がリダイレクトで適用」に確定 / 3 資料同期） | - |
| 19 | 低 | 設計 round 4: plan のテスト記述に旧語彙「マーカー間抽出パース」が残存 | 修正済み（NDJSON v1 必須 11 キー検証 / fenced block 抽出 + 1 行 1 JSON parse / id ベース削除 / partial / 排他 / SHA256 へ更新） | - |
| 20 | 中 | 設計 round 5: retrospective-resend.sh の exit code 規約が plan / logical 間で不整合（0=全件成功 vs 0=部分失敗含み走り切り） | 修正済み（`failed が 1 件以上 → exit 1` / `created/skipped のみ → exit 0` / 引数・spool 不正 → exit 2 で 3 資料統一） | - |

### サマリ

- 高: 6 件（解消済 6）
- 中: 11 件（解消済 11）
- 低: 3 件（解消済 3）
- **合計**: 20 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統の指摘）
- 反復 5 回（review-flow.md の上限 3 回を超過した round 4-5 は指摘軽減傾向のため継続実施 / round 5 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=20`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

---

## Set 2: 2026-05-05（コードレビュー）

- **レビュー種別**: コードレビュー（focus: code, security）
- **使用ツール**: codex（read-only モード / file-based stdin）
- **反復回数**: 1（指摘 6 件 → 全件即時反映）
- **結論**: 指摘 6 件全件解消 → `auto_approved`

### 指摘一覧

| # | 重要度 | focus | 内容 | 対応 |
|---|--------|-------|------|------|
| 1 | 高 | architecture | retrospective-resend.sh が retry_target / partial_state を尊重していない（local 二重起票リスク） | 解消（AIDLC_RETRO_FORCE_TARGET / AIDLC_RETRO_SKIP_LOCAL 環境変数経由で local 二重起票防止） |
| 2 | 高 | architecture | retrospective_issue_create に cap 判定経路が未実装（Plan / Logical Design 出力契約欠落） | 解消（AIDLC_RETRO_CURRENT_COUNT / AIDLC_RETRO_LIMIT 環境変数による cap 判定追加 / §1.5 から渡す） |
| 3 | 高 | security | cycle 未検証で spool_path に埋め込み（path traversal 可能） | 解消（`__retro_validate_cycle` 追加: `^[A-Za-z0-9._-]+$` + 予約名拒否） |
| 4 | 中 | code | _spool_append / _spool_remove_by_id でロック取得後の trap 不在 → リーク懸念 | 解消（subshell + trap で lock_dir / tmp_path 自動 cleanup） |
| 5 | 中 | code | mirror_state ラベル付け替え失敗が warn のみで成功扱い | 解消（3 回リトライ / 指数バックオフ + 失敗時 spool 退避 mirror_state=pending） |
| 6 | 低 | code | retrospective-resend.sh の LOCAL_CREATED 等が未使用 | 解消（指摘 #1 の SKIP_LOCAL 算出に使用） |
| 7 | 低 | code | §1.5 の `$()` 規約準拠 | 問題なし（変更不要） |

### サマリ

- 高: 3 件（解消済 3）
- 中: 2 件（解消済 2）
- 低: 1 件（解消済 1 / +指摘なし 1）
- **合計**: 6 件指摘 → 全件解消

### シグナル

- `review_detected=true`
- `resolved_count=6`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

---

## Set 3: 2026-05-05（統合レビュー）

- **レビュー種別**: 統合レビュー（設計-実装整合 / テストカバレッジ / 規約 / 互換）
- **使用ツール**: codex（read-only モード / file-based stdin）
- **反復回数**: 1
- **結論**: codex は明示的指摘形式を返さず、検証として bats / shellcheck / check-bash-substitution.sh を実行。既存テスト退行 9 件を検出 → 全件解消 → `auto_approved`

### 検出退行と対応

| 種別 | 内容 | 対応 |
|------|------|------|
| 既存テスト退行 | tests/retrospective/ の F1, F3, F5, F6, F7, GE1, GE1b, GE3, GE5, GE6 が v2.5.1 仕様変更で失敗 | 解消（テストを互換アダプタ層保証範囲に追従 / ファイル生成期待を撤廃 / gh shim を helper に追加） |
| 既存テスト退行 | tests/retrospective/ IS1, IS2, IS3 が §1.5 セクション見出し変更で失敗 | 解消（`Issue 起票フロー` / `unit002-retrospective-issue-only` アンカーへ追従） |
| 副次バグ | retrospective-generate.sh が cycle path traversal で sed 構文エラー（exit 1）を吐く | 解消（`__retro_validate_cycle` を sed 前に呼ぶ / 互換アダプタ exit 2 を保証） |
| 副次バグ | テスト副作用がリポジトリ内に漏れる（`__retro_spool_path` が cwd 相対） | 解消（AIDLC_PROJECT_ROOT 指定時は絶対パス返却） |

### 最終検証結果

- BATS: 全 113 テスト pass（新規 52 + 既存 61 / 退行ゼロ）
- shellcheck: warning 以上ゼロ
- bin/check-bash-substitution.sh: violations 0（プロジェクト規約準拠）

### シグナル

- `review_detected=true`
- `resolved_count=4`（テスト退行 + 副次バグ）
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`
