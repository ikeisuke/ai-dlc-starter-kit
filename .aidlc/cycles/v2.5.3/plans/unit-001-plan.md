# Unit 001 計画: 振り返り対話強制ガード強化（Operations §1）

## 概要

Operations Phase §1 振り返りステップで、AI エージェント（特に auto mode 動作中）が対話を経ずに振り返り Issue を独断起票してしまう運用ミスを構造的に防止する。文書ガード（`skills/aidlc/steps/operations/04-completion.md` §1 と `skills/aidlc/SKILL.md`）に加え、実行時ガード（`skills/aidlc/scripts/lib/retrospective-issue.sh` への対話確認トークン検証）を「文書 + 実行時」の二段防御として実装する。本サイクル内 fixture（`construction/fixtures/operations-mirror-autodialog.md`）も併設する。

本 Unit 完了直後から本サイクル後続 Unit（002/003/004）の Operations Phase 振り返りに対しても新ガードが有効化される（自己適用の閉ループ）。後続 Unit による上書き・希釈リスクを下流の計画ファイルへ申し送り事項として明示し、統合レビューでの不変条件保持を回帰チェック対象とする。

> **スコープ拡大の根拠**: Codex Round 1 計画レビューの指摘 #1（高 / architecture）に対し、ユーザー判断で Unit 001 スコープ拡大を選択（DR-008 / `inception/decisions.md` 参照）。Intent line 33 の文言は据え置き、解釈拡張を DR-008 で明文化する。

## 関連 Issue

- #647（[Feedback] Operations §1 振り返り対話強制ガード強化と auto mode 動作明文化）
- 参考: jailrun #70 / PR #71（外部実証事例 / non-blocking）

## 責務分離原則【SoT 明確化 / 計画レビュー指摘 #2 対応】

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 規範（SoT） | AskUserQuestion 使用ルールの正本（種別表 + 振り返り内容の決定行） | `skills/aidlc/SKILL.md` 「AskUserQuestion 使用ルール」節 |
| 手順 | Operations Phase §1 の手順記述。SoT へのリンク参照を中心に、重複文言を最小化 | `skills/aidlc/steps/operations/04-completion.md` §1.0.5（新設）/ §1.0 補足 / §1.5 |
| 実行時ガード | `retrospective_issue_create` 直前の対話確認トークン検証（文書ガードのバイパス防止） | `skills/aidlc/scripts/lib/retrospective-issue.sh` |
| 検証例 | 正常パターン例 + アンチパターン例（jailrun #70 再現） | `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` |
| 履歴 | 実装進捗・対話必須ガード強化反映の記録 | `.aidlc/cycles/v2.5.3/history/construction_unit01.md` |

