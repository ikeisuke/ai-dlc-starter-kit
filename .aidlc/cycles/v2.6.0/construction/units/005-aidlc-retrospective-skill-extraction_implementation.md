# 実装記録: Unit 005 /aidlc-retrospective 独立スキル化（破壊的変更）

## 実装日時

2026-05-09T23:30 〜 2026-05-10T01:30 (JST)

## 作成ファイル

### 新規ソースコード

- `skills/aidlc-retrospective/SKILL.md` - 独立スキル定義（`/aidlc retrospective` / 短縮 `/aidlc r`）。単方向境界宣言（aidlc-retrospective → aidlc 内部 lib への直接依存禁止 / Facade 経由のみ許可）
- `skills/aidlc-retrospective/steps/retrospective.md` - 振り返り実行ステップ（v2.5.x まで `04-completion.md §1` にあった内容を全量移転 / 約 280 行）。§1.0 feedback_mode 解決〜§1.6 次サイクル Intent 反映まで網羅
- `skills/aidlc/scripts/lib/retrospective-api.sh` - 公開 API Facade 層（141 行）。`retrospective_api_*` プレフィックスで 10 関数を再エクスポート（タイプ A 2 件 + タイプ B 8 件）。多重 source ガード + AIDLC_BASE 解決 + 内部 lib 5 ファイルの統合 source
- `skills/aidlc/scripts/lib/cycle-resolver.sh` - 対象サイクル特定の独立公開コンポーネント（192 行）。4 Strategy（S1 Arg / S2 Branch / S3a GitLog / S3b CycleDir）+ 優先順位ロジック + S3a/S3b 不一致時の conflict 通知 fail-safe ガード

### 修正ソースコード

- `skills/aidlc/scripts/write-history.sh` - `--operations-stage` ヒント値検証を fail-closed cross-check に強化（不一致時 exit 3）/ `AIDLC_OPERATIONS_STAGE` 環境変数サポート追加 / `--unit-slug` の `^[a-z0-9][a-z0-9-]{0,63}$` パターン検証追加（Round 1 指摘 #5）
- `skills/aidlc/scripts/lib/validate.sh` - `validate_unit_slug` 関数新設（Round 1 指摘 #5）
- `skills/aidlc/steps/operations/04-completion.md` - §1（振り返り）約 440 行 → 約 25 行に縮退。実行ロジックを完全削除し `/aidlc r` 案内文のみ残置
- `skills/aidlc/SKILL.md` - parser に `retrospective` (`r`) アクション追加（5 箇所更新: 短縮形展開表 / 有効値リスト / エラー文言 / ルーティングテーブル / 委譲先テーブル / ヘルプ表示）
- `skills/aidlc-migrate/steps/03-verify.md` - v2.6.0 移行案内文追記（破壊的変更明示）
- `CHANGELOG.md` - `## [2.6.0]` セクション新設（BREAKING CHANGES + Added + Changed）
- `README.md` - `/aidlc r` 利用案内 + スキル一覧更新

### テスト

- `tests/cycle-resolver.bats` - 10 件（S1〜S3b Strategy 単体 / 優先順位 / fail-safe / S3b pwd fallback 削除確認）
- `tests/retrospective-api-facade.bats` - 10 件（10 公開関数の存在 / 5 値正規系 / 旧値互換 / requires_wizard Facade 経由 / 多重 source ガード）
- `tests/validate-unit-slug.bats` - 9 件（kebab-case 許可 / 拒否ケース 6 種 / write-history.sh 統合）
- `tests/operations-04-completion-section1-5.bats` - 9 件（書き換え。Unit 005 移転後の構造 verify: 旧ファイル削除確認 + 新ファイル構造保持確認）

### 設計ドキュメント（Phase 1 で作成 / Round 2 last_round_clean 確定）

- `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_005_aidlc_retrospective_skill_extraction_domain_model.md`
- `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md`

## ビルド結果

成功（bash スクリプトのため明示的なビルドプロセスはなし）

