# 論理設計: worktreeメタ開発rsync同期修正

## 概要

`upgrade-aidlc.sh`の`resolve_starter_kit_root()`関数L141-186（Tier 3ブロック）にガード句を追加。

## 変更対象

| ファイル | 関数 | 行 | 変更内容 |
|---------|------|-----|---------|
| `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh` | `resolve_starter_kit_root()` | L145の後 | メタ開発環境検出ガード追加 |

## 変更コード

```bash
# L145: project_root="$(cd "$SCRIPT_DIR/../../../../.." && pwd)" の直後に追加

# メタ開発環境検出: project_root がスターターキット本体であればローカル使用
if [[ -d "${project_root}/prompts/package" ]] \
    && [[ -f "${project_root}/version.txt" ]] \
    && [[ -x "${project_root}/prompts/package/bin/sync-package.sh" ]]; then
    echo "$project_root"
    return 0
fi
```

## 動作フロー

```
upgrade-aidlc.sh 実行
  → resolve_script_dir() で SCRIPT_DIR 取得
  → resolve_starter_kit_root() 呼び出し
    → Tier 1: AIDLC_STARTER_KIT_PATH チェック（変更なし）
    → Tier 2: prompts/package/skills/*/bin チェック（変更なし）
    → Tier 3: docs/aidlc/skills/*/bin チェック
      → project_root 算出
      → [NEW] メタ開発環境チェック（prompts/package + version.txt + sync-package.sh）
        → YES: project_root を返す（early return）
        → NO: 既存の ghq 解決ロジック継続
    → Tier 4: エラー（変更なし）
```

## 影響範囲

- **影響あり**: worktreeメタ開発環境での`docs/aidlc/skills/*/bin`からの実行
- **影響なし**: Tier 1（環境変数）、Tier 2（正本パス）、外部プロジェクトのTier 3

## 後方互換性

既存の全パスで動作が変わらないことを確認:
- 環境変数 → Tier 1で処理（変更なし）
- prompts/package/skills/ → Tier 2で処理（変更なし）
- 外部プロジェクト docs/aidlc/skills/ → Tier 3ガードをスキップし既存ghq解決
- メタ開発 docs/aidlc/skills/ → Tier 3ガードでproject_rootを返す（NEW）
