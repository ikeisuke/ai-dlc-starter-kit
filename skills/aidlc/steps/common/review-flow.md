# AI レビューフロー

> ルーティング判定は `review-routing.md` 参照。本ファイルは `ReviewRoutingDecision` 受領後の実行手順のみを扱う。

ユーザー承認前に AI レビューを実行する。`review-routing.md` で `ReviewRoutingDecision` を導出後に以下を実行。`disabled` はパス 3 へ直行。

## 実行手順

**パス 1（外部 CLI）**: (1) レビュー前コミット → (2) 機密情報除外スキャン（`review-routing.md §2` の除外パターンで照合、`/`なし→ベース名、`/`あり→相対パス、ケースインセンシティブ。全除外 → パス 3、除外ファイルはパスのみ通知）→ (3) 反復レビュー（最大 5 回）: スキル呼び出し → 指摘あれば修正 → 再レビュー。**完了条件は単一仕様**で判定し、5 回後も残（`unresolved_count > 0`）で指摘対応判断フロー。

**Codex セッション管理**: 初回後 session id を記録、2 回目以降 `codex exec resume <session-id>`。**エラー時**は `review-routing.md §6` の `fallback_policy` に従う（`cli_runtime_error` / `cli_output_parse_error` への対応ポリシー、`skip_reason_required=true` は下記バリデーション適用）。

**パス 2（セルフ）**: 呼び出し形式は `review-routing.md §7`。反復上限・完了条件はパス 1 と同一（5R 上限 / 単一仕様による完了判定）。**パス 1 → パス 2 の遷移**は `review-routing.md §4` の ToolSelection 順序（`["codex", "self"]` 相当のリスト走査）の自然な延長として読める。`tools = ["codex"]` 設定の場合、暗黙シムにより末尾 self が補完されるため、外部 CLI 失敗時のセルフ降下は `fallback_to_self` ポリシーと等価に動作する（`recommend` モード）。

**パス 3（ユーザー）**: レビュー前コミット → 成果物提示 → 承認要求。修正依頼 → 反映 → レビュー後コミット → 再提示。

### 完了条件の判定単一仕様

各 round 終了後に以下の規則で `ReviewSession.is_completed()` を評価する:

- `rounds.size == 1 && rounds[0].is_clean()` → `completed`（**1R clean 特例**: Round 1 で指摘ゼロまたは defer 化されたら 1 round で完了）
- `rounds.size >= 2 && last_two_rounds_clean` → `completed`（最後 2 round 連続で指摘ゼロまたは defer 化）
- `rounds.size >= 5 && unresolved_count > 0` → `decision_required`（指摘対応判断フローへ遷移）
- 上記いずれにも該当しない → `in_progress`（次 round へ進む）

`is_clean()` は ReviewRound の `findings` が空または全件 defer 化（OUT_OF_SCOPE / TECHNICAL_BLOCKER 判定済み）されているかで判定する。`last_two_rounds_clean` は末尾 2 round がいずれも `is_clean()` で真。

**スキップ理由バリデーション**（`skip_reason_required=true` 時）: 空文字不可、禁止パターン（「パッチだから」「小さい変更だから」「時間がないから」等）のみは拒否、履歴に記録。

## 指摘対応判断フロー

反復レビュー 5 回後に残指摘（`unresolved_count > 0`）がある場合に実行（`decision_required` 遷移時）。

**千日手検出**: 過去 5 回中で「同種の指摘」（同一種別・同一パス・同一本質）が 3 回連続出現 → ユーザー判断（早期検出）。

**各指摘への判断**:

| 選択肢 | 動作 |
|--------|------|
| 修正する（推奨） | 修正後、反復レビューに戻る |
| TECHNICAL_BLOCKER | 技術的理由を記録（具体的な根拠必須）→ defer 自動 Issue 起票へ |
| OUT_OF_SCOPE | 次サイクルで対応 → defer 自動 Issue 起票へ |

