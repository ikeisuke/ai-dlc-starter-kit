# Inception Phase - ストーリー・Unit定義

## ステップ3: ユーザーストーリー作成

**タスク管理機能を活用してください。**

- Intentに基づいてユーザーストーリーを作成

**受け入れ基準の書き方【重要】**:

受け入れ基準は「何が実現されていれば完了とみなせるか」を具体的に記述する。

**良い例**（具体的で検証可能）:

- 「ログインボタンをクリックすると、ダッシュボード画面に遷移する」
- 「エラー時に赤色の警告メッセージが3秒間表示される」
- 「検索結果が100件を超える場合、ページネーションが表示される」

**悪い例**（曖昧で検証困難）:

- 「ユーザーが使いやすいこと」
- 「パフォーマンスが良いこと」
- 「適切に処理されること」

**記述のポイント**:

- 主語・動詞・結果を明確にする
- 数値や状態を具体的に記述する
- テスト可能な形で書く

**受け入れ基準のチェック観点【必須】**:

ユーザーストーリー作成時に、以下の観点で受け入れ基準をチェックする：

| チェック項目 | 確認内容 |
|-------------|---------|
| 具体性 | 数値、状態、動作が具体的に記述されているか |
| 検証可能性 | テストで確認できる形式になっているか |
| 完全性 | 正常系・異常系の両方が網羅されているか |
| 独立性 | 他の条件と重複や矛盾がないか |

- `.aidlc/cycles/{{CYCLE}}/story-artifacts/user_stories.md` を作成（テンプレート: `templates/user_stories_template.md`）

**Depth Level分岐**（`common/rules-reference.md` の「レベル別成果物要件」を参照）:
- `minimal`: 受け入れ基準を主要ケースのみに簡略化（主要エラーケースは維持）
- `comprehensive`: 完全な受け入れ基準に加え、エッジケースを網羅
- `standard`: 変更なし（現行動作）

**AI レビュー**: ユーザーストーリー承認前に `steps/common/review-flow.md` に従って実施（ルーティング判定の詳細は `steps/common/review-routing.md` 参照）。`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行。

**Inception固有のレビュー観点**:
- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か

**セミオートゲート判定**: `steps/inception/index.md` の「2.4 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。

### ステップ4: Unit定義【重要】

**タスク管理機能を活用してください。**

- ユーザーストーリーを独立した価値提供ブロック（Unit）に分解
- **各Unitの依存関係を明確に記載**（どのUnitが先に完了している必要があるか）
- 依存関係がない場合は「なし」と明記
- 依存関係は Construction Phase での実行順判断に使用される
- 各Unitは `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/{NNN}-{unit-name}.md` に作成（テンプレート: `templates/unit_definition_template.md`）

**Depth Level分岐**（`common/rules-reference.md` の「レベル別成果物要件」を参照）:
- `minimal`: 最小限の責務・境界記述。依存関係と優先度のみ記載
- `comprehensive`: 完全な記述に加え、技術的リスク評価セクションを追加
- `standard`: 変更なし（現行動作）

**Unit定義ファイルの命名規則**:
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- NNN: 3桁の0埋め番号（001, 002, ..., 999）
- unit-name: Unit名のケバブケース
- 番号は依存関係に基づく実行順序を表す
- 連番の重複は禁止
- 依存関係がないUnitは任意の順番でよいが、優先度順に番号付けを推奨
- **実装状態セクション**: 各Unit定義ファイルの末尾に以下のセクションを含める（テンプレートに含まれている）
  ```markdown
  ---
  ## 実装状態

  - **状態**: 未着手
  - **開始日**: -
  - **完了日**: -
  - **担当**: -
  - **エクスプレス適格性**: -
  - **適格性理由**: -
  ```

**AI レビュー**: Unit 定義承認前に `steps/common/review-flow.md` に従って実施（ルーティング判定の詳細は `steps/common/review-routing.md` 参照）。`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行。

**Inception固有のレビュー観点**:
- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか

**セミオートゲート判定**: `steps/inception/index.md` の「2.4 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。

### ステップ4a: 直近サイクル完了 Unit との重複チェック

**目的**: 新規起案された Unit のスラグおよび関連 CLOSED Issue 番号が直近 N サイクルの完了 Unit と重複していないかを承認前に検出し、再発防止のためユーザー判断（取り下げ / 継続）を仰ぐ。v2.6.4 Unit 001（v2.6.3 Unit 004 と完全重複で取り下げ）の再発を構造的に予防する SoT 手順（v2.6.5 / Unit 001 / #712 で導入）。

**実行タイミング**: ステップ 4（Unit 定義）完了直後・ステップ 4b（エクスプレスモード判定）開始前。Unit 定義承認前 AI レビューの **前** に実行する。

