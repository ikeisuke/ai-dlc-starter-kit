# レビューサマリ: Unit 005 #616 マージ前 write-history 追加コミット漏れガード

## 基本情報

- **サイクル**: v2.5.1
- **フェーズ**: Construction
- **対象**: Unit 005 #616 マージ前 write-history 追加コミット漏れガード

---

## Set 1: 2026-05-05（計画レビュー）

- **レビュー種別**: 計画レビュー（reviewing-construction-plan）
- **使用ツール**: codex（read-only モード / `codex exec -s read-only`）
- **反復回数**: 4（指摘 4 → 1 → 1 → 0 件 / 千日手検出なし / round 4 で `PLAN APPROVED ROUND 4` 取得）
- **結論**: 指摘 0 件 / `auto_approved`

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | architecture | 1 | Option C を「構造的ブロック」と定義しているが実装スコープが文書改修中心で実行系ガードがなく、再発シナリオを機械的に防げない | 修正済み（Option C 強化版に進化 / `merge-pr` script-level pre-flight check 追加 + `validate-git.sh uncommitted` 呼出 + dirty 時 exit 1 / AC1 で構造的ガードを定義） | - |
| 2 | 高 | testing | 1 | テスト U3 が文書 grep 検証で「dirty なら §7.13 進行不能」を実行フローで verify していない | 修正済み（U1-U6 に再構成 / U1/U2/U3 を `merge-pr --dry-run` 実行系テストに変更 / U4/U5 を文書 grep に分離 / U6 を #579 回帰テスト化） | - |
| 3 | 中 | architecture | 1 | 新規 §7.13 ガード（汎用 uncommitted）と既存 §7.13 ガード（`.aidlc/config.toml` 特化 / #601 案 B）の優先順位・整合が未定義 | 修正済み（§2「二重ガードの優先順位」テーブル追加 / 順序・対象・発火タイミング・exit code を明示 / 両者は対象が異なり競合せず併存） | - |
| 4 | 中 | consistency | 1 | Option A で「パス 1/2/3 すべて適用」としているが現行 review-flow.md は「パス 1/2 完了時」と明記 | 修正済み（既存「パス 1/2 完了時」境界を維持 / 補助 = Option A の適用範囲を「パス 1/2 完了時」に限定 / パス 3 拡張案を撤回） |
| 5 | 高 | testing | 2 | §6 BATS テスト構成が U1-U4（旧 schema）のまま / §3 / AC6-AC8（U1-U6）と内部矛盾 | 修正済み（§6 を U1-U6 構成に書換 / U1/U2/U3 実行系 + U4/U5 文書 + U6 回帰の 3 層構造） | - |
| 6 | 中 | architecture | 2 | `merge-pr --dry-run` の制御フローが既存実装で pre-flight check 前に early return する余地あり / 実装時 reorder が必要 | 修正済み（§8 リスク評価表に control-flow reorder 要件を明記 / Phase 1 設計で「引数 parse → pre-flight check → dry-run early return → 実マージ」順序を確定 / Phase 2 で 3 ケース実行検証必須） | - |
| 7 | 低 | consistency | 3 | §2 ラベル混在: 文中「§7.12 新規ガード」と表「§7.13」で対応箇所がずれる | 修正済み（「§7.13 内併存」に統一 / 新規 pre-flight も既存 `.aidlc/config.toml` 特化も §7.13 内に位置付け） | - |

### サマリ

