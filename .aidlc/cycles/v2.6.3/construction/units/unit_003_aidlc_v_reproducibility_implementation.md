# 実装記録: Unit 003 - /aidlc v 経路の再現性向上

## 実装日時

2026-05-15 〜 2026-05-15

## 作成・更新ファイル

### ソースコード

- `skills/aidlc/scripts/lib/version.sh` - CLI モードガード内に引数省略時の自己解決ロジック追加（`$# -eq 0` で `SCRIPT_DIR/../../../../.claude-plugin/marketplace.json` を `read_marketplace_version` に渡す）。冒頭コメントに自己解決ロジック存在と SoT 責務分離（CLAUDE.md / Issue #688）を明記
- `skills/aidlc/SKILL.md` - 「バージョン表示」節を圧縮（4 ステップ + 推測禁則 + zsh OOM 横断参照）、本文 298 行（500 行制限内）

### テスト

- `skills/aidlc/scripts/tests/test_read_marketplace_version.sh` - 旧 C3 を C3a / C3b / C3c に分解、C9 を追加（合計 28 テスト）

### 設計ドキュメント

- `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_003_aidlc_v_reproducibility_domain_model.md`
- `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_003_aidlc_v_reproducibility_logical_design.md`

### ドキュメント / 計画

- `.aidlc/cycles/v2.6.3/plans/unit-003-plan.md` - 完了条件チェックリスト 13 項目完了
- `.aidlc/cycles/v2.6.3/story-artifacts/units/003-aidlc-v-reproducibility.md` - 実装状態を「完了」に更新
- `.aidlc/cycles/v2.6.3/construction/units/003-review-summary.md` - 3 Set のレビューサマリ集約

## ビルド結果

成功（シェルスクリプトのため明示的ビルド工程なし。`bash skills/aidlc/scripts/lib/version.sh` の構文解析・実行で動作確認）

## テスト結果

成功

- 実行テスト数: 28
- 成功: 28
- 失敗: 0

```text
=== read_marketplace_version() テスト ===
PASS: 11 (関数本体: 通常 SemVer / prerelease / 空 / 非 SemVer / metadata 不在 / ファイル不在 / 引数空 / 読取権限なし 等)

=== CLI モード経由テスト ===
PASS: C1 / C2（既存）/ C3a / C3b / C3c（新規分解）/ C4 / C5 / C6 / C8 / C9（新規後方互換）

合計: PASS 28 / FAIL 0
```

回帰確認:

- `bin/check-marketplace-version.sh` → exit 0, `marketplace_version_check:ok`
- `bin/tests/test_check_marketplace_version.sh` → 14/14 PASS
- `npx markdownlint-cli2 skills/aidlc/SKILL.md` → 0 errors

## コードレビュー結果

- [x] セキュリティ: OK（N/A: ローカル CLI ツール内処理、ネットワーク・認証・永続データ非該当）
- [x] コーディング規約: OK（codex / reviewing-construction-code 1R clean）
- [x] エラーハンドリング: OK（exit 0/1/2 分類、stderr メッセージ既存仕様維持）
- [x] テストカバレッジ: OK（CLI レイヤー C3a/b/c、関数レイヤー、後方互換 C9 を独立にカバー）
- [x] ドキュメント: OK（SKILL.md 圧縮、version.sh 冒頭コメント更新、SoT 責務分離明示）

## 技術的な決定事項

1. **自己解決ロジックを CLI モードガード内に閉じる**: 関数本体（`read_marketplace_version`）の引数契約を不変に保ち、レイヤー責務（関数 vs CLI）を分離。テスタビリティ維持 + 後方互換性確保。
2. **`$2` 以降のサイレント無視を正式契約として確定**: 既存 v2.6.1 Unit 001 / Issue #688 で確立した挙動を後方互換維持のため正式契約化。引数個数チェック追加は破壊的変更となるため見送り。
3. **テスト C3 を C3a / C3b / C3c に分解**: CLI 契約と関数契約のレイヤー責務を独立に検証。C3b は `version.sh` を一時ディレクトリに複製して相対基点をずらす方式を採用（環境変数 override は現行仕様に存在しないため不採用）。
4. **SoT 責務分離の明示**: 規約本文 SoT は CLAUDE.md + bash-tool-safety.md、`version.sh` 冒頭コメントは「運用メモ + Issue リンク」役割に限定（Codex 設計レビュー指摘で確定）。
5. **lint コマンド統一化は OUT_OF_SCOPE**: リポジトリ全体の lint 運用統一は本 Unit Intent「含まれるもの」非該当のため #709 として defer 起票。

## 課題・改善点

- **#709 への対応**（次サイクル候補）: markdown lint 実行手段の統一化（`npm run lint:md` 等）。外部レビュー環境（codex 等）での再現性向上が目的。
- **パス段数のリポジトリ構造依存**: `../../../../.claude-plugin/marketplace.json`（4 段）は `<repo_root>/skills/aidlc/scripts/lib/` 配置を前提とする。`bootstrap.sh` 等も同前提を共有しており、構造変更時は両者同時改修が必要（変更が必要な場合は別 Issue 化）。

## 関連 Issue

- 解決対象: #698（/aidlc v 経路の再現性向上）
- 起票: #709（defer / markdown lint 統一化、OUT_OF_SCOPE）

## レビュー実施記録

- 計画承認前レビュー: 4 rounds clean（codex / 詳細は履歴）
- 設計レビュー Set 1: 2 rounds clean
- コードレビュー Set 2: 1R clean 特例
- 統合レビュー Set 3: 4 rounds clean（unresolved=0、defer=1 / #709）
- すべて codex / review_mode=required / セミオートゲート判定: 全承認ポイント auto_approved