**理由バリデーション**: 上記「スキップ理由バリデーション」と同じ（空文字不可、禁止パターン拒否）。

**スコープ保護確認**（OUT_OF_SCOPE 時のみ）: `rules-core.md` の「スコープ保護ルール」に基づき、指摘対象が `.aidlc/cycles/{{CYCLE}}/requirements/intent.md` の「含まれるもの」に該当するかを判定。**本確認は AI とユーザーの意思決定責務境界として常時維持される**（`automation_mode` / 5R 化に関わらず削除対象外）。

- 該当 → `automation_mode` に関わらずユーザー確認（対象要件・指摘内容を提示して「スコープから除外してよろしいですか？」）。「はい」→ 履歴に `スコープ保護確認` 記録 → defer 自動 Issue 起票へ / 「いいえ」→ 「修正する」に戻る
- 非該当 → defer 自動 Issue 起票へ
- 判定不能（「含まれるもの」不在・曖昧）→ ユーザー確認にフォールバック（安全側）

**判断完了後**: RESOLVE 選択あり → 反復レビューへ戻る / 全て defer（先送り） → レビュー完了処理（`review_detected=true` でセミオートゲートが `fallback(review_issues)`）。

## defer 判定時の自動 Issue 起票フロー

`disposition` が `out_of_scope` または `technical_blocker` に確定した ReviewFinding は、AI agent が即時 Issue を起票する（**起票保留禁止**）。「ユーザー判断に委ねる」「Issue 化保留」等の defer 起票の裁量は撤廃される（ユーザーが不要と判断した Issue は事後 close する逆順序とする）。

### 機密情報マスク

**マスク適用範囲**: Issue タイトル・本文に限らず、本フローで生成・更新されるすべての記録物（review-summary、`history/*.md`、warn 出力、`PENDING_MANUAL` 失敗ログ、コミットメッセージを含む）に同一マスクポリシーを適用する。

マスク対象:

- 秘密鍵（PEM 形式 / SSH 鍵）、API トークン、パスワード、Bearer トークン
- 接続文字列内の認証情報（例: `postgresql://user:pass@host/db` → `postgresql://****@host/db`）
- 内部のみで通用する機密パス（公開リポジトリでは伏せるべき URL / IP / ファイルパス）
- focus=security で詳細化が漏えいリスクとなる再現手順・影響範囲

機密情報を含む可能性がある場合は、記録前に AI agent がマスク処理を行う（例: `sk-****`、`Bearer ****`）。

**focus=security の特例**:

- 公開 Issue / review-summary / history / warn 出力には脆弱性種類の要約のみ記録し、再現手順・影響範囲・具体的なペイロードは記載しない（`SECURITY_PRIVATE` 扱いの場合は非公開管理側で詳細を保持する）
- defer 起票失敗時（`PENDING_MANUAL`）の理由ログにも本特例を適用し、要約のみ記録する

### 起票手順

1. **起票実行**:

   ```bash
   gh issue create \
     --title "[Backlog] {要約}" \
     --label "backlog" \
     --label "type:defer-from-review" \
     --body-file "<一時ファイル>"
   ```

   - **必須ラベル**: `backlog`, `type:defer-from-review`
   - **任意ラベル**: 該当 Unit 番号（`unit:NNN`）、優先度（`priority:medium` 等）
   - 必須ラベルが付与されていない Issue は本フロー由来として扱わない（運用上の識別キー）
   - **`focus: security` 例外**: 公開 Issue への詳細記載禁止。`SECURITY_PRIVATE`（非公開管理）またはマスク済み Issue（本文は `## 概要`（脆弱性種類のみ、再現手順・影響範囲は禁止）+ `## 検出元`（サイクル・Unit・種別）のみ）

