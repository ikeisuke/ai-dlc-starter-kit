# Unit 002 計画: プロンプトへのsquash組み込み

## 概要

Unit完了時の手順にsquashスクリプト呼び出しを組み込み、AIプロンプトの指示に従ってsquash処理が自動的に実行されるようにする。`docs/aidlc.toml` の設定に基づいてsquash有効/無効を判定し、ユーザー確認を経てから実行する。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `prompts/package/prompts/construction.md` | 修正 | squashステップ（ステップ3.5）の追加、ステップ4の修正 |
| `docs/aidlc.toml` | 修正 | `[rules.squash]` セクション追加 |

## 実装計画

### 1. `docs/aidlc.toml` にsquash設定セクション追加

`[rules.linting]` セクションの後（`[rules.size_check]` の前）に追加:

```toml
[rules.squash]
# squash設定（v1.15.0で追加）
# enabled: true | false - Unit完了時にsquashを提案するか（デフォルト: false）
# - true: Unit完了時にsquashステップを実行
# - false: squashステップをスキップ（従来の動作）
enabled = true
```

**デフォルト値**: `false`（既存ユーザーの動作を変更しない）。本プロジェクトでは `true` に設定。

### 2. `prompts/package/prompts/construction.md` の修正

#### 2.1 新ステップ「3.5 Squash（コミット統合）」の挿入

ステップ3（Markdownlint実行）とステップ4（Gitコミット）の間に挿入する。

**インターフェース境界**:

| 責務 | 担当コンポーネント |
|------|-------------------|
| squash有効/無効の判定 | construction.md（`[rules.squash].enabled` 参照） |
| VCS種類の判定 | construction.md（`[rules.jj].enabled` 参照し `--vcs` で渡す） |
| ユーザー確認フロー | construction.md |
| 未コミット変更の中間コミット作成 | construction.md |
| jj bookmark更新 | construction.md |
| 起点コミットの特定 | construction.md（AIがgit log/jj logから判定し `--base` で渡す）。squash-unit.shの自動検出はフォールバック |
| squash実行（reset + commit / jj squash） | squash-unit.sh |
| 最終コミットの作成 | squash-unit.sh（`--message` で受け取ったメッセージで作成） |
| Co-Authored-Byの抽出・引き継ぎ | squash-unit.sh |
| エラーハンドリング・リカバリ情報出力 | squash-unit.sh |

**呼び出し側（construction.md）の保証事項**: squash-unit.sh 呼び出し時点でworking tree / working copyがcleanであること。

**VCS判定の方針**: `[rules.jj].enabled` はAI-DLC全体でVCS種類を決定する正規ソースであり、squashステップもこの慣例に従う。環境との不一致（例: jj未インストール）はsquash-unit.shの事前チェック（`git status` / `jj diff`）で `squash:error:not-a-repository` として検出される。

**処理フロー**:

ユーザー確認を中間コミット作成の**前**に行う。これにより「いいえ」選択時に未コミット変更が残り、ステップ4の従来フロー（`feat:` コミット作成）が正常に動作する。

```text
[ステップ3.5 開始]
    │
    ├─ 1. squash設定確認
    │   docs/aidlc.toml の [rules.squash].enabled を確認
    │   └─ false/未設定 → このステップをスキップ → ステップ4へ
    │
    ├─ 2. VCS種類判定
    │   docs/aidlc.toml の [rules.jj].enabled を確認
    │   ├─ true → vcs=jj
    │   └─ false/未設定 → vcs=git
    │
    ├─ 3. ユーザー確認（中間コミット前に実施）
    │   「中間コミットをsquashしますか？」
    │   ├─ はい → 4に進む
    │   └─ いいえ → ステップ4へ（未コミット変更はステップ4で処理）
    │
    ├─ 4. (はいの場合) 未コミット変更のコミット（中間コミット）
    │   ステップ0〜3で変更されたファイルが未コミットの場合、
    │   中間コミットとして作成
    │   ├─ git: git add <files> && git commit -m "chore: ..."
    │   └─ jj: jj describe -m "chore: ..." && jj new
    │   └─ 未コミット変更なし → スキップ
    │
    ├─ 4.1 clean状態の検証
    │   ├─ git: git status --porcelain が空であること
    │   └─ jj: jj diff --stat が空であること
    │   └─ 空でない場合: 追加のgit add/commitで残りをコミット
    │
    ├─ 5. squash-unit.sh 実行
    │   squash-unit.sh --cycle {{CYCLE}} --unit {NNN} --vcs <vcs> \
    │     --message "feat: [{{CYCLE}}] Unit {NNN}完了 - {Unit名}"
    │   ├─ squash:success → ステップ4をスキップ
    │   ├─ squash:skipped:no-commits → ステップ4へ（スクリプトはコミット未作成）
    │   └─ squash:error → エラー表示、ユーザーに対応を確認
    │
    └─ 6. (jj環境のみ) bookmark更新
        jj bookmark set cycle/{{CYCLE}} -r @-
        （注: squash後 @-=squashed commit, @=working copy のため jj new 不要）
        （注: bookmark名はSetup Phaseで作成済み。未存在時はcreateで作成）
```

