# ドメインモデル: defaults.toml参照のスキル間依存ルール準拠

## エンティティ

### defaults.toml（設定スキーマファイル）
- **責務**: AI-DLCのデフォルト設定値を定義するスキーマファイル
- **正本**: `skills/aidlc/config/defaults.toml`（変更なし。設定スキーマの唯一の正本）
- **配布用コピー**: `skills/aidlc-setup/config/defaults.toml`（新規。正本からの完全コピー）

### 02-generate-config.md（ステップファイル）
- **責務**: `aidlc-setup` スキルのconfig.toml生成・アップグレードフローを定義
- **変更対象箇所**: ステップ7.4b「欠落キー検出」のパス解決ロジック（L379付近）

### detect-missing-keys.sh（スクリプト）
- **責務**: defaults.tomlとconfig.tomlを比較し、欠落キーを検出
- **インターフェイス**: `--defaults <path> --config <path>` （変更なし）

## 依存関係

### 実行時依存
```
02-generate-config.md
  └── パス解決 → defaults.toml（変更前: aidlcスキル内、変更後: aidlc-setupスキル内）
       └── detect-missing-keys.sh --defaults <path>（インターフェイス変更なし）
```

### 保守時依存
```
aidlc-setup/config/defaults.toml ──従属──> aidlc/config/defaults.toml（正本）
```
- **更新契機**: `aidlc` スキル側の `defaults.toml` が更新された時
- **同期責任者**: メタ開発チーム
- **差分検証方法**: リリース前に `diff skills/aidlc/config/defaults.toml skills/aidlc-setup/config/defaults.toml` を実行し差分0を確認

## 変更影響範囲
- `skills/aidlc-setup/steps/02-generate-config.md`: パス解決ロジックの変更
- `skills/aidlc-setup/config/defaults.toml`: 新規ファイル（正本からのコピー）
- `skills/aidlc/`: 変更なし
