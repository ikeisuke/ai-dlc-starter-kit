# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.6.2（patch リリース）

## 開発の目的

v2.6.0 で実施した3領域（**振り返りフロー独立化** / **marketplace.json への version SoT 一本化** / **GitHub Projects 移行**）の **やりきれなかった defer 項目** と、**振り返り分離・Operations フロー周辺で表面化した致命的バグ** を patch リリースで一括解消し、v2.6 系の運用基盤を完成させる。

具体的には以下を一括で対応する:

1. **振り返り分離 / Operations フロー関連の致命的バグ修正**:
   - **#677**: Operations §7.12.5 `squash-712` が `write-history --mode operations-round` 後の unstaged history を取り込めず、レビュー反映 commit が squash 統合 commit と分離する構造的バグ。`merge_method=merge` で main に細粒度 commit が残り、運用上 force push 回避策を強いられる
   - **#678**: `operations-release.sh pr-ready --body-file <path>` および内部 `gh pr edit --body-file` が **0 バイト空ファイル** を検出せずに送信し、PR 本文が `null` で上書きされる事故（v1.16.1 で実発生）
2. **GitHub Projects 移行の defer 完成（v2.6.0 Unit 006 R1 指摘 defer）**:
   - **#682**: `bin/gh-project-cli.sh ensure-fields` の **field options 差分同期** 未実装。spec.yaml 改訂後の再実行で新 option が追加されない冪等性欠落
   - **#683**: Unit 006 副作用 bats テスト整備（`gh` API モックフレームワーク + `setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh` の本体動作テスト）
3. **振り返り分離（aidlc-migrate）周辺のセキュリティ強化（v2.6.0 Unit 003 R1〜R3 連続指摘 defer）**:
   - **#680**: `skills/aidlc-migrate/scripts/migrate-apply-config.sh::_apply_resource()` の manifest 由来パス（`path` / `dest`）の **トラバーサル検証**未実装。細工された fork の manifest により `AIDLC_PROJECT_ROOT` 配下外（例: `/etc/cron.d/evil`）への書き込みが理論上可能
4. **AI エージェント運用周辺の zsh OOM クラス予防（#688 兄弟バグ / 一般化）**:
   - **#697**: #688（v2.6.1 で `/aidlc v` 経路を CLI モード化で個別解決済）の **根本原因クラス** が AI エージェントの Bash ツール経由の long-text プロンプト構築全般に存在。プロンプト内 backtick / `$(...)` をきっかけに bash がコマンド置換を試み、未定義コマンドへの zsh `command_not_found_handler` 無限再帰で OOM クラッシュ。v2.6.2 Inception Phase 中（codex Round 2 レビュー時）に実発生

## ターゲットユーザー

- **AI-DLC Starter Kit 利用者（consumer プロジェクト開発者）**: Operations Phase の squash 不整合・PR 本文上書き事故・migrate のパストラバーサル懸念から保護される
- **AI-DLC Starter Kit 自体のメタ開発者（本リポジトリ）**: GitHub Projects 連携の冪等性欠落・テストカバレッジ不足を解消し、v2.6.0 Unit 006 で立てた設計約束を完遂する
- **AI エージェント（Claude Code / Codex 等）**: 空ファイル PR 本文上書きや squash と history append の交番ミスといった「AI 操作運用に固有のリスクパターン」を構造的に検出できる

## ビジネス価値

- v2.6.0 で打ち立てた3領域（振り返り分離・marketplace SoT・GitHub Projects）の **設計約束を defer 含めて履行完了** させ、v2.6 系を「機能完成版」として固定する
- Operations Phase のレビュー反映 commit と PR 本文の信頼性を向上し、v2.7.0 以降の振り返り由来 reviewing 改善（#691/#692/#693/#694）に集中できる土台を整える
- aidlc-migrate のセキュリティハードニングにより、信頼境界外の fork 経由でも安全に AI-DLC を利用できる前提を確立する

