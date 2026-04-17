# 論理設計: Unit 004 Construction 側の squash 完了後 force-push 案内

## 概要

ドメインモデル（`unit_004_construction_squash_push_guidance_domain_model.md`）を `skills/aidlc/steps/construction/04-completion.md` の Markdown セクションとして写像する論理設計。静的案内のみ扱い、外部スクリプト変更は行わない。

**重要**: この論理設計では**コードは書かず**、Markdown 記述の構成とインターフェース（配置位置・セクション構造・文言要素）のみを定義する。

## 責務境界の再確認

| ドメイン層 | 実装対象 | 対応記述 |
|-----------|---------|---------|
| 条件付き案内ドメイン（`GuidanceRenderer`） | `skills/aidlc/steps/construction/04-completion.md` | ステップ 7 の直後に常設される Markdown サブセクション（記述自体は常設。AI エージェントが `squash:success` 時のみユーザーに提示、`squash:skipped` / `squash:error` では提示抑制） |
| 安全性契約ガード（`SafetyContractEnforcer`） | Markdown 内の必須要素（`--force-with-lease` 推奨・事前確認併記・警告併記・多層防御紹介） | 設計レビューと計画書チェックリストで目視確認 |
| 動的検出ドメイン（Unit 002） | `skills/aidlc/scripts/validate-git.sh` 他 | **本 Unit のスコープ外**。独立文書として整合 |

## アーキテクチャパターン

**静的ドキュメント + AI エージェント条件付き提示 + 安全性契約**:

- Markdown 文書による**固定表現**でユーザーに情報を提供（記述は常設）
- AI エージェントがステップ 7 のシグナル（`squash:success` / `squash:skipped` / `squash:error`）に応じて **本節を提示するかを制御**する（Markdown ファイル自体は書き換えない）
- 動的な「リモート状態判定」（既に push 済み等）は行わない。それは Unit 002（Operations Phase）の責務
- 安全性契約（`--force-with-lease` 限定・事前確認必須・警告必須）は Markdown の構造（セクション構成）で担保

## Markdown セクション構成

### 配置位置

`skills/aidlc/steps/construction/04-completion.md` の **ステップ 7（Squash）** の直後に常設セクションとして追加。ステップ 7 の分岐テーブルに AI エージェントの提示制御情報を組み込み、セクション見出し・本文冒頭にも提示条件を明記する:

```text
### 7. Squash（コミット統合）【オプション】

... 既存記述 ...

- `squash:success` → **ステップ 7a（force-push 推奨案内）をユーザーに提示** → ステップ8スキップ
- `squash:skipped` → ステップ8へ（ステップ 7a は**提示しない**）
- `squash:error` → エラーリカバリ後ステップ8へ（ステップ 7a は**提示しない**）

### 7a. Force-push 推奨コマンド案内【`squash:success` 時のみ提示】    ← 本 Unit で常設追加

> **提示条件**: ステップ 7 が `squash:success` を出力した場合のみ、AI エージェントが本節をユーザーに提示する。
> `squash:skipped` / `squash:error` では本節を提示しない（抑制）。
> ユーザーが既にリモートへ force-push 済みであることを確認できる場合も本節を提示せずスキップしてよい（判断はユーザー確認で行う）。

... 推奨コマンド・事前確認・警告・多層防御 ...

### 8. Gitコミット
```

**根拠**:
- Markdown ファイル自体は常設（書き換えは行わない）。提示制御は AI エージェントがシグナルに応じて行う
- 提示条件を 3 箇所（ステップ 7 分岐テーブル / セクション見出し `【squash:success 時のみ提示】` / セクション本文冒頭の `> 提示条件` 注記）で重複表現し、AI エージェントの提示制御が一貫するよう担保
- ステップ 7 の直後に配置することで、squash 直後のリモート状態に対する案内として文脈的に自然
- ステップ 8（Gitコミット）より前に配置することで、force-push のタイミングを明確化
- 他のステップ（9: Unit PR 作成、10: 完了サマリ）への波及は不要（Unit 定義「境界」準拠）

### セクション内部構造（必須要素、順序は任意）

**注**: 要素の順序は厳密に固定せず、Markdown として読みやすい任意の並びを許容する（例: 事前確認を推奨コマンドの前に書く構成も可）。ただし**以下の全要素を同一セクション内に欠落なく含める**ことが安全性契約。

