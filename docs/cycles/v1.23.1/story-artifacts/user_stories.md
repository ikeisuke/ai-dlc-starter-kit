# ユーザーストーリー

## Epic: ドキュメント改善

### ストーリー 1: commit-flow.mdのsquashパス表記明確化
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to commit-flow.mdのsquash --message-fileパス表記が正確である
So that squash実行時にパス指定で混乱しない

**受け入れ基準**:
- [ ] commit-flow.mdのSquash統合フローセクションで、--message-fileのパスが`/tmp/aidlc-squash-msg.XXXXXX`形式のmktempパターン例示であることが明記されている
- [ ] 「コードブロック内のパス表記」注記がcommon/rules.mdのテンポラリファイル規約と整合している
- [ ] 検証方法: `grep -n "message-file" prompts/package/prompts/common/commit-flow.md` で該当箇所を確認

**技術的考慮事項**:
関連Issue: #356

---

### ストーリー 2: READMEに名前付きサイクルの説明を追加
**優先順位**: Must-have

As a AI-DLCスターターキットの新規利用者
I want to READMEに名前付きサイクル（Named Cycle）の説明がある
So that サイクル管理の選択肢を理解し、自プロジェクトに適した方式を選べる

**受け入れ基準**:
- [ ] README.mdに「名前付きサイクル（Named Cycle）」見出しのセクションが追加されている
- [ ] 通常サイクル（vX.X.X形式）と名前付きサイクル（name/vX.X.X形式）の違いが表形式で比較されている
- [ ] `rules.cycle.mode` 設定への参照リンクまたは説明が含まれている
- [ ] 検証方法: `grep -n "Named Cycle\|名前付きサイクル" README.md` で見出しの存在を確認

**技術的考慮事項**:
関連Issue: #355

---

## Epic: バグ修正

### ストーリー 3: aidlc-setup.shのexit code修正
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to aidlc-setup.shがstatus:success時にexit code 0を返す
So that CI/CDやスクリプトからの呼び出しで正常終了を正しく検知できる

**受け入れ基準**:
- [ ] aidlc-setup.shがstatus:successを出力した場合、exit code 0で終了する
- [ ] status:error時はexit code 1で終了する（既存動作維持）
- [ ] dry-runモードでもexit codeが正しく返される（success→0, skip→0, error→1）
- [ ] 不正な引数（未知のオプション）を渡した場合、exit code 1でエラーメッセージを出力する（既存動作維持）
- [ ] サブスクリプト失敗時のexit code: check-setup-type.sh不在/失敗→warn出力して0継続、sync-package.sh失敗→error出力して1終了、migrate-config.sh失敗→error出力して1終了
- [ ] 検証方法: `aidlc-setup.sh --dry-run; echo $?` で exit code 0 を確認

**技術的考慮事項**:
関連Issue: #351。set -eによる意図しない非ゼロ終了がないか調査する。

---

## Epic: プロンプトリファクタリング

### ストーリー 4: Inception Phaseステップ18の削除
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to Inception Phaseからsession-state.md復元チェック（ステップ18）が削除されている
So that 混在していた2つの機能が分離され、利用者がセッション復帰の仕組みを誤解するリスクが低減する

**受け入れ基準**:
- [ ] prompts/package/prompts/inception.mdからステップ18（「セッション状態の復元」見出し）が削除されている
- [ ] 旧ステップ19（進捗管理ファイル確認）以降の番号が繰り上がり、連番が維持されている
- [ ] `grep -n "session-state.md" prompts/package/prompts/inception.md` の結果が「コンテキストリセット対応」セクション（旧ステップ番号の「コンテキストリセット対応【重要】」見出し配下）内の行のみであること。それ以外の行にsession-state.mdへの参照があれば未削除
- [ ] compaction.md内のsession-state.md生成指示が変更されていないこと
- [ ] session-continuity.mdの内容が変更されていないこと

**技術的考慮事項**:
prompts/package/prompts/inception.mdを編集すること（メタ開発ルール）。ストーリー5より先に実施する（ステップ番号変更がストーリー5のセットアップ処理参照に影響しないことを確認するため）。

---

### ストーリー 5: セットアップ処理の責務分類
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to setup-prompt.mdの各セクションが責務ごとに分類されている
So that 次サイクルでのスキル化時に移管範囲が明確で、作業の抜け漏れが防止できる

**受け入れ基準**:
- [ ] setup-prompt.mdの全セクション（セクション0〜10）が「初回セットアップ固有」「アップグレード固有」「共通」のいずれかに分類されている
- [ ] 分類結果がsetup-prompt.md内のコメントまたは別途文書として記録されている
- [ ] 既存のセットアップフロー（初回・アップグレード・サイクル開始・移行）の動作が維持されている
- [ ] 検証方法: setup-prompt.md内の全見出し（`## N.`形式）に対して分類タグが付与されていること。`grep -c "## [0-9]" prompts/setup-prompt.md` のセクション数と分類数が一致

**技術的考慮事項**:
ストーリー4完了後に実施する。setup-prompt.mdは1266行の大型プロンプト。

---

### ストーリー 6: aidlc-setupスキルへの移管計画文書化
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to aidlc-setupスキルへの移管対象と残存項目が文書化されている
So that 次サイクルでの完全スキル化の計画が明確で、見積もりが可能になる

**受け入れ基準**:
- [ ] 移管計画文書がdocs/cycles/v1.23.1/内に作成されている
- [ ] aidlc-setupスキルに移管する機能（アップグレード、rsync同期等）が一覧化されている
- [ ] setup-prompt.mdに残す機能（初回セットアップのプロジェクト情報収集等）が一覧化されている
- [ ] 移管時の技術的課題（初回セットアップとアップグレードの分岐ロジック等）が記載されている
- [ ] 検証方法: 文書内に「移管対象」「残存項目」「技術的課題」の各見出しが存在すること。`grep -c "## " docs/cycles/v1.23.1/requirements/setup-migration-plan.md` で3以上

**技術的考慮事項**:
ストーリー5の分類結果を入力として使用する。
