# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.3.5

## 開発の目的

**主目的**: v2.3.4 までに発見された Operations Phase 由来のバグ3件を修正し、復帰判定・リモート同期・PR マージフローの堅牢性を高める。あわせて、設定保存・テンプレート・監査指摘の既知不整合3件（#577 / #578 / #576）を同サイクルで解消し、v2.3.5 を「復帰判定の信頼性 + セットアップ直後の正しいデフォルト + 個人設定の暗黙書き込み防止 + 既知安全な監査指摘の抑制」まで含む統合的な品質強化リリースとする。

1. **#579 Operations復帰判定とマージ前完結ルールの矛盾解消（bugfix）**:
   復帰判定チェックポイント（`release_done` / `completion_done`）が `history/operations.md` の「PR Ready化」「PRマージ」記録に依存しており、記録タイミング（7.8 / 7.13）がステップファイル上の「マージ前完結」設計（7.7までに全記録完了）と矛盾している。結果、AIエージェントが7.12後や7.13後に独自判断でhistory追記を挟み、worktreeに未コミット変更が残る問題が発生する（v2.3.4マージで実例）。
   **採用方針**: **Option A（進捗源移行）**。`operations/progress.md` にステップ7のサブステップ完了フラグを持たせ、復帰判定の参照先をhistoryからprogress.mdに移行する。7.7コミット時点で全判定ソースが確定する構造とし、CI再実行のコストを発生させずに「マージ前完結」境界を7.7のまま維持する。

2. **#574 リモート同期チェックでsquash後のdivergenceを誤検知（bugfix）**:
   Operations Phase開始時のリモート同期チェック（ステップ6a）で、squash後のhistory rewriteによるdivergenceが `git rev-list HEAD..@{u} --count` で behind としてカウントされ、不要な「取り込む / スキップして続行」選択がユーザーに提示される。「取り込む」選択時にはsquash前の状態に戻るリスクがある。
   **採用方針**: 以下3点をまとめて実装する。
   - **(1) merge-base ancestor先行チェック**: `git merge-base --is-ancestor @{u} HEAD` が true（リモートがローカルの祖先）なら up-to-date と判定する
   - **(2) diverged ステータス区別**: divergence検出時は behind ではなく diverged として別ステータスを返し、「force push推奨」メッセージを出す
   - **(3) squash直後の案内（自動push はしない）**: Construction Phase完了時のsquash直後に、diverged が想定される場合のみ `git push --force-with-lease <remote> <branch>` の推奨コマンドを案内として表示する（AIエージェント・スクリプトによる自動実行は行わない）。squash されていない、または既に push 済みの場合は案内を抑制する

3. **#575 operations-release.sh merge-pr がCIチェック未設定リポジトリで失敗（feedback）**:
   CIチェックが設定されていないリポジトリで `merge-pr` を実行すると `checks-status-unknown` エラーで中断し、ユーザーはスクリプトをバイパスするしかない。
   **採用方針**: 以下3点をまとめて実装する。
   - **(a) エラーメッセージ改善**: 「CIチェックが設定されていません。`--skip-checks` でスキップできます」の具体メッセージを表示
   - **(b) `--skip-checks` オプション追加**: `gh pr checks` が `no checks reported` を返すケース（`checks-status-unknown`）限定でバイパスを許可する。failed / pending 等の状態は従来どおりエラーで拒否する（安全側に倒す）
   - **(c) ドキュメント記載**: 更新対象は `skills/aidlc/steps/operations/03-release.md`（`merge-pr` の前提条件・`--skip-checks` の適用条件）と、`--skip-checks` の挙動サマリを `skills/aidlc/guides/merge-pr-usage.md` に追加する（新規ガイド作成、`guides/` 配下に配置）

   **Unit 001-004 実施状況（2026-04-18 時点）**: Unit 001（#579）、Unit 002（#574 (1)(2)）、Unit 003（#575）、Unit 004（#574 (3)）は完了済み。以降は Unit 005-007 として #577 / #578 / #576 を追加実装する。

