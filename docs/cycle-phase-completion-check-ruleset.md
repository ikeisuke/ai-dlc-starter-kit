# Cycle Phase Completion Check 必須化手順

`cycle/*` ブランチの PR を `main` にマージする前に `Cycle Phase Completion` チェックを必須化する手順をまとめる。Unit 001 / Issue #672 / v2.5.6。

## 概要

`.github/workflows/cycle-phase-completion-check.yml` が `pull_request` イベントで `head_ref` が `cycle/*` のとき `bin/check-cycle-phase-completion.sh` を実行する。本ガードを Branch protection / Repository Ruleset で「必須」化することで、Inception / Construction / Operations の 3 Phase が未完了の cycle PR が `main` に取り込まれる事故を防ぐ。

## 適用タイミング

- **通常完了経路**: Operations Phase 完了直前に管理者が下記 「適用手順」を実施し、適用証跡（設定 JSON / スクリーンショット）を `docs/cycles/{cycle}/` または PR description に保存する
- **暫定完了経路**: 管理者操作が UI のみで本サイクル中に未完了となる場合、Operations Phase 完了直前に AskUserQuestion で「暫定完了承認」を取得し、follow-up Issue を起票して適用予定マイルストーンを明記する。本経路適用時は Unit 001 状態を「完了（暫定）」とし、`実装状態` セクションに暫定理由を記録する

## 適用手順 A: `gh api` REST/GraphQL（スクリプト化）

GitHub Repository Ruleset を REST API 経由で作成する例:

```bash
# 環境変数
OWNER="ikeisuke"
REPO="ai-dlc-starter-kit"
RULESET_NAME="cycle-phase-completion-required"
CHECK_NAME="Cycle Phase Completion"
WORKFLOW_FILE="cycle-phase-completion-check.yml"

# Ruleset payload を一時ファイルに書き出して送信（heredoc は GraphQL では使わず JSON 単独）
cat > /tmp/ruleset.json <<JSON
{
  "name": "${RULESET_NAME}",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {
            "context": "${CHECK_NAME}"
          }
        ],
        "strict_required_status_checks_policy": false
      }
    }
  ]
}
JSON

gh api "repos/${OWNER}/${REPO}/rulesets" \
  --method POST \
  --input /tmp/ruleset.json
```

注意:

- `required_status_checks[].context` は workflow の `jobs.<job>.name`（本 case `Cycle Phase Completion`）と完全一致させる
- 既存の Ruleset がある場合は `gh api repos/${OWNER}/${REPO}/rulesets` で一覧確認し、PUT で更新するか別 ID で追加するかを判断
- 適用後に作成した Ruleset の ID を `docs/cycles/{cycle}/ruleset-application.json` 等に保存（適用証跡）

## 適用手順 B: GitHub UI 操作

GitHub のリポジトリ設定 → Rules → Rulesets → New ruleset から作成する手順:

1. Repository → Settings → Rules → Rulesets → **New ruleset → New branch ruleset**
2. **Ruleset Name**: `cycle-phase-completion-required`
3. **Enforcement status**: `Active`
4. **Target branches** → Add target → **Include default branch**（または `main` を直接指定）
5. **Rules** セクションで以下を有効化:
   - **Require status checks to pass**: チェック追加 → `Cycle Phase Completion` を選択（workflow が main に存在する必要あり）
   - 必要に応じて `Require branches to be up to date before merging` をオフ（任意）
6. **Create** で保存
7. 適用証跡として設定画面のスクリーンショット（必須項目チェック後）を `docs/cycles/{cycle}/ruleset-application.png` に保存

## 動作確認

適用後、以下を確認する:

- `cycle/v2.5.6` ブランチの PR に対して `Cycle Phase Completion` が CI checks 一覧に表示される
- 3 Phase いずれかが未完了の cycle PR は `Cycle Phase Completion` で fail し、マージブロックされる
- `chore/*` / `fix/*` / `feature/*` 等の `cycle/*` 以外の PR では当該 job が `skipped` 表示になる（マージブロックは発生しない）

## 暫定完了経路の follow-up Issue 起票テンプレ

UI 操作が本サイクル中に間に合わない場合に起票する Issue テンプレート:

```markdown
## 概要

cycle/{cycle} で導入した `Cycle Phase Completion Check` の Branch protection 必須化を Repository Ruleset で適用する。

## 経緯

cycle/{cycle} Operations Phase 完了直前に GitHub Repository Ruleset の管理者適用が UI 操作で未完となったため、暫定完了経路を取った。本サイクルで CI チェック自体は導入済み（PR #XX）だが、必須化の実適用は次サイクルで対応する。

## 受け入れ基準

- [ ] `gh api repos/.../rulesets` で `cycle-phase-completion-required` Ruleset が active 状態
- [ ] cycle/* ブランチの PR で `Cycle Phase Completion` チェックが必須として表示される
- [ ] 適用証跡（設定 JSON またはスクリーンショット）が `docs/cycles/{次サイクル}/` 配下に保存される

## 適用予定マイルストーン

v{次サイクル}（cycle/{cycle} の次サイクル Operations Phase 完了直前）

## 関連

- 本サイクルの導入 PR: #XX
- Unit 001 計画書: `.aidlc/cycles/{cycle}/plans/unit-001-plan.md`
- 適用手順 doc: `docs/cycle-phase-completion-check-ruleset.md`
```