## 成功基準

- **#677 解消**: Operations §7.12 PR レビュー反映後、`§7.12.5 squash-712` 実行時に `history/operations.md` の unstaged 差分が squash 統合 commit に確実に取り込まれる（案 A: write-history auto-commit 化）、または unstaged 差分が残った状態での squash-712 実行が fail-fast で検出される（案 B: squash-712 側の事前検証）のいずれか **実動作変更を伴う案を必須採用** とする（案 C「手順書 SoT 明示化のみ」は単独採用不可。案 A/B に対する補助ドキュメント変更として併用可）。force push を伴う手動回復手順なしで「Operations 完了 → squash 統合 → push」が 1 commit 構成で完結する。**案 A 採用時の追加成功基準**: デフォルト挙動変更（auto-commit 化）が既存運用スクリプトを non-interactive で破綻させない（`--no-commit` 等の opt-out フラグで従来等価動作を保証）
- **#678 解消**: `operations-release.sh pr-ready --body-file <path>` が **0 バイトファイル / `<path>` 不在** を実行前検証し、`error\tpr-ready:body-file-empty\t<path>` ／ `error\tpr-ready:body-file-missing\t<path>` 等で exit 1 する。REST PATCH fallback 経路（`pr-ready:fallback:rest-patch`）でも同等の検証が行われ、PR 本文が `null` 上書きされない。**判定対象は 0 バイトおよびファイル不在のみ** とし、Issue #678 案 A の「極端に短い本文（warning）」は本サイクルのスコープ外（必要なら別 Issue で defer）
- **#680 解消**: `migrate-apply-config.sh::_apply_resource()` 系で manifest 由来の `path` / `dest` の許容仕様を以下に固定する:
  - **許容形式**: `AIDLC_PROJECT_ROOT` からの **相対パスのみ**（既存 manifest はすべてこの形式のため後方互換）
  - **拒否形式**: (1) `/` で始まる絶対パス、(2) `..` を含むパス、(3) `realpath -m` 解決後に `AIDLC_PROJECT_ROOT` 配下に収まらないパス
  - 拒否時は exit 2（または同等エラー）で停止し、stderr に `error\tmigrate-apply:path-traversal\t<path>` 等を出力
  - macOS BSD `realpath` と GNU `realpath` の挙動差を吸収するクロスプラットフォーム実装（`bin/lib/` 配下に shim を新設、または `realpath -m` の存在確認 + フォールバック）
  - トラバーサル攻撃ケース（`../../../etc/cron.d/evil` / 絶対パス / シンボリックリンク経由）の bats テストが追加される
