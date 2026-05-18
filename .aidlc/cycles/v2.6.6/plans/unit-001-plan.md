# Unit 001 実装計画: T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

## 対象 Unit

- **Unit**: 001 - T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義
- **関連 Issue**: #710（CLOSED / 方針親 / 本サイクル PR で Comment）
- **優先度**: High（Unit 004 の前提）
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

aidlc-retrospective skill の出力契約を「T 中心」に再定義し、`rules.retrospective.aggregate_issue_enabled` フラグ（既定 `false`）と cap 判定の意味を本 Unit で **単一 SoT** として定義する。実装利用（ループ起票実体 / 既定動作の cap 判定）は Unit 004 に委譲する。

Unit 001 は仕様 SoT 定義と fixture 整備までを担い、Unit 002（セルフレビュー）/ Unit 003（三層検証 helper）/ Unit 004（ループ起票本体）に必要な前提を整える。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `skills/aidlc-retrospective/SKILL.md` と `steps/retrospective.md` 冒頭への SoT 文言追加
  - 「**目的: T を Issue 化して実行に繋げること。KPT は T を導くための手段**」を SoT として明記
  - SC-01 充足条件: 文字列が両ファイル冒頭に存在
- **必須対応 2**: `config/defaults.toml` 二重 SoT への `rules.retrospective.aggregate_issue_enabled = false` 追加
  - `skills/aidlc/config/defaults.toml`
  - `skills/aidlc-setup/config/defaults.toml`
  - v2.6.5 Unit 004 で導入された二重 SoT CI 早期検出ガード（sync 検証）に合致する形式で追加
- **必須対応 3**: `aggregate_issue_enabled` 仕様節を `steps/retrospective.md` 内 `§1.5 前置き` セクションに新設（DR 推奨）
  - `true` / `false` 時の動作差分（集約 vs T ループ）
  - cap 判定意味の連動（`true`: 集約 Issue 1 件の上限 / `false`: T Issue 起票合計の上限）
  - SoT として記述し、他 SKILL/steps からの参照ポイントを明示
- **必須対応 4**: `skills/aidlc/scripts/lib/retrospective_api_aggregate_enabled` helper 追加（`skills/aidlc/scripts/lib/retrospective-api.sh` に登録）
  - 既存 `retrospective_api_*` 関数シグネチャ不変
  - 値解決経路: `scripts/read-config.sh rules.retrospective.aggregate_issue_enabled` 経由
  - **公開契約（単一・固定 / Unit 004 が依存）**:
    - **stdout**: 常に `true` または `false` を 1 行（末尾改行あり）の 2 値のみ
    - **exit code**: 常に `0`（本 helper は exit code で異常を伝えない）
    - **異常時挙動（fail-safe / 必ず exit 0 + stdout=false）**:
      - `read-config.sh` exit 1（キー不在）: stdout=`false`（v2.6.5 以前 consumer の互換窓 = 既定 off）+ exit 0
      - `read-config.sh` exit 0 だが非空値が `true` / `false` 以外（不正値）: 警告を stderr へ出力 + stdout=`false` + exit 0
      - `read-config.sh` exit 2（読み取り層エラー）: 警告を stderr へ出力 + stdout=`false` + exit 0
    - **Unit 004 側の契約前提**: stdout の `true` / `false` 2 値分岐のみ実装する。exit code 検査・追加の異常系分岐は実装不要