**スキップ条件**: サブステップ (0) の `normalized_lookback_cycles == 0`（明示的 opt-out）。

#### サブステップ (0): config 解決（責務: config 解決層）

直近サイクル数を `read-config.sh` で取得し、不正値を正規化する。**本サブステップは独立節**として扱い、出力契約 `normalized_lookback_cycles: non-negative int` を保証する。以降のサブステップは正規化済み値のみを受け取り、再正規化しない。

```bash
bash scripts/read-config.sh rules.inception.dedup_lookback_cycles
```

正規化規則:

| 取得結果 | `normalized_lookback_cycles` |
|---------|------------------------------|
| exit 0 + 非負整数 | 取得値そのまま |
| exit 1（キー不在） | defaults.toml 既定値 `3` |
| exit 0 + 非整数 / 負数 / 文字列 | stderr に `warn: invalid rules.inception.dedup_lookback_cycles=<value>, fallback to 3` を出力 + `3` を採用（fail-safe） |

#### サブステップ (1): 早期 opt-out

`normalized_lookback_cycles == 0` の場合、以下の 1 行をログ表示するのみで本ステップを完了し、ステップ 4b へ進む。

```text
dedup: skipped (lookback=0)
```

#### サブステップ (2)〜(3): 完了スラグ一覧取得（責務: 検出層）

直近 `normalized_lookback_cycles` サイクル分の `.aidlc/cycles/v*/story-artifacts/units/*.md` を走査し、ファイル名から slug を抽出する。**「実装状態 → 状態」が `完了` のもののみ**を対象とする（`取り下げ` / `進行中` / `未着手` は除外）。

新規候補 Unit（現在のサイクルの `story-artifacts/units/*.md`）の slug 集合と完了スラグ集合を**完全一致**で突合する（部分一致 / 正規化は本サイクルでは行わない / false positive 低減）。

#### サブステップ (4): 関連 Issue 抽出 + 状態確認

スラグ一致した完了 Unit について、以下を実施する:

1. (4-b) 関連 Issue 抽出: 完了 Unit 定義ファイルの「## 関連Issue」セクション直下の `#NNN` 形式の番号を `grep -E '^\s*-\s*#[0-9]+'` 等で抽出
2. (4-c) Issue 状態確認: `gh_status=available` の場合のみ `gh issue view <N> --json state -q .state` を実行。結果は `OPEN` / `CLOSED` / エラー時 `UNKNOWN`

**gh 不可用時のフォールバック**: `gh_status != available` の場合、(4-c) 全体を skip し、`UNKNOWN` 扱いで継続する（ステップ自体は中断しない）。警告として `warn: gh unavailable, dedup check uses slug-only match` を 1 行表示する。

#### サブステップ (5): 重複候補リスト構築

新規候補 1 件につき、突合結果を以下のいずれかとして分類する:

- `slug_and_closed_issue`（強）: スラグ一致 + 関連 Issue が CLOSED
- `slug_only`（弱）: スラグ一致のみ（Issue OPEN / `UNKNOWN` / 関連 Issue なし）
- 重複候補なし: ステップ 4b へ進む

#### サブステップ (6): AskUserQuestion による判断取得（責務: 対話層）

重複候補ありの場合、`AskUserQuestion` を使用してユーザー判断を取得する（**ゲート承認ではなくユーザー選択** / `automation_mode` に関わらず `AskUserQuestion` 必須 / SKILL.md「AskUserQuestion 使用ルール」のユーザー選択種別）。

質問形式（固定）:

- `header`: `重複警告`
- `question`: `新規 Unit <slug> は直近 <normalized_lookback_cycles> サイクル内の以下の完了 Unit と一致します。続行しますか？\n- <cycle>/<slug> (Issue #<NNN> <state>)\n...`

選択肢（`choice_id` 固定）:

| choice_id | label | reason | 正規アクション |
|-----------|-------|--------|---------------|
| `withdraw` | 取り下げ（推奨） | 不要 | 当該新規 Unit 定義ファイルの「実装状態 → 状態」を `取り下げ` に変更（物理削除しない / 履歴トレース保持） + history 追記 |
| `continue_with_reason` | 継続（理由必須） | 必須 | 当該新規 Unit 定義ファイル末尾に dedup-warning コメントブロック追記 + history 追記 |

`continue_with_reason` の `reason` バリデーション: 空文字不可、`review-flow.md` の禁止パターン規約を準用（「パッチだから」「小さい変更だから」「時間がないから」等の理由のみは拒否）。

#### サブステップ (7): 判断後アクション（責務: 記録層）

