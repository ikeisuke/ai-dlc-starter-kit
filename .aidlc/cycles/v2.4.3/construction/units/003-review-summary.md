# レビューサマリ: Unit 003 - migrate-backlog.sh の UTF-8 対応（#610）

## 基本情報

- **サイクル**: v2.4.3
- **フェーズ**: Construction
- **対象**: Unit 003 - migrate-backlog.sh の UTF-8 対応（#610）
- **対象ファイル**:
  - `.aidlc/cycles/v2.4.3/design-artifacts/domain-models/unit_003_migrate_backlog_utf8_fix_domain_model.md`
  - `.aidlc/cycles/v2.4.3/design-artifacts/logical-designs/unit_003_migrate_backlog_utf8_fix_logical_design.md`
  - （Phase 2 で追加: `skills/aidlc-setup/scripts/migrate-backlog.sh`）

---

## Set 1: 2026-04-28（設計レビュー）

- **レビュー種別**: 設計レビュー（Phase 1 / focus: architecture）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック継続。`review-routing.md §6 cli_runtime_error → retry_1_then_user_choice` 経由でユーザー選択、計画レビュー時にセルフレビュー採用済み・設計レビューも同方針継続）
- **反復回数**: 2（反復1: 6件、反復2: 0件で承認可能判定）
- **結論**: 指摘対応判断完了（合計 6 件すべて「修正する」で対応、反復2回目で構造的指摘ゼロを確認）

### 反復1 指摘（6件 / 中2 低4）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | ドメインモデル §集約「不変条件」 - `(utf8, latin1_default)` 契約下の挙動説明が現象網羅性で不正確（`Illegal byte sequence` 以外に「stderr エラーなしだが切れる」ケースもある） | 修正済み（不変条件を OR 条件で網羅: `Illegal byte sequence` 発生 or regex バイト単位評価で日本語末尾削除のいずれか、入力依存で発生形態が異なる旨を明記） | - |
| 2 | 中 | 論理設計 §設計判断記録 - 検証-A 採用根拠が計画ファイル §Phase1.3 の「条件1〜3 全て満たすと検証-B」判定基準と整合不明瞭 | 修正済み（「形式判定」と「実採用根拠」を分離記述。形式上は検証-B 条件を全て満たすが DEPRECATED 前提で検証-A を選択する根拠を明示。判定基準の差異を意思決定記録の追補対象として記録予告） | - |
| 3 | 低 | ドメインモデル §エンコーディング契約状態の表 - 4 状態網羅と定義しつつ表は 2 行のみ（残り 2 状態の本 Unit 扱いが不明瞭） | 修正済み（表を 4 行に拡張、`(latin1_default, utf8)` / `(latin1_default, latin1_default)` も「スコープ外」として理由付きで追加） | - |
| 4 | 低 | 論理設計 検証手段ケース 5（--dry-run）の「修正前 slug」列が「（ケース1と同じ）」となっており検証スコープが不明瞭 | 修正済み（設計判断記録および検証手段表ケース 5 の備考に「`generate_slug()` は --dry-run 分岐前に呼ばれるため slug 値はケース1と完全一致。比較対象は slug 値のみ」と検証スコープ明記） | - |
| 5 | 低 | ドメインモデル §SlugGenerationService が SlugGenerationPipeline.process(title) と責務重複（薄いラッパー）、設計過剰の懸念 | 修正済み（SlugGenerationService の責務を「Bash 実行コンテキスト管理（サブシェル起動・パイプ接続・終了コード回収）」と再定義。Pipeline は「段階定義 + 契約検証」の責務、Service は実行環境の責務として差別化。将来の再利用シナリオも追記） | - |
| 6 | 低 | 論理設計 ロケール非依存化検証 1 ケース vs Issue 受け入れ基準「3 ケース」の解釈整合不明瞭 | 修正済み（設計判断記録のロケール非依存化検証根拠を強化。`-CSD -Mutf8` がロケール依存・入力非依存に作用するため 1 ケースで契約成立を実証可能、残り 2 ケースは論理的同等動作が保証、`LANG=POSIX` は `LANG=C` と等価のため別ケース不要との解釈を明示。検証手段表ケース 6 の備考も強化） | - |

### 反復2 指摘（0件）

すべての反復1指摘が反映済み。新規矛盾・不整合なし。1 行修正の規模に対する設計過剰指摘も AI-DLC 規約整合の範囲内（許容）。千日手検出: 同種指摘の繰り返しなし。

### シグナル

- `review_detected`: true（反復1で6件検出）
- `deferred_count`: 0
- `resolved_count`: 6
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件 `review_not_executed` / `error` / `review_issues` / `incomplete_conditions` / `decision_required` すべて非該当、`semi_auto`）

### フォールバック記録

- **イベント**: Codex CLI ランタイムエラー（usage limit、4/29 7:56 AM 復旧予定）
- **`review-routing.md §6` 適用**: `cli_runtime_error` × `required` → `retry_1_then_user_choice`
- **ユーザー選択**: 計画レビュー時に「セルフレビュー実施」を選択。設計レビューも同方針継続
- **代替手段**: general-purpose サブエージェント方式（読み取り専用の指示テンプレート）

### 意思決定記録の追補予告

