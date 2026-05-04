# Unit 002 計画: aidlc-setup ウィザードの個人好み推奨案内

## 概要

`aidlc-setup` の対話フローに「個人好みの設定は `~/.aidlc/config.toml`（user-global）に書くことを推奨」する案内テキストを 1 回表示する仕組みを追加する。新規ユーザーが 4 階層マージ仕様（Unit 001 で実装した defaults / user-global / project 共有 / project.local）の意図に初期から気づける運用ガイダンスを実装する。

`aidlc-setup` は markdown-driven のスキル（LLM がステップファイルを順次解釈・実行する形態）であり、本 Unit の主な作業はステップファイル（`skills/aidlc-setup/steps/03-migrate.md`）への新セクション追記とその静的検証テスト追加に集約される。

## 対象キー（user_stories.md ストーリー 2 受け入れ基準準拠）

ストーリー 2 受け入れ基準の AC2 は「対象 7 キー（ストーリー 1 の正規定義）のうち代表 2〜3 件の例示」を要求する。本 Unit は AC2 の指示通り **3 件**（`reviewing.mode` / `automation.mode` / `linting.enabled`）を案内テキスト本文に明示する。Unit 001 の正規 7 キー集合（unit_stories.md ストーリー 1）と整合する範囲で抜粋し、案内文の冗長化を避ける。

| # | キー | 案内文での扱い |
|---|------|----------------|
| 1 | `rules.reviewing.mode` | 例示（必須） |
| 2 | `rules.automation.mode` | 例示（必須） |
| 3 | `rules.linting.enabled` | 例示（必須） |
| 4 | `rules.reviewing.tools` / `rules.git.squash_enabled` / `rules.git.ai_author` / `rules.git.ai_author_auto_detect` | 案内文には個別列挙せず、「他にも個人好みキーは defaults.toml に集約済み」と総括 |

## 現状分析

### `aidlc-setup` の構造

- **markdown-driven**: `skills/aidlc-setup/SKILL.md` がステップファイル（`steps/01-detect.md` → `steps/02-generate-config.md` → `steps/03-migrate.md`）を順次読み込み、LLM が解釈実行する
- **「生成サマリ」相当の箇所**: `steps/03-migrate.md` の `## 10. 完了メッセージと次のステップ` セクション。初回セットアップ／アップグレード／移行の 3 モード分岐で完了メッセージを表示する
- **既存テスト基盤の不在**: `tests/aidlc-setup/` ディレクトリは現時点で存在しない。Unit 001 で確立した `tests/config-defaults/` パターン（bats + helper + fixture + CI 接続）に倣って新設する

### `automation_mode` と aidlc-setup の関係（AC「`--non-interactive` でもログ記録」の解釈）

ストーリー 2 AC「案内テキストは `--non-interactive` モードでもログとして記録される（`stderr` 表示でもよい）」を、現行 `aidlc-setup` の実装範囲で**実動作レベルで保証可能**な形に再定義する:

- **現状の事実**: `aidlc-setup` は現状 `automation_mode` を参照しない（`steps/03-migrate.md` L80 に「フォワード互換のため明記」と既記述あり）。`--non-interactive` という CLI フラグも存在しない（aidlc-setup は markdown-driven skill であり LLM が解釈実行する形態）
- **AC の現実的解釈**: 「非対話モード」を「**`automation_mode` が `semi_auto` / `full_auto` の Express 走行コンテキスト**」と読み替える。Express モード（`/aidlc express` 経由）では `/aidlc setup` も自動走行する想定があり、ユーザー対話確認をスキップしながら案内テキストは確実にログ記録される必要がある
- **本 Unit で保証する実動作**:
  - 9b セクション本文に「**初回セットアップ経路では `automation_mode` が `manual` / `semi_auto` / `full_auto` のいずれでも本セクションをスキップせず、案内を 1 回表示する**」指示を明記する（LLM が automation_mode 判定で本セクションを誤って省略しないことを担保。アップグレード／移行モードでは 9b 自体が実行されないため automation_mode は問わない）
  - 9b セクション本文に「**AI エージェントが echo / printf 等で案内を出力する場合は `>&2`（stderr）にリダイレクトする**」指示を明記する（自動走行ログでログとして記録されるルートを担保）
  - 上記 2 つの指示はテスト観点 C で文字列含有を検査し、markdown 上で**実動作の保証根拠**となる