```text
bash -n skills/aidlc/scripts/lib/cycle-resolver.sh
bash -n skills/aidlc/scripts/lib/retrospective-api.sh
bash -n skills/aidlc/scripts/lib/validate.sh
bash -n skills/aidlc/scripts/write-history.sh
→ syntax OK

bin/check-bash-substitution.sh
→ no violations, 34 files checked
```

## テスト結果

成功

- 実行テスト数: 303（bats tests/）+ bin/tests 各テストスイート
- 成功: 303
- 失敗: 0

```text
bats tests/         : 1..303 全 pass（回帰なし）
bats bin/tests/operations-712-squash : 全 pass
bats bin/tests/aidlc-paths           : 全 pass
bash bin/tests/test_check_marketplace_version.sh : PASS=26 FAIL=0
bash bin/tests/test_update_version_no_toml_write.sh : PASS=14 FAIL=0
bash bin/check-bash-substitution.sh : no violations
```

工程 D 検証コマンド全 4 件 pass:

1. Operations 側に振り返り実行ロジック残存なし（`grep` 0 件ヒット）
2. `/aidlc r` が parser に追加（`skills/aidlc/SKILL.md` L127, 145, 155, 166, 224, 231）
3. `skills/aidlc-retrospective/SKILL.md` 存在
4. Inception `predecessor_resolve_issue` 不変（`skills/aidlc/steps/inception/01-setup.md` L80-87）

## コードレビュー結果

- [x] セキュリティ: OK（`--unit-slug` パターン検証追加 / S3b pwd silent fallback 削除）
- [x] コーディング規約: OK（`set -euo pipefail` / クォーティング / Facade 経由 / `$()` 不使用）
- [x] エラーハンドリング: OK（cycle_resolver_resolve rc=2 fatal 契約整備 / write-history exit code 1/2/3 整合）
- [x] テストカバレッジ: OK（38 件の新規・書き換えテスト / 既存 303 件回帰なし）
- [x] ドキュメント: OK（CHANGELOG / README / SKILL.md / aidlc-migrate 03-verify.md / retrospective.md 整合）

### AI レビュー履歴（reviewing-construction-code / codex）

| Round | 指摘件数 | 重要度内訳 | 対応 |
|-------|---------|-----------|------|
| Round 1 | 5 件 | 高1 / 中3 / 低1 | 全件修正（feedback_mode 表記統一 / Facade 違反解消 / sed `{{CYCLE}}` 値展開 / cycle-resolver rc=2 契約 / validate_unit_slug 追加） |
| Round 2 | 2 件 | 中2 | 全件修正（kpt_md_path 順序修正 / Strategy 契約コメント整合化） |
| Round 3 | 0 件 | - | `last_round_clean` で完了 |

`automation_mode=semi_auto` + `review_mode=required` + `unresolved_count=0` → `auto_approved`。

### 統合 AI レビュー（reviewing-construction-code / 統合観点）

実施。指摘 0 件（1R clean 特例）。検証範囲: bats 全 303 件 + bin/tests / bin/check-bash-substitution.sh / 工程 D 検証コマンド全 pass。

codex セッション ID: `019e0e6f-9369-75e0-a1ee-05cf2e8bd18b`（Phase 1 設計レビュー → Phase 2 コード Round 1-3 → 統合の 5 段階を同一セッションで継続）

## 技術的な決定事項

