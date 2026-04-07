# ユーザーストーリー

## Epic: AI-DLCスキル コンテキストサイズ圧縮 Wave 2

### エピック完了条件
- Wave 2実施後の全フェーズ初回ロード対象ファイルのバイト数合計がベースライン計測値から12.5KB以上削減されていること
- 全フェーズ（Inception/Construction/Operations）の `/aidlc` 実行で共通初期化フローが正常完了すること

---

### ストーリー 1: ベースライン計測
**優先順位**: Must-have

As a AI-DLCスキル開発者
I want to Wave 1実施後の現状ファイルサイズを正確に計測する
So that Wave 2の削減効果を定量的に評価できる

**受け入れ基準**:
- [ ] 各フェーズ（Inception/Construction/Operations）の初回ロード対象ファイルごとのバイト数が、ファイルパス・バイト数・フェーズ名を含む表形式で記録されていること
- [ ] フェーズ別合計バイト数が算出されていること
- [ ] 計測結果が `.aidlc/cycles/v2.2.1/requirements/baseline.md` に記録されていること
- [ ] 計測対象ファイル一覧がSKILL.mdの共通初期化フローの読み込み指示と一致していること（対象外ファイルが含まれていないこと）

**技術的考慮事項**:
- 計測対象: SKILL.mdの共通初期化フローで読み込まれるファイル + フェーズステップファイル
- `wc -c` でバイト数を計測

---

### ストーリー 2: rules.md 3階層分割
**優先順位**: Must-have

**変更責務ファイル**: `steps/common/rules.md`（分割元）、`steps/common/agents-rules.md`（統合元）、`SKILL.md`（参照パス更新）

As a AI-DLCスキル利用者
I want to rules.mdが用途別に3ファイルに分割され、フェーズ実行時に必要な部分のみがロードされる
So that 常時ロードされるルールファイルのサイズが削減される

**受け入れ基準**:
- [ ] `rules.md` が `rules-core.md`、`rules-automation.md`、`rules-reference.md` に分割されていること
- [ ] `rules-core.md` がSKILL.mdの共通初期化フロー（ステップ1）で読み込まれること
- [ ] `automation_mode=semi_auto` の場合のみ `rules-automation.md` が読み込まれ、`automation_mode=manual` では読み込まれないこと
- [ ] `rules-reference.md` がステップファイル内の参照指示（例: 「`rules-reference.md`のDepth Level詳細テーブルを参照」）からのみ読み込まれること
- [ ] `agents-rules.md` が削除され、その内容が `rules-core.md` に統合されていること（`grep -r "agents-rules" skills/aidlc/` で旧参照が0件）
- [ ] SKILL.md内の `agents-rules.md` への参照が `rules-core.md` に変更されていること
- [ ] 3ファイル合計バイト数 < 元の `rules.md`(10,891B) + `agents-rules.md`(3,841B) = 14,732B

**技術的考慮事項**:
- セミオートゲートフォールバック条件テーブル → `rules-automation.md`
- スコープ保護ルール → `rules-core.md`（常時必要）
- Depth Level詳細テーブル、設定仕様リファレンス → `rules-reference.md`

---

### ストーリー 3: compaction二重ロード解消
**優先順位**: Must-have

**変更責務ファイル**: `SKILL.md`（ロード指示削除）、`steps/common/session-continuity.md`（ロード指示統一先）

As a AI-DLCスキル利用者
I want to compaction.mdのロード指示が1箇所に統一される
So that compaction復帰時に同一内容が二重にコンテキストを消費しない

**受け入れ基準**:
- [ ] `compaction.md` への Read/参照指示が全ファイルを通じて1箇所のみであること（`grep -r "compaction.md" skills/aidlc/` で1件）
- [ ] compaction復帰時に `automation_mode` が正しく復元されること（compaction.md内のautomation_mode復元手順が変更されていないこと: `diff` でcompaction.md本文が変更なし）
- [ ] 通常起動時（compaction復帰でない場合）に `compaction.md` がロードされないこと

**技術的考慮事項**:
- compaction.md本文は一切変更しない（品質劣化リスクマトリクス「変更禁止」）
- ロード指示の統一先は `session-continuity.md`（コンパクション復帰判定時）が適切

---

### ストーリー 4: フェーズ完了処理の共通化
**優先順位**: Should-have

**変更責務ファイル**: `steps/inception/05-completion.md`(11,135B)、`steps/construction/04-completion.md`(8,276B)、`steps/operations/04-completion.md`(10,311B)

As a AI-DLCスキル開発者
I want to 3フェーズの完了処理の共通部分が1ファイルに抽出されている
So that 完了処理の重複記述が削減される

**受け入れ基準**:
- [ ] 共通完了処理ファイル `steps/common/completion-common.md` が作成されていること
- [ ] 各フェーズのcompletion.mdが「`completion-common.md` を読み込んで実行」の参照形式に変更されていること
- [ ] 共通化後の各フェーズ完了処理が以下の全ステップを実行できること: 履歴記録（`/write-history`）、squash（`squash_enabled=true`時）、Gitコミット、コンテキストリセット提示
- [ ] 各フェーズ固有ステップ（Inception: ドラフトPR作成・意思決定記録、Operations: カスタムワークフロー等）が各completion.mdに残っていること
- [ ] 3ファイル合計バイト数 + completion-common.md < 元の3ファイル合計(29,722B)

**技術的考慮事項**:
- 共通部分: 履歴記録、squash判定・実行、Gitコミット、完了サマリ出力、コンテキストリセット提示
- フェーズ固有部分は各completion.mdに残す

---

### ストーリー 5: review-flow圧縮
**優先順位**: Should-have

**変更責務ファイル**: `steps/common/review-flow.md`(11,945B)

As a AI-DLCスキル利用者
I want to review-flow.mdの遷移テーブルとインラインテンプレートが圧縮されている
So that レビューフロー参照時のコンテキスト消費が削減される

**受け入れ基準**:
- [ ] 遷移判定テーブル（現8行）が条件分岐ロジック（if/else形式）に簡略化されていること
- [ ] `reviewing-common-base.md` に既に含まれるサブエージェント指示テンプレートへの重複参照が削除されていること
- [ ] `review-flow.md` のバイト数が圧縮前(11,945B)より削減されていること
- [ ] 以下の全遷移パターンで圧縮前と同一の遷移先が導出されること: (mode=disabled), (mode=recommend, CLI有, スキル有), (mode=recommend, CLI無, スキル有), (mode=recommend, スキル無), (mode=required, CLI有, スキル有), (mode=required, CLI無, スキル有), (mode=required, スキル無), (semi_auto+recommend)
- [ ] 指摘対応判断フロー（「指摘対応判断フロー」セクション全体）が `diff` で変更なしであること
- [ ] 「AIレビュー指摘の却下禁止」セクションが `diff` で変更なしであること

**技術的考慮事項**:
- review-flow-reference.md(7,438B)は必要時参照のため圧縮優先度は低い