- **`--non-interactive` フラグ自体の実装**: 本 Unit のスコープ外（aidlc-setup は CLI スクリプトでないため、フラグ受理する実体が無い）。9b セクション本文には「将来 `--non-interactive` 等の非対話モードが導入された場合も同様の挙動とする」と**フォワード互換の参考記述**として残し、AC 文言との対応を明示する
- **テスト観点 C の整合**: 観点 C は「`automation_mode` 全モードでスキップしない」「`stderr` / `>&2` 出力指示」「`--non-interactive` への言及」の 3 要素を検査することで、AC 文言（`--non-interactive`）と実動作保証（automation_mode 全モード対応 + stderr）の両方を担保する

### Unit 001 の前提

- template から個人好み 7 キーは除去済み（コミット `6a0efbe7`）
- defaults.toml には 7 キー全てが正しい値で存在
- 4 階層マージは既存ロジックで動作（変更なし）
- Unit 002 は **template 差分には触れない**（参照のみ）

## 変更対象ファイル

### Phase 1: ステップファイル差分

1. **`skills/aidlc-setup/steps/03-migrate.md`** — 新セクション `## 9b. 個人好み user-global 推奨案内` を追加
   - **挿入位置**: `## 9. Git コミット` の直後、`## 10. 完了メッセージと次のステップ` の直前（生成サマリ表示**直前**）
   - **実行条件**: `## 10` の「初回セットアップの場合」に限定（移行モード／アップグレードモードでは案内を表示しない。理由: 既存ユーザーは過去に同等の案内を見ている可能性 + 既存 project config の運用を尊重）
   - **モード分岐ガイド更新**: `02-generate-config.md` 冒頭テーブルにこのステップを追記しないか確認（実態は 03-migrate.md 内で完結するためテーブル更新は不要だが、ステップ番号付与のため `## 9b` で 03-migrate.md 内に閉じる）
   - **本文の構成**:
     - 4 階層マージ仕様（defaults / user-global / project / project.local）の 1 行説明
     - 代表 3 キー（`rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`）の例示
     - `~/.aidlc/config.toml`（user-global）への記述方法の最小例（コードブロック）
     - 「他にも個人好みキーは defaults.toml に集約済み」の総括 1 文
     - 「project 共有 `.aidlc/config.toml` に書いた場合はチームメンバーにも反映される」のチーム影響注記
   - **出力先指示**:
     - 対話モード（既定）: ユーザー向けコンソール出力（LLM の標準応答）
     - 非対話モード（フォワード互換）: 「`--non-interactive` 等で AI エージェントが echo 経由で出力する場合は `>&2`（stderr）に出力する」と明記
   - **冪等性指示**: 「本セクションは初回セットアップ時の `## 10` の直前に **1 回のみ** 表示する。同一セッション内で他のステップから再表示しない」と明記

### Phase 2: テスト追加（bats 形式 / Unit 001 のパターンに準拠）

`tests/aidlc-setup/` を新設し、markdown ファイルの静的検証テストを追加する。`aidlc-setup` は markdown-driven skill のため、テストは「ステップファイルに必要な指示が含まれているか」を grep ベースで検証する形式となる。

**新規テストファイル**:

- `tests/aidlc-setup/setup-prefs-guidance.bats` — 観点 A / B / C / D の静的検証
- `tests/aidlc-setup/helpers/setup.bash` — 共通ヘルパ（`STEP_FILE_PATH` / `assert_section_exists` / `assert_section_count` / `extract_section_body`）