```markdown
### 7a. Force-push 推奨コマンド案内【`squash:success` 時のみ提示】

> **提示条件**: ステップ 7 が `squash:success` を出力した場合のみ、AI エージェントが本節をユーザーに提示する。
> `squash:skipped` / `squash:error` では本節を提示しない（抑制）。
> ユーザーが既にリモートへ force-push 済みであることを確認できる場合も本節を提示せずスキップしてよい（判断はユーザー確認で行う）。

**背景**: squash 実行によりローカル履歴が rewrite されたため、
リモート（`origin/{ブランチ}`）は古いコミット列を保持している。
この状態で通常の `git push` は rejected になる。

**推奨コマンド**:

```bash
git push --force-with-lease <remote> HEAD:<upstream_branch>
```

`<remote>` と `<upstream_branch>` は自分の環境（例: `origin` と `cycle/v2.3.5`）に置換する。

**`--force-with-lease` を推奨する理由**: `--force` は他者のコミットも
上書きしてしまうため、本案内では `--force-with-lease`（ローカルの upstream 記録と
リモート HEAD が一致する場合のみ上書きする安全な形式）のみを推奨する。

**事前確認【必須】**: 実行前に以下を必ず確認する:

```bash
# upstream 側の差分コミットを確認（他者の作業が含まれていないか）
git log HEAD..<remote>/<upstream_branch>

# ローカル側の差分コミットを確認（上書き意図どおりか）
git log <remote>/<upstream_branch>..HEAD
```

**実行中止の判定基準**: 他者のコミットが upstream に含まれている、
または tracking 設定違いが疑われる場合は実行を中止し、rebase
/ tracking 再設定 / 個別相談などユーザー判断で対応する。
force-push は自動実行しない（ユーザーが明示的に実行する）。

**多層防御**: 本案内を見落とした場合でも、Operations Phase 開始時に
`scripts/validate-git.sh remote-sync`（Unit 002 実装）が `diverged` を
検出して再度案内する。
```

### セクション構造の論理要素（ドメインモデル対応）

| Markdown 要素 | ドメインモデル対応 | 必須性 |
|--------------|------------------|-------|
| セクションタイトル（`### 7a. ...`） | `GuidanceRenderer.render()` の出力構造 1 | 必須 |
| 適用範囲の注記（`> 適用: ...`） | `ApplicabilityNote.applicable_signal` + `skip_condition` + `already_pushed_note` | 必須 |
| 背景の説明 | 静的案内の文脈情報 | 必須 |
| 推奨コマンド（コードブロック） | `RecommendedCommand.template` | 必須 |
| プレースホルダー解説 | `RecommendedCommand.placeholders` | 必須 |
| `--force-with-lease` 推奨理由 | `RecommendedCommand.flag` + `SafetyContractEnforcer` | 必須 |
| 事前確認（2 つの `git log`） | `PreflightCheck.check_upstream_diff_command` / `check_local_diff_command` | 必須 |
| 実行中止の判定基準 | `PreflightCheck.abort_condition` | 必須 |
| 「自動実行しない」の明記 | `UserNotice.manual_execution_only` | 必須 |
| 多層防御の説明 | Unit 002 との役割差 | **必須**（ドメインモデル安全性契約 #6 と同期） |

## コンポーネント構成

本 Unit はドキュメントのみの変更のため、コード的な「コンポーネント」は存在しない。代わりに **Markdown セクション内の論理要素**を以下の構造で配置する:

```text
04-completion.md
└── ステップ 7. Squash（コミット統合）
    ├── 既存: squashフロー記述
    ├── 既存: squash:success / skipped / error シグナル
    └── 新規: 7a. Force-push 推奨コマンド案内（常設）
        ├── 適用範囲の注記（ApplicabilityNote）
        ├── 背景の説明
        ├── 推奨コマンド（コードブロック）
        ├── プレースホルダー解説
        ├── --force-with-lease 推奨理由
        ├── 事前確認（git log 2 種）
        ├── 実行中止の判定基準
        ├── 自動実行しない明記
        └── 多層防御の説明（必須）
```

## インターフェース設計

### Markdown セクションの公開インターフェース

- **入力**: ステップ 7 の squash シグナル（`squash:success` / `squash:skipped` / `squash:error`）— AI エージェントが読み取り、提示可否を判定
- **出力**: AI エージェントが `squash:success` 時のみユーザーに Markdown セクション本文を提示
- **前提条件**: AI エージェントがステップ 7 の分岐テーブルおよびセクション 7a 冒頭の「提示条件」注記を読んでいること
- **後続処理**: なし（ユーザーが独立して判断し、必要に応じて手動で `git push --force-with-lease` を実行）

### `04-completion.md` 既存シグナルとの関係

Markdown セクションとしては常設（ファイルに常時存在）だが、AI エージェントはステップ 7 のシグナルに応じて本節を**ユーザーに提示するかどうかを制御する**。シグナルと AI エージェントの提示動作の関係:

