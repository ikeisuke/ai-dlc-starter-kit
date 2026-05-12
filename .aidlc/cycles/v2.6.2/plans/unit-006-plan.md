# Unit 006 計画: AI エージェント Bash プロンプト経由の zsh OOM クラス予防

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/006-ai-prompt-zsh-oom-prevention.md`
- 関連 Issue: #697（type:chore / priority:high / feedback / v2.6.1 Inception Phase 中に実発生）
- 関連クローズ済: #688（v2.6.1 Unit 001 で `/aidlc v` 経路の `read_marketplace_version` 呼び出しを CLI モード化で個別解決済）

## 目的

「AI エージェントが Bash ツール経由で long-text を bash 引数文字列として直接渡し、その中の backtick / `$(...)` がコマンド置換として展開され、未定義コマンドへの zsh `command_not_found_handler` 無限再帰で OOM クラッシュする」根本原因クラスへの予防策を、**規約改訂と推奨経路明文化**で確立する。

#688 は `/aidlc v` 経路の個別解決済（v2.6.1）だが、根本原因クラスは全 Bash ツール経由経路に存在しており、Markdown inline code（backtick）混入で再発する。本 Unit はコード変更を伴わず、リポジトリ配布物としての規約・ガイド・SKILL.md 表現を統一して AI エージェント運用安全性を向上させる。

## 前提整理（plan 時点での現状確認）

- **リポジトリ内 `CLAUDE.md`**: 「設計原則 § ドッグフーディング特殊処理を本体に埋めない」のみ記載。`$(...)` / backtick / コマンド置換禁止規約は **未記載**（個人グローバル `~/.claude/CLAUDE.md` にのみ存在する規約のため、配布物としての規約は別途追記が必要）
- **リポジトリ内 `AGENTS.md`**: **存在しない**
- **`skills/aidlc/SKILL.md` の zsh OOM 注意書き**: §「バージョン表示」の「注意: 使用すべきでない呼び出し経路」セクション（v2.6.1 Unit 001 で追加 / Issue #688）が `/aidlc v` 経路固有の表現になっている
- **`skills/write-history/SKILL.md`**: `--content` / `--content-file` の使い分けが既に明文化されているか要確認（設計フェーズで実態調査）
- **`skills/aidlc/steps/common/commit-flow.md` / `review-flow.md`**: 既存ファイル。backtick 関連の規約参照箇所が部分的に存在（`review-flow.md` のパス記法など）

## スコープ

### 含まれるもの

#### ① CLAUDE.md（リポジトリ内）への規約追加

1. **新規セクション**「## AI エージェント Bash ツール経由の安全パターン」追加:
    - コマンド置換禁止規約（`$(...)` および backtick `` ` `` 双方）の明文化
    - 対象範囲を「全 Bash ツール呼び出しの引数文字列」と明示
    - zsh `command_not_found_handler` 無限再帰 OOM クラッシュの背景説明
    - 安全パターン（優先順位順）:
      - **第一推奨**: Write ツールで一時ファイルに書き出し、wrapper script で読み込んで対象コマンドに渡す
      - **第二推奨**: `--content-file` / `--body-file` 等の file-based interface 優先使用
      - **禁止**: backtick / `$(...)` を含む文字列を Bash ツールの引数として直接渡す
    - 個人 `~/.claude/CLAUDE.md` の「`$(...)` 絶対禁止」セクションとの関係性を明示（リポジトリ規約は配布物としての baseline、個人設定は環境固有）
    - 関連 Issue 参照: #697（一般化）/ #688（`/aidlc v` 経路の個別解決済）

#### ② `skills/aidlc/SKILL.md` の注意書き一般化

2. §「バージョン表示」の「注意: 使用すべきでない呼び出し経路」セクションを以下のいずれかに改訂（設計レビューで方針確定）:
    - **案 a**: 同セクションを「Bash ツール経由のあらゆる外部スクリプト呼び出しに共通する zsh OOM 回避ルール」として一般化し、`/aidlc v` 例は配下の参照例として残す
    - **案 b**: `/aidlc v` 経路固有の表現は維持しつつ、一般化された注意書きを `steps/common/` 配下に新設し、SKILL.md 側はそちらを参照
3. 文中に Issue #697 / #688 のクロスリファレンスを追加

**案 a / b 選定基準（Phase 1 設計レビューで適用）**:

以下 4 基準を総合判定し、Phase 1 終了時に確定する。基準の優先順位は記載順。

