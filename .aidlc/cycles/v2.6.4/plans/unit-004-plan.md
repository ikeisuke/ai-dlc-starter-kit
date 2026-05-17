# Unit 004 実装計画: 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保

## 対象 Unit

- **Unit**: 004 - 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保
- **関連 Issue**: #710（部分対応 / `Relates` 扱い。完全クローズは v2.7.0+ で破壊的変更が入った時点）
- **検出元**: v2.6.3 サイクル振り返り議論（KPT で振り返り Issue 不要と判断した運用実例）
- **優先度**: Medium（refactor / 将来基盤）
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.3 振り返りで「`Retrospective: {cycle}` Issue を毎サイクル必ず起票」が冗長な場面（Try が既存 backlog Issue でカバー済、KPT が議論で完結等）が顕在化した。v2.7.0+ で「Try/改善単位の個別起票」へ移行する前段として、本サイクル（patch）では:

- 集約 Issue 起票を opt-out できる **config フラグの基盤** を導入（デフォルトは既存動作）
- 既存 `predecessor_resolve_issue` の 5 経路解決の **後方互換** を実測で確認
- 既存ガード（対話必須トークン / cap 判定 / mirror 送信判断）の **挙動不変** を実測で確認

を実施する。破壊的変更（自動起票完全廃止 / `Retrospective:` タイトル運用見直し / API 破壊的変更）は v2.7.0+ に明示除外。

## スコープ

### 含まれるもの（責務）

- **必須対応 1（opt-in 基盤）**: `skills/aidlc/config/defaults.toml` の `[rules.retrospective]` セクションに **`auto_issue_creation`**（boolean）を追加
  - デフォルト値 **`true`** に固定（=既存動作互換 / consumer は config を触らない限り挙動変化なし）
  - `false` の場合に集約 Issue 起票（§1.5 Step 3/4/5）をスキップする経路を実装
- **必須対応 2（retrospective.md 改訂）**: `skills/aidlc-retrospective/steps/retrospective.md` の §1.5 Step 2 末尾に opt-out 判定を追加
  - `auto_issue_creation=false` のとき `/tmp/aidlc-opt-out.txt` に opt-out フラグを出力
  - Step 3 直前のスキップ条件を `cap 超過 OR opt-out` に拡張
  - スキップ時は「opt-out により集約 Issue 起票をスキップしました（v2.6.4 / #710 基盤導入）」を平文表示
- **必須対応 3（既存ガードの呼び出し順不変化）**: `auto_issue_creation=false` 経路でも以下のガードが本来の意味で動作することを担保
  - 対話必須トークン / cap 判定 / mirror 送信判断は **§1.5 Step 2 までの既存処理** で評価され続ける。opt-out 判定は Step 3 進入の手前で適用されるため、ガード機構そのものに変更なし
- **必須対応 4（後方互換確認 / 5 経路）**: `predecessor_resolve_issue` の 5 経路の `resolution_path` 不変を確認
  - 既存 bats（`tests/predecessor-issue-handoff.bats`）を実行して pass を確認
  - 各経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）の発火条件を手動再現し、結果を `decisions.md` に DR として記録
- **必須対応 5（既存ガードの挙動維持確認）**:
  - 既存 bats（`tests/retrospective-dialog-token.bats` / `tests/retrospective-issue-create.bats` 他）の pass 確認
  - 対話必須トークン / cap 判定 / mirror 送信判断の手動再現結果を `decisions.md` に DR として記録
- **必須対応 6（対象外項目の defer 記載）**: `skills/aidlc-retrospective/SKILL.md`（または `steps/retrospective.md` 末尾）に「v2.6.4 サイクル対象外項目」と「v2.7.0+ で対応予定」を 5 〜 10 行で defer 記録

### 含まれないもの（境界 / Unit 定義に準拠）

- 振り返り Issue 自動起票の完全廃止（v2.7.0+）
- `Retrospective: {cycle}` タイトル運用の本格的見直し（v2.7.0+）
- 振り返り Issue API（`retrospective_api_*`）の破壊的変更（v2.7.0+）
- Try/改善単位での個別起票実装（v2.7.0+）
- `aidlc-retrospective` 以外のスキル（`aidlc-feedback` 等）への波及改修
- `feedback-mode.sh` の意味再定義（`mode=disabled` との関係整理は v2.7.0+ で実施。本サイクルでは併存）