- **必須対応 5**: `tests/fixtures/retrospective_v265_aggregate.json` 新規追加（SC-04 同等性オラクル fixture）
  - **SC-04 二段階基準（v2.6.6 / Unit 001 統合レビューで確定）**:
    - **Unit 001 段階基準（本 Unit 完了条件）**: fixture スキーマ整備 + 正規化規則 SoT + 公開契約 helper + 構造検証 bats まで完了する。fixture 実値（タイトル / hash / cap）は `fixture_status="schema-only"` で placeholder 運用とし、HLP4 等 read-config exit 1 直接モック困難系テストは skip 許容。これは Phase 2 統合レビューで「コードレビュー」観点に合致するレベルでの完了状態
    - **Unit 004 finalize 基準（最終 SC-04 達成条件）**: Unit 004 統合フェーズで aggregate path フル実起票テストを通じて fixture 実値（`fixture_status="finalized"`）と差分 0 同等性 bats を確定する。本 Unit 001 で導入された fixture スキーマ + 正規化規則 SoT + helper 公開契約はそのまま Unit 004 が消費する依存契約となる
  - **fixture 生成元（Unit 004 段階で固定）**: v2.6.5 集約 retrospective Issue が実起票されていない事実（v2.6.5 retrospective は #722/#723/#724 の T Issue 単位で散発化）を Unit 001 統合レビューで確認した。Unit 004 finalize 段階では「v2.6.6 リリース時点の aggregate path コードで生成される集約 Issue 本文の固定スナップショット」を SoT として採用する。これは Intent SC-04「v2.6.5 と完全同等」の厳密解釈からは「v2.6.5 リリース時点コード生成 output と等価」に置換されるが、v2.6.5 実起票実績不在を踏まえた現実的かつ唯一の SoT 化アプローチ
  - **取得不可時の運用（Unit 001 段階）**: 上記二段階基準により Unit 001 は `blocked` を発生させず、schema-only 状態で完了する
  - **正規化規則 SoT（本計画固定）**:
    - **正規化対象 allowlist**（`normalize_volatile()` で除外）:
      - タイムスタンプ（ISO 8601 / `YYYY-MM-DD HH:MM:SS` JST / `YYYY-MM-DDTHH:MM:SS+09:00` 等の日付時刻文字列）
      - セッション ID（`session_id`, `019e[0-9a-f-]+` 形式の UUID 等）
      - 環境固有パス（`/Users/<name>/...`, `/home/<name>/...` 等のホーム配下絶対パス）
      - 生成時の差分要因（`generated_at`, `version` の patch 番号末尾等）
    - **正規化しない比較必須キー**（差分検出対象）:
      - Issue タイトル、本文見出し（`##` / `###` 行）、ラベル名、cap 判定の `current_count` / `over` フラグ、各見出し配下の本文非変動部分
    - **正規化後ハッシュ計算手順**: `normalize_volatile()` 適用後の本文を `sha256sum` でハッシュ化し fixture 内の `expected_normalized_hash` フィールドと一致確認
    - **SoT の所在（固定）**: 正規化規則本体は **テストコード側**（`tests/lib/retrospective_normalize.bash` 等の bats helper）に置く。fixture には期待値（normalized hash / 期待タイトル / 期待本文見出し列 / 期待ラベル集合 / 期待 cap 値）のみを格納し、二重定義を避ける
- **必須対応 6**: `aggregate_issue_enabled = true` 明示時の出力が fixture と差分 0 で一致する bats テスト追加
  - SC-04 の一次責務 = 同等性ロジック実装 / fixture 整備 / 同等性テスト実装は本 Unit に集約
  - 既定 `false` 時の T ループ起票本体は Unit 004 に委譲（本 Unit ではフラグ判定 helper のみ提供）
