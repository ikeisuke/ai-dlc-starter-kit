# ユーザーストーリー

## Epic: v1→v2移行・品質向上

### ストーリー 1: v1→v2移行コア（#416, #421）
**優先順位**: Must-have

As a v1からのアップグレードユーザー
I want to `/aidlc migrate` を実行してv1環境をv2に自動移行したい
So that 手動でのファイル移動・設定変更なしにv2を利用開始できる

**受け入れ基準**:
- [ ] `/aidlc migrate` 実行後、config.tomlの `[paths].aidlc_dir` が `docs/aidlc` から `.aidlc` に更新される
- [ ] cycles配下のrules.md・operations.md・backlog.mdが `.aidlc/cycles/` 配下に移行される
- [ ] 移行対象ファイルが存在しない場合はスキップされる（エラーにならない）
- [ ] 移行後のファイル内容に含まれるv1パス参照（`docs/aidlc/` 等）が `.aidlc/` 系パスに更新される
- [ ] 既にv2環境の場合、移行不要と判定してスキップする
- [ ] 移行途中で失敗した場合、変更前の状態に復旧できる（バックアップまたはgit restore案内）
- [ ] 移行開始前に対象ファイル一覧と変更内容の確認メッセージが表示される

**技術的考慮事項**:
- 移行スキルは `skills/aidlc/` のステップファイルとして追加（SKILL.mdの引数ルーティングに `migrate` を追加）
- `docs/aidlc/` の実体ファイル操作はスコープ外（rsync管理）

---

### ストーリー 2: v1痕跡のクリーンアップ（#416関連）
**優先順位**: Must-have

As a v2環境のAI-DLC利用者
I want to v1専用のシンボリックリンク・設定ファイルが除去されていてほしい
So that リンク切れエラーが発生せず、不要ファイルが残らない

**受け入れ基準**:
- [ ] `.agents/skills/*` の `docs/aidlc/skills/` へのシンボリックリンクが `skills/` への直接リンクに更新される
- [ ] `.kiro/skills/*` の `docs/aidlc/skills/` へのシンボリックリンクが削除される
- [ ] `.kiro/agents/aidlc.json` の `docs/aidlc/kiro/` へのシンボリックリンクが削除される
- [ ] `.kiro/agents/aidlc-poc.json`（POC用実体ファイル）が削除される
- [ ] `.github/ISSUE_TEMPLATE/` のスターターキット由来テンプレート（backlog.yml, bug.yml, feature.yml, feedback.yml）が削除される
- [ ] Codex CLI起動時に `.agents/skills/` のリンク切れエラーが出力されない

**技術的考慮事項**:
- `/aidlc migrate` の一部として実行される（移行コアと同一コマンドで完了）

---

### ストーリー 3: Kiroエージェント設定のサンプル提供（#416関連）
**優先順位**: Must-have

As a Kiro CLIユーザー
I want to AI-DLCのKiroエージェント設定をコピーして使いたい
So that Kiro CLIでもAI-DLCワークフローを利用できる

**受け入れ基準**:
- [ ] `examples/kiro/agents/` にKiroエージェント設定のサンプルファイル（`aidlc.json`）が配置される
- [ ] サンプルファイルはv2のディレクトリ構造（`skills/`）を前提としたパス参照になっている
- [ ] `examples/kiro/README.md` にコピー手順（コピー先: `~/.kiro/agents/` または プロジェクトの `.kiro/agents/`）が記載される

**技術的考慮事項**:
- Kiro Power正式版がリリースされたらそちらでサポート。現時点ではexamplesとして手動コピー方式

---

### ストーリー 4: Inception完了メッセージの修正（#418）
**優先順位**: Should-have

As a AI-DLC利用者（Claude Code以外のツールを含む）
I want to Inception完了メッセージがツール非依存の表現であってほしい
So that Claude Code以外のツール（Kiro CLI, Codex CLI等）でも正しい次アクション案内を受けられる

**受け入れ基準**:
- [ ] `steps/inception/05-completion.md` のコンテキストリセットメッセージに `/aidlc construction` 等のスキル前提表現が含まれない
- [ ] 「コンストラクション進めて」等のツール非依存な表現、または各ツールの呼び出し方法を併記する形式になっている

---

### ストーリー 5: コンパクション復帰手順の明確化（#419）
**優先順位**: Should-have

As a 長時間セッションで作業するAI-DLC利用者
I want to コンパクション復帰時の手順が明確に定義されていてほしい
So that 復帰後に迷わずフェーズを再開できる

**受け入れ基準**:
- [ ] `steps/common/compaction.md` にコンパクション復帰時のスキル再読み込み手順が具体的に記載される（対象スキル名、読み込み順序を明記）
- [ ] 復帰後、compaction.mdの手順に従って再読み込みを実行すれば、reviewing-*・squash-unit等の依存スキルが利用可能になる
- [ ] 復帰フローの確認手順（「復帰後に `/aidlc construction` を実行し、レビュースキルが呼び出せることを確認」等）が記載される

---

### ストーリー 6: パス参照の抽象化（#420）
**優先順位**: Should-have

As a AI-DLCのメンテナー
I want to ステップファイル内の物理パス直接参照を抽象化したい
So that ディレクトリ構造変更時の修正箇所を最小化できる

**受け入れ基準**:
- [ ] ステップファイル内の `docs/aidlc/` 等の物理パス直接参照が、config.tomlの `[paths]` セクション経由またはスクリプトによる解決に置換される
- [ ] `skills/aidlc/scripts/` 内のスクリプトで物理パス直接参照がある場合も抽象化される
- [ ] 既存のパス解決テスト（`test_resolve_starter_kit_path.sh`）が更新され、新パス解決が検証される

---

### ストーリー 7: `.claude/settings.json` のセットアップ生成（#416関連）
**優先順位**: Should-have

As a AI-DLC利用者
I want to `/aidlc setup` 実行時にパーミッション設定が自動生成されてほしい
So that 手動で `.claude/settings.json` を編集する必要がない

**受け入れ基準**:
- [ ] `/aidlc setup` 実行時に `.claude/settings.json` が生成される
- [ ] 生成される `permissions.allow` には `Bash(skills/aidlc/scripts/*)`, `Bash(skills/*/bin/*)`, `Skill(aidlc)`, `Skill(reviewing-*)`, `Skill(squash-unit)` 等のAI-DLCスキル実行に必要なエントリが含まれる
- [ ] 既存の `.claude/settings.json` がある場合、既存キーを保持しつつAI-DLC必要分をマージする（既存設定を上書きしない）
- [ ] 既存ファイルのJSONが不正（パースエラー）の場合、上書きせず警告メッセージを表示してスキップする
