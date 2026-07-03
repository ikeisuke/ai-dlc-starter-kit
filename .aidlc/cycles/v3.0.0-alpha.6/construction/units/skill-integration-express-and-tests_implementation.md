# 実装記録: Unit 004 SKILL.md 統合・express 整合・テスト・回帰

## 実装日時
2026-06-27 〜 2026-06-27

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/SKILL.md` - `release` を「予約」→ `steps/release.md`（実在 / Step 1–4）に公開フリップ。位置づけ注記・frontmatter・コマンド表・パス解決を実態同期し stale 注記を除去。
- `skills/aidlc-v3/steps/release.md` - 公開フリップ後の stale 記述除去 + release.md 必須成果物を PR head に commit/push する整合修正（Step 2-4 / 3-3 / 4-2）。
- `skills/aidlc-v3/templates/release.md` - stale Unit 履歴コメントを Step 参照に修正。

### テスト
- `skills/aidlc-v3/scripts/tests/test-release-flow.sh` - 新規作成（自己完結 / jq 前提 / ネットワーク非依存）。release フロー Step 1–4 の構造・契約・マーカー perspective 単位・SKILL.md/release.md/template の stale 回帰・契約文字列を静的検証（65 assertion）。

### 設計ドキュメント
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/domain-models/unit_004_skill_integration_express_and_tests_domain_model.md
- .aidlc/cycles/v3.0.0-alpha.6/design-artifacts/logical-designs/unit_004_skill_integration_express_and_tests_logical_design.md

## ビルド結果
成功（Markdown / shell のためビルド対象なし。markdownlint 0 errors / shellcheck clean / CI 構造チェック pass）

## テスト結果
成功

- 実行テスト数: 8 スイート（既存 7 + 新規 test-release-flow.sh）
- 成功: 8 / 失敗: 0
- test-release-flow.sh: PASS 65 / FAIL 0

```text
TOTAL: pass=8 fail=0（回帰ゼロ / worktree clean）
```

## コードレビュー結果
- [x] セキュリティ: OK（base 直 push でゲート迂回しない / Bash 安全規約 / 機密混入なし）
- [x] コーディング規約: OK（test-activation.sh と同型 / shellcheck clean / 多バイト隣接変数は ${} で明示）
- [x] エラーハンドリング: OK（fail-closed / 移植性 grep/awk）
- [x] テストカバレッジ: OK（Step 1-4 主要要素・マーカー perspective 単位・stale 回帰・契約文字列）
- [x] ドキュメント: OK（SKILL.md 実態同期 / SoT 参照）

## 技術的な決定事項
- **release 公開フリップ**: SKILL.md の `release` を実装済みに更新し、stale 注記（旧 Phase / develop tiny）を除去。reflect/doctor は予約のまま（過剰主張なし）。
- **テスト方針**: jq は YAML 非対応のため、review サマリマーカーは parse せず perspective 単位の構造検証（各キー出現数 == perspective 数 / merge_blocker_any は reviews 外に 1 回）。routing/post-merge は SoT 参照 + 契約文字列のスモーク+核検証。
- **stale 回帰の自動検出**: SKILL.md / release.md / template の Unit 番号・プレースホルダ時代の語彙を test で検出。
- **release.md 必須成果物の PR 取込整合**（統合レビュー高指摘）: Step 2-4 で release.md を PR head に commit/push し、merge で統合先に取り込む。merge 記録（merge_approved/merged）を Step 3-3 / 4-2 で段階的に反映。

## 課題・改善点
- reflect / doctor の実装は Phase 6。alpha.6 自身のリリースを v3 release フローで実行する dogfooding は Phase 7。本流化（skills/aidlc-v3 → skills/aidlc）は Phase 7。

## 状態
**完了**

## 備考
レビュー: 計画(2R) / 設計(2R) / コード(2R) / 統合(3R) を codex で実施し全指摘 resolve（unresolved 0 / defer 0）。統合レビューで release フロー全体（Step 1→4）の通しギャップ（release.md 必須成果物の PR 取込）を検出・修正。詳細は 004-review-summary.md 参照。
