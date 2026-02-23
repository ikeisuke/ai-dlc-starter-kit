# Unit 001 計画: read-config.sh 改善

## 概要

read-config.sh のデフォルト値を全キーに設定し、複数キーの一括読み取り機能を追加する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/config/defaults.toml` | 不足キーのデフォルト値追加 |
| `prompts/package/bin/read-config.sh` | `resolve_key` 関数抽出、`--keys` オプション実装、key:value 一括出力 |

**注意**: `docs/aidlc/` 配下のファイルは rsync コピーのため直接編集しない（Operations Phase で同期）。

## 実装計画

### Task 1: defaults.toml への不足キー追加

現在の defaults.toml（17キー）に以下を追加:

| 追加キー | デフォルト値 | 参照元 |
|---------|------------|--------|
| `rules.commit.ai_author` | `""` （空文字） | commit-flow.md（自動検出有効時は空が前提、プロンプト内で参照） |
| `rules.branch.mode` | `"ask"` | Unit 002 の前提条件。ストーリー5の受け入れ基準に基づく |
| `rules.git.commit_on_unit_complete` | `true` | construction.md, operations.md で参照 |
| `rules.git.commit_on_phase_complete` | `true` | 同上 |
| `rules.documentation.language` | `"日本語"` | 各プロンプトで参照 |

**追加しないキー**（プロジェクト固有で汎用デフォルトが不適切）:
- `project.*` - プロジェクト名・技術スタックはプロジェクト固有
- `paths.*` - パスはプロジェクト固有
- `rules.coding.*` - コーディング規約はプロジェクト固有
- `rules.security.*` - セキュリティ要件はプロジェクト固有
- `rules.custom.*` - カスタムルールはプロジェクト固有
- `starter_kit_version` - バージョンはセットアップ時に設定

**選定基準**: 現行プロンプト・スクリプトで `read-config.sh` 経由または `docs/aidlc.toml` の `[rules.*]` として参照されるキーのうち、プロジェクト固有ではない汎用的なキーをdefaults.toml に追加する。

### Task 2: read-config.sh のリファクタリング（resolve_key 関数抽出）

現在の4層マージロジック（148-247行目）をトップレベル手続きから `resolve_key` 関数へ抽出する。

**目的**: 単一キー取得と複数キー一括取得で同一のマージロジックを共有し、重複実装を防ぐ。

**関数シグネチャ**:
```bash
# resolve_key <key>
# 4階層マージで値を解決し、strip_quotesを適用して出力
# 戻り値: 0=存在, 1=不在, 2=エラー
resolve_key() {
    local key="$1"
    # 既存の4層マージロジック（defaults → home → project → local）をここに移動
}
```

### Task 3: --keys オプション実装

**変更箇所**: 引数パース部分（49-74行目付近）

**仕様**:
1. `--keys key1 key2 key3` で複数キーの指定を受け付ける
2. `--keys` の後ろの引数を、次のオプション（`-*`）か引数終端まで読み取る
3. 排他チェック（違反時は終了コード2）:
   - `--keys` と位置引数（単一キー指定）の同時使用はエラー
   - `--keys` と `--default` の同時使用はエラー
4. 異常系:
   - `--keys` の後にキーが0件: エラーメッセージ出力、終了コード2
   - 重複キー: そのまま処理（重複排除しない。出力に同じキーが複数行出る）

### Task 4: key:value 形式の一括出力対応

**出力仕様**:
- 形式: `key:value`（1行に1キー）
- キーが存在しない場合、その行は出力しない（他のキーに影響しない）
- 全キーが存在しない場合: 何も出力せず終了コード1
- 1件以上のキーが取得できた場合: 終了コード0
- 値に `:` が含まれる場合も、最初の `:` をデリミタとして解釈（値の中の `:` はそのまま出力）
- **配列値の扱い**: daselが出力する形式をそのまま使用（例: `['codex']`）。strip_quotes済みの値をそのまま1行で出力する。配列の個別要素への分解は行わない

**実装アプローチ**:
- `resolve_key` 関数をキーごとにループで呼び出す
- 結果をバッファし、最後にまとめて出力

### Task 5: ヘッダーコメント・使用例の更新

read-config.sh のヘッダーコメント（使用方法、パラメータ、使用例）を更新し、`--keys` オプションの情報を追加する。

## 完了条件チェックリスト

- [x] defaults.toml にプロンプト内で参照される全設定キーのデフォルト値が定義されている（`rules.commit.ai_author`, `rules.branch.mode` を含む）
- [x] `read-config.sh rules.reviewing.mode` のように --default なしで呼び出した場合、defaults.toml の値が返り終了コード0となる
- [x] defaults.toml にもプロジェクト設定にもキーが存在しない場合、終了コード1が返る
- [x] 既存の --default オプションは引き続き動作する（後方互換）
- [x] プロジェクト設定やlocal設定がある場合、defaults.toml の値を上書きする（既存の優先順位を維持）
- [x] `read-config.sh --keys key1 key2 key3` で複数キーを一括取得できる
- [x] 出力は `key:value` 形式で、1行に1キーずつ出力される
- [x] キーが存在しない場合、その行は出力されない（他のキーには影響しない）
- [x] 全キーが存在しない場合、何も出力せず終了コード1を返す
- [x] 1件以上のキーが取得できた場合、終了コード0を返す
- [x] 既存の単一キー指定は引き続き動作する
- [x] `--keys` と単一キー指定を同時使用した場合、エラーメッセージ出力・終了コード2
- [x] `--keys` 後にキーが0件の場合、エラーメッセージ出力・終了コード2
- [x] 配列値（`rules.reviewing.tools` 等）が `--keys` で正常に1行出力される