- **#682 解消**: `bin/gh-project-cli.sh _subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期ロジックが追加され、spec 側 `fields[*].options` と既存 field の options 差分が `bin/lib/gh-project-repo.sh::gh_project_repo_add_field_option` で追加される。dry-run / strict / soft モード対応
- **#683 解消**: `gh` API モックフレームワーク（`bin/tests/gh-project/_helpers.bash` 等）が新設され、`setup-github-project.sh.bats` / `migrate-issue-524.bats` / `probe-github-project.bats` / `audit-github-project.bats` の副作用本体動作テストが追加される。既存 28 件の引数/エラー系テストとの並存
- **#697 解消**: 以下 3 軸が完了する:
  - **規約改訂（必須）**: CLAUDE.md「`$(...)` 絶対禁止」の対象範囲を「コマンド置換全般（`$(...)` および backtick `` ` ``）」「全 Bash ツール呼び出しの引数文字列」に拡張。AI エージェント向け「Bash ツール経由 long-text 渡し時の安全パターン」（一時ファイル + wrapper / `--content-file` / `--body-file` 推奨経路）を明文化
  - **主要スクリプトの推奨経路明示**: `skills/aidlc/scripts/write-history.sh` 等の long-text 受領インターフェースで `--content` ではなく `--content-file` を AI エージェント向け第一推奨に位置付け（既存仕様の SKILL.md / docs 表現更新のみ、スクリプト本体動作は変更しない）
  - **#688 注意書きの一般化**: SKILL.md の `/aidlc v` 経路の zsh OOM 注意書きを「Bash ツール経由のあらゆる外部スクリプト呼び出しに共通する zsh OOM 回避ルール」として一般化
- **回帰なし（判定母集団を明示）**:
  - **CI 必須 checks（確定一覧の参照規約）**: 判定対象の確定一覧は **Repository Settings > Branch protection / Ruleset の現行定義を正（SoT）** とする。Construction Phase 着手時に `gh api repos/ikeisuke/ai-dlc-starter-kit/branches/main/protection` および `gh ruleset list / view` で取得した required check 名のスナップショットを `.aidlc/cycles/v2.6.2/operations/required-checks.md` に列挙し、本サイクル中は当該一覧を判定母集団として固定する
  - **対象 OS / シェル**: macOS（zsh / bash）+ Linux Ubuntu（bash）。WSL / 他ディストリは best-effort
  - **bats / shellcheck**: ローカル `make test` 相当および GitHub Actions 上で全件 pass
- **patch リリース可能**: v2.6.2 タグ付け前提の CHANGELOG / version 更新が完了し、リリース判定がレビュー通過する

## 期限とマイルストーン

- **patch サイクル**: 短期完了を目標（破壊的変更なし）
- **Unit 数: 6 件固定**（Issue 1 件 = 1 Unit のマッピング: #677 / #678 / #680 / #682 / #683 / #697）。v2.6.2 Inception Phase 中（codex Round 2 レビュー時）に #697 を実発生検出により本サイクル中で追加（初版 5 Unit + Inception 中 1 追加 = 6 Unit）。Construction Phase 中の例外的な追加・分割は引き続き Intent 改訂を伴う
- Construction Phase は Unit ごと独立に進める
- Operations Phase で v2.6.2 タグ付け・CHANGELOG 更新・post-merge-sync を経てリリース完了

## 制約事項

- **後方互換性**: patch リリースのため破壊的変更は禁止。すべての変更は default 値による fallback / opt-out 経路を持つこと
- **設計原則準拠**: CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」を遵守。consumer プロジェクトで自然に skip / opt-in できる経路を選ぶ
- **コマンド置換禁止（強化）**: CLAUDE.md「`$(...)` 絶対禁止」の対象を **「`$(...)` および backtick `` ` `` を含むコマンド置換全般」** に拡張（Unit 006 / #697 で本サイクル中に規約改訂）。すべての修正案・サンプルコード・テスト・AI エージェント向け Bash ツール呼び出しでコマンド置換を新規導入しない
- **依存ツール**: dasel v3 / jq / gh CLI / bash / shellcheck / shellharden を前提とする
- **Project / API モック範囲**: #683 の bats モックは `gh project list` / `gh project create` / `gh project field-list` / `gh project item-add` 等の必要 API に限定し、`gh` 全 API のフルモックは構築しない（YAGNI）
- **対象外項目**: v2.6.0 振り返り由来の他項目（#691/#692/#693/#694）、v2.6.0 以前由来の defer / feedback（#679/#684/#685 等）、振り返り Issue 分離検討（#664）、retrospective mirror 自動統合（#621）、振り返り3層検証 skill 化（#652）は本サイクルでは対応しない

## 既存機能影響

本サイクルは patch リリースで、既存利用者に体感される変更を含む。互換性方針と更新範囲を以下に明示する:

### #677 `write-history operations-round` の auto-commit 化（対応案次第で利用者影響あり）

