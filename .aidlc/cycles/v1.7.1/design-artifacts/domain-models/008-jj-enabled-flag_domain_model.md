# ドメインモデル: jjサポート有効化フラグ

## 概念

### jjサポート設定（JjSupportSetting）

**責務**: jj（Jujutsu）によるバージョン管理を優先的に案内するかどうかを制御する設定値

**属性**:

- `enabled`: boolean - jjコマンドを優先的に案内するかどうか

**デフォルト値**: `false`（従来のgitを使用）

### 設定参照フロー

1. `docs/aidlc.toml`の`[rules.jj]`セクションを読み込む
2. `enabled`の値を取得
3. 以下の場合は`false`（デフォルト）として扱う:
   - セクションが存在しない
   - `enabled`キーが存在しない
   - 値が`true`/`false`以外（不正値）
4. `enabled=true`の場合:
   - 各プロンプトでjj使用時は`docs/aidlc/guides/jj-support.md`を参照するよう案内
   - **例外**: タグ操作（リリースタグ作成等）はjjでサポートされていないためgitを継続使用

## 境界コンテキスト

- **設定管理**: `docs/aidlc.toml`（既存）
- **ガイド**: `docs/aidlc/guides/jj-support.md`（既存、参照のみ）
- **プロンプト実行**:
  - `prompts/package/prompts/setup.md`（ソース、変更対象）
  - `prompts/package/prompts/inception.md`（ソース、変更対象）
  - `prompts/package/prompts/construction.md`（ソース、変更対象）
  - `prompts/package/prompts/operations.md`（ソース、変更対象）
  - ※ `docs/aidlc/prompts/`はOperations Phase時にrsyncで反映

## 適用範囲

- **対象**: 上記4つのプロンプトファイル（通常版）
- **対象外**: `lite/`配下のLite版プロンプト - 別途対応を検討

## 既存ガイドとの関係

`docs/aidlc/guides/jj-support.md`は実験的機能として提供済み。本設定は：

- enabled=false: 現状維持（jj-support.mdは補助資料として存在、gitコマンドを使用）
- enabled=true: プロンプト内でjj-support.md参照を案内（ガイドを通じてjjコマンドを使用）

**ガイドとの整合性**:
- 既存ガイドは「プロンプト本体はGitコマンドのまま、読み替え前提」と記載
- enabled=true時は「jj使用時はガイドを参照」と案内し、プロンプト内のgitコマンドは変更しない
- これによりガイドの「読み替え前提」方針と整合を保つ

## 補足

このUnitはプロンプト（Markdown）とTOML設定の修正のみのため、エンティティ・集約等の詳細定義は省略。
