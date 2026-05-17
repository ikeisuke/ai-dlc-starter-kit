# 論理設計: Unit 001 Inception 直近サイクル完了 Unit との重複検出フロー SoT 化

## 概要

`steps/inception/04-stories-units.md` のステップ 4（Unit 定義）直後・Unit 定義承認前 AI レビュー前に「ステップ 4a: 直近サイクル完了 Unit との重複チェック」セクションを挿入し、重複検出フローを SoT 化する。新規 config キー `[rules.inception].dedup_lookback_cycles`（既定 3）を `defaults.toml` に追加する。

**重要**: 本論理設計では**コードは書かず**、ステップ手順テキストの構成と各サブステップで呼ぶコマンド・期待出力の輪郭のみを定義する。具体的な手順テキストは Phase 2（コード生成）で書く。

## アーキテクチャパターン

- **SoT 配置パターン**: 重複検出ロジックの自然言語仕様を `04-stories-units.md` の 1 セクションに集約。コード化された関数ではなく、AI エージェントが解釈実行する手順としての SoT
- **opt-in シグナル + opt-out config**: 重複検出は既定 on（lookback=3）、`dedup_lookback_cycles=0` で明示的 opt-out。consumer プロジェクトでも追加設定なしで自然に有効化される
- **fail-safe フォールバック**: gh 不可用時はスラグ照合のみで継続、Issue 状態確認は skip。中断はしない
- **責務分離**: config 解決層（不正値正規化）/ 検出層（スラグ・Issue 照合）/ 対話層（AskUserQuestion）/ 記録層（write-history + 機械可読コメントブロック）の 4 層構造

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/
├── config/
│   └── defaults.toml                 # [rules.inception] セクション追加 + dedup_lookback_cycles 既定値
└── steps/
    └── inception/
        └── 04-stories-units.md       # ステップ 4a 追加（重複チェック手順 SoT）
.aidlc/cycles/v2.6.5/
└── history/
    └── inception.md                  # ドッグフーディング検証結果（v2.6.5 自身の Inception 結果を retrofit 記録）
