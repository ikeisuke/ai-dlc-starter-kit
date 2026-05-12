# 論理設計: Unit 006 AI エージェント Bash プロンプト経由の zsh OOM クラス予防

## 概要

「AI エージェントが Bash ツール経由で渡す文字列内のコマンド置換（`$(...)` / backtick）が zsh `command_not_found_handler` 再帰で OOM クラッシュを起こす根本原因クラス」への予防策を、リポジトリ配布規約の改訂として論理設計する。設計対象は **規約ドキュメント 7 ファイル**（CLAUDE.md / AGENTS.md / skills/aidlc/SKILL.md / skills/write-history/SKILL.md / commit-flow.md / review-flow.md / CHANGELOG.md）+ 案 b 採用時の `skills/aidlc/steps/common/<新設>.md`。

**重要**: 実行コード変更は伴わない。本論理設計は「規約レイヤー間の参照経路」「各ファイルの改訂差分構造」「案 a / b 確定スコアリング」を成果物として残す。

## アーキテクチャパターン

**SoT + Reference パターン**: 規約本文を CLAUDE.md ① セクションに **唯一の一次出典**（Single Source of Truth）として集約し、他ドキュメント（AGENTS.md / 各 SKILL.md / steps/common/ 新設ガイド等）は **規約本文を保持せず参照リンクと運用例のみ保持する**（DRY 原則）。理由:

- 重複記述によるドリフト（一方だけ更新される）リスクを排除
- 参照先がリポジトリルートに集約されることで、配布物の baseline 規約として consumer プロジェクトにも自然に届く
- 規約改訂時の編集範囲が 1 ファイル（+ アンカー保持）に限定される

レイヤー構造（ドメインモデル §エンティティから継承）:

```text
project_root（CLAUDE.md = SoT）
  └─ agent_baseline（AGENTS.md = リンク参照のみ）
  └─ skill_spec（SKILL.md 群 = リンク参照 + write-history のみ補強記述）
  └─ phase_common（commit-flow.md / review-flow.md = クロスリファレンス）
  └─ changelog（CHANGELOG.md = 変更記録）
```

## コンポーネント構成

### レイヤー / モジュール構成

```text
ConventionAggregate
├── CLAUDE.md（SoT / project_root）
│   ├── §設計原則（既存）
│   └── §AI エージェント Bash ツール経由の安全パターン（新規）
│       ├── 規約宣言（コマンド置換禁止 / 適用範囲）
│       ├── 背景（zsh command_not_found_handler 再帰 OOM）
│       ├── 安全パターン（第一推奨 / 第二推奨 / 禁止）
│       ├── 参考表（file-based 経路 vs 直接引数経路 / 4 行）
│       └── 関連 Issue（#697 primary / #688 sibling_resolved）
├── AGENTS.md（新規 / agent_baseline）
│   └── §Bash ツール経由の安全パターン（CLAUDE.md 参照リンクのみ）
├── skills/aidlc/SKILL.md（skill_spec）
│   └── §バージョン表示 §注意: 使用すべきでない呼び出し経路
│       ├── 案 a 採用時: 「Bash ツール経由の zsh OOM 回避ルール」として一般化
│       └── 案 b 採用時: steps/common/<新設>.md を参照する形に縮退
├── skills/write-history/SKILL.md（skill_spec）
│   └── §引数表 / §使用例 で --content-file 第一推奨を明示
├── skills/aidlc/steps/common/commit-flow.md（phase_common）
│   └── 既存 line 91 の「プロジェクトルール」参照を CLAUDE.md 新規セクションへの明示参照に格上げ
├── skills/aidlc/steps/common/review-flow.md（phase_common）
│   └── 既存 backtick 関連記述（review summary 引用パス記法）との責務分離注記を追加
├── CHANGELOG.md（changelog）
│   └── §[2.6.2] §Changed に Unit 006 規約改訂項目を追加
└── skills/aidlc/steps/common/<新設>.md（案 b 採用時のみ）
    └── 「Bash ツール経由 zsh OOM 回避 運用ガイド」（規約本文は保持しない / CLAUDE.md ① 参照 + 運用例 + 実装スニペットのみ）
```

