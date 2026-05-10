# Unit 004 論理設計: dasel 直接呼び出しの read-config.sh 経由統一 + 規約追記

## 全体構成

本 Unit は以下 4 ファイルの編集に分かれる:

1. **`skills/aidlc/steps/inception/02-preparation.md`** - 不正フラグ `dasel -f` を含む 3 行のコマンド例を `bash scripts/read-config.sh` 経由（単一キー × 3）に置換 + 説明文の整合
2. **`skills/aidlc-feedback/steps/feedback.md`** - 既存の `cat ... | dasel -i toml` を、`.aidlc/config.toml` 存在チェック先行 + `bash scripts/read-config.sh` 経由に置換 + エラーハンドリング表現を `read-config.sh` の exit code（0/1/2）に整合
3. **`skills/aidlc/steps/common/rules-core.md`** - 既存の **「## 設定読み込み【重要】」** セクション直下に「dasel 呼び出し規約（CLI v3）」+「禁止呼び出しパターン」の 2 サブセクションを追記（新規 H2 セクションは作らず、既存の設定読み込みルールを拡張）
4. **`.aidlc/rules.md`** - 「スキル間依存ルール」セクションに 1 行追記し、`scripts/read-config.sh` を「公開 API スクリプト層」として例外規定する（rules-core.md の詳細展開と整合）

## 1. `02-preparation.md` の論理設計

### 1.1 変更箇所（line 135-144）

#### 変更前

```text
1. **runtime binding 取得**: AI エージェントは `dasel` で `.aidlc/config.toml` から以下 3 つの値を別ステップで取得し、内部変数に保持する:
    - `github_projects.project_url`
    - `github_projects.project_number`
    - `github_projects.owner`（未設定時は `@me`）

   ```text
   dasel -f .aidlc/config.toml github_projects.project_url
   dasel -f .aidlc/config.toml github_projects.project_number
   dasel -f .aidlc/config.toml github_projects.owner
   ```
```

#### 変更後

```text
1. **runtime binding 取得**: AI エージェントは `bash scripts/read-config.sh` で `.aidlc/config.toml` から以下 3 つの値を別ステップで取得し、内部変数に保持する:
    - `github_projects.project_url`
    - `github_projects.project_number`
    - `github_projects.owner`（未設定時は `@me`）

   ```text
   bash scripts/read-config.sh github_projects.project_url
   bash scripts/read-config.sh github_projects.project_number
   bash scripts/read-config.sh github_projects.owner
   ```

   各コマンドの終了コード:
   - 0: 値あり（標準出力の値を内部変数に保持）
   - 1: キー不在（未設定として扱う。`owner` が未設定時は `@me` をフォールバック）
   - 2: エラー（dasel 未インストール / TOML 破損等。フォールバック条件として扱う）
```

### 1.2 整合性

- 既存のフォールバック節（line 158-163）は `read-config.sh` 経由でも同じ動作（exit 1/2 = 設定不在 / エラー）でカバーされる
- exit code の意味付けは `read-config.sh` ヘッダ（line 14-16）の規約と一致

## 2. `feedback.md` の論理設計

### 2.1 変更箇所（line 5-15）

#### 変更前

```text
## 設定確認

最初に `.aidlc/config.toml` の設定を確認する：

```bash
cat .aidlc/config.toml | dasel -i toml 'rules.feedback.enabled'
```

**エラーハンドリング**:
- `.aidlc/config.toml` 不在: `true`（デフォルト有効）として続行。初回セットアップ前の正常ケース
- `dasel` 未インストール / TOML破損・キー不在: ユーザーに送信可否を対話確認（自動判定しない）
```

#### 変更後

```text
## 設定確認

最初に `.aidlc/config.toml` の設定を確認する：

```bash
# .aidlc/config.toml が存在しない場合は true（デフォルト有効）として続行
if [[ ! -f .aidlc/config.toml ]]; then
  echo "true"
else
  bash scripts/read-config.sh rules.feedback.enabled
fi
```

**エラーハンドリング**:
- `.aidlc/config.toml` 不在（事前 `[[ -f ]]` チェック）: `true`（デフォルト有効）として続行。初回セットアップ前の正常ケース（既存挙動維持）
- `read-config.sh` exit 0（標準出力に値あり）: 値が `false` なら無効化メッセージ表示で終了、それ以外は続行
- `read-config.sh` exit 1（キー不在）: デフォルト値 `true` として続行（`[rules.feedback]` 未設定の正常ケース）
- `read-config.sh` exit 2（エラー: dasel 未インストール / TOML 破損等）: ユーザーに送信可否を対話確認（自動判定しない、既存挙動維持）
```

### 2.2 整合性

