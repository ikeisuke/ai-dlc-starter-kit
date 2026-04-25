# 論理設計: Unit 003 - Construction Squash ステップの誤省略抑止

## 概要

Unit 003 で行う `commit-flow.md` への前提チェックセクション追加と `04-completion.md` ステップ 7 の見出し改訂について、Markdown 改訂内容と挿入位置を論理レベルで定義する。実装は Phase 2 で行う。

## アーキテクチャパターン

**手順書ガード前置パターン**: 既存フロー先頭に「前提を確認して条件を満たさないなら早期終了」を挟むパターン。実体は Markdown 手順書の冒頭への分岐記述追加で表現する。

## 改訂対象ファイルと変更構造

### `skills/aidlc/steps/common/commit-flow.md`

#### 挿入位置

現状の構造（L72-82 周辺）:

```text
## Squash統合フロー

`rules.git.squash_enabled=true` の場合、フェーズ完了時に中間コミットを1つにまとめる。

**`/squash-unit` スキルを使用する**。スキルが利用できない場合は `squash-unit.sh` を直接実行する。

| 呼び出し元 | squashメッセージID |
|-----------|-------------------|
| Construction（Unit完了時） | UNIT_COMPLETE |
| Inception（Phase完了時） | INCEPTION_COMPLETE |
```

改訂後の構造:

```text
## Squash統合フロー

`rules.git.squash_enabled=true` の場合、フェーズ完了時に中間コミットを1つにまとめる。

### 前提チェック【必須】

[新規追加: 後述の本文]

### Squash の実行

**`/squash-unit` スキルを使用する**。スキルが利用できない場合は `squash-unit.sh` を直接実行する。

| 呼び出し元 | squashメッセージID |
|-----------|-------------------|
| Construction（Unit完了時） | UNIT_COMPLETE |
| Inception（Phase完了時） | INCEPTION_COMPLETE |
```

#### 「前提チェック【必須】」セクションの本文仕様

```markdown
### 前提チェック【必須】

`scripts/read-config.sh rules.git.squash_enabled` を実行し、結果に応じて分岐する:

| `read-config.sh` の結果 | 動作 | 戻り値 |
|------------------------|------|--------|
| exit 0 + stdout が `true` | Squash 実行へ進む（次のセクション） | （実行結果次第） |
| exit 0 + stdout が `false` | Squash 実行せずフロー終了 | `squash:skipped`（理由ログ: `reason: squash_enabled=false`） |
| exit 1（キー不在） | Squash 実行せずフロー終了 | `squash:skipped`（理由ログ: `reason: squash_enabled=unset`） |
| exit 2 / その他のエラー | Squash 実行せずフロー終了（安全側） | `squash:skipped`（理由ログ: `reason: read-config.sh failed`） |

**判定ロジックの注意点**: `if scripts/read-config.sh rules.git.squash_enabled ; then` のように exit code のみを評価する形式は不適切。`read-config.sh` は `false` を返した場合も exit 0 で正常終了するため、exit code だけで判定すると `false` 設定でも Squash を誤実行してしまう。**exit code と stdout の両方を併せて評価する**こと（具体的な bash パターンは「インターフェース仕様」を参照）。

**シグナル設計の方針**: 既存の `squash:skipped` 文字列をそのまま使う（新シグナル文字列は導入しない）。呼び出し元（`04-completion.md` ステップ 7 の `squash:skipped → ステップ8へ`）の既存分岐記述が改訂不要であり、後方互換性を完全に維持する。

**診断情報**: `reason: ...` の形式でログ（stdout）に追加出力する。これは AI エージェントや運用者が「なぜ skip されたか」を後から確認するための情報。シグナル文字列とは独立しており、既存分岐に影響しない。なお `/squash-unit` スキル本体が返す `squash:skipped:no-commits`（既存）には `reason: ...` 形式の追加ログは付かない。AI エージェントはシグナル文字列のみで分岐し、`reason:` ログの有無で挙動を変えない。
```

### `skills/aidlc/steps/construction/04-completion.md`

