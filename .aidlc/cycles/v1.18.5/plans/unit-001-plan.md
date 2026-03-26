# Unit 001 計画: worktreeメタ開発rsync同期修正

## 概要

worktree環境で`upgrade-aidlc.sh`を実行した際に、Tier 3（プロジェクトモード）がghq経由でメインリポジトリの`prompts/package/`を参照してしまう問題を修正する。

## 原因分析（既存分析の補正）

**既存分析ではTier 2が原因とされていたが、Issue #274の再現手順を確認した結果、実際の問題はTier 3（プロジェクトモード）にある。**

- スクリプトは`docs/aidlc/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`（rsyncコピー）から実行される
- Tier 3パターン`*/docs/aidlc/skills/*/bin`にマッチ（L141）
- `project_root`（5階層上）はworktreeルート（`.worktree/dev/`）に正しく解決される
- しかしTier 3はghq経由でメインリポジトリを探索し、そのルートをSTARTER_KIT_ROOTとする
- 結果、rsyncソースがメインリポジトリの`prompts/package/`（stale）になり、worktreeの最新変更が反映されない

**Tier 2（メタ開発モード）は正常動作**: `prompts/package/skills/*/bin`から実行した場合、5階層上でworktreeルートに解決され、rsyncソースも正しい。

## 変更対象ファイル

- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`（正本）

## 実装計画

### 修正箇所: Tier 3内のメタ開発worktree検出（L141-186）

Tier 3（プロジェクトモード）で`project_root`を算出した直後に、メタ開発環境（worktree含む）かどうかを判定する。

**判定ロジック**:

```
project_root算出後:
1. 以下3条件すべてを満たすか？
   - ${project_root}/prompts/package/ が存在（ディレクトリ）
   - ${project_root}/version.txt が存在（ファイル）
   - ${project_root}/prompts/package/bin/sync-package.sh が実行可能
   → YES: メタ開発環境（worktreeまたは通常checkout）
          project_rootをそのままSTARTER_KIT_ROOTとして返す
   → NO:  外部プロジェクト
          既存のghq解決ロジックを継続
```

**3条件複合判定の理由**（AIレビュー指摘対応）:

単一条件では外部プロジェクトに同名ディレクトリが存在した場合に誤検出するリスクがある。スターターキット固有の3ファイル（`prompts/package/`、`version.txt`、`sync-package.sh`）の複合判定により誤検出を防止する。

**この判定が安全な理由**:

- 外部プロジェクトにはこの3条件の組み合わせが存在しない → 既存動作に影響なし
- 通常メタ開発（ブランチ直接checkout）でもproject_root = リポジトリルートなので正しく動作
- worktreeメタ開発でもproject_root = worktreeルートなので正しく動作

### コード変更イメージ

L141のTier 3ブロック内、`project_root`算出直後（L145の後）に以下を追加:

```bash
# メタ開発環境検出: project_root がスターターキット本体であればローカル使用
if [[ -d "${project_root}/prompts/package" ]] \
    && [[ -f "${project_root}/version.txt" ]] \
    && [[ -x "${project_root}/prompts/package/bin/sync-package.sh" ]]; then
    echo "$project_root"
    return 0
fi
```

### フォールバック

- `prompts/package/`が存在しない場合 → 既存のghq解決ロジック（変更なし）
- ghq解決も失敗した場合 → 既存のエラーメッセージ（変更なし）

## 完了条件チェックリスト

- [ ] `upgrade-aidlc.sh`の`resolve_starter_kit_root()`でworktree環境を検出し、worktreeルートを返す
- [ ] worktree判定失敗時のフォールバック（既存ghq解決）が動作する
- [ ] worktree以外の通常環境での動作が変わらない
- [ ] プロジェクトモード（外部プロジェクト）の動作が変わらない
- [ ] `AIDLC_STARTER_KIT_PATH`環境変数によるオーバーライドが引き続き動作する
