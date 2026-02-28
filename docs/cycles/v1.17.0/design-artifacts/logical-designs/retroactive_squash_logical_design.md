# 論理設計: squash-unit.sh 事後squash対応

## 概要

squash-unit.shに `--retroactive` モードを追加する。既存のgit reset --soft方式を変更せず、新しいコードパスとしてGIT_SEQUENCE_EDITOR方式の非対話的rebaseを実装する。

**重要**: この論理設計ではコードは書かず、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のsquash-unit.shの構造（グローバル変数 + 関数群 + main関数）を踏襲し、retroactive用の関数群を追加する。mainフロー内で `RETROACTIVE` フラグに基づき分岐する。

## コンポーネント構成

### 関数構成（squash-unit.sh内）

```text
squash-unit.sh
├── グローバル変数（既存 + 追加）
│   ├── RETROACTIVE=false（新規）
│   ├── TREE_HASH_BEFORE=""（新規）
│   ├── UNIT_FIRST_COMMIT=""（新規）
│   ├── UNIT_FIRST_COMMIT_FULL=""（新規）
│   ├── UNIT_LAST_COMMIT=""（新規・短縮。rebase todo照合専用）
│   ├── UNIT_LAST_COMMIT_FULL=""（新規・フル。gitコマンドrev引数用）
│   └── UNIT_COMMIT_HASHES=""（新規・短縮。rebase todo照合専用）
├── 引数解析（既存拡張）
│   ├── parse_args()  ← --retroactive 追加
│   └── validate_retroactive_args()（新規）
├── 起点特定（既存）
│   ├── find_base_commit_git()
│   └── find_base_commit_jj()
├── Unit範囲特定（新規）
│   └── find_unit_commit_range_git()
├── rebase準備（新規）
│   ├── build_sequence_editor_script()
│   ├── build_commit_message_file()
│   └── capture_tree_hash()
├── squash実行（既存 + 新規）
│   ├── squash_git()（既存・変更なし）
│   ├── squash_jj()（既存・変更なし）
│   └── squash_retroactive_git()（新規）
├── 検証（新規）
│   └── verify_tree_hash()
└── main()（既存拡張・retroactive分岐追加）
```

### コンポーネント詳細

#### validate_retroactive_args()
- **責務**: `--retroactive` 時の追加バリデーション
- **チェック項目**:
  - `--vcs=git` であること（jj → `squash:error:unsupported-vcs`）
  - `--unit` が指定されていること（未指定 → エラー）
  - `--unit` が `^[0-9]{3}$` 形式であること
- **依存**: グローバル変数 RETROACTIVE, VCS_TYPE, UNIT

#### find_unit_commit_range_git()
- **責務**: 対象UnitのコミットのFirst/Last/全ハッシュリストを特定
- **依存**: CYCLE, UNIT, BASE_COMMIT（オプション）
- **アルゴリズム**:
  1. `git log --format="%h %H %s" <range>` でコミット一覧取得（range = merge-base..HEAD または base..HEAD）。短縮ハッシュ（%h）とフルハッシュ（%H）の両方を取得
  2. コミットメッセージを逆順（古い順）に走査
  3. **境界判定**: Unit完了コミット（`feat: [{cycle}] Unit {NNN}完了`）を境界アンカーとして使用
  4. Unit開始判定: 前Unitの完了コミット(`feat: [{cycle}] Unit {prev_unit}完了`)の次、またはInception完了コミット(`feat: [{cycle}] Inception Phase完了`)の次
  5. Unit終了判定: 対象Unitの完了コミット(`feat: [{cycle}] Unit {unit}完了`)まで。完了コミットが存在しない場合は次Unitの完了コミットの直前まで、どちらもなければHEADまで
  6. 対象Unitのコミットが見つからない場合 → `squash:error:unit-not-found`
- **出力**: UNIT_FIRST_COMMIT（短縮）, UNIT_FIRST_COMMIT_FULL（フル）, UNIT_LAST_COMMIT（短縮）, UNIT_LAST_COMMIT_FULL（フル）, UNIT_COMMIT_HASHES（短縮ハッシュ改行区切り）
- **ハッシュ使い分け**: 短縮ハッシュはrebase todo照合専用、フルハッシュはgitコマンドのrev引数に使用