## 設計方針

### config キー命名と配置

```toml
[rules.retrospective]
# ...既存キー（feedback_mode / feedback_max_per_cycle）...

# 振り返り集約 Issue の自動起票フラグ（v2.6.4 / #710 / opt-in 基盤）
# - true（デフォルト）: 既存動作。§1.5 Step 3/4/5 を実行して集約 Issue を 1 件起票する
# - false           : 集約 Issue 起票をスキップ。Try/改善単位起票への移行準備（v2.7.0+ で個別起票実装予定）
# 本フラグは feedback_mode と独立に評価される。feedback_mode の対話必須トークン / cap 判定 /
# mirror 送信判断のガード機構は本フラグ値に関わらず §1.5 Step 2 までで評価される。
# false 経路ではガード評価後に起票だけスキップされる。
auto_issue_creation = true
```

- `[rules.retrospective]` 配下に配置（既存 `feedback_mode` / `feedback_max_per_cycle` と同階層）
- read-config.sh の key alias 追加は不要（`rules.retrospective.*` は既存パターンと一致）

### retrospective.md 改訂方針（最小差分）

#### 実行順序の優先関係（Review Round 1 指摘 #2 への対応）

`§1.0 mode 確定 → §1.5 Step 2 opt-in 判定 → §1.5 Step 3-5 Issue 起票` の直列構造であり、優先順位は以下:

1. **最優先（§1.0 段階）**: `feedback_mode = "disabled"` が確定した場合、`retrospective.md:60` のガードにより以降のステップを実施せず exit 0。`auto_issue_creation` 判定には到達しない
2. **次優先（§1.5 Step 2 段階）**: `mode ≠ disabled` で Step 2 に到達した場合のみ、`auto_issue_creation` フラグが評価される
3. **cap 判定との関係**: cap 超過と opt-out のいずれが先に成立しても Step 3/4/5 スキップに収束するため順序依存なし

つまり `mode=disabled` と `auto_issue_creation=false` は **意味論的に独立** だが、**実行経路上は mode=disabled が先に評価され、auto_issue_creation はその後段の判定** という関係になる。テストシナリオもこの順序で分離する。

#### 挿入内容

§1.5 Step 2 の末尾、Step 3 進入直前に以下を追加。`read-config.sh` の exit code に応じて未設定と取得失敗を区別する（Review Round 1 指摘 #1 への対応）:

```bash
# v2.6.4 / #710 / opt-in 基盤: auto_issue_creation=false の場合は集約 Issue 起票をスキップ
# read-config.sh の終了コード: 0=値あり / 1=キー不在（未設定→ true fallback）/ 2=取得失敗（警告して continue + opt-out=false 既定）
set +e
scripts/read-config.sh rules.retrospective.auto_issue_creation > /tmp/aidlc-auto-issue.txt 2>/tmp/aidlc-auto-issue.err
rc_auto_issue=$?
set -e
case "$rc_auto_issue" in
    0)
        read auto_issue < /tmp/aidlc-auto-issue.txt
        ;;
    1)
        # キー不在: defaults.toml の値（true）に解決されていないケースは通常発生しないが、保険として true fallback
        auto_issue="true"
        ;;
    *)
        # 取得失敗: warn 表示 + 既定（既存動作）として true を採用（fail-open: opt-out 判定をスキップして従来通り起票）
        echo "[warn] auto_issue_creation の読み取りに失敗しました（rc=$rc_auto_issue）。既定動作（auto_issue_creation=true 相当）で続行します。" >&2
        cat /tmp/aidlc-auto-issue.err >&2 2>/dev/null || :
        auto_issue="true"
        ;;
esac
if [[ "$auto_issue" == "false" ]]; then
    echo "opt-out=true" > /tmp/aidlc-opt-out.txt
else
    : > /tmp/aidlc-opt-out.txt
fi
```

