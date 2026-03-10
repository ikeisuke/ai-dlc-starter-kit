# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 設定読み込み【重要】

AI-DLCの設定は `docs/aidlc.toml` と `docs/aidlc.toml.local`（個人設定）からマージして取得します。

**読み込み方法**:

```bash
# 単一キーモード（推奨）
docs/aidlc/bin/read-config.sh <key> [--default <value>]

# バッチモード（複数キーを一括取得）
docs/aidlc/bin/read-config.sh --keys <key1> [key2] ...

# 例
docs/aidlc/bin/read-config.sh rules.reviewing.mode
docs/aidlc/bin/read-config.sh rules.jj.enabled --default "false"
docs/aidlc/bin/read-config.sh --keys rules.reviewing.mode rules.jj.enabled rules.squash.enabled
```

**モードの使い分け**:
- 単一キーモード: 1つの設定値を取得。`--default` でフォールバック値を指定可能
- バッチモード: 複数の設定値を `key:value` 形式で一括取得。不在キーはスキップされる
- **注意**: `--keys` と `--default`、`--keys` と位置引数 `<key>` は同時に使用できません

**終了コード**:
- 0: 値あり
- 1: キー不在（単一モード: デフォルトなし / バッチモード: 全キー不在）
- 2: エラー

**マージルール**:
- `.local` の値が存在するキーはベースを上書き
- 配列は完全置換（マージしない）
- 詳細は `docs/aidlc/guides/config-merge.md` を参照

**注意**: `docs/aidlc.toml.local` は `.gitignore` に追加されるため、個人の設定を安全に上書きできます。

## ユーザーの承認プロセス【重要】

計画作成後、必ず以下を実行する:

1. 計画ファイルのパスをユーザーに提示
2. 「この計画で進めてよろしいですか？」と明示的に質問
3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
4. **承認なしで次のステップを開始してはいけない**

## 質問と回答の記録【重要】

独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める。

## Overconfidence Prevention原則【重要】

過信は品質低下を招く。確信度が低い場合は推測や仮定で進めず、必ずユーザーに質問する。

**デフォルト動作**: 確信度が判定できない場合は「質問する」（安全側に倒す）。「質問すべき場面」の全項目を体系的に評価し、スキップしない。

### 質問フロー（ハイブリッド方式）

1. まず質問の数と概要を提示する

   ```text
   質問が{N}点あります：
   1. {質問1の概要}
   2. {質問2の概要}
   ...

   まず1点目から確認させてください。
   ```

2. 1問ずつ詳細を質問し、回答を待つ
3. 回答を得てから次の質問に進む
4. 回答に基づく追加質問が発生した場合は「追加で確認させてください」と明示して質問する

### 質問すべき場面

- 要件が曖昧な場合
- 複数の解釈が可能な場合
- 技術的な選択肢がある場合
- 前提条件が不明確な場合
- 曖昧な回答を受領した場合（「たぶん」「場合による」「だいたい」等の不確定表現）
- 未定義用語や矛盾を検出した場合

### レッドフラグと成功指標

**レッドフラグ**（過信の兆候 - 以下に該当する場合は行動を見直す）:

- 複雑なプロジェクトで質問なしにステージを完了している
- 曖昧な回答にもかかわらず作業を進行している
- 「質問すべき場面」の項目を確認せずスキップしている
- 質問の代わりに仮定を使用している

**成功指標**（適切な質問行動の確認）:

- プロジェクトの複雑さに見合った質問量がある
- ユーザーの回答を徹底的に分析し、不明点を追加質問している
- 実装前に要件が明確になっている
- 後工程での手戻りが少ない

## Gitコミットのルール

コミットタイミング、メッセージフォーマット、Co-Authored-By設定は `common/commit-flow.md` を参照。

## Depth Level仕様【重要】

成果物詳細度（Depth Level）の3段階制御。タスクの複雑度に応じて成果物の詳細度を調整する。

### 設定読み込み

```bash
docs/aidlc/bin/read-config.sh rules.depth_level.level --default "standard"
```

**注意**: 設定キーは完全修飾キー `rules.depth_level.level` で参照する。`rules.history.level`（履歴記録レベル）とは別の設定。

### レベル定義

| レベル | 用途 | 説明 |
|--------|------|------|
| `minimal` | シンプルなバグ修正・小規模変更 | 設計省略可、受け入れ基準簡略化 |
| `standard` | 通常の機能開発（デフォルト） | 現行の動作と同等 |
| `comprehensive` | 複雑な機能開発・アーキテクチャ変更 | リスク分析・代替案検討等を追加 |

### レベル別成果物要件一覧

