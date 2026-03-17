# 論理設計: sync-package.sh配置見直しとlib同期検証

## 概要

sync-package.shを `prompts/package/bin/` から `prompts/bin/` に移動し、関連参照を更新する。

## 変更一覧

### 1. ファイル移動

- **移動元**: `prompts/package/bin/sync-package.sh`
- **移動先**: `prompts/bin/sync-package.sh`
- **ファイル内容の変更**: なし（パスのみ変更）

### 2. 後方互換ラッパー

旧パス `prompts/package/bin/sync-package.sh` に互換ラッパーを配置。
旧バージョンの `aidlc-setup.sh` が新バージョンのスターターキットを参照した場合でも動作を保証する。

```bash
#!/usr/bin/env bash
# 後方互換ラッパー - 次サイクルで削除予定
exec "$(dirname "$0")/../../bin/sync-package.sh" "$@"
```

### 3. aidlc-setup.sh 参照パス更新（正本のみ）

**ファイル**: `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh`

- L156: メタ開発判定条件
  - 変更前: `[[ -x "${project_root}/prompts/package/bin/sync-package.sh" ]]`
  - 変更後: `[[ -x "${project_root}/prompts/bin/sync-package.sh" ]]`
- L339: SYNC_PACKAGE変数
  - 変更前: `SYNC_PACKAGE="${STARTER_KIT_ROOT}/prompts/package/bin/sync-package.sh"`
  - 変更後: `SYNC_PACKAGE="${STARTER_KIT_ROOT}/prompts/bin/sync-package.sh"`

**`docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh`**: 正本の同期コピー。正本更新後にsyncで自動反映する（手動同期禁止）。

### 4. docs/aidlc/bin/sync-package.sh の扱い

互換ラッパーが `prompts/package/bin/sync-package.sh` に残るため、syncの `bin` 同期でラッパーが `docs/aidlc/bin/sync-package.sh` にもコピーされる。互換期間中はこの残置を許容する（ラッパーのため実害なし）。次サイクルで互換ラッパー削除時に自然消滅する。

### 5. パーミッション関連の更新

互換期間中は旧パス・新パスの両方を許可する。互換ラッパー削除（次サイクル）と同時に旧パス権限を削除する。

**setup-ai-tools.sh テンプレート（正本）**: `prompts/package/bin/setup-ai-tools.sh`
- L216: `"Bash(docs/aidlc/bin/sync-package.sh:*)"` は残置（互換ラッパーがsyncされるため必要）

**`.claude/settings.json`**: 共有設定
- L23: `"Bash(docs/aidlc/bin/sync-package.sh:*)"` は残置（同上）

**`.claude/settings.local.json`**: ローカル設定
- L98付近: `"Bash(prompts/bin/sync-package.sh:*)"` を追加（旧パスエントリも残置）

### 6. ドキュメント更新

**ファイル**: `prompts/setup-prompt.md`
- L713: `prompts/package/bin/sync-package.sh` → `prompts/bin/sync-package.sh`
- L714: `docs/aidlc/bin/sync-package.sh` → `docs/aidlc/bin/sync-package.sh（互換ラッパー）` に注記追加
- L715: `[スターターキットパス]/prompts/package/bin/sync-package.sh` → `[スターターキットパス]/prompts/bin/sync-package.sh`

## 実装手順

1. 正本ファイルを更新（aidlc-setup.sh, setup-ai-tools.sh）
2. sync-package.shを `prompts/bin/` に移動
3. 旧パスに互換ラッパーを配置
4. sync実行で docs/aidlc/ を自動更新
5. パーミッション設定を更新
6. ドキュメントを更新
7. lib同期検証

## lib同期検証

- sync-package.sh移動後に `prompts/bin/sync-package.sh --source prompts/package/lib/ --dest docs/aidlc/lib/ --dry-run` で同期動作を確認
- `validate.sh` が正しく同期対象に含まれることを検証

## 影響範囲

- 過去サイクルのドキュメント: 履歴のため更新不要
- 互換ラッパーは次サイクルで削除予定