**fail-open 採用根拠**: 本フラグは集約 Issue 起票のスキップを行う opt-in 基盤であり、取得失敗時に「起票スキップ」へ倒すと既存動作（=毎サイクル起票）からの後退となる。fail-open（既定の起票継続）を採用し、warn で診断可能性を担保する。診断不能な silent fallback ではない点が Review Round 1 指摘 #1 への対応。

スキップ判定の文言を以下に変更（最小差分）:

> `/tmp/aidlc-over.txt` が非空（cap 超過）**または** `/tmp/aidlc-opt-out.txt` が非空（auto_issue_creation=false）の場合は Step 3 / Step 4 / Step 5 をすべてスキップして §1.6 へ進む。

opt-out 経路のユーザー向けメッセージ:

```text
集約 Issue 起票をスキップしました（auto_issue_creation=false / v2.6.4 / #710 opt-in 基盤）。
KPT は振り返りローカル記録として保持されます。Try/改善が必要な場合は個別 Issue 起票を検討してください。
```

### 既存ガードへの影響

| ガード | 対応 | 理由 |
|--------|------|------|
| 対話必須トークン | Step 2 までで評価。Step 3 進入時にスキップしてもトークン状態は保持 | opt-out 経路では Step 4 の `retrospective_api_create_issue` を呼ばないため token 検証経路に到達しない。トークン記録 (`retrospective_api_record_response`) は Step 4 内部のため、opt-out 時は記録もスキップされる。これは「起票しないので対話確認も不要」という意味論で一貫 |
| cap 判定 | Step 2 で既存通り評価 | cap 超過と opt-out のいずれが先に成立しても Step 3/4/5 スキップに収束する。順序依存なし |
| mirror 送信判断 | feedback_mode wizard で既存通り評価 | feedback_mode の 5 値 enum 評価は §1.0 段階で完了済。opt-in 基盤フラグとは独立 |

### 後方互換確認シナリオ（必須チェック手順）

Unit 定義の 5 経路チェックを `decisions.md` に DR として記録する（DR-009 候補）。各経路 1 行で「実行コマンド・期待 resolution_path・実 resolution_path・判定」を記載。bats が pass する場合は bats の出力結果を要約として併記。

**`resolution_path` 正式値の統一**: 実装（`skills/aidlc/scripts/lib/predecessor-issue.sh`）およびテスト（`tests/predecessor-issue-handoff.bats`）で使用される正式値を SoT とする。Unit 定義（004-retrospective-opt-in-foundation.md）に当初記載されていた `v250_compat` 表記は Review Round 1 指摘 #3 への対応として `v2_5_0_compat` へ統一済み。DR 記録および以降のドキュメントもすべて `v2_5_0_compat` を使用する（Review Round 1 指摘 #3 への対応）。

5 経路の正式値（実装準拠）:

| 経路 | resolution_path 値 |
|------|-------------------|
| 1 | `milestone_and_label` |
| 1' | `label_fallback` |
| 2 | `spool_fallback` |
| 3 | `v2_5_0_compat` |
| 4 | `warn_continue` |

### 対象外項目の defer 記載

`skills/aidlc-retrospective/SKILL.md` 末尾または `steps/retrospective.md` 末尾に 5 〜 10 行追加:

```markdown
## v2.6.4 サイクル対象外項目（v2.7.0+ で対応予定）

本スキルは v2.6.4 / #710 / Unit 004 で opt-in 基盤（`auto_issue_creation` フラグ）と
`predecessor_resolve_issue` の 5 経路後方互換確保までを実施した。以下は v2.7.0+ で対応予定:

- 振り返り Issue 自動起票の完全廃止（`auto_issue_creation` デフォルト値 `false` 化）
- `Retrospective: {cycle}` タイトル運用の本格的見直し
- `retrospective_api_*` の破壊的変更（API シグネチャ変更）
- Try/改善単位での個別 Issue 起票実装（1 Try = 1 Issue ループ）

参照: Issue #710 / v2.6.3 サイクル振り返り議論
```

## 完了条件チェックリスト

Unit 定義「責務」セクション全項目を網羅:

- [ ] `skills/aidlc/config/defaults.toml` の `[rules.retrospective]` に `auto_issue_creation = true` が追加されている
- [ ] `skills/aidlc-retrospective/steps/retrospective.md` の §1.5 Step 2 末尾に opt-out 判定が追加されている
- [ ] §1.5 のスキップ条件が「cap 超過 OR opt-out」に拡張されている
- [ ] デフォルト動作（`auto_issue_creation` 未設定または `true`）で既存動作と完全同一（手動シナリオ確認）
- [ ] `auto_issue_creation=false` で集約 Issue 起票がスキップされる（手動シナリオ確認）
- [ ] `predecessor_resolve_issue` の既存 bats（`tests/predecessor-issue-handoff.bats`）が pass
- [ ] `predecessor_resolve_issue` の 5 経路の `resolution_path` 出力不変を手動再現で確認し `decisions.md` に DR として記録（既存 bats が経路をカバーしていれば bats 結果引用で可、未カバー経路は手動再現結果を記載）
- [ ] 既存 retrospective 系 bats（`tests/retrospective-*.bats`）が pass
- [ ] 対話必須トークン / cap 判定 / mirror 送信判断の挙動を `decisions.md` に DR として記録
- [ ] `skills/aidlc-retrospective/SKILL.md` または `steps/retrospective.md` 末尾に「v2.6.4 サイクル対象外項目」と「v2.7.0+ で対応予定」を defer 記載
- [ ] 設計 AI レビュー（codex）完了
- [ ] コード AI レビュー（codex）完了
- [ ] 統合 AI レビュー（codex）完了
- [ ] markdownlint 0 errors（`npm run lint:md`）
- [ ] shellcheck（変更スクリプトがあれば）0 errors
- [ ] Unit 定義ファイル（`004-retrospective-opt-in-foundation.md`）の実装状態を「完了」に更新
- [ ] 履歴記録（`construction_unit04.md`）追記
- [ ] Issue #710 を `Relates` として記録（クローズはしない、v2.7.0+ で破壊的変更が入った時点）

## リスク・考慮事項

- **デフォルト動作不変の検証**: `auto_issue_creation` 未設定の consumer プロジェクトで挙動が変わらないこと。defaults.toml の階層マージで `true` がデフォルトとして適用されることを `read-config.sh rules.retrospective.auto_issue_creation` で確認
- **既存 bats の網羅性**: 既存 bats が 5 経路すべてをカバーしているか事前 grep で確認。未カバー経路は手動再現結果を DR に必ず記載
- **AI エージェント Bash ツール安全パターン遵守**: 本 Unit は config 追加 + Markdown 改訂 + 既存スクリプト読み取りのみで、`$(...)` / backtick を引数文字列に含めない
- **ドッグフーディング特殊処理禁止**: starter kit 自身か consumer かを判定する分岐を追加しない。本フラグは config の値で自然に opt-in 判定される
- **mode=disabled との混同**: `mode=disabled`（既存）と `auto_issue_creation=false`（新規）は意味論が異なる
  - `mode=disabled`: 「Issue 起票しない」（mode 全体の意思）
  - `auto_issue_creation=false`: 「自動起票廃止への基盤」（mode に依存しないスキップ）
  - 両者の関係整理は v2.7.0+ で実施し、本サイクルでは併存させる（defer 記載に明記）
- **SKILL.md 本文 500 行制限**: 改訂後の SKILL.md 行数を確認。retrospective.md は steps 配下で制限対象外

## 見積もり

1 〜 1.5 日（opt-in 基盤導入 + 後方互換確認 + decisions.md DR 追記 + defer 記載）

## レビュー観点

- **設計レビュー**: config キー命名の整合性、`auto_issue_creation` と `mode=disabled` の意味論分離、§1.5 Step 2 への挿入位置の妥当性、既存ガード機構との独立性
- **コードレビュー**: `defaults.toml` 差分の最小性、`steps/retrospective.md` 改訂の最小性、後方互換確認シナリオの網羅性
- **統合レビュー**: 既存 bats 全 pass、手動再現結果の DR 記録完備、defer 記載の明確性、`auto_issue_creation=true/false` 双方の挙動確認結果