**ドリフト防止策**: 04-completion.md §1.0.5 は SKILL.md 該当節へのリンク + 振り返り固有の禁止/必須事項リストのみを記述し、対話分類定義の重複を避ける。fixture は SoT を参照するチェックリスト形式で記述する。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/SKILL.md` | 改修（規範 / SoT） | 「AskUserQuestion 使用ルール」テーブルに「振り返り内容の決定」行を追加（「ユーザー選択」種別 / auto mode 適用外）、節末に Operations §1 への参照リンクを追加 |
| `skills/aidlc/steps/operations/04-completion.md` | 改修（手順） | §1.0 と §1.1 の間に「対話必須」明記節（§1.0.5）を新設、§1.0 `feedback_mode` テーブル直後に「`silent` でも KPT 判断は対話必須」補足を追加、§1.5 Step 4（起票）直前の AskUserQuestion 必須化記述を追加。§1.0.5 は SKILL.md SoT への参照リンク中心とし、振り返り固有の禁止/必須事項リスト + 抽象操作レベル禁止 + 実装マッピング表（後述）のみを記述 |
| `skills/aidlc/scripts/lib/retrospective-issue.sh` | 改修（実行時ガード） | `retrospective_issue_create` 関数内、`gh issue create` 呼び出しの直前に「対話確認トークン検証」ガード関数を追加。トークン未取得 / 鮮度切れ時は exit 4（`dialog_required` 系新コード）でブロック |
| `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` | 新規作成 | 振り返り対話の正常パターン例（対話 → トークン書出 → 起票）とアンチパターン例（auto mode 独断起票 → トークン未取得 → exit 4）を fixture として記録 |
| `.aidlc/cycles/v2.5.3/history/construction_unit01.md` | 新規作成 | Unit 001 の進捗履歴（対話必須ガード強化反映の記録を含む） |

> **bin/tests/ 等への波及**: 既存 BATS テストで `retrospective_issue_create` を呼び出すケースが存在する場合、対話確認トークンファイルの事前生成が必要になる。実装計画 Phase 2 で grep 確認し、必要に応じてテストフィクスチャ補修を行う。

## 抽象操作レベルの禁止対象 + 実装マッピング表【計画レビュー指摘 #3 対応】

§1.0.5 の禁止事項は実装詳細名（`gh issue create` 等）への過結合を避けるため、抽象操作レベルで定義する。具体的なコマンド対応は別表として切り出す。

### 禁止対象（抽象操作レベル）

| 抽象操作 | 説明 |
|---------|------|
| `retrospective publish` | 振り返り内容を外部システム（GitHub Issue / API）に永続化する全ての副作用 |
| `retrospective state mutation` | mirror_state ラベルや local 記録を含む振り返り状態の更新副作用 |
| `dialog bypass` | AskUserQuestion 応答を経ずに上記 publish / state mutation を実行する経路 |

### 実装マッピング（参考 / 将来構造変更時はここを更新）

| 抽象操作 | 現行実装エントリポイント | 関連ファイル |
|---------|-------------------------|-------------|
| `retrospective publish` | `retrospective_issue_create` 関数経由の `gh issue create` / `gh api PATCH`（mirror_state ラベル更新） | `skills/aidlc/scripts/lib/retrospective-issue.sh` |
| `retrospective state mutation` | `retrospective_update_hook` / `retrospective_prefill_hook` の Issue edit 経路 | 同上 |
| `dialog bypass` | （実装ガードなし、本 Unit で追加） | 本 Unit で `retrospective-issue.sh` に追加 |

実装マッピングが変更される場合は、04-completion.md §1.0.5 の本表のみを更新すれば良く、抽象操作レベルの禁止事項は不変として残る。

## 実行時ガード設計（DR-008 / 計画レビュー指摘 #1 対応）

### 方式: 対話確認トークンファイル

- **トークンファイルパス**: `${TMPDIR:-/tmp}/aidlc-retro-confirmed-${cycle}.flag`
- **発行関数（新規）**: `retrospective_dialog_token_record_response` を `retrospective-issue.sh` に新規追加
  - 引数: `cycle`（許可文字: `^[A-Za-z0-9._-]+$`、`/` および `..` 禁止）、`response`（`approved` / `denied` の両方を受理）
  - 動作: トークンファイルに 1 行目=ISO 8601 / UTC タイムスタンプ、2 行目=`response` を書き出す（umask 077 でユーザーのみ書き込み可）
  - exit code: 0（成功）/ 1（引数不正: `invalid_cycle` / `invalid_response` / `missing_args`）/ 2（書き込み失敗: `write_failed`）
  - 命名統一: 「`mark_approved`」ではなく「`record_response`」とすることで approved / denied の両方を受理する責務を明示（設計レビュー Round 1 指摘 #2 反映）
- **書き出し主体**: AI エージェントが AskUserQuestion で「この内容で起票してよいか」の確認応答を得た直後に `retrospective_dialog_token_record_response` を呼び出す（04-completion.md §1.5 Step 4 はこの関数を呼ぶ契約のみを記載し、ファイル書き込みの実装詳細は記述しない）
- **検証関数（新規）**: `retrospective_dialog_token_verify` を `retrospective-issue.sh` に新規追加
  - トークンファイル存在確認
  - mtime 鮮度確認（直近 300 秒以内、定数 `AIDLC_RETRO_TOKEN_TTL_SECONDS=300`）
  - 応答結果が `approved` であること
- **ガード呼び出し位置**: `retrospective_issue_create` 関数内、`gh issue create` の直前
- **エラー時挙動**: 検証失敗時は exit 4（新コード）+ stderr に `error\tdialog_required\t<reason>` 出力、`gh issue create` をブロック
  - reason 値（業務拒否系）: `token_missing` / `token_stale` / `token_denied`
  - reason 値（I/O 異常系）: `token_io_error` / `token_parse_error`（exit code は 4 統一、stderr の reason 値で詳細分類）
  - 詳細仕様は論理設計「インターフェース設計 / `retrospective_dialog_token_verify`」セクション参照
- **`feedback_mode=disabled` 時のガード適用外**: §1 全体スキップのため検証関数も呼び出されない

### 後方互換性

- `feedback_mode` 別の真理表は論理設計「feedback_mode 別の verify 呼出真理表」セクションを SoT として参照
- `disabled`: §1 全体スキップのためガード適用外
- `silent`: §1.5 実施（ローカル記録のみ）→ `retrospective_issue_create` 呼出あり / 内部分岐で `gh issue create` 未実行 → verify は `gh issue create` 直前のため不到達 → 既存挙動完全互換
- `mirror`: §1.5 実施 → `retrospective_issue_create` 呼出 → `gh issue create` 実行 → verify が必須（破壊的変更だが、AI-DLC 内の唯一の正規呼び出し経路 §1.5 Step 4 が改修により発行手順を追加するため運用影響なし）
- spool 経路（`gh_status != available` 時）は `gh issue create` を実行しないため検証関数の呼び出しなし
- exit code 0 / 1 / 2 の既存意味は維持。exit 4 は新コード追加（`gh issue create` ブロック）

## 後続 Unit への申し送り事項【計画レビュー指摘 #4 対応】

Unit 003（事実テーブル先抽出ステップ + 推定値検出ガード）は同一ファイル `skills/aidlc/steps/operations/04-completion.md` §1 を編集するため、Unit 001 の §1.0.5 と §1.5 Step 4 起票直前 AskUserQuestion 記述を上書き・希釈するリスクが構造的に存在する。

### 申し送り対象計画ファイル + 受け入れ条件 ID（依存固定 / Round 2 指摘 #2 対応）

下記の計画ファイル（repo-relative）に、対応する受け入れ条件 ID で申し送り事項を反映する。Unit 003 / Unit 004 の計画策定者は本表を SoT として参照し、計画ファイル内に同 ID を明記すること。

| 受け入れ条件 ID | 反映先計画ファイル | 反映内容 |
|----------------|------------------|---------|
| `AC-U003-RETRO-GUARD-IMMUTABLE-1` | `.aidlc/cycles/v2.5.3/plans/unit-003-plan.md` | §1.0.5（対話必須ガード）の「禁止事項リスト」「必須事項リスト」「抽象操作レベル禁止表」「実装マッピング表」が改修後も保持されていること |
| `AC-U003-RETRO-GUARD-IMMUTABLE-2` | `.aidlc/cycles/v2.5.3/plans/unit-003-plan.md` | §1.5 Step 4 起票直前の AskUserQuestion 必須化記述および `retrospective_dialog_token_record_response` 呼出手順が改修後も保持されていること |
| `AC-U003-RETRO-GUARD-IMMUTABLE-3` | `.aidlc/cycles/v2.5.3/plans/unit-003-plan.md` | `retrospective_dialog_token_verify` 関数の存在と `retrospective_issue_create` からの呼び出し関係が改修後も保持されていること |
| `AC-U004-RETRO-GUARD-IMMUTABLE-1` | `.aidlc/cycles/v2.5.3/plans/unit-004-plan.md` | `retrospective-issue.sh` の関数移管 / refactor 時、Unit 001 で追加された `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` 関数と `retrospective_issue_create` への組み込みが破壊されないこと |
| `AC-U004-RETRO-GUARD-IMMUTABLE-2` | `.aidlc/cycles/v2.5.3/plans/unit-004-plan.md` | 新 helper 群（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）への関数移管対象に Unit 001 で追加した対話確認トークン関連関数を含めない（`retrospective-issue.sh` 残置） |

Unit 002 は同ファイルへの編集範囲外（Unit 002: `skills/aidlc/scripts/write-history.sh` / 同 SKILL.md）のため、Unit 002 計画への申し送りは不要。

### 統合レビュー（`reviewing-construction-integration`）回帰チェック観点

統合レビュー時に下記 5 項目（`AC-U003-RETRO-GUARD-IMMUTABLE-1〜3` + `AC-U004-RETRO-GUARD-IMMUTABLE-1〜2`）を回帰チェック観点として確認する。Unit 001 完了処理時に `reviewing-construction-integration` の引数または observe 対象として本表を参照させる。

### 受け入れ条件の取り込みタイミング（Unit 003/004 計画ファイル未存在時の運用）

Unit 003 / Unit 004 の計画ファイル（`.aidlc/cycles/v2.5.3/plans/unit-003-plan.md` / `unit-004-plan.md`）は本 Unit 001 完了時点では未着手のため未存在である。受け入れ条件 ID の反映は以下のタイミングで行う:

1. Unit 003 / Unit 004 の Construction Phase 開始時（`construction.01-setup` ステップ 10「実行前確認と完了条件の提示」）に、各 Unit の計画ファイル作成者が本「申し送り対象計画ファイル + 受け入れ条件 ID」表を SoT として参照
2. 各 Unit 計画ファイルの「完了条件チェックリスト」に対応する受け入れ条件 ID（`AC-U003-RETRO-GUARD-IMMUTABLE-1〜3` / `AC-U004-RETRO-GUARD-IMMUTABLE-1〜2`）を明示
3. 各 Unit の統合レビュー時に Unit 001 で追加されたガード文言・関数定義・組み込み呼出が改修後も保持されていることを回帰チェック

Unit 001 完了時点では「Unit 003/004 計画ファイルへの受け入れ条件記載」は未到達のため、本セクションが SoT として独立して存在することを担保する（Unit 001 の責務）。Unit 003/004 計画策定者の取り込みは Unit 003/004 の責務とする。

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_001_retro_dialog_guard_domain_model.md`）: 振り返り対話ガードのドメイン語彙（対話必須エンティティ・AskUserQuestion 種別境界・対話確認トークン・auto mode との関係）を整理
- 論理設計（`design-artifacts/logical-designs/unit_001_retro_dialog_guard_logical_design.md`）: §1.0.5 新節の文言仕様、SKILL.md 表への新規行の入出力契約、`retrospective_dialog_token_verify` 関数の入出力契約・状態遷移、fixture フォーマット仕様を確定

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