**観点 A: 案内セクションの存在 + 構造**

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| A1 | `## 9b. 個人好み user-global 推奨案内` ヘッダが `03-migrate.md` に **1 回のみ** 存在する | `grep -c '^## 9b\.' steps/03-migrate.md` が `1` |
| A2 | 9b ヘッダの位置が `## 9. Git コミット` の後 / `## 10. 完了メッセージ` の前に挟まれる | 行番号 `grep -n` で `line_9` / `line_9b` / `line_10` を抽出し `line_9 < line_9b < line_10` を検証（ヘルパ関数 `assert_section_between "9" "9b" "10"` で意図固定化） |
| A3 | 9b セクション本文に `~/.aidlc/config.toml` 文字列が含まれる | `awk` でセクション抽出後 `grep` |

**観点 B: 代表 3 キーの例示**

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| B1 | 9b セクション本文に `rules.reviewing.mode` が含まれる | セクション抽出 + `grep -F` |
| B2 | 9b セクション本文に `rules.automation.mode` が含まれる | 同上 |
| B3 | 9b セクション本文に `rules.linting.enabled` が含まれる | 同上 |

**観点 C: 非対話モード対応指示（AC「`--non-interactive` でもログ記録」の実動作保証）**

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| C1 | 9b セクション本文に `--non-interactive` 文字列（フォワード互換の参考記述）が含まれる | セクション抽出 + `grep -F '--non-interactive'` |
| C2 | 9b セクション本文に `stderr` または `>&2` のいずれかが含まれる | セクション抽出後、`grep -F '>&2'` を実行し exit code が非 0 の場合に `grep -F 'stderr'` でフォールバック検査（2 段判定方式に統一。正規表現エスケープ差分を回避） |
| C3 | 9b セクション本文に `automation_mode` 全モード対応指示（**初回セットアップ経路で** `manual` / `semi_auto` / `full_auto` のいずれでもスキップしない旨）が含まれる | セクション抽出 + `grep -F 'automation_mode'` および 3 モード文字列の含有検査 |

**観点 D: 冪等性とスコープ限定**

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| D1 | `~/.aidlc/config.toml` 推奨案内テキスト（代表キー 3 件すべて含む）が `03-migrate.md` 全体で **1 回のみ** 出現する | `grep -c` での出現数検査（同一文字列の二重定義防止） |
| D2 | 9b セクションは「初回セットアップ」モードに限定する旨の文言（`初回` / `初回セットアップ` のいずれか）を含む | セクション抽出 + `grep` |
| D3 | `02-generate-config.md` および `01-detect.md` には同等の推奨案内が含まれない（単一ソース化の保証） | `grep -L` |

**実行コマンド**: `bats tests/aidlc-setup/`

**fixture 不要**: 静的 markdown 検証のみで動的環境構築が不要なため、`tests/fixtures/aidlc-setup/` は作成しない。

### Phase 3: CI 接続

`.github/workflows/migration-tests.yml` を最小拡張し、Unit 002 のテストも CI で実行されるようにする。

- **PATHS_REGEX 拡張**: 既存に加えて以下を検出対象に追加
  - `tests/aidlc-setup/.+`
  - `skills/aidlc-setup/steps/.+`
- **実行コマンド変更**: `bats tests/migration/ tests/config-defaults/` → `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/`
- **新規 workflow ファイルは作成しない**（Unit 001 と同じ最小拡張方針）

### Phase 4: ドキュメント整合

- Unit 002 定義（`.aidlc/cycles/v2.5.0/story-artifacts/units/002-setup-wizard-prefs-guidance.md`）の「実装状態」を完了に更新
- 設計ドキュメント（domain model / logical design）を Unit 001 と同じディレクトリ構造で作成

## 実装計画

### 設計方針

- **挿入箇所固定原則**: 案内セクションは `03-migrate.md` の `## 9b` に配置し、他のステップファイルからは参照しない（単一ソース化）。これにより冪等性 NFR を構造的に保証する
- **モード限定原則**: 案内は「**初回セットアップ経路**」のみに表示する。アップグレード／移行モードでは表示しない（既存ユーザーへの再表示を避ける + 移行モードは v1→v2 の文脈で別案内が優先される）。`automation_mode` 全モード対応指示は**初回セットアップ経路の内側で**有効となるスコープ条件であり、モード限定原則と直交する（衝突しない）
- **markdown-driven 検証原則**: aidlc-setup が LLM 解釈実行型のため、テストは「ステップファイル markdown に必要な指示文字列が含まれているか」を静的に検証する。動的実行テスト（実際に LLM を走らせて案内が出るか）は範囲外
- **フォワード互換指示**: `--non-interactive` モードはまだ aidlc-setup に存在しないが、将来導入時に「stderr 出力」が指示として markdown に書かれている状態を作る。AC「案内テキストは `--non-interactive` モードでもログとして記録される」は markdown 内の指示文として満たす

