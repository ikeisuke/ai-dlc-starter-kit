# 論理設計: upgrading-aidlcスキルのスクリプト化

## 1. upgrade-aidlc.sh スクリプト設計

### 1.1 引数仕様

```
Usage: upgrade-aidlc.sh [OPTIONS]

Options:
  --dry-run       実際の変更を行わず差分を表示
  --config PATH   aidlc.tomlのパス（デフォルト: docs/aidlc.toml）
  --no-sync       パッケージ同期をスキップ
  --no-migrate    設定マイグレーションをスキップ
  --force         アップグレード不要でも強制実行
  --help          ヘルプを表示
```

### 1.2 処理フロー詳細

```
START
  │
  ├─ 引数解析（--dry-run, --config, --no-sync, --no-migrate, --force, --help）
  │
  ├─ mode 出力: "mode:execute" or "mode:dry-run"
  │
  ├─ Step 1: スターターキットパス解決（自前ロジック）
  │   └─ BASH_SOURCE[0]からスクリプト配置位置を判定
  │   └─ */prompts/package/skills/*/bin → メタ開発: 5階層上
  │   └─ */docs/aidlc/skills/*/bin → 利用PJ: AIDLC_STARTER_KIT_PATH環境変数
  │   └─ 失敗 → error:starter-kit-not-found → exit 1
  │   └─ 成功 → "starter_kit_path:<path>" 出力
  │
  ├─ Step 2: aidlc.toml存在確認
  │   └─ 不在 → error:config-not-found:<path> → exit 1
  │
  ├─ Step 3: セットアップ種別判定
  │   └─ check-setup-type.sh 呼び出し
  │   └─ 出力パース: RAW="${OUTPUT#setup_type:}" でプレフィックス除去
  │   └─ "setup_type:<type>" 出力（RAW値をそのまま使用）
  │   └─ 分岐:
  │       ├─ upgrade:* → 続行
  │       ├─ cycle_start + --force → 続行
  │       ├─ cycle_start → skip:already-current:<ver> → exit 0
  │       ├─ warning_newer:* → warn:project-newer:*、続行
  │       ├─ initial/migration → error:not-upgrade-target:<type> → exit 1
  │       └─ 空値 → warn:dasel-not-found、version.txt直接比較で続行
  │
  ├─ Step 4: バージョン情報取得
  │   └─ version.txt から KIT_VERSION 読み取り
  │   └─ aidlc.toml から PROJECT_VERSION 読み取り（grepベース、dasel不要）
  │   └─ "version_from:<project>" / "version_to:<kit>" 出力
  │
  ├─ Step 5: 設定マイグレーション（--no-migrate時はスキップ）
  │   └─ migrate-config.sh [--dry-run] 呼び出し
  │   └─ stdout を透過転送
  │   └─ exit 1 → error:migrate-failed → exit 1
  │   └─ exit 2 → warn:migrate-warnings、続行
  │
  ├─ Step 6: パッケージ同期（--no-sync時はスキップ）
  │   └─ 6ディレクトリ分のsync-package.sh呼び出し
  │   └─ 各呼び出しのstdoutを透過転送
  │   └─ 失敗 → error:sync-failed → exit 1
  │
  ├─ Step 7: AIツール設定（--dry-run時はスキップ）
  │   └─ setup-ai-tools.sh 呼び出し（stdout抑制）
  │   └─ 終了コードで判定
  │   └─ 成功 → "setup_ai_tools:success"
  │   └─ 失敗 → error:setup-ai-tools-failed → exit 1
  │   └─ dry-run → "setup_ai_tools:skipped(dry-run)"
  │
  ├─ Step 8: バージョン更新（--dry-run時はスキップ）
  │   └─ aidlc.tomlのstarter_kit_versionをsedで更新
  │   └─ 成功 → "version_updated:true"
  │   └─ dry-run → "version_updated:skipped(dry-run)"
  │
  └─ "status:success" → exit 0
```

### 1.3 パッケージ同期の詳細

setup-prompt.mdのセクション8.2で定義される6ディレクトリを順に同期する:

| # | ソース相対パス | 宛先相対パス |
|---|---------------|-------------|
| 1 | `prompts/package/prompts/` | `docs/aidlc/prompts/` |
| 2 | `prompts/package/templates/` | `docs/aidlc/templates/` |
| 3 | `prompts/package/guides/` | `docs/aidlc/guides/` |
| 4 | `prompts/package/bin/` | `docs/aidlc/bin/` |
| 5 | `prompts/package/skills/` | `docs/aidlc/skills/` |
| 6 | `prompts/package/kiro/` | `docs/aidlc/kiro/` |

各ディレクトリに対して`sync-package.sh --source <src> --dest <dst> --delete [--dry-run]`を呼び出す。ソースパスは`${STARTER_KIT_ROOT}/prompts/package/<subdir>/`（スターターキットルート基点）、宛先パスは`docs/aidlc/<subdir>/`（プロジェクトルート＝カレントディレクトリ基点）で構築する。

**前提**: `upgrade-aidlc.sh`はプロジェクトルートをカレントディレクトリとして実行されること。`setup-ai-tools.sh`も内部で`docs/aidlc`を相対パスで参照しており、同じ前提に依存する。

### 1.4 バージョン更新の詳細

`docs/aidlc.toml`の`starter_kit_version`を更新する方法:

**ターゲットプラットフォーム**: macOS（プロジェクト全体でmacOS前提。`migrate-config.sh`等の既存スクリプトも同様）。

```bash
# grepで存在確認し、sedで置換 or 先頭追加
if grep -q "^starter_kit_version" "$CONFIG_PATH"; then
    # 既存の行を更新（一時ファイル方式: macOS/Linux両対応）
    TMP=$(mktemp)
    sed "s/^starter_kit_version = .*/starter_kit_version = \"${KIT_VERSION}\"/" "$CONFIG_PATH" > "$TMP"
    \mv "$TMP" "$CONFIG_PATH"
else
    # 先頭に追加
    TMP=$(mktemp)
    echo "starter_kit_version = \"${KIT_VERSION}\"" > "$TMP"
    cat "$CONFIG_PATH" >> "$TMP"
    \mv "$TMP" "$CONFIG_PATH"
fi
```

### 1.5 dasel未インストール時のフォールバック

`check-setup-type.sh`が`setup_type:`（空値）を返した場合、`upgrade-aidlc.sh`内でversion.txtとaidlc.tomlからバージョンを直接比較する:

```bash
# aidlc.tomlからstarter_kit_versionをgrepで取得
PROJECT_VERSION=$(grep "^starter_kit_version" "$CONFIG_PATH" | sed 's/.*= *"\(.*\)"/\1/')
KIT_VERSION=$(cat "${STARTER_KIT_ROOT}/version.txt" | tr -d '[:space:]')
```

## 2. SKILL.md 設計

### 2.1 Before（現在のSKILL.md）

```markdown
## 実行方法

以下の手順で `setup-prompt.md` を特定し、読み込んでください。

### setup-prompt.md 検索フロー

`docs/aidlc.toml` の `[project]` セクションから `starter_kit_repo` を取得し、`ghq root` 経由でパスを解決する。

1. 事前にBashで以下を順に実行し、結果を変数に格納:

[ghq root, read-config.sh の実行手順]

2. 取得した値を使ってパスを組み立て:
   [パス組み立て手順]

解決したパスのファイルを読み込む。
```

### 2.2 After（新SKILL.md）

