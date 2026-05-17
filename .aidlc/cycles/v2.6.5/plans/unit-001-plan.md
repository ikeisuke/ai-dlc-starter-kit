# Unit 001 実装計画: Inception 直近サイクル完了 Unit との重複検出フロー SoT 化

## 対象 Unit

- **Unit**: 001 - Inception 直近サイクル完了 Unit との重複検出フロー SoT 化
- **関連 Issue**: #712（クローズ対象）
- **優先度**: High
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.4 Construction Phase 着手時、Unit 001（`operations-premerge-ci-sot` / Issue #694）の責務全項目が v2.6.3 Unit 004 で既に完全実装済みであることが判明し取り下げに至った。v2.6.4 Inception Phase 時点で「直近サイクル完了 Unit との重複」を構造的に検出できる SoT 手順が存在しないことが根本原因。

本 Unit は `steps/inception/04-stories-units.md` ステップ 4（Unit 定義）直後・Unit 定義承認前 AI レビュー前のタイミングに「直近サイクル完了 Unit との重複チェック」手順を追加し、再発を構造的に予防する。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `steps/inception/04-stories-units.md` への重複チェック手順追加（ステップ 4 直後、Unit 定義承認前 AI レビュー前に挿入）
- **必須対応 2**: 重複チェック 3 ステップの SoT 化
  - (a) 直近 N サイクルの完了 Unit スラグ一覧取得（`.aidlc/cycles/v*/story-artifacts/units/*.md` のファイル名から slug 抽出）
  - (b) 関連 Issue 番号抽出（各 Unit 定義の「関連 Issue」セクション、または旧キー）
  - (c) Issue OPEN/CLOSED 状態確認（`gh issue view --json state`、`gh_status=available` 時のみ）
- **必須対応 3**: AskUserQuestion 仕様明文化（出力スキーマを機械可読で固定）
  - **質問形式**: `header="重複警告"` / `question="<新規 Unit slug> は直近 N サイクル内の以下の完了 Unit と一致します。続行しますか？"`
  - **選択肢（choice_id 固定）**:
    - `withdraw`: 取り下げ。**正規アクション**: 当該 Unit 定義ファイルの「実装状態 → 状態」を `取り下げ` に変更（既存 enum 値）。物理削除は実施しない（履歴トレース保持）
    - `continue_with_reason`: 継続。`reason` 入力必須（空文字 / 禁止パターン拒否、`review-flow.md` の禁止パターン規約準用）
  - **記録先（固定）**:
    - `withdraw` → `.aidlc/cycles/{{CYCLE}}/history/inception.md` に「重複検出による取り下げ」イベント追記
    - `continue_with_reason` → 当該 Unit 定義ファイル末尾に機械可読コメントブロック追加（`<!-- dedup-warning: source=<duplicate_unit_path> related_issue=<#NNN or none> reason=<text> detected_at=<YYYY-MM-DD> -->`）+ `history/inception.md` に「重複検出後の継続判断」イベント追記
- **必須対応 4**: 直近 N サイクル数の config 解決ロジック仕様策定
  - 新規 config キー: `[rules.inception]` セクション + `dedup_lookback_cycles = 3`（既定）
  - `0` 指定で重複検出を完全スキップ（明示的な opt-out として正規動作）
  - **責務分界（固定）**: 不正値（負数 / 非整数 / 文字列）の正規化責務は **config 解決層（`scripts/read-config.sh` 経由のラッパー）に集約**する。重複検出層は常に正規化済み非負整数のみを前提とする
  - **fallback 仕様**: 不正値検出時は警告を stderr に出力 + デフォルト値 `3` にフォールバック（fail-safe: 重複検出を継続）
  - `defaults.toml` への新規セクション追加（v2.6.5 / #712 / Unit 001 コメント付与）
- **必須対応 5**: gh 不可用時のフォールバック（警告表示 + Issue 状態確認スキップ + スラグ照合のみ実行）
- **必須対応 6**: ドッグフーディング検証 + 結果を `.aidlc/cycles/v2.6.5/history/inception.md` に追記記録
- **設計ドキュメント**: ドメインモデル + 論理設計を `.aidlc/cycles/v2.6.5/design-artifacts/` 配下に作成
- AI レビュー（設計 / コード / 統合）を codex で実施

### 含まれないもの（境界）