### Unit 001 / 003 との境界

| 論点 | 所有 Unit | 他 Unit の扱い |
|------|----------|---------------|
| `config.toml.template` の 7 キー除去 | Unit 001（完了） | Unit 002 / 003 は変更しない |
| `defaults.toml` の 7 キー値 | Unit 001（完了、変更なし） | Unit 002 / 003 は変更しない |
| `config.toml.example` の編集 | Unit 001（完了） | Unit 002 / 003 は参照のみ |
| `aidlc-setup` ウィザード UI 文言（**本 Unit**） | **Unit 002** | Unit 001 / 003 は触れない |
| `aidlc-migrate` 移動提案ロジック | Unit 003 | Unit 001 / 002 は触れない |
| 「個人好みは `~/.aidlc/config.toml` 推奨」案内本文 | **Unit 002（master / 単一ソース）** / Unit 003（参照のみ） | Unit 001 は本文を持たない |

- **Unit 003 の参照スタンス**: aidlc-migrate 側で個人好みキー検出時に「user-global 推奨」案内を出す場合、本 Unit の 9b セクション本文を**コピーせず**、**実装ソース**（`skills/aidlc-setup/steps/03-migrate.md` の `## 9b. 個人好み user-global 推奨案内` セクション）への参照のみで案内する設計とする（計画書ではなく実装ソースを単一ソースとすることで、計画書改訂とのデカップリングを実現）。Unit 003 の計画作成時に再確認する

### ステップ

1. `skills/aidlc-setup/steps/03-migrate.md` に `## 9b. 個人好み user-global 推奨案内` セクションを追加
   - 挿入位置: `## 9. Git コミット` の直後 / `## 10. 完了メッセージ` の直前
   - 実行条件: 初回セットアップ時のみ
   - 本文に代表 3 キー（`rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`）を例示
   - 非対話モード時の stderr 出力指示を明記
   - 冪等性（1 回のみ表示）指示を明記
2. `tests/aidlc-setup/helpers/setup.bash` を新規作成（共通ヘルパ）
3. `tests/aidlc-setup/setup-prefs-guidance.bats` を新規作成（観点 A / B / C / D の 11 ケース以上）
4. `.github/workflows/migration-tests.yml` の `PATHS_REGEX` と実行コマンドを拡張
5. ローカルでテスト実行（`bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/`）— 既存テストへの回帰がないことも確認
6. markdownlint 実行（`.md` 変更があるため必須）
7. コミット

## 完了条件チェックリスト