#### 見出し改訂（L92）

Before:

```markdown
### 7. Squash（コミット統合）【オプション】
```

After:

```markdown
### 7. Squash（コミット統合）
```

#### 本文補強（見出し直下に追記）

Before（L92-93 付近）:

```markdown
### 7. Squash（コミット統合）【オプション】

コミットが存在しない状態でPR作成（ステップ9）に進んではいけない。
```

After:

```markdown
### 7. Squash（コミット統合）

`rules.git.squash_enabled=true` の場合は本ステップを **必ず実施** する。前提チェック（`squash_enabled` の値判定）は `commit-flow.md` の「Squash統合フロー」冒頭で実施され、`squash_enabled` が `true` でなければ `squash:skipped` として後続のステップ 8 に進む。

コミットが存在しない状態でPR作成（ステップ9）に進んではいけない。
```

## 論理フロー

### Squash統合フロー全体（改訂後）

```text
1. 呼び出し元（04-completion.md ステップ 7 / inception/05-completion.md ステップ 6）からエントリ
2. 前提チェック実行: scripts/read-config.sh rules.git.squash_enabled
3. 分岐判定:
   - true → /squash-unit スキル使用（既存手順）→ squash:success / squash:error
   - true 以外（false / key-absent / error）→ squash:skipped（理由ログ付き）
4. 呼び出し元へシグナル返却
5. 呼び出し元が既存の分岐ロジックでステップ 7a / 8 を選択
```

### `read-config.sh` の exit code 仕様（実コード確認結果）

`skills/aidlc/scripts/read-config.sh` のヘッダコメントおよびメイン処理の確認結果:

```text
終了コード:
  0 - 値あり（設定値を出力）
  1 - キー不在（何も出力しない）
  2 - エラー（dasel未インストール / プロジェクト config ファイル未存在 等）
```

本 Unit の前提チェックは「`true` を返したかどうか」のみを評価し、それ以外（`false` / 未設定 / エラー）はすべて `squash:skipped` に丸める。これにより `read-config.sh` の細かい exit code 区別を呼び出し側手順書に持ち込まない（責任分離）。

## インターフェース仕様

### Bash コマンド使用パターン

| 用途 | コマンド |
|------|---------|
| 設定値読み込み | `scripts/read-config.sh rules.git.squash_enabled` |
| 取得結果の評価 | exit code と stdout の **両方** を組み合わせて判定 |
| ログ出力 | `echo "reason: <理由>"`（stdout） |

#### 推奨判定パターン（プロジェクトルール `$()` 禁止に準拠）

`read-config.sh` の stdout を `$()` で変数代入せず、**一時ファイル経由**で評価する:

```bash
# 一時ファイルに stdout を退避（コマンド置換 $(...) を使わずに値を取得）
scripts/read-config.sh rules.git.squash_enabled > /tmp/aidlc-squash-enabled.out 2>/dev/null
ec=$?
if [ "$ec" = "0" ] && grep -Fxq 'true' /tmp/aidlc-squash-enabled.out; then
    # Squash 実行へ進む
    :
else
    # squash:skipped を出力 + 理由ログ
    case "$ec" in
        0) echo "reason: squash_enabled=false" ;;
        1) echo "reason: squash_enabled=unset" ;;
        *) echo "reason: read-config.sh failed" ;;
    esac
    echo "squash:skipped"
fi
rm -f /tmp/aidlc-squash-enabled.out
```

注: 上記パターンは `$()` コマンド置換を使わず、stdout をファイル経由で取得し `grep -Fxq` で値判定する。`grep -Fxq 'true' file` は固定文字列 `true` の完全一致行があるか検査し、見つかれば exit 0、なければ exit 1 を返す。これにより `read-config.sh` の出力（`true` / `false` / 空）を安全に区別できる。

### 手順書の AI エージェント解釈契約

- 「【必須】」ラベル: 省略不可（AI エージェントが手順を抜かない契約）
- 表形式の分岐: 各行が独立した分岐パターンを表す（曖昧な解釈を排除）
- `reason: ...` のログ: AI エージェントが echo で stdout に出力（運用者が後から trace 可能）