## Draft PR での skip 挙動（v2.6.1 Unit 002 / Issue #686）

`cycle/*` ブランチの **draft PR** では `Cycle Phase Completion` ジョブが GitHub UI 上で `Skipped` 表示になる。これは Construction Phase 中の中間 push で進捗未完了状態のジョブが fail することを防ぐための設計である（Issue #686）。

### イベントごとの挙動

| GitHub Event | PR draft 状態 | ジョブ動作 | UI 表示 |
|-------------|------------|----------|--------|
| `opened`（draft で開く） | draft | skip | Skipped |
| `synchronize`（draft 中に push） | draft | skip | Skipped |
| `ready_for_review` | non-draft | execute | Running → Pass / Fail |
| `synchronize`（ready 後に push） | non-draft | execute | Running → Pass / Fail |
| `converted_to_draft`（ready から draft に戻す） | draft | skip | Skipped |

### Repository Ruleset で required にしている場合の確認手順

**デフォルト運用方針**: 当ジョブを Required status check として **維持** することを推奨する。Cycle Phase 完了状態を main マージ前にゲートする目的（Issue #672 の本来の責務）と整合する。

#### パターン A（推奨・デフォルト運用）: Required 維持 + skipped を成功扱いに設定

GitHub Web UI 手順（参考、UI 文言は変動する可能性あり）:

1. Settings > Rules > Rulesets > 該当 Ruleset > Edit
2. 「Status checks that are required」セクションで `Cycle Phase Completion` を確認
3. skipped check の扱いに関する設定（GitHub UI の最新文言に従う）を「成功扱い（pass）」になるよう調整

API ベースの検証手順（推奨、UI 変動に依存しない）:

```bash
gh api repos/{OWNER}/{REPO}/rulesets/{RULESET_ID} \
  --jq '.rules[] | select(.type=="required_status_checks") | .parameters'
```

期待される確認ポイント（GitHub Rulesets API の `required_status_checks.parameters` 構造、本書執筆時点 / 2026-05-10）:

- `required_status_checks[]` 配列内に `context: "Cycle Phase Completion"` または `name` 相当のエントリが存在すること
- `strict_required_status_checks_policy` 等のキーが運用方針に合致していること
- skipped 扱いに関する parameter（API スキーマ更新で名称が変わる可能性があるため、最新スキーマは GitHub Docs `https://docs.github.com/en/rest/repos/rules` 参照）

期待される PR UI 表示:

- draft PR: `Cycle Phase Completion: Skipped`（job 自体が skip）
- ready_for_review 後: `Cycle Phase Completion: Pass / Fail`（実行結果に従う）
- 設定を誤った場合、draft PR の merge ボタンが「Cycle Phase Completion is required」でブロックされる挙動が観察される場合がある

**検証重視の指針**: Web UI 手順は GitHub の UI 文言変更で陳腐化しうるため、設定後は必ず実 PR で動作確認すること（draft / ready の両状態で merge ボタンの状態と check 表示を目視確認、または API で取得した設定値が運用方針と一致することを確認）。本ドキュメントは「設定すべき内容」を運用方針として示すものであり、UI ステップそのものは GitHub の最新ドキュメントを正本とする。

#### パターン B（緊急時の例外運用）: 一時的に required から外す

draft PR では skip、`ready_for_review` 後にのみ実行される性質上、**緊急時のみ** required から一時的に外す運用も許容する。ただし以下の条件を満たすこと:

- パターン A の設定変更に時間がかかり、リリースが阻害される一時的な状況に限る
- ジョブ実行結果は `gh pr checks` で **手動** 確認し、必ず通過していることを目視で確認
- 緊急対応完了後、速やかにパターン A に戻す

**警告**: パターン B を恒常化すると Cycle Phase Completion の merge ガード効果が失われ、Issue #672 で導入した本機能の意義が大きく損なわれる。Required 維持を強く推奨する。

## 関連

- 実装 SoT: `bin/check-cycle-phase-completion.sh`
- CI workflow: `.github/workflows/cycle-phase-completion-check.yml`
- Issue: #672（オリジナル導入）/ #686（draft PR skip 追加）
- Unit: `.aidlc/cycles/v2.5.6/story-artifacts/units/001-cycle-phase-completion-check.md`（オリジナル）/ `.aidlc/cycles/v2.6.1/story-artifacts/units/002-cycle-phase-completion-draft-skip.md`（draft skip）