- [x] `skills/aidlc-setup/steps/03-migrate.md` に `## 9b. 個人好み user-global 推奨案内` セクションが追加されている
- [x] 9b セクションの位置が `## 9. Git コミット` の直後 / `## 10. 完了メッセージ` の直前である
- [x] 9b セクション本文に `~/.aidlc/config.toml` の文字列が含まれる
- [x] 9b セクション本文に代表 3 キー（`rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`）が全て含まれる
- [x] 9b セクション本文に `--non-interactive`（フォワード互換参考）および `stderr`（または `>&2`）の文字列が含まれる
- [x] 9b セクション本文に `automation_mode` 全モード（`manual` / `semi_auto` / `full_auto`）でスキップしない指示が含まれる（AC 実動作保証根拠）
- [x] 9b セクション本文に「初回セットアップ」限定の指示が含まれる
- [x] 9b セクション相当の案内テキストが `01-detect.md` / `02-generate-config.md` には含まれない（単一ソース化）
- [x] **観点 A テスト**: `tests/aidlc-setup/setup-prefs-guidance.bats` がセクション存在 + 構造 + 位置を検証する（A1〜A3 の 3 ケース PASS）
- [x] **観点 B テスト**: 同 bats が代表 3 キーの本文含有を検証する（B1〜B3 の 3 ケース PASS）
- [x] **観点 C テスト**: 同 bats が `--non-interactive` / stderr 指示 / automation_mode 全モード対応の 3 要素含有を検証する（C1〜C3 の 3 ケース PASS）
- [x] **観点 D テスト**: 同 bats が冪等性（出現数 = 1）とスコープ限定（初回セットアップのみ）を検証する（D1 / D2 / D3 / D3b の 4 ケース PASS）
- [x] CI 接続: `.github/workflows/migration-tests.yml` の `PATHS_REGEX` と実行コマンドが拡張され、PR 上で `bats tests/aidlc-setup/` が走る
- [x] 既存の `tests/migration/` および `tests/config-defaults/` のテストが回帰せずパスする（87/87 件 PASS: migration 36 + config-defaults 34 + aidlc-setup 17、計画見積もり 80+ 件想定を上回る）
- [x] `.md` 差分の markdownlint パス（markdownlint-cli2 で 4 ファイル 0 errors）
- [x] Unit 002 定義（`story-artifacts/units/002-setup-wizard-prefs-guidance.md`）の実装状態が「完了」に更新されている

**追加の検証項目**（コードレビュー指摘で追加された安定 ID 契約検証）:

- [x] S1 / S2 テスト: HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->` が `## 9b.` の直前行（line + 1）に 1 回のみ配置されることを検証（PASS）

## NFR チェック

- **冪等性**: 9b セクションは `03-migrate.md` 内で 1 回のみ定義され、他のステップファイルからは参照されない構造（観点 D1 / D3 で検証）
- **テスト互換**: 既存 `tests/migration/` および `tests/config-defaults/` の bats テストが回帰せずパスする（観点なし、回帰確認のみ）
- **設計意図の伝達**: 案内本文に 4 階層マージ仕様の 1 行説明と「project 共有に書くとチームに反映される」注記を含めることで、ストーリー 2 の Why（チーム汚染回避）を初期セットアップ時に伝える

## 想定リスクと対策

| リスク | 対策 |
|--------|------|
| `--non-interactive` モードが aidlc-setup に存在しないため、AC「stderr 出力」が形骸化する | AC を「automation_mode 全モード（manual/semi_auto/full_auto）対応 + stderr リダイレクト指示」に**実動作レベルで再定義**（現状分析セクション「`automation_mode` と aidlc-setup の関係」参照）。観点 C で 3 要素（`--non-interactive` 文字列 / stderr 指示 / automation_mode 全モード対応）を検査することで、AC 文言と実動作保証の両面を担保。`--non-interactive` フラグ自体の実装は将来 Unit のスコープ |
| 案内本文を Unit 003（aidlc-migrate）でコピーすると単一ソース化が崩れる | Unit 003 の計画段階で「9b セクションへの参照リンクのみ」の設計を明示する。Unit 002 の plan で境界表に記載済み |
| markdown-driven テストが「文字列の存在」のみを検査するため、案内が実際に表示されるかは保証できない | 受け入れ範囲とする（aidlc-setup の動的実行テストは別 Unit / 別サイクルで対応）。本 Unit では「指示が markdown に書かれている = LLM が指示通り実行する前提」を採用 |
| `02-generate-config.md` のモード分岐ガイドテーブルが 9b の追加で陳腐化する | 9b は `03-migrate.md` 内で完結するため `02-generate-config.md` のテーブルには影響しない。テーブル更新は不要（リスク発生せず） |
| 9b セクション本文の文言を後の Unit が変更した場合、テストが壊れる | 観点 A〜D は「文字列の含有」を検査する設計のため、文言の表現を変えてもキー文字列（`rules.reviewing.mode` 等 / `~/.aidlc/config.toml` / `--non-interactive` / `stderr`）が残っていればパスする。耐久性の高い検査方式 |

## 関連 Issue

- #592（部分対応: 実装スコープ 3 を担当）

## 見積もり

0.3 セッション（テキスト追加と静的検証テスト主体、設計差分は最小）
