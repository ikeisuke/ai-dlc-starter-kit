# Unit 006 検証記録: 削減目標達成の計測レポートと #519 クローズ判断

## 概要

サイクル v2.3.0 の最終 Unit。`bin/measure-initial-load.sh` による計測スクリプト整備、`measurement-report.md` による達成判定の文書化、Intent §成功基準の段階 2 評価、そして #519 クローズ判断（Issue 操作層は本検証完了後に実行）を担う総括 Unit。

## 実装日時

2026-04-10（単日完了）

## 作成ファイル

### スクリプト

- `bin/measure-initial-load.sh` - v2.2.3 / v2.3.0 初回ロード tok 数計測の決定論的スクリプト

### レポート

- `.aidlc/cycles/v2.3.0/measurement-report.md` - 9 章構成の計測レポート（スクリプト出力転載 + Intent 対照 + 結論）

### 設計ドキュメント

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_006_measurement_and_closure_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_006_measurement_and_closure_logical_design.md`

### レビュー / 計画

- `.aidlc/cycles/v2.3.0/plans/unit-006-plan.md`
- `.aidlc/cycles/v2.3.0/construction/units/006-review-summary.md`

## 検証 1: スクリプト構文と決定論性

### 構文チェック

```bash
bash -n bin/measure-initial-load.sh
```

**結果**: エラーゼロ。

### 決定論性検証（2 回連続実行のバイト一致）

```bash
bash bin/measure-initial-load.sh > /tmp/run1.txt
bash bin/measure-initial-load.sh > /tmp/run2.txt
diff -q /tmp/run1.txt /tmp/run2.txt
```

**結果**: 差分ゼロ（`DETERMINISM_CONFIRMED`）。同一 ref・同一 tokenizer・同一ファイル集合での tok 数計測が決定論的であることを実測で確認。

### `BASELINE_REF` 検証

スクリプト内 `BASELINE_REF="56c6463747b41ab74108055a933cdfe29781fb43"` と `git rev-parse v2.2.3^{commit}` の戻り値が一致することを実行時に検証する。実測時は照合成功（不一致時はエラーメッセージを出して exit 1）。

### `--help` 表示

```bash
bash bin/measure-initial-load.sh --help
```

**結果**: 使用法・終了コード一覧を表示して exit 0。

## 検証 2: 計測値の閾値判定（段階 1）

スクリプト出力からの抽出値:

| フェーズ | v2.2.3 | v2.3.0 | Δ | 削減率 | 必達閾値 | 判定 |
|---------|------:|------:|---:|------:|--------:|:----:|
| Inception | 22,972 | 14,655 | -8,317 | -36.2% | ≤ 15,000 | ✅ |
| Construction | 17,980 | 15,567 | -2,413 | -13.4% | ≤ 17,980 | ✅ |
| Operations | 17,209 | 15,502 | -1,707 | -9.9% | ≤ 17,209 | ✅ |

**段階 1 結果**: 3 フェーズすべて達成。

v2.2.3 ベースライン値（22,972 / 17,980 / 17,209）は Intent §成功基準の必達基準値および user_stories.md の記載値と完全一致。

## 検証 3: Intent §成功基準対照（段階 2）

`measurement-report.md §8` の対照表で、必須基準 5 項目 + 動作保証基準 8 項目について Unit 001-005 の検証/実装記録から実在ファイル名 + 行番号 + 具体引用を併記。`expected_assertion` 充足を確認。

**段階 2 結果**: 必須基準 5 項目達成、動作保証基準 8 項目達成。

## 検証 4: boilerplate 削減状況（補助項目）

### 軸 1: ステップファイル群合計 tok 比較

| フェーズ | v2.2.3 | v2.3.0 | Δ | 判定 |
|---------|------:|------:|---:|:----:|
| Inception | 14,256 | 13,999 | -257 | ✅ |
| Construction | 9,264 | 8,921 | -343 | ✅ |
| Operations | 8,493 | 8,676 | +183 | ⚠️ |

Operations のみ Tier 2 副作用で +183 tok（+2.2%）の微増。Intent §成功基準の必達項目に含まれず、#519 クローズには影響しない補助項目として記録。

### 軸 2: index.md 集約証跡

| パターン | Inception | Construction | Operations |
|---------|:---------:|:------------:|:----------:|
| automation_mode | ✅ | ✅ | ✅ |
| depth_level | ✅ | ✅ | ✅ |
| review-flow|review-routing | ✅ | ✅ | ✅ |
| express | ✅ | ✅ | N/A (-) |

全 applicability `○` セルで集約を確認（11/11）。

## 検証 5: 補助検証（既存 CI スクリプト）

```bash
bash bin/check-bash-substitution.sh
# Bash substitution check completed: no violations, 34 files checked

