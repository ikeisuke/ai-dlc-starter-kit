# 論理設計: Unit 008 Milestone 運用 opt-out 設定の追加

## 概要

修正対象 15 ファイル（defaults.toml × 2 + Inception 3 ステップファイル + Operations 3 ステップファイル + docs/configuration.md + 4 guides + CHANGELOG + メタ開発リポ `.aidlc/config.toml`）の挿入・置換内容と動作確認手順を定義する。本 Unit はガード追加 + 設定キー新設 + ドキュメント追記のみのため、コンポーネント構成・処理フロー等は採用せず、**ガード位置の一貫性 + Unit 005/006 本体ロジック非干渉 + 後方互換性堅牢確保 + メタ開発リポ自己整合性**を中心に定義する。

**重要**: この論理設計では**コードは書かず**、テキスト挿入・置換位置と内容のみを定義する。具体的なファイル編集は Phase 2 で行う。

## アーキテクチャパターン

ガード分岐 + 設定キー新設（Markdown + TOML）。Unit 005 / 006 / 007 で確定した実装本体に侵入せず、**ステップ冒頭への opt-in ガード追加**と**設定キー既定 false 表明**の組み合わせで opt-out 機能を提供する。

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc/config/defaults.toml` | 末尾に `[rules.milestone]\nenabled = false` を追加（正本） | +3 行 |
| `skills/aidlc-setup/config/defaults.toml` | 正本と同じ追記（同期コピー） | +3 行 |
| `skills/aidlc/steps/inception/02-preparation.md` | ステップ 16「Milestone 紐付け」ブロック冒頭にガード追加（`gh_status` 判定の前） | +14 行 |
| `skills/aidlc/steps/inception/05-completion.md` | 「### 1. Milestone 作成・Issue 紐付け」見出し直後にガード追加 | +14 行 |
| `skills/aidlc/steps/inception/index.md` | L33 / L113 / L208 の Milestone 参照箇所に `enabled=true` 補足追加（最小編集） | +0 行（インライン編集） |
| `skills/aidlc/steps/operations/01-setup.md` | 「### 11. Milestone 紐付け確認・fallback 判定」見出し直後にガード追加 | +15 行 |
| `skills/aidlc/steps/operations/04-completion.md` | 「### 5.5 Milestone close」見出し直後にガード追加 | +15 行 |
| `skills/aidlc/steps/operations/index.md` §2.8 | gh_status 分岐表 + 補助契約に `enabled` 条件追加 | +2 行 |
| `docs/configuration.md` | 新規セクション `[rules.milestone]` + カスタマイズ例追加 | +14 行 |
| `skills/aidlc/guides/issue-management.md` | L52「2. Milestone 紐付け」項目に「既定 off + 明示設定で有効化」前提追加 | +1 行 |
| `skills/aidlc/guides/backlog-management.md` | L22「対応開始時の Milestone 紐付け（v2.4.0 以降）」見出し直下に同様の追記 | +1 行 |
| `skills/aidlc/guides/backlog-registration.md` | L48「Milestone について（v2.4.0 以降）」項目に同様の追記 | +1 行 |
| `skills/aidlc/guides/glossary.md` | L26 Milestone エントリ説明に「`[rules.milestone].enabled=true` のとき動作（既定 off）」追記 | +0 行（インライン編集） |
| `CHANGELOG.md` `[2.4.0]` 節 `### Added` | Unit 008 の opt-out 設定追加項目を末尾追加 | +1 行 |
| `.aidlc/config.toml`（メタ開発リポ自身） | 末尾に `[rules.milestone]\nenabled = true` を明示設定 | +8 行（コメント含む） |

## 修正対象ファイル一覧（実装直前のテキスト挿入・置換内容）

### 1. `skills/aidlc/config/defaults.toml`

#### 修正箇所: 末尾追加（`[rules.documentation]` セクションの後）

```toml

[rules.milestone]
enabled = false
```

### 2. `skills/aidlc-setup/config/defaults.toml`

#### 修正箇所: 末尾追加（正本と同じ位置・同じ内容）

正本（`skills/aidlc/config/defaults.toml`）の追記内容と完全一致させる。`bin/check-defaults-sync.sh` で同期検証する。

### 3. `skills/aidlc/steps/inception/02-preparation.md` ステップ 16