2. **起票後ラベル検証（必須）**:

   ```bash
   gh issue view <N> --json labels --jq '[.labels[].name]'
   ```

   実際に付与されたラベル集合を取得し、必須ラベル `backlog` と `type:defer-from-review` の両方が含まれることを検証する。両方含まれる場合のみ起票成功扱い。いずれかが欠落している場合（ラベル未存在で `gh issue create --label` が無視された場合を含む）は `PENDING_MANUAL` 扱い（warn 継続 + review-summary に `PENDING_MANUAL` を記録）に統一する。

3. **記録**:

   - 起票成功（必須ラベル両方付与確認後）→ review-summary 「バックログ」列に Issue 番号 `#NNN` を記録
   - `focus: security` の `SECURITY_PRIVATE` → review-summary 「バックログ」列に `SECURITY_PRIVATE` を記録
   - 起票失敗（`gh issue create` 失敗 / `gh_status != available` / 権限不足 / ネットワーク断 / API エラー / ラベル検証失敗）→ warn 表示 + review-summary 「バックログ」列に `PENDING_MANUAL` を記録、review 自体は中断しない
   - Issue 番号取得は `gh issue create` の stdout から `https://github.com/.../issues/<N>` を正規表現でパースする想定

## Round 4 以降の新領域指摘の自動 backlog 化フロー

Round 4 以降に発生した「新領域の指摘」は、千日手の予兆として AI agent が即時 backlog Issue を起票する。同 round 内で対応せず、次サイクルへ defer する（既存領域の指摘は通常通り対応する）。

### 新領域の判定ルール

- **一次判定（正準）**: Round 1〜3 の指摘パスを下記「境界条件」で正規化した領域キー集合 `K_old` と、Round 4 以降の指摘パスを正規化した領域キー集合 `K_new` の差分 `K_new - K_old` に該当する指摘を「新領域指摘」とする
- **二次判定（補助根拠）**: 一次判定で「新領域指摘」と判定された各指摘について、根拠として原パス（Round 4+ で指摘された具体的ファイルパス）と Round 1-3 で同じ領域キーが指摘されていなかったことの確認ログを review-summary に記録する

### 判定手順（再現可能、固定）

0. **`内容` 列のパス記法（規約）**: review-summary の「内容」列に記載するパスは、必ず repo-relative の path を backtick で囲む（例: `` `skills/aidlc/scripts/lib/aidlc-paths.sh` ``）。複数パスを 1 件の指摘で記載する場合は、各パスを backtick で囲み `, ` で区切る（例: `` `a.sh`, `b.sh` ``）。コードブロック内のパスは抽出対象外。絶対パスは記載しない（規約違反、起票時に reject 対象）。
1. Round 1〜3 の review-summary 各行から指摘対象パスを抽出（`内容` 列に backtick で囲まれた repo-relative path を正規表現 `` `([^`]+)` `` でマッチさせ、区切りは `, ` を期待。マッチしない場合は warn 表示 + 当該指摘を除外）。
2. 同じく Round 4 以降の review-summary 各行から指摘対象パスを抽出（手順 0 の規約と手順 1 の正規表現を適用、抽出不能時は warn + 除外）。
3. 各パスを下記「境界条件」テーブルで領域キーに正規化。
4. 重複除去 + 文字列昇順ソート → `K_old`（Round 1-3） / `K_new`（Round 4+） を確定。
5. 差分 `K_new - K_old` を計算 → 「新領域キー集合」を確定。
6. review-summary 末尾の追加セクション `## Round 4 新領域判定` に `K_old`, `K_new`, `K_new - K_old` を JSON 配列形式（例: `"K_old": ["scripts/lib", "steps/common"]`）で記録。
7. 各 Round 4+ 指摘について、その指摘パスを領域キーに正規化した結果が「新領域キー集合」に含まれる場合、当該指摘を「新領域指摘」と判定（true/false 二値）。

判定は AI agent が手順 1〜7 を機械的に実施し、`K_old` / `K_new` / `K_new - K_old` と該当指摘のパス集合を review-summary に記録する。