- **変更内容（採用案次第で異なる）**: 案 A（write-history auto-commit 化）採用時は `--mode operations-round` 呼び出しで自動 commit が走る。案 B（squash-712 fail-fast 化）採用時は利用者操作変更なし、エラーメッセージのみ追加。案 C（手順書 SoT 明示化）は実装変更なし
- **互換性方針**: 案 A 採用時は `--no-commit` フラグ等で従来挙動を opt-out 可能とする
- **移行案内**: 採用案に応じて CHANGELOG に詳細を記載
- **更新ドキュメント候補**: `skills/aidlc/scripts/write-history.sh` / `skills/aidlc/scripts/operations-release.sh` / `steps/operations/operations-release.md` / `CHANGELOG.md`

### #678 `pr-ready --body-file` の事前検証追加

- **変更内容**: 0 バイトファイル / 不在の検出。当該条件で exit 1 で停止（極端に短い本文の warning は本サイクル対象外）
- **互換性方針**: 既存の正常系（本文あり）動作には影響なし。空ファイルを意図的に渡していたユーザーへの破壊変更ではあるが、これは本来エラー検出すべき経路
- **移行案内**: CHANGELOG に「pr-ready が空 body-file をエラーで停止するようになった」旨を記載
- **更新ドキュメント候補**: `skills/aidlc/scripts/operations-release.sh` / `CHANGELOG.md`

### #680 / #682 / #683 の影響

- **#680**: 利用者からは透明（trav 検証エラーケースが追加されるのみ）。manifest が `AIDLC_PROJECT_ROOT` 配下のパスのみを使う限り従来通り動作
- **#682**: 利用者からは透明（spec.yaml に新 option を追加して `ensure-fields` 再実行した際に差分追加されるようになる、という機能追加方向）
- **#683**: 利用者からは透明（テスト追加のみ、本体動作変更なし）

### #697 の影響（規約・ドキュメント改訂）

- **変更内容**: CLAUDE.md / SKILL.md / AGENTS.md の規約改訂（backtick 含むコマンド置換全般禁止の明文化、AI エージェント向け安全パターン追記、#688 注意書きの一般化）。スクリプト本体動作は変更しない
- **互換性方針**: 既存ユーザーが backtick を含む Bash 呼び出しを行っていた場合、明示的にハッキング扱いとなる（規約レベル）。技術的なブロックは PreToolUse hook 経由の警告のみで、強制ブロックは追加しない（hook が許可ダイアログ後に実行される制約のため）
- **移行案内**: CHANGELOG に「AI エージェント向け規約 / SKILL.md の zsh OOM 注意書きを一般化」旨を記載
- **更新ドキュメント候補**: `CLAUDE.md` / `AGENTS.md` / `skills/aidlc/SKILL.md` / `skills/aidlc/steps/common/commit-flow.md` / `skills/aidlc/steps/common/review-flow.md` / `skills/write-history/SKILL.md` / `CHANGELOG.md`

### 共通更新範囲

- `CHANGELOG.md` に v2.6.2 セクションを追加し、上記変更を patch 扱いで記載
- `bin/update-version.sh --version v2.6.2` でバージョン更新（v2.6.0 / v2.6.1 リリース時と同経路）

## スコープ確認

### 含まれるもの

- #677 Operations §7.12.5 squash-712 と write-history operations-round の不整合解消（**実動作変更を伴う案 A / B のいずれか必須（A+B 併用可）**。案 C「手順書 SoT 明示化」は単独採用不可、案 A/B に対する補助ドキュメント変更として併用可。採用案決定は Construction の設計レビューに委ねる）
- #678 `pr-ready --body-file` の空ファイル / 不在検証（および REST PATCH fallback 経路の二重防御）。判定対象は **0 バイト / 不在のみ**（極端に短い本文の warning は本サイクル対象外）
- #680 `migrate-apply-config.sh::_apply_resource()` の manifest 由来パスのトラバーサル検証。**許容形式 = `AIDLC_PROJECT_ROOT` からの相対パスのみ**、絶対パス / `..` 含有 / 配下外を拒否（cross-platform `realpath` 対応 + bats 攻撃ケーステスト）
- #682 `bin/gh-project-cli.sh ensure-fields` の field options 差分同期実装（dry-run / strict / soft 対応）
- #683 Unit 006 副作用 bats テスト整備（gh API モックヘルパー + 4 スクリプト本体動作テスト）
- #697 AI エージェント Bash プロンプト経由の zsh OOM クラス予防（規約改訂 + 主要スクリプトの推奨経路明示 + #688 注意書きの一般化）
- 上記 6 件に対応する bats / shellcheck テスト追加・更新（#697 はドキュメント中心のためテスト追加は CLAUDE.md / SKILL.md の lint 通過確認程度）
- v2.6.2 リリース準備（CHANGELOG / version / Milestone / PR）