#### 修正箇所: L53 直前（「**Milestone 紐付け**（`gh_status` が `available` の場合、Issueを選択した後）」の前）

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.milestone.enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=02-preparation-step16:reason=opt-out` を出力し、**本ステップの Milestone 紐付け処理をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定および Milestone 紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定および Milestone 紐付け処理を実行する
````

### 4. `skills/aidlc/steps/inception/05-completion.md` ステップ 1

#### 修正箇所: L60 直後（「### 1. Milestone 作成・Issue 紐付け」見出しの次行）

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.milestone.enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=05-completion-step1:reason=opt-out` を出力し、**本ステップ（1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付け）をすべてスキップ**して次のステップ（履歴記録等）へ進む。後続の `gh_status` 判定および Milestone 作成・紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付けを実行する
````

**注**: 「エクスプレスモード完了処理」セクションのステップ 2（L28-L30）は本ステップ 1 に委譲しているため、ガードは自動波及する（追加編集不要）。

### 5. `skills/aidlc/steps/inception/index.md`

#### 修正箇所 1: L33 のステップ表セル

```markdown
| `inception.05-completion` | 完了処理 | Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）／履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |
```

#### 修正箇所 2: L113 §2.7 表セル

```markdown
| `available` | Issue 確認・バックログ確認・Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）紐付け・ドラフト PR 作成をすべて実行 |
```

#### 修正箇所 3: L208 4. ステップ読み込み契約のセル

```markdown
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |
```

### 6. `skills/aidlc/steps/operations/01-setup.md` ステップ 11

#### 修正箇所: L128 直後（「### 11. Milestone 紐付け確認・fallback 判定【重要】」見出しの次行、`gh_status` 判定の前）

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.milestone.enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=01-setup-step11:reason=opt-out` を出力し、**本ステップ（11-1 Milestone 状態確認 + 11-2 関連 Issue 紐付け補完 + 11-3 PR 紐付け確認 + 末尾 `LINK_FAILED` 集約判定）をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / Milestone 紐付け処理 / `LINK_FAILED` 集約判定 exit 1 契約は **一切実行しない**（紐付け処理自体を実施しないため）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 11-1 / 11-2 / 11-3 + 末尾 `LINK_FAILED` 集約判定を実行する
````

### 7. `skills/aidlc/steps/operations/04-completion.md` ステップ 5.5

#### 修正箇所: L183 直後（「### 5.5 Milestone close【マージ前完結契約準拠】」見出しの次行、`gh_status` 判定の前）

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.milestone.enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=04-completion-step5.5:reason=opt-out` を出力し、**本ステップの Milestone close をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / `gh_status != available` 時 exit 1 契約 / Milestone close 5 ケース判定処理は **一切実行しない**（opt-out 時はマージ前完結契約のサイクル完了可視化要件は **opt-out 利用者の責任範囲外** とし、close 自体を要求しないため、警告も表示しない）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定（`available` 以外で exit 1）+ Milestone close 5 ケース判定処理を実行する
````

### 8. `skills/aidlc/steps/operations/index.md` §2.8

#### 修正箇所 1: L132 の表 3 行目（`available` 以外の例外行）

```markdown
| `available` 以外（**例外: Milestone close**） | `04-completion.md` ステップ 5.5 のみ **exit 1 で停止**（サイクル完了の可視化に必須のため、未実施のままサイクル完了させない）。**ただし `[rules.milestone].enabled=false`（既定）時はステップ 5.5 自体がスキップされ本例外は発動しない**。手動代替手順（REST API 直叩き curl + PAT、または GitHub UI 上での手動 close）の完了をもって 5.5 をスキップ可とする |
```

#### 修正箇所 2: L136 の補助契約

```markdown
**補助契約: `gh_status = available` かつ `[rules.milestone].enabled=true` 時の Milestone 紐付け補完失敗**

`01-setup.md` ステップ11 内で `gh api PATCH` 個別呼び出しが失敗し `LINK_FAILED` が 1 件以上ある場合、ステップ11 末尾で **exit 1 で停止**（紐付け未達のまま 04-completion 5.5 を実施するとサイクル可視化が不完全になるため）。失敗対象を手動復旧してから再実行。`gh_status != available` 時は setup ステップ11 はスキップされ本契約は発動しない。**`[rules.milestone].enabled=false`（既定）時も setup ステップ11 自体がスキップされ本契約は発動しない**。
```

### 9. `docs/configuration.md`

#### 修正箇所 1: L156 直後（`### [rules.documentation]` セクションの後、`## カスタマイズ例` の前）

```markdown
### `[rules.milestone]` — Milestone 運用（v2.4.0 で追加）

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `false` | GitHub Milestone 自動作成 / 紐付け / close 機能を有効にするか。`true` 時は Inception Phase で Milestone 自動作成、Operations Phase で自動 close。`false`（既定）では Milestone 関連ステップが全てスキップされる |

> **後方互換性**: v2.3.6 以前から v2.4.0 にアップグレードする利用者は本キーが未設定のため、Milestone 機能は動作しません。Milestone 運用を有効化したい場合は `.aidlc/config.toml` に `[rules.milestone]\nenabled = true` を追記してください。

```

