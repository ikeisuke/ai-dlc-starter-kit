## 8b. cycles git管理外オプション案内

**実行条件**: Gitリポジトリ内である場合のみ実行する（`git rev-parse --is-inside-work-tree 2>/dev/null` が `true`）。

`.aidlc/config.toml` から `rules.cycle.git_tracked` の値を確認する（AIがReadツールで読み取り、該当キーを探す）。

`git_tracked` が `false` の場合、`.gitignore` に `.aidlc/cycles/` が既に記載されているか確認:

```bash
grep -q '.aidlc/cycles/' .gitignore 2>/dev/null
```

- **既に記載済み**: 案内をスキップ
- **未記載**: 以下の案内メッセージを表示（自動変更は行わない）:

```text
ℹ rules.cycle.git_tracked = false が設定されています。
.aidlc/cycles/ ディレクトリをGit管理外にするには、.gitignore に以下を追加してください:

  .aidlc/cycles/

※ 既に追跡済みのファイルは自動的にはuntrackされません。
  必要に応じて git rm --cached -r .aidlc/cycles/ を実行してください。
```

`git_tracked` が `true`（デフォルト）または読み取り失敗: 案内をスキップ。

## 9. Git コミット

セットアップで作成・更新したすべてのファイルをコミット:

```bash
git add .aidlc/
# AIツール設定が作成されている場合のみ追加
[ -f ".claude/settings.json" ] && git add .claude/
```

**コミットメッセージ**（モードに応じて選択）:
- **初回**: `git commit -m "feat: AI-DLC初回セットアップ完了"`
- **アップグレード**: `git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"`
- **移行**: `git commit -m "chore: AI-DLC新ファイル構成に移行"`

---

## 10. 完了メッセージと次のステップ

### 初回セットアップの場合

```text
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

プロジェクト設定:
- .aidlc/config.toml - プロジェクト設定
- .aidlc/rules.md - プロジェクト固有ルール

AIツール設定:
- .claude/settings.json - Claude Code許可設定
```

### アップグレードの場合

#### マージ後フォローアップ

> **適用条件**: 本セクションは **アップグレードフロー（ケースC）でのみ実行** する。初回セットアップ・移行ケースでは実行しない。`chore/aidlc-v<version>-upgrade` 形式の一時ブランチが作成されたアップグレード走行で、PR をマージした直後の状態整理を案内する。

実行順序は次に固定する:

1. マージ確認ガード（ユーザー意思の確認）
2. 未コミット差分ガード（HEAD 同期前に tracked 差分を解消）
3. HEAD 同期案内（`origin/main` の最新コミットに HEAD を揃える）
4. 一時ブランチ削除案内（HEAD 同期後にのみ実行）

順序の根拠: §9 完了直後の HEAD は `chore/aidlc-v<version>-upgrade` をチェックアウト中であり、git 制約により現在のチェックアウトブランチを `git branch -d|-D` で削除できない。HEAD 同期で `chore/...` から離脱した後にのみ削除を提案する。

**全体の前提**:

- 各ステップは `AskUserQuestion` を用いた **オプトイン** とし、同意がない限り破壊的操作を行わない
- 本フローは破壊的 git 操作（HEAD 移動 / ブランチ削除 / リモート push）を含むため、`automation_mode` に関わらず対話必須（aidlc-setup は現状 `automation_mode` を参照しないが、フォワード互換のため明記）

##### 1. マージ確認ガード

`AskUserQuestion` で次の選択肢を提示する（**1 回のみ**）:

| 選択肢 | 動作 |
|--------|------|
| はい（マージ済み） | 後続の 2〜4 を連続提示 |
| いいえ（未マージ） | 本マージ後フォローアップを終了し、下記「アップグレード完了メッセージ」へ進む |
| 判断保留 | 本マージ後フォローアップを終了し、下記「アップグレード完了メッセージ」へ進む |

質問文例: 「`/aidlc-setup` で作成したアップグレード PR をマージしましたか？」 / `header: "マージ確認"`

「いいえ」「判断保留」選択時はローカル / リモートいずれも変更しない。

##### 2. 未コミット差分ガード

**事前確認**: `git status --porcelain` を実行し、出力を行ごとに分類する。

| 出力パターン | 判定 | 動作 |
|-------------|------|------|
| 出力空 | 差分なし | ステップ 3（HEAD 同期）へ進行 |
| 全行が `??` プレフィックス | untracked のみ | 注意喚起メッセージを表示し、ステップ 3 へ進行（continued） |
| `??` 以外を含む（tracked 差分あり） | tracked 差分あり | 下記「差分解消の案内」を提示 |

untracked のみの場合の注意喚起例: 「ℹ untracked ファイルが検出されました。HEAD 同期は続行しますが、続行前に必要に応じて手動で確認してください」。

**差分解消の案内（tracked 差分検出時のみ）**: `AskUserQuestion` で次の選択肢を提示する（`header: "差分解消"`）。

