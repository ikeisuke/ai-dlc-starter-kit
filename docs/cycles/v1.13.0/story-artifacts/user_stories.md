# ユーザーストーリー

## Epic 1: Inception Phase品質向上

### ストーリー 1: Inception PhaseでのAIレビュー
**優先順位**: Must-have
**関連Issue**: #154

As a AI-DLC開発者
I want to Inception PhaseでIntent・ユーザーストーリー・Unit定義をAIレビューしたい
So that 上流工程での品質を担保し、下流での手戻りを削減できる

**受け入れ基準**:
- [ ] Intent作成後にAIレビューが実行される
- [ ] ユーザーストーリー作成後にAIレビューが実行される
- [ ] Unit定義後にAIレビューが実行される
- [ ] review-flow.mdと同様のフローが適用される
- [ ] `[rules.mcp_review].mode`設定が共用される

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`の各ステップ完了時にレビューフローを追加
- Inception固有のレビュー観点（目的の妥当性、INVEST原則、分割の適切さ等）を明記

---

### ストーリー 2: Intent明確化の深掘り強化
**優先順位**: Must-have
**関連Issue**: #154

As a AI-DLC開発者
I want to Intent明確化で目的・背景・制約をより詳細にヒアリングしたい
So that 曖昧な要件のまま設計に進むことを防げる

**受け入れ基準**:
- [ ] Intent明確化での質問項目が具体化されている
- [ ] 目的・背景・制約・スコープについて深掘り質問がある
- [ ] 曖昧な回答に対して追加質問を促すガイダンスがある

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`のステップ1を強化

---

### ストーリー 3: 受け入れ条件の厳格化
**優先順位**: Must-have
**関連Issue**: #154

As a AI-DLC開発者
I want to ユーザーストーリーの受け入れ条件を厳格にチェックしたい
So that 曖昧な条件によるテスト漏れや認識齟齬を防げる

**受け入れ基準**:
- [ ] 受け入れ条件のチェック観点がプロンプトに明記されている
- [ ] 曖昧な条件（「適切に」「正しく」等）を指摘するガイダンスがある
- [ ] 具体的で検証可能な条件への書き換え例が示されている

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`のステップ3を強化

---

## Epic 2: Issue管理プロセス改善

### ストーリー 4: Issueライフサイクル管理の明文化
**優先順位**: Must-have
**関連Issue**: #28

As a AI-DLC開発者
I want to 各フェーズでIssueをどう扱うかを明確に知りたい
So that 何をいつやるかが明確になり、Issueの取り扱いに迷わない

**受け入れ基準**:
- [ ] Inception PhaseでのIssue取り扱いが明記されている（対応Issue選択、ラベル付け）
- [ ] Construction PhaseでのIssue取り扱いが明記されている（進捗更新）
- [ ] Operations PhaseでのIssue取り扱いが明記されている（クローズ）
- [ ] 各フェーズのプロンプトにIssue管理セクションが追加されている

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`に追記

---

### ストーリー 5: PRマージ時の自動クローズ
**優先順位**: Must-have
**関連Issue**: #28

As a AI-DLC開発者
I want to PRマージ時に関連Issueが自動クローズされるようにしたい
So that Issueの閉じ忘れを防げる

**受け入れ基準**:
- [ ] PR作成時に「Closes #XX」を含めるガイダンスがある
- [ ] ドラフトPR作成時のテンプレートに関連Issue記載欄がある
- [ ] Operations PhaseのPRマージ手順に自動クローズの説明がある

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`のドラフトPR作成部分を修正
- `prompts/package/prompts/operations.md`のPRマージ部分を修正

---

### ストーリー 6: ラベル・マイルストーン活用
**優先順位**: Should-have
**関連Issue**: #28

As a AI-DLC開発者
I want to Issueのステータスをラベルで管理したい
So that Issue一覧で進捗状況が一目でわかる

**受け入れ基準**:
- [ ] ステータスラベル（in-progress, blocked等）の定義がある
- [ ] ラベル付与タイミングがプロンプトに明記されている
- [ ] label-cycle-issues.shがステータスラベルにも対応している（または別スクリプト）

**技術的考慮事項**:
- ラベル定義をドキュメント化
- 必要に応じてスクリプト追加・修正

---

## Epic 3: リリースプロセス改善

### ストーリー 7: Operations Phaseにversion.txt更新ステップ追加
**優先順位**: Must-have
**関連Issue**: #158

As a AI-DLCスターターキット開発者
I want to リリース時にversion.txt更新が漏れないようにしたい
So that バージョン番号の不整合を防げる

**受け入れ基準**:
- [ ] Operations Phaseのステップ6（リリース準備）にversion.txt更新が明記されている
- [ ] version.txtとdocs/aidlc.tomlのstarter_kit_versionの両方を更新する手順がある
- [ ] AI-DLCスターターキット自体のリリース時のみ適用される条件分岐がある

**技術的考慮事項**:
- `prompts/package/prompts/operations.md`のステップ6に追記
- `project.name = "ai-dlc-starter-kit"`の場合のみ実行

---

## Epic 4: バグ修正

### ストーリー 8: label-cycle-issues.shのラベル付け漏れ修正
**優先順位**: Must-have
**関連Issue**: #148

As a AI-DLC開発者
I want to label-cycle-issues.shが対象Issueを漏れなくラベル付けしてほしい
So that サイクルに関連するIssueが正しく追跡できる

**受け入れ基準**:
- [ ] ラベル付け漏れの原因が特定されている
- [ ] バグが修正されている
- [ ] 修正後のテストでラベル付けが正しく動作することを確認

**技術的考慮事項**:
- `prompts/package/bin/label-cycle-issues.sh`のデバッグ・修正

---

## Epic 5: 機能削除

### ストーリー 9: Dependabot PR確認機能の削除
**優先順位**: Must-have
**関連Issue**: #96

As a AI-DLCスターターキット開発者
I want to Dependabot PR確認機能を削除したい
So that メンテナンスコストを削減し、コードベースをシンプルに保てる

**受け入れ基準**:
- [ ] inception.mdからDependabot PR確認ステップが削除されている
- [ ] check-dependabot-prs.shが削除されている
- [ ] aidlc.tomlテンプレートから[inception.dependabot]セクションが削除されている
- [ ] 関連ドキュメントが更新されている

**技術的考慮事項**:
- `prompts/package/prompts/inception.md`から該当セクション削除
- `prompts/package/bin/check-dependabot-prs.sh`削除
- `prompts/setup/templates/aidlc.toml.template`から設定削除
