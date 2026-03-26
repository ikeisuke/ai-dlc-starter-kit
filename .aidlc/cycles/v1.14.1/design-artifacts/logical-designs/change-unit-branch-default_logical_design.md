# 論理設計: unit_branch.enabledデフォルト値変更

## 概要

construction.mdの判定ロジックを反転し、`enabled = true` の場合のみUnitブランチ作成を提案するように変更する。

## コンポーネント構成

### 変更対象1: construction.md（判定ロジック）

**ファイル**: `prompts/package/prompts/construction.md` 386-387行目

**変更前の判定フロー**:

```text
enabled = false → スキップ
enabled = true / 未設定 / 不正値 → 実行
```

**変更後の判定フロー**:

```text
enabled = true → 実行
enabled = false / 未設定 / 不正値 → スキップ
```

**箇条書きの記述変更**:

- 変更前1行目: `- \`enabled = false\`の場合: このセクションをスキップして次へ進む`
- 変更前2行目: `- \`enabled = true\`、未設定、または不正値の場合: 以下の「前提条件チェック」から実行`
- 変更後1行目: `- \`enabled = true\`の場合: 以下の「前提条件チェック」から実行`
- 変更後2行目: `- \`enabled = false\`、未設定、または不正値の場合: このセクションをスキップして次へ進む`

### 変更対象2: docs/aidlc.toml（コメント）

**ファイル**: `docs/aidlc.toml` 87行目

**変更前**:

```toml
# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: true）
```

**変更後**:

```toml
# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: false）
```

## 影響範囲

- `docs/aidlc/prompts/construction.md` は `prompts/package/prompts/construction.md` のrsyncコピーであり、直接編集しない
  - **同期タイミング**: Operations Phaseで `/upgrading-aidlc` スキル実行時にrsyncで同期される（`docs/cycles/rules.md` 参照）
  - **同期前提条件**: この変更が `docs/aidlc/prompts/construction.md` に反映されるのは、upgrading-aidlc実行後。同期前は旧ロジックが残るが、このプロジェクトの開発フローでは問題なし
- `enabled = true` を明示的に設定している既存プロジェクトには影響なし
- 未設定の既存プロジェクトは、Unitブランチ作成が推奨されなくなる（意図された動作）
