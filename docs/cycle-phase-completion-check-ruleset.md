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

## 関連

- 実装 SoT: `bin/check-cycle-phase-completion.sh`
- CI workflow: `.github/workflows/cycle-phase-completion-check.yml`
- Issue: #672
- Unit: `.aidlc/cycles/v2.5.6/story-artifacts/units/001-cycle-phase-completion-check.md`
