# 論理設計: 運用安定化

## 概要

write-historyスキルのパス修正、reviewingスキルのCodex呼び出し統一、post-merge-sync.shのエラーハンドリング改善の具体的な変更内容を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のスキルプラグイン構成・シェルスクリプト構成を維持する局所的修正パターン。新しいアーキテクチャの導入は行わない。

## コンポーネント構成

```text
skills/
├── write-history/
│   └── SKILL.md           ← 修正 #494-1（スクリプトパス修正）
├── aidlc/
│   ├── config/
│   │   └── settings-template.json  ← 修正 #494-2（パーミッション追加）
│   └── scripts/
│       └── write-history.sh        （変更なし、参照先の実体）
├── reviewing-*/
│   └── SKILL.md (×9)      ← 修正 #491（Codexセクション統一）
bin/
└── post-merge-sync.sh     ← 修正 #500（リモートブランチ存在確認追加）
```

## 修正 #494-1: write-history SKILL.mdのスクリプトパス修正

### 問題

SKILL.md内で `scripts/write-history.sh` を参照しているが、write-historyスキルのベースディレクトリ（`skills/write-history/`）には `scripts/` ディレクトリが存在しない。実体は `skills/aidlc/scripts/write-history.sh` にある。

### 依存方向の明確化

write-historyスキルはaidlcスキルに**依存する**委譲スキルである。独自のスクリプトは持たず、aidlcスキルの `scripts/write-history.sh` を呼び出す。

```text
依存方向:
  write-history SKILL.md → aidlcスキルの scripts/write-history.sh
  （write-historyは独立スキルではなく、aidlcスキルへの委譲インターフェース）
```

### 変更内容

1. **冒頭説明文**: `scripts/write-history.sh` の参照を「aidlcスキルの `scripts/write-history.sh`」と明記し、依存方向を明確にする
2. **使用例セクション**: パスはaidlcフロー（呼び出し元）のコンテキストで記述されている。呼び出し元からの相対パスとして正しいため変更不要。ただし、使用例の冒頭にaidlcフローのコンテキストである旨の注記を追加する

## 修正 #494-2: settings-template.jsonへのパーミッション追加

### 変更内容

`skills/aidlc/config/settings-template.json` の `allow` 配列に `"Skill(write-history)"` を追加する。

### 挿入位置

既存のSkillエントリ群（`Skill(aidlc-feedback)` 等）の末尾にアルファベット順で挿入する。

```text
現在のSkillエントリ:
  Skill(aidlc-feedback)
  Skill(aidlc-migrate)
  Skill(aidlc-setup)
  Skill(reviewing-inception-intent)
  ...
  Skill(reviewing-operations-premerge)
  Skill(squash-unit)

追加後:
  ...
  Skill(squash-unit)
  Skill(write-history)    ← 追加
```

## 修正 #491: reviewingスキルのCodex呼び出し統一

### 対象ファイル（9件）

1. `skills/reviewing-construction-code/SKILL.md`
2. `skills/reviewing-construction-design/SKILL.md`
3. `skills/reviewing-construction-integration/SKILL.md`
4. `skills/reviewing-construction-plan/SKILL.md`
5. `skills/reviewing-inception-intent/SKILL.md`
6. `skills/reviewing-inception-stories/SKILL.md`
7. `skills/reviewing-inception-units/SKILL.md`
8. `skills/reviewing-operations-deploy/SKILL.md`
9. `skills/reviewing-operations-premerge/SKILL.md`

### 共通契約（正本 — 9スキル共通の変更仕様）

以下の契約を9スキル全てに同一に適用する。本セクションが正本であり、計画ファイルの「#491共通契約」セクションは本設計への参照として扱う。

#### 変更対象セクション

各SKILL.mdの「実行コマンド」→「Codex」サブセクションのコードブロック1箇所のみ。

#### 変更内容

**変更前**:

```bash
codex exec -s read-only -C . "<レビュー指示>"
```

**変更後**:

```bash
codex exec "<レビュー指示>"
```

#### 変更理由

CLAUDE.mdで定義されている標準的な `codex exec` パターンに統一する。`-s read-only -C .` はcodex CLIのデフォルト動作（プロジェクトディレクトリで実行）と重複しており、明示指定は不要。

#### 変更しない箇所

- セッション継続コマンド（`codex exec resume <session-id> "<指示>"`）— 既に標準パターンと一致
- フロントマターの `allowed-tools: Bash(codex:*)` — codex CLIを使用する点は変わらないため維持
- `compatibility` フィールド — 変更不要
- Claude/Geminiの実行コマンド — 対象外
- セルフレビューモード — 対象外

#### 検証方法

