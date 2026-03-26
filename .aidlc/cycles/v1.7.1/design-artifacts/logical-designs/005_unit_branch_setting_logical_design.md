# 論理設計: Unitブランチ設定統合（最小構成）

## 変更対象

- `prompts/package/prompts/construction.md`（ソースファイル）
  - セクション: 「6. Unitブランチ作成【推奨】」

### 反映先

- `docs/aidlc/prompts/construction.md`
  - Operations Phase完了時のrsyncで自動反映（`docs/cycles/rules.md`参照）

### 適用範囲外

- `prompts/package/prompts/lite/construction.md`（Lite版）
  - Lite版への適用は別途検討（本Unitのスコープ外）

## 処理フロー

```text
開始
  ↓
[1] docs/aidlc.tomlの[rules.unit_branch]セクションを読み込む
  ↓
[2] enabledの値を取得
    - 値が存在しない場合: true（デフォルト）
    - 値がtrue/false以外（不正値）の場合: true（デフォルト）
  ↓
[3] 条件分岐
    ├─ enabled = true  → 従来フロー（GitHub CLI確認 → ユーザー確認 → ブランチ作成）
    └─ enabled = false → スキップして次のセクションへ
  ↓
終了
```

## 設定読み込み方法

既存の設定参照パターン（他のrules設定と同様）に従い、`docs/aidlc.toml`を直接読み込む形式を採用。

## 変更箇所の詳細

### 追加する内容

「6. Unitブランチ作成【推奨】」セクションの先頭に以下を追加:

1. **設定確認**: `[rules.unit_branch].enabled`の値を確認
2. **条件分岐**: enabled=falseの場合はスキップ

### 修正後のフロー概要

```text
6. Unitブランチ作成【推奨】

**設定確認**:
`docs/aidlc.toml`の`[rules.unit_branch]`セクションを確認し、`enabled`の値を取得。

- enabled = false の場合: このセクションをスキップして次へ
- enabled = true、未設定、または不正値の場合: 以下を実行

**前提条件チェック**:
（既存の処理）
```

## テスト観点

- enabled=trueの場合、従来通りUnitブランチ作成確認が表示されること
- enabled=falseの場合、Unitブランチ作成確認がスキップされること
- 設定が存在しない場合、trueとして動作すること
- 不正値（true/false以外）の場合、trueとして動作すること
