# 論理設計: post-merge-cleanup マルチリモート対応

## 概要

resolve_remote() 関数にマルチリモート対応のフォールバック探索ロジックを追加する。探索ロジックは新規ヘルパー関数 find_remote_by_branch() に分離し、resolve_remote() は検証・適用・警告の責務に集中する。

**重要**: このドキュメントでは設計のみ記述し、実装コードは書かない。

## コンポーネント構成

### 変更対象

- **ファイル**: `prompts/package/bin/post-merge-cleanup.sh`
- **関数**:
  - `resolve_remote()` — 既存関数の修正（探索ロジックを外部委譲）
  - `find_remote_by_branch()` — **新規関数**（探索のみ、副作用なし）

### 変更しないもの

- resolve_remote() の関数シグネチャ（引数: branch_name, error_step, error_code）
- グローバル変数 WT_REMOTE への設定方式
- validate_remote() 関数
- step_0a, step_2 での呼び出し方法

## 入力型の定義

### ブランチ名の扱い

設計全体を通じて、ブランチ名は**短縮名**（例: `cycle/v1.27.1`）で扱う。Git コマンド境界でのみ適切なプレフィックスを付与する:

| コンテキスト | ブランチ名の形式 | 例 |
|-------------|----------------|-----|
| 関数引数・変数 | 短縮名 | `cycle/v1.27.1` |
| git for-each-ref フィルタ | `refs/remotes/*/${branch}` | `refs/remotes/*/cycle/v1.27.1` |
| git ls-remote 引数 | `refs/heads/${branch}` | `refs/heads/cycle/v1.27.1` |

### 引数 branch_name とグローバル BRANCH_NAME の役割

| 変数 | スコープ | 役割 | 使用箇所 |
|------|---------|------|---------|
| `branch_name`（引数） | ローカル | ブランチ追跡設定（`git config`）の参照キー | 戦略1 |
| `BRANCH_NAME`（グローバル） | グローバル | refs/remotes および ls-remote 探索のブランチパス | 戦略2, 3 |
| `effective_branch`（ローカル） | ローカル | 探索キー。`branch_name` が空の場合は `BRANCH_NAME` をフォールバックとして使用 | find_remote_by_branch への入力 |

## find_remote_by_branch() 設計（新規関数）

### 責務

探索キーを受け取り、該当ブランチを持つリモート名を stdout に出力する。見つからない場合は何も出力しない。副作用（グローバル変数更新、警告出力）は持たない。

### インターフェース

- **引数**: `$1` — effective_branch（ブランチ短縮名）
- **出力**: stdout にリモート名（1行）。見つからない場合は空
- **副作用**: なし
- **前提**: カレントディレクトリがリポジトリルート

### 内部フロー

```text
find_remote_by_branch(effective_branch)
│
├─ refs/remotes 探索
│  ├─ git for-each-ref --format='%(refname)' "refs/remotes/*/${effective_branch}"
│  ├─ 出力からリモート名を抽出（sed で refs/remotes/ と /${effective_branch} を除去）
│  ├─ origin 優先タイブレーク: 候補に origin が含まれれば origin を選択
│  └─ ヒットあり → stdout にリモート名を出力して return
│
└─ git ls-remote 探索
   ├─ git remote で全リモート一覧を取得
   ├─ 各リモートに対して:
   │  ├─ <timeout_cmd> git ls-remote --heads <remote> "refs/heads/${effective_branch}"
   │  │  （timeout_cmd は環境に応じて gtimeout 5 / timeout 5 / GIT_HTTP_LOW_SPEED_* から自動選択）
   │  ├─ 失敗/タイムアウト → 次のリモートへ
   │  └─ 出力あり → 候補リストに追加
   ├─ 共通タイブレーク規則: 候補に origin が含まれれば origin、なければ最初の候補
   └─ 候補なし → 何も出力せず return
```

## resolve_remote() フロー設計（修正版）

