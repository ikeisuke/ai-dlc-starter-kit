# ユーザーストーリー — v2.5.3「振り返り機能の信頼性向上」

## Epic: 振り返り機能（retrospective）の構造的脆弱性の解消

本サイクルで対応する 5 ストーリーはすべて Operations Phase §1 振り返りフローまたはその支援基盤（履歴記録 / 解析補助スクリプト）に関連する。Issue #647 / #637 / #634（絞込）/ #643 にそれぞれ対応する（**#637 については Round 1 レビュー指摘 #4 に従い「short note 追加」と「operations-round 追加」を 2 ストーリーに分割したため、Issue 4 件 / ストーリー 5 件**）。

---

### ストーリー 1: Operations §1 振り返りでの auto mode 独断起票を防ぐ（#647）

**優先順位**: Must-have

**As a** AI-DLC Starter Kit を `feedback_mode=mirror` × `automation_mode=semi_auto` × Claude Code auto mode で運用する開発者
**I want to** AI エージェントが対話を経ずに振り返り Issue を `gh issue create` してしまう運用ミスを構造的に防止してほしい
**So that** jailrun #70 で実証されたような「KPT / 主因切り分け / mirror 送信判断のすべてが AI 独断で確定して起票される」事故を再発させない

**受け入れ基準**:

- [ ] `steps/operations/04-completion.md` §1 冒頭（§1.0 と §1.1 の間）に「対話必須」明記が追加されており、**§1 ブロック範囲に限定して** `grep -E "対話必須|AskUserQuestion"` がヒットする（`awk '/^#### 1\.0/,/^### 2\./' steps/operations/04-completion.md | grep -cE "対話必須|AskUserQuestion"` が **2 以上**）
- [ ] §1.0 の `feedback_mode` テーブル直後または §1.0 表内に「`feedback_mode=silent` でも KPT 判断は対話必須（mirror 送信が不要なだけで対話自体は省略禁止）」が明示される
- [ ] `skills/aidlc/SKILL.md` の「AskUserQuestion 使用ルール」テーブルに「振り返り内容の決定」種別が追加され、auto mode 適用外（必ず `AskUserQuestion`）であることが明示される（`grep "振り返り内容の決定" skills/aidlc/SKILL.md` が 1 件以上）
- [ ] §1 内のすべての `gh issue create` / `gh api PATCH` 実行コマンドの直前に AskUserQuestion による要否・内容・mirror 送信可否の確認が必須化されており、対話なし起票パスが存在しない
- [ ] **fixture 検証の定量条件**:
  - 本リポ内ドライラン用 fixture（`.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md` 等）が作成される
  - fixture 上で「AskUserQuestion 未実施 → `gh issue create` に到達」のシナリオを擬似実行した場合、(a) 手順上で `❌ 対話必須ガード違反` と等価なエラー文言が定義されている / (b) 期待出力に `gh issue create` 行が**含まれない**こと / (c) `04-completion.md` §1 をなぞる手順が `AskUserQuestion → 対話 → 起票判断 → gh issue create` のシーケンスを必ず通過すると確認できる
- [ ] 履歴記録: `aidlc:write-history` 経由で「対話必須ガード強化反映」が `.aidlc/cycles/v2.5.3/history/construction_unit01.md` に追記される

**技術的考慮事項**:

- `04-completion.md` 651 行のうち §1 セクションの改訂のみ。他セクション（§2 バックログ・§3-§7 リリース手順等）は不変
- `SKILL.md` 251 行のうち「AskUserQuestion 使用ルール」テーブルへの行追加のみ。500 行制限を維持
- jailrun #70 / PR #71 は外部参考事例として記載するが、合格判定からは non-blocking に分離

---

### ストーリー 2A: write-history skill に Unit 完了 short note モードを追加（#637 / 分割①）

**優先順位**: Must-have