#### 1. `skills/aidlc/SKILL.md` 「AskUserQuestion 使用ルール」拡張（規範 / SoT）

- 「インタラクション種別と対応方法」テーブルに「振り返り内容の決定」行を追加
  - 種別: `ユーザー選択`（既存 3 種別への新規行追加）
  - 説明: Operations Phase §1 振り返りでの KPT / 主因切り分け / mirror 送信判断 / 起票実行確認
  - 対応方法: `AskUserQuestion` 必須
  - `semi_auto` での扱い: 自動化対象外（常に `AskUserQuestion`）
  - 具体例: 「この Keep を振り返り Issue に含めますか？」「この内容で Issue を起票しますか？」
- 「セミオートゲート仕様との関係」節の直後に、auto mode（Claude Code 側）に関わらず本ルールが適用される旨の補足を 1 文追記
- 節末に「Operations Phase §1 における具体的手順は `steps/operations/04-completion.md` §1.0.5 を参照」のリンク参照を追加

#### 2. `skills/aidlc/steps/operations/04-completion.md` §1 改訂（手順）

- **§1.0.5（新設）**: §1.0 と §1.1 の間に「対話必須」明記節を追加
  - 冒頭ボックス（` > **重要**:` 強調表示）で「振り返りは判断要件を含むため、AI エージェントの auto mode に関わらず必ずユーザー対話を経て進める」を明記
  - SKILL.md「AskUserQuestion 使用ルール」節へのリンク参照（SoT）
  - 禁止事項リスト（抽象操作レベル）:
    - `dialog bypass`（AskUserQuestion 応答を経ずに `retrospective publish` / `retrospective state mutation` を実行）
    - KPT / 主因切り分け / 格納先選択 / mirror 送信判断のすべてを AI エージェントが独断で決定
    - auto mode を理由とした AskUserQuestion 省略
  - 必須事項リスト:
    - KPT 各観点（Keep / Problem / Try）について 1 項目ずつ AskUserQuestion で確認
    - §1.5 Step 4 起票直前に AskUserQuestion で確認 + 対話確認トークンファイル書き出し
    - §1.5 Step 5-3 の既存 AskUserQuestion ループは引き続き必須
  - 抽象操作レベル禁止表 + 実装マッピング表（本計画ファイル「抽象操作レベルの禁止対象 + 実装マッピング表」セクションを節として展開）
