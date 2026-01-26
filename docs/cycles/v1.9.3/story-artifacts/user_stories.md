# ユーザーストーリー

## Epic: AI-DLC v1.9.3 品質改善

### ストーリー 1: jjドキュメント誤記修正 (#89)
**優先順位**: Must-have

As a jjを使用するAI-DLC利用者
I want to jj-support.mdの記述が正確である
So that jjコマンドを正しく使用できる

**受け入れ基準**:
- [ ] 未追跡ファイルの記述が「自動的に含まれる」から「未追跡のまま（`jj file track`で取り込み）」に修正されている
- [ ] リモートブックマーク表記が `origin/main` から `main@origin` に修正されている

**技術的考慮事項**:
- 対象ファイル: `prompts/package/guides/jj-support.md`

---

### ストーリー 2: codex skill resume説明追加 (#121)
**優先順位**: Should-have

As a codex skillを使用するAI-DLC利用者
I want to resume機能の使い方が明示されている
So that 中断したセッションを継続できる

**受け入れ基準**:
- [ ] codex skillのドキュメントにresume利用方法が記載されている
- [ ] コマンド例が含まれている

**技術的考慮事項**:
- 対象ファイル: `prompts/package/skills/codex/SKILL.md`

---

### ストーリー 3: kiroエージェント設定修正 (#120)
**優先順位**: Should-have

As a KiroCLIを使用するAI-DLC利用者
I want to .kiro/agents/aidlc.jsonの設定が正確である
So that KiroCLIでAI-DLCエージェントを正しく利用できる

**受け入れ基準**:
- [ ] エージェント設定の内容が実際のファイル構成と一致している
- [ ] 必要なリソース参照が正しく設定されている

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/AGENTS.md` 内のKiroCLI設定例

---

### ストーリー 4: アップグレード指示にパス参照追加 (#87)
**優先順位**: Could-have

As a AI-DLCスターターキット開発者（メタ開発）
I want to アップグレード指示にメタ開発用パスが明記されている
So that どのディレクトリを参照すべきか明確にわかる

**受け入れ基準**:
- [ ] アップグレード指示にメタ開発用パス（例: `$(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/`）が記載されている

**技術的考慮事項**:
- 対象ファイル: `prompts/setup-prompt.md` または関連ドキュメント

---

### ストーリー 5: プレリリースバージョン対応 (#88)
**優先順位**: Must-have

As a AI-DLC利用者
I want to init-cycle-dir.shがプレリリースバージョン（例: v2.0.0-alpha.4）を受け入れる
So that 柔軟なバージョン命名でサイクルを作成できる

**受け入れ基準**:
- [ ] `v2.0.0-alpha.4` 形式が受け入れられる
- [ ] `2.0.0` 形式（vなし）が受け入れられる
- [ ] `feature-branch` のような任意の文字列が受け入れられる
- [ ] 空文字のみ拒否される

**技術的考慮事項**:
- 対象ファイル: `prompts/package/bin/init-cycle-dir.sh`
- バージョン形式の正規表現チェックを削除し、空文字チェックのみ残す

---

### ストーリー 6: skillsシンボリックリンク廃止 (#119)
**優先順位**: Must-have

As a AI-DLC利用者
I want to skillsディレクトリがシンボリックリンクでない
So that プロジェクト独自のスキルを追加できる

**受け入れ基準**:
- [ ] `docs/aidlc/skills/` がシンボリックリンクではなく、実ディレクトリになっている
- [ ] セットアップ時にskillsがコピー（rsync）される
- [ ] プロジェクト独自スキルの追加方法がドキュメント化されている

**技術的考慮事項**:
- 対象ファイル: `prompts/setup-prompt.md`
- rsync除外パターンの調整が必要な可能性

---

### ストーリー 7: env-info.shセットアップ情報追加 (#81)
**優先順位**: Should-have

As a AI-DLC利用者
I want to env-info.shがセットアップに必要な情報を一括出力する
So that セットアップ時のコマンド実行回数を減らせる

**受け入れ基準**:
- [ ] `--setup` オプションで追加情報が出力される
- [ ] 出力項目: project.name, backlog.mode, current_branch, latest_cycle
- [ ] 既存の出力（gh, dasel, jj, git）との後方互換性が維持される

**技術的考慮事項**:
- 対象ファイル: `prompts/package/bin/env-info.sh`

---

### ストーリー 8: メタ開発ドキュメント分離 (#117)
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to メタ開発用ドキュメントがユーザー配布パッケージから分離されている
So that ユーザーに不要な情報が配布されない

**受け入れ基準**:
- [ ] `prompts/package/` 内に開発者向け（非ユーザー向け）のドキュメントがない
- [ ] 開発者向けドキュメントは `docs/development/` または別の場所に配置されている
- [ ] rsync同期される内容がユーザー向けのみになっている

**技術的考慮事項**:
- 対象ファイル: `prompts/package/` 配下の調査と整理