## 非機能要件（NFR）への対応

### パフォーマンス

- 前提チェックは `read-config.sh` の 1 回呼び出しのみ。既存 squash 実行に対する追加コストは無視できる範囲（ミリ秒オーダー）

### セキュリティ

- 該当なし。`read-config.sh` は読み取り専用、`/squash-unit` の権限要件にも変更なし

### スケーラビリティ

- 該当なし。手順書改訂のみで実行時挙動は変わらない

### 可用性

- `squash_enabled=false` 環境への影響: 現状（`commit-flow.md` 冒頭の「`squash_enabled=true` の場合」と本文記述）と等価。前提チェック追加により動作が変わらないことを保証
- `read-config.sh` がエラー（exit 2）を返す異常系でも `squash:skipped` で安全に継続し、後続ステップ 8（通常コミット）に進める

## 実装上の注意事項

- **既存表（呼び出し元と squashメッセージID）の保持**: `commit-flow.md` の「Squash統合フロー」内にある既存テーブル（`Construction（Unit完了時）` / `Inception（Phase完了時）`）は前提チェック追加と独立に維持。改訂時に誤って削除しない
- **「【オプション】」の他箇所引用確認**: `04-completion.md` 内に他箇所で「【オプション】」を引用している記述がないか、および `skills/aidlc/` 配下全体で「Squash + 【オプション】」の組み合わせが残っていないかを Phase 2b で `grep -rn` 確認する
- **Inception Phase 側の見出し点検**: `inception/05-completion.md` ステップ 6 が `commit-flow.md`「Squash統合フロー」を呼び出す箇所を `grep` で確認し、新前提チェックが Inception 完了時にも適用されることを Phase 2b で読み合わせる。**併せて Inception 側の見出し / 本文に「【オプション】」相当の表現が残っていないかも `grep` で確認**（残っている場合は本 Unit のスコープ外として記録し、別 Issue 化を検討）
- **既存ステップ 7 分岐文言の妥当性確認**: `04-completion.md` ステップ 7（L98-100）の `squash:skipped` 分岐記述（「ステップ 7a は提示しない、squash 未実施のため rewrite なし」）は、前提チェック未通過ケース（`squash_enabled=false` 等）でも妥当（rewrite なしで通常コミットへ進むのが正しい）。本 Unit ではこの分岐記述の文言改訂は行わず維持する
- **`/squash-unit` スキル本体不変**: `skills/squash-unit/SKILL.md` および `skills/aidlc/scripts/squash-unit.sh` には変更を加えない（DR-006 整合）

## 技術選定

- **対象ファイル形式**: Markdown（既存 `commit-flow.md` および `04-completion.md` への改訂）
- **bash コマンド**: 既存の `scripts/read-config.sh` のみ。新規スクリプト追加なし
- **シグナル文字列**: 既存の `squash:skipped` をそのまま再利用。新文字列導入なし

## 不明点と質問（設計中に記録）

[Question] 前提チェックを `commit-flow.md` の「Squash統合フロー」のサブセクションとして追加する形式（`### 前提チェック【必須】`）と、フロー本文の冒頭にプレーンな段落として追加する形式のどちらが望ましいか？
[Answer] サブセクション形式（H3 見出し）を採用。理由: (1) 構造が明確で AI エージェントが「前提チェック → Squash 実行」の段階を認識しやすい、(2) 既存「Squash統合フロー」セクション全体の中で前提チェックが独立した責務として位置付けられる、(3) Markdownlint の見出し階層ルール（H2 配下に H3 を置く）と整合する。

[Question] `read-config.sh` の `key-absent` 時に「`unset`」と「未設定」のどちらの語を使うか？
[Answer] ログメッセージは英語キーワードとして `unset` を使う（機械可読性 + 短い）。手順書本文の説明は日本語で「未設定」と書く（人間可読性）。両者を併記して整合させる。