#### 修正箇所 2: L183 直後（カスタマイズ例の末尾、`## 欠落キーの自動検出` の前）

````markdown
### Milestone 運用を有効化する

```toml
[rules.milestone]
enabled = true
```

````

### 10. `skills/aidlc/guides/issue-management.md`

#### 修正箇所: L52「2. Milestone 紐付け」の最初の子項目として追加

```markdown
   - **前提（v2.4.0 以降）**: 本機能は `[rules.milestone].enabled=true` のときのみ動作する（既定 off）。明示有効化していないプロジェクトでは Milestone 紐付けステップ自体がスキップされる
```

### 11. `skills/aidlc/guides/backlog-management.md`

#### 修正箇所: L22「**対応開始時の Milestone 紐付け（v2.4.0 以降）**:」の最初の子項目として追加

```markdown
- **前提（v2.4.0 以降）**: 本機能は `[rules.milestone].enabled=true` のときのみ動作する（既定 off）。明示有効化していないプロジェクトでは Milestone 関連ステップが全てスキップされる
```

### 12. `skills/aidlc/guides/backlog-registration.md`

#### 修正箇所: L48「**Milestone について（v2.4.0 以降）**」の説明文末尾に追加

```markdown
**Milestone について（v2.4.0 以降）**: 新規 Issue 作成時は Milestone 未割当（empty）を初期状態とする。Milestone への正式紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施し、`02-preparation.md` ステップ 16 では既存 Milestone がある場合のみ先行紐付けする（Unit 005 / #597）。**ただし、Milestone 機能は `[rules.milestone].enabled=true` のときのみ動作する（既定 off / Unit 008 / #597 Unit G）**。
```

### 13. `skills/aidlc/guides/glossary.md`

#### 修正箇所: L26 Milestone エントリの説明欄

```markdown
| Milestone | `vX.X.X`（GitHub Milestone title） | GitHub Milestone を AI-DLC のサイクル管理単位として用いる（v2.4.0 以降、`[rules.milestone].enabled=true` のとき動作 / 既定 off）。Inception Phase が自動作成、Operations Phase が自動 close。1 Issue = 1 Milestone 制約 | 全フェーズ | `guides/backlog-management.md` |
```

### 14. `CHANGELOG.md` `[2.4.0]` 節 `### Added`

#### 修正箇所: L15 の Operations Phase 追加項目の後（`### Changed` の前）

```markdown
- `[rules.milestone].enabled` 設定キーを新設（boolean、既定 `false`）。Milestone 運用を opt-in 方式に切り替え、未設定プロジェクト・既存利用者（v2.3.6 以前からのアップグレード者）は Milestone 機能が一切動作しない。Milestone 運用を有効化するには `.aidlc/config.toml` に `[rules.milestone]\nenabled = true` を追記する。本 opt-in 化により、`gh_status != available` 時の `exit 1` 契約および `LINK_FAILED` 集約判定 `exit 1` 契約はいずれも `enabled=true` のときのみ適用される（後方互換性確保）（#597 / Unit 008 / Unit G）
```

### 15. `.aidlc/config.toml`（メタ開発リポジトリ自身）

#### 修正箇所: 末尾追加（最終セクションの後）

```toml

[rules.milestone]
# Milestone 運用設定（v2.4.0 で追加 / Unit 008 / #597 Unit G）
# enabled: true | false - Milestone 自動作成 / 紐付け / close を有効にするか（既定: false）
# - true: Inception Phase で自動作成、Operations Phase で自動 close
# - false: Milestone 関連ステップを全てスキップ
# 本リポジトリは v2.3.6 試験運用 + v2.4.0 本採用継続のため明示有効化
enabled = true
```

## 動作確認手順

### 1. defaults.toml 同期チェック

```bash
bash bin/check-defaults-sync.sh
# 期待: sync:ok（exit 0）
```

### 2. read-config.sh 動作確認

```bash
# メタ開発リポ（明示設定）
scripts/read-config.sh rules.milestone.enabled
# 期待: true、終了コード 0

# 配布側想定 1: project config に [rules.milestone] が無い場合
# （一時的に .aidlc/config.toml の [rules.milestone] セクションを退避してテスト）
scripts/read-config.sh rules.milestone.enabled
# 期待: false（defaults.toml フォールバック）、終了コード 0

# 配布側想定 2: project / defaults 両方からキーを除去した場合
# （一時的に defaults.toml の [rules.milestone] も退避してテスト）
scripts/read-config.sh rules.milestone.enabled
# 期待: 何も出力しない、終了コード 1。ガード側で `|| echo "false"` フォールバックで false 扱い

# 配布側想定 3: PROJECT_CONFIG_FILE 不在の場合（read-config.sh L106-L110 の致命扱い）
# 期待: stderr 診断メッセージ、終了コード 2。ガード側で `2>/dev/null || echo "false"` フォールバックで false 扱い
```

