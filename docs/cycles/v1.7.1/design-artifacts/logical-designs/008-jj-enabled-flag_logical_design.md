# 論理設計: jjサポート有効化フラグ

## 変更対象

### 設定ファイル

- `prompts/package/aidlc.toml.template`
  - `[rules.jj]`セクションを追加

### プロンプトファイル

- `prompts/package/prompts/setup.md`
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`

### 反映先

- `docs/aidlc/` 配下
  - Operations Phase完了時のrsyncで自動反映（`docs/cycles/rules.md`参照）

### 適用範囲外

- `prompts/package/prompts/lite/` 配下（Lite版）
  - Lite版への適用は別途検討（本Unitのスコープ外）

## 処理フロー

```text
開始
  ↓
[1] docs/aidlc.tomlの[rules.jj]セクションを読み込む
  ↓
[2] enabledの値を取得
    - 値が存在しない場合: false（デフォルト）
    - 値がtrue/false以外（不正値）の場合: false（デフォルト）
  ↓
[3] 条件分岐
    ├─ enabled = true  → jjコマンドを案内、jj-support.md参照を追加
    └─ enabled = false → 従来通りgitコマンドを使用
  ↓
終了
```

## 設定ファイルの変更

### aidlc.toml.template への追加

```toml
[rules.jj]
# jjサポート設定（v1.8.0で追加）
# enabled: true | false
# - true: プロンプト内でjjコマンドを優先的に案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
```

### 配置位置

`[rules.unit_branch]`セクションの後に追加

## プロンプトファイルの変更方針

### 方針

各プロンプトのGit操作セクションに以下を追加:

1. **設定確認ブロック**: `[rules.jj].enabled`の値を確認する案内
2. **条件分岐**: enabled=trueの場合はjj-support.mdを参照するよう案内

### 変更箇所の詳細

#### setup.md

- 対象セクション: サイクルブランチ作成
- 追加内容: jj設定確認と`jj bookmark create`コマンドの案内

#### inception.md

- 対象セクション: Gitコミット関連
- 追加内容: jj設定確認と`jj describe`/`jj new`コマンドの案内

#### construction.md

- 対象セクション: Gitコミット関連、Unitブランチ作成
- 追加内容: jj設定確認と対応するjjコマンドの案内

#### operations.md

- 対象セクション: リリースタグ作成、PRマージ
- 追加内容: jj設定確認とjjコマンドの案内
- 注意: タグ操作はjjでサポートされていないためgitを使用（jj-support.md参照）

### 追加するガイダンスブロック（共通形式）

```markdown
**jjサポート設定の確認**:

`docs/aidlc.toml`の`[rules.jj]`セクションを確認:

- enabled = true の場合: jjコマンドを使用。詳細は`docs/aidlc/guides/jj-support.md`を参照
- enabled = false、未設定、または不正値の場合: 以下のgitコマンドを使用
```

## テスト観点

- enabled=trueの場合、jj-support.md参照が案内されること
- enabled=falseの場合、従来通りgitコマンドが使用されること
- 設定が存在しない場合、falseとして動作すること（git使用）
- 不正値（true/false以外）の場合、falseとして動作すること

## 参照ドキュメント

- `docs/aidlc/guides/jj-support.md`: jjコマンドの詳細ガイド（既存）
