# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.16.0 - スキル化基盤構築とバグ修正・機能強化

## 開発の目的

AI-DLCの各フェーズプロンプトを `.claude/skills/` 形式のスキルとして再実装し、最終的に `~/.claude/skills/` に配置することでリポジトリ単位のアップデートを不要にする基盤を構築する。併せて、既存シェルスクリプトのバグ修正と Operations Phase の機能強化を行う。

## ターゲットユーザー

- AI-DLC Starter Kit を利用する開発者
- AI-DLC Starter Kit 自体の開発者（メタ開発）

## ビジネス価値

- **スキル化**: フェーズプロンプトをグローバルスキル化することで、リポジトリごとの `docs/aidlc/` 更新が不要になり、運用コストを大幅に削減
- **バグ修正**: worktree環境でのVCS検出バグ解消により、worktree利用者の開発体験を改善
- **機能強化**: SemVerバリデーション追加でバージョン提案の信頼性向上、push確認ステップ追加でマージ事故を防止

## 成功基準

- Inception / Construction / Operations の各フェーズが `.claude/skills/` 形式のスキルとして動作する
- スキル化されたフェーズが `~/.claude/skills/` に配置して正常に動作する（リポジトリ非依存）
- `aidlc-git-info.sh` が git worktree 環境で正しく VCS を `git` と検出する（#198）
- `suggest-version.sh` の `get_latest_cycle()` が不正なバージョン文字列を除外する（#197）
- Operations Phase の PR マージ前にローカル/リモートの差分チェックが実行され、未push時にマージをブロックする（#196）

## 期限とマイルストーン

- 特定の期限なし
- スキル化は段階的に進め、本サイクルでは基盤構築と最低1フェーズのスキル化を目標とする

## 制約事項

- メタ開発構造: `prompts/package/` が編集対象、`docs/aidlc/` は rsync コピーなので直接編集禁止
- スキルは Claude Code の `.claude/skills/` 仕様に準拠する必要がある
- 既存の `docs/aidlc/prompts/` によるフェーズ実行との後方互換性を維持する
- シェルスクリプトは POSIX sh 互換を維持

## 不明点と質問（Inception Phase中に記録）

[Question] 「各フェーズのスキル化」の具体的なスコープは？
[Answer] `.claude/skills/` で再実装し、最終的に `~/.claude/skills/` に配置することでリポジトリ単位のアップデートを不要にする

[Question] #198の再現条件は？
[Answer] worktree環境で `aidlc-git-info.sh` を実行すると VCS が `unknown` と表示される

[Question] #196の期待する動作は？
[Answer] PRマージ処理の前にローカルとリモートの差分を確認し、未プッシュでのマージを防ぐ

## スコープ

### 含まれるもの

- 各フェーズ（Inception / Construction / Operations）の `.claude/skills/` 形式での再実装
- `aidlc-git-info.sh` の worktree 環境での VCS 検出バグ修正（#198）
- `suggest-version.sh` の SemVer バリデーション追加（#197）
- Operations Phase プロンプトへの push 確認ステップ追加（#196）

### 除外されるもの

- セミオートモードの実装（#164）
- GitHub Projects連携（#31）
- 既存プロンプト形式の廃止（後方互換性維持のため残す）