#### minimal（簡略モード）

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 1-2文の簡潔な記述 |
| Inception | ユーザーストーリー | 受け入れ基準を主要ケースのみに簡略化 |
| Inception | Unit定義 | 最小限の責務・境界記述 |
| Inception | PRFAQ | スキップ可能 |
| Construction | ドメインモデル | スキップ可能（設計省略を明記） |
| Construction | 論理設計 | スキップ可能（設計省略を明記） |
| Construction | コード・テスト | 通常通り |
| Operations | リリース準備 | 通常通り |

#### standard（標準モード）

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 標準的な記述（背景・目的・スコープ） |
| Inception | ユーザーストーリー | 完全な受け入れ基準（INVEST準拠） |
| Inception | Unit定義 | 完全な責務・境界・依存関係記述 |
| Inception | PRFAQ | 通常通り |
| Construction | ドメインモデル | 標準的なドメインモデル設計 |
| Construction | 論理設計 | 標準的な論理設計 |
| Construction | コード・テスト | 通常通り |
| Operations | リリース準備 | 通常通り |

#### comprehensive（詳細モード）

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 詳細な記述 + リスク分析・代替案検討セクション追加 |
| Inception | ユーザーストーリー | 完全な受け入れ基準 + エッジケース網羅 |
| Inception | Unit定義 | 完全な記述 + 技術的リスク評価 |
| Inception | PRFAQ | 通常通り |
| Construction | ドメインモデル | 詳細なドメインモデル + ドメインイベント定義 |
| Construction | 論理設計 | 詳細な論理設計 + シーケンス図・状態遷移図 |
| Construction | コード・テスト | 通常通り + 統合テスト強化 |
| Operations | リリース準備 | 通常通り + ロールバック手順の詳細化 |

### バリデーション仕様

取得した値に対して以下の順序でバリデーションを行う:

1. **正規化**: 前後の空白をトリム
2. **有効値チェック**: `minimal` / `standard` / `comprehensive` のいずれか（小文字完全一致）
3. **無効値時の動作**: 警告を出力し `"standard"` にフォールバック

**警告文言**:

```text
【警告】rules.depth_level.level に無効な値 "{入力値}" が設定されています。"standard" にフォールバックします。有効値: minimal / standard / comprehensive
```

**無効値の例**: 空文字、大文字混在（`Standard`）、typo（`standerd`）、未定義値（`full`）

### Unit 003向け契約仕様

各フェーズプロンプトでは、以下の手順でDepth Levelに基づく成果物要件の分岐を実装する:

1. `read-config.sh rules.depth_level.level --default "standard"` で設定値を取得
2. 本セクションのバリデーション仕様に従い正規化・有効値チェックを実施
3. 本セクションの「レベル別成果物要件一覧」を参照し、該当フェーズの要件を適用

**仕様の参照ルール**: 判定ロジックの仕様（有効値、警告文言、フォールバック動作、成果物要件）は本セクション（`rules.md`）を唯一の定義源（Single Source of Truth）とする。各フェーズプロンプトに仕様を重複記述してはならない。

## jjサポート設定（非推奨）

> **非推奨（v1.19.0）**: jjサポートは非推奨です。将来のバージョンで削除予定です。`enabled = true` に設定している場合は、gitへの移行を検討してください。

`docs/aidlc.toml`の`[rules.jj]`セクションを確認:

- `enabled = true`: jjを使用（非推奨）。gitコマンドを`docs/aidlc/skills/versioning-with-jj/references/jj-support.md`の対照表で読み替えて実行
- `enabled = false`、未設定、または不正値: 以下のgitコマンドをそのまま使用

## セミオートゲート仕様【重要】

セミオートモード（`rules.automation.mode = "semi_auto"`）が有効な場合、AIレビュー合格時にユーザー承認を省略して自動遷移する。

### 設定読み取り

```bash
docs/aidlc/bin/read-config.sh rules.automation.mode --default "manual"
```

- `manual`: 従来フロー（すべての承認ポイントでユーザー確認）。ゲート判定をスキップ
- `semi_auto`: セミオートゲート判定を実施

**注意**: プロンプト文中では `automation_mode` として参照する（`rules.reviewing.mode`（review_mode）との混同防止）。

### ゲート判定ロジック（全承認ポイント共通）

各承認ポイントで以下の順序で判定する:

1. `automation_mode` を取得
2. `automation_mode=manual` → ゲート判定スキップ、従来フローを実行。**終了**
3. `automation_mode=semi_auto` → グローバルフォールバック条件を先に評価
4. グローバルフォールバックに該当 → `fallback(error)` として従来フローへ。履歴記録
5. 承認ポイント固有のフォールバック条件を優先順位順に評価
6. フォールバック条件に該当 → `fallback` として従来フローへ。履歴記録
7. フォールバック条件に該当しない → `auto_approved` として次ステップへ自動遷移。履歴記録

