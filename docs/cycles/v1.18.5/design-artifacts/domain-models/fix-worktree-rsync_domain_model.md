# ドメインモデル: worktreeメタ開発rsync同期修正

## 概要

既存の`resolve_starter_kit_root()`関数のTier 3（プロジェクトモード）パスにガード句を追加する最小変更。新規エンティティ・値オブジェクト・集約の定義は不要。

## 既存エンティティへの変更

### resolve_starter_kit_root() - Tier 3 分岐

**現在の動作**:

```
Tier 3: SCRIPT_DIR が */docs/aidlc/skills/*/bin にマッチ
  → project_root = 5階層上
  → ghq経由でスターターキットルート解決
  → STARTER_KIT_ROOT = メインリポジトリ
```

**変更後の動作**:

```
Tier 3: SCRIPT_DIR が */docs/aidlc/skills/*/bin にマッチ
  → project_root = 5階層上
  → [NEW] project_root にスターターキット固有ファイルが存在？
    → YES: STARTER_KIT_ROOT = project_root（メタ開発環境）
    → NO:  ghq経由でスターターキットルート解決（外部プロジェクト、既存動作）
```

## 判定条件

スターターキット固有ファイルの3条件複合判定:
- `${project_root}/prompts/package/` （ディレクトリ存在）
- `${project_root}/version.txt` （ファイル存在）
- `${project_root}/prompts/package/bin/sync-package.sh` （実行可能ファイル存在）

3条件すべて満たす場合のみメタ開発環境と判定。`sync-package.sh`はスターターキット固有のパッケージ同期スクリプトであり、外部プロジェクトには存在しない。

## 不明点

なし（計画で全て解決済み）
