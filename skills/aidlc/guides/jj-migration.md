# jjスキル移行ガイド

## 概要

v1.21.0で、jj（Jujutsu）サポートはスターターキット本体から削除されました。

jjスキルは今後、独立したskillsリポジトリとして提供される予定です。引き続きjjを使用する場合は、本ガイドに従って移行してください。

### 変更の背景

- スキル管理のマーケットプレイス対応（v1.21.0）に伴い、jjサポートを外部化
- スターターキット本体のスコープをコアワークフローに集中
- jjスキルは独立リポジトリとして、マーケットプレイス経由またはスタンドアロンで利用可能に

## マーケットプレイス方式でのインストール（準備中）

skillsリポジトリの公開後は、以下の手順でインストールできるようになります。

```bash
# skillsリポジトリ公開後に利用可能
claude-plugin install <jj-skills-repo-url>
```

**注意**: skillsリポジトリは現在準備中です。公開時期が確定次第、本セクションを更新します。

## 手動インストール手順

skillsリポジトリが公開されるまで、または手動管理を希望する場合は以下の手順で導入できます。

### 1. ファイルの取得

skillsリポジトリ（公開後）から以下のファイルを取得してください:

- `SKILL.md` - jjスキル定義（versioning-with-jj）
- `references/jj-support.md` - Git/jjコマンド対照表・詳細ガイド

### 2. ディレクトリ配置

プロジェクト内に以下の構成で配置します:

```text
your-project/
└── .claude/
    └── skills/
        └── versioning-with-jj/
            ├── SKILL.md
            └── references/
                └── jj-support.md
```

### 3. Claude Code向けの設定

Claude Codeでスキルとして認識させるには、`.claude/skills/` ディレクトリに配置するだけで有効になります。

スキルの呼び出し名は `versioning-with-jj` です。

## 設定の移行

### `[rules.jj]` セクションの削除

`aidlc.toml` に `[rules.jj]` セクションが残っている場合は、手動で削除してください。

```toml
# 以下のセクションを削除
[rules.jj]
enabled = true
```

**影響**: `[rules.jj]` セクションを削除しても、他の設定には影響ありません。このセクションはjjスキル専用の設定であり、スターターキットの他の機能とは独立しています。

**確認方法**: `migrate-config.sh` を実行すると、`[rules.jj]` が残っている場合に警告が表示されます。

## 参考リンク

- [jj 公式ドキュメント](https://martinvonz.github.io/jj/latest/)
- [jj GitHub リポジトリ](https://github.com/martinvonz/jj)
- skillsリポジトリ（公開後にURLを追加）
