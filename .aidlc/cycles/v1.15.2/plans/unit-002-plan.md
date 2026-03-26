# Unit 002 計画: ドキュメント構文エラー修正

## 概要

`prompts/package/guides/ios-version-update.md` と `prompts/package/guides/config-merge.md` のコード例における構文エラーを修正する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/guides/ios-version-update.md` | パラメータ展開構文修正 |
| `prompts/package/guides/config-merge.md` | TOML テーブル重複定義解消 |

## 実装計画

### Phase 1: 設計（省略）

本Unitは構文エラーの修正のみであり、設計は不要。

### Phase 2: 実装

#### 修正1: `prompts/package/guides/ios-version-update.md` のパラメータ展開構文修正

- **対象行**: 38-39行目
- **修正前**:
  ```bash
  # サイクルバージョンからvプレフィックスを除去
  CYCLE_VERSION="${{CYCLE}#v}"
  ```
- **修正後**:
  ```bash
  # サイクルバージョンからvプレフィックスを除去
  CYCLE="{{CYCLE}}"
  CYCLE_VERSION="${CYCLE#v}"
  ```
- **理由**: `${{CYCLE}#v}` はテンプレートプレースホルダ `{{CYCLE}}` とbashパラメータ展開 `${...#v}` が混在し不正な構文。`docs/cycles/rules.md` の前例（`CYCLE="{{CYCLE}}"` → `VERSION="${CYCLE#v}"`）に合わせ、まず変数に代入してからパラメータ展開を行うことでテンプレート層とシェル層の境界を明確化する。

#### 修正2: `prompts/package/guides/config-merge.md` のTOMLテーブル重複定義解消

- **対象行**: 138行目と142行目
- **修正前**:
  ```toml
  # AIレビューを個人的に無効化
  [rules.reviewing]
  mode = "disabled"

  # 独自のAIツール優先順位
  [rules.reviewing]
  tools = ["claude", "codex"]
  ```
- **修正後**:
  ```toml
  # AIレビューを個人的に無効化 / 独自のAIツール優先順位
  [rules.reviewing]
  mode = "disabled"
  tools = ["claude", "codex"]
  ```
- **理由**: TOMLでは同一テーブル名の重複定義は無効。1つのテーブルに統合する。

## 完了条件チェックリスト

- [ ] `prompts/package/guides/ios-version-update.md` のパラメータ展開構文修正（`${{CYCLE}#v}` → `CYCLE="{{CYCLE}}"` + `${CYCLE#v}`）
- [ ] `prompts/package/guides/config-merge.md` の TOML 例で `[rules.reviewing]` テーブルの重複定義解消