**ステップ3.5に記載する内容**:

```markdown
### 3.5 Squash（コミット統合）【オプション】

Unit作業中の中間コミット（レビュー前/反映コミット等）を1つの完了コミットにまとめる。

**設定確認**:

`docs/aidlc.toml` の `[rules.squash].enabled` を確認。
- `true` の場合: 以下の手順を実行
- `false`、未設定の場合: このステップをスキップしてステップ4へ

**VCS種類判定**:

`docs/aidlc.toml` の `[rules.jj].enabled` を確認。
- `true` → `vcs=jj`
- `false`、未設定 → `vcs=git`

**手順**:

1. **ユーザー確認**（中間コミット作成前に実施。「いいえ」選択時に未コミット変更をステップ4に引き継ぐため）:

（text）
中間コミット（レビュー前/反映コミット等）を1つの完了コミットにsquashしますか？

1. はい - squashを実行する（推奨）
2. いいえ - squashをスキップしてステップ4で通常コミットを行う
（/text）

2. **「いいえ」の場合**: ステップ4に進み、通常通りコミットを行う（未コミット変更はステップ4で処理される）

3. **「はい」の場合 - 未コミット変更のコミット**: ステップ0〜3で変更されたファイルが未コミットの場合、中間コミットとして作成:

   - git環境:
   （bash）
   git add <変更ファイル>
   git commit -m "chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

   Co-Authored-By: {ai_author}"
   （/bash）

   - jj環境:
   （bash）
   jj describe -m "chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

   Co-Authored-By: {ai_author}"
   jj new
   （/bash）

   - 未コミット変更がない場合: このステップをスキップ

   **clean状態の検証**（中間コミット後、またはスキップ後）:
   - git: `git status --porcelain` が空であることを確認
   - jj: `jj diff --stat` が空であることを確認
   - 空でない場合: 残りの変更を追加コミット（全ファイルをコミットするまで繰り返す）

4. **squash実行**:

   （bash）
   docs/aidlc/bin/squash-unit.sh --cycle {{CYCLE}} --unit {NNN} \
     --vcs <vcs> --message "feat: [{{CYCLE}}] Unit {NNN}完了 - {Unit名}"
   （/bash）

   - `squash:success` の場合: squash完了。**ステップ4をスキップ**する
   - `squash:skipped:no-commits` の場合: 「squash対象のコミットがありません。ステップ4に進みます。」と表示してスキップ（スクリプトはコミットを作成しないため、ステップ4で `feat:` コミットを作成する）
   - `squash:error` の場合: エラーメッセージと recovery コマンドをユーザーに提示し、対応を確認

5. **(jj環境のみ) bookmark更新**:

   （bash）
   jj bookmark set cycle/{{CYCLE}} -r @-
   （/bash）

   squash後の状態: `@-` = squashedコミット（feat: メッセージ付き）、`@` = working copy（空）。`jj new` は不要。

   **bookmark名**: Setup Phaseで作成済みの `cycle/{{CYCLE}}` を使用する。bookmarkが存在しない場合は `jj bookmark create cycle/{{CYCLE}} -r @-` で作成する。
```

#### 2.2 ステップ4「Gitコミット」の修正

ステップ4の冒頭に、squash実行済みの場合の分岐を追加:

```markdown
**注意**: ステップ3.5でsquashを実行した場合、コミットは既に完了しています。以下の確認のみ行い、新規コミットは作成しません:

（bash）
git status  # または jj status
（/bash）

期待される結果: `nothing to commit, working tree clean`（git）または変更なし（jj）

squashを実行していない場合（ステップ3.5をスキップまたは「いいえ」を選択した場合）は、以下の通常コミット手順を実行:
```

### 3. スクリプトパスの対応

`prompts/package/bin/squash-unit.sh` は `docs/aidlc/bin/squash-unit.sh` として参照される（rsyncコピー）。プロンプト内では `docs/aidlc/bin/squash-unit.sh` パスで記載する。

### 4. スコープ外

- `prompts/setup-prompt.md` のtomlテンプレートへの `[rules.squash]` 追加（別Unit/別サイクルで対応）
- Lite版プロンプトへの反映（Unit 005で検討）

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/construction.md` のUnit完了時必須作業にsquashスクリプト呼び出しを追加
- [ ] git/jj環境の自動判定（`[rules.jj].enabled` 参照）
- [ ] ユーザー確認フロー（squash実行前の確認、スキップ可能）
- [ ] `docs/aidlc.toml` へのsquash設定追加
