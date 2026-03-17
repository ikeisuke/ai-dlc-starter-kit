# ドメインモデル: sync-package.sh配置見直しとlib同期検証

## 概要

sync-package.shの配置を見直し、rsync同期対象外に移動する。

## エンティティ

### sync-package.sh

- **現在の配置**: `prompts/package/bin/sync-package.sh`（rsync同期対象内）
- **移動先**: `prompts/bin/sync-package.sh`（rsync同期対象外）
- **役割**: `prompts/package/` から `docs/aidlc/` への rsync同期を実行するユーティリティ
- **呼び出し元**: `aidlc-setup.sh` の Step 6（パッケージ同期）

### aidlc-setup.sh

- **配置**: `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh`
- **sync-package.sh参照**: `${STARTER_KIT_ROOT}/prompts/package/bin/sync-package.sh`
- **更新後の参照**: `${STARTER_KIT_ROOT}/prompts/bin/sync-package.sh`

### SYNC_DIRS

- 7ディレクトリ: prompts, templates, guides, bin, skills, kiro, lib
- `bin` が含まれるため、`prompts/package/bin/` 内の全ファイルが `docs/aidlc/bin/` に同期される
- sync-package.shを `prompts/package/bin/` から除去することで不要コピーが解消される

### lib同期

- **ソース**: `prompts/package/lib/validate.sh`
- **宛先**: `docs/aidlc/lib/validate.sh`
- **現状**: 同期済み（動作確認済み）
- **検証**: sync-package.sh移動後も正常に動作することを確認

### 後方互換ラッパー

- **配置**: `prompts/package/bin/sync-package.sh`（旧パスに残置）
- **役割**: 旧バージョンの `aidlc-setup.sh` が新スターターキットを参照した場合の互換保証
- **実装**: `exec` で新パスに転送するだけの薄いラッパー
- **ライフサイクル**: 次サイクルで削除予定

### setup-ai-tools.sh パーミッションテンプレート

- **配置**: `prompts/package/bin/setup-ai-tools.sh`（正本）
- **影響**: `docs/aidlc/bin/sync-package.sh` のパーミッションエントリを含むテンプレートを生成
- **対応**: sync-package.shがdocs/aidlc/bin/に配置されなくなるため、該当エントリを削除

## 正本と同期コピーの関係

- **正本**: `prompts/package/` 配下のファイル
- **同期コピー**: `docs/aidlc/` 配下のファイル（syncで自動反映）
- **原則**: 正本のみ編集し、docs/aidlc/はsyncで更新（手動同期禁止）

## 不変条件

- sync-package.sh自体のロジック変更は不要（配置場所のみ変更）
- SYNC_DIRSの構成は変更しない
- `resolve_starter_kit_root` のメタ開発判定条件にsync-package.sh存在チェックが含まれるため更新が必要
