# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回のスコープに関連するファイル:

```
prompts/
├── setup-prompt.md                          # アップグレードエントリーポイント
├── setup/bin/
│   └── check-setup-type.sh                  # セットアップ種類判定
├── package/
│   ├── prompts/
│   │   ├── common/
│   │   │   ├── commit-flow.md               # コミットフロー（#317対象）
│   │   │   └── review-flow.md               # レビューフロー（#319対象）
│   │   └── construction.md                  # Construction Phase（#318対象）
│   ├── bin/
│   │   ├── setup-branch.sh                  # ブランチ作成（validate_cycle呼び出し元）
│   │   └── sync-package.sh                  # パッケージ同期
│   ├── lib/
│   │   └── validate.sh                      # validate_cycle()定義（#326対象）
│   └── skills/
│       └── aidlc-setup/
│           └── bin/aidlc-setup.sh            # スキル版アップグレード
```

## アーキテクチャ・パターン

- **プロンプト駆動**: AIエージェントが`.md`プロンプトを読み込んで手順を実行
- **メタ開発構造**: `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー
- **スクリプト分離**: バリデーション関数は `lib/validate.sh` に共通化（根拠: setup-branch.sh L21の`source`）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト)、Markdown (プロンプト) | prompts/package/bin/*.sh |
| フレームワーク | AI-DLC独自フレームワーク | prompts/package/prompts/ |
| 主要ツール | gh, dasel, rsync, git | prompts/setup-prompt.md |

## 依存関係

### スコープ内ファイル間の依存

- `setup-branch.sh` → `lib/validate.sh` (`source`で読み込み)
- `aidlc-setup.sh` → `check-setup-type.sh` → `check-version.sh` (呼び出しチェーン)
- `setup-prompt.md` → `sync-package.sh`, `migrate-config.sh`, `resolve-starter-kit-path.sh` (参照)

### 鶏と卵問題（アップグレードパス）

`setup-prompt.md` が `docs/aidlc/bin/` のスクリプトを参照するが、古いバージョンにはそれらが存在しない:
- `docs/aidlc/bin/sync-package.sh` → 存在しない場合あり
- `docs/aidlc/bin/resolve-starter-kit-path.sh` → 存在しない場合あり
- `docs/aidlc/bin/setup-ai-tools.sh` → ハードコードされたパス（L1053）

## 特記事項

### validate_cycle()の現状（validate.sh L39-73）

現在の正規表現: `^[a-z0-9v][a-z0-9._-]*(/[a-z0-9v][a-z0-9._-]*)?$`

**Git ref安全性の欠落**:
- 末尾ドット（`foo.`）を許可 → `git check-ref-format`で拒否される
- `.lock`接尾辞（`foo.lock`）を許可 → Gitの予約パターン
- 連続ドット（`foo..bar`）はパストラバーサルチェックで拒否済み

### check-setup-type.shの誤検出（check-setup-type.sh L67-74）

`version_status:not_found` と `*`（不明ステータス）の両方が `setup_type:initial` にマッピング。
原因パターン:
1. `starter_kit_version`がaidlc.tomlに存在しない
2. バージョン値が`v`プレフィックス付き（semver正規表現が`^[0-9]+`で始まるため拒否）
3. dasel未インストール

### construction.md Step 6のテスト失敗フロー（L545-587）

テスト失敗時に即座にバックログ登録を提案し、修正→再実行のループはあるが最大回数制限がない。