4. **#577 config.toml.template の ai_author デフォルトが自動検出を阻害（bugfix）**:
   `skills/aidlc-setup/templates/config.toml.template` の `ai_author` がデフォルトで `"Claude <noreply@anthropic.com>"` にハードコードされており、setup 直後から `commit-flow.md` の自動検出フロー（自己認識→環境変数→ユーザー確認）が機能しない。複数 AI ツール（Claude / Codex / Cursor / Kiro 等）を使い分ける開発者で Co-Authored-By が常に Claude になる。
   **採用方針**: template の既定値を空文字 `""` に変更し、あわせて `skills/aidlc/config/config.toml.example` のサンプル値・コメントを「空なら自動検出」と整合させる。既存サイクルの `.aidlc/config.toml` 実ファイルには遡及的変更を加えない（setup 直後の新規プロジェクトのみ新既定が適用される）。

5. **#578 設定保存フローの暗黙書き込みを防止（bugfix）**:
   3 箇所（`steps/inception/01-setup.md` の `rules.git.branch_mode`、`steps/inception/05-completion.md` の `rules.git.draft_pr`、`steps/operations/operations-release.md` の `rules.git.merge_method`）の設定保存フローで、ユーザーが明確に意図していない状態で `.aidlc/config.local.toml` に個人設定が書き込まれるケースがある。`automation_mode=semi_auto` 下で「保存しますか？」がゲート承認扱いされ自動承認されるリスクも残る。
   **採用方針**: 以下3点をまとめて実装する。
   - **(a) インタラクション種別をユーザー選択に明示**: SKILL.md および 3 ステップファイルに「保存しますか？／保存先はどちら？」は常に `AskUserQuestion` 必須（ゲート承認ではない）と明記
   - **(b) デフォルト選択肢を「いいえ（今回のみ使用）」に変更**: 3 箇所の `AskUserQuestion` 選択肢で「いいえ」を Recommended（先頭）配置、「はい（保存する）」は 2 番目
   - **(c) 3 ファイルの設定保存フロー記述を統一フォーマットに揃える**: 質問文・選択肢順序・保存先既定の説明を共通化

6. **#576 suggest-permissions の既知安全な監査指摘を抑制（feature）**:
   `suggest-permissions --review` で毎回同じ指摘（`Bash(bash -n *)` の CRITICAL、`Bash(rm /tmp/aidlc-*)` の HIGH 等）が偽陽性として検出される。これらは実質リスクなしだが毎回手動で判定する必要があり、本当に新しい問題への注意力が削がれる。
   **採用方針**: acknowledged findings 機構を導入する。
   - **(a) 抑制リストの格納先（一意固定）**: `.claude/settings.json` の専用フィールド `suggestPermissions.acknowledgedFindings`（配列）に格納する。エントリ 1 件は `{ pattern, severity, note, acknowledgedAt }` の構造を持つ。ファイル自体はユーザー側で既存のものを使用し、本機能では当該フィールドの読み書きのみを責務とする（新規ファイル作成は責務外）。`pattern` のマッチング方式の詳細（正規表現 / glob / 完全一致のいずれを採用するか）は Construction Phase 設計フェーズで確定する
   - **(b) 既定表示モード（一意固定）**: 抑制された指摘はデフォルトで**非表示**とする。ただし Review 出力末尾に必ず `ℹ N件の既知指摘を抑制しました（詳細は --show-suppressed）` の集約サマリを 1 行表示し、「何かが抑制されている」事実の可視性を保つ。完全非表示は採用しない
   - **(c) 再表示オプション**: `suggest-permissions --review --show-suppressed` で抑制済み指摘も含めて全件表示する
   - **(d) 追加コスト最小化**: 既存の Review モードの主要出力・終了コードは維持し、互換性を壊さない。acknowledged findings エントリが空または当該フィールド未設定の場合は従来通りの出力