```markdown
## 実行方法

### 事前準備

1. Bashで以下を実行し、スクリプトのパスを確認:

\`\`\`bash
# upgrade-aidlc.sh のパスを確認
ls docs/aidlc/skills/upgrading-aidlc/bin/upgrade-aidlc.sh
\`\`\`

スクリプトが存在しない場合、AI-DLCのバージョンが古い可能性があります。
`prompts/setup-prompt.md` を読み込んで手動アップグレードしてください。

### アップグレード実行

1. dry-runで変更内容を確認:

\`\`\`bash
docs/aidlc/skills/upgrading-aidlc/bin/upgrade-aidlc.sh --dry-run
\`\`\`

2. 結果をユーザーに提示し、続行の承認を得る

3. アップグレード用ブランチを作成:

   事前にBashで現在のブランチ名を取得:
   \`\`\`bash
   git branch --show-current
   \`\`\`

   \`\`\`bash
   git checkout -b upgrade/vX.X.X
   \`\`\`
   （X.X.Xはdry-run出力の `version_to:` の値）

4. アップグレードを実行:

\`\`\`bash
docs/aidlc/skills/upgrading-aidlc/bin/upgrade-aidlc.sh
\`\`\`

5. 変更をコミット:

\`\`\`bash
git add docs/aidlc/ docs/aidlc.toml .claude/ .kiro/
git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"
\`\`\`

6. プッシュ＆PR作成（gh利用可能時）:

   \`\`\`bash
   git push -u origin upgrade/vX.X.X
   \`\`\`

   Writeツールで一時ファイルを作成（内容: PR本文）:
   \`\`\`text
   ## AI-DLC アップグレード

   バージョン X.X.X → Y.Y.Y へのアップグレード

   ### 変更内容
   - [dry-run出力のsync_added/sync_updated/sync_deleted行を要約]
   \`\`\`

   \`\`\`bash
   gh pr create --title "chore: AI-DLCをバージョンX.X.Xにアップグレード" --body-file <一時ファイルパス>
   \`\`\`

   一時ファイルを削除

7. セッション終了を案内
```

### 2.3 メタ開発モードと利用プロジェクトモード

SKILL.mdのスクリプトパスは`docs/aidlc/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`とする（rsync後のパス）。メタ開発モードでは`prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`を使う場合もあるが、SKILL.mdは利用プロジェクト向けに記述する。

**パス解決方針**: `upgrade-aidlc.sh`は自身の`BASH_SOURCE[0]`からスクリプト配置位置を判定し、スターターキットルートを自前で解決する。`resolve-starter-kit-path.sh`には依存しない（`resolve-starter-kit-path.sh`は`*/prompts/package/bin`または`*/docs/aidlc/bin`パターンで判定するが、`upgrade-aidlc.sh`は`skills/*/bin`配下にあり合致しないため）。

**解決ロジック**:
1. 環境変数`AIDLC_STARTER_KIT_PATH`が設定されていればそれを使用
2. スクリプト配置位置が`*/prompts/package/skills/*/bin`の場合: メタ開発モード → 5階層上がスターターキットルート
3. スクリプト配置位置が`*/docs/aidlc/skills/*/bin`の場合: 利用プロジェクトモード → `AIDLC_STARTER_KIT_PATH`が必須（未設定ならghq経由のフォールバック）
4. 上記すべて失敗: `error:starter-kit-not-found`

**利用プロジェクトモードでの`AIDLC_STARTER_KIT_PATH`設定方法**（SKILL.mdに記載）:
- ghq利用時: `ghq root`と`read-config.sh`で`starter_kit_repo`を取得し、パスを組み立てて`export AIDLC_STARTER_KIT_PATH=...`
- 手動: ユーザーにスターターキットの絶対パスを確認

**フォールバック**: `AIDLC_STARTER_KIT_PATH`未設定かつ利用プロジェクトモードの場合、`docs/aidlc/bin/read-config.sh`で`project.starter_kit_repo`を取得し、`ghq root`と組み合わせてパスを解決する。ghqが利用不可の場合は`error:starter-kit-not-found`。

## 3. operations.md 変更

### 3.1 行7の変更

**Before**:
```
**セットアッププロンプトパス（アップグレード時のみ）**: $(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md
```

**After**:
```
**アップグレード**: `/upgrading-aidlc` スキルを使用してください。
```

### 3.2 行672-673の変更

**Before**:
```
**AI-DLCスターターキットをアップグレードする場合**: `${SETUP_PROMPT}` を読み込んでください。
（ghq形式の場合: `$(ghq root)/${SETUP_PROMPT#ghq:}` で展開可能）
```

**After**:
```
**AI-DLCスターターキットをアップグレードする場合**: `/upgrading-aidlc` スキルを実行してください。
```
