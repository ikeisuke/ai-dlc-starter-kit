# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.6.1（patch リリース）

## 開発の目的

v2.6.0 リリース後に検出された **クリティカルバグ・UX 退行・規約一貫性不足・CI ノイズ** を patch リリースで解消し、v2.6 系を安定運用フェーズに移行させる。

具体的には以下を一括で対応する:

1. **致命的バグ修正**: `/aidlc v` を Bash ツールから実行すると zsh `command_not_found_handler` 無限再帰により OOM クラッシュする問題（#688）
2. **UX 退行修正**: `aidlc-feedback` が `gh issue create --web` 必須化により毎回ブラウザを強制起動する問題（#690）
3. **規約一貫性向上**: `.aidlc/config.toml` 読取で AI エージェントが `dasel -f` 等の不正フラグを誤生成する問題に対する `read-config.sh` 経由統一・規約追記（#689）
4. **設計原則準拠**: `squash-unit.sh` の CI 構造チェックスクリプトのハードコードを設定駆動化し、CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則への準拠度を上げる（#687）
5. **CI ノイズ削減**: `cycle/*` ブランチの draft PR で Cycle Phase Completion Check が実行され不要な fail を生む問題のスキップ化（#686）

## ターゲットユーザー

- **AI-DLC Starter Kit 利用者（consumer プロジェクト開発者）**: zsh 環境クラッシュおよびフィードバック起票時のブラウザ強制起動 UX を解消する
- **AI-DLC Starter Kit 自体のメタ開発者**: squash-unit.sh の設計原則準拠度向上、cycle PR 中の CI ノイズ削減により開発効率を改善する
- **AI エージェント（Claude Code / Codex 等）**: `dasel -f` 誤生成リスク低減、`/aidlc v` の安全な呼び出し経路提供により正しい操作経路を確保する

## ビジネス価値

- v2.6.0 で導入した新機能（GitHub Projects 移行基盤、squash-unit.sh CI チェック opt-in 化）を安心して利用できる安定版を提供する
- AI エージェントが安全に operate できる v2.6 系の運用標準を確立する
- v2.6.0 で表面化した規約・設計原則違反を早期解消し、後続サイクル（v2.7.0）の振り返り由来 reviewing 改善（#692/#693/#694）に集中できる土台を整える

## 成功基準

- **#688 解消**: zsh 環境（macOS Darwin）の Claude Code Bash ツール経由（必須サポート経路）で AI-DLC スキルが提供する version 取得操作（`/aidlc v` 相当）を実行した際に、OOM クラッシュが発生せず正常終了し、SKILL.md に安全な呼び出し経路（bash サブプロセス経由 / 専用ラッパー / CLI モード等）が明文化されている。非対象経路: ユーザーが対話シェルで手動 `source` した場合（既知の zsh 補完衝突は SKILL.md の注意書きで案内するに留める）
- **#690 解消**: `/aidlc feedback` 実行時にブラウザが自動起動せず、`--web` 経路の選択優先順位は **設定 > フラグ > 対話** で固定される。非対話環境（非 TTY / CI 等）では常に非 `--web`（直接起票）を採用する。`[rules.feedback].open_in_browser` 設定キー（または等価）の追加と、AI エージェント側で `--web` を付ける条件が一意に決まること
- **#689 解消**: `feedback.md` 等の dasel 直接呼び出しが `read-config.sh` 経由に統一され、`rules-core.md` に dasel CLI v3 制約と禁止フラグ列挙が追記されている
- **#687 解消**: `.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キー（または等価設計）が追加され、`squash-unit.sh` 本体は CI チェックスクリプト名・パスをハードコードしない。設定不在時は既存 3 種（`check-skill-references` / `check-bash-substitution` / `check-test-isolation`）を fallback default として読み込むことで後方互換を維持する
- **#686 解消**: `cycle/*` の draft PR で Cycle Phase Completion Check が GitHub UI 上 skipped 表示になり、`ready_for_review` 遷移時にジョブが実行される。Repository Ruleset で当 check を required にしている場合でも、draft 中の skipped を許容する設定であることをドキュメントで明示する
- **回帰なし（判定母集団を明示）**: 以下の判定対象がすべて green であること
  - **CI 必須 checks（確定一覧の参照規約）**: 判定対象の確定一覧は **Repository Settings > Branch protection / Ruleset の現行定義を正（SoT）** とする。Construction Phase 着手時に `gh api repos/ikeisuke/ai-dlc-starter-kit/branches/main/protection` および `gh ruleset list / view` で取得した required check 名のスナップショットを `.aidlc/cycles/v2.6.1/operations/required-checks.md` に列挙し、本サイクル中は当該一覧を判定母集団として固定する（途中追加された check は v2.6.2 以降で再評価）
  - **対象 OS / シェル**: macOS（zsh / bash）+ Linux Ubuntu（bash）。WSL / 他ディストリは best-effort
  - **draft / ready_for_review 期待状態**: draft 時は `cycle-phase-completion-check` が skipped、それ以外の必須 check は通常実行で green。`ready_for_review` 時は全必須 check が通常実行で green
  - **bats / shellcheck**: ローカル `make test` 相当および GitHub Actions 上で全件 pass
- **patch リリース可能**: v2.6.1 タグ付け前提の CHANGELOG / version 更新が完了し、リリース判定がレビュー通過する

## 期限とマイルストーン

- **patch サイクル**: 短期完了を目標（破壊的変更なし）
- **Unit 数: 5 件固定**（Issue 1 件 = 1 Unit のマッピング）。例外的な追加・分割が必要な場合は Construction Phase で再計画し、Intent 改訂を伴う
- Construction Phase は Unit ごと独立に進める
- Operations Phase で v2.6.1 タグ付け・CHANGELOG 更新・post-merge-sync を経てリリース完了

