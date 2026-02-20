# ユーザーストーリー

## Epic 1: AI-DLCフェーズのスキル化

**設計判断**: ストーリー1-3は3フェーズのスキル化であり、構造・受け入れ基準が類似するが、各フェーズは独立して完了・リリース可能。共通モジュールは各スキルに独立コピーを持つ方式を想定（スキル間の暗黙的依存を排除するため）。

### ストーリー 1: Inception Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Inception Phaseを `.claude/skills/` スキルとして実行したい
So that リポジトリ固有の `docs/aidlc/prompts/inception.md` に依存せず、グローバルスキルで新規サイクルを開始できる

**受け入れ基準**:
- [ ] `.claude/skills/inception-phase/SKILL.md` が作成され、「start inception」でスキルが呼び出されInception Phaseのステップ1（Intent明確化）が開始される
- [ ] 共通モジュール（rules, review-flow, commit-flow等）がスキル内の `references/` に含まれ、SKILL.md から参照される
- [ ] 既存の `docs/aidlc/prompts/inception.md` を直接読み込んだ場合、ステップ1（Intent明確化）〜ステップ5（PRFAQ作成）の全ステップが実行でき、成果物（intent.md, user_stories.md, units/*.md）が生成される（後方互換）
- [ ] `~/.claude/skills/` にコピーして、`docs/aidlc/` が存在しない別リポジトリから呼び出した場合も、サイクルディレクトリ作成・Intent作成・ユーザーストーリー作成・Unit定義が完了できる
- [ ] スキルが見つからない場合やロードに失敗した場合は、従来のプロンプト読み込み方法へのフォールバック案内が表示される

**技術的考慮事項**:
- `docs/aidlc/bin/` のスクリプト群への依存をどう解決するか（スキルから相対パスで参照 or スクリプトもスキル内に含める）
- SKILL.md の frontmatter で適切なトリガー条件を定義

---

### ストーリー 2: Construction Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Construction Phaseを `.claude/skills/` スキルとして実行したい
So that リポジトリ固有のプロンプトファイルに依存せず、グローバルスキルで設計・実装を進められる

**受け入れ基準**:
- [ ] `.claude/skills/construction-phase/SKILL.md` が作成され、「start construction」でスキルが呼び出されConstruction Phaseが開始される
- [ ] 共通モジュールがスキル内の `references/` に含まれ、SKILL.md から参照される
- [ ] 既存の `docs/aidlc/prompts/construction.md` を直接読み込んだ場合、Phase 1（ステップ1:ドメイン分析、ステップ2:ドメイン設計、ステップ3:設計レビュー）〜Phase 2（ステップ4:論理設計/コード生成、ステップ5:テスト、ステップ6:統合とレビュー）が実行でき、設計成果物（domain-models/, logical-designs/）と実装コードが生成される（後方互換）
- [ ] `~/.claude/skills/` にコピーして、`docs/aidlc/` が存在しない別リポジトリから呼び出した場合も、設計・実装フローが完了できる
- [ ] スキルが見つからない場合は、従来のプロンプト読み込み方法へのフォールバック案内が表示される

**技術的考慮事項**:
- Inception Phaseスキルと共通モジュールの重複管理（各スキルに独立コピーを持つ or 共有スキルとして分離）

---

### ストーリー 3: Operations Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Operations Phaseを `.claude/skills/` スキルとして実行したい
So that リポジトリ固有のプロンプトファイルに依存せず、グローバルスキルでリリース作業を進められる

**受け入れ基準**:
- [ ] `.claude/skills/operations-phase/SKILL.md` が作成され、「start operations」でスキルが呼び出されOperations Phaseが開始される
- [ ] 共通モジュールがスキル内の `references/` に含まれ、SKILL.md から参照される
- [ ] 既存の `docs/aidlc/prompts/operations.md` を直接読み込んだ場合、ステップ0（変更確認）、ステップ1（デプロイ準備）、ステップ2（CI/CD構築）、ステップ3（監視・ロギング戦略）、ステップ4（配布）、ステップ5（バックログ整理と運用計画）、ステップ6（リリース準備: バージョン確認、CHANGELOG更新、PR Ready化、PRマージ）が実行でき、成果物（operations/progress.md, CHANGELOG.md）が生成される（後方互換）
- [ ] `~/.claude/skills/` にコピーして、`docs/aidlc/` が存在しない別リポジトリから呼び出した場合も、リリースフローが完了できる
- [ ] スキルが見つからない場合は、従来のプロンプト読み込み方法へのフォールバック案内が表示される

**技術的考慮事項**:
- push確認ステップ（#196）はストーリー6で定義。Operations Phaseスキルはストーリー6の変更を含んだ `operations.md` をベースに作成する

---

## Epic 2: バグ修正・機能強化

### ストーリー 4: worktree環境でのVCS検出修正
**優先順位**: Must-have
**関連Issue**: #198

As a git worktree環境で作業する開発者
I want to `aidlc-git-info.sh` がworktree環境でもVCSを正しく検出してほしい
So that worktree環境でもAI-DLCの全機能が正常に動作する

**受け入れ基準**:
- [ ] `.worktree/dev` 等のworktree環境で `aidlc-git-info.sh` を実行すると `vcs_type:git` が返される
- [ ] 通常の `.git` ディレクトリ環境でも引き続き `vcs_type:git` が返される
- [ ] jj環境（`.jj` ディレクトリ存在時 かつ jjコマンド利用可能時）は `vcs_type:jj` が返される（既存動作維持）
- [ ] `.git` も `.jj` も存在しない環境では `vcs_type:unknown` が返される（既存動作維持）
- [ ] worktree環境で `.git` がファイル（`gitdir:` 形式）の場合でも正しく検出される

**技術的考慮事項**:
- `detect_vcs()` 関数の `.git` チェックを `-d` から `-e` に変更（ファイル/ディレクトリ両方を検出）
- jjの優先判定（`.jj` + jjコマンド）は変更不要

---

### ストーリー 5: SemVerバリデーション追加
**優先順位**: Must-have
**関連Issue**: #197

As a AI-DLC利用者
I want to `suggest-version.sh` が不正なディレクトリ名を除外してほしい
So that バージョン提案が常に正しいSemVer形式のサイクルのみを基準にする

**受け入れ基準**:
- [ ] `docs/cycles/` に `v1.15.2/`, `vtest/`, `v-temp/` が存在する場合、`latest_cycle` として `v1.15.2` のみが返される
- [ ] SemVer形式: `v` + MAJOR.MINOR.PATCH（各要素は `0` または先頭ゼロなしの正整数、正規表現: `^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`）
- [ ] 既存の正常なサイクルディレクトリ（`v1.0.0/`, `v1.15.2/` 等）の検出に影響しない
- [ ] SemVer形式に一致するディレクトリが1つも存在しない場合、`latest_cycle` は空文字が返される（既存動作維持）

**技術的考慮事項**:
- `get_latest_cycle()` 関数に grep フィルタを追加

---

### ストーリー 6: PRマージ前のリモート同期確認
**優先順位**: Must-have
**関連Issue**: #196

As a AI-DLC利用者
I want to PRマージ前にローカルとリモートの同期状態を確認してほしい
So that 未pushのコミットがある状態でのマージ事故を防止できる

**受け入れ基準**:
- [ ] Operations Phase の 6.6.5（コミット漏れ確認）と 6.7（PRマージ）の間に同期確認ステップ 6.6.6 が追加される
- [ ] `git log origin/{branch}..HEAD` で未pushコミットが検出された場合、マージがブロックされpushを促すメッセージが表示される
- [ ] 未pushコミットがない場合は自動的に次のステップ（6.7 PRマージ）に進む
- [ ] pushコマンド実行後に再確認が行われ、同期完了後にマージに進める
- [ ] リモートブランチが存在しない場合（upstream未設定時）は、pushを実行するよう促すメッセージが表示される
- [ ] `git fetch origin` を実行してからチェックし、リモートの最新状態と比較する

**技術的考慮事項**:
- `operations.md` に新ステップ `6.6.6 リモート同期確認` を追加
- `gh:available` 以外の場合はスキップ可能（手動マージのため）