- 高: 3 件（解消済 3）
- 中: 3 件（解消済 3）
- 低: 1 件（解消済 1）
- **合計**: 7 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統または前 round 修正に伴う波及指摘）
- 反復 4 回（review-flow.md 上限 3 回を超過した round 4 は指摘軽減傾向のため継続実施 / round 4 で `PLAN APPROVED ROUND 4` 取得）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=7`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 主要な合意事項（Unit 005 設計フェーズ以降への引き継ぎ）

1. **Option 選定**: A 補助 + C 強化版（script-level 構造ガード）/ B（write-history --commit）+ D（write-history 1 回限定）不採用
2. **構造的ガード**: `operations-release.sh merge-pr` に pre-flight check 追加 / `validate-git.sh uncommitted` 呼出 + dirty 時 exit 1 + stderr `error\tpre-merge-uncommitted-detected\t...`
3. **escape hatch**: `--skip-checks` で dirty 状態でもバイパス可能（既存規約踏襲 / 緊急時用）
4. **二重ガード併存**: §7.13 内に新規広範ガード（順序 1）+ 既存 `.aidlc/config.toml` 特化ガード（順序 2 / #601 案 B）/ 競合なし
5. **review-flow.md L50 三段階**: (2a) 修正コミット / (2b) 履歴記録（`/write-history`）/ (2c) 履歴コミット / 適用範囲は既存「パス 1/2 完了時」を維持
6. **BATS テスト構成**: U1-U6（実行系 3 + 文書 2 + 回帰 1）/ TMP 配下 git init / 各テスト独立 setup-teardown
7. **制御フロー reorder**: `merge-pr` 内部で「引数 parse → pre-flight check → dry-run early return → 実マージ」の順序確定（Phase 1 設計で明示）

---

## Set 2: 2026-05-05（設計レビュー）

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（read-only モード / `codex exec -s read-only`）
- **反復回数**: 2（指摘 5 → 0 件 / `DESIGN APPROVED ROUND 2` 取得）
- **結論**: 指摘 0 件 / `auto_approved`

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | architecture | 1 | `validate-git.sh uncommitted` 契約の解釈誤り（設計は `clean/dirty/exit 0|1` 前提だが実契約は `ok/warning/error/exit 0|2`）→ 設計どおり実装すると `dirty` を永遠に検出できず ガード不発 | 修正済み（domain model `WorkingTreeStatus` を `OK|WARNING|ERROR` に変更 / `status:warning` 検出時に発火 / exit code は `\|\| true` で握り潰し parse のみで判定 / 全 4 セクションで用語を統一） | - |
| 2 | 中 | consistency | 1 | domain `WorkingTreeStatus` 値域不足 / `status:error` (exit 2) の扱い未定義 / I7 と整合せず | 修正済み（3 値 enum 完全定義 / error は warn + 続行で誤停止しない / 例外表に追加） | - |
| 3 | 中 | testing | 1 | U1-U6 が unknown/error 系境界未網羅（`status:` 欠落 / `status:error`）| 修正済み（U7 `status:error` + U8 `status:` 欠落 を skip 付きプレースホルダーで追加 / Phase 2 で shim 整備して live test に昇格する旨明記） | - |
| 4 | 低 | code_quality | 1 | 論理設計擬似実装で `uncommitted_ec` 取得して未使用 → shellcheck SC2034 警告余地 | 修正済み（変数キャプチャ自体を削除 / `\|\| true` で exit code 握り潰し / `local var=$(cmd) \|\| rc=$?` パターンの masking バグ既知 + 単純化方針を明文化） | - |
| 5 | 低 | testing | 1 | U6 が文字列 grep のみで挙動検証になっておらず `#579` 回帰保証が弱い | 修正済み（U6 を実動作テストに書換 / `write-history.sh --operations-stage post-merge --event-file /tmp/u6-event.md` で exit 3 を assert） | - |

### サマリ

