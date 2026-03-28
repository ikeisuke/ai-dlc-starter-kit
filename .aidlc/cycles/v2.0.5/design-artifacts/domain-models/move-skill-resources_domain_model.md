# ドメインモデル: スキルリソース移設・重複削除

## 概要

ファイルシステム上のリソース移設と重複削除を行うUnitのドメインモデル。コードロジックはなく、ファイル操作とシンボリックリンク管理が中心。

## エンティティ（Entity）

### SkillResource

スキルが使用するリソースファイル（ガイド・テスト）。

- **ID**: ファイルパス（リポジトリルート相対）
- **属性**:
  - sourcePath: string - 移動元パス（docs/aidlc/ 配下）
  - targetPath: string - 移動先パス（skills/aidlc/ 配下）
  - category: enum(guide, test) - リソース種別
- **振る舞い**:
  - move(): git mvで移動元から移動先へ移動

### NonSkillResource

スキル非依存のリソースファイル（Kiro CLI設定等）。skills/配下ではなくルート直下に配置。

- **ID**: ファイルパス（リポジトリルート相対）
- **属性**:
  - sourcePath: string - 移動元パス（docs/aidlc/ 配下）
  - targetPath: string - 移動先パス（ルート直下）
  - category: enum(kiro) - リソース種別
- **振る舞い**:
  - move(): git mvで移動元から移動先へ移動

### DuplicateFile

正本のコピーとして存在する重複ファイル。

- **ID**: ファイルパス
- **属性**:
  - canonicalPath: string - 正本のパス（skills/aidlc/ 配下）
  - isDuplicate: boolean - 正本と内容一致または旧版であることが確認済み
- **振る舞い**:
  - remove(): git rmで削除

### SymbolicLink

他ツール（.agents/, .kiro/）からスキルディレクトリへの参照。

- **ID**: リンクパス
- **属性**:
  - currentTarget: string - 現在のリンク先
  - newTarget: string - 更新後のリンク先
  - status: enum(valid, broken) - 現在の状態
- **振る舞い**:
  - update(): ln -sfで新しいターゲットに更新

## 値オブジェクト（Value Object）

### ResourceCategory

- **属性**: type: enum(guide, test)
- **不変性**: リソースの種別は移動後も変わらない

### FilePath

- **属性**: path: string（リポジトリルート相対）
- **等価性**: 文字列としての完全一致

## 集約（Aggregate）

### ResourceMigration

- **集約ルート**: Unit 001の移設操作全体
- **含まれる要素**: SkillResource[], NonSkillResource[], DuplicateFile[], SymbolicLink[]
- **不変条件**:
  - 移動先にファイルが存在してから重複元を削除する
  - シンボリックリンクのターゲットが存在するパスを指す
  - git mvで履歴追跡を維持する

## ドメインサービス

### MigrationService

- **責務**: 移設操作の順序制御と整合性確保
- **操作**:
  - migrateResources(): guides, tests, kiroの順にgit mv実行
  - removeDuplicates(): prompts, templates, lib, .github, prompts/packageの順にgit rm実行
  - updateSymlinks(): 全シンボリックリンクを新パスに更新
  - verify(): 完了条件の検証

## ユビキタス言語

- **正本（SSoT）**: skills/aidlc/ 配下のファイル。唯一の信頼できる情報源
- **旧コピー**: docs/aidlc/ 配下のファイル。v1 rsyncインフラでコピーされた古い版
- **パッケージングコピー**: prompts/package/ 配下のファイル。docs/aidlc/のコピー元

## 不明点と質問

なし（計画段階で全て確認済み）
