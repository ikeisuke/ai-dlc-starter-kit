# 実装記録: Unit 003 — CycleResolver 明示指定優先の回帰テスト（T6）

## 実装日時
2026-06-23（Phase 1 設計 〜 Phase 2 実装・レビュー）

## 作成ファイル

### ソースコード
- なし（production code 変更なし。本 Unit は既存仕様の回帰テスト固定のみ）

### テスト
- `skills/aidlc-v3/scripts/tests/test-cycle-resolution.sh` - v3 cycle 解決の明示指定優先 / gitlog 非依存の回帰テスト（自己完結型 bash ハーネス / jq・git・mktemp 前提 / 12 アサート）

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/domain-models/unit_003_cycle_resolution_regression_test_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.4/design-artifacts/logical-designs/unit_003_cycle_resolution_regression_test_logical_design.md`

## ビルド結果
成功（bash スクリプトのためビルド工程なし。静的検査 `bash -n` / `shellcheck` clean）

```text
bash -n: OK
shellcheck: clean（read_cycle_in_sandbox は assert_out 経由の間接呼び出しのため SC2329 を理由付き disable）
```

## テスト結果
成功

- 実行テスト数: 12（新規 test-cycle-resolution.sh）
- 成功: 12
- 失敗: 0

```text
== 静的検査 ==（bash -n × 2 / shellcheck × 1）
== cycle 解決: 明示指定優先 ==（v3.0.0 / 任意値 v9.9.9）
== cycle 解決: gitlog 非依存（中核） ==（誤誘導 v2.6.6/v1.0.0 下で v3.0.0 / 誤誘導履歴実在確認 / state.json 変更後 v9.9.9）
== cycle 解決: 未設定/欠落・明示 null ==（read exit 1 / validate exit 1 / null="null" / validate null exit 1）
PASS: 12  FAIL: 0

回帰: v3 全7スイート緑（activation 19 / cycle-resolution 12 / define-flow 79 / develop-flow 49 / frontmatter-parser 67 / state-scripts 88 / work-item-next 33）
既存 check 4本緑: check-skill-references / check-bash-substitution / check-test-isolation / check-frontmatter-parse-guard
```

## コードレビュー結果
- [x] セキュリティ: OK（一時ファイルは mktemp 配下 / heredoc の変数展開は制御値 cycle のみ / 機密情報なし）
- [x] コーディング規約: OK（既存ハーネス様式踏襲 / bash 3.2-4.0+ 互換 / set -uo pipefail / git -C 不使用＝AGENTS.md 規約）
- [x] エラーハンドリング: OK（jq/git 未導入 exit 2 / サンドボックス構築失敗ハンドリング / assert_out は rc=0 必須）
- [x] テストカバレッジ: OK（明示指定優先 / gitlog 非依存 / 未設定拒否 / 明示 null 区別の4軸）
- [x] ドキュメント: OK（スクリプト冒頭コメントに目的・回帰意図・終了コード規約を記載）

## 技術的な決定事項
- **新規ファイル採用**（vs 既存 test-state-scripts.sh への追加）: cycle 解決 / gitlog 非依存は汎用 CRUD テストと関心が異なり、git サンドボックス構築という重いセットアップを伴うため独立ファイルに分離。#733 P4 の回帰テストとして単独で指し示せる。
- **gitlog 非依存の「証明」設計**: 単なる `assert_out` ではなく、`current_cycle` と異なる cycle 名（v2.6.6/v1.0.0）の git 履歴・ディレクトリを実際に作り、**サンドボックス cwd 内で** state-read を実行（`read_cycle_in_sandbox`）。将来 cwd 基準の git 推定が混入したら誤誘導履歴を踏んで赤になる実効的ガード。
- **環境非依存**: git サンドボックスは `user.email`/`user.name`/`commit.gpgsign=false` を `git -c` で明示し、グローバル git 設定に非依存。
- **production code 不変**: 計画 §4.5 のとおり、想定外差分は出ず（既存仕様が既に明示指定一本化）、production code は変更していない。

## 課題・改善点
- v3 の `skills/aidlc-v3/scripts/tests/*.sh` を集約実行する CI ランナーは未整備（現状は開発時ローカル直接実行）。本 Unit のスコープ外（既存運用に合わせた）。CI 集約は別途検討余地あり。

## 状態
**完了**

## 備考
- 関連 Issue: #733（部分対応 / T6 のみ / Relates、Closes ではない）。framework 側（`skills/aidlc/`）の CycleResolver は Intent 除外・本サイクル GA スコープ外。
- レビュー: 計画 codex 2R（指摘1 / git -C 不使用へ修正）/ 設計 codex 1R clean / コード codex 2R（指摘3 全 resolved）/ いずれも unresolved 0。
