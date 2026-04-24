# Unit 008 計画: Milestone 運用 opt-out 設定の追加

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/008-milestone-opt-out-setting.md`
- **担当ストーリー**: 追加ストーリー（v2.4.0 Operations Phase 中の振り返りで浮上）
- **関連 Issue**: #597（追加対応：Unit G。Unit A は Unit 006、Unit B は Unit 005、Unit C は Unit 007）
- **依存 Unit**: Unit 005（完了済み）/ Unit 006（完了済み）/ Unit 007（完了済み）
- **見積もり**: 3〜4 時間

## 課題と修正方針

### 課題

Unit 005 / 006 / 007 で「本採用」として実装した GitHub Milestone 運用は、以下の点で**全プロジェクトへの強制適用**となっており、利用者の選択権を奪う:

1. `04-completion.md` ステップ 5.5 で `gh_status != available` 時 `exit 1`（Milestone close 未実施でサイクル完了させない契約）
2. `01-setup.md` ステップ 11 で `LINK_FAILED` が 1 件以上ある場合 `exit 1`（紐付け未達のまま 5.5 に進ませない契約）
3. v2.4.0 にアップグレードした既存利用者は config を編集せずとも Milestone 機能（Inception 自動作成 / Operations 自動 close）が動き始める

メタ開発リポジトリ自身は v2.3.6 試験運用 + v2.4.0 本採用継続のため Milestone を使い続けたいが、配布側のデフォルトは「未設定では Milestone 機能が一切動かない」が望ましい。

### 修正方針

`[rules.github].milestone_enabled`（boolean、既定 `false`）を新設し、各 Milestone 関連ステップの**冒頭にガード分岐**を追加する。Unit 005 / 006 / 007 で確立した実装本体（5 ケース判定 / 冪等補完原則 / 手動復旧 3 パターン分岐 / Keep a Changelog 順序 / `gh_status != available` 時の exit 1 契約）は触らず、ガードのみを上乗せする。

具体的修正対象:

1. **`skills/aidlc/config/defaults.toml`**（正本）: `[rules.github]\nmilestone_enabled = false` を追加
2. **`skills/aidlc-setup/config/defaults.toml`**（同期コピー）: 正本と同じ追記
3. **`skills/aidlc/steps/inception/02-preparation.md`** ステップ 16 の Milestone 紐付けブロック冒頭にガード追加
4. **`skills/aidlc/steps/inception/05-completion.md`** ステップ 1 の Milestone 作成ブロック冒頭にガード追加（エクスプレスモード完了処理セクション 2 もステップ 1 に委譲しているため自動波及）
5. **`skills/aidlc/steps/inception/index.md`** Milestone（v2.4.0以降）参照箇所に「`milestone_enabled=true` のみ動作」の補足追加
6. **`skills/aidlc/steps/operations/01-setup.md`** ステップ 11 冒頭にガード追加
7. **`skills/aidlc/steps/operations/04-completion.md`** ステップ 5.5 冒頭にガード追加（**`milestone_enabled=false` 時は `gh_status != available` 時 exit 1 契約も発動しない**）
8. **`skills/aidlc/steps/operations/index.md`** §2.8 補助契約に `enabled` 条件追加
9. **`docs/configuration.md`** に新規セクション `[rules.github]` 追加
10. **`skills/aidlc/guides/issue-management.md` / `backlog-management.md` / `backlog-registration.md` / `glossary.md`**: 「既定 off + 明示設定で有効化」の前提を追記
11. **`CHANGELOG.md` `[2.4.0]` 節 `### Added`**: Unit G の opt-out 設定追加を追記
12. **`.aidlc/config.toml`**: メタ開発リポジトリ自体に `[rules.github].milestone_enabled = true` を明示設定

### ガード実装方針

既存ステップで採用されている **`gh_status` 分岐パターン**（自然文での明示的スキップ指示 + 参考 bash スニペット）を踏襲する。`gh_status` 判定は「`gh_status` を参照する。`gh_status` が `available` 以外の場合: スキップ。`available` の場合、以下の手順を実行」という自然文で AI / 人間が解釈する仕組みになっており、Unit 008 の Milestone opt-in ガードもこれと**完全に同じ自然文パターン**で記述する。

理由: 別個の bash コードブロックで `if [ ... ]; then ...; fi` を書いても、後続の bash ブロックは「if 内で `exit 0` しない限り」普通に AI / シェルから読まれて実行される。ガード分岐は「ステップ全体の事前判定」として **Markdown 上の自然文で明示**し、後続の bash 群は条件付き実行であることを言語化する必要がある。