## 制約事項

- **後方互換性**: patch リリースのため破壊的変更は禁止。すべての変更は default 値による fallback / opt-out 経路を持つこと（特に #687 の設定駆動化）
- **設計原則準拠**: CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」を遵守。consumer プロジェクトで自然に skip / opt-in できる経路を選ぶ（特に #687）
- **コマンド置換禁止**: CLAUDE.md「`$(...)` 絶対禁止」を遵守。すべての修正案・サンプルコード・テストでコマンド置換を新規導入しない
- **依存ツール**: dasel v3 / jq / gh CLI / bash / shellcheck / shellharden を前提とする（既存依存と同じ）
- **対象外項目**: v2.6.0 振り返り由来の他項目（#691/#692/#693/#694）および v2.6.0 以前由来の feedback（#677/#678/#679 等）は本サイクルでは対応しない

## 既存機能影響

本サイクルは patch リリースだが、既存利用者に体感される変更を 2 件含む。互換性方針と更新範囲を以下に明示する:

### #690 `aidlc-feedback` のデフォルト挙動変更（非破壊扱い）

- **変更内容**: feedback 起票デフォルトを `gh issue create --web`（ブラウザ起動）から `gh issue create --body-file ...`（直接起票）へ切替
- **互換性方針**: `[rules.feedback].open_in_browser = true` 設定または明示的 `--web` フラグで従来挙動を再現可能（opt-in で旧経路維持）
- **移行案内**: CHANGELOG に「feedback 起票がデフォルトで非ブラウザ化された」旨と従来挙動の opt-in 手順を記載
- **更新ドキュメント**: `skills/aidlc-feedback/SKILL.md` / `skills/aidlc-feedback/steps/feedback.md` / `CHANGELOG.md`

### #686 Cycle Phase Completion Check の draft skip

- **変更内容**: `cycle/*` の draft PR で当ジョブが skipped 扱いとなる
- **互換性方針**: `ready_for_review` 遷移時には従来通り実行されるため、required ステータスとして利用しているユーザーへの実害なし。Ruleset 側で「skipped を allow」する設定が必要な場合のみ更新案内
- **移行案内**: CHANGELOG に「draft PR で skipped 表示になる」旨と Repository Ruleset 設定の確認案内を記載
- **更新ドキュメント**: `.github/workflows/cycle-phase-completion-check.yml` / `docs/cycle-phase-completion-check-ruleset.md`（存在する場合）/ `CHANGELOG.md`

### #688 / #689 / #687 の影響

- **#688**: 利用者からは透明（呼び出し経路の安全化のみ）。SKILL.md / `scripts/lib/version.sh` の修正に閉じる
- **#689**: 利用者からは透明（既存 `read-config.sh` 経路への統一）。`feedback.md` 等の手順書改訂と `rules-core.md` への規約追記のみ
- **#687**: 設定不在時の既存挙動を完全互換維持（fallback default で従来 3 種をロード）。consumer プロジェクト側に追加設定不要

### 共通更新範囲

- `CHANGELOG.md` に v2.6.1 セクションを追加し、上記変更を patch 扱いで記載
- `bin/update-version.sh --version v2.6.1` でバージョン更新（v2.6.0 リリース時と同経路）

## スコープ確認

### 含まれるもの

- #688 `/aidlc v` の zsh OOM クラッシュ修正（CLI 直接実行モード追加 / ラッパー / SKILL.md 改訂のいずれか / 組合せ）
- #690 `aidlc-feedback` の `--web` デフォルト解除（直接起票を主経路化、`--web` opt-in 化）
- #689 dasel 直接呼び出しの `read-config.sh` 経由統一 + `rules-core.md` への規約追記
- #687 `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化（`[rules.squash.internal_ci_checks]` 等）
- #686 Cycle Phase Completion check の draft PR skip（job レベル `if` 条件）
- 上記 5 件に対応する bats / shellcheck テスト追加・更新
- v2.6.1 リリース準備（CHANGELOG / version / Milestone / PR）

### 含まれないもの（明示的除外）

- #691 squash-unit.sh の汎用 CI チェックをスキル本体に取り込む設計検討（v2.7.0 へ送り）
- #694 Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（v2.7.0 振り返り由来項目セットへ）
- #693 reviewing-construction-plan に「実装言語選択 / cross-platform 妥当性」評価軸追加（v2.7.0 へ）
- #692 reviewing-construction-design に「副作用境界 / ドメイン層分離」評価軸追加（v2.7.0 へ）
- 振り返り由来以外の v2.6.0 以前 feedback / backlog 項目（#677/#678/#679/#680/#683/#684/#685 等）

## 不明点と質問（Inception Phase中に記録）

[Question] #688 の修正方針は実装フェーズで決定する想定でよいか（CLI 直接実行モード追加 / ラッパー追加 / SKILL.md 改訂のうちどれを採用するかは Construction の設計レビューに委ねる）。
[Answer] （Construction Phase で詳細決定）

[Question] #687 の設定キー設計は `[rules.squash.internal_ci_checks].scripts` を Issue で提案された通りに採用してよいか。
[Answer] （Construction Phase で詳細決定。後方互換 fallback として既存 3 種をデフォルトに含める方針は前提）

[Question] #686 の workflow 修正は job レベル `if` 条件追加（案 A）で確定でよいか。
[Answer] Issue 推奨の案 A を前提とする。Construction Phase で必要なら再検討。
