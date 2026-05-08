# Unit 004 計画: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加

## 概要

`skills/aidlc/steps/operations/04-completion.md` のステップ 3（バージョンタグ付け）に「リモート CI 自動 tag 機構との競合確認」手順を追加する。`git ls-remote --tags origin vX.X.X` による事前確認 + 衝突時の判定マトリクス（不在 / 同 SHA 衝突 / 異 SHA 衝突）+ fallback 手順を文書化することで、Visitory v1.15.0 cycle で観測された tag push reject 時の誤判断リスク（自分のタグが拒否された / force push が必要？）を排除する。

## 関連 Issue

- #650（[Feedback] 04-completion ステップ3 に「リモート CI 自動 tag 機構との競合確認」手順追加）

## スコープ確定（Unit 定義からの抽出）

Unit 定義の責務 4 項目を SoT とする。Issue #650 の「B. config に CI 自動 tag 運用フラグを追加」「C. CI 連携パターン例 / `guides/` 配下」は **本 Unit のスコープ外**（Issue 提案のうち Unit 定義に取り込まれていない部分は OUT_OF_SCOPE）。

| 項目 | スコープ判定 | 備考 |
|------|------------|------|
| A. ステップ 3 への事前確認 + 判定マトリクス + fallback 手順追加 | IN | Unit 定義「責務」4 項目に該当 |
| B. `version_tag = "ci"` モードの追加 | OUT | Unit 境界「既存の `version_tag = false`/`true` 設定の構造変更は行わない」 |
| C. `guides/` 配下の CI 連携パターン例 | OUT | Unit 境界「CI 自動 tag ワークフローのテンプレート提供は行わない」 |
| bats テスト追加 | OUT | Unit 境界「bats テスト追加は不要」（成功基準は grep / markdown 構造検証で機械的にチェック） |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/steps/operations/04-completion.md` | 改修（責務 1〜4） | ステップ 3 に事前確認手順 + 判定マトリクス（3 ケース）+ 同 SHA fallback（3 項目）+ 異 SHA fallback（3 項目）を追加 |
| `.aidlc/cycles/v2.5.5/history/construction_unit04.md` | 新規作成 | Unit 004 進捗履歴（変更ファイル / レビュー round / 検証結果 / grep 検証ログ） |

設計成果物（Phase 1）:

- `design-artifacts/domain-models/unit_004_operations_tag_conflict_handling_domain_model.md`: リモート tag 状態のドメイン語彙（不在 / 同 SHA / 異 SHA）、tagger 種別（github-actions[bot] / human / 不明）、判定マトリクスのドメインモデル
- `design-artifacts/logical-designs/unit_004_operations_tag_conflict_handling_logical_design.md`: 04-completion.md ステップ 3 への挿入位置・文言確定、判定マトリクスの markdown table 構造、3 ケース手順の文書構造

## 文書構造設計（責務 1〜4 のマッピング）

### 1. 事前確認手順（責務 1）

ステップ 3 の `version_tag = true` 経路の冒頭に挿入する。**annotated tag の誤分類を防ぐため、存在検出と peeled commit SHA 取得の 2 段で実施**（設計レビュー Round 1 指摘 #1 反映）:

```bash
# (新規 1) リモートに同名タグが既に存在するか確認（存在検出）
git ls-remote --tags origin vX.X.X