- 既存の **「`.aidlc/config.toml` 不在 → `true` 続行」** 挙動は事前 `[[ -f ]]` チェックで保護される（read-config.sh が config 不在を exit 2 で扱う仕様との不整合を回避）
- 既存の **`false` の場合** / **`false` 以外の場合（デフォルト: `true`）** の分岐ロジック（line 17-29）は維持
- エラーハンドリングのセマンティクス（「自動判定しない」要件）は exit 2 時の対話分岐として維持

### 2.3 既存テストとの互換性（AC 異常系対応）

ユーザーストーリー 4 の AC「`aidlc-feedback` の機能テスト（既存 bats）が引き続き green」を満たすため、以下を確認する:

- `[[ -f .aidlc/config.toml ]]` 先行チェックにより、config 不在時の挙動（`true` 続行）が既存と完全一致
- read-config.sh 呼び出し時の exit 0/1/2 ハンドリングが既存挙動（true/対話）に対応付けられる
- bats テストが存在する場合は実装フェーズで実行確認（テスト存在自体を Phase 2 で確認）

## 3. `rules-core.md` の論理設計

### 3.1 挿入位置

既存の **「## 設定読み込み【重要】」** セクション（line 5-18 の `read-config.sh` 利用方法とエラーコード規約を含む）の **直下** に、サブセクション（H3）として 2 つを追加する。新規 H2 セクションは作らない（既存の設定読み込みルールの自然な拡張として配置）。

挿入後の章構成:

```text
## 設定読み込み【重要】
（既存内容: read-config.sh の利用方法、終了コード規約、`.local` 上書き仕様）
### dasel 呼び出し規約（CLI v3）  ← 新設（H3）
### 禁止呼び出しパターン           ← 新設（H3）

## 実行前の検証
（以降既存）
```

### 3.2 「dasel 呼び出し規約（CLI v3）」サブセクション（新設）