全9件について、変更後のCodexコードブロックが `codex exec "<レビュー指示>"` であることをgrepで一括確認する。

```text
検証コマンド（概念）:
  grep "codex exec" skills/reviewing-*/SKILL.md
  → 全9件が「codex exec "<レビュー指示>"」のみ（-s read-only -C . が残っていないこと）
```

## 修正 #500: post-merge-sync.shのリモートブランチ存在確認

### 変更箇所

`bin/post-merge-sync.sh` の2箇所（`--yes`モード、対話モード）のリモートブランチ削除ループ内に事前存在確認を追加する。

### 処理フロー（変更後）

```text
リモートブランチ削除ループ:
  for each branch:
    1. git ls-remote --exit-code origin "refs/heads/$branch"
       → exit code 2: ref不在（自動削除済み）
       → exit code 0: ref存在
       → その他の非0: システムエラー（認証失敗・通信断等）
    2. ref不在（exit code 2）:
       → echo "skipped:already-deleted:$branch"
       → 次のbranchへ
    3. ref存在（exit code 0）:
       → git push origin --delete "$branch"
       → 成功: echo "deleted:remote:$branch"
       → 失敗: echo "warn:remote-delete-failed:$branch"
                DELETE_FAILED=true
    4. システムエラー（その他の非0 exit code）:
       → echo "warn:remote-check-failed:$branch"
       → DELETE_FAILED=true（安全側に倒す）
       → 次のbranchへ
```

**注**: `git ls-remote --exit-code` はref不在時に exit code 2 を返す。exit code 0 は成功（ref存在）。その他の非0（例: 128）は通信・認証エラーを示す。この区別により、ref不在と外部コマンド障害を正しく分離する。

### 変更パターン（2箇所共通）

```text
変更前:
  if (cd "$PARENT_REPO" && git push origin --delete "$branch" 2>/dev/null); then

変更後:
  ls_remote_exit=0
  (cd "$PARENT_REPO" && git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1) || ls_remote_exit=$?
  if [[ "$ls_remote_exit" -eq 2 ]]; then
      echo "skipped:already-deleted:$branch"
  elif [[ "$ls_remote_exit" -ne 0 ]]; then
      echo "warn:remote-check-failed:$branch"
      DELETE_FAILED=true
  elif (cd "$PARENT_REPO" && git push origin --delete "$branch" 2>/dev/null); then
```

### I/O契約

| 出力パターン | 意味 | 新規/既存 |
|-------------|------|---------|
| `deleted:remote:{branch}` | 削除成功 | 既存（変更なし） |
| `warn:remote-delete-failed:{branch}` | 削除失敗 | 既存（変更なし） |
| `skipped:already-deleted:{branch}` | ref不在（自動削除済み）でスキップ | **新規** |
| `warn:remote-check-failed:{branch}` | ls-remote失敗（認証・通信エラー等） | **新規** |
| `[dry-run] git push origin --delete {branch}` | ドライラン表示 | 既存（変更なし） |

### 終了コード

- `skipped:already-deleted` は `DELETE_FAILED` を設定しない → 終了コード0（正常）
- `warn:remote-check-failed` は `DELETE_FAILED=true` を設定 → 終了コード1（部分失敗）
- 既存の `deleted:remote` / `warn:remote-delete-failed` の動作は変更なし

### 終了コード規約との整合性

- ref不在（exit 2）→ 正常系（`skipped`）: 処理完了扱い（exit 0）。終了コード規約の「処理が完了したら exit 0」に合致
- 通信・認証エラー（その他非0）→ `warn:remote-check-failed` + `DELETE_FAILED=true`: 終了コード規約の「外部コマンド失敗はシステムエラー」に準拠。ただし個別ブランチの失敗であるため、スクリプト全体はpartial-failure（exit 1）として既存の`DELETE_FAILED`メカニズムで処理

### dry-runモードへの影響

dry-runモードは `git push origin --delete` を実行せず `[dry-run]` 表示のみのため、`git ls-remote --exit-code` による事前確認は不要。dry-runブロックは変更しない。

## 非機能要件（NFR）への対応

- **パフォーマンス**: `git ls-remote` の追加呼び出しはブランチ数が通常少数のため影響なし
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 実装上の注意事項

- #494: write-historyスキルのSKILL.md修正では、使用例セクションのパスは呼び出し元コンテキストの記述なので変更不要
- #491: 9ファイルに同一パターンの変更を適用するため、1ファイルを修正後に残り8ファイルに同じ変更を適用
- #500: Issue #500の本文に修正diffが記載済み。そのパターンに従う
- #500: `PARENT_REPO` 変数のコンテキスト（`cd "$PARENT_REPO"`）を維持する

## 不明点と質問（設計中に記録）

なし