### コンポーネント詳細

#### CLAUDE.md ① セクション（SoT）

- **責務**: コマンド置換禁止規約 / 適用範囲 / 背景 / 安全パターン / file-based interface 参考表 / 関連 Issue を一次定義する
- **依存**: 個人グローバル `~/.claude/CLAUDE.md` の同種規約とは独立（リポジトリ baseline として書き直す）
- **公開インターフェース**:
  - アンカー `#ai-エージェント-bash-ツール経由の安全パターン`（markdown header から auto-generated）
  - 参考表に `履歴記録` / `PR 本文` / `PR Ready` / `外部 CLI レビュー` の 4 行（最低限）

#### AGENTS.md（新規 / 最小骨格）

- **責務**: AGENTS.md 参照型 AI エージェント（Codex CLI / Gemini CLI 等）に対するリポジトリ baseline 規約のエントリポイント
- **依存**: CLAUDE.md ① セクション（参照）
- **公開インターフェース**:
  - `# AGENTS.md` / `## Bash ツール経由の安全パターン` の最小 2 セクション
  - CLAUDE.md 該当アンカーへの参照リンク
  - 要点 1〜2 行のサマリ（参照先到達前の最低限の防御）

#### skills/aidlc/SKILL.md §注意: 使用すべきでない呼び出し経路

- **責務**: `/aidlc v` 経路（Issue #688）の zsh OOM 回避を一般化 / 共通ガイドへ移管
- **依存**: 案 a → CLAUDE.md ① セクション参照（または本セクション内で一般化） / 案 b → `steps/common/<新設>.md` 参照
- **公開インターフェース**: 既存セクション見出しは維持（v2.6.1 で導入済みのアンカーを保持）
- **案 b 採用時のトレーサビリティ確保**（R1 指摘 #4 反映）: SKILL.md 側を「単純参照のみ」に縮退させず、**一般化要約 1〜2 文を SKILL.md 内に残す**。Unit 定義「責務」の「`skills/aidlc/SKILL.md` の `/aidlc v` 経路の zsh OOM 注意書きを `Bash ツール経由の外部スクリプト呼び出しに共通する zsh OOM 回避ルール` として一般化」という要件は SKILL.md 内の要約で直接充足し、詳細（運用例 / 禁止パターンサンプル / 実装スニペット）は `steps/common/<新設>.md` を参照する形にする。要件充足判定がレビューア依存にならないよう、論理設計レベルで配置を固定する

#### skills/write-history/SKILL.md

- **責務**: `--content` / `--content-file` の使い分けを AI 第一推奨として明示（既存 API 変更なし）
- **依存**: CLAUDE.md ① セクション（参照）
- **公開インターフェース**: 既存引数表・使用例セクションを保持。`--content-file` 推奨明示行（1〜2 行）と CLAUDE.md ① への参照を追記

#### commit-flow.md

- **責務**: 既存 line 91 の「`$(...)` コマンド置換禁止のプロジェクトルール準拠」参照を、CLAUDE.md ① セクションへの明示リンクに格上げ
- **依存**: CLAUDE.md ① セクション
- **公開インターフェース**: 既存セクション見出し維持

#### review-flow.md

- **責務**: 既存 backtick 関連記述（review summary パス記法）が CLAUDE.md ① セクションの「Bash ツール経由」規約と **別観点** であることを 1 行で明示
- **依存**: CLAUDE.md ① セクション
- **公開インターフェース**: 既存セクション見出し維持

#### CHANGELOG.md

- **責務**: v2.6.2 セクションに本 Unit の規約改訂を `Changed` 項目として記録
- **依存**: なし（変更履歴の単方向追記）
- **公開インターフェース**: 既存フォーマット準拠（Keep a Changelog）

#### skills/aidlc/steps/common/<新設>.md（案 b 採用時のみ）