### 新領域判定の境界条件（完全列挙＋フォールバック）

パス比較は文字列完全一致ではなく、以下のキー集合に正規化した値同士で同一性を判定する。

**完全列挙する領域キー**:

| 元パス（glob） | 領域キー |
|---------------|---------|
| `skills/aidlc/scripts/lib/*` | `scripts/lib` |
| `skills/aidlc/scripts/*`（lib 以下を除く） | `scripts` |
| `skills/aidlc/steps/common/*` | `steps/common` |
| `skills/aidlc/steps/inception/*` | `steps/inception` |
| `skills/aidlc/steps/construction/*` | `steps/construction` |
| `skills/aidlc/steps/operations/*` | `steps/operations` |
| `skills/aidlc/templates/*` | `templates` |
| `skills/aidlc/config/*` | `config` |
| `skills/aidlc/agents/*` | `agents` |
| `skills/aidlc/guides/*` / `skills/aidlc/references/*` | `docs/skill` |
| `skills/reviewing-*/**` | `skills/reviewing` |
| `bin/*`（tests を除く） | `bin` |
| `bin/tests/**` | `bin/tests` |
| `tests/**` | `tests` |
| `.github/workflows/*` | `ci` |
| `docs/**` | `docs/repo` |
| `.aidlc/cycles/<cycle>/**` | `cycle-artifacts` |

**フォールバック規則**: 上記に該当しないパスは、リポジトリルートからの第一階層ディレクトリ名を領域キーとする（例: `Makefile` → `root`、`foo/bar.txt` → `foo`）。リポジトリルート直下のファイルは `root` キーに集約する。

### 起票手順（新領域指摘）

1. **起票実行**:

   ```bash
   gh issue create \
     --title "[Backlog] {要約} (Round 4+ 新領域)" \
     --label "backlog" \
     --label "type:new-area-from-round4plus" \
     --body-file "<一時ファイル>"
   ```

   - **必須ラベル**: `backlog`, `type:new-area-from-round4plus`
   - 機密情報マスクは「defer 判定時の自動 Issue 起票フロー」のマスクルールを準用

2. **起票後ラベル検証（必須、defer 起票と同等）**:

   ```bash
   gh issue view <N> --json labels --jq '[.labels[].name]'
   ```

   必須ラベル `backlog` と `type:new-area-from-round4plus` の両方が含まれることを検証する。両方含まれる場合のみ起票成功扱い、いずれかが欠落している場合は `PENDING_MANUAL` 扱い（warn 継続 + review-summary 記録）。

3. **記録**:

   - 同 round 内で対応しない（次サイクルへ defer）
   - 既存領域の指摘は通常通り対応（同 round 内で修正 / 5R 完了条件評価へ）
   - review-summary 末尾 `## Round 4 新領域判定` セクションに `K_old` / `K_new` / `K_diff` を JSON 配列で記録

### 計画承認前レビューでの扱い（特例）

計画承認前のレビューはレビューサマリ非生成（後述）のため、Round 4 に到達した場合の `K_old` / `K_new` / `K_diff` は `history/construction_unit{NN}.md` または `inception/{成果物名}-history.md` に手動で記録する運用とする。本サイクルでは計画承認前のサマリ非生成ルールを破らない。

## レビュー完了時の共通処理

パス 1/2 完了時: (1) シグナル生成（`review_detected`, `deferred_count`, `resolved_count`, `unresolved_count`、承認ポイント内有効）/ (2) レビュー後コミット【**v2.5.1 Unit 005 / #616 で三段階明示**: (2a) 修正コミット（コードベース変更を反映）→ (2b) 履歴記録（`/write-history` で `history/*.md` に AIレビュー完了等を追記）→ (2c) 履歴コミット（`history/*.md` のみ / `chore: [{{CYCLE}}] レビュー履歴追記` 等）/ (2c) 未実施のままマージ実行に進むと `operations-release.sh merge-pr` の pre-flight check が `pre-merge-uncommitted-detected` で exit 1 で停止する】/ (3) **レビューサマリ更新**【必須、計画承認前除く、未作成のまま次へ進まない】/ (4) セミオートゲート判定（`unresolved_count == 0` かつフォールバック非該当 → `auto_approved`）。

