# Unit 003 実装計画: ドラフトPR作成設定の固定化

## 対象Unit

- Unit 003: ドラフトPR作成設定の固定化
- 関連Issue: #557, #551

## 目的

Inception Phase完了時のドラフトPR作成判断を `config.toml` の `rules.git.draft_pr` キー（`always/never/ask`）で設定可能にし、毎回の確認を省略できるようにする。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `skills/aidlc/config/defaults.toml` | 追加 | `[rules.git]` セクションに `draft_pr = "ask"` を追加 |
| `skills/aidlc/steps/inception/05-completion.md` | 主変更 | ステップ5のドラフトPR作成判定に `draft_pr` 設定分岐を追加 |
| `skills/aidlc/steps/inception/index.md` | 追記 | 分岐ロジックセクションに `draft_pr` 分岐を追記 |

## 変更方針

### 1. `defaults.toml` - デフォルト値追加

- `[rules.git]` セクションに `draft_pr = "ask"` を追加（既存の動作を維持）

### 2. `05-completion.md` - ステップ5の実行手順変更

現在のステップ5は `gh_status` 判定 → 既存PR確認 → ユーザー確認 → PR作成の流れ。`draft_pr` 分岐の判定ロジックは `index.md` に一元化し、`05-completion.md` では「判定は `index.md` §2.x を参照」として実行手順のみを持たせる。

**実行手順（`index.md` の分岐判定結果を受けて実行）**:

1. `gh_status` が `available` 以外 → スキップ（既存動作維持）
2. `draft_pr` 値を `read-config.sh` で取得し、`index.md` §2.x の分岐判定に従う
3. 判定結果に応じた実行:
   - `always`: 既存PR確認 → なければ自動作成（ユーザー確認なし）
   - `never`: スキップ（メッセージ表示）
   - `ask`: 既存PR確認 → なければユーザーに確認（既存動作。`automation_mode` には関与しない独立したユーザー選択）

**`read-config.sh` の終了コード別処理**:

| 終了コード | 意味 | 処理 |
|-----------|------|------|
| 0 | 値取得成功 | 値バリデーション（`always/never/ask` 以外は `⚠ draft_pr の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。` と警告し `ask` にフォールバック） |
| 1 | キー不在 | `⚠ draft_pr が未設定です。デフォルト値 "ask" を使用します。` と警告し `ask` にフォールバック |
| 2 | 読取エラー | `⚠ draft_pr の読み取りに失敗しました。デフォルト値 "ask" を使用します。` と警告し `ask` にフォールバック |

`draft_pr` は PR作成方針のみを表す独立設定であり、`automation_mode` とは無関係。`ask` は常にユーザー選択（`AskUserQuestion`）として扱う。

### 3. `index.md` - 分岐ロジック一元化

- 分岐ロジックセクションに `draft_pr` 分岐を新規セクションとして追記（`gh_status` 分岐のサブ分岐として位置付け）
- `draft_pr` の意味定義（`always/never/ask` の動作差分テーブル）はここにのみ記載
- `05-completion.md` は本セクションを参照し、実行手順のみを持つ

## 完了条件チェックリスト

- [x] `defaults.toml` の `[rules.git]` に `draft_pr = "ask"` が追加されている
- [x] `05-completion.md` ステップ5に `draft_pr` 設定分岐の実行手順が実装されている
- [x] `draft_pr` のバリデーションが実装されている（有効値: `always/never/ask`、不正値時は警告+`ask`フォールバック）
- [x] `read-config.sh` の終了コード別処理（0/1/2）が明確に定義されている
- [x] `draft_pr=always` で既存PRなし時にユーザー確認なしで自動作成される
- [x] `draft_pr=never` でスキップされる
- [x] `draft_pr=ask` で既存動作（ユーザー確認）が維持される
- [x] `draft_pr` は `automation_mode` とは独立した設定として扱われている
- [x] `index.md` の分岐ロジックに `draft_pr` 分岐が一元定義されている（意味定義は `index.md` のみ）
- [x] `05-completion.md` は `index.md` の分岐判定を参照し、実行手順のみを持つ
- [x] PR作成後の操作（本文更新、Ready化等）は変更されていない
- [x] Operations Phase のPR Ready化フローは変更されていない
- [x] テスト: N/A（Markdownプロンプト変更のみ）
