# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.3.5

## 開発の目的

**主目的**: v2.3.4までに発見されたOperations Phase由来のバグ3件を修正し、復帰判定・リモート同期・PRマージフローの堅牢性を高める。

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
   - **(c) ドキュメント記載**: 更新対象は `skills/aidlc/steps/operations/03-release.md`（`merge-pr` の前提条件・`--skip-checks` の適用条件）と、`--skip-checks` の挙動サマリを `skills/aidlc/guides/` 配下に1箇所追加する（`merge-pr` の使い方ガイドのため `guides/` に配置、ファイル名は Construction Phase で確定）

## ターゲットユーザー

AI-DLC Starter Kitを使用する開発者およびAIエージェント

## ビジネス価値

- **Operations Phaseの信頼性向上（#579）**: worktreeに未コミット変更が残る問題が解消され、PR マージ後のクリーンアップが不要になる。「マージ前完結」ルールが構造的に保証され、AIエージェントの誤動作を誘発しない
- **リモート同期チェックの精度向上（#574）**: squash後の誤検知が解消され、ユーザーに不要な選択肢を提示せず、誤った「取り込む」操作によるsquash巻き戻しリスクも排除される
- **AI-DLCの適用範囲拡大（#575）**: CIチェック未設定リポジトリ（例: 個人開発・実験リポジトリ）でもAI-DLC Operations Phaseがスムーズに実行できるようになる

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
- 全Issue共通: AIレビュー（Codex）で問題なく通過。関連する既存テスト・既存フローが破壊されていない

## 期限とマイルストーン

- Inception Phase: 今セッション内で完了
- Construction Phase: Unit単位で順次実装（Unit数は3～4を想定）
- Operations Phase: v2.3.5としてリリース

## 含まれるもの（スコープ）

- `skills/aidlc/steps/operations/**` の進捗源移行・フロー調整（#579）
- `skills/aidlc/steps/common/phase-recovery-spec.md` の復帰判定仕様更新（#579）
- `skills/aidlc/steps/operations/index.md` のチェックポイント表更新（#579）
- `skills/aidlc/templates/operations_progress_template.md` へのサブステップフラグ追加（#579）
- `skills/aidlc/scripts/operations-release.sh` の `verify-git` リモート同期チェック修正（#574 (1)(2)）
- `skills/aidlc/steps/operations/01-setup.md` / 関連ステップのステータス処理追加（#574 (2)）
- `skills/aidlc/steps/construction/**` の squash 完了後の case-by-case 案内（diverged想定時のみ `git push --force-with-lease` 推奨を表示、自動実行はしない）追加（#574 (3)）
- `skills/aidlc/scripts/operations-release.sh` の `merge-pr` サブコマンドへの `--skip-checks` オプション追加（`checks-status-unknown` 限定で有効、failed / pending では拒否）（#575 (b)）
- `merge-pr` のエラーメッセージ・ヘルプテキスト更新（`--skip-checks` の存在と適用条件を案内）（#575 (a)）
- `skills/aidlc/steps/operations/03-release.md` への `merge-pr` 前提条件と `--skip-checks` 適用条件の記載（#575 (c)）
- `--skip-checks` の挙動サマリを `skills/aidlc/guides/` 配下に1箇所追加（ファイル名は Construction Phase で確定、新規作成を許容）（#575 (c)）
- v2.3.5 リリース準備（version.txt, CHANGELOG.md, README.md等の更新）

## 含まれないもの（明示的除外）

- Construction Phase復帰判定のステップレベル化（#554、別サイクル）
- Inception progress.md のPart/ステップ命名統一（#565、別サイクル）
- suggest-permissions: 既知安全な監査指摘の抑制機能（#576、別サイクル）
- write-config.sh デフォルト書き込み防止（#578、別サイクル）
- config.toml.template の ai_author デフォルト変更（#577、別サイクル）
- config.toml 旧キー自動移行（#573、別サイクル）
- 原始人プロンプト（#568、別サイクル）
- Operations Phaseの大規模リファクタリング（復帰判定以外の構造変更は対象外）
- 既存ワークフローの大幅な再設計

## 既存機能との関連

- **既存機能への影響**:
  - #579: `operations_progress_template.md` の構造変更 → 既存サイクルの `operations/progress.md` フォーマットと後方互換性を確保する必要あり（新サイクルのみ新形式、既存サイクルは触らない運用で対応可能）
  - #574: `verify-git` の出力ステータスに `diverged` が追加される → `01-setup.md` / `03-release.md` の分岐処理追加
  - #575: `merge-pr` のインターフェース拡張（新オプション）→ 既存呼び出しへの影響なし（デフォルト挙動維持）
- **依存関係**: `steps/common/phase-recovery-spec.md` と `steps/operations/index.md` の整合性維持（Materialized Binding）

## 制約事項

- **メタ開発**: 本プロジェクトは自分自身（AI-DLCスターターキット）を改善しているため、変更は次回セットアップ時から反映される
- **既存サイクルの保護**: `v2.3.4` 以前のサイクルの `operations/progress.md` や `history/operations.md` に遡及的な変更を加えない（読み取り時の互換性は担保）
- **CI再実行コスト**: #579 の対策で 7.8 以降にコミットを増やさない（GitHub Actions の再実行を避ける）
- **コード品質基準**: `.aidlc/rules.md` の「コマンド置換（`$()`）使用禁止」を遵守する
- **レビュー必須**: `review_mode=required`、`review_tools=['codex']` のためCodexによるレビューを全Unitで実施

## 不明点と質問（Inception Phase中に記録）

[Question] なし（方針確定済み）
[Answer] -
