---
name: versioning-with-jj
description: jjでバージョン管理操作を実行する。jjが有効化されている環境でgitコマンドの代わりに使用。bookmark移動忘れによる変更漏れ・履歴分断を防ぐワークフローを提供。
argument-hint: [subcommand] [args]
allowed-tools: Bash(jj:*)
---

# Jujutsu (jj)

co-locationモード（Git共存）での使用を前提とする。

## 最重要: bookmarkは自動で進まない

> **Gitとの最大の違い**: jjのbookmarkはコミット時に自動追従しない。手動で移動が必要。

忘れると: 変更がpushに含まれない、サイクル判定（ブランチ名ベース）が壊れる。

## ワークフロー

`cycle/vX.X.X` はサイクルのbookmark名。実行時にブランチ名から取得すること。

### 作業開始

```bash
jj log -r 'all()' --limit 10
jj bookmark list
jj new cycle/vX.X.X
```

**Check**: `jj log -r '@'` で現在位置がcycle bookmarkの子であることを確認。

### コミット（3点セット）

**必ずこの3つをセットで実行する**:

```bash
jj describe -m "feat: [vX.X.X] 変更内容" && jj new && jj bookmark set cycle/vX.X.X -r @-
```

**Check**: `jj log -r 'cycle/vX.X.X | @'` でbookmarkが `@` の親（`@-`）にあることを確認。

**例外**: 既存リビジョンの修正（`jj describe` のみ）やsquash時はこのフローに従わなくてよい。

### push

```bash
jj log -r 'cycle/vX.X.X'
jj git push --bookmark cycle/vX.X.X
```

**Check**: bookmarkが意図したリビジョンを指しているか確認してからpush。古いリビジョンを指している場合は先に `jj bookmark set` で修正。

### 空リビジョンの整理

`jj new` を繰り返すと空リビジョンが蓄積する。

```bash
jj log -r 'empty()'
jj abandon <revision>
```

### 履歴の整理（squash）

小さいリビジョンが散在した場合:

```bash
# 現在のリビジョンの変更を親にまとめる
jj squash

# 特定のリビジョンに変更をまとめる
jj squash --into <revision>
```

squash後はbookmarkの位置がずれる場合がある。**Check**: `jj log -r 'cycle/vX.X.X | @'` で確認。

### トラブルシューティング

**bookmarkが取り残された場合**:

```bash
jj bookmark set cycle/vX.X.X -r @-
```

**どこにいるか分からなくなった場合**:

```bash
jj log -r 'all()' --limit 20
```

**直前の操作を取り消したい場合**:

```bash
jj undo
```

## 参考リンク

- [jj 公式ドキュメント](https://martinvonz.github.io/jj/latest/)
- [Git comparison](https://martinvonz.github.io/jj/latest/git-comparison/)
- Git/jjコマンド対照表・詳細ガイド: [references/jj-support.md](references/jj-support.md)