#### build_sequence_editor_script()
- **責務**: GIT_SEQUENCE_EDITOR用のbashスクリプトを一時ファイルとして生成
- **依存**: UNIT_FIRST_COMMIT, UNIT_COMMIT_HASHES
- **ロジック**:
  - 入力: rebase todoファイル（$1）
  - 処理: todoファイルを1行ずつ読み、各コミットの短縮ハッシュを照合（rebase todoは短縮ハッシュを使用するため）
    - UNIT_FIRST_COMMIT（短縮）に一致: `pick` → `reword`
    - UNIT_COMMIT_HASHES の2番目以降（短縮）に一致: `pick` → `fixup`
    - それ以外: `pick` のまま
  - 出力: 書き換え済みtodoを同じファイルに上書き
- **実装方式**: bashスクリプト（while read line + case文）で一時ファイルに書き出し→mvで上書き。sed -i は使用しない

#### build_commit_message_file()
- **責務**: GIT_EDITOR用のコミットメッセージ一時ファイルを生成
- **依存**: MESSAGE, CO_AUTHORS
- **出力**: 一時ファイルパス（mktemp使用）

#### capture_tree_hash()
- **責務**: 現在のHEADのツリーハッシュを記録（squash前）
- **ロジック**: `git rev-parse HEAD^{tree}` でツリーオブジェクトのハッシュを取得
- **出力**: TREE_HASH_BEFORE

#### extract_co_authors_for_range()
- **責務**: 対象Unit範囲内のCo-Authored-By情報のみを抽出
- **依存**: UNIT_FIRST_COMMIT_FULL, UNIT_LAST_COMMIT_FULL
- **ロジック**: `git log --format="%b" ${UNIT_FIRST_COMMIT_FULL}^..${UNIT_LAST_COMMIT_FULL}` でUnit範囲のコミットbodyを取得し、Co-Authored-By行を抽出・重複排除
- **注意**: 既存のextract_co_authors()は base..HEAD 全体を対象とするため、retroactiveでは使用しない（別Unitの Co-Author 混入防止）

#### squash_retroactive_git()
- **責務**: GIT_SEQUENCE_EDITOR + GIT_EDITOR方式でrebaseを実行
- **依存**: find_unit_commit_range_git, build_sequence_editor_script, build_commit_message_file, extract_co_authors_for_range
- **処理フロー**:
  1. Co-Authored-By抽出（extract_co_authors_for_range で対象Unit範囲のみ）
  2. rebase起点の特定（UNIT_FIRST_COMMIT_FULL の親コミット: `git rev-parse ${UNIT_FIRST_COMMIT_FULL}^`）
  3. GIT_SEQUENCE_EDITOR スクリプト生成
  4. コミットメッセージファイル生成
  5. `GIT_SEQUENCE_EDITOR="bash <script>" GIT_EDITOR="bash -c 'cat <msgfile> > \"$1\"' --" git rebase -i <parent>`
  6. rebase成功 → 一時ファイル削除 → 新しいHEADハッシュ取得
  7. rebase失敗（conflict） → `git rebase --abort` → 一時ファイル削除 → `squash:error:conflict`
- **エラーリカバリ**: `git rebase --abort` で元の状態に復帰

#### verify_tree_hash()
- **責務**: squash後のツリーハッシュがsquash前と一致することを検証
- **ロジック**: `git rev-parse HEAD^{tree}` を再度取得し、TREE_HASH_BEFORE と比較
- **不一致時**: 警告を出力（ツリーが変わった = rebaseで内容が変わった可能性。ただしrebase自体は成功している）

## スクリプトインターフェース設計

### squash-unit.sh（追加オプション）

#### 引数（追加分）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--retroactive` | 任意 | 事後squashモードを有効化 |

#### 既存引数の制約変更

| 引数 | 変更内容 |
|------|---------|
| `--unit` | `--retroactive` 時は必須。`^[0-9]{3}$` 形式を厳格化 |
| `--vcs` | `--retroactive` 時は `git` のみ許可 |
| `--base` | `--retroactive` 時はオプション（指定時はUnit範囲検索の起点として使用） |

#### 成功時出力
```text
vcs_type:git
retroactive:true
unit_range:{first_hash}..{last_hash}
unit_commit_count:{N}
squash:success:{new_hash}
```

#### ドライラン出力
```text
vcs_type:git
retroactive:true
unit_range:{first_hash}..{last_hash}
unit_commit_count:{N}
[コミット一覧 stderr出力]
squash:dry-run:{N}
```