## レビューサマリファイル

計画承認前以外のレビュー完了時に生成・追記。テンプレート: `templates/review_summary_template.md`、既存時は `---` 後に追記。パス: Construction → `construction/units/{NNN}-review-summary.md`、Inception → `inception/{成果物名}-review-summary.md`。

**バックログ列の有効値**:

- `#NNN`: Issue 作成済み（`out_of_scope` / `technical_blocker` の自動起票成功時）
- `PENDING_MANUAL`: gh CLI 失敗・ラベル検証失敗等で手動登録待ち
- `SECURITY_PRIVATE`: focus=security の defer 指摘の非公開対応
- `-`: 修正済み（`disposition=resolved`）のみ許可。**`out_of_scope` / `technical_blocker` 時の `-` は原則禁止**（自動起票が必須のため）

`out_of_scope` / `technical_blocker` 時は `#NNN` / `PENDING_MANUAL` / `SECURITY_PRIVATE` のいずれかが必須。

**反復回数の表記**: `**反復回数**: [1〜5]`（5R 上限）。1R clean 特例で 1 round 完了の場合は `1`、最大の場合は `5`。

### 列の記述ガイダンス

レビューサマリの「指摘一覧」テーブル各列の記述ルール:

| 列 | 記述ルール |
|----|----------|
| `#` | 1 から始まる連番。Set 内で一意 |
| `重要度` | `高` / `中` / `低` のいずれか |
| `内容` | `[対象パス] - [問題事象]` の形式。パスは repo-relative の path を backtick で囲む（例: `` `skills/aidlc/...` ``）。複数パスは backtick で囲み `, ` で区切る。絶対パス禁止。コードブロック内のパスは新領域判定の抽出対象外。機密情報マスクを適用 |
| `対応` | `修正済み（{ファイル名}:{行番号}: {何を変更したか}）` / `TECHNICAL_BLOCKER（理由: {具体的な技術的根拠}）` / `OUT_OF_SCOPE（理由: {次サイクル候補となる根拠}）` のいずれか |
| `バックログ` | 「バックログ列の有効値」セクション参照（`#NNN` / `PENDING_MANUAL` / `SECURITY_PRIVATE` / `-`） |

**禁止事項**:

- 「修正済み」だけの記載（修正内容の要約と該当箇所が必須）
- `OUT_OF_SCOPE` で `-` のみ記載（自動起票必須のため `#NNN` / `PENDING_MANUAL` / `SECURITY_PRIVATE` のいずれかが必須）
- 絶対パス記載（新領域判定の抽出対象外となるため `repo-relative` で記載）

新領域判定の抽出規則・領域キー正規化は本ファイル「Round 4 以降の新領域指摘の自動 backlog 化フロー」セクションを参照。

## 履歴記録

`/write-history` で記録する主要イベント: `AIレビュー完了` / `フォールバック`（機密情報マスク済み）/ `千日手判断` / `AIレビュー指摘対応判断` / `バックログ自動登録`（defer 自動 Issue 起票 + Round 4+ 新領域 backlog 化を含む）/ `AIレビュースキップ`。

## AI レビュー指摘の却下禁止【絶対遵守】

AI レビュワーの指摘をメインエージェントが自己判断で却下してはならない。必ず (1) 修正して再レビュー、または (2) 指摘対応判断フローでユーザー判断を仰ぐ。

## 外部入力検証