## ターゲットユーザー

AI-DLC Starter Kitを使用する開発者およびAIエージェント

## ビジネス価値

- **Operations Phaseの信頼性向上（#579）**: worktreeに未コミット変更が残る問題が解消され、PR マージ後のクリーンアップが不要になる。「マージ前完結」ルールが構造的に保証され、AIエージェントの誤動作を誘発しない
- **リモート同期チェックの精度向上（#574）**: squash後の誤検知が解消され、ユーザーに不要な選択肢を提示せず、誤った「取り込む」操作によるsquash巻き戻しリスクも排除される
- **AI-DLCの適用範囲拡大（#575）**: CIチェック未設定リポジトリ（例: 個人開発・実験リポジトリ）でもAI-DLC Operations Phaseがスムーズに実行できるようになる
- **setup 直後から正しく動く自動検出（#577）**: 複数 AI ツールを併用する開発者でも、Co-Authored-By が実作業者に基づいて付与される。セットアップ直後から既存の自動検出フローが期待通り機能し、手動での `config.toml` 編集が不要になる
- **個人設定の暗黙書き込み防止（#578）**: ユーザーが自覚した上でのみ `config.local.toml` に設定が保存される運用に変わり、`semi_auto` 実行時も意図しない個人設定の上書きを防げる。プロジェクト共有設定（`config.toml`）と個人設定の境界が明確化される
- **監査指摘レビューの効率化（#576）**: suggest-permissions Review モードで既知安全な指摘が毎回手動判定される負担が解消され、本当に新しい問題への注意力が確保される。既存運用フロー（Review 実行 → 指摘対応）と完全互換

## 成功基準

- `#579`:
  - Operations復帰判定が `operations/progress.md` から行われ、復帰判定用のhistory追記が不要となる
  - v2.3.4 で発生した「PR マージ後の未コミット変更」問題が再現しない
  - **後方互換性**: 新形式（v2.3.5以降のサブステップフラグ付き）と旧形式（v2.3.4以前の progress.md / history.md）の両方で復帰判定が成立する。旧サイクルを再開しても従来通りの判定結果が得られる
- `#574`:
  - squash後のリモート同期チェックで誤検知が発生せず、divergence時は `diverged` ステータスとして `behind` と区別して扱われる
  - `diverged` 時のメッセージは `git push --force-with-lease` の推奨のみを案内し、自動実行は行わない
- `#575`:
  - CIチェック未設定リポジトリ（`gh pr checks` が `no checks reported` を返すケース）で `merge-pr --skip-checks` が成功する
  - `--skip-checks` は `checks-status-unknown` 限定で機能し、failed / pending 等の状態では従来どおりエラーで拒否される（安全性を損なわない）
  - エラーメッセージが `--skip-checks` の存在と適用条件を案内する
- `#577`:
  - `skills/aidlc-setup/templates/config.toml.template` の `ai_author` 既定値が `""`（空文字）になっている
  - 同ファイルのコメントが「空なら自動検出」と整合している
  - `skills/aidlc/config/config.toml.example` のサンプル値・コメントが新既定と整合している
  - 新規 setup 直後の `config.toml` で `ai_author` が空のままとなり、`commit-flow.md` の自動検出フローが起動する
- `#578`:
  - 3 箇所（`steps/inception/01-setup.md` / `steps/inception/05-completion.md` / `steps/operations/operations-release.md`）の設定保存フローが統一フォーマットで記述されている
  - 各フローの `AskUserQuestion` で「いいえ（今回のみ使用）」が Recommended（先頭）に配置されている
  - 同フローが `automation_mode=semi_auto` 下でも自動承認されない（常に `AskUserQuestion` 必須）
  - SKILL.md「AskUserQuestion 使用ルール」に上記 3 場面が「ユーザー選択」種別として明記されている
