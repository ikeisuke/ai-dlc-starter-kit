# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.5.5 — Operations / Construction レビュー周辺の運用ノイズ統合解消

## 開発の目的

v2.5.4 リリース後にバックログへ蓄積された **5 件の高優先度（priority:high）バックログ** を統合解消する patch リリース。いずれも Operations / Construction Phase の自動化フロー上で AI エージェントが実害（手動 fallback 必要 / 履歴コミット分裂 / 環境依存破綻）を経験した実証ベースの改善案であり、個別対応では類似シナリオ再発を抑制できないため一括で構造的健全化する。

1. **`pr-ops.sh merge` の auto-merge エラー判別不全**（[#665](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/665)）— auto-merge 無効リポジトリ + CI pending 状態で `pr-ops.sh` の grep パターンが GitHub CLI 実エラー文言（`Auto merge is not allowed`、`enablePullRequestAutoMerge`）に網羅マッチせず `error:unknown` を返却。結果として `operations-release.md §7.13` のエラー対処案内が起動せず、利用者が原因特定に複数ステップのデバッグを強いられる構造問題を解消する
2. **`retrospective-issue.sh` の zsh source 互換性問題**（[#661](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/661)）— v2.5.4 Unit 004 で `predecessor-issue.sh` を shell 判定分岐方式（案 B）に修正したが、同一の `__SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" ...)` パターンを持つ `retrospective-issue.sh` は v2.5.4 Inception DR-001 で OUT_OF_SCOPE 化された。本サイクルで同方式を適用し、v2.5.4 で `skip` マーカーを残した `tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` zsh source 検証を通常の bash/zsh 両 source 検証に戻す
3. **Construction Unit 完了処理ステップ 5（履歴記録）↔ ステップ 8（コミット）の分裂**（[#654](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/654)）— v1.15.1 cycle 実例で 5 Unit × 2 commit = 10 commit に膨張し最終的に rebase fixup（破壊的操作）で統合した実害が報告されている。`04-completion.md` ステップ順序は正しいが、`review-flow.md` (v2.5.1) の (2c) 履歴コミット推奨と Unit 完了 commit の関係が曖昧で、Markdownlint / Squash 等他作業に挟まれて履歴記録の存在を忘れて commit を先行する誘発構造になっている。文書整合 + コミット前チェックリスト + write-history 警告経路の組合せで構造的予防する
4. **Operations 04-completion ステップ3 リモート CI 自動 tag 競合手順不在**（[#650](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/650)）— Visitory v1.15.0 cycle で GitHub Actions の `release.yml` が auto-merge 後にタグを自動作成し、`04-completion.md` 手順通りのローカル `git tag → push` がリモート tag 衝突で reject される実害が観測された。現行手順は `version_tag = false`/`true` の二択しか想定しておらず、CI 自動 tag 運用ケースが構造未対応。事前確認 + 衝突時 fallback 手順を追加する
5. **`gh pr edit --body-file` のスコープ不足エラー fallback 経路不在**（[#626](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/626)）— Visitory v1.14.2 cycle で Operations 7.8 の `pr-ready` 中、`gh pr edit` 内部実装の GraphQL `login` / `name` / `slug` フィールド取得が `read:org` / `read:discussion` スコープ不足で失敗し、PR Ready 化は成功するが PR 本文更新だけが手動 fallback（`gh api PATCH`）必要になった。`operations-release.sh pr-ready` 自体に REST PATCH fallback を組み込み、Operations 自動化の完全性を保つ

## ターゲットユーザー

- AI-DLC Starter Kit を採用しているプロジェクト開発者（特に GitHub auto-merge 無効 / CI 自動 tag 運用 / トークンスコープ制限のあるエンタープライズ環境）
- AI エージェントが auto mode で Operations Phase を完走する場面（pr-ready / merge-pr / version-tag / post-merge-cleanup の自動化フロー）
- AI エージェントが zsh interactive shell で AI-DLC helper を `source && 関数呼び出し` する経路（Claude Code 含む複数 AI エージェント実装）
- Construction Phase で複数 Unit を一気通貫で完走する開発者（履歴コミット分裂による rebase 操作を避けたい運用者）

## ビジネス価値

- **Operations 自動化フローの完全性保全** — `pr-ops.sh merge` の auto-merge エラー判別精度向上 + `gh pr edit` フォールバック組み込み + リモート CI 自動 tag 競合対処手順により、Operations Phase が AI エージェント単独で完走できるリポジトリ条件のカバレッジを拡大
- **AI エージェント実行環境互換性の担保** — `retrospective-issue.sh` zsh source 化により、v2.5.4 で `predecessor-issue.sh` のみ救済された AI エージェント実行経路を helper 全体に拡張完了
- **Construction 履歴コミット分裂の構造的予防** — 文書整合 + commit-flow チェックリスト + write-history 警告の三層化により、利用者が手順を取り違えても 2 コミット分裂が発生しない構造を作る（v1.15.1 cycle のような 10 commit + 破壊的 rebase の再発防止）
- **patch リリース運用の標準化** — v2.5.4 と同じ「5 件統合解消」パターンで連続的に運用ノイズを取り除き、starter kit の信頼性向上を可視化

## 含まれるもの（Unit 想定 5 件）

| Unit 候補 | 対象 Issue | 概要 |
|----------|-----------|------|
| Unit 001 | [#665](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/665) | `pr-ops.sh` の `auto_error` grep パターンを `auto[- ]merge is not allowed` / `enablePullRequestAutoMerge` / `not enabled` 等を含む形に拡張し、auto-merge 無効リポジトリ + CI pending 時に `pr:<N>:error:auto-merge-not-enabled` を返す。`operations-release.sh` の bats テストにエラー分類シナリオを追加 |
| Unit 002 | [#661](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/661) | `skills/aidlc/scripts/lib/retrospective-issue.sh` の `__RETRO_ISSUE_SCRIPT_DIR` 解決を v2.5.4 Unit 004 と同じ shell 判定分岐方式（`if [[ -n "${ZSH_VERSION:-}" ]]; then ${(%):-%N}; else ${BASH_SOURCE[0]}; fi`）に揃える。`tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` zsh skip マーカーを解除して bash/zsh 両 source 検証 + SCRIPT_DIR 検証を通常実施に戻す |
| Unit 003 | [#654](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/654) | Construction Unit 完了処理 step5↔step8 分裂の構造的予防。`steps/construction/04-completion.md` ステップ 5/8 の関係明示（履歴ファイルを必ず Unit 完了 commit に含める）+ `steps/common/commit-flow.md` チェックリストへの「履歴ファイル staged 確認」追加 + `scripts/write-history.sh` 実行後の unstaged 警告（提案 A+B+C を組合せ。D は A の自然帰結として吸収） |
| Unit 004 | [#650](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/650) | `steps/operations/04-completion.md` ステップ 3（バージョンタグ付け）に「リモート CI 自動 tag 機構との競合確認」手順を追加。事前確認（`git ls-remote --tags origin vX.X.X`）+ 衝突時の判定マトリクス（同 SHA / 異 SHA）+ fallback 手順（ローカル削除 → `git fetch origin tag` で同期）を文書化 |
| Unit 005 | [#626](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/626) | `scripts/operations-release.sh pr-ready` の `gh pr edit --body-file` 失敗時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST 直叩きする fallback 経路を組み込む。エラー判別ロジックは grep パターン（`read:org` / `read:discussion` / GraphQL field error）で行い、それ以外のエラーは従来通り上位に伝播 |

## 除外するもの（OUT_OF_SCOPE）

- **[#667](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/667)** 振り返りフローを Operations Phase から分離 / `/aidlc r | retrospective` 独立起動 — 規模大（新スキル + parser 改修）、本サイクル patch スコープ外。次サイクル以降（minor v2.6.0 候補）で対応
- **[#666](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/666)** GitHub ラベル体系を標準ラベルに統一（type: プレフィックス廃止） — refactor かつ全 Issue 影響、本サイクル patch スコープ外
- **[#664](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/664)** 振り返り Issue と通常 backlog Issue の分離・可視化方式検討 — 設計検討フェーズが必要、本サイクル patch スコープ外
- **[#663](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/663)** パーミッション監査の設定フラグ化 — feature 拡張、本サイクル patch スコープ外
- **[#662](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/662)** Construction 計画レビュー早期 defer ガイド適用拡大 — v2.5.4 振り返り Try 1、本サイクル patch スコープ外
- **[#655](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/655)** Operations codex review の focus 絞り込み — feature 検討、本サイクル patch スコープ外
- **[#652](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/652)** 振り返り 3 層検証手順の skill 化 — 規模大、本サイクル patch スコープ外
- **#654 提案 D（ステップ 8 への `git add` 明示手順追加）の単独実装** — 提案 A（文書整合）の自然な帰結として吸収するため独立記述しない（規則の重複・矛盾を避ける）
- **`pr-ops.sh` 全エラーパターンの網羅再設計** — Unit 001 は #665 が指摘した auto-merge 関連の grep パターン拡張に限定し、他のエラーパターン（`merge conflict` / `branch protection` 等）の再設計は OUT_OF_SCOPE

## 成功基準

| Unit | 検証方法 | 合格条件（定量） |
|------|---------|----------------|
| Unit 001 | (a) `pr-ops.sh` の `auto_error` grep パターンが `auto[- ]merge is not allowed` / `enablePullRequestAutoMerge` を含む（**grep でパターン拡張を確認**）<br>(b) bats テスト追加: GitHub CLI の実エラー文言 `GraphQL: Auto merge is not allowed for this repository (enablePullRequestAutoMerge)` を fixture として与えた場合に `pr:<N>:error:auto-merge-not-enabled` を返す（**追加テスト 1 件以上**）<br>(c) 既存の `auto-merge is not allowed`（ハイフン付き）パターンが引き続き合格する後方互換テストが残っている<br>(d) **fixture 更新トリガーの明文化（DR-001）**: 「`gh` CLI バージョン更新で実エラー文言が変わった場合、現行 `gh` 出力を固定化した bats fixture が失敗することで気付ける運用」を Unit 001 完了履歴 `.aidlc/cycles/v2.5.5/history/construction_unit01.md` に **1 行以上** 記録（grep で確認、Unit 005 と保守方針を統一） | (a)(b)(c)(d) すべて合格 |
| Unit 002 | (a) `bash` / `zsh -c` 両方で `source skills/aidlc/scripts/lib/retrospective-issue.sh && retrospective_resolve_issue v2.5.4` が exit 0 で動作（v2.5.4 Unit 004 の predecessor-issue.sh と同等の動作確認）<br>(b) `__RETRO_ISSUE_SCRIPT_DIR` の SCRIPT_DIR 解決が `if [[ -n "${ZSH_VERSION:-}" ]]; then ${(%):-%N}; else ${BASH_SOURCE[0]}; fi` パターンに置換されている（grep で確認）<br>(c) `tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` テストから `skip "OUT_OF_SCOPE: see backlog #..."` マーカーが削除され、bash/zsh 両 source 検証 + SCRIPT_DIR 検証が通常実行される | (a)(b)(c) すべて合格 |
| Unit 003 | (a) `steps/construction/04-completion.md` ステップ 5/8 の関係に「履歴ファイルを必ず Unit 完了 commit に含める」旨の注記が **1 箇所以上**（grep で確認）<br>(b) `steps/common/commit-flow.md` のコミット前チェックリストに「履歴ファイル staged 確認」項目が **1 項目以上** 追加されている（grep で確認）<br>(c) `scripts/write-history.sh` 実行後に履歴ファイルが unstaged の場合に `warning: history file unstaged` 等の警告を stdout/stderr に出力する（exit code 0 維持、bats テストで動作確認、**追加テスト 1 件以上**）<br>(d) ドライラン手順を **必須記載項目 3 点固定**で文書化（**(d-1)** `write-history` 実行手順の参照、**(d-2)** `git status` または `git diff --cached --name-only` で履歴ファイル staged 確認、**(d-3)** 履歴ファイル `git add` 確認）。grep で 3 項目すべての出現を検証 | (a)(b)(c)(d-1)(d-2)(d-3) すべて合格 |
| Unit 004 | (a) `steps/operations/04-completion.md` ステップ 3 に `git ls-remote --tags origin vX.X.X` による事前確認手順が追加されている（grep で確認）<br>(b) リモート tag 状態の **判定マトリクス（3 ケース必須: 不在 / 同 SHA 衝突 / 異 SHA 衝突）が表形式（markdown table）で記載**され、各ケースに **(b-1)** 実行コマンド 1 つ以上、**(b-2)** 期待結果 1 つ以上、**(b-3)** 次アクション 1 つ以上、を必須カラムとして含む<br>(c) 同 SHA 衝突時の fallback 手順として **(c-1)** ローカル tag 削除コマンド、**(c-2)** `git fetch origin tag vX.X.X` または等価の同期コマンド、**(c-3)** 同期後検証手順、の 3 項目を文書化<br>(d) 異 SHA 衝突時の手順として **(d-1)** AI が自動 push を中止する判断保留ルール、**(d-2)** ユーザーへの差分提示（両 tag のコミット SHA 表示）、**(d-3)** ユーザー選択肢提示（リモート優先 / ローカル優先 / 中断）、の 3 項目を文書化 | (a)(b-1)(b-2)(b-3)(c-1)(c-2)(c-3)(d-1)(d-2)(d-3) すべて合格 |
| Unit 005 | (a) `scripts/operations-release.sh pr-ready` で `gh pr edit --body-file` 実行時にスコープ不足エラー（`read:org` / `read:discussion` / GraphQL field error 等）を grep 検出する分岐が追加されている（grep で確認）<br>(b) 検出時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST PATCH fallback を実行する経路が追加されている<br>(c) bats テスト追加: `gh pr edit --body-file` がスコープ不足エラーを返す fixture を与えた場合に REST PATCH fallback が呼ばれ exit 0 で完了する（**追加テスト 1 件以上**）<br>(d) スコープ不足以外のエラーは従来通り上位に伝播し、無関係な失敗を fallback で握り潰さない（後方互換テスト） | (a)(b)(c)(d) すべて合格 |

## 期限とマイルストーン

- patch リリース v2.5.5 として 1 サイクル内で完了
- 全 Unit を Inception → Construction → Operations 一気通貫で実施

## 制約事項

- **後方互換**: 既存の Operations Phase progress.md / history / Operations release scripts の挙動を破壊しない
  - Unit 001: 既存の auto-merge エラーパターン（`auto-merge is not allowed`、ハイフン付き）が引き続きマッチすること（パターン拡張のみ）
  - Unit 005: スコープ不足以外のエラーは従来通り上位伝播し、無関係な失敗を fallback で握り潰さない
- **patch スコープ**: 破壊的変更なし。設定ファイル（config.toml）のキー追加・名称変更は行わない（Unit 003 の write-history 警告は exit code 0 維持で stdout/stderr 出力のみ）
- **メタ開発前提**: スキルファイル変更は `skills/aidlc/SKILL.md` の本文 500 行制限を遵守
- **検証手段の追加 / 有効化**: 各 Unit で **検証手段の追加または有効化を必須** とする（「テスト追加」「文書 grep 検証」「既存テスト skip 解除」のいずれかで充足）。Unit 別の充足要件:
  - Unit 001 / 003 / 005: **新規 bats テスト追加 1 件以上**（Unit 003 は write-history 警告経路、Unit 001 / 005 は grep パターン分岐）
  - Unit 002: **既存テストの有効化**（`tests/aidlc-helpers-zsh-source.bats` の `skip "OUT_OF_SCOPE: see backlog #..."` マーカー削除）で要件充足。新規テスト追加は不要
  - Unit 004: **文書追加が主作業**のため、bats テスト追加は不要。**成功基準 (a)〜(d) の各項目を grep または markdown 構造検証で機械的にチェックする検証手段で充足**（テスト追加任意の例外ではなく「文書 grep 検証で充足」と位置付ける）
- **修正対象の限定**: Unit 001 は `pr-ops.sh` の `auto_error` grep パターンに限定（他エラーパターンの再設計は OUT_OF_SCOPE）。Unit 002 は `retrospective-issue.sh` 1 ファイルに限定（他 helper の追加 refactor なし）

## 不明点と質問（Inception Phase中に記録）

[Question] Unit 003 の write-history 警告経路について、`scripts/write-history.sh` が呼び出された後に外部から git status を確認するのか、`write-history.sh` 自身が `git diff --cached --name-only` で staged 確認するのか、設計選択があるか
[Answer] **DR-002 で確定**: write-history.sh 自身が `git diff --cached --name-only -- <history-path>` で staged 確認する（単一責任 + bats テスト対象明確化）。`git diff` 実行失敗時は警告スキップで exit 0 維持を Construction Phase で実装。詳細は `.aidlc/cycles/v2.5.5/inception/decisions.md` DR-002 参照

[Question] Unit 005 のスコープ不足エラー判別 grep パターンが将来の `gh` バージョンで変わる場合の保守性
[Answer] **DR-001 で確定**: fixture-based bats テストで現行 `gh` 出力を固定化し、`gh` バージョン更新時にテストが失敗することで気付ける運用とする。fixture 更新トリガーの記録先は Unit 完了履歴（`history/construction_unit{NN}.md`）に統一（Unit 001 / Unit 005 共通）。詳細は `.aidlc/cycles/v2.5.5/inception/decisions.md` DR-001 参照