| 基準 | 内容 | 案 a が優位な条件 | 案 b が優位な条件 |
|------|------|------------------|------------------|
| 参照経路の単純性 | 利用者（AI / 人間）が「Bash ツール経由の zsh OOM 回避」規約を発見するまでのホップ数 | SKILL.md 一箇所完結なら 1 ホップ | `steps/common/` 共通ガイドへの参照が 2 ホップ目だが、他 SKILL.md からも再利用される場合に有利 |
| 重複記述量 | 規約本文が複数箇所に分散しないか | SKILL.md だけで完結する場合 | 他 SKILL.md（`write-history` 等）からも参照される場合、`steps/common/` で 1 箇所定義が DRY |
| 責務分離 | CLAUDE.md（プロジェクト規約） vs SKILL.md（スキル仕様） vs `steps/common/`（フェーズ共通） の境界 | `/aidlc v` 経路に固有の話なら案 a | 「Bash ツール経由全般」が `aidlc` スキル固有でないなら案 b（`steps/common/` 寄り） |
| 保守コスト | 将来追加される類似経路（codex exec / write-history 等）への拡張容易性 | 案 a で SKILL.md に集約すると拡張時の編集範囲が広がる | 案 b で `steps/common/` に集約すると拡張時に 1 ファイル編集で済む |

**確定ロジック**:

- 4 基準のうち 3 つ以上で案 b 優位 → 案 b 採用（`steps/common/` 配下に新設し SKILL.md は参照のみ）
- 案 a 優位が 3 つ以上 → 案 a 採用（SKILL.md 内で一般化）
- 同点（2:2）→ 案 b（DRY 原則優先 / 拡張容易性を重視）をデフォルト採用

#### ③ write-history 等の long-text interface 推奨化

4. **MUST**: `skills/write-history/SKILL.md` で `--content` / `--content-file` 使い分けの記述を AI 第一推奨に位置付け（既存 API 動作は無変更）
    - 設計フェーズで `skills/write-history/SKILL.md` の現状を実態調査し、既に file-based 経路推奨が明記されていれば「AI 第一推奨」明示の追記のみ
5. **MUST**: 「AI エージェント向け Bash ツール経由 long-text 渡し時の安全パターン」を CLAUDE.md ① セクションに記載する際、同セクション内に以下の対応一覧を **参考表** として記載（個別 SKILL.md / docs の改訂は行わない / 表の出典は CLAUDE.md のみ）:

    | 用途 | file-based 経路 | 直接引数経路（非推奨） |
    |------|----------------|------------------------|
    | 履歴記録 | `write-history.sh --content-file <file>` | `--content "..."` |
    | PR 本文 | `gh pr create / edit --body-file <file>` | `--body "..."` |
    | PR Ready 化 | `operations-release.sh pr-ready --body-file <file>`（v2.6.2 Unit 001 整備済） | （該当なし） |
    | 外部 CLI レビュー | `codex exec - < <file>`（stdin 経由）/ `claude -p` の wrapper script 経由 | `codex exec "..."` |

    **完了条件で検証する対象**: CLAUDE.md ① セクションの参考表が上記 4 行を網羅していること。個別 SKILL.md（`operations-release.sh` / `gh pr` / `codex` 等）への直接改訂は本 Unit のスコープに含めない（別 Unit / 別 Issue で必要時に対応）

#### ④ クロスリファレンス整備

6. `skills/aidlc/steps/common/commit-flow.md` の「コミットメッセージ内 backtick 禁止」関連箇所に CLAUDE.md ①セクションへの参照を追加（既存記述があれば再強調、なければ短く言及）
7. `skills/aidlc/steps/common/review-flow.md` の review summary 引用パス記法（既存 backtick ルール）と、CLAUDE.md ①セクションの「Bash ツール経由」規約の責務分離を明示

#### ⑤ CHANGELOG.md v2.6.2 セクション

8. `CHANGELOG.md` の `[2.6.2]` セクションに本 Unit の「規約改訂」項目を追加:
    - `### Changed` 配下に CLAUDE.md / SKILL.md / docs 改訂 1 項目
    - Issue #697 / 関連 #688 参照
    - Unit 番号（Unit 006）と PR 番号は確定後追記

#### ⑥ AGENTS.md 新規作成（MUST）