| シグナル | AI エージェントの提示動作 | 理由 |
|---------|------------------------|------|
| `squash:success` | **提示する** | 本案内の主な対象。squash による history rewrite 後の force-push を案内 |
| `squash:skipped` | **提示しない**（抑制） | squash 未実施のため rewrite なし、force-push 不要 |
| `squash:error` | **提示しない**（抑制） | エラーリカバリを優先、案内は不適切 |
| `rules.git.squash_enabled=false` | ステップ 7 自体を通過しないため到達しない | ステップ 7 が実行されないため本案内に到達することは稀 |

提示制御の根拠は 3 箇所の情報源による重複表現により担保される: (1) ステップ 7 の分岐テーブル内の AI 向け提示指示、(2) セクション 7a の見出し `【squash:success 時のみ提示】`、(3) セクション 7a 冒頭の「提示条件」注記。AI エージェントはこの 3 箇所を読み取って提示/抑制を判断する。ユーザーが「既に push 済み」であることを示唆した場合は提示せずスキップしてよい（AI エージェントの裁量）。

## データモデル概要

### 静的 Markdown 要素

本 Unit で新規追加する Markdown 要素は以下の固定文字列セットで構成される:

| 要素 | 内容 |
|------|------|
| セクションタイトル | `### 7a. Force-push 推奨コマンド案内【squash:success 時のみ提示】` |
| 適用範囲の注記 | `squash:success` のみ参照、他はスキップ、既に push 済みならスキップ |
| 推奨コマンドテンプレート | `git push --force-with-lease <remote> HEAD:<upstream_branch>` |
| 事前確認コマンド 1 | `git log HEAD..<remote>/<upstream_branch>`（upstream 差分） |
| 事前確認コマンド 2 | `git log <remote>/<upstream_branch>..HEAD`（local 差分） |
| 実行中止の判定基準 | 他者コミット含有・tracking 設定違い疑念時 |
| 自動実行禁止の明記 | ユーザーが明示的に実行、自動実行はしない |
| 多層防御の説明 | Operations Phase の動的検出が保険として機能 |

## 処理フロー概要

### ユースケース 1: squash 実施済みで未 push の場合

**ステップ**:

1. ユーザーが `04-completion.md` ステップ 7 で squash を実行
2. `squash:success` シグナルが出力される
3. ユーザーが新規サブセクション 7a を読む
4. 推奨コマンドの背景と文言を確認
5. 事前確認の 2 つの `git log` コマンドを実行
6. upstream 差分に他者コミットがないこと、local 差分が意図どおりであることを確認
7. `git push --force-with-lease <remote> HEAD:<upstream_branch>` を実行（`<remote>` / `<upstream_branch>` は自分の環境に置換）
8. ステップ 8（Gitコミット）へ進む

### ユースケース 2: 既に push 済みの場合

**ステップ**:

1. ユーザーが squash を実行（または過去に実行済み）
2. `squash:success` シグナルが出力される
3. ユーザーが新規サブセクション 7a を読む
4. 適用範囲の注記「既にリモートへ force-push 済みの場合もスキップしてよい」を確認
5. 自分の状況を判断してスキップ
6. ステップ 8（Gitコミット）へ進む

### ユースケース 3: squash 未実施の場合（`squash:skipped`）

**ステップ**:

1. ユーザーが `04-completion.md` ステップ 7 で squash を実行しない（`rules.git.squash_enabled=false` 等）
2. `squash:skipped` シグナルが出力される
3. 新規サブセクション 7a の適用範囲注記により**読み飛ばしてよい**と判断
4. ステップ 8（Gitコミット）へ進む

### ユースケース 4: Construction 側の案内を見落として Operations Phase に進んだ場合

**ステップ**:

1. ユーザーが squash 実施済みだが force-push を見落として Operations Phase へ
2. `operations-release.sh verify-git` → `validate-git.sh remote-sync` が `diverged` を検出
3. `status:diverged` + `recommended_command:<実値>`（Unit 002 契約により `<remote>` / `<upstream_branch>` は実際の値に展開される）が出力される
4. `operations-release.md` 7.10 / `01-setup.md` §6a のユーザー選択フローで事前確認と実行を案内
5. Operations 側で救済される（多層防御）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 既存と同等（ドキュメントのみの変更のため性能影響なし）
- **対応策**: N/A

### セキュリティ（安全性契約）

- **要件**: `--force` ではなく `--force-with-lease` を必ず推奨（Unit 定義 NFR）
- **対応策**:
  - Markdown 記述で `--force-with-lease` のみを推奨コマンドに含める
  - `--force` を代替として紹介しない
  - 事前確認（2 つの `git log`）を必須併記
  - 実行中止の判定基準を明記
  - 自動実行を禁止

### 可用性

- **要件**: Construction 側の案内を見落としても Operations 側でカバーされる
- **対応策**: 多層防御として Unit 002 の動的検出を紹介

