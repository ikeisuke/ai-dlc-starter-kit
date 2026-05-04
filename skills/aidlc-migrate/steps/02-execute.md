# ステップ2: 移行実行

ステップ1で取得した `manifest_path` を使用する。

## 1. config.toml パス更新

```bash
scripts/migrate-apply-config.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2**: stderr を確認し、`git checkout .` で変更を復元して中断
- **exit 0 + journal に error エントリ**: 問題箇所を確認し、必要に応じて `git checkout .` で復元して中断

## 2. データ移行

```bash
scripts/migrate-apply-data.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2 または journal に error エントリ**: `git checkout .` で変更を復元して中断

## 3. v1痕跡クリーンアップ

```bash
scripts/migrate-cleanup.sh --manifest <manifest_path>
```

### エラー処理

- **exit 2 または journal に error エントリ**: `git checkout .` で変更を復元し、ユーザーに確認

## 3b. Issueテンプレートの確認

manifest の resources に `action: "confirm_delete"` のエントリがある場合、ユーザーに削除するか確認する。

```text
v1で管理していたIssueテンプレートと同名のファイルが見つかりました。
v2では管理対象外のため、不要であれば削除できます。

{ファイル一覧}

削除しますか？
1. はい - 上記ファイルを削除する
2. いいえ - そのまま残す
```

- 「はい」の場合: 各ファイルを `rm` で削除する
- 「いいえ」の場合: 次のステップへ進む
- `confirm_delete` エントリがない場合: このステップをスキップ

<!-- guidance:id=unit003-migrate-prefs-relocation -->
## 4. 個人好みキー移動提案

**実行条件**: ステップ 1〜3b が成功した直後。エラー時は本セクションをスキップして「## 5. ロールバック手順」へ進む。

**Unit 002 案内との関係（単一ソース原則）**:
新規セットアップ向けの案内は `skills/aidlc-setup/steps/03-migrate.md` の `## 9b` セクション（stable_id: `unit002-user-global`）に集約されています。本セクションは**既存プロジェクトの個別キーごとの移動可否確認**に特化し、案内本文は再掲しません。

### 4.1 個人好みキーの検出

```bash
scripts/migrate-relocate-prefs.sh detect
```

出力フォーマット（タブ区切り）:

| プレフィックス | フィールド構成 |
|--------------|--------------|
| `detected` | `detected\t<key>\t<value>\t<user_global_conflict>` |
| `summary` | `summary\ttotal\t<N>` |

`<user_global_conflict>` は `true` / `false`。`true` の場合、`move` 適用時に追加の上書き確認が必要。

**検出 0 件（`summary total 0`）の場合**: 本セクションをスキップして「## 5. ロールバック手順」へ進む。

### 4.2 各キーごとの移動可否確認（対話遷移規則あり）

**bulk_action 状態管理**:

LLM は本セクション開始時に状態変数 `bulk_action ∈ {none, move-all, keep-all}` を初期値 `none` で保持し、各キーで以下の手順を反復する:

1. **bulk_action == none の場合**: `AskUserQuestion` で 4 択（`header: "個人好み移動"`）を提示
   - `移動 (user-global へ)` → このキーに `move` を適用
   - `そのまま残す` → このキーに `keep` を適用
   - `全件移動 (yes-to-all)` → bulk_action を `move-all` に遷移し、このキー含め残り全キーに `move` を無質問で適用
   - `全件残す (no-to-all)` → bulk_action を `keep-all` に遷移し、このキー含め残り全キーに `keep` を無質問で適用
2. **bulk_action == move-all の場合**: 無質問で `move` を適用
3. **bulk_action == keep-all の場合**: 無質問で `keep` を適用

### 4.3 上書き確認（user_global_conflict=true かつ move 適用時）

`move` 適用キーかつ `<user_global_conflict>` が `true` の場合、追加で `AskUserQuestion` を提示する（`header: "上書き確認"`）:

| 選択肢 | 動作 |
|--------|------|
| 上書き | `scripts/migrate-relocate-prefs.sh move <key> --overwrite` |
| スキップ | `scripts/migrate-relocate-prefs.sh keep <key>`（このキーのみ keep に切り替え） |
| キャンセル | 個人好みキー移動提案フロー全体を中断（後続キーの処理も停止して「## 5. ロールバック手順」へ進む） |

### 4.4 script の呼び出し

各 RelocationAction に対応する script コマンドは以下:

| Action | コマンド |
|--------|---------|
| `Move` | `scripts/migrate-relocate-prefs.sh move <key>` |
| `MoveOverwrite` | `scripts/migrate-relocate-prefs.sh move <key> --overwrite` |
| `Keep` | `scripts/migrate-relocate-prefs.sh keep <key>` |

dry-run コンテキストで実行する場合は `--dry-run` をすべての呼び出しに付与する。

### 4.5 出力解釈

- `move\t<key>\t<value>\tfrom_project\tto_user_global`: 正常移動
- `keep\t<key>`: 非破壊（変更なし）
- `warn:user-global-key-exists:<key>` (stderr): user-global に既存キー検出 + skip。`--overwrite` 未指定時の通常動作
- `error:<type>:<detail>` (stderr): 致命エラー → 「## 5. ロールバック手順」へ進む

### 4.6 冪等性

移動済みキーは project から削除済みのため、次回 `aidlc-migrate` 実行時の detect で再検出されない（idempotency）。本セクションは複数回実行しても、毎回その時点の project 状態を入力とする純粋関数として動作する。

## 5. ロールバック手順

問題が発生した場合:

```bash
git checkout .
```

gitブランチ（`aidlc-migrate/v2`）上で作業しているため、上記コマンドで全変更を復元できます。

## 6. 次のステップへ

全フェーズ成功後、ステップ3（03-verify.md）の指示に従う。
