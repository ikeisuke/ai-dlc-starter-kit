# 論理設計: サイクル横断ドキュメント置き場

## 作成するディレクトリ構造

```text
docs/shared/
├── README.md           # サイクル横断ドキュメント管理ガイド
├── adr/
│   └── README.md       # ADR運用ルール・一覧
├── specs/
│   └── README.md       # 技術仕様一覧
└── runbooks/
    └── README.md       # 運用手順書一覧
```

## 作成するファイル

### 1. docs/shared/README.md

**内容**:
- サイクル横断ドキュメントの説明
- ディレクトリ構成
- 判断基準（何をここに置くか）
- 各サブディレクトリへのリンク

### 2. docs/shared/adr/README.md

**内容**:
- ADRとは何か
- フォーマット（MADRベース）
- 命名規則
- 運用ルール（作成・レビュー・更新）
- ADR一覧（空または例示）

### 3. docs/shared/specs/README.md

**内容**:
- 技術仕様の説明
- 置くべきドキュメントの例
- 仕様一覧（空）

### 4. docs/shared/runbooks/README.md

**内容**:
- 運用手順書の説明
- 置くべきドキュメントの例
- 手順書一覧（空）

## docs/aidlc/ との棲み分け

| 項目 | docs/aidlc/ | docs/shared/ |
|------|-------------|--------------|
| 目的 | AI-DLCフレームワーク自体 | プロジェクト固有のサイクル横断 |
| 同梱 | スターターキットに含む | プロジェクトで作成 |
| 例 | テンプレート、プロンプト、ガイド | ADR、技術仕様、運用手順 |
| 更新 | AI-DLCバージョンアップ時 | プロジェクト運用中随時 |

## docs/development/ との棲み分け

| 項目 | docs/development/ | docs/shared/specs/ |
|------|-------------------|-------------------|
| 目的 | 開発環境セットアップ | 技術仕様 |
| 内容 | 環境構築手順、ツール設定 | システム動作仕様、設計方針 |
| 対象読者 | 新規開発者 | 全開発者・運用者 |
| 例 | ローカル環境構築、テスト実行方法 | API設計方針、データモデル仕様 |

## 実装手順

1. `docs/shared/` ディレクトリ作成
2. `docs/shared/README.md` 作成
3. `docs/shared/adr/README.md` 作成
4. `docs/shared/specs/README.md` 作成
5. `docs/shared/runbooks/README.md` 作成

## 既存ファイルへの影響

| ファイル | 対応 | 理由 |
|----------|------|------|
| `docs/cycles/rules.md` | 移動しない | AI-DLCプロンプトから参照されているため |
| `docs/monitoring.md` | 移動しない | 既存参照への影響を避けるため |

代わりに `docs/shared/README.md` から上記ファイルへのリンクを設置する。

## docs/shared/README.md に含める内容

- サイクル横断ドキュメントの説明
- 判断フロー（何をここに置くか）
- 既存のサイクル横断ドキュメントへのリンク:
  - `../cycles/rules.md` - プロジェクト追加ルール
  - `../monitoring.md` - モニタリング設定