- **追補対象**: 検証-B 採用条件の判定基準（計画ファイル §Phase1.3）に「条件4: 対象が DEPRECATED でないこと」を補足するか別 Issue 化
- **記録先**: `inception/decisions.md` または Operations Phase での検討記録
- **背景**: 本 Unit で形式判定（条件1〜3）と実採用判断（DEPRECATED 除外）が一致せず、判定基準に揺れがあった

---

## Set 2: 2026-04-28（コードレビュー）

- **レビュー種別**: コードレビュー（Phase 2 / focus: code, security）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック継続）
- **反復回数**: 1（反復1: 0件で承認可能判定）
- **結論**: 指摘0件（設計→実装の追跡可能性が完全一致、副次発見は OUT_OF_SCOPE で別 Issue 化済み）

### 反復1 指摘（0件）

設計→実装→検証の整合性が確認された。具体的な確認事項:

- L75 の修正差分（`perl -CSD -Mutf8 -pe '...'`）は計画ファイル §Phase 2 §コード生成 / 論理設計 §実装範囲 / Issue #610 修正案と完全一致
- ドメインモデル §EncodingContract `(utf8, utf8)` 契約が `-CSD`（IO 層）+ `-Mutf8`（regex 層）併用で確立
- 検証-A 実行表 6 ケースの実測値（history 記録）が論理設計 §検証手段（期待値テーブル）と完全一致
- Case 6 再定義（Perl 段階の効果確認のみ）は計画ファイル / 論理設計 / history で整合
- DEPRECATED マーク維持、`generate_slug()` の他段階・他関数・パイプライン順序すべて不変
- POSIX / macOS-Linux 互換性、終了コード伝搬、副作用、セキュリティ観点すべて問題なし

### 副次発見（コードレビュー観点ではないため指摘外、参考記録）

| # | 内容 | 対応 | バックログ |
|---|------|------|-----------|
| (副次) | Phase 2 検証実行で `LANG=C` × 50 バイト超入力時の `cut -c1-50` 段階のロケール依存（バイト単位切り詰めで UTF-8 多バイト境界分断）が露見 | OUT_OF_SCOPE（Intent §「成功基準」#610 主旨は Case 1〜4 で達成済み、`cut` 段階の問題は別問題） | #615 |

### シグナル

- `review_detected`: false
- `deferred_count`: 0（コードレビューの指摘ではないため。副次発見の OUT_OF_SCOPE は別事象として処理）
- `resolved_count`: 0
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件 `review_not_executed` / `error` / `review_issues` / `incomplete_conditions` / `decision_required` すべて非該当、`semi_auto`）

### フォールバック記録

- Set 1（設計レビュー）と同じ（Codex usage limit による継続的セルフレビュー、4/29 7:56 AM 復旧予定）

---

## Set 3: 2026-04-28（統合レビュー）

- **レビュー種別**: 統合レビュー（Phase 2 完了時 / focus: code）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック継続）
- **反復回数**: 1（反復1: 0件で承認可能判定）
- **結論**: 指摘0件（設計→実装→検証の追跡可能性が完全一致、Issue #610 解消、副次発見は OUT_OF_SCOPE で別 Issue 化済み、後方互換性問題なし）

### 反復1 指摘（0件）

設計→実装→検証の統合的整合性が確認された。具体的な確認事項:

- Issue #610 修正案 `perl -CSD -Mutf8 -pe '...'` が L75 に完全一致して反映
- Unit 定義「責務」4 項目すべて達成（Perl 修正 / 3 必須ケース確認 / `--dry-run` 同等動作確認 / DEPRECATED マーク維持）
- ドメインモデル `EncodingContract (utf8, utf8)` 契約 → 論理設計「実装範囲（差分）」→ 実装 L75 の三層整合
- 検証-A 実行表 6 ケース（必須3 + 参考1 + dry-run + LANG=C）の実測値が論理設計 §検証手段の期待値テーブルと完全一致
- Case 6 再定義（Perl 段階の効果確認のみ）が計画 / 論理設計 / history / review-summary の 4 箇所で一貫
- 4 タイミング AI レビュー（計画 / 設計 / コード / 統合）すべて履歴記録済み
- DEPRECATED マーク維持、`--dry-run` / `--no-delete` 動作不変、macOS / Linux 共通動作確認
- 千日手検出: 過去 3 回（計画 / 設計 / コード）で同種指摘の反復なし

### Issue #610 解消の妥当性

- Intent §「成功基準」#610 「`tr: Illegal byte sequence` を出さず slug が末尾まで保持される」は Case 1〜4 の `LANG=ja_JP.UTF-8` 環境で達成
- 副次発見（`cut -c1-50` × `LANG=C`）は Intent §「含まれるもの」#3 に明示記載されていないため Issue #615 へ OUT_OF_SCOPE 化、スコープ保護判定として妥当

### シグナル

- `review_detected`: false
- `deferred_count`: 0
- `resolved_count`: 0
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件 `review_not_executed` / `error` / `review_issues` / `incomplete_conditions` / `decision_required` すべて非該当、`semi_auto`）

### フォールバック記録

- Set 1 / Set 2 と同じ（Codex usage limit による継続的セルフレビュー、4/29 7:56 AM 復旧予定）