```

### コンポーネント詳細

#### `defaults.toml` の `[rules.inception]` セクション

- **責務**: 重複検出ウィンドウのデフォルト値を集中管理
- **依存**: なし（`read-config.sh` から参照される）
- **公開インターフェース**: TOML キー `rules.inception.dedup_lookback_cycles`（int、既定 3）

#### `04-stories-units.md` ステップ 4a「直近サイクル完了 Unit との重複チェック」

- **責務**: AI エージェントが Unit 定義承認前 AI レビュー前に重複チェックを実施するための手順 SoT
- **依存**:
  - `scripts/read-config.sh`（config 解決）
  - `gh issue view --json state`（Issue 状態確認、`gh_status=available` 時のみ）
  - `.aidlc/cycles/v*/story-artifacts/units/*.md`（スラグ抽出元）
  - `templates/unit_definition_template.md`（「関連 Issue」セクションの参照フォーマット SoT）
- **公開インターフェース**: ステップ手順テキスト。サブステップ構成は処理フロー側（後述「処理フロー概要 > Unit 定義承認前の重複チェック処理フロー」）の (0)〜(7) に統一する。層とサブステップ番号の対応:

  | サブステップ | 責務層 | 内容 |
  |-------------|--------|------|
  | (0) | config 解決層 | `dedup_lookback_cycles` を正規化し `normalized_lookback_cycles: non-negative int` を出力 |
  | (1) | 早期 opt-out | `normalized_lookback_cycles == 0` で全工程 skip |
  | (2) | 検出層 | 直近 N サイクル完了スラグ集合の構築 |
  | (3) | 検出層 (a) | スラグ完全一致検査 |
  | (4) | 検出層 (b)(c) | 一致 Unit の関連 Issue 抽出 + Issue 状態確認（gh available 時のみ） |
  | (5) | 検出層 | `DuplicateMatch` リスト構築 |
  | (6) | 対話層 | AskUserQuestion で `withdraw` / `continue_with_reason` を取得 |
  | (7) | 記録層 | Unit 定義ファイル更新 + `write-history.sh` 追記 + 既存 AI レビューフローへ合流 |

## インターフェース設計

### コマンド（手順内でエージェントが実行）

> サブステップ番号は処理フロー側 (0)〜(7) に統一。本節は各サブステップで呼び出すコマンド・戻り値・可用性を定義する。

#### サブステップ (3): 完了スラグ一覧取得

- **コマンド例**: `ls -1 .aidlc/cycles/v*/story-artifacts/units/*.md | xargs -I{} sh -c '...'`（実装時の具体形は手順テキストで提示）
- **戻り値**: `(cycle, slug)` のペア一覧（直近 `normalized_lookback_cycles` サイクル分）
- **絞り込み条件**: 「実装状態 → 状態」が `完了` のもののみ（`取り下げ` 除外）

#### サブステップ (4-b): 関連 Issue 抽出

- **コマンド例**: `grep -E '^\s*-\s*#[0-9]+' <unit_file>`（「## 関連Issue」セクション直下のリスト抽出）
- **戻り値**: Issue 番号リスト（0 件以上）

#### サブステップ (4-c): Issue 状態確認

- **コマンド例**: `gh issue view <N> --json state -q .state`
- **戻り値**: `OPEN` / `CLOSED` / エラー時 `UNKNOWN`
- **可用性**: `gh_status != available` 時はサブステップ全体を skip、`UNKNOWN` 扱い

#### サブステップ (6): AskUserQuestion

- **質問形式（固定）**:

  ```text
  header: "重複警告"
  question: "新規 Unit `<slug>` は直近 <normalized_lookback_cycles> サイクル内の以下の完了 Unit と一致します。続行しますか？\n- <cycle>/<slug> (Issue #<NNN> <state>)\n..."
  ```

- **選択肢**:

  | choice_id | label | reason 必須 | 正規アクション |
  |-----------|-------|-------------|---------------|
  | `withdraw` | 取り下げ（推奨） | 不要 | Unit 定義ファイルの「実装状態 → 状態」を `取り下げ` に変更 + history 追記 |
  | `continue_with_reason` | 継続（理由必須） | 必須 | Unit 定義ファイル末尾に dedup-warning コメントブロック追記 + history 追記 |

#### サブステップ (7): 判断後アクション

- `withdraw` 選択時:
  1. Unit 定義ファイルの「実装状態 → 状態」を `取り下げ` に更新
  2. `write-history.sh --phase inception --step "Unit 定義" --content-file <tmp>` で「重複検出による取り下げ」を追記
- `continue_with_reason` 選択時:
  1. Unit 定義ファイル末尾に以下を追記（**新シリアライズ規約準拠**、`key="value"` 引用符必須、エスケープ規約・受理正規表現はデータモデル概要セクションの SoT を参照）:

     ```html
     <!-- dedup-warning: source=".aidlc/cycles/v2.6.3/story-artifacts/units/004-operations-premerge-ci-sot.md" related_issue="#694" reason="意図的に別アプローチで再起案" detected_at="2026-05-17" -->
     ```

  2. `write-history.sh` で「重複検出後の継続判断」を追記

## スクリプトインターフェース設計

本 Unit では新規スクリプトを作成しない。既存スクリプト（`scripts/read-config.sh` / `scripts/write-history.sh`）と既存 CLI（`gh issue view`）を `04-stories-units.md` の手順テキストから呼び出すだけ。

### 既存スクリプトの利用

#### `scripts/read-config.sh rules.inception.dedup_lookback_cycles`

- **戻り値**: 設定値文字列（stdout）/ exit 0=値あり、exit 1=キー不在（defaults.toml の既定値 3 が自動採用される）
- **正規化責務**: 取得値が非整数 / 負数の場合、手順テキスト内で「stderr に warn 表示 + default 3 にフォールバック」と明示

## データモデル概要

### ファイル形式

#### dedup-warning コメントブロック（HTML コメント形式）

- **形式**: HTML コメント（Markdown レンダリング時に非表示、grep 可能）。1 行 1 ブロック（改行禁止）。
- **シリアライズ規約（固定 / 機械可読パース可）**:
  - 全フィールドを `key="value"` の二重引用符付きで記述する（引用符省略禁止）
  - `value` 内の `"` は `\"` でエスケープ、バックスラッシュ自身は `\\` でエスケープ
  - 許可エスケープシーケンスは `\"` と `\\` のみ（その他 `\X` 表現は不正値として拒否）
  - `value` 内に改行文字 (`\n` / `\r`) は含めない（含む場合は半角スペース 1 個に正規化）
  - フィールド区切りは半角スペース 1 個
  - フィールド順は固定: `source` → `related_issue` → `reason` → `detected_at`
- **受理正規表現**:

  ```text
  <!-- dedup-warning: source="(?:[^"\\]|\\["\\])+" related_issue="(?:#[0-9]+|none)" reason="(?:[^"\\]|\\["\\])+" detected_at="[0-9]{4}-[0-9]{2}-[0-9]{2}" -->
  ```

- **記述例**:

  ```html
  <!-- dedup-warning: source=".aidlc/cycles/v2.6.3/story-artifacts/units/004-operations-premerge-ci-sot.md" related_issue="#694" reason="意図的に別アプローチで再起案" detected_at="2026-05-17" -->
  ```

- **主要フィールド**:
  - `source`: string - 重複先 Unit 定義ファイルのリポジトリ相対パス（絶対パス禁止）
  - `related_issue`: string - `#NNN` 形式または `none`
  - `reason`: string - ユーザー入力理由（エスケープ規約適用）
  - `detected_at`: string - YYYY-MM-DD 形式

#### `defaults.toml` 追加セクション

```toml
[rules.inception]
# 直近サイクル完了 Unit との重複検出フローで参照する直近サイクル数（v2.6.5 / #712 / Unit 001）
# - 既定 3。0 で重複検出を完全スキップ（opt-out）
# - 不正値（負数 / 非整数）時は warn + default 3 にフォールバック（fail-safe）
dedup_lookback_cycles = 3
```

## 処理フロー概要

### Unit 定義承認前の重複チェック処理フロー

`04-stories-units.md` ステップ 4a 内のサブステップ構成。**サブステップ (0) は独立節**として記述し、出力契約を厳密に固定する。後段サブステップ (1)〜(7) は正規化済み値のみを受け取る前提を明文化する。

**ステップ**:

0. **config 解決サブステップ（独立節 / 責務: config 解決層）**:
   - 入力: 環境（`scripts/read-config.sh` 経路）
   - 処理: `read-config.sh rules.inception.dedup_lookback_cycles` を実行
   - 正規化規則:
     - exit 0 + 非負整数 → そのまま採用
     - exit 1（キー不在）→ defaults.toml 既定値 3 を採用
     - exit 0 + 非整数 / 負数 / 文字列 → stderr に `warn: invalid rules.inception.dedup_lookback_cycles=<value>, fallback to 3` を 1 行出力 + 3 を採用
   - **出力契約（固定）**: `normalized_lookback_cycles: non-negative int`
   - 以降のサブステップは本契約に従う値のみを受け取り、再度の正規化を行わない（責務重複禁止）
1. **早期 opt-out**: `normalized_lookback_cycles == 0` → ログ 1 行（`dedup: skipped (lookback=0)`）のみで完了。AskUserQuestion を起動しない
2. 検出層: 直近 `normalized_lookback_cycles` サイクル分の完了スラグ集合を構築
3. 新規候補 Unit 定義ファイル群に対して、(a) スラグ完全一致を検査
4. 一致あり: (b) 当該完了 Unit の関連 Issue を抽出 → (c) `gh_status=available` 時のみ Issue 状態を確認
5. 重複候補リスト構築（`DuplicateMatch`）
6. 対話層: AskUserQuestion で `withdraw` / `continue_with_reason` を取得
7. 記録層: 選択に応じてファイル更新 + write-history 追記。完了後、既存の「Unit 定義承認前 AI レビュー」フローに合流

**関与するコンポーネント**: `read-config.sh` / `04-stories-units.md` のステップ 4a 手順 / `gh issue view` / AskUserQuestion / `write-history.sh`

### ドッグフーディング検証フロー（v2.6.5 自身の Inception での retrofit 記録）

**ステップ**:

1. v2.6.5 Inception の story-artifacts/units/ 配下 5 Unit のスラグ取得
2. 直近 3 サイクル（v2.6.4 / v2.6.3 / v2.6.2）の完了スラグと突合
3. 該当ありなら一致表 / 該当なしなら「該当なし」を `history/inception.md` に追記
4. 「Unit 001 改修内容を実適用した場合の検証結果」として記録

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 10 秒以内（直近 3 サイクル × 平均 5 Unit × Issue 状態確認）
- **対応策**: スラグ一覧取得は ls + grep のみで O(N)。Issue 状態確認は一致ヒット件についてのみ実行（最大数件）

### セキュリティ

- **要件**: gh CLI 認証範囲内、追加権限要求なし
- **対応策**: `gh issue view --json state` は read-only 操作。書き込み権限不要

### スケーラビリティ

- **要件**: N サイクル数を config で調整可能
- **対応策**: `dedup_lookback_cycles` を config キーで変更可能。将来 5〜10 に拡張可

### 可用性

- **要件**: gh 不可用時はスキップ（フェーズ中断しない）
- **対応策**: `gh_status != available` 時は Issue 状態確認サブステップ全体を skip、警告表示後にスラグ一致のみで判定し AskUserQuestion を継続

## 技術選定

- **形式**: Markdown ステップファイル（自然言語 SoT）+ TOML config + shell コマンド呼び出し
- **言語**: 自然言語（日本語）+ bash one-liner 例示
- **依存ツール**: 既存 `read-config.sh` / `write-history.sh` / `gh` CLI

## 実装上の注意事項

- 手順テキスト内のコマンド例は AI エージェントが Bash ツール経由で実行する想定。**コマンド置換 `$(...)` / backtick 禁止**（本リポジトリ規約 / Issue #697）
- 「関連 Issue」セクションの見出しは `templates/unit_definition_template.md` の現行形式（`## 関連Issue`）に合わせる
- スラグ抽出は完全一致のみ。正規化（複数形 / 略語）は将来 issue として明示的にスコープ外
- `dedup_lookback_cycles=0` で AskUserQuestion 自体を起動しない（誤起動による中断回避 / 1 行 log のみ）
- Unit 004（defaults sync guard）との依存契約: Unit 004 計画書側で「新規セクション追加を許容する互換窓」を保証する。Unit 001 / Unit 004 は実行順序非依存
- 手順は AI エージェントが解釈実行する自然言語 SoT のため、bats テスト等の自動検証は本 Unit では実施しない（v2.6.5 Inception 自身でのドッグフーディング検証で動作確認とする）

## 不明点と質問（設計中に記録）

[Question] `04-stories-units.md` への挿入位置はステップ 4 直後・ステップ 4b（エクスプレスモード判定）直前のどちらが適切か
[Answer] ステップ 4 直後・ステップ 4b 直前。ステップ 4b はエクスプレスモード分岐でスキップされる場合があるため、その前段で必ず実行される位置に置く。新規セクション ID は「ステップ 4a」とし、既存ステップ番号は保持（4b / 5 を維持）

[Question] Unit 定義ファイル末尾の dedup-warning コメントブロックは「## 実装状態」セクションの後ろに置くか、ファイル末尾（実装状態セクション後）か
[Answer] ファイル末尾（実装状態セクション後）。実装状態セクションは Construction Phase が更新するため、その後ろに置くことで誤更新リスクを下げる