| 選択肢 | 動作 |
|--------|------|
| 中止（既定） | 本マージ後フォローアップを終了し、「アップグレード完了メッセージ」へ進む |
| stash で退避 | AI エージェントが `git stash push`（tracked のみ退避）を実行。**事前に実行コマンドをユーザーに提示**。`-u`（untracked 含む）は採用しない（untracked のみは続行する設計と整合させ、ユーザー意図しない untracked 退避を防ぐため）。untracked が残った状態で続行する場合は注意喚起のみ → 再検査へ |
| commit する | AI エージェントが `git add -A && git commit -m "<message>"` を実行（`<message>` はユーザー入力 or 既定文言。`-m` 指定によりエディタ起動を回避し非対話実行を保証）→ 再検査へ |

**再検査ループ**: stash / commit 選択後、`git status --porcelain` を再実行して tracked 差分が解消されたことを確認する。**最大 3 回まで再検査します（解消が見込めない場合は中止扱いで離脱）**。再検査の上限は AI エージェントが内部管理し、ユーザー入力が要因で解消が進まない場合は安全側で中止する（疲労閾値 + 無限ループ防止）。

##### 3. HEAD 同期案内

`AskUserQuestion` で次の選択肢を提示する（`header: "HEAD同期"`）。

| 選択肢 | 動作 |
|--------|------|
| 同意 | `git fetch origin --prune` を実行し、HEAD 状態を判定して同期コマンドを実行 |
| スキップ | 本マージ後フォローアップを終了し、「アップグレード完了メッセージ」へ進む（一時ブランチ削除も一律スキップ） |

質問文例: 「ローカル HEAD を `origin/main` に同期しますか？（`git fetch origin --prune` を含みます）」

**副作用説明（同意選択肢の description）**: 「現在ブランチが main 以外（`chore/aidlc-v*-upgrade` 含むフィーチャ系）の場合、HEAD は detached 状態に移行します。元のブランチに戻るには `git checkout <branch-name>` を実行してください」。

**`git fetch origin --prune` の副作用注記**: `--prune` はリモートで削除されたブランチに対応するローカル追跡ブランチ（`refs/remotes/origin/...`）を整理します。**ローカルブランチ自体には影響しません**。

**HEAD 同期の実行**: 同意取得後、以下の順序で処理する。

1. `git fetch origin --prune` を実行
2. HEAD 状態を判定（worktree 判定 → main 系判定 → detached 判定の順）:

   ```bash
   # worktree 判定: --git-common-dir と --git-dir を比較
   #   --git-common-dir != --git-dir なら worktree（前者がメインリポジトリの .git、後者が <main>/worktrees/<name>）
   #   --git-common-dir == --git-dir ならメインリポジトリ
   git rev-parse --git-common-dir
   git rev-parse --git-dir

   # 通常ブランチ vs detached HEAD 判定
   #   出力が "main" なら main 系
   #   出力が "main" 以外（例: chore/aidlc-v*-upgrade）なら フィーチャ系
   #   exit code !=0 なら detached HEAD（worktree 軸と独立で単一ケースに集約）
   git symbolic-ref --short HEAD
   ```

3. 5 サブ条件マトリクスに従って同期コマンドを実行:

   | 現在の HEAD 状態 | 検出結果 | 一次選択コマンド | フォールバック |
   |-----------------|----------|----------------|--------------|
   | 通常ブランチ（main 系） | `--git-common-dir` == `--git-dir` AND `symbolic-ref --short HEAD` == `main` | `git pull --ff-only` | ff 不可 → 警告通知 + 一時ブランチ削除スキップ + 完了メッセージへ |
   | 通常ブランチ（フィーチャ系） | `--git-common-dir` == `--git-dir` AND `symbolic-ref --short HEAD` 成功 AND 値 != `main` | `git checkout --detach origin/main` | - |
   | detached HEAD | `symbolic-ref --short HEAD` exit !=0 | `git checkout --detach origin/main` | - |
   | worktree（main 系 checkout） | `--git-common-dir` != `--git-dir` AND `symbolic-ref --short HEAD` == `main` | `git pull --ff-only` | ff 不可 → 警告通知 + 一時ブランチ削除スキップ + 完了メッセージへ |
   | worktree（フィーチャ系 checkout） | `--git-common-dir` != `--git-dir` AND `symbolic-ref --short HEAD` 成功 AND 値 != `main` | `git checkout --detach origin/main` | - |

   **`git -C <worktree-path>` は使用しない**: 現在の作業ディレクトリで直接実行する。

   **`git reset --hard origin/main` は本フローで自動実行しない**: 破壊性のため、ff 不可時は警告通知のみ。

**到達現実性の補足**: `/aidlc-setup` アップグレード走行直後の典型例は「通常ブランチ-フィーチャ系」または「worktree-フィーチャ系」（`chore/aidlc-v<version>-upgrade` チェックアウト中）。「main 系」「detached HEAD」は §9 完了後にユーザーが手動で操作した場合のみ到達する異常経路。

**ff 不可時のユーザー案内例**:

```text
⚠ git pull --ff-only が失敗しました（fast-forward 不可）。HEAD は origin/main に同期されていません。
divergence 状況を確認するには以下を参照してください:
  - git log --oneline HEAD..origin/main  （ローカルに未取得のリモートコミット）
  - git log --oneline origin/main..HEAD  （リモートに未push のローカルコミット）
HEAD 強制同期が必要な場合は手動で git reset --hard origin/main 等を検討してください。
本フローでは破壊的操作を行わず、一時ブランチ削除もスキップします。
```

