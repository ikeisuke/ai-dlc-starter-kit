# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 設定読み込み【重要】

AI-DLCの設定は `docs/aidlc.toml` と `docs/aidlc.toml.local`（個人設定）からマージして取得します。

**読み込み方法**:

```bash
# 単一キーモード（推奨）
docs/aidlc/bin/read-config.sh <key> [--default <value>]

# バッチモード（複数キーを一括取得）
docs/aidlc/bin/read-config.sh --keys <key1> [key2] ...

# 例
docs/aidlc/bin/read-config.sh rules.reviewing.mode
docs/aidlc/bin/read-config.sh rules.jj.enabled --default "false"
docs/aidlc/bin/read-config.sh --keys rules.reviewing.mode rules.jj.enabled rules.squash.enabled
```

**モードの使い分け**:
- 単一キーモード: 1つの設定値を取得。`--default` でフォールバック値を指定可能
- バッチモード: 複数の設定値を `key:value` 形式で一括取得。不在キーはスキップされる
- **注意**: `--keys` と `--default`、`--keys` と位置引数 `<key>` は同時に使用できません

**終了コード**:
- 0: 値あり
- 1: キー不在（単一モード: デフォルトなし / バッチモード: 全キー不在）
- 2: エラー

**マージルール**:
- `.local` の値が存在するキーはベースを上書き
- 配列は完全置換（マージしない）
- 詳細は `docs/aidlc/guides/config-merge.md` を参照

**注意**: `docs/aidlc.toml.local` は `.gitignore` に追加されるため、個人の設定を安全に上書きできます。

## ユーザーの承認プロセス【重要】

計画作成後、必ず以下を実行する:

1. 計画ファイルのパスをユーザーに提示
2. 「この計画で進めてよろしいですか？」と明示的に質問
3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
4. **承認なしで次のステップを開始してはいけない**

## 質問と回答の記録【重要】

独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める。

## 予想禁止・一問一答質問ルール【重要】

不明点や判断に迷う点がある場合、予想や仮定で進めてはいけない。必ずユーザーに質問する。

**質問フロー（ハイブリッド方式）**:

1. まず質問の数と概要を提示する

   ```text
   質問が{N}点あります：
   1. {質問1の概要}
   2. {質問2の概要}
   ...

   まず1点目から確認させてください。
   ```

2. 1問ずつ詳細を質問し、回答を待つ
3. 回答を得てから次の質問に進む
4. 回答に基づく追加質問が発生した場合は「追加で確認させてください」と明示して質問する

**質問すべき場面**:

- 要件が曖昧な場合
- 複数の解釈が可能な場合
- 技術的な選択肢がある場合
- 前提条件が不明確な場合

## Gitコミットのルール

コミットタイミング、メッセージフォーマット、Co-Authored-By設定は `common/commit-flow.md` を参照。

## jjサポート設定

`docs/aidlc.toml`の`[rules.jj]`セクションを確認:

- `enabled = true`: jjを使用。gitコマンドを`docs/aidlc/skills/versioning-with-jj/references/jj-support.md`の対照表で読み替えて実行
- `enabled = false`、未設定、または不正値: 以下のgitコマンドをそのまま使用

## コード品質基準

コード品質基準、Git運用の原則は `docs/cycles/rules.md` を参照