**統一ガード記述（4 箇所共通テンプレート）**:

```markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=<step-id>:reason=opt-out` を出力し、**本ステップ（または本セクション）の Milestone 関連処理をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / Milestone 紐付け / close 処理 / `LINK_FAILED` 集約判定 / `gh_status != available` 時 exit 1 契約は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定および Milestone 関連処理を実行する
```

**設計上の注意**:

- 「条件式 + bash ブロック」の組み合わせを **複数の独立した bash ブロックに分割しない**。bash スニペットは `MILESTONE_ENABLED` の取得 1 行のみとし、判定・分岐は自然文の箇条書きで明示する
- これにより既存の `gh_status` 判定と完全に同じ実行モデル（AI / 人間が自然文を読み、後続 bash の実行可否を判断する）になる
- Operations ステップ 5.5: `milestone_enabled=false` 時は `gh_status != available` 時 exit 1 契約を**自然文レベルで無効化宣言**（「後続の `gh_status` 判定 / `exit 1` 契約は一切実行しない」と明記）

### read-config.sh 終了コードの扱い

`read-config.sh` の実装（`skills/aidlc/scripts/read-config.sh`）に基づき、以下のように扱う。**project config 不在は致命扱いで exit 2**、defaults.toml 不在は警告のみで継続することに注意:

| 終了コード | 状況 | read-config.sh の振る舞い | ガード扱い |
|----------|------|------------------------|----------|
| 0 + 値 `true` | 明示有効化 | 値出力 | Milestone 処理を実行 |
| 0 + 値 `false` / その他 | 明示無効化 / 不正値（`yes` 等） | 値出力 | スキップ |
| 1 | キー不在（defaults.toml にも project にも無い） | 何も出力しない | スキップ（`echo "false"` フォールバック → 既定 false） |
| 2 | dasel 未インストール、または **project config 不在**、または読取失敗 | エラーメッセージを stderr 出力 | スキップ（`2>/dev/null || echo "false"` フォールバック → 既定 false、後方互換最優先） |

**根拠**: 既存の `gh_status` 分岐と整合させ、「設定取得に失敗した場合も既定 false でフォールバック」とすることで、後方互換性【最重要】を堅牢に確保する。`read-config.sh` 実装上、defaults.toml 不在は警告継続（project config に値があれば exit 0）、project config 不在は致命的（exit 2）であることを正確に反映する。終了コード 2 をエラー扱いせずスキップに倒すのは、ステップファイル単独実行時（メタ開発リポ以外でのテスト等）にも Milestone 機能を強制起動しないため。

### 配置検討

| 候補 | ガード位置 | 理由 | 採否 |
|------|----------|------|------|
| (A) ステップ本文の冒頭 1 行 | 各ステップの最初の bash ブロック直前 | 視認性が高く、本文編集の影響を受けにくい | **採用** |
| (B) bash ブロック内の最初の行 | bash ブロック先頭 | 既存スクリプトとの統合度が高い | 不採用（ステップ全体スキップではなく bash 内分岐になる） |
| (C) 共通ライブラリ関数化 | `skills/aidlc/scripts/lib/milestone-guard.sh` 等 | 重複削減 | 不採用（オーバーエンジニアリング、本 Unit はガード追加のみ） |

→ 採用: (A)。各ステップの Milestone 関連ブロック冒頭に **3-5 行のガード分岐**を Markdown 上で追加し、`enabled != true` の場合は本ステップをスキップする旨をメッセージ表示する。

### Unit 005 / 006 / 007 の実装本体との分離

| 既存実装 | 触るか | 理由 |
|---------|-------|------|
| 5 ケース判定（open / closed カウント） | 触らない | Unit 005 / 006 所有、ロジック本体は維持 |
| 冪等補完原則（empty のみ紐付け、他 Milestone は付け替えず警告） | 触らない | Unit 006 所有 |
| 手動復旧 3 パターン分岐（A-1 duplicate / A-2 LINK_FAILED / B gh 不可） | 触らない | Unit 007 所有 |
| Keep a Changelog 順序 | 触らない | Unit 007 所有 |
| `gh_status != available` 時 exit 1 契約 | **`milestone_enabled=false` 時のみ無効化** | Unit 006 所有契約だが、opt-out 時は強制 close を要求しないため |
| LINK_FAILED 集約判定 exit 1 契約 | **`milestone_enabled=false` 時のみ無効化** | 同上 |

**過剰修正回避原則**: 既存 5 ケース判定マトリクスや手動復旧 3 パターン記述は触らない。ガードは「ステップ全体の前段判定」として配置し、本体ロジックには侵入しない。

### マージ前完結ルールとの整合確認

本 Unit はステップファイル + defaults.toml + ドキュメント編集 + メタ開発 `.aidlc/config.toml` 設定追加のみで、GitHub 側操作を含まない。すべて cycle ブランチ配下のファイルとして `.aidlc/cycles/{{CYCLE}}/**` 外（または cycle 内の `.aidlc/config.toml` のみ）に位置するため、PR マージ後の cycle ブランチファイル更新ガード（`write-history.sh` exit 3）の対象外。コミット完了 → PR Ready 化 → main マージで通常の Operations Phase に進む。

## 修正詳細

### 1. `skills/aidlc/config/defaults.toml`

末尾（`[rules.documentation]` の後）に追加:

```toml

[rules.github]
milestone_enabled = false
```

### 2. `skills/aidlc-setup/config/defaults.toml`

正本と同じ位置に同じ内容を追加。**`bin/check-defaults-sync.sh` で同期確認**（コメント・空行は許容、設定値部分の一致を検証）。

### 3. `skills/aidlc/steps/inception/02-preparation.md` ステップ 16

L53 の「Milestone 紐付け」ブロック冒頭（`gh_status` 判定の**前**）に追加:

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=02-preparation-step16:reason=opt-out` を出力し、**本ステップの Milestone 紐付け処理をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定および Milestone 紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定および Milestone 紐付け処理を実行する
````

### 4. `skills/aidlc/steps/inception/05-completion.md` ステップ 1

L60-L70 の「### 1. Milestone 作成・Issue 紐付け」見出しの直後（`gh_status` 判定の前）にガード追加:

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=05-completion-step1:reason=opt-out` を出力し、**本ステップ（1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付け）をすべてスキップ**して次のステップ（履歴記録等）へ進む。後続の `gh_status` 判定および Milestone 作成・紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付けを実行する
````

**注**: 「エクスプレスモード完了処理」セクションのステップ 2 は本ステップ 1 に委譲しているため、ガードは自動波及する（追加編集不要）。

### 5. `skills/aidlc/steps/inception/index.md`

L33 の `inception.05-completion` 行と L113 / L208 の Milestone 参照箇所に `milestone_enabled=true` のみ動作する旨の補足を追加（最小編集）:

- L33: `Milestone（v2.4.0以降）` → `Milestone（v2.4.0以降、`[rules.github].milestone_enabled=true` のみ動作）`
- L113 §2.7 表セル: 同様の補足追加
- L208 4. ステップ読み込み契約: 同様の補足追加

### 6. `skills/aidlc/steps/operations/01-setup.md` ステップ 11

L128 の「### 11. Milestone 紐付け確認・fallback 判定」見出しの直後（`gh_status` 判定の前）にガード追加:

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=01-setup-step11:reason=opt-out` を出力し、**本ステップ（11-1 Milestone 状態確認 + 11-2 関連 Issue 紐付け補完 + 11-3 PR 紐付け確認 + 末尾 `LINK_FAILED` 集約判定）をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / Milestone 紐付け処理 / `LINK_FAILED` 集約判定 exit 1 契約は **一切実行しない**（紐付け処理自体を実施しないため）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 11-1 / 11-2 / 11-3 + 末尾 `LINK_FAILED` 集約判定を実行する
````

### 7. `skills/aidlc/steps/operations/04-completion.md` ステップ 5.5

L183 の「### 5.5 Milestone close【マージ前完結契約準拠】」見出しの直後（`gh_status` 判定の前）にガード追加:

````markdown
**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=04-completion-step5.5:reason=opt-out` を出力し、**本ステップの Milestone close をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / `gh_status != available` 時 exit 1 契約 / Milestone close 5 ケース判定処理は **一切実行しない**（opt-out 時はマージ前完結契約のサイクル完了可視化要件は **opt-out 利用者の責任範囲外** とし、close 自体を要求しないため、警告も表示しない）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定（`available` 以外で exit 1）+ Milestone close 5 ケース判定処理を実行する
````

### 8. `skills/aidlc/steps/operations/index.md` §2.8

L124 の「### 2.8 gh_status 分岐」表および補助契約の冒頭に `enabled` 条件を追加:

- 表内の Milestone 関連行（`available` 以外の例外行）に「**かつ `[rules.github].milestone_enabled=true` のとき**」の条件を追記
- 補助契約に「**`[rules.github].milestone_enabled=false` のときは setup ステップ11 自体がスキップされ本契約は発動しない**」を追記

### 9. `docs/configuration.md`

L156（`### [rules.documentation]` の後、`## カスタマイズ例` の前）に新規セクション追加:

```markdown
### `[rules.github]` — Milestone 運用（v2.4.0 で追加）

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `false` | GitHub Milestone 自動作成 / 紐付け / close 機能を有効にするか。`true` 時は Inception Phase で Milestone 自動作成、Operations Phase で自動 close。`false`（既定）では Milestone 関連ステップが全てスキップされる |

> **後方互換性**: v2.3.6 以前から v2.4.0 にアップグレードする利用者は本キーが未設定のため、Milestone 機能は動作しません。Milestone 運用を有効化したい場合は `.aidlc/config.toml` に `[rules.github]\nmilestone_enabled = true` を追記してください。
```

カスタマイズ例にも追加:

```markdown
### Milestone 運用を有効化する

```toml
[rules.github]
milestone_enabled = true
```
```

### 10. 4 guides

各ファイルの Milestone 関連箇所の先頭に「v2.4.0 以降、`[rules.github].milestone_enabled=true` のとき動作（既定 off）」の前提を 1 行追記:

- `issue-management.md` L52 「2. Milestone 紐付け」項目の最初に追加
- `backlog-management.md` L22 「対応開始時の Milestone 紐付け（v2.4.0 以降）」見出し直下に追加
- `backlog-registration.md` L48 「Milestone について（v2.4.0 以降）」項目に追加
- `glossary.md` L26 Milestone エントリの説明に「`[rules.github].milestone_enabled=true` のとき動作（既定 off）」を追記

### 11. `CHANGELOG.md` `[2.4.0]` 節 `### Added`

L15 の Operations Phase 追加項目の後に追加:

```markdown
- `[rules.github].milestone_enabled` 設定キーを新設（boolean、既定 `false`）。Milestone 運用を opt-in 方式に切り替え、未設定プロジェクト・既存利用者（v2.3.6 以前からのアップグレード者）は Milestone 機能が一切動作しない。Milestone 運用を有効化するには `.aidlc/config.toml` に `[rules.github]\nmilestone_enabled = true` を追記する。本 opt-in 化により、`gh_status != available` 時の `exit 1` 契約および `LINK_FAILED` 集約判定 `exit 1` 契約はいずれも `milestone_enabled=true` のときのみ適用される（後方互換性確保）（#597 / Unit 008 / Unit G）
```

### 12. `.aidlc/config.toml`（メタ開発リポジトリ自体）

末尾に追加:

```toml

[rules.github]
# Milestone 運用設定（v2.4.0 で追加 / Unit 008 / #597 Unit G）
# enabled: true | false - Milestone 自動作成 / 紐付け / close を有効にするか（既定: false）
# - true: Inception Phase で自動作成、Operations Phase で自動 close
# - false: Milestone 関連ステップを全てスキップ
# 本リポジトリは v2.3.6 試験運用 + v2.4.0 本採用継続のため明示有効化
milestone_enabled = true
```

## 動作確認手順

1. **defaults.toml 同期チェック**: `bash bin/check-defaults-sync.sh` を実行 → `sync:ok`
2. **read-config.sh 動作確認**:
   - メタ開発リポ（明示設定）: `scripts/read-config.sh rules.github.milestone_enabled` → `true`、終了コード 0
   - 配布側想定 1（一時的に `.aidlc/config.toml` から `[rules.github]` セクションを削除して検証）: `scripts/read-config.sh rules.github.milestone_enabled` → `false`（defaults.toml フォールバック）、終了コード 0
   - 配布側想定 2（一時的に `defaults.toml` 側の `[rules.github]` も削除し、project / defaults 両方からキーを除去）: `scripts/read-config.sh rules.github.milestone_enabled` → 何も出力しない、終了コード 1。ガード側で `|| echo "false"` フォールバックで `false` 扱い
3. **opt-out 時のスキップ動作検証【最重要】**: `milestone_enabled=false` 時に Milestone 関連処理が **一切実行されないこと** を以下で検証:
   - 一時的に `.aidlc/config.toml` の `milestone_enabled=true` を `false` に変更して保存
   - 修正後の Inception 02-preparation ステップ 16 / 05-completion ステップ 1 / Operations 01-setup ステップ 11 / 04-completion ステップ 5.5 を順に AI / 人間が読み、`MILESTONE_ENABLED != "true"` 判定後に**本ステップの bash 群（`gh_status` 判定 / `gh api` / `gh issue edit` / `LINK_FAILED` 集約判定 / Milestone close）が一切実行されない**ことを確認
   - 期待される出力: `milestone:disabled:skip:step=<step-id>:reason=opt-out` のみ（`gh_status` 判定や Milestone API 呼び出しの出力は含まれない）
   - 確認後、`milestone_enabled=true` に戻す
4. **bash syntax check**: 修正したステップファイル内の `MILESTONE_ENABLED` 取得 bash 行（1 行のみ）に対して `bash -n <(echo "...")` で構文チェック
5. **Markdown 整合性検証**:
   - 修正対象ファイル全てが `markdownlint` 通過
   - 内部リンク（`05-completion.md` ステップ 1 等）が全て解決可能
   - ガード分岐の自然文記述が `gh_status` 判定パターンと一貫していること（「以下を実行する」前段に明示的なスキップ指示）
6. **メタ開発フローでの実行可能性確認**: 本 Unit のコミット直後に `.aidlc/config.toml` の `milestone_enabled=true` で Operations Phase 04-completion ステップ 5.5 が動作することを本サイクル後続の Operations Phase で確認

## 各ステップ修正後の整合性チェック

### 1. Inception 02-preparation.md ステップ 16

ガード追加後、既存の `gh_status` 判定 + Milestone 紐付け処理が `MILESTONE_ENABLED=true` のときのみ実行されることを確認。`MILESTONE_ENABLED=false` 時は処理スキップ + ログ出力のみ。

### 2. Inception 05-completion.md ステップ 1

ガード追加後、1-1 / 1-2 両方が `MILESTONE_ENABLED=true` のときのみ実行されることを確認。エクスプレスモードのステップ 2 は本ステップ 1 に委譲しているため自動波及。

### 3. Operations 01-setup.md ステップ 11

ガード追加後、11-1 / 11-2 / 11-3 + 末尾 `LINK_FAILED` 集約判定すべてが `MILESTONE_ENABLED=true` のときのみ実行されることを確認。`MILESTONE_ENABLED=false` 時は `LINK_FAILED` 集約判定 exit 1 契約も発動しない。

### 4. Operations 04-completion.md ステップ 5.5

ガード追加後、`gh_status != available` 時の exit 1 契約および 5 ケース判定処理がすべて `MILESTONE_ENABLED=true` のときのみ適用されることを確認。`MILESTONE_ENABLED=false` 時は exit 1 にならず、メッセージ出力のみで通常完了扱い。

## Unit 完了判定基準

- [ ] `skills/aidlc/config/defaults.toml` に `[rules.github]\nmilestone_enabled = false` を追加
- [ ] `skills/aidlc-setup/config/defaults.toml` に同期コピー
- [ ] `bash bin/check-defaults-sync.sh` が `sync:ok`
- [ ] Inception 2 ステップ + Operations 2 ステップに opt-in ガード追加（4 箇所）
- [ ] Inception index.md / Operations index.md に `milestone_enabled=true` 補足追加
- [ ] `docs/configuration.md` に `[rules.github]` セクション追加
- [ ] 4 guides に「既定 off + 明示設定で有効化」追記
- [ ] `CHANGELOG.md` `[2.4.0]` 節 `### Added` に Unit G の opt-out 設定追加を追記
- [ ] `.aidlc/config.toml`（メタ開発リポジトリ）に `[rules.github]\nmilestone_enabled = true` 設定追加
- [ ] `read-config.sh rules.github.milestone_enabled` がメタ開発リポで `true` を返すことを確認
- [ ] codex AI レビュー auto_approved 達成

## 実装上の注意

- **ガード位置の一貫性**: 4 ステップとも「見出し直後 + `gh_status` 判定の前」にガード配置。位置がバラバラだと将来のメンテナンスで認知負荷が増す
- **既存ロジック非干渉**: 5 ケース判定 / 冪等補完原則 / 手動復旧 3 パターン / Keep a Changelog 順序などの本体ロジックには一切手を入れない
- **メタ開発リポの自己整合**: 本 Unit のコミットに `.aidlc/config.toml` の `milestone_enabled=true` 設定追加を含めることで、本 Unit 完了直後の Operations Phase 04-completion ステップ 5.5 で v2.4.0 Milestone を close する流れを維持
- **後方互換性最優先**: `read-config.sh` 終了コード 1 / 2 でもガード非該当（既定 false）として扱い、defaults.toml 不在の旧環境でも安全に動作させる