```markdown
### dasel 呼び出し規約（CLI v3）

`.aidlc/config.toml` の TOML 値読取は **`scripts/read-config.sh` 経由を第一推奨** とする。

**理由**:
- 4 階層マージ（defaults / HOME / project / local）と key alias を一元的に処理
- 終了コード規約（0=値あり、1=キー不在、2=エラー）が定義済み
- AI エージェントが `dasel -f` のような不正フラグを誤生成するリスクを排除

**公開 API スクリプト層としての位置付け**:

`scripts/read-config.sh` は AI-DLC スターターキット内の **公開 API スクリプト** として位置付けられ、`.aidlc/rules.md` の「スキル間依存ルール」が禁じる「他スキル内部実装への依存」には該当しない（`.aidlc/rules.md` 本体に例外規定済み）。これにより、aidlc-feedback / aidlc-setup / aidlc-migrate / reviewing-* など全スキルから参照可。`scripts/lib/*` 等は引き続き内部実装として扱う。

**呼び出し記法**:

| 用途 | 記法 |
|------|------|
| AI 手順内コマンド（プロンプト `.md` 内） | `bash scripts/read-config.sh <key>`（SKILL.md パス解決でスキルベースディレクトリ相対を絶対化） |
| 検証コマンド（人間 / CI） | `bash skills/aidlc/scripts/read-config.sh <key>`（リポジトリルート相対の絶対参照） |

**dasel 直接呼び出しの例外**:

`read-config.sh` 自身が動作不能な低レイヤー（bootstrap 内部・stdlib 系）、または `read-config.sh` が必須前提とする `.aidlc/config.toml` 自身の存在検証段階（aidlc-setup の早期判定）でのみ、dasel CLI を直接呼んでよい。その場合、以下の **2 形式のみ許容** する:

- `cat <file> | dasel -i toml '<key>'`
- `dasel -i toml '<key>' < <file>`

**dasel CLI v3 の制約**:

- `-f <file>` フラグは **存在しない**（`unknown flag` エラー、exit 80）。これは v2 系の構文との混同による AI 誤生成パターンであり、絶対に使用してはならない
```

### 3.3 「禁止呼び出しパターン」サブセクション（新設）

```markdown
### 禁止呼び出しパターン

AI エージェントが誤生成しがちな anti-pattern を以下に列挙する。これらは絶対に使用してはならない。

| パターン | エラー | 正しい代替 |
|---------|-------|----------|
| `dasel -f <file> '<key>'` | `unknown flag -f`（exit 80、dasel v3） | `bash scripts/read-config.sh <key>` または `cat <file> \| dasel -i toml '<key>'` |
| `dasel -f <file> -r toml '<key>'` | 同上、`-r`/`-f` 混在 | 同上 |

**拡張余地**: 将来の anti-pattern は別 Issue / Unit で追加（初版は dasel 関連 2 例に限定）。
```

## 3a. `.aidlc/rules.md` の論理設計

### 3a.1 変更箇所

既存の「### スキル間依存ルール」セクション（line 33-37）の末尾に、公開 API スクリプト層の例外を 1 行追記する。

#### 変更前（line 33-37）

```markdown
### スキル間依存ルール

- **禁止**: 他スキルの内部実装（`scripts/`, `steps/`, `templates/` 等の内部ファイルパス）への依存
- **許可**: スキルの呼び出し名（`/aidlc`, `/reviewing-construction-code` 等）とSKILL.mdで定義された入出力引数への依存
- 内部ファイルパス参照はAPIと見なさない。スキル更新時の波及範囲を限定するため、公開された呼び出しインターフェイスのみに依存すること
```

#### 変更後（line 33-38）

```markdown
### スキル間依存ルール

- **禁止**: 他スキルの内部実装（`scripts/`, `steps/`, `templates/` 等の内部ファイルパス）への依存
- **許可**: スキルの呼び出し名（`/aidlc`, `/reviewing-construction-code` 等）とSKILL.mdで定義された入出力引数への依存
- **例外（公開 API スクリプト層）**: `skills/aidlc/scripts/read-config.sh` は AI-DLC スターターキット全体の公開 API スクリプトとして全スキルから参照可（詳細は `skills/aidlc/steps/common/rules-core.md` の「dasel 呼び出し規約（CLI v3）」セクション参照）。`scripts/lib/*` 等は引き続き内部実装として禁止対象
- 内部ファイルパス参照はAPIと見なさない。スキル更新時の波及範囲を限定するため、公開された呼び出しインターフェイスのみに依存すること
```

### 3a.2 整合性

- 上位ルール（rules.md）と詳細ルール（rules-core.md）の優先順位が明確化される
- 公開 API スクリプト層の初期メンバーは `read-config.sh` のみ
- `scripts/lib/*` 等は引き続き禁止対象であり、公開／非公開の区別が明示される

## 4. 整合性チェック

### 4.1 ガイド照合（CLAUDE.md / .aidlc/rules.md）

| ルール | 適用 |
|--------|------|
| ドッグフーディング特殊処理を本体に埋めない | 規約セクションは AI 一般向け、自リポジトリ判定なし |
| `$(...)` 絶対禁止 | 本 Unit の置換コマンドは `bash scripts/read-config.sh <key>` 単純呼び出し、`$(...)` 不使用 |
| スキル間依存ルール | `read-config.sh` を **公開 API スクリプト層** として `.aidlc/rules.md` 本体に例外規定（rules.md と rules-core.md の優先順位を明確化） |
| ファイル参照境界ルール | スキル内リソース参照（`scripts/read-config.sh` のスキルベース相対参照）は SKILL.md パス解決ルールに従う |

### 4.2 Unit 001 / Unit 002 完了済み修正との整合

- Unit 001（version.sh OOM 修正）: `scripts/lib/version.sh` の bash CLI モードガードに閉じる修正で、本 Unit と干渉しない
- Unit 002（cycle-phase-completion-check の draft skip）: `.github/workflows/` 修正で、本 Unit と干渉しない
- Unit 003 / Unit 005（推奨依存元）: 本 Unit 完了後、`rules-core.md` の規約に従って `read-config.sh` 経由実装が選択しやすくなる

### 4.3 既存 read-config.sh 機能との整合

- `read-config.sh` の既存インターフェース（単一キー / `--keys` バッチモード）は変更しない
- 既存の終了コード規約（0/1/2）は変更しない
- 既存の 4 階層マージ（defaults / HOME / project / local）は変更しない

## 5. 実装手順（Phase 2 着手時の指針）

1. `skills/aidlc/steps/inception/02-preparation.md` の line 135-144 を Edit ツールで置換
2. `skills/aidlc-feedback/steps/feedback.md` の line 5-15 を Edit ツールで置換（`[[ -f .aidlc/config.toml ]]` 先行チェック追加）
3. `skills/aidlc/steps/common/rules-core.md` の「## 設定読み込み【重要】」セクション直下に H3 サブセクション 2 つを Edit ツールで追加
4. `.aidlc/rules.md` の「### スキル間依存ルール」に公開 API スクリプト層の例外行を Edit ツールで追記
5. `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1` で markdownlint 実行
6. 機械判定 grep（計画ファイルの「観測可能な判定指標」セクションのコマンド）で anti-pattern 残存と置換完了を確認
7. スモークテスト（read-config.sh 経由の 3 キー取得 dry run）で動作確認
8. **既存 bats テストの存在確認**: `find skills/aidlc-feedback -name "*.bats" -type f` で aidlc-feedback の bats テスト存在を確認。存在する場合は実行して green を確認
9. **対象外確認**: `skills/aidlc-setup/steps/01-detect.md` の line 97 が変更されていないことを `git diff` で確認
