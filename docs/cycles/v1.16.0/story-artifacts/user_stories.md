# ユーザーストーリー

## Epic 1: AI-DLCフェーズのスキル化

### ストーリー 1: Inception Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Inception Phaseを `.claude/skills/` スキルとして実行したい
So that リポジトリ固有の `docs/aidlc/prompts/inception.md` に依存せず、グローバルスキルで新規サイクルを開始できる

**受け入れ基準**:
- [ ] `.claude/skills/inception-phase/SKILL.md` が作成され、スキル呼び出しでInception Phaseが開始される
- [ ] 共通モジュール（rules, review-flow, commit-flow等）がスキル内の `references/` に含まれる
- [ ] 既存の `docs/aidlc/prompts/inception.md` を読み込む方法でも従来通り動作する（後方互換）
- [ ] `~/.claude/skills/` にコピーして、別リポジトリから呼び出した場合も正常に動作する

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
- [ ] `.claude/skills/construction-phase/SKILL.md` が作成され、スキル呼び出しでConstruction Phaseが開始される
- [ ] 共通モジュールがスキル内の `references/` に含まれる
- [ ] 既存の `docs/aidlc/prompts/construction.md` を読み込む方法でも従来通り動作する（後方互換）
- [ ] `~/.claude/skills/` にコピーして、別リポジトリから呼び出した場合も正常に動作する

**技術的考慮事項**:
- Inception Phaseスキルと共通モジュールの重複管理

---

### ストーリー 3: Operations Phaseスキル化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Operations Phaseを `.claude/skills/` スキルとして実行したい
So that リポジトリ固有のプロンプトファイルに依存せず、グローバルスキルでリリース作業を進められる

**受け入れ基準**:
- [ ] `.claude/skills/operations-phase/SKILL.md` が作成され、スキル呼び出しでOperations Phaseが開始される
- [ ] 共通モジュールがスキル内の `references/` に含まれる
- [ ] 既存の `docs/aidlc/prompts/operations.md` を読み込む方法でも従来通り動作する（後方互換）
- [ ] `~/.claude/skills/` にコピーして、別リポジトリから呼び出した場合も正常に動作する

**技術的考慮事項**:
- Operations Phaseスキルには #196 のpush確認ステップも含める

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
- [ ] jj環境（`.jj` ディレクトリ存在時）の検出に影響しない

**技術的考慮事項**:
- `detect_vcs()` 関数の `.git` チェックを `-d` から `-e` に変更、または `git rev-parse` を使用

---

### ストーリー 5: SemVerバリデーション追加
**優先順位**: Must-have
**関連Issue**: #197

As a AI-DLC利用者
I want to `suggest-version.sh` が不正なディレクトリ名を除外してほしい
So that バージョン提案が常に正しいSemVer形式のサイクルのみを基準にする

**受け入れ基準**:
- [ ] `docs/cycles/` に `v1.15.2/`, `vtest/`, `v-temp/` が存在する場合、`latest_cycle` として `v1.15.2` のみが返される
- [ ] `vX.Y.Z` 形式（X, Y, Z は非負整数）以外のディレクトリ名がフィルタリングされる
- [ ] 既存の正常なサイクルディレクトリ（`v1.0.0/` 等）の検出に影響しない

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
- [ ] Operations Phase の 6.6.5（コミット漏れ確認）と 6.7（PRマージ）の間に同期確認ステップが追加される
- [ ] `git log origin/{branch}..HEAD` で未pushコミットが検出された場合、マージがブロックされpushを促すメッセージが表示される
- [ ] 未pushコミットがない場合は自動的に次のステップに進む
- [ ] pushコマンド実行後に再確認が行われ、同期完了後にマージに進める

**技術的考慮事項**:
- `operations.md` に新ステップ `6.6.6 リモート同期確認` を追加