- **§1.0 feedback_mode テーブル直後への補足**: `feedback_mode=silent` でも §1.1〜§1.6 の KPT 判断は対話必須（mirror 送信が不要なだけ）の旨を明文化
- **§1.5 Step 4 直前への記述追加**: `retrospective_issue_create` 呼出直前に「KPT 内容確認 + 起票実行可否」を AskUserQuestion で確認 → 応答得た直後に `retrospective_dialog_token_record_response "$cycle" "$response"` を呼び出す手順を追加（トークンファイルパス・書き出し内容の実装詳細は関数側に集約され、04-completion.md は関数呼出契約のみを記載する）

#### 3. `skills/aidlc/scripts/lib/retrospective-issue.sh` への実行時ガード追加

- `retrospective_dialog_token_record_response` 関数を新規追加（発行側 / 前述「実行時ガード設計」参照）
- `retrospective_dialog_token_verify` 関数を新規追加（検証側 / 前述「実行時ガード設計」参照）
- `retrospective_issue_create` 関数内、`gh issue create` の直前に `retrospective_dialog_token_verify` 呼び出しを追加
  - 検証失敗時: exit 4 + stderr `error\tdialog_required\t<reason>`
- 多重 source ガード（既存パターン）の踏襲
- 定数 `AIDLC_RETRO_TOKEN_TTL_SECONDS=300` をファイル冒頭付近で定義（環境変数で上書き可）

