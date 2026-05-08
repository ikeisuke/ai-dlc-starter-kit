# 意思決定記録 - v2.5.5

<!--
Inception Phase で発生した重要な意思決定を記録する。
DR-001 〜 DR-003 は Inception ストーリー・Unit 定義レビュー Round 1 指摘で確定した方針。
-->

## DR-001: fixture 更新トリガーの記録先を「Unit 完了履歴」に固定

- **ステップ**: Inception ストーリー・Unit 定義レビュー Round 1 指摘 #1 対応
- **日時**: 2026-05-08

### 背景

Intent / Story 1 / Unit 001 / Unit 005 の受け入れ基準で「fixture 更新トリガー（`gh` バージョン更新時に bats fixture が失敗することで気付ける運用ルール）」の記録先が「Construction Phase の設計レビュー or 履歴に記録」と "or" 表記で不定だった。Codex レビューで「検証対象・完了条件が不定」と指摘。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | Construction Phase の設計レビュー（design-artifacts/logical-designs）に記録 | 設計判断として一覧性が高い | 設計レビュー文書は Unit 単位で揮発しやすく、運用ルールとしての持続性が弱い |
| 2 | Unit 完了履歴（`history/construction_unitNN.md`）に記録 | サイクル完了後も恒久的に参照可能、AIDLC の標準的な「決定事実の沈殿先」 | 設計検討中の議論が history に残らないので背景把握には別途 review-summary 参照が必要 |
| 3 | 各 bats fixture コメントとして直接記録 | 実装の最も近くに残るため最も発見しやすい | 同じ運用ルールが複数 bats に重複記載される、横断的な参照が難しい |

### 決定

**選択肢 2（Unit 完了履歴に記録）** を採用。

### トレードオフと判断根拠

- **得たもの**: 運用ルールが Unit 完了 commit と紐づいて恒久的に追跡可能。`history/construction_unitNN.md` は 全 Unit で必ず生成されるため記録先が一意に定まる
- **犠牲にしたもの**: 検討プロセスは review-summary を別途参照する必要がある（ただし review-summary は本サイクルで生成済みのため実害なし）
- **判断根拠**: AI-DLC では「設計判断は design-artifacts、決定事実は history に沈殿」が確立した運用パターン。fixture 更新トリガーは「決定事実」に該当するため history が適切。なお、Unit 001 と Unit 005 は同様の保守ルールを共有するため、両 Unit の `history/construction_unit{NN}.md` で **「fixture 更新トリガー: gh CLI バージョン更新時に bats fixture が失敗することで気付ける」を 1 行以上記録** することを完了条件とする

---

## DR-002: write-history.sh の unstaged 警告判定主体を「write-history.sh 自身」に固定

- **ステップ**: Inception ストーリー・Unit 定義レビュー Round 1 指摘 #2 対応
- **日時**: 2026-05-08

### 背景

Unit 003 の AC (c) で「write-history.sh 実行後に履歴ファイルが unstaged の場合に警告を stdout/stderr に出力」を要求しているが、Intent [Question]/[Answer] では「判定主体は Construction Phase の設計レビューで詳細決定」となっており、テスト対象（関数 / 経路）が確定していない。Codex レビューで「変更範囲・テスト粒度が変わる」と指摘。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | write-history.sh 自身が判定（`git diff --cached --name-only -- <history-path>` 内部実行で staged 確認 → 警告） | 単一責任、bats テストで write-history.sh を直接呼んで検証可能、利用者側で何も追加実装不要 | write-history.sh が git コマンドに依存（ただし既に AI-DLC 全体で git は前提依存） |
| 2 | 外部から `git status` を確認（呼び出し側手順としてチェックリスト化） | write-history.sh 内部に git 依存を持ち込まない | bats テストでチェックリスト遵守を機械検証する手段が乏しく、実害発生リスクが残存 |
| 3 | 別 helper（`scripts/check-history-staged.sh`）を新設 | 責務分離が明確 | 新規ファイル追加で patch スコープが拡大、Unit 003 の修正範囲超過 |

### 決定

**選択肢 1（write-history.sh 自身が判定）** を採用。

### トレードオフと判断根拠

- **得たもの**: bats テスト対象が `write-history.sh` 関数の単独呼び出しで完結。利用者側の追加作業ゼロ。AC (c) の「警告を stdout/stderr に出力」が write-history.sh 内部で完結することで、commit-flow チェックリスト追加（AC (b)）と二重防御として機能
- **犠牲にしたもの**: write-history.sh が `git diff --cached` を呼ぶため、git リポジトリ外で実行された場合の挙動を考慮する必要がある（既存実装も .git 前提のため実害なし、ただし `git diff` 失敗時は警告スキップで exit 0 維持する仕様を Construction で明記）
- **判断根拠**: 単一責任原則 + テスト対象の明確化が Unit 003 の見積もり精度向上に直結。write-history.sh への内部判定追加は数行のコード変更で完結（patch スコープ内）。Unit 003 の責務に「判定主体: write-history.sh 自身」「テスト対象: write-history.sh の `--mode base` 通常パス完了直後の staged 確認分岐」を明記する

---

## DR-003: Unit 005 の「二段階失敗（gh pr edit 失敗 + REST PATCH も失敗）」 bats 検証を補足扱いに統一

- **ステップ**: Inception ストーリー・Unit 定義レビュー Round 1 指摘 #3 対応
- **日時**: 2026-05-08

### 背景

Unit 005 の技術的考慮事項に「異常系として『gh pr edit 失敗 + REST PATCH も失敗』の二段階失敗時の挙動も bats で検証する」と記載があるが、Story 5 / Intent 成功基準には必須要件として明記されていない。Codex レビューで「スコープの解釈差が出る」と指摘。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | Story 5 / Intent 成功基準に必須要件として追加 | 二段階失敗の挙動が確実に保証される | テストケース増加で Unit 005 の見積もりが拡大（patch スコープ圧迫） |
| 2 | Unit 005 から「必須」ニュアンスを外し、技術的考慮事項の補足扱いで統一 | 変更範囲を最小化、必須 AC は Story 5 / Intent と完全一致 | 二段階失敗時の挙動はベストエフォート扱いになる |

### 決定

**選択肢 2（Unit 005 を補足扱いで統一）** を採用。

### トレードオフと判断根拠

- **得たもの**: patch スコープ内で必須 AC が一意に定まる（Story 5 / Intent / Unit 005 の三者で同一の合格条件）。Unit 005 の見積もりが安定
- **犠牲にしたもの**: 二段階失敗の bats 検証は AI 実装者の判断で追加可能だが必須でない。仮に実装が未着手でも Unit 005 完了判定に影響しない
- **判断根拠**: 二段階失敗（fallback も失敗）は通常運用で発生頻度極低（読み取りスコープ全部欠落 + 書き込みスコープも欠落のレアケース）。発生時もエラーログから手動 fallback 可能。patch スコープ保護を優先し、Unit 005 の技術的考慮事項を「実装者裁量で追加可能、必須ではない」と明示する形に書き換える
