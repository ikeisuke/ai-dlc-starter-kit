# 論理設計: aidlc-setupリネーム

## 概要

`upgrading-aidlc` → `aidlc-setup` リネームの論理設計。ファイル構造の変更とテキスト参照の更新を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

該当なし。リネーム作業のため、新規アーキテクチャパターンの導入はない。

## コンポーネント構成

### 変更対象の構造

```text
prompts/package/skills/
├── aidlc-setup/              ← upgrading-aidlc/ からリネーム
│   ├── SKILL.md              ← 内部参照を更新
│   └── bin/
│       └── aidlc-setup.sh    ← upgrade-aidlc.sh からリネーム

docs/aidlc/skills/
├── aidlc-setup/              ← upgrading-aidlc/ からリネーム（rsyncコピー）
│   ├── SKILL.md
│   └── bin/
│       └── aidlc-setup.sh

.claude/skills/
├── aidlc-setup → ../../docs/aidlc/skills/aidlc-setup  ← シンボリックリンク再作成

.kiro/skills/
├── aidlc-setup → ../../docs/aidlc/skills/aidlc-setup  ← シンボリックリンク再作成
```

### コンポーネント詳細

#### aidlc-setup スキル

- **責務**: AI-DLC環境のセットアップ・アップグレードを実行するスキル
- **依存**: `docs/aidlc.toml`（設定読み込み）、`rsync`（ファイル同期）、`dasel`（TOML操作）
- **公開インターフェース**: `/aidlc-setup` スラッシュコマンド（旧 `/upgrading-aidlc` は v1.19.0 で非推奨化済み、互換エイリアスなしで即時削除）

## スクリプトインターフェース設計

### aidlc-setup.sh

#### 概要

AI-DLCスターターキットのファイル同期とバージョン管理を行うセットアップスクリプト。内部ロジックの変更なし（パス参照は `resolve_script_dir()` で動的解決）。

#### 引数

変更なし（既存の `upgrade-aidlc.sh` と同一）。既存引数仕様:

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| (引数なし) | - | デフォルト動作: `prompts/package/` から `docs/aidlc/` への rsync 同期 |

スクリプトは引数を取らず、実行ディレクトリとスクリプト配置場所から自動でパスを解決する。

#### 成功時出力

変更なし（既存と同一）。rsync の同期結果とバージョン情報を stdout に出力。終了コード 0。

#### 同等性検証基準

リネーム後のスクリプトが以下を満たすこと:
- `resolve_script_dir()` が新パスを正しく解決する
- rsync 同期先・同期元が正しい
- 終了コード・出力形式が既存と同一

## 処理フロー概要

### リネーム作業の処理フロー

**ステップ**:

1. `prompts/package/skills/upgrading-aidlc/` をディレクトリごとリネーム
2. `upgrade-aidlc.sh` を `aidlc-setup.sh` にリネーム
3. SKILL.md 内の参照を更新
4. aidlc-setup.sh 内のコメント・ログ出力を更新（必要な場合）
5. `docs/aidlc/skills/upgrading-aidlc/` も同様にリネーム・更新
6. ドキュメントファイル群の参照を一括更新
7. シンボリックリンクを再作成
8. 旧名の残留確認（grep検証）
9. 動作確認（readlink + test -x + スモークテスト）

**関与するコンポーネント**: スキルディレクトリ、シンボリックリンク、ドキュメントファイル

## 非機能要件（NFR）への対応

Unit定義に記載のとおり、すべて「該当なし」。

## 技術選定

- **言語**: Bash（既存スクリプト）、Markdown（ドキュメント）
- **ツール**: git mv（リネーム）、ln -s（シンボリックリンク）、grep（検証）

## 実装上の注意事項

- 編集は `prompts/package/` 側で行う（メタ開発ルール）
- `docs/aidlc/` は rsync コピーだが、rsync は Operations Phase まで実行されないため、現サイクルでスキルが動作するよう同期更新する（SoT は `prompts/package/`、`docs/aidlc/` 直接編集は本例外のみ）
- `aidlc-setup.sh` 内の `resolve_script_dir()` はシンボリックリンクを追跡するため、リネーム後のパスでの動作確認が必要
- 歴史的参照（CHANGELOG.md、過去サイクルの成果物）は変更しない

## 不明点と質問（設計中に記録）

設計に関する不明点なし。
