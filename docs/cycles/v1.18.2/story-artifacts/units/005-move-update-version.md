# Unit: update-version.sh rsync対象外ディレクトリへ移動

## 概要
スターターキット固有のupdate-version.shを`prompts/package/bin/`から`bin/`（リポジトリルート直下）に移動し、利用先プロジェクトへの配布を防止する。

## 含まれるユーザーストーリー
- ストーリー 6: update-version.sh rsync対象外ディレクトリへ移動 (#210)

## 責務
- `prompts/package/bin/update-version.sh`を`bin/update-version.sh`に移動
- `docs/cycles/rules.md`の参照パスを`bin/update-version.sh`に更新
- `.claude/settings.local.json`のallowedToolsの参照パスを更新
- 移動後の動作確認:
  - `bin/update-version.sh --version v1.0.0 --dry-run` が正常動作すること
  - `prompts/package/bin/sync-package.sh --delete --dry-run` で `docs/aidlc/bin/update-version.sh` が削除対象に含まれること
  - `.claude/settings.local.json`の参照パスが`bin/update-version.sh`に更新されていること

## 境界
- update-version.shの機能変更は行わない
- sync-package.shの変更は行わない（--deleteオプションにより自動削除される）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **後方互換性**: 移動後も同一のCLI引数・戻り値・終了コードを維持

## 技術的考慮事項
- `bin/`ディレクトリはリポジトリルートに既存（`check-size.sh`が存在）
- rsync対象は`prompts/package/`配下のみなので、`bin/`は自動的に対象外
- sync-package.shの`--delete`により、次回rsync後に`docs/aidlc/bin/update-version.sh`は自動削除される

## 実装優先度
Low

## 見積もり
0.5セッション

## 関連Issue
- #210

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