> **凝集度**: 発行（`record_response`）と検証（`verify`）の両方を `retrospective-issue.sh` に集約することで、トークンスキーマ変更時の影響範囲を 1 ファイルに閉じる。手順側（`04-completion.md`）はこれらの関数を呼ぶ契約のみを記述し、ファイル書き込み・パス解決・タイムスタンプ生成の実装詳細を持たない。

#### 4. fixture 作成

- `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` を新規作成
- 内容:
  - **正常パターン例**: KPT 1 項目 → AskUserQuestion → 主因切り分け → AskUserQuestion → mirror 送信判断 → AskUserQuestion → トークン書出 → `retrospective_issue_create` 成功 のループ
  - **アンチパターン例**: auto mode で AI エージェントが KPT・主因・mirror 送信をすべて独断で決定 → トークン未書出 → `retrospective_issue_create` で `retrospective_dialog_token_verify` が exit 4 で fail → `gh issue create` ブロック（jailrun #70 の再現が exit 4 で阻止される）
  - 各パターンに対して「ガード文言（§1.0.5 / SKILL.md 該当行 / `retrospective_dialog_token_verify`）が予防すべきポイント」を併記

#### 5. 既存 BATS テスト追従

- `bin/tests/` および `tests/` 配下を grep し、`retrospective_issue_create` を呼び出すテストケースがあれば、対話確認トークンファイル事前生成の前処理を追加
- 検出されない場合は明示的に「該当テスト未検出」と履歴記録する

#### 6. 履歴記録

- `.aidlc/cycles/v2.5.3/history/construction_unit01.md` を新規作成し、`/write-history` skill で進捗を逐次追記
- Unit 完了直前に対話必須ガード強化反映の記録（変更ファイル一覧 / レビュー round 数 / 自己適用検証結果 / 実行時ガード動作確認結果）を追記

#### 7. 自己適用の検証

- 本 Unit 自身の Phase 1 / Phase 2 のレビュー対話（`reviewing-construction-*` 呼出）が AskUserQuestion ベースで進むこと
- Unit 完了処理の文脈で `retrospective_dialog_token_verify` 関数の単体動作を確認（トークン書出 → 検証成功 / トークン未書出 → exit 4）

