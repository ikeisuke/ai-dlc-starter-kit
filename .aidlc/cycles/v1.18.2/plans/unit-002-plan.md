# Unit 002 計画: upgrading-aidlcスキルのスクリプト化・PR分離・許可自動化

## 概要

upgrading-aidlcスキルのアップグレード処理をスクリプト化（`upgrade-aidlc.sh`）し、アップグレード用ブランチ・PRの自動分離を実現する。現在は`setup-prompt.md`を読み込んでAIが対話的にステップを実行しているが、定型的なアップグレード処理をスクリプトに集約することで、許可プロンプトの削減と処理の信頼性向上を図る。

## 変更対象ファイル

### Phase A: upgrade-aidlc.shスクリプト新規作成
- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh` - 新規作成（メインスクリプト）

### Phase B: SKILL.md更新
- `prompts/package/skills/upgrading-aidlc/SKILL.md` - スクリプト呼び出し方式に変更

### Phase C: operations.md更新
- `prompts/package/prompts/operations.md` - アップグレード参照をスクリプト呼び出し方式に更新

## 実装計画

### Phase A: upgrade-aidlc.sh スクリプト新規作成

**配置先**: `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`

**責務**: アップグレード処理の一括実行（バージョン更新・設定マイグレーション・rsync同期）

**処理フロー**:

1. **スターターキットパス解決**: 自前ロジックでスターターキットルートを解決（詳細は「パス解決戦略」参照）
2. **セットアップ種別判定**: `check-setup-type.sh`を呼び出してアップグレード可能か判定
3. **バージョン情報取得**: `version.txt`からキットバージョンを読み取り
4. **設定マイグレーション**: `migrate-config.sh`を呼び出して設定更新
5. **パッケージ同期（dry-run）**: `sync-package.sh --dry-run --delete`で差分確認
6. **パッケージ同期（実行）**: `sync-package.sh --delete`で実行
7. **AIツール設定**: `setup-ai-tools.sh`を呼び出してシンボリックリンク更新
8. **バージョン更新**: `docs/aidlc.toml`の`starter_kit_version`を更新
9. **完了サマリ出力**: 同期結果をkey:value形式で出力

**引数**:

| 引数 | 説明 | デフォルト |
|------|------|-----------|
| `--dry-run` | 実際の変更を行わず差分を表示 | なし |
| `--config <path>` | aidlc.toml のパス | `docs/aidlc.toml` |
| `--no-sync` | パッケージ同期をスキップ | なし |
| `--no-migrate` | 設定マイグレーションをスキップ | なし |
| `--force` | アップグレード不要でも強制実行 | なし |

**出力形式**（既存スクリプトのkey:value形式に準拠）:

サブスクリプトの出力はプレフィックスを付けず透過的に転送する（二重プレフィックス防止）。upgrade-aidlc.sh固有の出力のみ独自キーを使用する。

```text
mode:execute              # または mode:dry-run
starter_kit_path:<path>   # 解決されたスターターキットパス
setup_type:<type>         # セットアップ種別
version_from:<ver>        # 現在のバージョン
version_to:<ver>          # アップグレード先バージョン
# --- migrate-config.sh出力（透過転送） ---
# migrate:add-section:rules.backlog
# skip:already-exists:rules.reviewing
# --- sync-package.sh出力（透過転送） ---
# sync:success
# sync_added:path/to/file
# sync_updated:path/to/file
setup_ai_tools:success    # AIツール設定結果（終了コードで判定）
version_updated:true      # バージョン更新結果
status:success            # 最終ステータス
```

**`setup-ai-tools.sh`の出力処理**: `setup-ai-tools.sh`は自由形式テキストを出力するため、stdoutを抑制し終了コードのみで成功/失敗を判定する。`upgrade-aidlc.sh`が`setup_ai_tools:success`または`error:setup-ai-tools-failed`を出力する。

**セットアップ種別ごとの処理分岐**:

| setup_type | 動作 | 終了コード |
|------------|------|-----------|
| `upgrade:<project>:<kit>` | アップグレード実行を続行（正常系） | 0 |
| `cycle_start` + `--force`なし | `skip:already-current:<version>` | 0 |
| `cycle_start` + `--force`あり | アップグレード実行を続行（強制） | 0 |
| `warning_newer:<project>:<kit>` | `warn:project-newer:<project>:<kit>`で続行 | 0 |
| `initial` / `migration` | `error:not-upgrade-target:<type>` | 1 |
| （空値: dasel未インストール） | `warn:dasel-not-found`で続行（version.txtのみで判定） | 0 |

**その他の異常系ハンドリング**:

| 条件 | 動作 | 終了コード |
|------|------|-----------|
| スターターキットパス解決失敗 | `error:starter-kit-not-found` | 1 |
| aidlc.toml不在 | `error:config-not-found:<path>` | 1 |
| migrate-config.sh失敗（exit 1） | `error:migrate-failed` + stderr転送 | 1 |
| migrate-config.sh警告（exit 2） | `warn:migrate-warnings`で続行 | 0 |
| sync-package.sh失敗 | `error:sync-failed` + stderr転送 | 1 |
| setup-ai-tools.sh失敗 | `error:setup-ai-tools-failed` | 1 |

**`--dry-run`時の各ステップ挙動**:

| ステップ | dry-run時の挙動 |
|---------|----------------|
| スターターキットパス解決 | 通常実行（読み取りのみ） |
| セットアップ種別判定 | 通常実行（読み取りのみ） |
| バージョン情報取得 | 通常実行（読み取りのみ） |
| 設定マイグレーション | `migrate-config.sh --dry-run`で実行 |
| パッケージ同期 | `sync-package.sh --dry-run --delete`で実行 |
| AIツール設定 | スキップ（`setup_ai_tools:skipped(dry-run)`出力） |
| バージョン更新 | スキップ（`version_updated:skipped(dry-run)`出力） |

**冪等性保証**: 途中失敗後の再実行で追加差分が発生しないこと。各サブスクリプトが既に冪等性を持つため、upgrade-aidlc.shはそれらを順に呼び出すだけで冪等性が保たれる。

**スクリプト内部の依存スクリプト解決**:

`upgrade-aidlc.sh`は自身の配置位置からスターターキットルートを解決し、そこから各スクリプトのパスを導出する。

**前提条件**: プロジェクトルートをカレントディレクトリとして実行すること。

**パス解決戦略**: `upgrade-aidlc.sh`自身の配置位置（`BASH_SOURCE[0]`）からスターターキットルートを解決する。`resolve-starter-kit-path.sh`には依存しない（後述の理由）。

配置位置パターンと解決方法:
1. `*/prompts/package/skills/upgrading-aidlc/bin/`: メタ開発モード → 5階層上がスターターキットルート
2. `*/docs/aidlc/skills/upgrading-aidlc/bin/`: 利用プロジェクトモード → 環境変数`AIDLC_STARTER_KIT_PATH`を使用
3. 上記以外: `error:starter-kit-not-found`

**`resolve-starter-kit-path.sh`を使わない理由**: `resolve-starter-kit-path.sh`は自身の配置位置（`*/prompts/package/bin`または`*/docs/aidlc/bin`）で判定するが、`upgrade-aidlc.sh`から3階層上の`bin/`にある`resolve-starter-kit-path.sh`を呼ぶ場合でも動作する。ただし、`upgrade-aidlc.sh`自身の方がコンテキスト（メタ開発か利用プロジェクトか）を直接判定できるため、自前で解決する方がシンプルで保守しやすい。

スターターキットルート（`STARTER_KIT_ROOT`）を取得後、以降はすべて`STARTER_KIT_ROOT`からの絶対パスで参照する:
- `sync-package.sh`: `${STARTER_KIT_ROOT}/prompts/package/bin/sync-package.sh`
- `migrate-config.sh`: `${STARTER_KIT_ROOT}/prompts/package/bin/migrate-config.sh`
- `check-setup-type.sh`: `${STARTER_KIT_ROOT}/prompts/setup/bin/check-setup-type.sh`
- `setup-ai-tools.sh`: 同期先の `docs/aidlc/bin/setup-ai-tools.sh`（同期後に実行し最新版を使用するため、意図的にプロジェクトルート基点）
- `version.txt`: `${STARTER_KIT_ROOT}/version.txt`

### Phase B: SKILL.md更新

現在のSKILL.mdは`setup-prompt.md`を検索して読み込む方式だが、スクリプト呼び出し方式に変更する。

**変更内容**:

1. 「実行方法」セクションを`upgrade-aidlc.sh`呼び出しに変更
2. `setup-prompt.md`検索フローを削除
3. スクリプトの出力解釈ガイドを追加
4. アップグレード用ブランチ作成・PR作成フローを追加

**SKILL.md新フロー**:

`upgrade-aidlc.sh`内部で`resolve-starter-kit-path.sh`を呼び出すため、SKILL.mdからは`upgrade-aidlc.sh`を呼ぶだけで完結する。利用プロジェクトモード（`docs/aidlc/bin/`から実行）の場合のみ、事前に環境変数`AIDLC_STARTER_KIT_PATH`の設定が必要であり、その手順をSKILL.mdに記載する。

1. 事前準備（利用プロジェクトモードのみ）: `read-config.sh`で`starter_kit_repo`を取得し、`AIDLC_STARTER_KIT_PATH`を設定
2. `upgrade-aidlc.sh --dry-run`で事前確認
3. dry-run結果をユーザーに提示
4. 承認後、アップグレード用ブランチ作成（`upgrade/vX.X.X`）
5. `upgrade-aidlc.sh`を実行
6. 結果をコミット＆プッシュ
7. PRを作成（gh利用可能時）
8. セッション終了を案内

**ブランチ・PR作成フロー**:

- ブランチ名: `upgrade/vX.X.X`（X.X.Xはアップグレード先バージョン）
- 現在のブランチから作成
- PRタイトル: `chore: AI-DLCをバージョンX.X.Xにアップグレード`
- PRベース: 現在のブランチ（`main`またはサイクルブランチ）
- gh未認証時・ネットワークエラー時: warning出力でスキップ（手動でPR作成するよう案内）

### Phase C: operations.md更新

operations.mdの7行目にある`$(ghq root)/...`の参照を、新しいスクリプト呼び出し方式の案内に更新。

**変更前**（行7）:
```
**セットアッププロンプトパス（アップグレード時のみ）**: $(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md
```

**変更後**:
```
**アップグレード**: `/upgrading-aidlc` スキルを使用してください。
```

**変更前**（行672-673）:
```
**AI-DLCスターターキットをアップグレードする場合**: `${SETUP_PROMPT}` を読み込んでください。
（ghq形式の場合: `$(ghq root)/${SETUP_PROMPT#ghq:}` で展開可能）
```

**変更後**:
```
**AI-DLCスターターキットをアップグレードする場合**: `/upgrading-aidlc` スキルを実行してください。
```

## 完了条件チェックリスト

- [x] `upgrade-aidlc.sh`スクリプトが新規作成されていること（バージョン更新・設定マイグレーション・rsync同期を一括実行）
- [x] `--dry-run`オプションが動作すること
- [x] 異常系ハンドリング: サブスクリプト失敗時にエラー出力と適切な終了コードを返すこと
- [x] 冪等性保証: 途中失敗後の再実行で追加差分が発生しないこと
- [x] SKILL.mdがスクリプト呼び出し方式に更新されていること
- [x] アップグレード用ブランチ作成・PR自動作成フローがSKILL.mdに記述されていること
- [x] SKILL.md内の`$(ghq root)`, `$(read-config.sh ...)`パターンが排除されていること（Unit 001で対応済み、維持確認）
- [x] スターターキットパス解決が自前ロジックで実装されていること（メタ開発・利用プロジェクト両モード対応）
- [x] operations.mdの`$(ghq root)`参照がスキル呼び出し案内に更新されていること
- [x] gh未認証時・ネットワークエラー時はwarning出力でスキップすること
- [x] 出力形式が既存スクリプトのkey:value形式に統一されていること