9. **MUST**: 最小 `AGENTS.md` をリポジトリルートに新規作成し、CLAUDE.md ① セクションへの単純な参照リンクを配置する。Unit 定義「責務」が CLAUDE.md / AGENTS.md / 関連 SKILL.md への追記を明示しており、Issue #697 受け入れ基準「案 A（CLAUDE.md / AGENTS.md / SKILL.md の規約改訂）」とも整合する。

    **AGENTS.md 最小構成例**:

    ```markdown
    # AGENTS.md

    本リポジトリで活動する AI エージェント（Codex CLI / Gemini CLI 等の AGENTS.md 参照 AI、および Claude Code）共通の規約。

    ## Bash ツール経由の安全パターン

    詳細は `CLAUDE.md` の「AI エージェント Bash ツール経由の安全パターン」セクションを参照。

    要点: コマンド置換（`$(...)` および backtick `` ` ``）を含む文字列を Bash ツールの引数として直接渡さない。長文プロンプトは file-based interface（`--content-file` / `--body-file` 等）または Write ツールで一時ファイル経由とする。
    ```

    将来 AGENTS.md 固有の規約が必要になった際は、本 Unit で作成した最小骨格に追記する形で拡張する（CLAUDE.md との重複防止）。

### 含まれないもの

- **強制ブロック実装**: PreToolUse hook での backtick / `$(...)` 検出 + ブロックは技術的制約（hook が許可ダイアログ後に実行される）のため対象外
- **`skills/aidlc/scripts/lib/version.sh` 等のスクリプト本体変更**: v2.6.1 Unit 001 で個別解決済。再オープンしない
- **`--content` 引数の廃止**: 既存ユーザーの互換性維持のため API 削除なし。「AI エージェント向け推奨経路から除外」する文書改訂のみ
- **#688 自体の再オープン**: 注意書き一般化のみ実施し、Issue は CLOSED のまま
- **個人グローバル `~/.claude/CLAUDE.md` の改訂提案**: ユーザー個人設定への介入はしない。リポジトリ規約の整備でカバー
- **markdownlint-cli2 / shellcheck の設定変更**: 既存 lint 設定で改訂後ファイルが通ることを確認するのみ
- **`codex exec` / `claude -p` 等の外部 CLI wrapper script 新規作成**: ドキュメントとしての推奨記述のみ。wrapper script 実体の追加は別 Unit / 別 Issue で検討

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] リポジトリ内 `CLAUDE.md` に「AI エージェント Bash ツール経由の安全パターン」セクションが追加され、コマンド置換全般（`$(...)` および backtick）禁止と対象範囲（全 Bash ツール呼び出し引数文字列）が明文化されている
- [ ] `CLAUDE.md` に AI エージェント向け Bash ツール経由 long-text 渡し時の安全パターン（第一推奨 / 第二推奨 / 禁止）が追記されている
- [ ] `CLAUDE.md` に「file-based 経路 vs 直接引数経路」の参考表（履歴記録 / PR 本文 / PR Ready / 外部 CLI レビュー の 4 行以上）が記載されている
- [ ] `skills/write-history/SKILL.md` で `--content-file` / file-based 経路が AI 第一推奨として明示されている
- [ ] `skills/aidlc/SKILL.md` の `/aidlc v` 経路の zsh OOM 注意書きが、Phase 1 で確定した案（a / b）に従って一般化されている
- [ ] 案 b 採用時: `steps/common/` 配下に zsh OOM 回避共通ガイドが新設され、`skills/aidlc/SKILL.md` がこれを参照している
- [ ] 案 a 採用時: `skills/aidlc/SKILL.md` 内で注意書きが一般化されている
- [ ] `skills/aidlc/steps/common/commit-flow.md` / `review-flow.md` に CLAUDE.md 新規セクションへのクロスリファレンスが追記されている
- [ ] `CHANGELOG.md` v2.6.2 セクションに本 Unit の「規約改訂」項目が追加されている
- [ ] `AGENTS.md` がリポジトリルートに新規作成され、CLAUDE.md ① セクションへの参照リンクが配置されている

### Issue #697 受け入れ基準

- [ ] 案 A（CLAUDE.md / AGENTS.md / SKILL.md の規約改訂）が実施されている
- [ ] 案 B（主要スクリプトの long-text interface 推奨化）が SKILL.md 表現の更新として実施されている（既存仕様の表現更新のみ、API 変更なし）
- [ ] **案 B 充足定義**: `skills/write-history/SKILL.md` を MUST 更新（`--content-file` 第一推奨明示）し、他経路（`gh pr` / `operations-release.sh` / `codex exec` / `claude -p` 等）は CLAUDE.md ① セクションの参考表で網羅する。個別 SKILL.md / docs への直接改訂は本 Unit では行わない
- [ ] 案 C（各種ドキュメント / 関連プロセスへの横展開）が `commit-flow.md` / `review-flow.md` 等で実施されている

### Intent 制約適合

- [ ] スクリプト本体動作・引数仕様は無変更（後方互換性完全維持）
- [ ] ドッグフーディング特殊処理（自リポジトリ判定）は混入していない（規約改訂内容は consumer プロジェクトの AI エージェント運用にも自然に適用される）
- [ ] 改訂後の CLAUDE.md / SKILL.md / docs が markdownlint-cli2 を通過する
- [ ] 改訂ファイルが shellcheck / shellharden（該当する場合）を通過する

### AI レビュー

- [ ] 設計レビュー（codex / `reviewing-construction-design` スキル）が実施されている
- [ ] コードレビュー（codex / `reviewing-construction-code` スキル）が実施されている
- [ ] 統合レビュー（codex / `reviewing-construction-integration` スキル）が実施されている

## 実装方針

### Phase 1（設計）

1. **対象ファイル実態調査**: 改訂対象 7 ファイル（CLAUDE.md / `AGENTS.md`（新規作成対象 / 現状不在を確認）/ `skills/aidlc/SKILL.md` / `skills/write-history/SKILL.md` / `commit-flow.md` / `review-flow.md` / CHANGELOG.md）の現状を読み込み、改訂箇所と差分構造を特定
2. **ドメインモデル**: 「規約改訂対象」「クロスリファレンス先」「AI 推奨経路」「禁止パターン」の論理単位を整理
3. **論理設計**: 各ファイルの改訂差分（追加セクション / 変更行 / 削除行）を仕様化。設計成果物として `design-artifacts/domain-models/unit_006_ai_prompt_zsh_oom_prevention_domain_model.md` と `design-artifacts/logical-designs/unit_006_ai_prompt_zsh_oom_prevention_logical_design.md` を作成
4. **判断ポイント**:
    - SKILL.md 注意書き一般化の **案 a / 案 b** どちらを採用するか（上記「案 a / b 選定基準」の 4 基準で確定）
    - AGENTS.md の取扱: **新規作成は MUST**（最小骨格 + CLAUDE.md 参照リンク）。設計レビューでは最終的な文言と配置を確認する

### Phase 2（実装）

5. CLAUDE.md 改訂（① セクション追加）
6. `skills/aidlc/SKILL.md` 改訂（② 注意書き一般化）
7. `skills/write-history/SKILL.md` 改訂（③ `--content-file` 推奨明示）
8. `commit-flow.md` / `review-flow.md` クロスリファレンス追加（④）
9. CHANGELOG.md v2.6.2 セクション追記（⑤）
10. AGENTS.md 新規作成（⑥ 最小骨格 + CLAUDE.md 参照リンク / 設計レビューでは文言微調整のみ）
11. markdownlint-cli2 / shellcheck 実行
12. 各 AI レビュー（コード / 統合）

### Phase 3（完了）

13. 完了条件チェック / 設計・実装整合性チェック
14. Unit 定義状態更新 → 完了
15. 履歴記録（`construction_unit06.md`）
16. squash / commit
17. コンテキストリセット提示

## リスク・注意点

- **CLAUDE.md セクション追加の影響範囲**: リポジトリ内 CLAUDE.md は consumer プロジェクトにも配布される baseline 規約。consumer 側の AI エージェント運用に影響するため、文言は普遍的（Claude Code 固有でなく Codex CLI 等にも適用可能）に保つ
- **個人グローバル `~/.claude/CLAUDE.md` との重複懸念**: ユーザーが個人設定で既に類似規約を持っている場合、内容の重複・矛盾が起きないよう、リポジトリ版は「Bash ツール経由」という観点で配布物として独立した規約セットにする
- **既存規約箇所のリンク切れ**: `commit-flow.md` / `review-flow.md` 既存 backtick 関連記述との整合性を確認し、責務分離を明確化
- **markdownlint-cli2 / shellcheck の lint 違反**: 改訂後ファイルが既存 lint 設定を通過することを Phase 2 で確認

## 見積もり

0.5 日（Unit 定義通り）。規約 / SKILL.md / docs 改訂中心、コード変更なし。設計レビュー / コードレビュー / 統合レビューの 3 ラウンドが見積もりの中心。

## 関連参照

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/006-ai-prompt-zsh-oom-prevention.md`
- Issue: #697 / 関連 CLOSED: #688
- v2.6.1 Unit 001 PR: `/aidlc v` 経路の CLI モード化
- 個人グローバル CLAUDE.md（参考）: `~/.claude/CLAUDE.md` の「コマンド実行ルール § シェルコマンド置換 `$(...)` の絶対禁止」
