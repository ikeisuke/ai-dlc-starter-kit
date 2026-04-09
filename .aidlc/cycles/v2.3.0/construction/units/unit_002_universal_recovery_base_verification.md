# Unit 002 検証記録: 汎用復帰判定仕様の静的検証

## 概要

本 Unit はドキュメント成果物（`phase-recovery-spec.md`、`inception/index.md` の binding 層など）が主である。判定ロジックはコードとして実行されるのではなく、AI エージェントが spec を読んで判定に従う形で動作する。そのため「テスト」は以下の**静的検証**として実施する:

1. 全13ケースの fixture を `verify-inception-recovery.sh --dry-run` で生成可能なことを確認
2. 各ケースの期待値 (`expected_phase` / `expected_step_id` / `expected_diagnostics`) が `phase-recovery-spec.md` の判定規則に照らして**単一の値**に固定できることを仕様レベルで照合
3. `spec_refs` に列挙された仕様セクションが実在することを確認

実際の対話フロー再実行（AI エージェントが spec を読んで復帰判定を実行）は Unit 006 の最終検証で一括実施する。

## 実行結果

**実行コマンド**:

```bash
for c in normal-1 normal-2 normal-3 normal-4a normal-4b normal-5 abnormal-missing_file abnormal-conflict abnormal-format_error abnormal-legacy_structure i553-1a i553-1b i553-2; do
  skills/aidlc/scripts/verify-inception-recovery.sh --case "$c" --dry-run
done
```

**結果**: 全13ケースが成功（終了コード 0）、期待値を含む fixture が正しく生成される。

### 正常系6ケース

| # | ケース | expected_phase | expected_step_id | spec_refs | 単値性 |
|---|--------|---------------|------------------|-----------|-------|
| 1 | normal-1 | `inception` | `inception.01-setup` | `spec§4;spec§5.setup_done;spec§6;spec§8` | ✓ |
| 2 | normal-2 | `inception` | `inception.03-intent` | `spec§4;spec§5.intent_done;spec§6;spec§8` | ✓ |
| 3 | normal-3 | `inception` | `inception.04-stories-units` | `spec§4;spec§5.units_done;spec§6;spec§8` | ✓ |
| 4a | normal-4a | `inception` | `inception.04-stories-units` | `spec§4;spec§5.units_done;spec§6;spec§8` | ✓ |
| 4b | normal-4b | `inception` | `inception.05-completion` | `spec§4;spec§5.completion_done;spec§6;spec§8` | ✓ |
| 5 | normal-5 | `inception` | `inception.05-completion` | `spec§4;spec§5.completion_done;spec§6;spec§8` | ✓ |

**仕様との照合**:

