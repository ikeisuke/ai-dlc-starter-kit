# 実装記録: Unit 001 - AI エージェント Bash 実行の安全規約整備

## 実装日時

2026-05-14 〜 2026-05-15（Construction Phase）

## 作成ファイル

### ソースコード（変更）

- `skills/aidlc-migrate/scripts/lib/path-guard.sh` - #706 予防リファクタ。result-out 関数 6 つの内部 local を `_local_<関数省略名>_<名>` 形式で namespace 統一（`m` / `fb` / `rp` / `nlo` / `init` / `vp`）+ 各関数 docstring に命名規約メモ追記。外部公開関数シグネチャは不変。

### ドキュメント（変更）

- `CLAUDE.md` - #706 規約本文「printf -v 系 result-out 関数の local 命名規約」サブセクション追加（正本）/ #703「codex exec の stdin 待ちガード」横断ルール追加 / 関連 Issue に #706・#703 追記
- `AGENTS.md` - #703 横断ルール（codex exec は `</dev/null` 必須）を「最低限守るべき」リストに追加 + 関連規約に reviewing-common-base 参照追記
- `skills/aidlc/steps/common/bash-tool-safety.md` - #706 実装例・運用補助セクション（NG/OK スニペット）追加。正本は CLAUDE.md と明示
- `skills/reviewing-common/reviewing-common-base.md` - #703 正本。`codex exec` / `codex exec resume` 例に `</dev/null` 追加 +「stdin 待ちガードルール」セクション新設
- `skills/reviewing-*/references/reviewing-common-base.md`（9 ファイル）- 正本変更を `bin/sync-reviewing-common.sh` で同期伝播

### テスト

- 新規テストファイルなし。Unit 境界（自動 lint ルールの新規実装は行わない）および Unit 外部依存（`tests/migration` の既存 bats 49 件を回帰確認に使用）により、既存 bats が回帰スイートとして機能する。

### 設計ドキュメント

- `.aidlc/cycles/v2.6.3/design-artifacts/domain-models/unit_001_ai_bash_safety_conventions_domain_model.md`
- `.aidlc/cycles/v2.6.3/design-artifacts/logical-designs/unit_001_ai_bash_safety_conventions_logical_design.md`

## ビルド結果

成功（シェルスクリプト構文チェック）

```text
bash -n skills/aidlc-migrate/scripts/lib/path-guard.sh
→ syntax OK
```

## テスト結果

成功

- 実行テスト数: 49
- 成功: 49
- 失敗: 0

```text
# bats tests/migration/
1..49
ok 1 e2e: full v1-to-v2 migration pipeline succeeds
...
ok 49 verify: result JSON has correct structure
（全 49 件 pass / 0 failures。path-guard.sh の result-out 関数 namespace 統一リファクタによる回帰なし）
```

### その他の検証

| 検証 | コマンド | 結果 |
|------|---------|------|
| シェル構文 | `bash -n skills/aidlc-migrate/scripts/lib/path-guard.sh` | OK |
| migration 回帰 | `bats tests/migration/` | 49/49 pass, 0 failures |
| reviewing-common-base 同期 | `bash bin/sync-reviewing-common.sh --verify` | 9/9 OK |
| markdownlint | `npx markdownlint-cli2 <変更 .md 18 ファイル>` | 0 errors |
| bash substitution check | `bash bin/check-bash-substitution.sh` | 0 violations, 35 files |
| skill reference check | `bash bin/check-skill-references.sh` | 0 violations, 223 files |

## コードレビュー結果

- [x] セキュリティ: OK（path-guard.sh のパストラバーサル判定ロジック挙動不変。`printf -v` 書き込み先逸脱の再発なし。コードレビュー Set 2 指摘 0 件）
- [x] コーディング規約: OK（命名規約 `_local_<関数省略名>_<名>` を一貫適用。コマンド置換不使用）
- [x] エラーハンドリング: OK（終了コード 0/1/2 規約・stderr 出力フォーマット不変）
- [x] テストカバレッジ: OK（既存 bats 49 件で path-guard.sh の result-out 関数経路を回帰カバー）
- [x] ドキュメント: OK（規約 SoT 単一化 / 設計レビュー Set 1・コードレビュー Set 2 実施済み）

## 技術的な決定事項

- #706 規約 SoT は `CLAUDE.md`「AI エージェント Bash ツール経由の安全パターン」セクション内サブセクションに固定（既存の同セクション SoT 宣言に整合）。`bash-tool-safety.md` は実装例・運用補助のみ
- #703 codex 非対話実行運用 SoT は `reviewing-common-base.md` の「stdin 待ちガードルール」セクション。CLAUDE.md / AGENTS.md は横断参照のみ（規範文の重複掲載なし）
- path-guard.sh の namespace 化対象は result-out 関数（`printf -v "$result_var"` で書き込む関数）+ その caller の結果受け取り用 local に限定。`_emit_error` / `_detect_realpath_m` / `_has_parent_segment` は result-out 関数でないため対象外（設計時の [Answer] で確定）
- Phase 1 設計調査で「同期 verify を実行する CI ジョブは存在しない」ことが判明。検証手段を `bin/sync-reviewing-common.sh --verify`（ローカル/手動実行）に確定し、Plan・Unit 定義の「CI 同期 verify」記述を実機構に統一（設計レビュー Set 1 指摘 #1 対応）

## 課題・改善点

- 同期 verify を CI ジョブ化する案は Unit 境界（自動 lint ルールの新規実装は行わない）のため本 Unit では対象外。必要なら別 Issue で検討
- 完了条件チェックリストの最終確定と Unit 定義「実装状態」の「完了」化・完了日記入は、本 Unit の完了処理（Construction Phase ステップ 04）で実施する

## 状態

**実装完了**（Unit 完了処理で完了条件チェックリスト最終確定 + Unit 状態「完了」化を実施予定）

## 備考

- 統合レビュー Round 1 指摘 #1（bats 実行証跡なし）への対応として本実装記録ファイルを新設し、bats 49 件 pass の実行証跡および全 CI 構造チェック結果を記録した
- 統合レビュー Round 1 指摘 #2（完了条件トラッキング未更新）への対応として、Unit 定義「実装状態」を「進行中」に更新（開始日記入）し、計画ファイルの完了条件チェックリストの実装完了項目をチェック済みにした。「完了」化・完了日記入・残項目（統合レビュー実施確認）の最終チェックは完了処理で実施する