```text
resolve_remote(branch_name, error_step, error_code)
│
├─ branch_name が空でない場合
│  └─ git config branch.<name>.remote → 成功かつ validate_remote(".", remote) → WT_REMOTE 設定して return
│
├─ effective_branch = branch_name（空なら BRANCH_NAME）
├─ effective_branch が空でない場合
│  ├─ searched=true
│  ├─ candidate = find_remote_by_branch(effective_branch)  # stdout をキャプチャ
│  └─ candidate が空でなく validate_remote(".", candidate) 成功 → WT_REMOTE 設定して return
│
├─ 【既存】origin が存在 → WT_REMOTE="origin"
│  └─ searched=true なら警告出力
│
├─ 【既存】origin 不在 → 最初のリモート
│  └─ searched=true なら警告出力
│
└─ リモートなし → fatal_error
```

## refs/remotes 探索の詳細設計

### refname からリモート名を抽出する方法

`git for-each-ref` の出力 `refs/remotes/<remote>/<branch>` からリモート名を抽出する。

**採用する方法**: `%(refname)` のフルパスを出力し、プレフィックスとサフィックスを除去してリモート名を取得する。

```text
# パターン: refs/remotes/<remote>/cycle/v1.27.1
# 抽出: <remote> 部分

format: %(refname)
filter pattern: refs/remotes/*/${effective_branch}
extraction: sed "s|^refs/remotes/||; s|/${effective_branch}$||"
```

**実装上の考慮**:

- effective_branch にスラッシュが含まれる（`cycle/v1.27.1`）ため、単純な `strip=N` は使えない
- sed のデリミタに `|` を使用（パス中の `/` との衝突回避）

### 複数リモートにヒットした場合（origin 優先タイブレーク）

1. 抽出結果に `origin` が含まれるか確認（`grep -Fqx origin`）
2. 含まれる場合: `origin` を返す
3. 含まれない場合: `head -1` で最初の1件を返す

**理由**: fork 環境では upstream と origin に同名ブランチが存在する可能性がある。step_5（リモートブランチ削除）で `git push --delete` を実行するため、push 権限のある origin を優先することで削除失敗のリスクを軽減する。

## git ls-remote 探索の詳細設計

### 探索ロジック

1. `git remote` で全リモート一覧を取得
2. 各リモートに対して `GIT_TERMINAL_PROMPT=0 <timeout_cmd> git ls-remote --heads <remote> "refs/heads/${effective_branch}"` を実行
3. 出力が空でなければ候補リストに追加
4. **共通タイブレーク規則**: 候補に `origin` が含まれれば `origin` を返す。含まれなければ最初の候補を返す（refs/remotes 探索と同一ポリシー）

### タイムアウト制御（環境適応型）

1リモートあたり5秒のタイムアウトを保証する。環境に応じて以下の優先順で手段を選択:

| 優先順 | 手段 | 検出方法 | プロトコル | 備考 |
|--------|------|---------|----------|------|
| 1 | `gtimeout 5` | `which gtimeout` | 全プロトコル | macOS + Homebrew coreutils |
| 2 | `timeout 5` | `which timeout` | 全プロトコル | Linux / GNU coreutils |
| 3 | `GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=5` + `GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5'` | フォールバック | 全プロトコル | HTTP(S): git組み込み低速検出。SSH: ConnectTimeout で接続タイムアウト |

- 手段の検出は `find_remote_by_branch()` 内で1回のみ実行し、ローカル変数に保持
- GIT_TERMINAL_PROMPT=0 はすべての手段で併用
- **NFR**: いずれの環境・プロトコルでも5秒/リモートのタイムアウト制限が保証される

### パフォーマンス考慮

- refs/remotes 探索が先に成功すれば ls-remote は実行されない（ネットワーク不要）
- ls-remote は全リモートを走査して候補を収集（共通タイブレーク規則の適用のため）
- タイムアウト制御により、オフライン環境での待ち時間を最大 5秒×リモート数 に限定