### 3. opt-out 時のスキップ動作検証【最重要】

`enabled=false` 時に Milestone 関連処理が **一切実行されないこと** を以下で検証する。これが本 Unit の主要リスクであり、bash 構文確認だけでは担保できない:

1. 一時的に `.aidlc/config.toml` の `[rules.milestone].enabled` を `true` から `false` に変更して保存
2. 修正後の各ステップファイルを順に AI / 人間が読み、ガード判定後の動作を確認:
   - **Inception 02-preparation ステップ 16**: `milestone:disabled:skip:step=02-preparation-step16:reason=opt-out` のみ出力。L57 以降の `MILESTONE_LOOKUP=...` / `gh issue edit` 等は **一切実行されない**
   - **Inception 05-completion ステップ 1**: `milestone:disabled:skip:step=05-completion-step1:reason=opt-out` のみ出力。1-1 / 1-2 の `gh api` / `gh issue edit` / `awk` 抽出は **一切実行されない**
   - **Operations 01-setup ステップ 11**: `milestone:disabled:skip:step=01-setup-step11:reason=opt-out` のみ出力。11-1 / 11-2 / 11-3 の `gh api` / `gh issue edit` / `LINK_FAILED` 集約判定 exit 1 は **一切実行されない**（ステップ 12 以降に正常進行）
   - **Operations 04-completion ステップ 5.5**: `milestone:disabled:skip:step=04-completion-step5.5:reason=opt-out` のみ出力。`gh_status != available` 時 exit 1 契約 / 5 ケース判定 / `gh api PATCH state=closed` は **一切実行されない**（ステップ 6 以降に正常進行）
3. 確認後、`.aidlc/config.toml` の `enabled=true` に戻す

**検証ポイント**: ガード分岐が独立した bash ブロック + 後続独立 bash ブロックの構造ではなく、**自然文での明示的スキップ指示** + **AI / 人間が条件付きで後続 bash を実行する解釈モデル**になっていること。`gh_status` 判定パターンと完全に同じ実行モデルが達成されていること。

### 4. Markdown 整合性検証

```bash
# 修正対象 Markdown ファイル全てに対して markdownlint 実行
npx markdownlint-cli2 \
  skills/aidlc/steps/inception/02-preparation.md \
  skills/aidlc/steps/inception/05-completion.md \
  skills/aidlc/steps/inception/index.md \
  skills/aidlc/steps/operations/01-setup.md \
  skills/aidlc/steps/operations/04-completion.md \
  skills/aidlc/steps/operations/index.md \
  docs/configuration.md \
  skills/aidlc/guides/*.md \
  CHANGELOG.md
# 期待: 全ファイル lint 通過
```

### 5. bash syntax check

修正したステップファイル内の `MILESTONE_ENABLED` 取得 bash 行（1 行のみ）に対して構文チェック:

```bash
bash -n <(cat <<'EOF'
MILESTONE_ENABLED=$(scripts/read-config.sh rules.milestone.enabled 2>/dev/null || echo "false")
EOF
)
# 期待: 構文エラーなし（exit 0）
```

**注**: ガード判定本体は Markdown 自然文で記述するため、bash 構文チェック対象は `MILESTONE_ENABLED` 取得 1 行のみ。

### 6. メタ開発フローでの実行可能性確認

本 Unit のコミット直後、Operations Phase 04-completion ステップ 5.5 が `MILESTONE_ENABLED=true` で動作することを本サイクル後続の Operations Phase で確認:

```bash
# .aidlc/config.toml の [rules.milestone].enabled が true であることを確認
scripts/read-config.sh rules.milestone.enabled
# 期待: true

# Operations Phase 04-completion ステップ 5.5 実行時のガード非該当確認
# （ステップファイル冒頭の MILESTONE_ENABLED ガードを通過し、本体処理に進む）
# 期待: milestone:v2.4.0:closed:number=2 が出力される
```

## ガード位置の一貫性検証