### 実装順序

1. `skills/aidlc/SKILL.md` 「AskUserQuestion 使用ルール」テーブル拡張 + 補足 + リンク参照（SoT を先に確定）
2. `skills/aidlc/scripts/lib/retrospective-issue.sh` への `retrospective_dialog_token_verify` 関数追加 + `retrospective_issue_create` への組み込み
3. `skills/aidlc/steps/operations/04-completion.md` §1.0.5 新設 + §1.0 補足追加 + §1.5 Step 4 直前記述追加（SoT への参照リンク中心）
4. fixture 作成（`construction/fixtures/operations-mirror-autodialog.md`）
5. 既存 BATS テスト追従（`bin/tests/` / `tests/` を grep）
6. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
7. 履歴記録の補足追加（対話必須ガード強化反映の記録）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `retrospective_dialog_token_verify` で TTL 切れ検出 | exit 4 + reason=`token_stale`（業務拒否系）で `gh issue create` ブロック |
| AskUserQuestion 応答が `denied` | exit 4 + reason=`token_denied`（業務拒否系）で `gh issue create` ブロック（ユーザーが起票を拒否したケース） |
| トークンファイル書き込み権限不足（極稀） | `record_response` 側で exit 2 + `error\twrite_failed\t<path>`（書き込み副作用の失敗扱い、`verify` 側の `token_missing` とは分離）|
| トークンファイル読み取り失敗（破損 / 権限不足等） | `verify` 側で exit 4 + reason=`token_io_error`（I/O 異常系）で `gh issue create` ブロック |
| トークンファイル形式不正（行数不足 / タイムスタンプ解釈失敗 / response 値不正） | `verify` 側で exit 4 + reason=`token_parse_error`（I/O 異常系）で `gh issue create` ブロック |
| `04-completion.md` §1 構造が将来変更される | §1.0.5 の禁止/必須事項リストは抽象操作レベル（`dialog bypass` 等）で記述。実装マッピング表の更新のみで構造変更に追従可能 |
| SKILL.md 行数が 500 行制限に近づく | 現状 251 行のため余裕あり。新規行 1 行 + 補足 1 文 + リンク参照 1 行で 260 行未満 |
| fixture が cycle-artifacts として cycle 完結することを保証 | `.aidlc/cycles/v2.5.3/construction/fixtures/` 配下に配置し、`skills/aidlc/**` 配下には置かない |
| 既存 BATS テストへのトークンファイル事前生成漏れ | Phase 2 ステップ 5 で grep + 補修。漏れがあれば exit 4 で fail することで検出可能 |
| 後続 Unit 003 による §1.0.5 上書き・希釈 | 「後続 Unit への申し送り事項」セクションで Unit 003 計画への受け入れ条件追加を明示。統合レビューで回帰チェック |

## NFR

- **パフォーマンス**: トークンファイル検証は `stat` + 文字列比較のみで O(1)。`retrospective_issue_create` 呼出 1 回あたり数ミリ秒程度の追加コスト
- **セキュリティ**: トークンファイルは `${TMPDIR:-/tmp}` 配下に配置し、サイクル名以外の機密情報を含めない。既存の機密情報マスクポリシーを維持
- **後方互換**: 既存の振り返りフロー（`feedback_mode=silent` / `mirror` / `disabled`）の挙動を破壊しない。`disabled` はガード適用外、`silent` は `retrospective_issue_create` 内部分岐で `gh issue create` 未実行のため verify が不到達（既存挙動完全互換）、`mirror` は対話を経た正常フローで通過（実装計画「後方互換性」セクションの真理表参照）
- **可用性**: トークン検証失敗時は exit 4 で明確にブロック。spool 経路（`gh_status != available`）は `gh issue create` 未実行のため検証関数呼び出しなし

## 完了条件チェックリスト

### 文書ガード（規範・手順）

