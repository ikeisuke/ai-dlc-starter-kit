# ユーザーストーリー

## Epic: プラグイン環境対応とレビュースキルリファクタリング

### ストーリー 1: パス参照問題の解消
**優先順位**: Must-have

As a AI-DLCスキルのプラグイン利用者
I want to Kiro CLI等のプラグイン環境でスキルが正常に動作する
So that プロジェクトルート構造に依存せず安定してAI-DLCを利用できる

**受け入れ基準**:
- [ ] `grep -r '\.\./\.\.' skills/` の検出結果がゼロ（ただし `scripts/tests/` 配下はメタ開発固有の例外として除外）
- [ ] aidlc-migrate の `migrate-detect.sh` がプラグイン環境（`~/.kiro/skills/`）で正常動作する
- [ ] aidlc-setup のスクリプトがスキルベースディレクトリ相対で動作する
- [ ] スキル間の内部ファイル直接参照（`scripts/`, `steps/`, `templates/`）がゼロ

**技術的考慮事項**:
- Markdownリンクの `../../` はドキュメント参照のため、スキルベース相対に変更
- review-flow.md, rules.md のパス参照修正は Unit 002 の責務（本ストーリーでは対象外）

---

### ストーリー 2: レビュースキルのタイミングベース化
**優先順位**: Must-have

As a AI-DLC開発者
I want to レビュースキルがレビュータイミングに基づいて命名・構成されている
So that どのタイミングでどのレビューが実行されるか一目で分かり、拡張・保守が容易になる

**受け入れ基準**:
- [ ] 旧スキル4つ（reviewing-code/architecture/inception/security）が9つのタイミングベーススキルに再構成されている
- [ ] `marketplace.json` に新スキル名が登録済み、旧スキル名の参照がゼロ
- [ ] `review-flow.md` の CallerContext マッピングが新スキル名で更新されている
- [ ] `rules.md`（`.aidlc/rules.md`）のスキル呼び出し記述が新スキル名に更新されている
- [ ] 各スキルの SKILL.md にタイミング固有のレビュー観点が記載されている
- [ ] reviewing-construction-code が旧 code + security の観点を統合している
- [ ] reviewing-construction-integration が設計乖離・レビュー/テスト実施確認の観点に変更されている

---

### ストーリー 3: レビュー完了条件の修正
**優先順位**: Must-have

As a AI-DLC利用者
I want to レビュー完了がレビュワーの承認に基づいて判定される
So that 作業者側の自己判断で品質ゲートが通過されることがなくなる

**受け入れ基準**:
- [ ] review-flow.md の反復レビューフローがレビュワー承認ベースに変更されている
- [ ] 再レビュー時、レビュワーに修正内容+対応しない理由を提示し、承認/未解消を返す構造になっている
- [ ] レビュワーが承認（LGTM）を返した場合のみ完了となる
- [ ] 一定回数繰り返し or 千日手の場合にユーザーに判断を委ねるフローが維持されている

---

### ストーリー 4: 400行超えMarkdownファイルの分割
**優先順位**: Should-have

As a AIエージェント
I want to ステップファイルが400行以内に収まっている
So that コンテキストウィンドウを効率的に使用でき、応答品質が向上する

**受け入れ基準**:
- [ ] `skills/aidlc/` 配下の `.md` ファイルが全て400行以内（過去cycleアーカイブ・生成物・履歴ファイルは対象外）
- [ ] 分割後のファイル間リンクで既存フローの読み順が追える
- [ ] 分割後ファイルに冒頭ナビゲーション（元ファイルへの参照）がある

**技術的考慮事項**:
- 対象9ファイル: inception/01-setup.md(692行), operations-release.md(628行), sandbox-environment.md(583行), ai-agent-allowlist.md(573行), rules.md(546行), construction/01-setup.md(478行), review-flow.md(439行), commit-flow.md(438行), construction/04-completion.md(416行)

---

### ストーリー 5: migrationスクリプトのエッジケース対応
**優先順位**: Should-have

As a v1からv2への移行ユーザー
I want to 部分移行やリトライが正常に動作する
So that 移行が途中で失敗しても安全に再開できる

**受け入れ基準**:
- [ ] ディレクトリ作成後に中断→再実行で重複ディレクトリが発生しない
- [ ] 一部ファイルコピー後に中断→再実行で欠落やコピー重複が発生しない
- [ ] 失敗後リトライで最終状態が初回成功時と一致する

**前提条件**: Unit 001（パス参照修正）が完了していること

**関連Issue**: #483
