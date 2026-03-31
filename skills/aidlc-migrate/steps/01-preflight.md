# ステップ1: 検出とバックアップ

## 0. マイグレーションブランチの作成

### ワーキングツリーのクリーンチェック

まず、未コミットの変更がないことを確認する:

```bash
git status --porcelain
```

- **出力が空**: クリーン。続行する
- **出力がある場合**: 以下を表示して **中断** する:

```text
未コミットの変更が検出されました。
マイグレーション前に変更をコミットまたはstashしてください。

変更をstashするには:
  git stash

マイグレーション完了後に復元:
  git stash pop
```

### ブランチ作成

ワーキングツリーがクリーンであることを確認後、ブランチを作成して切り替える:

```bash
git checkout -b aidlc-migrate/v2
```

ブランチ名は `aidlc-migrate/v2` 固定。既に存在する場合はユーザーに確認する。

## 1. v1環境検出

`migrate-detect.sh` を実行し、manifest JSON を取得する。**stdout が JSON、stderr が診断メッセージ**なので、必ず分離して扱うこと。

```bash
scripts/migrate-detect.sh 2>/dev/null
```

**注意**: stderr の診断メッセージは表示用であり、manifest には含めない。

### 分岐判定

stdout の JSON を解析し、`status` フィールドで分岐する:

- **`already_v2`**: 以下のメッセージを表示して終了:
  ```text
  v2環境が検出されました。移行は不要です。
  ```

- **`v1_detected`**: 移行対象を表示し、ユーザーに確認:
  ```text
  v1環境が検出されました。以下のリソースが移行対象です:

  | リソース種別 | パス | アクション |
  |-------------|------|-----------|
  | ... | ... | ... |

  移行を開始してよろしいですか？
  ```

## 2. manifest 保存

ステップ1で取得した JSON を一時ファイルに保存する:

```bash
# 一時ファイルを作成
mktemp /tmp/aidlc-manifest.XXXXXX

# stdout のみをファイルに保存（stderr は捨てる）
scripts/migrate-detect.sh 2>/dev/null > <manifest_path>
```

保存したパスを後続ステップで使用する。

**注意**: バックアップは不要です。マイグレーションは専用ブランチ（`aidlc-migrate/v2`）で実行されるため、git自体がバックアップとして機能します。問題が発生した場合は `git checkout .` で復元できます。

## 3. 次のステップへ

ステップ2（02-execute.md）の指示に従う。