**As a** AI-DLC で複数サイクルを継続する開発者・メンテナ
**I want to** Unit 完了時の short note（3-5 行の苦労 / 次サイクルへの伝言）が履歴に必ず記録される構造にしてほしい
**So that** v2.5.1 Unit 002 で発生した short note 記録漏れの再発を防ぎ、次サイクル振り返り時に Unit 単位のリアルタイム文脈を一次情報として参照できる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/write-history.sh` に `--mode unit-complete-short-note` オプションが追加される
- [ ] `/write-history --mode unit-complete-short-note --short-note "<3-5 行>" --cycle X --unit N` を実行すると `history/construction_unitNN.md` 末尾に固定テンプレ「## 補足（short note）」セクション + 自由記述行が追記される（exit 0）
- [ ] `skills/write-history/SKILL.md` 引数表に `--mode unit-complete-short-note` の説明が追記される（500 行制限内）
- [ ] 既存呼び出し（`--mode` 未指定の従来パス）は完全互換（exit code / 出力フォーマット / 追記位置）
- [ ] post-merge ガード（`--operations-stage post-merge` / 自動判定）は新モードでも有効（exit 3 維持）
- [ ] 履歴記録: 本 Unit 自体が新規モードを使って short note を書く self-apply

**技術的考慮事項**:

- `write-history.sh` 787 行のうち引数パーサ + `--mode unit-complete-short-note` 分岐 + テンプレ構築箇所を増設
- short note は AI が「Unit 完了直前」に直接記述する

---

### ストーリー 2B: write-history skill に Operations round エントリモードを追加（#637 / 分割②）

**優先順位**: Must-have

**As a** AI-DLC で Operations Phase の PR マージ前レビューを運用するメンテナ
**I want to** PR マージ前レビュー round 1 から round 5 まで、各 round 開始時点の指摘件数・重要度内訳・対応判定を履歴に必ず記録できるようにしてほしい
**So that** v2.5.1 で発生した「round 1 履歴漏れ」を構造的に防止し、次サイクル振り返りで Operations の round 推移を再現できる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/write-history.sh` に `--mode operations-round` オプションが追加される
- [ ] `/write-history --mode operations-round --round R --findings F --critical C --high H --medium M --low L --resolved-count X --deferred-count Y --cycle Z` を実行すると `history/operations.md` に round R エントリ（指摘件数 / 重要度内訳 / 対応判定の集計）が追記される（exit 0）
- [ ] round 1 〜 round 5 すべてで同一テンプレ構造のエントリが追記される（round 番号によるテンプレ差分なし）
- [ ] `skills/write-history/SKILL.md` 引数表に `--mode operations-round` の説明が追記される（500 行制限内）
- [ ] 既存呼び出し（`--mode` 未指定の従来パス）は完全互換
- [ ] post-merge ガード（`--operations-stage post-merge` / 自動判定）は新モードでも有効

**技術的考慮事項**:

- ストーリー 2A と同じ `write-history.sh` を改修するため、Construction Phase で 2A → 2B の順または 1 Unit に統合実装すると効率的
- Operations round エントリは「## Round R: YYYY-MM-DD HH:MM:SS」+ 指摘件数 / 重要度内訳 / 対応判定の標準集計テーブル

---

### ストーリー 3: 振り返り作業での推測値混入を予防する（#634 絞込）

**優先順位**: Should-have

**As a** AI-DLC で振り返り（特にメタ振り返り）を実施する AI エージェント・メンテナ
**I want to** 一次情報を Read しても、セッション内記憶からの推測値（「約」「approximately」「推定」等）が KPT / 主因切り分け / Issue 本文に混入しないようガードしてほしい
**So that** 振り返り Issue の信頼性が高まり、次サイクルの Intent 立案で誤った前提から出発するリスクを下げられる

**受け入れ基準**:

- [ ] `steps/operations/04-completion.md` §1.x（§1.1 KPT テンプレと §1.2 主因切り分けの間）に「事実テーブル先抽出ステップ」が追加される（`grep -E "事実テーブル|fact[- _]table" steps/operations/04-completion.md` で 1 件以上）
- [ ] 事実テーブル先抽出ステップは以下の最低 3 source を「読み込み対象」として明示する: (a) `decisions.md` / (b) `construction/units/*-review-summary.md` / (c) `history/*.md`
- [ ] `steps/common/review-flow.md` の「指摘対応判断フロー」または末尾に「推定値検出ガード」が追加される
- [ ] 推定値検出ガードは Intent v2.5.3 §「推定値検出ガードの境界条件」に従い、以下の境界条件を持つ:
  - 検出マーカー: `約`, `およそ`, `approximately`, `approx.`, `推定`, `〜くらい`, `〜程度` 等
  - 数値隣接判定: 直前または直後 5 文字以内に算用数字または日本語数字
  - 根拠リンク併記時の例外: 同一段落内に PR/Commit/Issue リンクまたはファイルパス参照あり
- [ ] **review-flow ドライランの定量条件**（`steps/common/review-flow.md` に追加するガード仕様に対する fixture / マニュアル検証）:
  - 入力媒体: 振り返り Issue 本文ドラフト（markdown 1 段落単位の文字列）
  - 投入手順: AI レビューワー（Codex / セルフ）にガード仕様を提示し、入力ドラフトを review 対象として渡す
  - 判定出力期待（**主判定**）: ガードが反応した場合、AI レビューワーの応答に「指摘 #N - 推定値混入: `<該当箇所>`」の形式の文言が **必ず 1 件以上** 含まれる（pass / fail の一意な判定基準）。review-summary への記録は副次的な観察項目（Construction Phase で実装方針として確定）
  - 入力例 A「DR-001〜DR-035 の **35 件**（推定）」 → flag 期待
  - 入力例 B-flag「DR-001〜DR-010（**約 10 件**）」 → flag 期待
  - 入力例 B-allow「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」 → flag されない期待
- [ ] `review-flow.md` 内に許容例・非許容例が **2 件以上** 併記される（コードブロック内 / 表内のいずれでも可）

**技術的考慮事項**:

- 事実テーブル先抽出は AI 手順としての記述（実装スクリプトは作らない）。3 層検証 skill 化（jsonl 解析含む）は #652 として OUT_OF_SCOPE
- 推定値検出ガードも自然言語の判定ルール記述で十分（regex の機械実装は Construction Phase で確定）
- `review-flow.md` 247 行への追記。500 行制限内に収める

---

### ストーリー 4: predecessor-issue.sh の retrospective-issue.sh 横依存を解消する（#643）

**優先順位**: Should-have

**As a** retrospective 系スクリプトを将来改修する AI-DLC Starter Kit メンテナ
**I want to** `predecessor-issue.sh` が `retrospective-issue.sh` を直接 source して内部関数を借用する構造を解消し、責務別 helper（path/validation/gh/spool-parse）に分離してほしい
**So that** retrospective 側の内部実装変更が predecessor 側に波及する障害伝播リスクを減らし、用途別 helper として独立してテスト・改修できる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/lib/aidlc-validate.sh`（cycle バリデーション 等）/ `aidlc-gh.sh`（gh 状態確認 等）/ `aidlc-spool.sh`（spool パース 等）の 3 ファイルが新規追加される
- [ ] `__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` の関数定義が `retrospective-issue.sh` から削除され、新 helper にそれぞれ移管される（`grep -E "^(__retro_validate_cycle|__retro_gh_status|_spool_extract_entries)" skills/aidlc/scripts/lib/retrospective-issue.sh` が 0 件）
- [ ] `predecessor-issue.sh` が `retrospective-issue.sh` を **直接 source しない**（`grep -E "source.*retrospective-issue\.sh" skills/aidlc/scripts/lib/predecessor-issue.sh` が 0 件 / 代わりに 3 つの新 helper を直接 source）
- [ ] 新 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）が他の retrospective 系 helper を `source` または `.` (dot source) で読み込まないこと（Markdown テーブル外で示した `grep -EHn "^(source|\.)..."` で 0 件）
- [ ] `predecessor_resolve_issue` / `retrospective_collect_candidates` / `retrospective_issue_create` 等の既存公開関数の **CLI 引数列・引数名・必須／任意フラグ** が破壊変更されていない
- [ ] **exit code 互換性**: 既存ケース（success / not-found / gh-unavailable）の exit code が一致
- [ ] **stderr 文言互換性**: 既存テストケースで stderr 文言の主要行（`predecessor_candidates_emitted` / `info` / `warn` プレフィックス等）が一致
- [ ] **回帰テスト**: v2.5.2 サイクルでの `predecessor_resolve_issue v2.5.2` 呼び出しを再生し、同等の NDJSON 出力（`resolution_path` / `issue_url` / `candidates`）が得られる
- [ ] 多重 source ガード（`__AIDLC_<NAME>_SH_LOADED=1`）が新 helper 群で踏襲されている

**技術的考慮事項**:

- 既存呼び出し元（`01-setup.md` §4a の AI エージェントロジック）は変更しない（API 非破壊）
- 新 helper は既存の `aidlc-paths.sh`（v2.5.2 Unit 003 で新設済）と同じ命名規約に従う
- 関数の物理配置のみが変わり、関数名・引数・戻り値・stderr メッセージは同一

---

## ストーリー間の依存関係

依存関係を「論理依存」と「実装順依存（同一ファイル改訂によるコンフリクト回避）」の 2 軸で整理する：

| ストーリー | 論理依存（前提条件） | 実装順依存（同一ファイル / Skill 改訂） |
|----------|---------------------|-------------------------------------|
| ストーリー 1 (#647) | なし | ストーリー 3 とは同一ファイル `steps/operations/04-completion.md` §1 を改訂するため、**ストーリー 1 → ストーリー 3 の順** が安全 |
| ストーリー 2A (#637 / short note) | なし | ストーリー 2B とは同一スクリプト `write-history.sh` / 同一 SKILL.md を改訂するため、**ストーリー 2A → 2B の順、または 1 Unit に統合** が安全 |
| ストーリー 2B (#637 / operations-round) | なし | ストーリー 2A と同上 |
| ストーリー 3 (#634 / 絞込) | なし | ストーリー 1 と同上（**ストーリー 1 後に着手**） |
| ストーリー 4 (#643) | なし | なし（独立した helper 分離） |

**並列実装可能性**:

- ストーリー 4 は完全独立で並行実装可能（独立した helper ファイル群を新設し、`predecessor-issue.sh` の source 変更のみ）
- ストーリー 1 ↔ ストーリー 3 は同一ファイル `04-completion.md` §1 を改訂するため、Construction Phase でブランチ分離せずに逐次実装する
- ストーリー 2A ↔ 2B は同一スクリプト改修のため、1 Unit にまとめて実装すると効率的（Unit 002 で統合）

**論理依存（成果物としての前提）**: 5 ストーリー（1 / 2A / 2B / 3 / 4）はそれぞれ独立した価値を提供するため、論理的には他ストーリーの完了を待つ必要はない。