**AI レビュー応答**: サブエージェント（Agent ツール）に委譲して事実関係・技術的正確性・対象コード整合性を検証（メインエージェントは結果に介入しない）。出力: 応答要約 / 検証結果 / 相違点 / 結論。サブエージェント起動失敗時はメインエージェントが同フォーマットで検証（却下禁止ルール適用）。セルフレビューは同一エージェント内のため検証非適用（構造・妥当性のみ）。

**ユーザー入力**: 曖昧な入力は解釈を明示して確認。複数解釈可能な場合はすべて提示。

## 推定値検出ガード（Unit 003 / #634 / v2.5.3+）

振り返り作業時の推測値混入を予防するためのレビューガード。詳細仕様は Intent v2.5.3 §「推定値検出ガードの境界条件」および user_stories.md ストーリー 3 受け入れ基準を SoT として参照。

### 適用スコープ

本ガードは **振り返り文脈のみ** に適用する:

- retrospective Issue 本文（`retrospective` ラベル付き Issue）
- Operations Phase §1 振り返り作業時の KPT / 主因切り分け / Try / §1.5 Step 5-3 mirror 候補本文

それ以外のレビュー文脈（コードレビュー指摘内容 / Plan / Design / 統合レビューサマリ等）は **適用対象外**。レビューワーは適用スコープ判定を「対象が振り返り文脈か」で行う。

### 判定原則【重要・固定 / Intent v2.5.3 SoT 直接引用】

**一次情報を Read 済みでも、根拠リンクや出典参照が併記されていない近似語付き数値は flag する**。一次情報の有無は flag 判定に使わず、Intent 上で明示された「根拠リンク併記」のみが許容条件。

### 検出マーカー

- `約`, `およそ`, `approximately`, `approx.`, `推定`, `〜くらい`, `〜程度`

### 数値隣接判定

検出マーカーの**直前または直後 5 文字以内**に算用数字（`[0-9]`）または日本語数字（一〜十、百、千、万）が出現する場合のみ flag 候補。

### 例外条件（許容）

同一段落内に以下のいずれかが存在する場合は flag しない:

- PR/Commit/Issue リンク（`#NNN` / `https://github.com/...` / `<sha>` 等）
- 対象ファイルパス参照（`` `path/to/file.md` ``）

### flag 出力フォーマット

ガードが反応した場合、AI レビューワーの応答に **必ず 1 件以上** 以下の形式の文言を含める:

```text
指摘 #N - 推定値混入: `<該当箇所>`
```

### 許容例（flag されない）

- `[AXIS-1: 数値非隣接]` 「約束された動作」「推定エンジン」（マーカーはあるが数値非隣接 / 概念用法）
- `[AXIS-2: 根拠リンク併記]` 「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」（同一段落内にファイルパス参照あり）
- `[AXIS-3: スコープ外]` コードブロック内の数値（`approximately = 5` のような変数定義）

### 非許容例（flag される）

- `[AXIS-1: 数値隣接ヒット]` 「DR-001〜DR-035 の 35 件（推定）」（マーカー「推定」が数値「35 件」と隣接）
- `[AXIS-1 + AXIS-2: 数値隣接 + 根拠リンクなし]` 「約 50 round」「approximately 130 件」「推定 35 件」
- `[AXIS-2: 根拠リンクなし]` 「DR-001〜DR-010（**約 10 件**）」（数値隣接 + 段落内に根拠リンク・ファイルパス参照なし）

> **検証軸**: AXIS-1（数値隣接判定）/ AXIS-2（根拠リンク併記の有無）/ AXIS-3（適用スコープ）。各例は最低 1 軸を検証し、判定仕様とのトレーサビリティを確保する。

## 分割ファイル参照

- `review-routing.md`: ルーティング判定テーブル集（レビュー開始時の `ReviewRoutingDecision` 導出）
- `review-flow-reference.md`: 外部 CLI の既知制約と対処法（CLI 利用前・エラー発生時）