bash skills/aidlc/scripts/run-markdownlint.sh v2.3.0
# Summary: 0 error(s)
# markdownlint:success
```

**結果**: 既存 CI スクリプトすべて通過。

## ビルド結果

**成功**

```text
bash -n bin/measure-initial-load.sh  → エラーゼロ
bash bin/measure-initial-load.sh     → 全フェーズ計測成功、決定論性確認済み
bash bin/check-bash-substitution.sh  → 違反ゼロ
bash skills/aidlc/scripts/run-markdownlint.sh v2.3.0 → エラーゼロ
```

## テスト結果

**成功**

- 実行検証数: 5（構文 / 決定論性 / 段階 1 / 段階 2 / 補助 CI）
- 成功: 5
- 失敗: 0

## コードレビュー結果

- [x] セキュリティ: OK（パストラバーサルなし、機密情報なし、外部入力検証あり）
- [x] コーディング規約: OK（`set -euo pipefail`、quoting、終了コード正規化、配列正本化）
- [x] エラーハンドリング: OK（5 つの終了コードで失敗カテゴリを正規化、エラーメッセージは stderr）
- [x] テストカバレッジ: OK（決定論性 + 閾値判定 + Intent 対照 + 補助 CI を網羅）
- [x] ドキュメント: OK（スクリプト冒頭コメント / `--help` / 設計成果物 / レポート / レビューサマリすべて整備）

**レビュー履歴**:

- 計画レビュー: codex 4 反復、初回 5 件 → 0 件
- 設計レビュー: codex 2 反復、初回 4 件 → 0 件
- コードレビュー: codex 2 反復、初回 4 件 → 0 件

すべて `auto_approved (semi_auto, フォールバック非該当)`。

## 技術的な決定事項

1. **`BASELINE_REF` を実際の v2.2.3 タグ commit に固定**: Unit 定義が参照していた `d88b0074`（マージ元ブランチの最終コミット）と実際の v2.2.3 タグ commit `56c64637...`（PR #550 のマージコミット）の `skills/aidlc/` ツリー内容は完全一致するが、`git rev-parse v2.2.3^{commit}` が返す実際のタグ commit を正本とする
2. **計測対象ファイルリストの正本をスクリプト内 bash 配列に一元化**: 計画書とレポートは参考表示のみ。スクリプトと不一致が発生した場合はスクリプトを真とする
3. **決定論性の物理的保証**: 表示パスに一時ディレクトリパスを使わず、`display_path::real_path` ペアでスクリプト内に固定文字列の表示パスを保持し、出力をバイト単位で安定化
4. **#519 クローズ判断の 2 段階化**: 計測達成（段階 1）+ Intent §成功基準項目（段階 2）の両方を必須化。引用は `expected_assertion` ベースで「引用の存在」ではなく「引用内容が期待条件を満たすか」で判定
5. **boilerplate 削減を補助項目（非阻害）扱い**: Intent で「自動解消扱い」とされていることを根拠に、軸 1（ステップファイル群合計 tok 比較）/ 軸 2（index.md 集約証跡）の判定結果を記録するが #519 クローズには影響させない。Operations の +183 tok 微増は Tier 2 施策（`operations-release.sh` 化、`review-routing.md` 抽出）の副作用として注記
6. **boilerplate 機械検証を 2 軸化**: 当初の grep ベースの単純パターンカウントでは「ロジック記述」と「`steps/{phase}/index.md` への参照記述」を区別できなかったため、軸 1 を tok 数比較に変更

## 課題・改善点

- **Operations のステップファイル群合計 tok 微増（+183 tok）**: 補助項目のため #519 クローズに影響しないが、将来的に `operations-release.sh` への参照記述や `review-routing.md` への参照記述を最小化する余地がある。本サイクルではバックログ Issue 化はせず、レポートに記録のみ
- **`bin/measure-initial-load.sh` の Python 依存パス固定**: `/tmp/anthropic-venv/bin/python3` をハードコードしている。将来 Python 環境が変わる場合はスクリプトの更新が必要

## 状態

**完了**

## Unit 完了処理結果

- **CHANGELOG.md 更新**: v2.3.0 セクションを追加（Changed: 案D 実装 / Tier 2 施策、Fixed: #553 根本解決、Added: `bin/measure-initial-load.sh` / `measurement-report.md`）
- **#519 クローズ判断コメント投稿**: <https://github.com/ikeisuke/ai-dlc-starter-kit/issues/519#issuecomment-4218804629>
- **#519 ラベル更新**: `status:in-progress` → `status:done` （`status:done` ラベルは本 Unit で新規作成）
- **#519 クローズ**: `gh issue close 519 --reason completed` 実行成功、`gh issue view 519 --json state` で `state="CLOSED"` を確認

## 備考

サイクル v2.3.0 の総括 Unit として、#519 コンテキスト圧縮プロジェクトのクローズを完遂した。
