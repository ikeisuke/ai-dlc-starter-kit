# ユーザーストーリー

## Epic: バグ修正・運用品質向上

### ストーリー 1: SKILL.md参照の混同修正（#513）
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to メタ開発時にプラグインキャッシュのSKILL.mdとリポジトリのskills/が正しく区別される
So that 誤編集によるメタ開発効率の低下を防止できる

**受け入れ基準**:
- [ ] メタ開発環境（`STARTER_KIT_DEV`判定時）では、SKILL.md参照先としてリポジトリの`skills/aidlc/SKILL.md`を使用する
- [ ] `~/.claude/plugins/`配下のファイルは編集候補・更新対象・差分比較対象から除外する
- [ ] 既存のデプロイ済みファイル確認（ステップ3: `ls skills/aidlc/SKILL.md`）の動作に影響しない

**技術的考慮事項**:
- 対象: Inceptionセットアップのデプロイ済みファイル確認ロジック
- 関連Issue: #513

---

### ストーリー 2: post-merge-sync.shのエラーハンドリング修正（#512）
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to リモートブランチが自動削除済みの場合でもpost-merge-sync.shが正常終了する
So that PRマージ後のクリーンアップが中断せずに完了する

**受け入れ基準**:
- [ ] リモートブランチが既に削除済み（GitHub側で自動削除）の場合、`git push origin --delete`の失敗をgracefulにハンドリングしexit 0で終了する
- [ ] リモートブランチが存在する場合は従来通り削除処理が実行される
- [ ] ローカルブランチの削除処理に影響しない

**技術的考慮事項**:
- 対象: `bin/post-merge-sync.sh`
- 関連Issue: #512

---

### ストーリー 3: Codex PRリアクション検出追加（#511）
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to PRマージ前レビュー確認（Codex PRレビュー状態判定）でPR本体へのリアクションも検出される
So that レビュー承認判定漏れによるマージ遅延やミスを防止できる

**補足**: Codex PRレビュー状態判定（c判定フロー）は、PRマージ前にCodexボットの承認状態を確認するステップ。現在はIssue Comment（`@codex review`コメント）へのリアクション（c-2）とIssue Commentの本文内容（c-4）で判定しているが、Pull Request Reviewオブジェクト（`gh api repos/{owner}/{repo}/pulls/{PR}/reviews`で取得されるレビュー）へのリアクションは検出対象外。

**受け入れ基準**:
- [ ] Pull Request Reviewオブジェクトに対するCodexボット（`chatgpt-codex-connector[bot]`）の`+1`リアクションが承認として検出される
- [ ] 既存のIssue Commentベースのリアクション検出との併用で動作する（Pull Request Reviewリアクション → Issue Commentリアクション → コメント本文の優先順で判定）
- [ ] いずれのリアクションも存在しない場合はコメント本文での承認判定にフォールバックする

**技術的考慮事項**:
- 対象: `.aidlc/rules.md`のPRマージ前レビューコメント確認セクション
- 関連Issue: #511

---

### ストーリー 4: リモートデフォルトブランチ取り込み確認（#510）
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to Inception開始時にリモートデフォルトブランチとの差分が検出・警告される
So that 古い状態のブランチから新サイクルを開始してしまうリスクを防止できる

**受け入れ基準**:
- [ ] Inception Phase開始時（ブランチ確認ステップ）で、現在のブランチがリモートデフォルトブランチ（`origin/main`）に対してbehindの場合に警告を表示する
- [ ] aheadのみの場合は警告しない（通常の開発状態）
- [ ] 警告はフェーズをブロックしない（ユーザーが続行可能）
- [ ] `git fetch`に失敗した場合（オフライン等）はスキップして続行する

**技術的考慮事項**:
- 対象: `steps/inception/01-setup.md`のブランチ確認ステップ
- 比較対象: `origin/main`（リモートデフォルトブランチ）
- 関連Issue: #510

---

### ストーリー 5: バージョンチェック改善
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to `/aidlc`起動時にスキルとconfig間のバージョン不整合が自動検出・警告される
So that 古いスキルや未更新の設定ファイルを使い続けることによる問題を早期に防止できる

**受け入れ基準**:
- [ ] 設定キーが`rules.version_check.enabled`にリネームされる。新キー優先、新キー未設定時のみ旧キー（`rules.upgrade_check.enabled`）をフォールバック読み取り
- [ ] デフォルト値が`true`に変更され、未設定でもチェックが実行される
- [ ] メタ開発リポジトリ（`STARTER_KIT_DEV`）でもチェックが実行される（スキップ条件廃止）
- [ ] ローカル設定 < スキルの場合: 「`/aidlc setup`を実行して設定を更新してください」と警告
- [ ] スキル < ローカル設定の場合: 「スキル（プラグイン）を最新に更新してください」と警告
- [ ] スキル < リモートの場合: 「スキル（プラグイン）を最新に更新してください」と警告
- [ ] チェックは警告表示のみでフェーズをブロックしない

**技術的考慮事項**:
- 対象: `steps/inception/01-setup.md`のステップ6、`config/defaults.toml`
- 比較対象の3ソース: リモート（GitHub main branch版）、スキル（ローカルプラグインのversion.txt）、ローカル設定（config.tomlのstarter_kit_version）
- 既存の3ソース比較ロジック（ComparisonMode等）を改修して使用

---

### ストーリー 6: skills/直接参照チェック
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to skills/以下のファイルでプロジェクトルート相対パスによる参照違反がCIで自動検出される
So that ファイル参照境界ルール違反のリリース混入を防止し、外部プロジェクトでの動作を保証できる

**受け入れ基準**:
- [ ] `skills/`配下のファイルで禁止参照パターン（`skills/aidlc/`で始まるパス文字列）が検出できる
- [ ] コメント内の参照も検出対象とする（意図的な参照もルール違反のため）
- [ ] 違反検出時にexit 1、違反なしでexit 0を返す
- [ ] GitHub ActionsのCIジョブに追加され、違反時にCIが失敗する

**技術的考慮事項**:
- 実装: 新規スクリプト（仮: `bin/check-skill-references.sh`）、対象拡張子は`.md`, `.sh`, `.toml`
- CI統合: `check-bash-substitution.sh`と同様のGitHub Actionsジョブ形式
- 関連ルール: `.aidlc/rules.md`の「ファイル参照境界ルール」

---

### ストーリー 7: setupスキルの早期判定改修
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to `/aidlc setup`実行時にconfig.tomlが存在してもバージョン不一致ならアップグレードモードに遷移する
So that バージョンチェックで案内された`/aidlc setup`が実際にバージョン更新処理を実行できる

**受け入れ基準**:
- [ ] config.toml存在時、config.tomlの`starter_kit_version`とsetupスキルのversion.txtを比較する
- [ ] バージョンが不一致の場合、アップグレードモードに遷移する（既存の7.3ステップで`starter_kit_version`が更新される）
- [ ] バージョンが一致している場合は従来通り「セットアップ済み」としてInception Phaseに遷移する
- [ ] 初回セットアップ（config.toml未存在）・移行モードの既存動作に影響しない

**技術的考慮事項**:
- 対象: `skills/aidlc-setup/steps/01-detect.md`の早期判定ロジック
- 判定条件はストーリー7自身で完結（config.tomlの`starter_kit_version` vs setupスキルのversion.txt）
