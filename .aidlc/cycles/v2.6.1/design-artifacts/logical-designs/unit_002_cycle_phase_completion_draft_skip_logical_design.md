# Unit 002 論理設計: Cycle Phase Completion Check の draft PR skip

## 全体構成

本 Unit は以下 2 種類の成果物に分かれる:

1. **`.github/workflows/cycle-phase-completion-check.yml`** - `pull_request.types` への `converted_to_draft` 追加 + `if` 条件への `&& github.event.pull_request.draft == false` 追加 + 冒頭コメント根拠追記
2. **`docs/cycle-phase-completion-check-ruleset.md`** - draft skip 挙動と Ruleset required 互換確認手順の追記

## 1. workflow yaml の論理設計

### 1.1 `pull_request.types` の変更

```yaml
# 変更前
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    branches: [main]

# 変更後
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review, converted_to_draft]
    branches: [main]
```

### 1.2 `if` 条件の変更

```yaml
# 変更前
if: startsWith(github.head_ref, 'cycle/')

# 変更後
if: startsWith(github.head_ref, 'cycle/') && github.event.pull_request.draft == false
```

### 1.3 冒頭コメントへの根拠追記

```yaml
# 既存
# Unit 001 / Issue #672 / v2.5.6

# 追記
# Unit 002 / Issue #686 / v2.6.1: draft PR skip
```

### 1.4 評価セマンティクス

| event type | github.head_ref | github.event.pull_request.draft | 評価結果 | ジョブ動作 |
|-----------|-----------------|-------------------------------|---------|----------|
| `opened` | `cycle/v2.6.1` | true | false（第 1 項 true、第 2 項評価で false） | skip |
| `opened` | `cycle/v2.6.1` | false | true | execute |
| `synchronize` | `cycle/v2.6.1` | true | false（第 2 項評価で false） | skip |
| `synchronize` | `cycle/v2.6.1` | false | true | execute |
| `ready_for_review` | `cycle/v2.6.1` | false | true | execute |
| `converted_to_draft` | `cycle/v2.6.1` | true | false（第 2 項評価で false） | skip |
| 任意 | `chore/foo` | 任意 | false（第 1 項 false → AND 短絡 stop、第 2 項未評価） | skip |

## 2. ドキュメント追記の論理設計

### 2.1 `docs/cycle-phase-completion-check-ruleset.md` への追加セクション

文書末尾に以下のセクションを追加する:

```markdown
## Draft PR での skip 挙動（v2.6.1 Unit 002 / Issue #686）

`cycle/*` ブランチの draft PR では、`Cycle Phase Completion` ジョブが GitHub UI 上で
`Skipped` 表示になる。これは Construction Phase 中の中間 push で進捗未完了状態の
ジョブが fail することを防ぐための設計である。

### イベントごとの挙動

| GitHub Event | PR 状態 | ジョブ動作 | UI 表示 |
|------------|--------|----------|--------|
| `opened` (draft) | draft | skip | Skipped |
| `synchronize` (draft) | draft | skip | Skipped |
| `ready_for_review` | non-draft | execute | Running → Pass/Fail |
| `synchronize` (non-draft) | non-draft | execute | Running → Pass/Fail |
| `converted_to_draft` | draft | skip | Skipped |

### Repository Ruleset で required にしている場合の確認手順（推奨運用）

**デフォルト運用方針**: 当ジョブは Cycle Phase 完了状態を main マージ前にゲートする目的で導入されたため、**Required status check として維持** することを前提とする。`required から外す` 運用は本来の責務（未完了 phase の merge 防止）と逆方向であり、緊急時の例外運用として明確に格下げする。

#### パターン A（推奨・デフォルト運用）: Required 維持 + skipped を成功扱いに設定

GitHub Web UI:

1. Settings > Rules > Rulesets > 該当 Ruleset > Edit
2. 「Status checks that are required」セクションで `Cycle Phase Completion` を確認
3. **「Skipped status checks are treated as successful」相当の設定を有効化**（GitHub の最新 UI 文言に準拠）

API での確認:

```bash
gh api repos/{OWNER}/{REPO}/rulesets/{RULESET_ID} --jq '.rules[] | select(.type=="required_status_checks") | .parameters'
```

#### パターン B（緊急時の例外運用）: 一時的に required から外す

draft PR では skip、`ready_for_review` 後にのみ実行される性質上、**緊急時のみ** required から一時的に外す運用も許容する。ただし以下の条件を満たすこと:

- パターン A の設定変更に時間がかかり、リリースが阻害される一時的な状況に限る
- ジョブ実行結果は `gh pr checks` で **手動** 確認し、必ず通過していることを目視で確認
- 緊急対応完了後、速やかにパターン A に戻す（「Required 化」が AI-DLC スターターキットの設計目的）

**警告**: パターン B を恒常化すると Cycle Phase Completion の merge ガード効果が失われ、`v2.5.6 / Unit 001 / Issue #672` で導入した本機能の意義が大きく損なわれる。Required 維持を強く推奨する。

#### 想定表示

draft PR 状態の GitHub PR UI では以下のように表示される:

- Cycle Phase Completion: ✓ Skipped（パターン A の場合）
- Cycle Phase Completion: ⊘ Skipped（required で skip allow を有効にしていない場合は merge ブロック）

### 関連

- Issue: #686
- Unit 定義: `.aidlc/cycles/v2.6.1/story-artifacts/units/002-cycle-phase-completion-draft-skip.md`
- 既存設計: `Unit 001 / Issue #672 / v2.5.6`（オリジナル workflow）
```

## 3. 整合性チェック

### 3.1 ガイド照合（CLAUDE.md ルール）

| ルール | 適用 |
|--------|------|
| ドッグフーディング特殊処理を本体に埋めない | yaml の `if` 条件は GitHub Actions 標準機能のみ使用、自リポジトリ判定なし |
| `$(...)` 絶対禁止 | yaml には bash コマンド埋め込みなし。本 Unit のサンプル yaml も `$(...)` 不使用 |

### 3.2 Unit 001 設計との整合性

Unit 001 は scripts/lib 系の修正、Unit 002 は workflow 系の修正で互いに独立。共有する依存も干渉もない。

### 3.3 既存 Cycle Phase Completion 機能との整合性

- 当 workflow の判定スクリプト本体（`bin/check-cycle-phase-completion.sh`）は変更しない
- 当 workflow のチェック対象（3 Phase 完了状態）は変更しない
- 変更は「ジョブ実行可否のフィルタ」だけ

## 4. 実装手順（Phase 2 着手時の指針）

1. `.github/workflows/cycle-phase-completion-check.yml` の `pull_request.types` に `converted_to_draft` を追加
2. 同 workflow の `cycle-phase-completion` ジョブの `if` に `&& github.event.pull_request.draft == false` を追加
3. 冒頭コメントに `Unit 002 / Issue #686 / v2.6.1: draft PR skip` を追記
4. `docs/cycle-phase-completion-check-ruleset.md` 末尾に「## Draft PR での skip 挙動」セクション追加
5. `actionlint`（利用可能なら）または yaml パース確認
6. markdownlint で `docs/cycle-phase-completion-check-ruleset.md` を検証
7. **事前実観測**（マージ前ゲート）: cycle/v2.6.1 の draft PR で synchronize / ready_for_review / converted_to_draft の各イベントを発火させ、GitHub Actions UI で当ジョブの skipped / execute 切替を確認、PR URL / Run URL を `history/construction_unit02.md` に記録