- `#576`:
  - `suggest-permissions --review` 実行時、`.claude/settings.json` の `suggestPermissions.acknowledgedFindings` 配列のエントリに一致する指摘が **デフォルトで非表示** となる
  - Review 出力末尾に `ℹ N件の既知指摘を抑制しました（詳細は --show-suppressed）` の集約サマリが 1 行表示される（N=0 の場合は表示されない）
  - `suggest-permissions --review --show-suppressed` で抑制済み指摘も含めて全件表示できる
  - acknowledged findings エントリが空、または `suggestPermissions.acknowledgedFindings` フィールド未設定の場合は従来通りの出力（集約サマリも表示されない）
  - 既知安全な指摘例（`Bash(bash -n *)` CRITICAL / `Bash(rm /tmp/aidlc-*)` HIGH 等）を `acknowledgedFindings` に追加した場合に実際に非表示化される
- 全Issue共通: AIレビュー（Codex）で問題なく通過。関連する既存テスト・既存フローが破壊されていない

## 期限とマイルストーン

- Inception Phase: 今セッション内で完了（初期 Unit 001-004 定義済み、#576/#577/#578 追加のためバックトラックで Unit 005-007 を追加）
- Construction Phase: Unit単位で順次実装（Unit 001-004 完了済み、Unit 005-007 を追加実装。総数 7）
- Operations Phase: v2.3.5としてリリース

## 含まれるもの（スコープ）

- `skills/aidlc/steps/operations/**` の進捗源移行・フロー調整（#579）
- `skills/aidlc/steps/common/phase-recovery-spec.md` の復帰判定仕様更新（#579）
- `skills/aidlc/steps/operations/index.md` のチェックポイント表更新（#579）
<!-- v2.3.5 Operations Phase で Codex レビュー指摘により取り下げ。new_format パス（固定スロット + GitHub PR 実態確認）の実装ロジック（pr-ready/merge-pr でのスロット更新）が未実装のため、テンプレートに箱だけ置くと次サイクル復帰判定が機能不全になる。#581 として次サイクル送り。 -->
<!-- 取り下げ: - `skills/aidlc/templates/operations_progress_template.md` へのサブステップフラグ追加（#579） -->
- `skills/aidlc/scripts/operations-release.sh` の `verify-git` リモート同期チェック修正（#574 (1)(2)）
- `skills/aidlc/steps/operations/01-setup.md` / 関連ステップのステータス処理追加（#574 (2)）
- `skills/aidlc/steps/construction/**` の squash 完了後の case-by-case 案内（diverged想定時のみ `git push --force-with-lease` 推奨を表示、自動実行はしない）追加（#574 (3)）
- `skills/aidlc/scripts/operations-release.sh` の `merge-pr` サブコマンドへの `--skip-checks` オプション追加（`checks-status-unknown` 限定で有効、failed / pending では拒否）（#575 (b)）
- `merge-pr` のエラーメッセージ・ヘルプテキスト更新（`--skip-checks` の存在と適用条件を案内）（#575 (a)）
- `skills/aidlc/steps/operations/03-release.md` への `merge-pr` 前提条件と `--skip-checks` 適用条件の記載（#575 (c)）
- `--skip-checks` の挙動サマリを `skills/aidlc/guides/merge-pr-usage.md` として新規作成（#575 (c)、Unit 003 で実装済み）
- `skills/aidlc-setup/templates/config.toml.template` の `ai_author` 既定値・コメント更新（#577）
- `skills/aidlc/config/config.toml.example` のサンプル値・コメントを新既定に整合（#577）
- `skills/aidlc/steps/inception/01-setup.md` / `steps/inception/05-completion.md` / `steps/operations/operations-release.md` の設定保存フロー記述を統一フォーマットで書き換え（`AskUserQuestion` 必須化、デフォルト「いいえ」化）（#578 (a)(b)(c)）
- `skills/aidlc/SKILL.md`（または関連ドキュメント）の「AskUserQuestion 使用ルール」に設定保存フロー 3 箇所を「ユーザー選択」種別として明記（#578 (a)）
- `suggest-permissions` Review モードへの acknowledged findings 抑制機構追加（格納先: `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` 配列、既定表示: 非表示＋集約サマリ、`--show-suppressed` で再表示）（#576 (a)(b)(c)(d)）
- v2.3.5 リリース準備（version.txt, CHANGELOG.md, README.md等の更新）