### グローバルフォールバック条件

すべての承認ポイント（「自動実行」ポイント含む）に適用:

- 設定読取失敗（`read-config.sh` がエラー終了コード2を返した場合）
- 実行エラー（前提となる処理がエラーで終了した場合）
- 前提不成立（ゲート判定に必要なコンテキスト情報が欠落している場合）

### フォールバック条件テーブル（承認ポイント固有）

| 優先度 | reason_code | 条件 | ユーザーへのメッセージ方針 |
|--------|-------------|------|------------------------|
| 1 | `error` | ビルド/テスト失敗またはエラー発生 | エラー内容を提示し対応を求める |
| 2 | `review_issues` | AIレビュー指摘が残っている | 指摘一覧を提示し判断を求める |
| 3 | `incomplete_conditions` | 完了条件に未達成項目がある | 未達成項目を提示し判断を求める |
| 4 | `decision_required` | 技術的判断・選択が必要 | 選択肢を提示し判断を求める |

### 構造化シグナルスキーマ

| semi_auto_result | reason_code | fallback_reason | 条件 |
|------------------|-------------|-----------------|------|
| `auto_approved` | `none`（必須） | 空（使用しない） | フォールバック条件に該当しない |
| `fallback` | 有効値（必須） | 説明文字列（必須） | フォールバック条件に該当 |

**バリデーション規則**:

- `auto_approved` 時: `reason_code=none`、`fallback_reason` は空
- `fallback` 時: `reason_code` は `none` 以外、`fallback_reason` は空でない文字列
- `automation_mode=manual` 時: シグナルを生成しない

### Bashコードブロック内の`$()`・バッククォート使用禁止【重要】

プロンプト`.md`ファイルのBashコードブロック（` ```bash ` 〜 ` ``` ` の範囲）内で`$()`コマンド置換およびバッククォート（`` ` ``）によるコマンド置換を使用しない。Claude Codeのセミオートモードで許可プロンプトが発生するため。また、バッククォートは`$()`の旧式構文であり、ネストが困難で可読性も低いため使用を禁止する。

- **禁止**: `git commit -m "$(cat <<'EOF'...)"`, `SQUASH_MESSAGE="$(cat <<'EOF'...)"`, `--content "$(cat <<'CONTENT_EOF'...)"`, `` VAR=`command` `` 等
- **代替方式**:
  - コミット: `mktemp` でパス生成 → Writeツールで書き込み → `git commit -F <パス>` → 削除
  - jj: `mktemp` でパス生成 → Writeツールで書き込み → `jj describe --stdin < <パス>` → 削除
  - write-history.sh: `mktemp` でパス生成 → Writeツールで書き込み → `--content-file <パス>` → 削除
  - squash-unit.sh: `mktemp` でパス生成 → Writeツールで書き込み → `--message-file <パス>` → 削除
  - gh pr create/edit: `mktemp` でパス生成 → Writeツールで書き込み → `--body-file <パス>` → 削除
  - 変数取得: 事前にBashでコマンド実行し結果を変数に格納
- **例外**: `.sh`スクリプト内部の`$()`は対象外（Claude Codeの許可対象外）
- **例外**: 説明文中のインラインコード・リテラルテキスト内の`$()`およびバッククォートによるコマンド置換表記は対象外

### `--content`/`--content-file`引数の安全パターン【重要】

`write-history.sh`の`--content-file`方式を推奨。`--content`直接指定も後方互換として動作する。

- **推奨**: `mktemp` でパス生成 → Writeツールで書き込み → `--content-file <パス>` → 削除
- **許可（後方互換）**: `--content "直接文字列"`（`$()`を含まないリテラル文字列のみ）
- **禁止**: `--content "$(cmd)"`、`--content "$VAR"` 等のコマンド置換・変数展開を含む文字列

### テンポラリファイル規約【重要】

一時ファイルの生成・使用・削除について以下の規約に従う。

#### 出力先ディレクトリ

`/tmp`（OS標準の一時ディレクトリ）を使用する。

#### ファイル生成方法

`mktemp` コマンドで一意なパスを生成する。**固定パスの直接使用は禁止**する。

| 用途 | mktemp テンプレート |
|------|------|
| コミットメッセージ | `mktemp /tmp/aidlc-commit-msg.XXXXXX` |
| スカッシュメッセージ | `mktemp /tmp/aidlc-squash-msg.XXXXXX` |
| 履歴コンテンツ | `mktemp /tmp/aidlc-history-content.XXXXXX` |
| PRボディ | `mktemp /tmp/aidlc-pr-body.XXXXXX` |

#### 使用手順

1. **パス生成**: Bashツールで上記 `mktemp` コマンドを実行し、出力されたパスを取得する
2. **書き込み**: Writeツールで取得したパスにコンテンツを書き込む
3. **使用**: 取得したパスをコマンド引数として使用する
4. **削除**: コマンド実行直後に一時ファイルを削除する

**コードブロック内のパス表記**: 本ドキュメント群のコードブロックに記載される `/tmp/aidlc-*` で始まるパスはパターン例示である。実行時は上記手順で `mktemp` により生成された実際のパスを使用すること。

#### 使用後の削除義務

一時ファイルは使用後に**必ず削除**する。`/tmp`のOS再起動時自動クリーンアップも補助的に機能する。

#### セキュリティ注意事項

- `mktemp` により一意なパスが生成されるため、シンボリックリンク攻撃や並行セッションでのファイル衝突を防止できる
- 一時ファイルに**機密情報（秘密鍵、トークン、パスワード等）を含めない**こと。用途はコミットメッセージ、履歴コンテンツ、PRボディ等の非機密情報に限定する
- 万一機密情報を含むファイルが必要な場合は、本規約のスコープ外とし、適切なセキュリティ対策（パーミッション制御等）を個別に実施する

#### 規約外パスの使用

1. **デフォルトは必ず `mktemp` でパスを生成する**（`/tmp` ディレクトリ、`aidlc-{purpose}.XXXXXX` テンプレート）
2. 規約外パスの使用は、明示的な技術的要件がある場合のみ許可する（例: ツールが特定パスを要求する場合）
3. 規約外パスを使用する場合は、その理由をコメントで明記する

### 自動承認時の履歴記録フォーマット

1. Writeツールで一時ファイルを作成（内容: 履歴コンテンツ）:

```text
【セミオート自動承認】
【承認ポイントID】{承認ポイントID}
【判定結果】auto_approved
【AIレビュー結果】指摘0件
```

2. 以下を実行:

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase {{PHASE}} \
    --unit {N} \
    --unit-name "[Unit名]" \
    --unit-slug "[unit-slug]" \
    --step "セミオート自動承認" \
    --content-file /tmp/aidlc-history-content.txt
```