- normal-1: `inception/progress.md` のステップ1が「未着手」→ spec §5.1.1 の「progress.md のステップ1完了マークが未設定」に合致 → `inception.01-setup` で単値
- normal-2: ステップ1/2 完了、ステップ3「進行中」、`intent.md` 存在、`user_stories.md` なし → spec §5.1.3 の「intent.md 存在、user_stories.md 未存在、ステップ3完了マーク未設定」に合致 → `inception.03-intent` で単値
- normal-3: `user_stories.md` 存在、`units/` 空 → spec §5.1.4 の最初のブランチ「user_stories.md 存在、units/*.md 未存在」に合致 → `inception.04-stories-units` で単値
- normal-4a: `units/*.md` 存在、progress.md「完了処理」未着手、`history/inception.md` なし → spec §5.1.4 の後半ブランチに合致 → `inception.04-stories-units` で単値
- normal-4b: `units/*.md` 存在、progress.md「完了処理」進行中、`history/inception.md` なし → spec §5.1.5 の「進行中 OR history/inception.md 存在 かつ全完了でない」の前半に合致 → `inception.05-completion` で単値
- normal-5: `history/inception.md` 存在、progress.md 一部未完了 → spec §5.1.5 の後半に合致 → `inception.05-completion` で単値

### 異常系4ケース

| # | ケース | expected_phase | expected_diagnostics | 分類 | spec_refs |
|---|--------|---------------|---------------------|------|-----------|
| 1 | abnormal-missing_file | `undecidable:missing_file` | `none` | blocking | `spec§4;spec§7;spec§8` |
| 2 | abnormal-conflict | `undecidable:conflict` | `none` | blocking | `spec§4;spec§7;spec§8` |
| 3 | abnormal-format_error | `undecidable:format_error` | `none` | blocking | `spec§3;spec§7;spec§8` |
| 4 | abnormal-legacy_structure | `inception` | `legacy_structure` | warning | `spec§4;spec§5.setup_done;spec§6;spec§7;spec§8` |

**仕様との照合**:

- missing_file: `inception/progress.md` が存在せず `units/*.md` のみ → spec §7.0 の必須集合（`inception/progress.md`）が欠損 → `undecidable:missing_file`
- conflict: `inception/progress.md` 未完了 + `operations/progress.md` 存在 → spec §4.3 の conflict 条件に合致 → `undecidable:conflict`
- format_error: `inception/progress.md` が空ファイルまたは見出し欠落 → spec §3.5 のパース失敗判定 → `undecidable:format_error`
- legacy_structure: `session-state.md` が残存 → spec §7.1 の warning 分類 → `result=inception`（判定継続可）、`diagnostics[]` に `legacy_structure` 追加

**`automation_mode=semi_auto` での挙動**: blocking 3系統はすべて spec §8 に従い自動継続禁止（ユーザー確認必須）。warning 1系統は継続可だが警告表示は必須。

### #553 再現シナリオ3ケース

| # | ケース | 期待結果 | v2.2.3 の実運用挙動 | 改善内容 |
|---|--------|---------|---------------------|---------|
| 1a | i553-1a | `inception.04-stories-units`（単値） | 判定表の建前では Inception 優先ガードで Inception になるはずだが、実運用では progress.md の書式変化により判定順2 のガード条件（「進行中」「未着手」文字列走査）が取りこぼし → 判定順3 に流れ **Construction と誤判定** | spec §4 判定順3で `phaseProgressStatus[inception]=completed` を Construction 必須条件としたため、Inception が未完了である限り構造的に判定順3 を skip し、必ず Inception に到達する |
| 1b | i553-1b | `inception.05-completion`（単値） | 同上（実運用で Construction と誤判定） | 同上 + spec §5.1.5 で「完了処理進行中」状態を明示的に扱い、`inception.05-completion` で単値固定 |
| 2 | i553-2 | `construction` / `step=None`（暫定ディスパッチャ） | Construction と判定（正しい） | 仕様上は正常動作。Unit 003 完了後に具体的な step 判定に置換予定 |

**v2.2.3 ロジックとの対比記録**: `phase-recovery-spec.md` §10.3 に記載済み。判定表テキスト上の建前（判定順2 の Inception 優先ガード）と実運用の挙動（書式取りこぼしによる Construction 誤判定）の乖離が #553 の本質である。本仕様では `phaseProgressStatus` を `ArtifactsState` 構築時に enum 正規化し、判定層は enum 比較のみで動作する構造に変更することで、progress.md の書式変化に起因する取りこぼしを構造的に排除する。

## spec_refs の実在確認

各ケースで出力される `spec_refs` に列挙されたセクションが `phase-recovery-spec.md` に実在することを確認:

| spec_ref | 実在 | 対応セクション |
|----------|------|-------------|
| `spec§2` | ✓ | §2. 2段レゾルバ構造（暫定ディスパッチャ説明） |
| `spec§3` | ✓ | §3. 判定の入力モデル（ArtifactsState）、§3.5 パース失敗時の扱い |
| `spec§4` | ✓ | §4. フェーズ判定仕様（PhaseResolver） |
| `spec§5.setup_done` | ✓ | §5.1.1 |
| `spec§5.intent_done` | ✓ | §5.1.3 |
| `spec§5.units_done` | ✓ | §5.1.4 |
| `spec§5.completion_done` | ✓ | §5.1.5 |
| `spec§6` | ✓ | §6. 戻り値インターフェース契約 |
| `spec§7` | ✓ | §7. 異常系4系統の処理仕様 |
| `spec§8` | ✓ | §8. ユーザー確認必須性ルール |
| `spec§10` | ✓ | §10. Inception への適用例 |

## スクリプト品質検証

### bash substitution check

```bash
bin/check-bash-substitution.sh
```

結果: `Bash substitution check completed: no violations, 31 files checked`

- `$(...)` およびバッククォート使用ゼロ
- `.aidlc/rules.md` のコーディング規約に完全準拠

### セキュリティ: ディレクトリトラバーサル対策

```bash
# 正常系
skills/aidlc/scripts/verify-inception-recovery.sh --case normal-1 --dry-run
# → verify-case:normal-1:.aidlc/cycles/vTEST-normal-1:dry-run (exit 0)

# ディレクトリトラバーサル (拒否されるべき)
skills/aidlc/scripts/verify-inception-recovery.sh --case normal-1 --dest ".aidlc/cycles/vTEST-../../tmp/pwn"
# → 【verify-inception-recovery エラー】--dest に '..' セグメントは含められません (exit 2)

# 絶対パス (拒否されるべき)
skills/aidlc/scripts/verify-inception-recovery.sh --case normal-1 --dest "/tmp/pwn"
# → 【verify-inception-recovery エラー】--dest は絶対パス不可です (exit 2)
```

結果: すべての拒否ケースで exit 2。`rm -rf` の前にバリデーションが実施される構造となっている。

### 終了コード規約準拠

| 条件 | 終了コード | 確認 |
|------|---------|------|
| 正常完了 | 0 | ✓ |
| 引数エラー（`--case` 未指定、不正値、`--dest` 不正） | 2 | ✓ |
| 内部エラー（ケース分岐の未処理） | 1 | ✓（到達不能なフェイルセーフ） |

`.aidlc/guides/exit-code-convention.md` に準拠。

## 完了条件チェックリストの仕様側確認

計画ファイル `.aidlc/cycles/v2.3.0/plans/unit-002-plan.md` の完了条件チェックリスト（18項目）を静的検証で確認:

- [x] 【共通仕様策定】`phase-recovery-spec.md` 新規作成、10セクション完備（§1〜§10）
- [x] 【正本の一本化】`inception/index.md` の先頭宣言を `Materialized Binding` 形式に修正
- [x] 【2段レゾルバ構造】`phase-recovery-spec.md §2` に記載
- [x] 【暫定ディスパッチャ】`compaction.md` の「復帰フローの確認手順」に `judge()` 契約と phase 別の暫定ルート明示
- [x] 【Inception 適用 - binding 層】`inception/index.md §3` のチェックポイント表を実値 + spec 参照トークンで埋め済み
- [x] 【骨格スキーマ不変】列構造・行構造（5 checkpoint）は Unit 001 から変更なし
- [x] 【論理インターフェース契約更新】`inception/index.md §3.1` を `judge()` 契約経由 + `result + diagnostics[]` 分離形式に更新
- [x] 【04/05 境界の単値化】spec §5.1.4 / §5.1.5 で境界ルールを単値化（progress.md「完了処理」＋ `history/inception.md` の両方で判定）
- [x] 【正常系検証】代表6ケース（1/2/3/4a/4b/5）の fixture 生成 + 期待値の単値性確認
- [x] 【異常系4系統検証】blocking 3系統 + warning 1系統すべて検証記録済み
- [x] 【#553 根本解決】再現シナリオ1a/1b/2 の期待値を単値固定、spec §4 判定順3での吸収を明記
- [x] 【#553 対比記録】`phase-recovery-spec.md §10.3` に v2.2.3 判定ロジックとの対比を記載
- [x] 【compaction.md リファクタ】「復帰フローの確認手順」の判定順テーブル（1〜4）を削除、`judge()` 契約記述に置き換え
- [x] 【compaction.md 存続部分】`automation_mode` 復元手順（手順1〜5）は diff 上変更なし
- [x] 【session-continuity.md 更新】Inception 行を `judge()` 契約経由の新フローに更新、Construction/Operations は現状維持 + コメント追記
- [x] 【後方互換性】`phase-recovery-spec.md §7.0 / §7.1 / §8` に `legacy_structure` warning の扱いを明記（`diagnostics[]` 追加のみ、強制マイグレーションなし）
- [x] 【Unit 003/004 接続点】`phase-recovery-spec.md §5.2 / §5.3` に placeholder セクションを配置
- [x] 【全チェックポイントの非正本マーカー撤去】`compaction.md` の「非正本・暫定」マーカー付きテーブルは完全削除

## 結論

- 全13ケース（正常系6 + 異常系4 + #553再現3）が仕様通りの期待値を単値で導出できることを静的検証で確認
- `verify-inception-recovery.sh` は `set -euo pipefail` + ディレクトリトラバーサル対策 + `$()` 禁止 + 終了コード規約準拠
- 完了条件チェックリスト18項目すべて達成

**実地検証は Unit 006（計測・クローズ判断）で Unit 001-005 の成果物すべてを使って一括実施する**。