## 含まれないもの（明示的除外）

- `operations_progress_template.md` への固定スロット追加と new_format パス実装完成（#581、次サイクル。v2.3.5 Operations Phase で Codex 指摘を受けスコープ縮小、ユーザー承認済み）
- Construction Phase復帰判定のステップレベル化（#554、別サイクル）
- Inception progress.md のPart/ステップ命名統一（#565、別サイクル）
- config.toml 旧キー自動移行（#573、別サイクル）
- 原始人プロンプト（#568、別サイクル）
- suggest-permissions の格納先ファイル（`.claude/settings.json`）自体の新規作成（既存ユーザー設定ファイルへのフィールド読み書きのみ実装、ファイル不在時は抑制機能をスキップして従来出力）（#576 の境界）
- `pattern` のマッチング方式の詳細（正規表現 / glob / 完全一致のいずれを採用するか）は Construction Phase 設計フェーズで確定する論点として残す（#576 の境界、採用方針 (a) と同文の表現で統一）
- Operations Phaseの大規模リファクタリング（復帰判定以外の構造変更は対象外）
- 既存ワークフローの大幅な再設計

## 既存機能との関連

- **既存機能への影響**:
  - #579: `operations_progress_template.md` の構造変更 → 既存サイクルの `operations/progress.md` フォーマットと後方互換性を確保する必要あり（新サイクルのみ新形式、既存サイクルは触らない運用で対応可能）
  - #574: `verify-git` の出力ステータスに `diverged` が追加される → `01-setup.md` / `03-release.md` の分岐処理追加
  - #575: `merge-pr` のインターフェース拡張（新オプション）→ 既存呼び出しへの影響なし（デフォルト挙動維持）
  - #577: テンプレート・サンプルの既定値変更のみ → 既存プロジェクトの実ファイル（`.aidlc/config.toml`）は触らない。新規 setup 時のみ新既定が適用
  - #578: 3 ステップファイルの設定保存フロー記述書き換え → `automation_mode=semi_auto` 利用者には挙動差が生じる（従来は自動承認されうる場面で `AskUserQuestion` 必須になる）。既存 `.aidlc/config.local.toml` への遡及変更はない
  - #576: suggest-permissions Review モードの出力に抑制表示オプションが追加される → acknowledged findings 未設定時は従来通りの出力（後方互換）
- **依存関係**: `steps/common/phase-recovery-spec.md` と `steps/operations/index.md` の整合性維持（Materialized Binding）。#578 対応時は `SKILL.md`「AskUserQuestion 使用ルール」の分類と 3 ステップファイルの記述が同期している必要あり

## 制約事項

- **メタ開発**: 本プロジェクトは自分自身（AI-DLCスターターキット）を改善しているため、変更は次回セットアップ時から反映される
- **既存サイクルの保護**: `v2.3.4` 以前のサイクルの `operations/progress.md` や `history/operations.md` に遡及的な変更を加えない（読み取り時の互換性は担保）
- **CI再実行コスト**: #579 の対策で 7.8 以降にコミットを増やさない（GitHub Actions の再実行を避ける）
- **コード品質基準**: `.aidlc/rules.md` の「コマンド置換（`$()`）使用禁止」を遵守する
- **レビュー必須**: `review_mode=required`、`review_tools=['codex']` のためCodexによるレビューを全Unitで実施

## 不明点と質問（Inception Phase中に記録）

[Question] なし（方針確定済み）
[Answer] -
