# レビューサマリ: Unit 001 v3 state スクリプト基盤

## 基本情報

- **サイクル**: v3.0.0-alpha.2
- **フェーズ**: Construction
- **対象**: Unit 001（v3 state スクリプト基盤）

---

## Set 1: 設計レビュー（2026-06-11）

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus: architecture）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（Round 1 で 4 件指摘 → 全件修正 → Round 2 で指摘0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `unit_001_v3_state_scripts_logical_design.md` - state-validate.sh が release サブフィールドを型検証のみで判定し、jq が欠落キーと明示 null をともに null と返すため必須サブフィールド欠落を有効扱いしうる | 修正済み（logical_design: 検証項目 5 に「release サブフィールド存在検証」を型検証前段として追加、has() で 3 キー存在を確認し欠落は exit 1） | - |
| 2 | 中 | `unit_001_v3_state_scripts_logical_design.md` - state-read.sh でキー欠落と明示 null を区別する仕様が不足 | 修正済み（logical_design: read 挙動に「キー欠落は exit 1 / 明示 null は exit 0、has() で区別」を追加、read と validate の責務分担を注記） | - |
| 3 | 中 | `unit_001_v3_state_scripts_logical_design.md` - updated_at の ISO 8601 正規表現が桁数のみ制約で `2026-99-99T99:99:99+99:99` 等の不正値を通す | 修正済み（logical_design: 正規表現を範囲制約版〔月 01-12/日 01-31/時 00-23/分秒 00-59/オフセット範囲〕に修正） | - |
| 4 | 中 | `unit_001_v3_state_scripts_logical_design.md` - state-write.sh が依存する state-validate.sh の不在/実行不可時に 126/127 が漏れ終了コード規約 0/1/2 を破りうる | 修正済み（logical_design: write 処理フローに「依存スクリプト存在・実行権限を起動時確認し exit 2」+「validate 呼び出し rc を捕捉し想定外終了を exit 2 に正規化」を追加） | - |

---

## Set 2: コードレビュー（2026-06-11）

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus: code, security）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（Round 1: 2 件 → 修正 / Round 2: 1 件 → 修正 / Round 3: 指摘0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/state-validate.sh`, `skills/aidlc-v3/scripts/state-read.sh`, `skills/aidlc-v3/scripts/state-write.sh` - 読み取り権限なし等の read error が `jq empty` 失敗経由で exit 1（バリデーション）に誤分類され、規約上の exit 2（システムエラー）とずれる | 修正済み（3 本とも file 存在チェック後・jq 実行前に `[[ -r ]]` を追加し読み取り不可は exit 2 に正規化） | - |
| 2 | 中 | `skills/aidlc-v3/scripts/state-write.sh` - release.pr_number の正規表現 `^-?[0-9]+$` が先頭ゼロ（`001`/`-01`）を許し、jq が黙って `1` にコアースして意図しない値が exit 0 で書き込まれる（サブエージェント検証で真因を特定。codex の「jq parse 失敗→exit 2」は本環境 jq で非再現） | 修正済み（正規表現を `^(0\|-?[1-9][0-9]*)$` に厳格化し先頭ゼロを exit 1 で拒否） | - |
| 3 | 中 | `skills/aidlc-v3/scripts/state-validate.sh` - jq 1.8.1 が先頭ゼロ数値を寛容に受理するため strict JSON 検証が jq の寛容性に依存する | 修正済み（strict parser 追加は Unit 制約「jq 唯一」を超える依存追加のため不採用。検証契約「JSON 妥当性 = jq が受理する入力」を state-validate.sh ヘッダおよび論理設計に明文化し、意図された設計判断として固定） | - |

---

## Set 3: 統合レビュー（2026-06-11）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus: code）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘対応判断完了（Round 1: 4 件 → テスト拡充で全件対応 / Round 2: 指摘0件）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` - 完了条件の bash -n / shellcheck 通過がテストハーネスで担保されていない（動作テストのみ） | 修正済み（静的検査セクションを追加: 3 スクリプトの bash -n + shellcheck 存在時の検査） | - |
| 2 | 中 | `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` - validate の型不正テストが define_completed / pr_number に偏り、他の必須フィールド・release サブフィールド型を回帰保護できていない | 修正済み（schema_version/current_cycle/release/updated_at/release.ready/release.merge_approved の型不正 6 ケースを追加） | - |
| 3 | 低 | `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` - read の抽出テストが許容キー完全リストを網羅していない（current_cycle / release.ready 等） | 修正済み（current_cycle / release.ready / updated_at の assert_out を追加し許容キー全 7 種を固定） | - |
| 4 | 低 | `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` - exit 2 経路が読み取り不可のみで、jq 不在 / 依存スクリプト不備が未検証 | 修正済み（validate/read の jq 不在 exit 2、write の依存 state-validate.sh 実行不可/不在の exit 2 を追加） | - |


