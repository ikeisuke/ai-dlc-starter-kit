# Unit 008: メタ開発ルール定義の現行化 - 計画

## 概要

`.aidlc/rules.md` のメタ開発セクションをv2.0.5以降の実態（skills/aidlcプラグイン構成）に合わせて更新する。廃止済みの `prompts/package/` および `docs/aidlc/` への参照を除去し、メタ開発時の編集パス（`skills/aidlc/**`）とスキル実行時の参照方式（スキルベース相対パス）を明確に区別する。既存Unit定義ファイルの古いパス参照も修正する。

## 変更対象ファイル

| ファイル | 変更種別 |
|---------|---------|
| `.aidlc/rules.md` | メタ開発セクション更新 |
| `.aidlc/cycles/v2.0.9/story-artifacts/units/002-construction-ops-step-docs.md` | パス参照修正 |
| `.aidlc/cycles/v2.0.9/story-artifacts/units/003-template-script-format.md` | パス参照修正 |
| `.aidlc/cycles/v2.0.9/story-artifacts/units/005-agents-rules-review-unify.md` | パス参照修正 |
| `.aidlc/cycles/v2.0.9/story-artifacts/units/007-review-flow-dismiss-prohibition.md` | パス参照修正 |

## 実装計画

### 1. 参照棚卸し（移行前検証）

リポジトリ全体で `prompts/package/` と `docs/aidlc/` の参照を洗い出し、変更対象を確定する。

```bash
grep -rn "prompts/package/" .aidlc/
grep -rn "docs/aidlc/" .aidlc/
```

許可される文脈（変更不要）と禁止される文脈（変更必要）を分類してから修正に進む。

### 2. `.aidlc/rules.md` の更新

#### 2a. 「メタ開発の意識」セクション

- `docs/aidlc/` rsync警告（直接編集で変更が消える旨）を削除
- 「ツール側/成果物側」の説明を更新:
  - ツール側: `skills/aidlc/`（メタ開発時の編集対象）
  - 成果物側: `.aidlc/cycles/`
  - `docs/aidlc/` 参照を除去
- `docs/aidlc/` は `prompts/package/` の rsyncコピーである旨の記述を削除
- 「スターターキットのパス参照」をプラグイン構成に更新
- **2つの参照方式の区別を明記**:
  - メタ開発時（ファイル編集）: `skills/aidlc/**`（プロジェクトルート相対、例外パスとして許可）
  - スキル実行時（AI-DLCフロー内）: スキルベース相対パス（`templates/`, `steps/`, `scripts/` 等）
  - 通常ルールやUnit記述ではスキルベース相対参照を使用する原則を明文化

#### 2b. スキル間依存ルールの追加

- 他スキルの内部実装への依存禁止（`scripts/`, `steps/`, `templates/` 等の内部ファイルパス参照）
- 許可される依存: スキルの呼び出し名（`/aidlc`, `/reviewing-code` 等）とSKILL.mdで定義された入出力引数
- 内部ファイルパス参照をAPIと見なさないルールを明記

#### 2c. 「ファイル参照境界ルール」例外リスト更新

- META-001: `prompts/package/**` → `skills/aidlc/**` に更新（メタ開発時のスキル編集用）
- META-002: `docs/aidlc/**` → 廃止扱い（欠番として維持、IDは繰り上げない）
  - 理由: IDは安定識別子として維持し、参照整合性を保つ
- META-003: 変更なし（`bin/**` のまま維持）

#### 2d. カスタムワークフロー・その他セクション

- 設計レビューガイド照合ルールの `prompts/package/guides/` 参照を `skills/aidlc/guides/` に更新（メタ開発時の例外参照として明記）
- `docs/aidlc.toml` → `.aidlc/config.toml` の参照修正（216行目付近）
- デフォルト禁止テーブルの `prompts/xxx` 行と `docs/aidlc/xxx` 行を更新

### 3. Unit定義ファイルのパス参照修正

各ファイルの「技術的考慮事項」セクションで文脈に応じた修正を行う:
- 対象: Unit 002, Unit 003, Unit 005, Unit 007
- 現状の記述「メタ開発のため、prompts/package/ 配下のファイルを編集する」はメタ開発時の編集文脈
  → `skills/aidlc/` に置換（メタ開発時の編集対象パスとして正しい）
- 実行時参照を示す記述がある場合はスキルベース相対パスに修正

### 4. 移行後検証

修正完了後、以下で残存参照がないことを確認:

```bash
grep -rn "prompts/package/" .aidlc/
grep -rn "docs/aidlc/" .aidlc/  # 廃止扱い記述のみ残存が正常
```

## 完了条件チェックリスト

- [ ] `.aidlc/rules.md`「メタ開発の意識」セクションがv2.0.5以降の構成に更新されている
- [ ] メタ開発時の編集パスとスキル実行時の参照方式が明確に区別されている
- [ ] `docs/aidlc/` rsyncコピーの記述が削除されている
- [ ] スキル間依存ルールが追加されている（呼び出し名と入出力引数のみ許可）
- [ ] ファイル参照境界ルールのMETA-001が `skills/aidlc/**` に更新されている
- [ ] ファイル参照境界ルールのMETA-002が廃止扱い（欠番維持）になっている
- [ ] 既存Unit定義ファイル（002, 003, 005, 007）の古いパス参照が修正されている
- [ ] 移行後検証で残存する古い参照がないことが確認されている
