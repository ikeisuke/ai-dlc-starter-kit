# Unit 001 計画: 名前付きサイクル設定

## 概要

`rules.cycle.mode` 設定の仕様定義と、Inception Phaseプロンプトへのモード読み取り・バリデーション・フォールバック指示の追加を行う。

## 変更対象ファイル

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `prompts/package/prompts/inception.md` | 修正 | `rules.cycle.mode` 読み取り・バリデーション・フォールバック指示の追加（Step 5.5） |
| `docs/aidlc.toml` | 修正 | `[rules.cycle]` セクションに `mode` キーのコメント付きデフォルト値を追加 |

## 実装計画

### 1. docs/aidlc.toml に設定キーを追加

`[rules.cycle]` セクションを追加し、`mode` キーをコメント付きで記述する。

```toml
[rules.cycle]
# mode = "default"  # 有効値: default / named / ask
```

### 2. inception.md への `rules.cycle.mode` 読み取りステップ追加

**挿入位置**: Part 1 ステップ5（スターターキットバージョン確認）とステップ6（サイクルバージョンの決定）の間に、新ステップ「5.5 サイクルモード確認」を追加。

**理由**: モード値はステップ6（バージョン決定）・ステップ7（ブランチ作成）・ステップ9（ディレクトリ作成）で使用されるため、それらの前で読み取る必要がある。

**追加内容**:

```markdown
#### 5.5 サイクルモード確認

`rules.cycle.mode` 設定を読み取り、コンテキスト変数 `cycle_mode` として保持する。

\```bash
docs/aidlc/bin/read-config.sh rules.cycle.mode --default "default"
\```

**読み取り失敗時**（終了コード2）: 以下の警告を表示し、`"default"` として扱う:
\```text
【警告】rules.cycle.mode の読み取りに失敗しました。デフォルト（default）にフォールバックします。
\```

**値の検証**:
- 有効値: `"default"`, `"named"`, `"ask"`
- 有効値以外の場合 → 以下の警告を表示し、`"default"` として扱う:
  \```text
  【警告】rules.cycle.mode の値 "{取得した値}" は無効です。有効値: default, named, ask
  デフォルト（default）にフォールバックします。
  \```

**注意**: `cycle_mode` に基づくモード別分岐ロジック（名前入力フロー、ディレクトリパス組み立て等）はUnit 003で実装する。このステップでは値の読み取りとバリデーションのみ。
```

### 3. 設計パターンの参考

既存の `rules.branch.mode` バリデーション（inception.md ステップ7-1〜7-2）と同じ2段構成（警告文 + フォールバック文）を踏襲する:
- `read-config.sh` で読み取り
- 読み取り失敗時の警告 + フォールバック
- 有効値リストとの完全一致チェック
- 無効値時の警告 + フォールバック

## 完了条件チェックリスト

- [ ] `rules.cycle.mode` 設定キーの仕様定義: 有効値 `default` / `named` / `ask`、デフォルト値 `default`
- [ ] `docs/aidlc.toml` に `[rules.cycle]` セクションとコメント付き `mode` キーを追加
- [ ] Inception Phaseプロンプト（`inception.md`）にStep 5.5として設定値読み取り・バリデーション・フォールバックの指示を追加
- [ ] 警告メッセージフォーマットが `rules.branch.mode` の形式（2段構成: 警告文 + フォールバック文）と統一されていること
- [ ] STARTER_KIT_DEV分岐（Step 3）の遷移先をStep 5.5に変更し、全フローでモード読み取りが実行されること