### 保守性

- **要件**: Unit 002 との**独立性**を保ちつつ、推奨コマンド種別と事前確認観点は共通化
- **対応策**:
  - 文字列完全一致は目指さない（指摘 #2 対応）
  - 推奨コマンド種別（`git push --force-with-lease`）を揃える
  - 事前確認観点（`git log` 2 種）を揃える
  - 役割差（Construction=静的、Operations=動的）を明示

## 技術選定

- **言語**: Markdown のみ（Bash / シェルスクリプトの変更なし）
- **フレームワーク**: なし
- **依存**: 既存 `04-completion.md` の構造のみ

## 既存ガイドとの照合

### `skills/aidlc/guides/worktree-usage.md`

- 本 Unit の案内は worktree 運用との整合が必要（dev worktree で force-push する場合のユースケース）
- 特別な対応は不要（worktree 環境でも `git push --force-with-lease` は同じコマンドで動作）

### `skills/aidlc/guides/branch-protection.md`

- Branch protection 下では force-push が制限される可能性があるが、本 Unit は「推奨コマンドの案内」であり実行保証は行わない
- Branch protection で拒否された場合はユーザーが個別対応（設定解除 or admin 権限依頼）
- 本 Unit 案内では触れない（ユースケースが広がりすぎる）

### `skills/aidlc/guides/exit-code-convention.md`

- 本 Unit はドキュメントのみで exit code を扱わないため対象外

## 実装上の注意事項

### 文言の簡潔性

- セクション全体で 15-20 行程度に収める（冗長すぎるとステップ 7 のフローが読みにくくなる）
- 事前確認コマンドのコメントは 1 行で簡潔に

### コードブロックのフォーマット

- 推奨コマンドは `bash` 言語指定のコードブロック
- 事前確認コマンドも `bash` 言語指定で 2 コマンドを併記

### `<remote>` / `<upstream_branch>` プレースホルダー

- 角括弧記法（`<...>`）を使用（Unit 002 の `operations-release.md` 7.10 / `01-setup.md` §6a と揃える）
- リテラル `origin` / `cycle/v2.3.5` 等は書かない（サイクル・環境依存を排除）

### Unit 002 との差異の明記

- 本 Unit の Markdown 内で「Operations Phase 開始時に `validate-git.sh remote-sync` が再度検出する」旨を 1 文で紹介
- 詳細な動的検出の説明は Unit 002 のドキュメントに委ねる（本 Unit では言及のみ）

### markdownlint 準拠

- 既存 `04-completion.md` と同じ Markdown スタイル（見出しレベル・箇条書き形式）に従う
- 行長制限（markdownlint 設定依存）を守る

## 不明点と質問

[Question] 新規サブセクション番号を `7a` とするか `7.1` とするか、あるいは `8 新設・既存ステップ番号を繰り下げ` とするか？
[Answer] `7a` を採用。既存ステップ 7 の「補足的な案内」であり、後続のステップ 8 以降の番号を繰り下げないことで既存ドキュメント・履歴への影響を最小化する。`04-completion.md` 内で既存の番号繰り下げ前例はないため、サブセクション記法 `7a` が最適。

[Question] 推奨コマンドに `HEAD:<upstream_branch>` 形式を使うか、シンプルに `<upstream_branch>` だけにするか？
[Answer] `HEAD:<upstream_branch>` 形式を使用（Unit 002 の `validate-git.sh run_remote_sync` が出力する `recommended_command` と一致、異名 upstream 対応）。local ブランチ名と upstream ブランチ名が一致する標準的なケースでは `<upstream_branch>` のみでも動作するが、Unit 002 と整合するため `HEAD:<upstream_branch>` 形式に統一する。

[Question] 事前確認コマンドに `--oneline` フラグを付けてログを見やすくするか？
[Answer] 付けない。シンプルな `git log HEAD..<remote>/<upstream_branch>` 形式とし、表示形式の選択はユーザーに委ねる（`--oneline` / `--graph` / その他、環境や好みで異なる）。Unit 002 の `operations-release.md` 7.10 の事前確認と揃える。

[Question] 「既に push 済みかどうか」の自動判定コマンド（例: `git rev-parse @ && git rev-parse @{u}` の比較）を案内に含めるか？
[Answer] 含めない。本 Unit は**静的案内**のスコープ外。`rev-parse` 比較を含めるとユーザーがコマンドを誤解釈するリスクや、自動判定ロジックの実装欲求が生じる。適用範囲の注記「既に push 済みならスキップしてよい」を読んだユーザーが自分で判断する前提とし、詳細な検出は Unit 002（Operations Phase の `validate-git.sh remote-sync`）に委ねる。