#### エラー時出力
```text
squash:error:unsupported-vcs    # --retroactive + --vcs=jj
squash:error:unit-not-found     # 対象Unitのコミットが見つからない
squash:error:dirty-working-tree # 作業ツリーが汚い（既存と同じ）
squash:error:conflict           # rebase中にコンフリクト発生
```
終了コード: `1`（一般エラー）、`2`（引数エラー）

#### 使用コマンド例
```bash
# 基本的な事後squash
squash-unit.sh --cycle v1.17.0 --unit 003 --vcs git --retroactive \
  --message "feat: [v1.17.0] Unit 003完了 - 説明"

# ドライラン
squash-unit.sh --cycle v1.17.0 --unit 003 --vcs git --retroactive --dry-run \
  --message "feat: [v1.17.0] Unit 003完了 - 説明"

# 起点明示指定
squash-unit.sh --cycle v1.17.0 --unit 003 --vcs git --retroactive \
  --base abc1234 --message "feat: [v1.17.0] Unit 003完了 - 説明"
```

## 処理フロー概要

### 事後squashの処理フロー

**ステップ**:
1. 引数解析・バリデーション（VCS=git, unit形式チェック）
2. working tree clean チェック
3. mainブランチ保護チェック（既存）
4. Unit コミット範囲特定（find_unit_commit_range_git）
5. 対象コミット数チェック（0件 → skipped, dry-run → 表示のみ）
6. ツリーハッシュ記録（capture_tree_hash）
7. Co-Authored-By抽出（extract_co_authors_for_range: 対象Unit範囲のみ）
8. rebaseスクリプト生成 + メッセージファイル生成
9. `git rebase -i` 実行（GIT_SEQUENCE_EDITOR + GIT_EDITOR）
10. 成功判定（conflict → abort → error / success → 次へ）
11. ツリーハッシュ検証（verify_tree_hash）
12. 一時ファイルクリーンアップ
13. 結果出力（squash:success:{hash}）

**関与するコンポーネント**: parse_args, validate_retroactive_args, find_unit_commit_range_git, extract_co_authors_for_range, build_sequence_editor_script, build_commit_message_file, capture_tree_hash, squash_retroactive_git, verify_tree_hash

## 非機能要件（NFR）への対応

### 互換性
- **要件**: Linux/macOSの `sed -i` 差異に対応
- **対応策**: sed -i は使用しない。bashスクリプト（while read + 一時ファイル + mv）でtodo編集を実装。OS依存を排除

### 安全性
- **要件**: rebase衝突時のリカバリ手順
- **対応策**:
  - conflict検出時は即座に `git rebase --abort` を実行
  - 一時ファイルは trap でクリーンアップ
  - squash前後のツリーハッシュ比較で内容の同一性を検証

## 技術選定
- **言語**: Bash（既存スクリプトと同一）
- **依存コマンド**: git, mktemp, bash

## グローバル変数I/F表（retroactive新規分）

| 変数名 | 設定元関数 | 利用先関数 |
|--------|-----------|-----------|
| RETROACTIVE | parse_args | validate_retroactive_args, main（分岐制御） |
| UNIT_FIRST_COMMIT | find_unit_commit_range_git | build_sequence_editor_script, squash_retroactive_git |
| UNIT_FIRST_COMMIT_FULL | find_unit_commit_range_git | extract_co_authors_for_range, squash_retroactive_git（親コミット特定） |
| UNIT_LAST_COMMIT | find_unit_commit_range_git | （rebase todo照合用、現状未使用） |
| UNIT_LAST_COMMIT_FULL | find_unit_commit_range_git | extract_co_authors_for_range |
| UNIT_COMMIT_HASHES | find_unit_commit_range_git | build_sequence_editor_script |
| TREE_HASH_BEFORE | capture_tree_hash | verify_tree_hash |

## 実装上の注意事項
- 一時ファイルは `mktemp` で作成し、trap EXIT でクリーンアップ
- GIT_SEQUENCE_EDITOR に渡すスクリプトは実行権限付き一時ファイル
- rebase -i の対象範囲は `UNIT_FIRST_COMMIT^`（親コミット）から開始
- `--retroactive` と既存パス（reset --soft）は mainフロー内の分岐で切り替え。コードの混在を避ける