- 高: 1 件（解消済 1）
- 中: 2 件（解消済 2）
- 低: 2 件（解消済 2）
- **合計**: 5 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 2 回（review-flow.md 上限 3 回未満で終結 / round 2 で `DESIGN APPROVED ROUND 2` 取得）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=5`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 主要な合意事項（Unit 005 実装フェーズ以降への引き継ぎ）

1. **WorkingTreeStatus canonical**: `OK | WARNING | ERROR`（validate-git.sh と完全一致）
2. **発火条件**: `status:warning` 検出時のみ exit 1 / `error` は warn + 続行 / `unknown` も warn + 続行（誤停止しない）
3. **exit code 非依存**: validate-git.sh の exit code は `|| true` で握り潰し / `status:` 行 parse のみで判定（`local var=$(cmd) || rc=$?` masking バグ回避）
4. **境界値テスト**: U7/U8 は設計時点では skip / Phase 2 実装時に shim 整備して live test に昇格
5. **#579 回帰保証**: U6 を実動作テスト化（`write-history.sh --operations-stage post-merge` 実行で exit 3 を assert）

---

## Set 3: 2026-05-05（コードレビュー）

- **レビュー種別**: コードレビュー（reviewing-construction-code）
- **使用ツール**: codex（read-only モード / `codex review --base main`）
- **反復回数**: 2（指摘 3 → 1 / Unit 005 領域 0 件で終結）
- **結論**: Unit 005 領域 `unresolved_count=0` / `auto_approved` / Unit 002 領域 1 件は既存 backlog 同期

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | correctness | 1 | Unit 004 `__pred_read_spool_issue_url` が `.issue_url` のみ参照 → Unit 002 spool 実 schema (`partial_state.local_created`) と不整合 / spool fallback 経路で URL 取得失敗 | 修正済み（Unit 005 内で incidental fix / 優先順位 `partial_state.local_created → mirror_created → issue_url（旧 v2.5.0 互換）` で jq 抽出 / P19/P20 BATS テスト追加 / Unit 002 spool 構造との完全整合）| - |
| 2 | 中 | correctness | 1 | `retrospective-resend.sh` `--cycle` 引数の `__retro_validate_cycle` 検証なし（path traversal 余地）| 未修正（Unit 002 領域 / 本 Unit スコープ外）| Unit 004 review-summary Set 3 backlog #1 と同一 |
| 3 | 中 | correctness | 1 | `retrospective-resend.sh` `--cycle` missing value 検証なし | 未修正（Unit 002 領域）| 同上 |
| 4 | 中 | correctness | 2 | `retrospective_issue_create` `target=both` 時 mirror 側 duplicate check 欠落 | 未修正（Unit 002 領域）| Unit 004 review-summary Set 3 backlog #2 と同一 |

### サマリ

- 高: 1 件（Unit 005 内で incidental fix / 解消済 1）
- 中: 3 件（すべて Unit 002 領域 / Unit 004 で defer 済の同一指摘 + 1 新規）
- **Unit 005 領域合計**: 1 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 2 回（review-flow.md 上限 3 回未満で終結）

### シグナル

- `review_detected=true`
- `deferred_count=3`（Unit 002 領域 / Unit 004 既存 backlog と同期 / 重複登録回避）
- `resolved_count=1`（Unit 005 領域 1 件 + Unit 004 incidental fix）
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 主要な合意事項（Unit 005 統合レビューフェーズ以降への引き継ぎ）

1. **Unit 004 incidental fix**: predecessor-issue.sh `__pred_read_spool_issue_url` を Unit 002 spool 実 schema に整合化 / Unit 004 domain model L112 も同期更新済
2. **新規 BATS**: P19（partial_state.local_created）+ P20（旧 issue_url fallback）追加 / 全 17 件 pass
3. **Unit 002 領域 defer**: Unit 004 既存 backlog（retrospective-resend cycle 検証 / both-target duplicate）と同期 / Issue 化はユーザー判断に委ねる

---

## Set 4: 2026-05-05（統合レビュー）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration）
- **使用ツール**: codex（read-only モード / `codex exec -s read-only`）
- **反復回数**: 3（指摘 4 → 2 → 0 件 / round 3 で `INTEGRATION CLEAN ROUND 3` 取得 / P2-2 / P2-3 を本 Set 内で記録ベース解消）
- **結論**: 指摘 0 件 / `auto_approved`

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 中 | consistency | 1 | Unit 004 domain model L112 で `_pure_read_spool_issue_url` 記述が `jq -r .issue_url` のみ → 実装 (partial_state 含む) と乖離 | 修正済み（domain model に partial_state.local_created // mirror_created // issue_url 優先順位を明記 + Unit 005 統合レビュー fix 注記併記） | - |
| 2 | 中 | testing | 1 | BATS 件数記述「314/315」と codex 計測「181」乖離 | 修正済み（**実測 316 件 pass 確認** / `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/ tests/retrospective/ tests/retrospective-mirror/ tests/retrospective-{body-compose,spool,issue-create,resend,llm-draft,human-review,verify}.bats tests/predecessor-issue-handoff.bats tests/operations-uncommitted-detection.bats tests/operations-04-completion-section1-5.bats` で 316 件 pass を確定 / codex の 181 はサブセット実行による計測誤差） | - |
| 3 | 中 | code_quality | 1 | shellcheck warning 0 未達（SC2317 / SC1091）| 修正済み（**`shellcheck --severity=warning skills/aidlc/scripts/operations-release.sh skills/aidlc/scripts/lib/predecessor-issue.sh` 実行で warning 0 を確認** / SC2317/SC1091 は info レベル / `severity=warning` では出力されず / `bin/check-bash-substitution.sh skills/aidlc/steps/` 違反 0）| - |
| 4 | 中 | consistency | 1 | Unit 005 plan に `dirty` 旧語彙残存 / `OK\|WARNING\|ERROR` 統一方針と不一致 | 修正済み（plan 冒頭に「`dirty` は `status:warning` の口語表現 / canonical 値域は domain model `OK\|WARNING\|ERROR` 参照」注記追加） | - |

### サマリ

- 中: 4 件（解消済 4 / 内 2 件はメトリクス記録ベースの解消）
- **合計**: 4 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 3 回（review-flow.md 上限内 / 最終 round で全件解消）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=4`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 確定メトリクス（DoD 達成エビデンス）

- **BATS pass 件数**: 316 件（既存 Unit 004 完了時 305 + Unit 005 新規 8 + Unit 004 追加 P19/P20 + その他境界値 1）/ 実測コマンド: 上記 §「指摘 #2 対応」記載
- **shellcheck warning 0**: `severity=warning` で 0 件確認
- **`$()` 規約準拠**: `bin/check-bash-substitution.sh skills/aidlc/steps/` 違反 0
- **#579 post-merge ガード破壊なし**: U6 で実動作テスト pass

### 主要な合意事項（Unit 005 完了処理 / 04-completion phase へ引き継ぎ）

1. **Unit 005 単体 DoD 達成**: pre-flight check + 8 BATS テスト + operations-release.md / review-flow.md 改修 + migration-tests.yml 整合 + shellcheck warn 0 + `$()` 規約準拠
2. **境界跨ぎ更新（Unit 004）**: `__pred_read_spool_issue_url` を Unit 002 spool 実 schema 整合化（incidental fix）/ domain model も同期 / P19/P20 BATS 追加で 17 件全 pass
3. **deferred 残（Unit 002 領域）**: Unit 004 既存 backlog（retrospective-resend `--cycle` 検証 / both-target duplicate check）と同期 / 重複 Issue 登録は回避
4. **回帰確認済**: 全 316 BATS pass / shellcheck warning 0 / `$()` 違反 0