##### 4. 一時ブランチ削除案内

**事前条件**: HEAD 同期が成功し、HEAD が `chore/aidlc-v<version>-upgrade` から離脱した状態であること。HEAD 同期失敗（ff 不可）または HEAD 同期スキップ時は本ステップを実行しない。

`AskUserQuestion` で次の 3 択を提示する（`header: "ブランチ削除"`）。各選択肢には `description` を添え、push 権限不在ユーザーが「ローカルのみ削除」を選びやすくする。

| 選択肢 | 動作 | description（参考文言） |
|--------|------|----------------------|
| ローカル + リモート両方を削除 | ローカル削除 → リモート削除（push 失敗時 warning + 継続） | リモート push 権限がある場合の標準 |
| ローカルのみ削除 | ローカル削除のみ | push 権限不在のユーザー環境向け。リモートブランチは別途管理者に削除依頼するか、後日 push 権限が確保された時点で再実行 |
| スキップ | 何もせず「アップグレード完了メッセージ」へ進む | 一時ブランチを保持したい場合（後日参照等） |

質問文例: 「アップグレード用一時ブランチ（`chore/aidlc-v<version>-upgrade`）を削除しますか？」

**ローカル削除の実行**:

```bash
# <version> は §9 までで判明している /aidlc-setup のコンテキスト変数から流用
git branch -d chore/aidlc-v<version>-upgrade
```

**ローカル削除失敗時のフォールバック**: `git branch -d` が exit code !=0 で失敗した場合（squash merge / rebase merge 後はマージ判定が外れるため）、`AskUserQuestion` で次の選択肢を提示する（`header: "強制削除確認"`）。

| 選択肢 | 動作 |
|--------|------|
| `-D` で強制削除 | `git branch -D chore/aidlc-v<version>-upgrade` を実行 |
| スキップ | ローカル削除をスキップし、「アップグレード完了メッセージ」へ進む（リモート削除も一律スキップ） |

質問文例: 「`-d` で削除できませんでした（squash/rebase merge の可能性）。`-D` で強制削除しますか？」

**リモート削除の実行**（「ローカル + リモート両方を削除」選択時のみ、ローカル削除成功後）:

```bash
git push origin --delete chore/aidlc-v<version>-upgrade
```

**リモート削除失敗時の動作**: `git push origin --delete` が exit code !=0 で失敗した場合（push 権限なし or リモート不在）、以下の warning を表示して**フローは中断せず継続する**（後続ステップは「アップグレード完了メッセージ」へ進むのみ。本フロー全体としては正常終了として扱う）。

```text
⚠ リモートブランチ削除に失敗しました（push 権限なし or リモート不在の可能性）。ローカル削除のみ完了しています。
```

##### マージ後フォローアップ完了

すべて完了したら下記「アップグレード完了メッセージ」へ進む。

---

```text
AI-DLCのアップグレードが完了しました！

更新されたファイル:
- .aidlc/config.toml - バージョン情報更新
- AIツール設定 - 最新テンプレートに更新

※ .aidlc/config.toml は保持されています（変更なし）

---
**セットアップは完了です。このセッションはここで終了してください。**

新しいセッションで `/aidlc inception` と指示し、サイクルを開始してください。
```

**重要**: アップグレード完了後は、自動で Inception Phase を開始しないでください。ユーザーが新しいセッションで明示的に開始するまで待機してください。

### 移行の場合

```text
AI-DLCの新ファイル構成への移行が完了しました！

移行されたファイル:
| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | .aidlc/config.toml |
| docs/aidlc/prompts/additional-rules.md | .aidlc/rules.md |
| .aidlc/cycles/rules.md | .aidlc/rules.md |
| .aidlc/cycles/operations.md | .aidlc/operations.md |
| docs/aidlc/version.txt | （削除: config.toml に統合） |

これにより、v2のプラグインモデルに移行されました。
```

<!-- AIDLC-PATH: physical-path-required (reason: v1-migration) -->

---

## 次のステップ: サイクル開始

**注意**: このセクションは初回セットアップ・移行の場合のみ表示してください。
- **ケースB（バージョン同じ）**: このセクションは表示せず、自動で `/aidlc inception` を実行する
- **ケースC（アップグレード完了後）**: 上記「アップグレードの場合」のメッセージを表示し、セッションを終了する

### 初回セットアップ・移行の場合

セットアップが完了しました。新しいセッションで `/aidlc inception` と指示し、サイクルを開始してください。

---

## AI-DLC 概要

AI-DLC（AI-Driven Development Lifecycle）は、AIを開発の中心に据えた新しい開発手法です。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **短サイクル反復**: 各フェーズを短いサイクルで反復

**3つのフェーズ**:
1. **Inception**: 要件定義、ユーザーストーリー作成、Unit分解
2. **Construction**: 設計、実装、テスト
3. **Operations**: デプロイ、監視、運用