- 重複判定ロジックの自動ブロック化（警告 + AskUserQuestion のみ、ブロックしない）
- 既存 `phase-recovery-spec.md` の materialized binding 構造変更
- false positive 低減のためのスラグ正規化（複数形 / 略語展開等）
- consumer プロジェクトへの追加配布物（既存 `steps/inception/` 内で完結）
- Inception index.md「2. 分岐ロジック」or「3. 判定チェックポイント表」への新行追加（本サイクルではステップ本文記述のみで完結）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**: 「Unit 重複候補（slug 一致 / Issue CLOSED）」「重複検出範囲（直近 N サイクル）」「ユーザー判断（取り下げ / 継続）」を中心としたモデルを整理
- **論理設計**:
  - `04-stories-units.md` への挿入位置確定（ステップ 4 末尾の AI レビュー記述直前）
  - 重複チェック 3 ステップの手順テキスト化（コマンド例 + 期待出力 + フォールバック）
  - AskUserQuestion 質問文・選択肢・記録形式の確定（機械可読コメントブロック仕様: `<!-- dedup-warning: source=<path> reason=<text> -->`）
  - `dedup_lookback_cycles` の解決ロジック仕様（`scripts/read-config.sh rules.inception.dedup_lookback_cycles` → 既定 3 / 不正値時 fallback）
  - gh 不可用時のフォールバック動作仕様
  - ドッグフーディング検証手順（v2.6.5 Inception で実施済みの結果を `history/inception.md` に retrofit 記録する形態）

### Phase 2: 実装

1. `skills/aidlc/config/defaults.toml` に `[rules.inception]` セクション + `dedup_lookback_cycles` を追加（Unit 004 で sync チェック対象になる前提）
2. `skills/aidlc/steps/inception/04-stories-units.md` のステップ 4 直後に「ステップ 4a: 直近サイクル完了 Unit との重複チェック」セクションを追加
3. `.aidlc/cycles/v2.6.5/history/inception.md` にドッグフーディング結果を追記（v2.6.5 Inception での重複検出ケースの記録 / 該当なしならその旨記録）
4. markdownlint 実行 + 既存 bats 群への影響確認（無いはず）

## 完了条件チェックリスト

### #712 受け入れ基準

- [x] `steps/inception/04-stories-units.md` に「ステップ 4a: 直近サイクル完了 Unit との重複チェック」が追加されている
- [x] 重複チェック 3 ステップ（slug 一覧 / 関連 Issue 抽出 / Issue 状態確認）が SoT として記述されている
- [x] AskUserQuestion による「取り下げ / 継続」選択仕様（`choice_id` 固定 / 正規アクション / 記録先）が機械可読で明文化されている
- [x] 「継続」選択時の機械可読コメントブロック仕様（`<!-- dedup-warning: ... -->` 形式）が記述されている
- [x] `dedup_lookback_cycles` の config 解決ロジック（責務分界 + 不正値時 fallback 仕様）が仕様化されている
- [x] `defaults.toml` に `[rules.inception]` セクション + `dedup_lookback_cycles = 3` が追加されている
- [x] gh 不可用時のフォールバック動作が記述されている
- [x] v2.6.5 Inception でのドッグフーディング検証結果が `history/inception.md` に記録されている
- [x] Unit 004 との依存契約（ハード依存なし / Unit 004 側で新規セクション追加の互換窓を保証）がリスクセクションに明記されている

### 共通

- [x] markdownlint で新規エラー 0 件（ドキュメント変更がある場合）
- [x] AI レビュー（設計 / コード / 統合）が `review_mode=required` に従い codex で実施されている

## リスク・考慮事項

- **Unit 004 との依存契約（ハード依存なし / 互換窓を Unit 004 側 SoT で保証）**: Unit 001 は defaults.toml に `[rules.inception]` を新規追加する。Unit 004（defaults sync guard）は「新規セクション / 新規キーの追加」を fail させない設計（project 側 `config.toml` の `[rules.inception]` 不在は warn 扱い、または defaults 側に存在し project 側に不在のキーは sync 対象外）を Unit 004 計画書側で保証する。これにより Unit 001 / Unit 004 の実行順序は非依存となる（並行 / 任意順序で完了可）。Unit 004 計画時にこの互換窓を明示的な受入条件として記載する
- false positive リスク: スラグ部分一致は誤検出が多いため完全一致のみ判定。これは Unit 定義本文の境界記述に合致
- `gh issue view` の latency: 直近 3 サイクル × 平均 5 Unit = 15 Issue 程度の確認で 10 秒以内（NFR）。N サイクル増加時のスケーラビリティは将来 issue で対応
- 本ドキュメント変更は配布物 `skills/aidlc/` 配下のため consumer プロジェクトにも自動配布される。新規 config キーは defaults.toml で既定値が定義されるため互換性破壊なし
- 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない（本リポジトリ規約）