- [x] `skills/aidlc/SKILL.md` 「AskUserQuestion 使用ルール」テーブルに「振り返り内容の決定」行が「ユーザー選択」種別として追加されている
- [x] SKILL.md 該当節に auto mode（Claude Code 側）に関わらず本ルールが適用される旨の補足が追記されている
- [x] SKILL.md 該当節末に Operations §1 への参照リンクが追加されている
- [x] SKILL.md 全体行数が 500 行制限を超えていない
- [x] `skills/aidlc/steps/operations/04-completion.md` §1.0 と §1.1 の間に「対話必須」明記節（§1.0.5）が追加され、冒頭ボックス（` > **重要**:` 強調表示）で auto mode に関わらず対話必須である旨が明記されている
- [x] §1.0.5 に SKILL.md SoT への参照リンクが含まれている
- [x] §1.0.5 に禁止事項リスト（抽象操作レベル: `dialog bypass` / 独断決定 / auto mode を理由とした省略）と必須事項リスト（KPT 各観点での AskUserQuestion / §1.5 Step 4 起票直前確認 + トークン書出 / §1.5 Step 5-3 既存ループ維持）が記述されている
- [x] §1.0.5 に抽象操作レベル禁止表 + 実装マッピング表が記述されている
- [x] §1.0 `feedback_mode` テーブル直後に「`silent` でも KPT 判断は対話必須」補足が追加されている
- [x] §1.5 Step 4 直前に `retrospective_issue_create` 呼出前の AskUserQuestion 必須化 + トークン書出記述が追加されている

### 実行時ガード

- [x] `skills/aidlc/scripts/lib/retrospective-issue.sh` に `retrospective_dialog_token_verify` 関数が追加されている
- [x] `retrospective_issue_create` 関数内、`gh issue create` の直前に `retrospective_dialog_token_verify` 呼び出しが追加されている
- [x] 検証失敗時の exit code が 4 で、stderr に `error\tdialog_required\t<reason>` が出力される
- [x] reason 値（業務拒否系: `token_missing` / `token_stale` / `token_denied`、I/O 異常系: `token_io_error` / `token_parse_error`）が網羅されている
- [x] 定数 `AIDLC_RETRO_TOKEN_TTL_SECONDS=300` が定義され、環境変数で上書き可能
- [x] 既存呼び出し（`feedback_mode=silent` で verify 不到達 / `mirror` 正常 / `disabled` でガード適用外 / spool 経路）の挙動が後方互換で維持されている（真理表に整合）
- [x] 既存 BATS テストで `retrospective_issue_create` を呼び出すケースに対話確認トークンファイル事前生成の前処理が追加されている（または該当テスト未検出が履歴に明記されている）

### 検証例 + 履歴

- [x] `.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` が新規作成され、正常パターン例とアンチパターン例（jailrun #70 再現が exit 4 で阻止される）が併記されている
- [x] fixture に各パターンのガード文言（§1.0.5 / SKILL.md 該当行 / `retrospective_dialog_token_verify`）が予防すべきポイントが記述されている
- [x] `.aidlc/cycles/v2.5.3/history/construction_unit01.md` に対話必須ガード強化反映の記録（変更ファイル / レビュー round / 自己適用検証結果 / 実行時ガード動作確認結果）が追記されている

### 後続 Unit への申し送り

- [x] 「後続 Unit への申し送り事項」セクションが計画ファイルに明記され、Unit 003 / Unit 004 の計画で受け入れ条件 ID（`AC-U003-RETRO-GUARD-IMMUTABLE-1〜3` / `AC-U004-RETRO-GUARD-IMMUTABLE-1〜2`）として参照される
- [x] 統合レビュー（`reviewing-construction-integration`）の観点に上記 5 受け入れ条件 ID（§1.0.5 / §1.5 Step 4 / `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify`）の不変条件保持が追加されている

### 品質ゲート

- [x] markdownlint（`markdown_lint=true` 設定）が pass する
- [x] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（最後 2 round 連続で指摘ゼロまたは defer 化）を満たす
- [x] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み

## 見積もり（Round 2 で更新）

- 設計フェーズ: 0.5 日（domain model / logical design / `retrospective_dialog_token_verify` 入出力契約）
- 実装フェーズ: 2 日（docs 改訂 + scripts/lib 実行時ガード追加 + fixture 作成 + BATS 追従 + レビュー）
- 合計: **2.5 日**（Round 1 時点 1.5 日 → Unit 001 スコープ拡大により +1 日）