- **設計ドキュメント**: ドメインモデル + 論理設計を `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成
- AI レビュー（設計 / コード / 統合）を codex で実施（`review_mode=required`）

### 含まれないもの（境界）

- **§1.5 Issue 起票ループ実装本体** → Unit 004 (ストーリー 4A)
- **§1.2.5 セルフレビュー追加** → Unit 002
- **三層検証 helper 追加** → Unit 003
- **既定動作 (`false`) 時の cap 判定実装本体** → Unit 004
- `retrospective_api_*` の既存関数シグネチャ変更（不変保証）
- v2.7.0+ defer 項目への着手（`Retrospective: {cycle}` タイトル運用完全廃止 / 破壊的 API 変更等）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**:
  - 「振り返り出力モード」（`aggregate` / `t_loop`）の概念整理
  - 「cap 判定対象」の意味分岐（集約 1 件 vs T Issue 合計）
  - 「同等性オラクル fixture」のスキーマと正規化規則
- **論理設計**:
  - SoT 文言の挿入位置確定（SKILL.md 冒頭 / steps/retrospective.md 冒頭 / §1.5 前置き仕様節）
  - `defaults.toml` 二重 SoT 追加箇所と CI 早期検出ガード整合性
  - `retrospective_api_aggregate_enabled` helper のシグネチャ・戻り値・エラー時挙動
  - fixture スキーマ（JSON 構造 / 正規化規則 / `normalize_volatile()` 対象項目）
  - bats テスト構成（fixture 比較ロジック / 差分検出方法）

### Phase 2: 実装

1. `skills/aidlc-retrospective/SKILL.md` 冒頭への SoT 文言追加
2. `skills/aidlc-retrospective/steps/retrospective.md` 冒頭への SoT 文言追加
3. `skills/aidlc-retrospective/steps/retrospective.md` `§1.5 前置き` への仕様節新設（`true` / `false` 動作差分 + cap 判定意味）
4. `skills/aidlc/config/defaults.toml` への `[rules.retrospective]` セクション + `aggregate_issue_enabled = false` 追加
5. `skills/aidlc-setup/config/defaults.toml` 側にも同期して追加（二重 SoT 維持）
6. `skills/aidlc/scripts/lib/retrospective-api.sh` への `retrospective_api_aggregate_enabled` helper 追加
7. `tests/fixtures/retrospective_v265_aggregate.json` 新規追加（v2.6.5 artifact 参照）
8. `tests/retrospective_*.bats` への同等性テスト追加（`aggregate_issue_enabled = true` 時の差分 0 一致確認）
9. markdownlint 実行 + 二重 SoT CI ガード pass 確認 + 既存 bats 群への影響確認

## 完了条件チェックリスト

### Unit 責務（Intent SC からの導出）

- [ ] **SC-01**: SKILL.md / steps/retrospective.md 冒頭に「目的: T を Issue 化して実行に繋げること。KPT は T を導くための手段」が SoT として明記されている
- [ ] **SC-04 Unit 001 段階基準**: fixture スキーマ（`expected_title` / `expected_heading_set` / `expected_normalized_body_hash` / `expected_labels` / `expected_cap`）が `tests/fixtures/retrospective_v265_aggregate.json` に存在し、構造検証 bats が pass する（実値は `fixture_status="schema-only"` の placeholder 状態を許容）
- [ ] **SC-04 Unit 004 finalize 基準（本 Unit では未達成許容 / Unit 004 統合フェーズで完了）**: `aggregate_issue_enabled = true` opt-in での出力が finalize された fixture と以下 5 項目すべて差分 0 で一致する bats テストが Unit 004 で pass する
  - 集約 Issue タイトル（完全一致）
  - 本文見出し集合（順序・重複含めた一致）
  - 各見出し配下本文の正規化比較（`normalize_volatile()` 適用後の完全一致 / 本文全体の正規化ハッシュ一致）
  - ラベル集合（順不同一致）
  - cap 判定結果（`current_count` / `over` フラグ）
- [ ] `defaults.toml` 二重 SoT（aidlc / aidlc-setup）に `rules.retrospective.aggregate_issue_enabled = false` が追加され、二重 SoT CI 早期検出ガード（v2.6.5 Unit 004 由来）が pass する
- [ ] `aggregate_issue_enabled` 仕様節が `steps/retrospective.md` `§1.5 前置き` セクションに新設され、`true` / `false` 動作差分 + cap 判定連動が SoT として記述されている
- [ ] `retrospective_api_aggregate_enabled` helper が `retrospective-api.sh` に追加され、`scripts/read-config.sh` 経由で値解決する
- [ ] `tests/fixtures/retrospective_v265_aggregate.json` が新規追加され、`normalize_volatile()` 対象項目が抽出規則として fixture 内 or テストコード内に定義されている
- [ ] `retrospective_api_*` の既存関数シグネチャが不変であることが grep で確認できる
- [ ] NFR: 起票 helper 追加による既存処理オーバーヘッドが 5% 以内（簡易計測 or 引数判定のみで非該当を明示）
- [ ] `retrospective_api_aggregate_enabled` helper が「公開契約（単一・固定）」通りに動作することが bats テストで確認されている（read-config exit 1 / exit 2 / 不正値の 3 ケースとも stdout=`false` + exit 0 を返すことを確認）

### 共通

- [ ] markdownlint で新規エラー 0 件（ドキュメント変更がある場合）
- [ ] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている
- [ ] 本リポジトリ規約遵守: Bash ツール引数文字列にコマンド置換（`$(...)` / backtick）を含めない
- [ ] 本リポジトリ規約遵守: codex 非対話実行時の stdin 待ちガード（`</dev/null` 付与または `codex exec - < <file>` 形式）を関連スクリプト・手順で遵守する

## リスク・考慮事項

- **fixture 二段階基準（Unit 001 統合レビューで確定 / Unit 004 で finalize）**: v2.6.5 サイクル時点で集約 retrospective Issue が実起票されていないことを Unit 001 統合レビューで確認した（v2.6.5 retrospective は #722/#723/#724 の T Issue 単位で散発化）。本 Unit 001 では fixture スキーマ + 正規化規則 SoT + helper 公開契約までを完了し（`fixture_status="schema-only"`）、Unit 004 統合フェーズで「v2.6.6 リリース時点 aggregate path コード生成 output」を SoT として fixture 実値を finalize（`fixture_status="finalized"`）+ 差分 0 同等性 bats を確定する。Intent SC-04「v2.6.5 と完全同等」は v2.6.5 実起票実績不在のため「v2.6.5 リリース時点コード生成 output と等価」に置換される
- **二重 SoT CI ガード整合性**: v2.6.5 Unit 004 で導入された CI 早期検出ガードの書式要件を Phase 1 設計時に確認し、新規セクション追加が fail させない形式であることを保証する
- **Unit 004 との契約**: 本 Unit が提供する `retrospective_api_aggregate_enabled` helper を Unit 004 が呼び出す前提。helper の **公開契約（stdout / exit code / 異常時フォールバック）** は本計画「必須対応 4」に固定済み。Unit 004 計画書はこの契約を依存記述として参照し、独自の異常系分岐を追加しない
- **NFR 計測**: 「5% 以内オーバーヘッド」は helper 追加分のみ。本 Unit では helper を導入するだけで既存処理パスを変更しないため、影響範囲は呼び出しオーバーヘッドのみとなる見込み
- **本リポジトリ規約**: Bash ツール経由のコマンド置換禁止 + result-out 関数の local 命名規約遵守（既存 lib への helper 追加時）+ codex 非対話実行時の `</dev/null` 付与（stdin 待ちガード / 本サイクル CLAUDE.md SoT 参照）
