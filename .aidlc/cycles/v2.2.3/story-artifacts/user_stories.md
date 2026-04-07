# ユーザーストーリー

## Epic: コンテキスト圧縮仕上げ（#519）

### ストーリー 1: session-state.md廃止
**優先順位**: Must-have

As a AI-DLCスキル利用者
I want to session-state.mdの生成・復元ロジックが廃止される
So that セッション継続時の不要なコンテキスト消費が削減され、progress.mdベースの復元に一本化される

**受け入れ基準**:
- [ ] session-continuity.mdからsession-state.mdの生成・復元ロジックが除去される
- [ ] 各フェーズの01-setup.md（inception, construction, operations）からsession-state.md関連の参照が除去される
- [ ] context-reset.mdからsession-state.md生成指示が除去される
- [ ] compaction.mdからsession-state.md参照が除去される
- [ ] progress.mdベースの復元フローが正常に機能する（フォールバックが唯一のパスになる）
- [ ] guides/troubleshooting.mdからsession-state.md関連記述が除去される

**技術的考慮事項**:
session-continuity.md自体は残すが、内容をprogress.mdベースの復元のみに簡略化する。

---

### ストーリー 2: preflight.md圧縮
**優先順位**: Must-have

As a AI-DLCスキル利用者
I want to プリフライトチェックの出力フォーマットが簡略化される
So that 初回ロード時のコンテキスト消費が削減される

**受け入れ基準**:
- [ ] preflight.mdの冗長な説明・コメント・例示が除去される
- [ ] 出力フォーマットが簡潔になる（機能は維持）
- [ ] blocker判定ロジック（手順1-3）は品質劣化リスクマトリクスにより変更しない
- [ ] 計測条件: v2.2.2タグのpreflight.md全文をtiktoken cl100k_baseで計測し、比較元（3,068 tok）から800tok以上削減を達成する

**技術的考慮事項**:
設定値取得のバッチモードや派生ロジック（history_level, markdown_lint解決）の説明を圧縮対象とする。

---

### ストーリー 3: 設定値に応じた条件ロードスキップ
**優先順位**: Must-have

As a AI-DLCスキル利用者
I want to 使用しない設定の場合に関連ファイルのロードがスキップされる
So that 不要なコンテキスト消費が削減される

**受け入れ基準**:
- [ ] `review_mode=disabled` の場合、review-flow.mdとreview-flow-reference.mdのロードがスキップされる
- [ ] `automation_mode=manual` の場合、rules-automation.mdのロードがスキップされる
- [ ] `review_mode!=disabled`（required, recommend等）ではreview-flow系を従来どおりロードする
- [ ] `automation_mode!=manual`（semi_auto等）ではrules-automation.mdを従来どおりロードする
- [ ] 未定義値・不正値では安全側にフォールバックし、ロードする（スキップしない）
- [ ] スキップ対象は`steps/common/`配下の必要時ロードファイルのみ（フェーズステップファイルは対象外）
- [ ] スキップ条件が各ステップファイル内で明確に記述される

**技術的考慮事項**:
不変ルール「ステップファイルの読み込みは省略不可」に抵触しない。対象はステップファイルではなく必要時ロードの共通ファイル。

---

## Epic: SKILL.md構造整理

### ストーリー 4: SKILL.md整形・セクション整理
**優先順位**: Must-have

As a AI-DLCスキル開発者
I want to SKILL.mdのセクション構造が整理・整形される
So that 文書としての可読性が向上し、ハーネス展開時の安定性が高まる

**受け入れ基準**:
- [ ] 見出しはH1（タイトルのみ）、H2（主要セクション）、H3（サブセクション）の3階層のみ使用する
- [ ] 手順文・条件分岐・コマンド例・テーブルの意味変更がないことを差分レビューで確認する
- [ ] 必須セクション（非AIDLCプロジェクトガード、不変ルール、質問と実行の判断基準、承認プロセス、AskUserQuestion使用ルール、ARGUMENTSパーシング、引数ルーティング、共通初期化フロー、制約事項）が全て維持される
- [ ] SKILL.md本文500行以内の制限を維持する

**技術的考慮事項**:
ハーネスバグ（#549）の修正は対象外。文書構造の明確化のみを目的とする。

---

## Epic: バックログ消化

### ストーリー 5: 不要ルール・冗長判定の棚卸し
**優先順位**: Should-have

As a AI-DLCスキル開発者
I want to ステップファイル内の不要・重複ルールが除去される
So that AIエージェントの判断精度が向上し、コンテキスト消費が削減される

**対象範囲**: steps/common/配下のファイル（session-state関連はストーリー1で対応済みのため除外）、steps/{inception,construction,operations}/配下のファイル、guides/配下のファイル

**依存関係**: ストーリー1（session-state.md廃止）完了後に着手する

**受け入れ基準**:
- [ ] 対象ファイルで、以下の基準文書でカバー済みの重複ルールが特定される: rules-core.md、SKILL.md、.aidlc/rules.md（この3文書のみを重複元として判定）
- [ ] 特定された重複ルールが除去される
- [ ] 除去後に既存ワークフローが正常に動作する（レビューフロー、コミットフロー、セッション継続が既存と同じ挙動）

**技術的考慮事項**:
v2.2.2でSTARTER_KIT_DEV判定を廃止した際と同種の作業。session-state関連の除去はストーリー1の責務。

---

### ストーリー 6: adminマージ禁止・auto-merge対応
**優先順位**: Should-have

As a AI-DLCスキル利用者
I want to Operations PhaseのマージフローでCIチェック通過後のauto-mergeが利用できる
So that CIチェックのバイパスが防止され、品質ゲートが強化される

**受け入れ基準**:
- [ ] operations-release.md（ステップ7.13）にauto-merge対応が追加される
- [ ] CIが未完了の場合は`gh pr merge --auto`でauto-merge設定する分岐が追加される
- [ ] CIが完了済みの場合は即時マージ（既存動作維持）
- [ ] 既存のマージ方法選択（通常/Squash/Rebase）は維持される
- [ ] auto-merge未サポート（リポジトリ設定未有効化）時は手動マージ手順へフォールバックし、エラーメッセージと対処を案内する
- [ ] 権限不足またはCLIエラー時はマージを実行せず、原因と手動対応手順を案内する
- [ ] Branch protection rulesの設定手順がガイドに追記される

**技術的考慮事項**:
Operations Phaseの既存マージ条件を緩和しない。auto-mergeは追加オプションとして提供。
