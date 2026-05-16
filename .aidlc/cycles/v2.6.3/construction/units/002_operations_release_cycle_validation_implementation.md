# 実装記録: operations-release.sh cmd_squash_712 への --cycle バリデーション導入

## 実装日時

2026-05-15 〜 2026-05-15

## 作成ファイル

### ソースコード

- `skills/aidlc/scripts/operations-release.sh` - 変更（2 点）:
  - 冒頭（`DRY_RUN=0` 直後）に `source "${SCRIPT_DIR}/lib/validate.sh"` を追加
  - `cmd_squash_712` の `-z "$cycle"` チェック直後に `validate_cycle "$cycle"` 検証を追加
    （不正値時 `error\tsquash-712:invalid-cycle\t<value>` を stderr 出力 + `return 1`）

### テスト

- `tests/operations-release-squash712-cycle-validation.bats` - 新規。`cmd_squash_712` 入口の
  `--cycle` バリデーションを統合観点で検証する bats テスト（6 ケース: 正常 cycle /
  パストラバーサル / 先頭スラッシュ / 空白 / 制御文字 / 形式不一致）

### 設計ドキュメント

- `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_002_operations_release_cycle_validation_domain_model.md`
- `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_002_operations_release_cycle_validation_logical_design.md`

## ビルド結果

N/A（bash スクリプトのため build ステップなし）。`bash -n` 構文チェックは pass。

## テスト結果

成功

- 実行テスト数: 32（新規 6 + 既存 squash712 系 9 + 他 operations-release 系 17）
- 成功: 32
- 失敗: 0

```text
新規: tests/operations-release-squash712-cycle-validation.bats … ok 1〜6
回帰: tests/operations-release-squash712-dirty-history.bats … ok 7〜13
      tests/operations-release-squash712-integration.bats … ok 14〜15
      tests/operations-release-pr-edit-fallback.bats … ok 1〜8
      tests/operations-release-pr-ready-body-validate.bats … ok 9〜17
回帰なし。既存 squash712 dirty-history の (f) ケース（../etc / /tmp/evil）は
validate_cycle で先に拒否されるが、出力 squash-712:invalid-cycle は不変のため pass を維持。
```

## コードレビュー結果

- [x] セキュリティ: OK（Set 2 codex / focus: security 指摘0件。パストラバーサル対策の実効性確認済み）
- [x] コーディング規約: OK（Set 2 codex / focus: code 指摘0件。既存スタイルとの整合確認済み）
- [x] エラーハンドリング: OK（不正値時 exit 1 + tab 区切り stderr、既存インライン拒否と同一フォーマット）
- [x] テストカバレッジ: OK（計画 Phase 1 の不正パターン 4 種 + 正常系 + 形式不一致を網羅）
- [x] ドキュメント: OK（設計レビュー Set 1 で論理設計・ドメインモデルの整合性確認済み）

設計レビュー（Set 1 / codex / 反復2回 / 指摘3件すべて解消）、コードレビュー（Set 2 / codex /
指摘0件）、統合レビュー（Set 3 / codex / 指摘0件）。詳細は `002-review-summary.md` 参照。

## 技術的な決定事項

- `validate_cycle` の挿入位置は `-z "$cycle"` チェック直後（Step 1 の前）とした。これにより
  `__operations_release_progress_path` / `__squash_712_check_history_clean` を含む全ての
  `--cycle` 利用経路が検証後の値を参照することを保証
- 既存 `__squash_712_check_history_clean` のインライン・トラバーサル拒否は除去せず防御的に維持
  （二層防御。計画「責務境界の確定方針（fixed）」と整合）
- `lib/validate.sh` の source は既存スクリプト（`write-history.sh` 等）の慣例に従いファイル
  全体を取り込む。実装前に既存関数（23 個）と `validate.sh` 公開関数（6 個）の名前衝突が
  ないことを `grep` で確認（衝突なし）
- 新規 bats は独立した観点のため新規ファイル `operations-release-squash712-cycle-validation.bats`
  に分離（既存 squash712 bats の `setup()` パターンを流用）

## 課題・改善点

- 下位層 `__squash_712_check_history_clean` の `return 1` は invalid-cycle 拒否時も dirty 検出時も
  同一で、呼び出し元が一律 `squash:failed:reason=dirty_history` に丸める構造的曖昧さが残る
  （統合レビュー Set 1 指摘 #3）。入口層 `validate_cycle` 追加後は正常経路で下位層の
  invalid-cycle 分岐へ到達することはほぼなくなるため、責務分割は本 Unit のスコープ外とし
  decisions.md に既知の制約として記録する
- 他サブコマンド（`record-release-prep-commit` 等）への同種検証導入の要否は、Unit 完了処理で
  intent.md「分離判定基準」に照らして判断し decisions.md に記録する

## 状態

**完了**

## 備考

特記事項なし。