# (新規 2) annotated tag の誤分類を防ぐため、peeled commit SHA を取得
git ls-remote origin "refs/tags/vX.X.X^{}"
# 出力空かつ手順 1 が非空なら lightweight tag → 手順 1 の SHA を採用
```

`version_tag = false` 経路には影響しない。

### 2. 判定マトリクス（責務 2）

3 ケース必須を 4 列以上の markdown table で記載する:

| ケース名 | 検出条件（peeled commit SHA 比較） | 期待結果 / 動作 | 次アクション |
|---------|-----------------------------------|---------------|------------|
| ケース A: 不在 | 手順 1（`git ls-remote --tags`）が空出力 | リモートに未作成。ローカルから新規作成可 | 既存手順通り `git tag -a` + `git push origin vX.X.X` |
| ケース B: 同 SHA 衝突 | 手順 2（`refs/tags/vX.X.X^{}`）の SHA = `git rev-parse HEAD` | CI 側が先に作成済み。最終 commit SHA が同じなのでリモート版が正規 | 同 SHA fallback（後述）でローカル同期 |
| ケース C: 異 SHA 衝突 | 手順 2 の SHA ≠ `git rev-parse HEAD`（手順 2 が空かつ lightweight tag で手順 1 の SHA も不一致 を含む） | リモート tag が予期しないコミットを指している。誤操作 / 古い CI 実行の可能性 | 異 SHA fallback（後述）で安全側中断 |

> SHA 一致判定は **peeled commit SHA 同士**（`git ls-remote origin "refs/tags/vX.X.X^{}"` の出力 SHA と `git rev-parse HEAD` の出力）を文字列完全比較する。`git ls-remote --tags` の素の出力（annotated tag では tag object SHA）はコミット SHA と直接比較してはならない（誤分類防止 / 設計レビュー Round 1 指摘 #1 反映）。

### 3. 同 SHA 衝突時の fallback 手順（責務 3）

3 項目必須:

1. **ローカル tag 削除**: `git tag -d vX.X.X`（ローカルにアノテーション付きで作成済みの場合のみ。未作成ならスキップ）
2. **リモート版を取得**: `git fetch origin tag vX.X.X`
3. **同期検証**: `git show vX.X.X` で取得した tag の commit / tagger を確認し、想定どおりであることを確認

### 4. 異 SHA 衝突時の手順（責務 4）

3 項目必須:

1. **自動 push 中止**: `git push origin vX.X.X` を実行しない（既に実行している場合は reject されているため追加対応不要）
2. **差分提示**: `git ls-remote origin "refs/tags/vX.X.X^{}"` で取得した **peeled commit SHA**（`<remote-commit-sha>`）と `git rev-parse HEAD` のローカル SHA（`<local-sha>`）を表示し、`git log <remote-commit-sha>..<local-sha>` および逆方向 `git log <local-sha>..<remote-commit-sha>` で双方向の差分をユーザーに提示。**peeled 出力が空の場合は lightweight tag として `git ls-remote --tags origin vX.X.X` の SHA を `<remote-commit-sha>` に採用する**（tag object SHA を `git log` に渡してはならない / 設計レビュー Round 2 指摘 #1 反映）
3. **ユーザー選択肢提示**:
   - (i) リモート優先: ローカル tag を削除し `git fetch origin tag vX.X.X` で同期（推奨）
   - (ii) ローカル優先: `git push --force origin vX.X.X`（**破壊的操作**。明示確認必須。CI 機構や他のリリース成果物との整合性が壊れるリスクを警告）
   - (iii) 中断: tag 操作をスキップして調査（`Operations Phase` を中断し、CI 設定 / リモート tag の作成経緯を調査）

## ドリフト検知（grep 検証クエリ / 設計レビュー Round 1 指摘 #2 反映）

責務ごとに分割した複数クエリで検証する。各クエリは少なくとも 1 件 hit することを期待値とする:

| 責務 | 検証クエリ | 期待 hit |
|------|----------|---------|
| 1 | `grep -nE 'git ls-remote --tags origin vX\.X\.X' skills/aidlc/steps/operations/04-completion.md` | ≥ 1 |
| 1（誤分類防止） | `grep -nE 'refs/tags/vX\.X\.X\^\{\}\|vX\.X\.X\^\{commit\}' skills/aidlc/steps/operations/04-completion.md` | ≥ 1 |
| 2 | `grep -nE 'ケース A\|ケース B\|ケース C' skills/aidlc/steps/operations/04-completion.md` | ≥ 3（3 ケース全て） |
| 2 | `grep -nE 'github-actions\[bot\]' skills/aidlc/steps/operations/04-completion.md` | ≥ 1 |
| 3 | `grep -nE '同 SHA' skills/aidlc/steps/operations/04-completion.md` + 同セクション内の `1\.` / `2\.` / `3\.` 順序付きリスト確認 | 同 SHA fallback の 3 項目構造 |
| 4 | `grep -nE '異 SHA' skills/aidlc/steps/operations/04-completion.md` + 同セクション内の `1\.` / `2\.` / `3\.` 順序付きリスト確認 | 異 SHA fallback の 3 項目構造 |
| 4 | `grep -nE '\(i\)\|\(ii\)\|\(iii\)' skills/aidlc/steps/operations/04-completion.md` | ≥ 3 |
| 4 | `grep -nE '破壊的\|明示確認' skills/aidlc/steps/operations/04-completion.md` | ≥ 1 |

すべてのクエリが期待 hit を満たせば責務 1〜4（誤分類防止を含む 5 項目）が文書に組み込まれていることを機械的に確認できる。

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `git ls-remote` がネットワーク失敗 | 既存手順の `git push origin vX.X.X` 失敗時と同等。エラーメッセージを表示しユーザーが再試行 / 手動介入を判断（事前確認手順そのものは追加運用負荷ゼロ） |
| マージコミット SHA が取得できない（`git rev-parse HEAD` 失敗） | 既存ステップ 1（`git checkout main`）/ 2（`git pull`）が完了していない可能性。事前確認手順の前提条件（main 最新）を満たさないため、直前ステップへの差し戻しを案内 |
| ケース C で iii）中断を選択 | tag 操作を完了せず Operations Phase を中断。`history/operations.md` に「tag 競合により中断」を記録し、調査完了後にステップ 3 から再開 |
| 同 SHA 比較で部分一致 / 短縮 SHA 混在 | `git ls-remote` 出力は full SHA（40 文字）固定。`git rev-parse HEAD` も full SHA 出力のため文字列完全一致で判定可能 |

## NFR

- **パフォーマンス**: `git ls-remote` 1 回追加（リモート問い合わせ 1 ラウンドトリップ）。許容範囲（< 1 秒想定）
- **セキュリティ**: 該当なし（リモート tag 確認は読み取り操作のみ）
- **後方互換**: 既存の `version_tag = false` 経路は完全に未変更。`version_tag = true` 経路のみ事前確認手順を追加。既存ユーザーは「ケース A」に該当する限り従来通りの手順で完了する

## 完了条件チェックリスト

### 文書整合（責務 1: 事前確認手順）

- [ ] `04-completion.md` ステップ 3 の `version_tag = true` 経路に `git ls-remote --tags origin vX.X.X` の事前確認手順が追加されている
- [ ] 事前確認手順は既存の `git tag -a` / `git push` の **前** に挿入されている

### 文書整合（責務 2: 判定マトリクス）

- [ ] 判定マトリクスが markdown table 形式で記載されている
- [ ] 3 ケース必須（不在 / 同 SHA 衝突 / 異 SHA 衝突）すべてが table 行に含まれている
- [ ] table のカラム数が 4 列以上（ケース名 / 検出コマンド出力 / 期待結果 / 次アクション）
- [ ] 各ケースに実行コマンド 1 つ以上 / 期待結果 1 つ以上 / 次アクション 1 つ以上が記載されている

### 文書整合（責務 3: 同 SHA fallback）

- [ ] 同 SHA 衝突時の fallback 手順が 3 項目記載されている
- [ ] 3 項目に「ローカル tag 削除」「`git fetch origin tag vX.X.X`」「同期後検証」の 3 つが含まれている

### 文書整合（責務 4: 異 SHA 手順）

- [ ] 異 SHA 衝突時の手順が 3 項目記載されている
- [ ] 3 項目に「自動 push 中止」「差分提示」「ユーザー選択肢提示」の 3 つが含まれている
- [ ] ユーザー選択肢に (i) リモート優先 / (ii) ローカル優先（破壊的・明示確認必須）/ (iii) 中断 の 3 つが含まれている

### ドリフト検知 / grep 検証

- [ ] 計画 §「ドリフト検知（grep 検証クエリ）」の **8 クエリすべて** を実行し、期待 hit 数を満たすことを確認、Unit 履歴に記録
- [ ] peeled commit SHA 取得コマンド（`refs/tags/vX.X.X^{}` または `vX.X.X^{commit}`）が文書に含まれている（誤分類防止）
- [ ] (ii) ローカル優先選択肢に「破壊的」かつ「明示確認」の両キーワードが文書内に併記されている
- [ ] 既存記述（`version_tag = false`/`true` の二択構造）が破壊的に変更されていないことを diff 確認

### 履歴

- [ ] `.aidlc/cycles/v2.5.5/history/construction_unit04.md` が新規作成され、変更ファイル / レビュー round / 検証結果 / grep ログが記録されている

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件を満たす
- [ ] markdownlint が変更対象 markdown ファイルで pass

## 見積もり

- 設計フェーズ: 0.1 日（domain model / logical design / 文言確定）
- 実装フェーズ: 0.15 日（04-completion.md ステップ 3 への追加 + grep 検証 + 履歴記録）
- レビューフェーズ: 0.05 日
- 合計: **0.3 日（約 2〜2.5 時間）**（Unit 定義の見積もり「2 時間」とほぼ整合）
