# Intent（開発意図）

## プロジェクト名

AI-DLC v1.18.5 - worktreeメタ開発の同期修正 + プロンプトのissue-onlyモード一貫性強化

## 開発の目的

AI-DLCスターターキットのworktree環境でのメタ開発時に発生するrsync同期漏れを修正し、コンパクション後のセミオートモード引き継ぎを強化し、issue-onlyモード時の不要なローカルバックログ操作を排除する。

## ターゲットユーザー

AI-DLCスターターキットを利用する開発者（自身を含む）

## ビジネス価値

- **メタ開発の信頼性向上**: worktree環境でのupgrade-aidlc.sh実行時に、最新の変更が正しくdocs/aidlc/に反映される（#274）
- **セミオートモードの安定性向上**: コンパクション後もsemi_autoモードが確実に維持され、不要なユーザー確認が発生しない（#273）
- **issue-onlyモードの一貫性確保**: ローカルバックログファイルの不要な作成・探索を排除し、設定に忠実な動作を実現。既存の不要ファイルも削除（#272）

## 成功基準

- **#274**: `.worktree/dev/` で `prompts/package/` のファイルを編集後、`upgrade-aidlc.sh --force` を実行すると、worktree内の最新ファイルが `docs/aidlc/` に反映されること
- **#273**: コンパクション後に `docs/aidlc/bin/read-config.sh rules.automation.mode` が `semi_auto` を返し、AIレビュー合格後の承認ポイントでユーザー確認プロンプトが表示されず自動遷移すること
- **#272**: `backlog.mode=issue-only` 設定時に、プロンプトのバックログ関連ロジックがローカルファイル（`docs/cycles/backlog/`、`docs/cycles/backlog-completed/`）の作成・探索を行わないこと。既存のローカルバックログファイル（`docs/cycles/backlog-completed.md` + `docs/cycles/backlog-completed/` 54ファイル）が削除されていること

## スコープ

### 対象

- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`: worktree環境検出とrsyncソースパスの修正
- `prompts/package/prompts/common/compaction.md`: コンパクション時のsemi_auto引き継ぎ強化
- `prompts/package/prompts/` 配下のバックログ関連ロジック: issue-onlyモード時のローカルファイル操作スキップ
- `docs/cycles/backlog-completed.md` および `docs/cycles/backlog-completed/`: 既存不要ファイルの削除

### 対象外

- 外部プロジェクトでのスキル認識問題（セットアップ側の課題）
- session-titleスキルのWSL2対応（#271）
- GitHub Projects連携（#31）
- Amazon AIDLCリポジトリからのエッセンス取り込み（#218）

## 互換性要件

- worktree以外の通常環境（ブランチ直接チェックアウト）でのupgrade-aidlc.sh動作を変更しない
- `backlog.mode` が `git`、`issue`、`git-only` の場合のバックログ動作は現行通り維持
- セミオートモード以外（`manual`）の承認フローは現行通り維持

## 期限とマイルストーン

特になし（パッチリリース）

## 制約事項

- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集し、rsyncで同期）
- `$()` コマンド置換の使用禁止（プロンプトおよびBash実行）

## 不明点と質問（Inception Phase中に記録）

[Question] session-titleスキルが外部プロジェクトで認識されない問題はスコープに含めるか？
[Answer] スコープ外。このリポジトリではスキルは正しく同期されている。外部プロジェクト側のセットアップの問題。

[Question] #272の既存ローカルバックログファイル削除もスコープに含めるか？
[Answer] 含める。プロンプト修正 + 既存ファイル削除の両方を対応する。