3. 一時ファイルを削除

- `--unit`, `--unit-name`, `--unit-slug`: constructionフェーズの場合のみ指定

### フォールバック時の履歴記録フォーマット

1. Writeツールで一時ファイルを作成（内容: 履歴コンテンツ）:

```text
【セミオートフォールバック】
【承認ポイントID】{承認ポイントID}
【判定結果】fallback
【reason_code】{reason_code}
【詳細】{fallback_reason}
```

2. 以下を実行:

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase {{PHASE}} \
    --unit {N} \
    --unit-name "[Unit名]" \
    --unit-slug "[unit-slug]" \
    --step "セミオートフォールバック" \
    --content-file /tmp/aidlc-history-content.txt
```

3. 一時ファイルを削除

- `--unit`, `--unit-name`, `--unit-slug`: constructionフェーズの場合のみ指定

### 承認ポイントID命名規則

`{phase}.{context}.{step}` 形式。例:

- `construction.plan.approval`, `construction.design.review`
- `inception.intent.approval`, `inception.stories.approval`
- `operations.plan.approval`

### 改善提案のバックログ登録ルール【重要】

「次のサイクルで対応」「将来的に改善」「改善の余地がある」等の改善提案を行う場合、**必ずバックログに登録**すること。口頭（テキスト出力のみ）で提案だけして、バックログ（issueまたはファイル）を作成しないことを禁止する。

**理由**: セッション終了時に口頭の提案は消失し、追跡不能になるため。

**ルール**:

1. 改善提案をする際は、同時にバックログ登録を実行する
2. バックログ登録方法は `docs/aidlc.toml` の `[rules.backlog].mode` に従う
   - `issue` / `issue-only`: GitHub Issueを作成（`gh issue create`）
   - `git` / `git-only`: `docs/cycles/backlog/` にファイルを作成
   - 詳細は `docs/aidlc/guides/backlog-management.md` を参照
3. バックログ登録が技術的に不可能な場合（gh CLI不可用 + issue-onlyモード等）は、ユーザーに手動登録を依頼する

**禁止例**:
- 「次のサイクルで改善を検討できます」（← issueやファイル未作成）
- 「将来的に対応したほうがよいでしょう」（← バックログ未登録）

**正しい例**:
- 「次のサイクルで改善を検討できます。バックログIssueを作成しました: #XXX」
- 「将来的に対応したほうがよいでしょう。バックログファイルを作成しました: `docs/cycles/backlog/chore-xxx.md`」

## コード品質基準

コード品質基準、Git運用の原則は `docs/cycles/rules.md` を参照
