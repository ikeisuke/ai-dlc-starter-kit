# 論理設計: squash retroactiveモード改善

## 1. 変更概要

squash-unit.shのretroactiveモードにおけるコミットフォーマット依存リスクを軽減する。3段階の戦略チェーン（ハッシュ直接指定 > トレーラー検索 > パターンマッチ）で境界検出の信頼性を向上させる。

## 2. コンポーネント構成

### 2.1 squash-unit.sh 変更箇所

#### 新規グローバル変数

```bash
FROM_COMMIT=""      # --from で指定された開始コミット（フルハッシュ正規化後）
TO_COMMIT=""        # --to で指定された終了コミット（フルハッシュ正規化後）
```

#### 新規関数: validate_from_to_args()

```
入力: FROM_COMMIT, TO_COMMIT, BASE_COMMIT（グローバル変数）
処理:
  1. --from/--to は両方同時に指定する必要がある（片方のみはエラー）
  2. --from/--to と --base は排他（同時指定はエラー）
  3. validate_base_format() で両方のハッシュを検証
  4. git rev-parse でフルハッシュへ正規化
  5. --from が --to の祖先（またはイコール）であることを検証
出力: FROM_COMMIT, TO_COMMIT にフルハッシュを格納
エラー:
  - "Error: --from and --to must be specified together"
  - "Error: --from/--to and --base are mutually exclusive in retroactive mode"
  - "Error: --from {hash} is not an ancestor of --to {hash}"
```

#### 変更関数: find_unit_commit_range_git()

既存のパターンマッチロジックにトレーラー検索を統合する。

```
入力: cycle, unit（引数）、FROM_COMMIT, TO_COMMIT（グローバル変数）
処理:
  戦略1: --from/--to 指定時
    1. FROM_COMMIT..TO_COMMIT の範囲をそのまま使用
    2. git log --reverse --format="%h %H %s" "${FROM_COMMIT}^..${TO_COMMIT}" でコミット一覧取得
    3. 先頭=UNIT_FIRST_COMMIT, 末尾=UNIT_LAST_COMMIT, 全ハッシュ=UNIT_COMMIT_HASHES
    4. return

  戦略2: トレーラー検索（--from/--to 未指定時）
    1. git log --reverse --format="%h %H %s%x00%(trailers:key=Unit-Number,valueonly)" "$log_range" でsubject+trailerを同時取得
    2. NUL区切りで分離: subject部 / trailer部
    3. trailer部から Unit-Number マッチするコミットを境界候補として記録:
       - 開始境界: Unit {prev_unit} のUnit-Number trailerを持つ「最後の」コミットの次
       - 終了境界: Unit {unit} のUnit-Number trailerを持つ「最後の」コミット
       注: 同一Unit-Numberを持つコミットが複数ある場合の終端選択規則:
            1. subject が `feat: [cycle] Unit NNN完了` にマッチするコミットを優先（UNIT_COMPLETE）
            2. 存在しない場合は同一Unit-Numberの最後のコミットを採用
    4. Unit 001の場合: 開始境界 = Inception Phase完了のtrailer（なし）→ subject パターンでInception完了を検出
    5. 両境界が確定 → 成功、UNIT_FIRST/LAST_COMMIT 等を設定、return
    6. 部分的にしかトレーラーが見つからない場合:
       - 警告: "Warning: partial Unit-Number trailers found, falling back to pattern matching"
       - 戦略3にフォールバック

  戦略3: パターンマッチ（既存ロジック、フォールバック）
    1. 既存の subject ベースのパターンマッチで境界検出
    2. フォールバック使用時は警告: "Warning: Unit-Number trailer not found, using commit message pattern matching"

出力: UNIT_FIRST_COMMIT, UNIT_FIRST_COMMIT_FULL, UNIT_LAST_COMMIT, UNIT_LAST_COMMIT_FULL, UNIT_COMMIT_HASHES
エラー:
  - "Error: commits for Unit ${unit} not found in cycle ${cycle}"
  + "Hint: Ensure commit messages follow the pattern 'feat: [${cycle}] Unit ${unit}完了 - ...'"
  + "Hint: Or add 'Unit-Number: ${unit}' trailer to commit messages"
  + "Hint: Or use --from/--to to specify the commit range explicitly"
```

#### 変更関数: parse_args()

`--from` と `--to` オプションのパースを追加する。

#### 変更関数: show_help()

`--from` と `--to` の説明を追加する。

#### 変更箇所: main()

retroactiveフロー内で `validate_from_to_args()` を呼び出し、`--from`/`--to` 指定時は `find_unit_commit_range_git()` の戦略1を使用する。

### 2.2 commit-flow.md 変更箇所

#### コミットメッセージフォーマット一覧テーブル

`UNIT_COMPLETE` と `UNIT_SQUASH_PREP` のテンプレートに `Unit-Number: {NNN}` トレーラーを追加。

#### Unit完了コミットテンプレート

```text
feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}

Unit-Number: {NNN}
Co-Authored-By: {AI_AUTHOR}
```

#### Unit完了準備コミットテンプレート

```text
chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備

Unit-Number: {NNN}
Co-Authored-By: {AI_AUTHOR}
```

#### 事後squash（retroactive）セクション

以下を追加:
- `--from`/`--to` による手動境界指定の使用方法とサンプル
- 「`--from`/`--to` と `--base` は排他」の注意事項
- 「dry-run直後に同一履歴で実行」「rebase後はハッシュが変わるため再取得必須」の注意事項

## 3. データフロー

```
[呼び出し元]
    |
    v
parse_args() → FROM_COMMIT, TO_COMMIT, BASE_COMMIT, RETROACTIVE, UNIT, CYCLE, MESSAGE
    |
    v
validate_retroactive_args()  ← 既存（VCS=git, UNIT必須）
    |
    v
validate_from_to_args()      ← 新規（排他チェック、フルハッシュ正規化）
    |
    v
squash_retroactive_git()
    |
    v
find_unit_commit_range_git()
    |
    +--[from/to指定]→ 戦略1: 直接範囲使用
    |
    +--[from/to未指定]→ 戦略2: trailer検索
    |                      |
    |                      +--[成功]→ 境界確定
    |                      +--[失敗/部分]→ 戦略3: パターンマッチ
    |
    v
[境界確定] → extract_co_authors_for_range() → build_sequence_editor_script() → git rebase -i
```

## 4. エラーハンドリング

| エラー状況 | エラーメッセージ | 終了コード |
|---|---|---|
| --from のみ / --to のみ指定 | `Error: --from and --to must be specified together` | 2 |
| --from/--to と --base 同時指定 | `Error: --from/--to and --base are mutually exclusive in retroactive mode` | 2 |
| --from が --to の祖先でない | `Error: --from {hash} is not an ancestor of --to {hash}` | 1 |
| --from/--to のハッシュ不正 | `Error: --from/--to contains invalid characters` | 1 |
| Unit境界が見つからない（全戦略失敗） | 既存エラー + Hint 3行追加 | 1 |

## 5. 後方互換性

- 既存の `--base` オプションは変更なし（retroactiveでは探索起点として利用可能、`--from`/`--to` とは排他）
- 既存のパターンマッチは戦略3として維持
- `Unit-Number` トレーラーなしのコミットは既存動作のまま
- 新オプション `--from`/`--to` は指定しなければ既存動作に影響なし
