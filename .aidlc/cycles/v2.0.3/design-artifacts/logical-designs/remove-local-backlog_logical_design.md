# 論理設計: ローカルバックログ廃止

## 変更方針

`backlog_mode`設定を廃止し、バックログ管理をGitHub Issue固定にする。
プロンプト・スクリプト内のモード分岐を全て削除し、Issue方式のみの記述に統一する。

## カテゴリ別変更詳細

### カテゴリ1: スクリプト変更

#### 1.1 defaults.toml

`[rules.backlog]`セクションを削除。

#### 1.2 resolve-backlog-mode.sh

常に`issue`を返すように簡素化。旧設定検出時はstderr警告。

```bash
resolve_backlog_mode() {
    # 旧設定が残っていれば警告
    # 常に "issue" を返す
}
```

- `_VALID_BACKLOG_MODES`を削除
- `_is_valid_backlog_mode()`を削除
- TOML読み取り関数は旧設定検出用に残す（警告出力のため）
- 最終的に常に`echo "issue"`

#### 1.3 init-cycle-dir.sh

`create_common_backlog_dirs()`関数内のバックログディレクトリ作成処理を無条件スキップに変更。
`resolve-backlog-mode.sh`のsource、`resolve_backlog_mode`呼び出しを削除。

#### 1.4 migrate-detect.sh

バックログディレクトリ検出をmode非依存に変更。
バックログディレクトリが存在すれば常に削除候補として報告。
`backlog_mode`の読み取りと条件分岐（case文）を削除。

#### 1.5 migrate-config.sh

`[rules.backlog]`の新規追加処理（L177-）を削除。旧設定が存在しても新規追加しない。
既存の`[rules.backlog]`は触らない（非破壊的）。

#### 1.6 env-info.sh

- L109付近: `resolve-backlog-mode.sh`のsourceと`backlog.mode`出力行を削除
- L189付近: `--setup`モードでの`backlog.mode`出力を削除

#### 1.7 prompts/package/ 正本ファイル

以下の正本ファイルも同等の変更が必要（skills/aidlc/steps/と対応）:
- `prompts/package/prompts/common/preflight.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/common/rules.md`
- `prompts/package/prompts/common/review-flow.md`
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/operations.md`

#### 1.8 aidlc.toml.template

`prompts/setup/templates/aidlc.toml.template` のL112付近: `[rules.backlog]`セクションを削除。

### カテゴリ2: 設定ファイル

#### 2.1 config.toml.example

`[rules.backlog]`セクションにDEPRECATED注記を追加、または削除。

#### 2.2 .aidlc/config.toml

`[rules.backlog]`セクションにDEPRECATEDコメント追加（既存値は削除しない）。

### カテゴリ3: ステップファイル - 主要変更

#### 3.1 agents-rules.md (L37-52)

バックログ管理テーブルを削除し、以下に置換:

```markdown
## バックログ管理

バックログはGitHub Issueに記録する（`gh issue create`）。
```

排他モード説明（L48-52）も削除。

#### 3.2 preflight.md

`check-backlog-mode.sh`の実行行と`backlog_mode`コンテキスト変数の出力行を削除。

#### 3.3 construction/01-setup.md

- L60-87: 気づき記録フローの`backlog_mode`条件分岐を削除。Issue方式のみの記述に統一
  - `mode=git`/`git-only`のファイル作成パスを削除
  - `mode=issue`/`issue-only`の条件分岐 → 無条件にIssue作成
- L257-279: バックログ確認セクションの条件分岐を削除
  - `mode=git`/`git-only`のls確認 → 削除
  - `mode=issue`/`issue-only`のIssue確認 → 無条件にgh issue list
  - 排他モード/非排他モードの記述 → 削除
  - フォールバック（issueモードでgh不可時のファイル確認） → 削除

#### 3.4 construction/03-implementation.md

- L127-139: バックログ登録のmode分岐を削除
  - `mode = git`/`git-only`のファイル作成パスを削除
  - `mode = issue`/`issue-only`のIssue作成 → 無条件に
  - フォールバック分岐（e節）を削除

#### 3.5 common/rules.md (L598-646)

- L600: `git`/`git-only`のファイル作成パス → 削除
- L610: バックログファイル作成の例文 → Issue作成の例文に
- L618-630: モード別テーブル → 削除し、Issue固定の記述に
- L634: `backlog_mode`コンテキスト変数参照 → 削除
- L646: `git-only`バリデーションエラー → 削除

#### 3.6 common/review-flow.md (L520-613)

- L520: `backlog_mode`取得ロジック → 削除
- L524-526: `mode=git`/`git-only`のファイル作成 → 削除
- L609-613: フォールバック → 削除

### カテゴリ4: ステップファイル - 軽微な変更

#### 4.1 inception/01-setup.md

- L199-204: `backlog_mode`参照・フォールバック記述 → 削除
- L294: backlogディレクトリを除外するgrep → 維持（ディレクトリ自体は旧環境に残りうる）
- L326, L337, L380: backlog予約語チェック → 維持（予約語として残す）
- L415-431: バックログ確認の条件分岐 → Issue確認のみに
- L705-710: ディレクトリ説明のbacklog_mode言及 → 削除

#### 4.2 inception/02-preparation.md

- L10: `backlog_mode`コンテキスト変数 → 削除
- L68-89: バックログ確認セクションの条件分岐 → Issue確認のみに

#### 4.3 inception/05-completion.md

- L85: `backlog_mode`参照 → 削除

#### 4.4 operations/01-setup.md

- L133: `backlog_mode`コンテキスト変数言及 → 削除

#### 4.5 operations/02-deploy.md

- L98-167: バックログ確認・整理の条件分岐 → Issue方式のみに
  - ファイル操作（ls, mv）→ 削除
  - 排他モード記述 → 削除

#### 4.6 operations/04-completion.md

- L29-38: バックログ記録の条件分岐 → Issue作成のみに

#### 4.7 setup/03-migrate.md

- バックログ関連の記述確認・更新

### カテゴリ5: ガイド・ドキュメント

#### 5.1 backlog-management.md

- モードテーブル（L11-16）→ 削除し「GitHub Issueに記録」に
- 排他モード記述（L20-21）→ 削除
- ファイルvsIssue比較テーブル（L29）→ 削除
- 設定セクション（L42-48）→ 廃止注記に
- 推奨設定テーブル（L56-61）→ 削除
- ファイルベース手順（L147-181）→ 削除
- 確認方法の分岐（L190-196）→ Issue方式のみ
- Git駆動のアーカイブ（L222）→ 削除

#### 5.2 backlog-registration.md

- L70: Git方式の行 → 削除

#### 5.3 02-generate-config.md / setup-prompt.md

- backlog_mode設定ヒアリング・生成処理 → 廃止（セクション削除またはスキップ）

### カテゴリ6: 同期

`sync-package.sh`実行で`docs/aidlc/`に反映。

### カテゴリ7: 後方互換性の方針

- **旧設定は読むだけで生成しない**: migrate-config.shは`[rules.backlog]`を新規追加しない
- **manifestからbacklog_modeを削除**: migrate-detect.shのmanifest JSONから`backlog_mode`フィールドを除去
- **ラベル作成条件はgh_statusのみ**: setup-prompt.mdのbacklogラベル作成をbacklog_modeから`gh_status`のみに変更