- **`withdraw` 選択時**:
  1. 当該新規 Unit 定義ファイルの「実装状態 → 状態」を `取り下げ` に書き換える
  2. `bash scripts/write-history.sh --cycle {{CYCLE}} --phase inception --step "Unit 定義" --content-file <tmp>` で「重複検出による取り下げ」イベントを追記（content に新規 slug / 重複先 slug / Issue 番号を含む）
- **`continue_with_reason` 選択時**:
  1. 当該新規 Unit 定義ファイル末尾に以下の HTML コメントブロックを追記する（1 行 1 ブロック、改行禁止、フィールド順固定、`key="value"` 引用符必須、`value` 内 `"` は `\"` エスケープ）:

     ```html
     <!-- dedup-warning: source=".aidlc/cycles/<duplicate_cycle>/story-artifacts/units/<NNN>-<slug>.md" related_issue="#<NNN>" reason="<user reason>" detected_at="<YYYY-MM-DD>" -->
     ```

     受理正規表現:

     ```text
     <!-- dedup-warning: source="(?:[^"\\]|\\["\\])+" related_issue="(?:#[0-9]+|none)" reason="(?:[^"\\]|\\["\\])+" detected_at="[0-9]{4}-[0-9]{2}-[0-9]{2}" -->
     ```

     許可エスケープシーケンスは `\"` と `\\` のみ（その他 `\X` 表現は不正値として拒否）。`value` 内に改行文字 (`\n` / `\r`) は含めない（含む場合は半角スペース 1 個に正規化）。

  2. `bash scripts/write-history.sh ... --step "Unit 定義" --content-file <tmp>` で「重複検出後の継続判断」イベントを追記

完了後、既存のステップ 4 末尾 AI レビューフロー（reviewing-inception-units）に合流する。

#### 実装メモ

- 本ステップは `automation_mode=semi_auto` でもユーザー選択 (`AskUserQuestion`) として常時実行される（SKILL.md「AskUserQuestion 使用ルール」のユーザー選択種別に該当）
- Bash ツール経由で `gh issue view` / `read-config.sh` を実行する際は、コマンド置換 `$(...)` / backtick を引数文字列に含めない（本リポジトリ規約 / Issue #697）

### ステップ4b: エクスプレスモード判定

**スキップ条件**: `express_enabled` が `false` の場合、このステップをスキップする。

`express_enabled=true` の場合、`common/rules-automation.md` の「エクスプレスモード仕様」セクションに従い判定を実施する。

**判定手順**:

1. Unit定義ファイルの数をカウントする:

```bash
ls .aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md 2>/dev/null | wc -l
```

2. Unit数が0の場合: フォールバック。`common/rules-automation.md` の「エクスプレスモード仕様」セクションのフォールバック通知メッセージ（Unit数0用）を表示し、通常フローを継続（ステップ5へ進む）

3. Unit数が1以上の場合: 各 Unit に対して複雑度判定を実施する。`common/rules-automation.md` の「複雑度判定」に従い、Unit 定義ファイルの内容に基づいて4項目（受け入れ基準の明確さ、依存関係の複雑さ、技術的リスク、変更影響範囲）を評価する。

4. 判定結果に応じた分岐:

- **全 Unit が eligible**: エクスプレスモード有効。各 Unit 定義ファイルの「実装状態」セクションに `エクスプレス適格性: eligible` を記録する。以下のメッセージを表示:

  ```text
  【エクスプレスモード有効】全Unit（N件）が複雑度条件を満たしたため、Inception→Construction統合フローを適用します。
  ```

  → `depth_level=minimal` の場合: ステップ5（PRFAQ）をスキップし、「エクスプレスモード完了処理」セクションへ進む
  → `depth_level=standard/comprehensive` の場合: ステップ5（PRFAQ）へ進み、PRFAQ作成完了後に「エクスプレスモード完了処理」セクションへ進む

- **1つでも ineligible**: フォールバック。`common/rules-automation.md` の「エクスプレスモード仕様」セクションのフォールバック通知メッセージ（複雑度不適格用）を表示し、通常フローを継続（ステップ5へ進む）。該当 Unit 定義ファイルに `エクスプレス適格性: ineligible` と理由を記録する。

**フォールバック時の履歴記録**:

フォールバック発生時、以下を履歴に記録する:

`/write-history` スキルで記録（`--step "エクスプレスモード判定"` `--content "エクスプレスモードフォールバック: [理由]"`）。

### ステップ5: PRFAQ作成

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules-reference.md` の「レベル別成果物要件」を参照）:
- `minimal`: このステップをスキップ可能（progress.mdで「スキップ」に更新し、完了時の必須作業へ）
- `comprehensive` / `standard`: 通常通り実行

- プレスリリース形式でプロジェクトを説明
- `.aidlc/cycles/{{CYCLE}}/requirements/prfaq.md` を作成（テンプレート: `templates/prfaq_template.md`）

---