1. **公開 API Facade 層の導入（GATE-2 採用案）**: `aidlc-retrospective` から `aidlc/scripts/lib/` 内部実装への直接依存を遮断するため、`retrospective-api.sh` で `retrospective_api_*` プレフィックス公開関数のみを再エクスポート。出力タイプ規約（A: key=value 複数行 / B: raw text 1 行）で戻り値仕様を明示。Round 1 指摘 #2 を受けて `retrospective_api_requires_wizard` を後追い追加
2. **対象サイクル特定の Strategy 分離（GATE-3 採用案）**: 4 Strategy（引数 / カレントブランチ / git log / `.aidlc/cycles/`）を独立関数化し、優先順位 S1 > S2 > S3a > S3b で評価。`confidence != high` かつ S3a/S3b 不一致時は `conflict=true` 通知で呼出側 AskUserQuestion ガードを促す
3. **S3a 正規仕様（git log 第一・gh pr list 第二）**: ネットワーク不要なオフライン経路を優先。Round 1 指摘 #4 を受けて各 Strategy で `command -v` ガード + 終了コード捕捉に統一し、`|| true` で吸収していた誤判定経路を削除
4. **マージ前完結契約の fail-closed cross-check（GATE-7 採用案）**: `--operations-stage` ヒント値と実行コンテキスト導出値を `write-history.sh` 内で常時 cross-check。不一致時 `error:post-merge-history-write-forbidden:hint_mismatch:...` で exit 3。`AIDLC_OPERATIONS_STAGE` 環境変数のヒント偽装経路を遮断
5. **bash コード内 `{{CYCLE}}` を `$cycle` 変数化（Round 1 指摘 #3）**: AI 実行時 `{{CYCLE}}` 置換モデルとの衝突を解消。retrospective.md 内のすべての bash 呼び出しで `$cycle` 変数（`cycle_resolver_resolve` 経由で確定）を使用するように統一。テンプレ展開 sed は `s|{{CYCLE}}|${cycle//|/\\|}|g` で値展開 + delimiter 衝突回避
6. **Step 2 / Step 3 順序修正（Round 2 指摘 #1）**: `kpt_md_path` を Step 2 冒頭で展開し、prefill フック / compose_body 両方が定義済み参照になるように再構成

## 設計ドキュメントとの差分

設計ドキュメント（domain-model / logical-design）は Phase 1 完了時点で `retrospective_api_*` 公開関数 6 件を想定していた。Phase 2 のコードレビュー Round 1 指摘 #2 を受けて以下の関数が追加された:

- `retrospective_api_requires_wizard`（Facade に追加 / 設計の出力タイプ B）
- `retrospective_api_is_interactive_env`（実装早期で `is_interactive_env` 委譲として追加 / タイプ B）
- `retrospective_api_prefill`（prefill フック呼出 / タイプ B）
- `retrospective_api_update_issue`（update フック呼出 / タイプ B）

これらは設計の責務分離（L1〜L4 単方向境界 / Facade 経由のみ許可）を厳格化する方向の差分であり、契約レベルでの後退はない。`retrospective-api.sh` ヘッダコメントの出力タイプ規約に追加 4 関数を反映済み。

`cycle_resolver_resolve` の rc=2 fatal 契約はRound 1 指摘 #4 / Round 2 指摘 #2 を経て「Strategy は 0/1 のみ、rc=2 は将来拡張用予約 path」と明文化された。`resolve()` 側に rc=2 propagation 分岐を保持し、将来 Strategy が rc=2 を返す変更が入った際に即時伝播できる構造を確保。

## 課題・改善点

- `aidlc-retrospective` 単独 e2e CI の追加は本 Unit のスコープ外（計画書 OUT_OF_SCOPE）。Operations Phase テストで間接的に担保しており、必要時に別 Issue で起票
- 旧 v2.5.0 互換アダプタ層（`retrospective-generate.sh` / `retrospective-mirror.sh`）の完全削除は v2.7.x の別 Unit で対応予定（既存 lib は `retrospective-api.sh` 経由でのみ参照可能）
- `[rules.retrospective].feedback_mode` の表記揺れ（旧 3 値表記が一部の配下ドキュメントに残存している可能性）は本 Unit の検査範囲外。今後 review-summary 等で発見次第別 Issue で対処

## 状態

**完了**

## 備考

- 関連 Issue: #667
- 破壊的変更: v2.6.0 で Operations 内の振り返り起動を完全廃止（互換アダプタ層なし）
- 設計の domain-model / logical-design は Phase 1 で確定済（Round 2 last_round_clean）
- レビューサマリ: `.aidlc/cycles/v2.6.0/construction/units/005-review-summary.md`
- codex セッション ID: `019e0e6f-9369-75e0-a1ee-05cf2e8bd18b`