### 含まれないもの（明示的除外）

- #691 squash-unit.sh の汎用 CI チェックをスキル本体に取り込む設計検討（v2.6.1 時点と同様 v2.7.0 以降へ）
- #694 Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（v2.7.0 振り返り由来項目セットへ）
- #693 reviewing-construction-plan に「実装言語選択 / cross-platform 妥当性」評価軸追加（v2.7.0 へ）
- #692 reviewing-construction-design に「副作用境界 / ドメイン層分離」評価軸追加（v2.7.0 へ）
- #664 振り返り Issue と通常 backlog Issue の分離・可視化方式検討（feature）
- #621 retrospective mirror Issue の自動重複統合 workflow（feature）
- #652 振り返り 3層検証手順の skill 化（feature）
- #679 Construction Phase 1 設計起草前の事前コード Read 工程（v2.6.0 以前由来 feedback）
- #684 audit-github-project.sh spec-conformance 拡張（priority:low、v2.7.0 以降検討）
- #685 Consumer 向け GitHub Projects setup 統合（feature、minor リリースに送る）

## 不明点と質問（Inception Phase中に記録）

[Question] #677 の修正方針は本文「成功基準 / スコープ確認」で確定した制約「**案 A（write-history auto-commit 化）/ 案 B（squash-712 fail-fast 化）のいずれか必須、案 C（手順書 SoT 明示化）は単独採用不可で A/B に対する補助併用のみ可**」のもとで、Construction Phase の設計レビューで A / B / A+B のどれを採用するかを判断する想定でよいか。
[Answer] （Construction Phase で A / B / A+B のいずれかを確定）

[Question] #678 の修正方針は本文で確定した「**案 A（pr-ready 側 body-file 0 バイト / 不在検証）+ 案 B（REST PATCH fallback 経路の二重防御）の両方を本サイクル必須**」とし、**案 C（テンプレ生成 helper 追加）は本サイクル対象外（別 Issue として defer）** で確定する。Construction Phase で再拡張しないこと。
[Answer] 案 A + B を本サイクル必須、案 C は別 Issue で defer（Construction Phase 再拡張不可）

[Question] #680 のクロスプラットフォーム `realpath` 実装は GNU `realpath -m` / BSD `realpath` の挙動差を吸収する shim を `bin/lib/` 配下に用意する方針でよいか。
[Answer] （Construction Phase で設計レビューにて確定）

[Question] #683 の bats モック整備範囲は v2.6.0 Unit 006 計画書の 4 スクリプト（setup/migrate/probe/audit）に限定し、AI モック対象 API は最小限（必要に応じて拡張）でよいか。
[Answer] Issue 推奨範囲を前提とする。Construction Phase で必要なら再検討。

[Question] #697 の対応軸は本文「成功基準」で確定した「規約改訂（必須）+ 主要スクリプトの推奨経路明示 + #688 注意書きの一般化」の 3 軸セットで進める想定でよいか。PreToolUse hook の動作実装（強制ブロック）は本サイクル対象外で、文書化のみとする。
[Answer] 3 軸セットを本サイクル必須。PreToolUse hook の強制ブロック実装は対象外（hook の動作タイミング制約のため）。