| ステップ | ガード位置の一貫性 | 検証ポイント |
|---------|------------------|------------|
| Inception 02-preparation ステップ 16 | 「Milestone 紐付け」ブロック冒頭（`gh_status` 判定の前） | `gh_status` 判定よりガードが先に評価される |
| Inception 05-completion ステップ 1 | 「### 1. Milestone 作成・Issue 紐付け」見出し直後 | 1-1 / 1-2 両方をスキップする位置に配置 |
| Operations 01-setup ステップ 11 | 「### 11. Milestone 紐付け確認・fallback 判定」見出し直後 | 11-1 / 11-2 / 11-3 + 末尾集約判定すべてをスキップする位置に配置 |
| Operations 04-completion ステップ 5.5 | 「### 5.5 Milestone close」見出し直後 | `gh_status != available` 時 exit 1 契約および 5 ケース判定すべてをスキップする位置に配置 |

**根拠**: 4 箇所すべて「見出し直後 + `gh_status` 判定の前」にガード配置することで、将来のメンテナンス時の認知負荷を最小化する。位置がバラバラだと「このステップのガードはどこにある？」と探す必要が生じる。

## 後方互換性検証

| 検証項目 | 期待動作 | 検証方法 |
|---------|---------|---------|
| v2.3.6 以前からのアップグレード（project config 未編集 + defaults.toml 配布済み） | Milestone 機能が動作しない、警告も出ない（read-config.sh exit 0 + 値 `false`） | defaults.toml の `enabled = false` がフォールバックとして機能 |
| defaults.toml 配布前 + project config に [rules.milestone] なし環境 | `read-config.sh` exit 1（キー不在）→ ガード `false` 扱いでスキップ | ガード分岐の `\|\| echo "false"` フォールバック |
| dasel 未インストール環境 | `read-config.sh` exit 2 → ガード `false` 扱いでスキップ | ガード分岐の `2>/dev/null \|\| echo "false"` フォールバック |
| PROJECT_CONFIG_FILE 不在環境（read-config.sh L106-L110 で致命扱い） | `read-config.sh` exit 2 → ガード `false` 扱いでスキップ | 同上 |
| `enabled = false` 明示設定 | Milestone 機能が動作しない、メッセージ `milestone:disabled:skip:...:reason=opt-out` 出力 | ガード分岐の `!= "true"` 判定 |
| `enabled = true` 明示設定 | Milestone 機能が動作（既存ロジック実行） | ガード非該当 |
| `enabled = "yes"` 等の不正値 | Milestone 機能が動作しない（厳密一致 `!= "true"`） | ガード分岐の文字列比較 |

## メタ開発リポ自己整合性検証

| 検証項目 | 期待動作 | 検証方法 |
|---------|---------|---------|
| 本 Unit のコミット内容に `.aidlc/config.toml` の `[rules.milestone]\nenabled = true` 追加が含まれる | コミット時の `git diff --stat` で確認 | コミット前に `git diff .aidlc/config.toml` を確認 |
| 本 Unit 完了直後の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close できる | ガード非該当 → 既存ロジック実行 → close 成功 | 次回サイクル（または本サイクル後続）の Operations Phase 実行時に確認 |
| メタ開発リポでの「Milestone 運用」「opt-in ガード機能」の二重テスト成立 | 両機能が同時に動作 | Operations Phase ログで `milestone:` プレフィックスの出力を確認 |

## CHANGELOG セクション順序検証

| セクション | 順序 | Unit 008 の影響 |
|----------|------|----------------|
| `### Added` | 1 番目 | **末尾に Unit 008 項目追加**（既存 2 項目に追加で 3 項目に） |
| `### Changed` | 2 番目 | 触らない（既存 4 項目維持） |
| `### Deprecated` | 3 番目 | 触らない（既存 2 項目維持） |
| `### Removed` | 4 番目 | 触らない（既存 1 項目維持） |

Keep a Changelog 順序（Added → Changed → Deprecated → Removed）は Unit 007 で確立済み。本 Unit はこの順序を維持しつつ `### Added` 内に項目追加するのみ。

## 過剰修正回避検証

| 候補 | 実態調査結果 | 採否 |
|------|------------|------|
| `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記 | Unit 005 / 007 所有のため対象外 | **不採用** |
| 4 guides の本体記述書き換え | Unit 007 で既に整備済みのため、1 行追記のみで足りる | 1 行追記のみ採用 |
| Inception 05-completion エクスプレスモードセクション 2 への独立ガード追加 | 本ステップ 1 に委譲しているため自動波及 | **不採用**（追加編集不要） |
| v2.5.0 以降の opt-out 設定の運用評価 | 本サイクル対象外 | **不採用** |
| `.aidlc/rules.md` への opt-out 設定言及 | grep 確認で関連記述なし | **不採用** |

## 不明点と質問

なし（Plan 段階で全候補の採否を確定済み）。