- **責務**: 「Bash ツール経由 zsh OOM 回避」の **運用ガイド**（規約本文は保持しない）。CLAUDE.md ① セクションを SoT として参照し、その規約を AI エージェント運用視点での具体例・禁止パターンサンプル・安全パターン実装スニペットに展開する
- **依存**: CLAUDE.md ① セクション（規約 SoT 参照）
- **SoT 責務境界**: 規約本文は CLAUDE.md ① にのみ存在し、本ファイルには絶対に重複記述しない（規範性と運用性の責務分離）
- **公開インターフェース**: ファイル名は `bash-tool-safety.md`（仮 / 案 b 採用時に Phase 2 で確定）

## インターフェース設計

本 Unit は API / コマンド / クエリを新設しない。代わりに **規約ドキュメント間の参照リンク仕様** を定義する。

### 参照リンク記法（規約）

- **Markdown 内参照**: `` [テキスト](`CLAUDE.md`#ai-エージェント-bash-ツール経由の安全パターン) `` のように repo-relative path + 自動生成アンカー
- **アンカー安定性**: 見出し文言から `markdownlint` 互換のスラッグ生成を前提とする
- **参照先存在性**: Phase 2 完了時に手動 grep でリンク健全性を確認（自動化ツールは新設しない）

### CLAUDE.md ① セクション参考表（4 行 + α）

| 用途 | file-based 経路 | 直接引数経路（非推奨） |
|------|----------------|------------------------|
| 履歴記録 | `write-history.sh --content-file <file>` | `--content "..."` |
| PR 本文 | `gh pr create / edit --body-file <file>` | `--body "..."` |
| PR Ready 化 | `operations-release.sh pr-ready --body-file <file>` | （該当なし） |
| 外部 CLI レビュー | `codex exec - < <file>`（stdin 経由）/ `claude -p` の wrapper script 経由 | `codex exec "..."` |

## スクリプトインターフェース設計

該当なし。本 Unit はスクリプトを新設しない。既存スクリプトの引数仕様は完全維持する。

## データモデル概要

該当なし。

## 処理フロー概要

本 Unit は対話的なプロセスを持たない。代わりに **Phase 2 改訂順序** を以下に固定する。

### Phase 2 実装フロー（固定順序 / 案 b 採用）

1. CLAUDE.md ① セクション新規追加（SoT 確立 / 他改訂の前提）
2. AGENTS.md 新規作成（CLAUDE.md ① への参照リンクのみ）
3. `skills/aidlc/steps/common/<新設>.md` 作成（案 b 採用 / SKILL.md からの参照先を先に作る）
4. skills/aidlc/SKILL.md §注意 セクション改訂（案 b: 一般化要約 1〜2 文 + step 3 への詳細参照）
5. skills/write-history/SKILL.md 改訂（`--content-file` 第一推奨明示 + CLAUDE.md ① / step 3 への参照）
6. commit-flow.md 改訂（line 91 参照を CLAUDE.md ① への明示リンクに格上げ）
7. review-flow.md 改訂（責務分離注記 1 行追加）
8. CHANGELOG.md v2.6.2 §Changed 追加
9. markdownlint-cli2 実行（全改訂ファイル）
10. shellcheck / shellharden 実行（該当ファイル 0 件 / 形式確認のみ）
11. リンク健全性手動 grep（CLAUDE.md ① セクションへの参照リンクが 5 ファイル以上から到達可能）

**理由（順序固定の根拠 / R1 指摘 #2 反映）**:

- SoT（CLAUDE.md ①）を **最初に** 確立しないと、後続ファイルが「存在しない参照先」を指す状態が発生する
- 案 b 採用時は SKILL.md が新設 `steps/common/<新設>.md` を参照する設計のため、**新設ファイル作成 (step 3) → SKILL.md 改訂 (step 4) の順序を厳守**する（一時的な参照不整合の予防）
- git 状態としては各ステップでコミット可能だが、本 Unit はドキュメント Unit のため Phase 2 を 1 コミットに集約する（squash 前提）

**案 a 採用時の代替順序**（参考 / 本 Unit では未採用）: step 3 をスキップし、step 4 で SKILL.md 内に直接一般化を記述する 10 ステップ構成になる。

## 非機能要件（NFR）への対応

### 可読性（Unit 定義 NFR）

- **要件**: 規約改訂後の CLAUDE.md / AGENTS.md / SKILL.md が AI エージェントにとって解釈一意で曖昧でないこと
- **対応策**:
  - CLAUDE.md ① セクションは **断定文** で記述（「〜してはいけない」「〜を使う」）
  - 例外条件・推奨度の境界（第一推奨 / 第二推奨 / 禁止）を表形式で示す
  - 「全 Bash ツール呼び出し引数文字列」の対象範囲を冒頭で 1 文に圧縮し、配下の安全パターン記述で具体化

### 互換性（Unit 定義 NFR）

- **要件**: 既存スクリプトの動作・引数仕様を一切変更しない
- **対応策**:
  - 本 Unit のスコープは規約ドキュメント改訂のみ。`scripts/` / `bin/` / `lib/` 配下のスクリプト本体は touch しない（実装フェーズの境界条件）
  - `--content` 引数の廃止予定や非推奨化（deprecated 表記）は **しない**。「AI エージェント向け推奨度の整理」のみ実施

### 検証可能性（Unit 定義 NFR）

- **要件**: 規約遵守が PR コードレビューで判定可能（手動 + lint）
- **対応策**:
  - markdownlint-cli2 で改訂ファイルの構文を機械的に保証
  - リンク健全性は手動 grep（自動化ツール新設は本 Unit のスコープ外）
  - 改訂内容が consumer プロジェクトに与える影響を CHANGELOG.md §Changed で記録

## 技術選定

- **記法**: GitHub Flavored Markdown（既存リポジトリ準拠）
- **lint**: markdownlint-cli2（既存設定 `.markdownlint.jsonc` をそのまま流用）
- **shell 検証**: shellcheck / shellharden（規約改訂対象に shell ファイルは含まれないが、既存 lint パイプラインへの非干渉を確認）
- **新規ツール / ライブラリ**: なし

## 案 a / b 評価ログ（4 基準スコアリング）

ドメインモデルの [Answer] に従い、計画の「案 a / b 選定基準」4 軸でスコアリングする。

| 基準 | 案 a が優位な条件 | 案 b が優位な条件 | 本 Unit での判定 | 優位 |
|------|------------------|------------------|----------------|------|
| 参照経路の単純性 | SKILL.md 一箇所完結なら 1 ホップ | 共通ガイド経由は 2 ホップだが他 SKILL.md からも再利用される場合に有利 | 本 Unit では skills/write-history からも参照したい / 他 skill_spec への再利用余地あり | **案 b** |
| 重複記述量 | SKILL.md だけで完結する場合 | 複数 SKILL.md から参照される場合、共通ガイドで 1 箇所定義が DRY | write-history / aidlc 両方から参照する設計 | **案 b** |
| 責務分離 | `/aidlc v` 経路に固有の話なら案 a | 「Bash ツール経由全般」が `aidlc` スキル固有でないなら案 b | Unit 006 の対象は「全 Bash ツール経由経路」で aidlc 固有でない | **案 b** |
| 保守コスト | SKILL.md 集約は拡張時編集範囲が広い | 共通ガイド集約は拡張時 1 ファイル編集で済む | 将来 `codex exec` / `claude -p` 等への拡張余地が高い | **案 b** |

**スコア**: 案 a 0 / 案 b 4 → **案 b 採用**（4 基準すべてで案 b 優位 / 計画の確定ロジック「3 つ以上で優位なら採用」に該当）

**Phase 2 への影響**:

- `skills/aidlc/steps/common/bash-tool-safety.md`（仮称 / 命名は Phase 2 コード生成時に確定）を新設
- `skills/aidlc/SKILL.md` §注意セクションは **「Bash ツール経由の外部スクリプト呼び出しに共通する zsh OOM 回避ルール」一般化要約 1〜2 文 + 詳細は steps/common への参照** という 4〜6 行構成にする（R1 指摘 #4 反映 / Unit 定義「責務」のトレーサビリティを SKILL.md 内で直接充足）
- `skills/write-history/SKILL.md` も同じ共通ガイドを参照
- 規約本文の SoT は **依然として CLAUDE.md ① セクション**。`steps/common/bash-tool-safety.md` は「AI エージェント運用視点での具体ガイド」として CLAUDE.md ① の規約を実装ガイドラインに展開する役割（SoT は重複しない / 規範性と運用性の責務分離）

## 実装上の注意事項

- **SoT 二重化の禁止**: `steps/common/bash-tool-safety.md`（案 b 採用）と CLAUDE.md ① セクションの両方に規約本文を書かない。`steps/common/` は「運用具体例」「禁止パターンの具体的サンプル」「安全パターンの実装スニペット」のみを記載し、規約本文は CLAUDE.md ① への参照に統一する
- **アンカー安定性**: CLAUDE.md ① のセクション見出しを Phase 2 で 1 度だけ確定し、参照リンクが全て同じアンカーを指すよう統一する
- **CHANGELOG.md フォーマット**: 既存 v2.6.1 / v2.6.0 と同じ Keep a Changelog 記法を踏襲。Unit 番号 / 関連 Issue を必ず記載
- **個人 CLAUDE.md との重複懸念**: 個人グローバル `~/.claude/CLAUDE.md` の「`$(...)` 絶対禁止」とリポジトリ CLAUDE.md ① の「Bash ツール経由」規約は別観点として共存可能。リポジトリ ① セクション内で「個人設定で類似規約を持つ場合との関係性」を 1〜2 行で言及する（用語の混乱回避）
- **ドッグフーディング特殊処理排除**: 規約本文に「starter kit 自身か consumer か」を判定する条件分岐の記述を含めない。consumer の AI エージェント運用にも自然適用される普遍的な規約として記述する

## 不明点と質問（設計中に記録）

[Question] 案 b 採用で新設する共通ガイドのファイル名候補
[Answer] Phase 2 で確定。候補: `bash-tool-safety.md`（用途明示 / 推奨）/ `ai-prompt-safety.md`（AI エージェント観点 / 代替）/ `zsh-oom-prevention.md`（根本原因観点 / 検索性は高いが範囲狭い印象）。Phase 2 コード生成時に最終確定する

[Question] CHANGELOG.md §Added / §Changed / §Fixed のどこに置くか
[Answer] `Changed`（規約改訂は仕様変更ではなく既存規約の文書整理 + 拡張 / `Added` は新規機能向け / `Fixed` は v2.6.1 Unit 001 で個別解決済のためここでは使わない）

[Question] commit-flow.md line 91 の「プロジェクトルール準拠」表記をどう書き換えるか
[Answer] 既存表現を保持しつつ、新規参照リンクを追加する 2 段構成にする。例: 「`$(...)` コマンド置換禁止のプロジェクトルール（CLAUDE.md §AI エージェント Bash ツール経由の安全パターン）準拠、ファイル経由 + `grep -Fxq`）」。1 段で書き換えると既存実装の正当性記述と齟齬が出るため、追記の形が安全

[Question] AGENTS.md の冒頭サマリで CLAUDE.md 到達前に最低限示すべき防御内容
[Answer] 2 項目: (a) コマンド置換（`$(...)` / backtick）を Bash ツールの引数文字列に含めない、(b) 長文プロンプトは file-based interface または Write ツール経由の一時ファイルとする。これだけで「CLAUDE.md を読まずに作業を始めてしまった AI エージェント」も最低限の防御が効く

[Question] review-flow.md の責務分離注記をどこに置くか
[Answer] §「内容」列のパス記法（規約）の冒頭（line 121 付近）に 1 行追加する。例: 「（本セクションは review-summary 引用パス記法を扱う。Bash ツール引数文字列内のコマンド置換禁止規約とは別観点であり、詳細は CLAUDE.md §AI エージェント Bash ツール経由の安全パターン を参照）」