### エラーハンドリング（障害分離）

- 各リモートへの ls-remote は独立して実行。1つのリモートの失敗が他に波及しない
- タイムアウト超過: 当該リモートをスキップし次のリモートへ
- ネットワークエラー: 当該リモートをスキップし次のリモートへ
- 全リモートで失敗: 空を返す（致命的エラーにはしない）。呼び出し元のフォールバックロジックで処理

## セキュリティ考慮事項

### git ls-remote 探索時の資格情報保護

ls-remote 探索では、リポジトリに登録された全リモートURLへ外向き接続を行う。悪意あるリモートURLが登録されている場合のリスクを軽減するため、以下のハードニングを実施する:

| 対策 | 設定 | 目的 |
|------|------|------|
| 資格情報ヘルパー無効化 | `-c credential.helper=` | 保存済み資格情報の漏洩防止 |
| パスワードプロンプト無効化 | `-c core.askPass=` + `GIT_TERMINAL_PROMPT=0` | 対話的プロンプトの抑止 |
| SSH エージェント無効化 | `-o IdentityAgent=none` | SSH鍵の自動提供を防止 |
| SSH 鍵ファイル無視 | `-o IdentitiesOnly=yes` | デフォルト鍵ファイルの使用を防止 |
| SSH 設定ファイル無視 | `-F /dev/null` | ユーザーSSH設定の影響を排除 |
| バッチモード強制 | `-o BatchMode=yes` | SSH対話プロンプトの抑止 |

### 既知のリスク: 全リモートへの外向き接続

**リスク**: `git remote` で列挙される全リモートURLに対して接続を試行するため、リポジトリに登録された任意のURLへ外向きネットワーク接続が発生する。

**評価**: これは機能要件（マルチリモート探索）に内在するリスクであり、設計上排除できない。以下の理由から受容可能と判断する:

1. **refs/remotes探索が先行**: ローカルキャッシュで解決可能な場合、ls-remote は実行されない（ネットワーク接続なし）
2. **資格情報の完全無効化**: 上記ハードニングにより、接続先への認証情報漏洩リスクは最小化されている
3. **タイムアウト制御**: 各リモートに対して5秒のタイムアウトが保証されており、応答しないホストへの長時間接続は発生しない
4. **リモートURLはユーザー管理**: `git remote add` で登録されたURLのみが対象であり、外部入力から動的に生成されるものではない

## 警告出力の設計

### 条件

- `searched=true`（探索を実行した）にも関わらずフォールバックに到達した場合のみ
- `effective_branch` が空の場合（探索未実行）は警告不要

### 出力形式

```text
message:警告: ブランチ ${effective_branch} のリモートを特定できませんでした。${WT_REMOTE} にフォールバックします
```

### 実装方法

- resolve_remote() 内のローカル変数 `searched=false`
- find_remote_by_branch を呼び出す直前に `searched=true`
- フォールバック到達時に `searched=true` なら警告出力

## テスト戦略

### テスト対象シナリオ

1. **シングルリモート + ブランチあり**: 従来通り git config で解決（回帰テスト）
2. **シングルリモート + ブランチなし**: refs/remotes で origin を発見
3. **マルチリモート + ブランチなし + refs/remotes にあり（origin含む）**: origin を優先選択
4. **マルチリモート + ブランチなし + refs/remotes にあり（origin含まず）**: 最初の1件を選択
5. **マルチリモート + ブランチなし + refs/remotes になし + ls-remote にあり**: ls-remote で発見
6. **マルチリモート + ブランチなし + どこにもなし**: 警告出力 + origin フォールバック
7. **リモートなし**: fatal_error（既存動作）
8. **ls-remote タイムアウト**: タイムアウト後に次のリモートへスキップ

### テスト実装方法

- Git テストリポジトリを一時的に作成してテスト
- find_remote_by_branch() を独立関数として単体テスト可能
