# ユーザーストーリー

## Epic: v2.6.2 patch リリース - v2.6.0 関連調整（バグ修正 + defer 完成）

v2.6.0 で実施した3領域（**振り返りフロー独立化** / **marketplace.json への version SoT 一本化** / **GitHub Projects 移行**）の defer 完成と、**振り返り分離・Operations フロー周辺で表面化した致命的バグ** を patch リリースで一括解消し、v2.6 系の運用基盤を「機能完成版」に固定する。

---

## DoD（Epic 共通の運用チェックリスト）

各ストーリーの受け入れ基準（AC）は振る舞い・出力・ログ・テストで定義する。以下の運用観点は AC ではなく Epic 共通の DoD（Definition of Done）として扱い、Operations Phase の完了処理で確認する:

- 関連 Issue（#677 / #678 / #680 / #682 / #683）が PR マージ後に close されること
- v2.6.2 Milestone に上記 5 Issue がすべて紐付いていること
- CHANGELOG.md に v2.6.2 セクションが追加され、全 5 ストーリーの変更が patch 扱いで記載されていること
- Repository Settings > Branch protection / Ruleset の現行 required check 一覧（`.aidlc/cycles/v2.6.2/operations/required-checks.md` スナップショット）が CI で全件 green であること

## ストーリー間依存マトリクス

5 ストーリー間の依存関係を以下に明示する。Construction Phase の Unit 実行順序判断および AI レビュー時の整合性検証に使用する:

| ストーリー | 依存先 | 依存理由 / 順序前提 |
|----------|--------|------------------|
| ストーリー 1（#677 squash-712 / write-history 整合）| なし | Operations フロー独立。他 4 件の前後どちらでも実装可 |
| ストーリー 2（#678 pr-ready 空 body 検証）| なし | Operations フロー独立。他 4 件の前後どちらでも実装可 |
| ストーリー 3（#680 migrate トラバーサル検証）| なし | aidlc-migrate スコープに閉じる。他 4 件と独立 |
| ストーリー 4（#682 ensure-fields options 差分同期）| なし（前提のみ）| GitHub Projects スクリプト本体は v2.6.0 Unit 006 で整備済み。本ストーリーは options 差分のみを追加する |
| ストーリー 5（#683 副作用 bats テスト整備）| **ストーリー 4 を先に完了することを推奨**（同一サイクル内では順序前提）| Phase 2 で `setup-github-project.sh` / `gh-project-cli.sh` のテスト網羅性を上げる際、ストーリー 4 で追加された `ensure-fields` options 差分同期ロジックのテストも合わせて担保するのが効率的。順序前提が崩れた場合は Phase 2 完了時点で options 差分同期テストを追加する形で吸収する |

ストーリー 1〜3 は完全独立、ストーリー 4 → ストーリー 5 のソフト順序のみ存在する（厳密な実装ブロッカーではない）。Construction Phase で `unit_branch_enabled=false` の現設定下では順次実装となる。

**Unit ファイル番号と実装順序の対応**（`story-artifacts/units/` 配下）:

| Unit 番号 | Issue | 概要 | 順序前提 |
|----------|-------|------|---------|
| 001 | #678 | pr-ready 空 body 検証 | なし |
| 002 | #680 | aidlc-migrate トラバーサル検証 | なし |
| 003 | #677 | squash-712 / write-history 整合 | なし |
| 004 | #682 | gh-project-cli options 差分同期 | なし（Unit 005 の前提） |
| 005 | #683 | gh-project 副作用 bats テスト整備 | Unit 004 の後を推奨 |

**推奨実装順序**: 001 → 002 → 003 → 004 → 005（001〜003 の相互順序は任意、004 → 005 のソフト順序のみ守る）。順序前提が崩れた場合の吸収方法は各 Unit 定義ファイルに記載。

**順次実行時の合算工数レンジ**:

| Unit | 単体見積もり | 累積（順次実行） |
|------|------------|----------------|
| 001（pr-ready 空 body 検証） | 0.5〜1 日 | 0.5〜1 日 |
| 002（migrate トラバーサル検証） | 1〜1.5 日 | 1.5〜2.5 日 |
| 003（squash-712 / write-history 整合） | 1〜2 日 | 2.5〜4.5 日 |
| 004（gh-project options 差分同期） | 0.5〜1 日 | 3〜5.5 日 |
| 005（gh-project bats テスト整備） | 2〜3 日 | 5〜8.5 日 |

合算 **5〜8.5 日**（patch サイクル想定の短期完了レンジ）。`unit_branch_enabled=false` のため Construction Phase は順次実行となる。

**遅延時の圧縮方針**:

通常時の Done 条件は **「Intent スコープ確認の 5 Issue（#677 / #678 / #680 / #682 / #683）すべて完遂」** であり、この条件を崩す圧縮（Issue defer / Unit 分離）は **Intent 改訂と再承認（automation_mode 関わらずユーザー確認必須）** を経て初めて実施可能。短期完了（5 日想定）に収まらないリスクが顕在化した場合、以下の順で検討する:

1. **Unit 003 採用案の縮退（Intent 改訂不要）**: A+B 併用想定なら案 A 単独 / 案 B 単独に縮退する。これは Intent §成功基準 #677 の「案 A / B のいずれか必須」の枠内であり、スコープ縮退には該当しない（Construction 設計レビューで判断）
2. **Unit 005 Phase 2 の段階完了 + 後半 defer（Intent 改訂・再承認が必須）**: 4 スクリプトを 2 グループ（setup + migrate / probe + audit）に分けて段階完了し、後グループを別 Issue で defer。**実施するには Intent §スコープ確認 §成功基準を改訂し、ユーザー再承認を得ること**
3. **Unit 004 を別 patch（v2.6.3）に分離（Intent 改訂・再承認が必須）**: Unit 005 Phase 1 のモック基盤整備のみ本サイクルで実施し、options 差分同期実装は別 patch に分離。**実施するには Intent §スコープ確認 §成功基準を改訂し、ユーザー再承認を得ること**

優先度 high の Unit 001 / 002 / 003（バグ修正・security）は本サイクルの最低必達範囲とし、これらの Issue defer / 分離は本サイクルでは認めない（patch リリースの存在意義が失われるため）。

---

## リリース系タスクの責務分担（Construction / Operations 境界の明示）

Intent「含まれるもの」のうち Issue 直結タスクは Unit 001〜005 で担当する。一方、以下のリリース系タスクは **個別 Unit ではなく Operations Phase で実施する** Epic 共通タスクとして扱う:

| リリース系タスク | 担当フェーズ | 担当ステップ |
|----------------|-----------|------------|
| `bin/update-version.sh --version v2.6.2` 実行（version 更新） | Operations Phase | リリース準備 §7.1 後 |
| CHANGELOG.md v2.6.2 セクション追記 | Operations Phase | リリース準備 §7.2 |
| Milestone v2.6.2 作成・Issue 紐付け（早期紐付けは Inception §16 で試行済 / defer-to-05-completion） | Operations Phase | 完了処理 |
| draft PR 作成・PR レビュー反映・マージ | Operations Phase | リリース準備〜完了処理 |
| Branch protection / Ruleset 現行 required check 一覧スナップショット（`operations/required-checks.md`） | Operations Phase | デプロイ準備 §7 序盤 |
| post-merge-sync（main 同期 + マージ済みブランチ削除） | Operations Phase | ポストマージクリーンアップ |

---

### ストーリー 1: Operations §7.12.5 squash-712 と write-history operations-round の不整合解消

**優先順位**: Must-have（致命的バグ / 振り返り分離関連）

As a AI-DLC Starter Kit を利用して Operations Phase でリリース PR をレビュー反映する開発者
I want to `§7.12 PR レビュー反映 → §7.12.5 squash-712 統合 → push` の流れで `history/operations.md` の追記内容が squash 統合 commit に確実に取り込まれるか、unstaged 差分を伴う squash-712 実行が fail-fast で検出される
So that レビュー反映 commit と履歴 commit が分離して main に細粒度 commit が残る事態を防ぎ、`git push --force-with-lease` を伴う手動回復手順から解放される

**AC 採用ルール**:

本ストーリーは Construction 設計レビューで案 A / 案 B / A+B のいずれかを採用案として確定する。**確定後、非採用案専用 AC は対象外として除外し、残った AC（共通 AC + 採用案専用 AC）の全項目を Done 条件とする**。AC 分離は INVEST の Estimable / Testable を担保するための構造化であり、Inception 時点で全 AC が同時に達成される必要はない。

**共通 AC（採用案に関わらず必須）**:

- [ ] `§7.12` codex review 完了 → `write-history.sh --mode operations-round` 実行 → `§7.12.5 squash-712` 実行の標準フローを通過した結果、main にマージ可能な commit 構成が「Operations Phase 完了 commit + squash 統合 commit」の **2 commit 構成（レビュー反映 = 1 squash commit）** で完結する。3 commit 構成（squash の後に分離した history commit）は発生しない
- [ ] `git push --force-with-lease` を伴う手動回復手順なしで、上記 2 commit 構成が達成できる
- [ ] 共通 AC を担保する integration テスト（`§7.12 → write-history → squash-712 → git log` で 1 squash commit を確認）が `skills/aidlc/scripts/tests/` に追加される
- [ ] CHANGELOG に採用案と利用者への影響（auto-commit 化なら opt-out 手順）が patch 扱いで記載される

**案 A 専用 AC（write-history auto-commit 化を採用した場合のみ）**:

- [ ] `write-history.sh --mode operations-round` 実行で `history/operations.md` の追記が自動的に staged + commit され、続く `squash-712` で `git reset --soft + git commit` が当該 commit を取り込んで 1 つの squash 統合 commit にまとめる
- [ ] opt-out フラグ（例: `--no-commit`）が用意され、従来動作（append のみ / 自動 commit なし）が完全に再現できる
- [ ] case A 採用時に `squash-712` を「`history/operations.md` が clean な状態」で起動した場合は **従来通り正常完了する**（dirty 検出による fail は導入されない、案 B との重複導入を避ける）。dirty 状態は実行前に write-history auto-commit 経由でクリアされる前提
- [ ] **案 A 単独採用時の dirty 判定ポリシー**: `history/operations.md` 以外のファイル（unrelated file）の dirty 状態は **すべて許容して通常完了する**（squash-712 の従来挙動を維持）。案 A は history 系の auto-commit 化のみを担保し、他ファイルの dirty 検出は案 B 採用時のみ担当する。bats テストで「`history/operations.md` clean かつ `README.md` 等の unrelated file が dirty」シナリオで案 A 単独構成の `squash-712` が exit 0 で正常完了することを検証する
- [ ] auto-commit 失敗時（pre-commit hook fail 等）は append 自体はロールバックせず、stderr に commit 失敗を明示し exit 非 0（履歴データの損失を防ぐ）
- [ ] bats テストで「`write-history --mode operations-round` 実行後の `git status --porcelain` 出力がクリーン」「`--no-commit` フラグ付与時の従来等価動作」「auto-commit 失敗時の append 保持と exit 非 0」を検証する

**案 B 専用 AC（squash-712 fail-fast 化を採用した場合のみ）**:

- [ ] `squash-712` 起動時に `git status --porcelain` で `history/operations.md` 等の unstaged / staged 差分を検出した場合、exit 1 で停止し stderr に `error\tsquash-712:uncommitted-history\t<files>` および「先に `git add + git commit` してから再実行してください」案内を出力する
- [ ] dirty 判定対象ファイルパターンが定義され（少なくとも `history/operations.md`、必要に応じて他 history 系ファイル）、検出時の対象ファイル一覧が stderr に出力される
- [ ] 検証回避用フラグ（例: `--allow-dirty-history`）の有無は Construction 設計レビューで判断（必要時のみ追加）
- [ ] bats テストで「dirty 状態での `squash-712` 起動が exit 1 + 期待 stderr」「clean 状態での通常完了」「対象外ファイル（dirty だが history 系でない）の場合は通常完了」を検証する

**A+B 併用採用時の追加 AC**:

- [ ] write-history が auto-commit を試みた後、何らかの理由（auto-commit が opt-out された等）で `history/operations.md` が dirty なまま `squash-712` が起動された場合、案 B の fail-fast が発動し利用者を保護する（多層防御）

**技術的考慮事項**:

- Issue #677 案 A / 案 B / A+B 併用のいずれを採用するかは Construction Phase 設計レビューで確定（**案 C「手順書 SoT 明示化のみ」は単独採用不可、A/B に対する補助併用のみ可**）
- 案 A 採用時は `write-history.sh` の構造に `--no-commit` オプション追加が必要。construction phase / inception phase の append とは責務切り分けが必要（operations-round 限定で auto-commit）

---

### ストーリー 2: `pr-ready --body-file` の空ファイル検証で PR 本文 null 上書き事故を防止

**優先順位**: Must-have（致命的バグ）

As a AI-DLC Starter Kit を利用して Operations Phase で PR 本文を更新する開発者・AI エージェント
I want to `operations-release.sh pr-ready --body-file <path>` および内部 `gh pr edit --body-file` / REST PATCH fallback が、0 バイトファイル / 不在ファイルを実行前に検出して停止する
So that AI エージェントが `mktemp` 経由で生成した 0 バイト一時ファイルを誤って渡しても PR 本文が `null` で上書きされる事故が発生しない

**受け入れ基準（正常系）**:

- [ ] `operations-release.sh pr-ready --body-file <path>` で `<path>` が 0 バイトの場合、exit 1 で停止し stderr に `error\tpr-ready:body-file-empty\t<path>` および「本文が空です。--body-file の中身を確認してから再実行してください」案内が出力される
- [ ] `<path>` が存在しない場合、exit 1 で停止し stderr に `error\tpr-ready:body-file-missing\t<path>` が出力される
- [ ] REST PATCH fallback 経路（`pr-ready:fallback:rest-patch`）でも上記 2 条件を再検証し、空ファイル / 不在を検出して停止する（二重防御）
- [ ] 本文ありの正常な `--body-file <path>` 経路は従来通り動作し、`gh pr edit --body-file` / REST PATCH のいずれの経路でも PR 本文が正しく更新される

**受け入れ基準（異常系）**:

- [ ] 空ファイルでの実行が exit 1 になることで、`gh pr edit` / REST PATCH リクエスト自体が送信されない（`null` 上書きの根本予防）
- [ ] 検証エラー時のメッセージが、AI エージェントが自動再試行ロジックに組み込めるよう機械可読な tab 区切り形式（`error\t<error_code>\t<context>`）である

**受け入れ基準（テスト）**:

- [ ] bats テストで「0 バイトファイル / 不在ファイル / 通常ファイル」3 ケースの exit code と stderr 出力を検証する
- [ ] REST PATCH fallback 経路でも同等の検証ロジックが動作することを確認するテストケースが追加される

**技術的考慮事項**:

- Issue #678 案 A（pr-ready 側 body-file 0 バイト / 不在検証）+ 案 B（REST PATCH fallback 経路の二重防御）を **本サイクル必須** とし、案 C（テンプレ生成 helper 追加）は本サイクル対象外（別 Issue defer）
- 「極端に短い本文（warning）」は本サイクル対象外。判定対象は **0 バイトおよびファイル不在のみ**
- 既存の AI 運用が暗黙的に `mktemp` 経由で空ファイルを渡していた場合、本変更により exit 1 で停止する。これは本来エラー検出すべき経路であり、CHANGELOG で破壊変更ではなく品質改善として案内する

---

### ストーリー 3: aidlc-migrate manifest 由来パスのトラバーサル検証

**優先順位**: Must-have（security:high / 振り返り分離（aidlc-migrate）周辺）

As a 信頼できない fork やサードパーティ経由で AI-DLC Starter Kit を取得する利用者
I want to `aidlc-migrate` 実行時に manifest 由来の `path` / `dest` が `AIDLC_PROJECT_ROOT` 配下に収まることが検証される
So that 細工された manifest により `/etc/cron.d/evil` 等のリポジトリ外システムファイルが書き換えられるトラバーサル攻撃から保護される

**受け入れ基準（正常系）**:

- [ ] `migrate-apply-config.sh::_apply_resource()` 系で manifest 由来の `path` / `dest` が `AIDLC_PROJECT_ROOT` からの相対パスで、かつ `realpath -m` 解決後に `AIDLC_PROJECT_ROOT` 配下に収まる場合のみ処理が継続される
- [ ] `cp` / `rm` / `mkdir -p` / `mv` 各リソース種別の処理パスで一貫してトラバーサル検証が行われる（漏れなく適用）
- [ ] 既存の正常な manifest（v2.6.x までの apply.json）が変更なしで動作する（後方互換）

**受け入れ基準（異常系 - トラバーサル攻撃ケース）**:

すべての拒否ケースで **exit code は固定で `2`** とし、stderr フォーマットは tab 区切り 4 フィールド固定 `error\tmigrate-apply:path-traversal\t<offending_path>\treason=<reason_code>`（末尾改行 1）で出力する。`<reason_code>` は以下の集合から 1 つ:

| ケース | `<reason_code>` |
|------|----------------|
| `path` / `dest` が `/` で始まる絶対パス | `absolute-path` |
| `path` / `dest` に `..` セグメントを含む | `parent-traversal` |
| `realpath -m` 解決後に `AIDLC_PROJECT_ROOT` 配下に収まらない | `outside-root` |
| シンボリックリンク経由で配下から脱出（物理パス解決で配下外） | `outside-root`（物理パス解決後の判定に集約、`realpath` の `-P` / 物理パス解決相当を使用） |

- [ ] 絶対パスケース: exit 2 + stderr フォーマット完全一致（`reason=absolute-path`）
- [ ] `..` 含有ケース: exit 2 + stderr フォーマット完全一致（`reason=parent-traversal`）
- [ ] `realpath` 解決後配下外ケース: exit 2 + stderr フォーマット完全一致（`reason=outside-root`）
- [ ] シンボリックリンク経由のトラバーサル: exit 2 + stderr フォーマット完全一致（`reason=outside-root`、物理パス解決により検出）
- [ ] 同一 manifest 内に複数の不正パスが混在する場合、最初に検出した不正パスで停止し対応する `<offending_path>` / `<reason_code>` を出力する（fail-fast / exit 2）

**受け入れ基準（テスト）**:

- [ ] bats テストでトラバーサル攻撃 4 ケース（絶対パス / `..` 含有 / `realpath` 解決後配下外 / シンボリックリンク経由）の exit code と stderr 出力を検証する
- [ ] cross-platform テスト: macOS BSD `realpath` 環境と GNU `realpath -m` 環境の両方で同じ判定結果になることを確認する

**技術的考慮事項**:

- Issue #680 推奨対応: `realpath` で manifest 由来の `path` / `dest` が `AIDLC_PROJECT_ROOT` 配下にあることを検証
- macOS BSD `realpath`（古い macOS では `-m` / `--strict` 不在）と GNU `realpath` の挙動差を吸収する shim を `bin/lib/` 配下に新設するか、`realpath -m` の存在確認 + フォールバック実装する（採用方針は Construction 設計レビューで確定）
- 信頼境界の前提（公式リポジトリ経由では発火しない）も合わせて `aidlc-migrate` SKILL.md / docs に記述する

---

### ストーリー 4: gh-project-cli ensure-fields の field options 差分同期

**優先順位**: Should-have（v2.6.0 Unit 006 R1 defer-from-review）

As a AI-DLC Starter Kit のメタ開発者として GitHub Projects の spec.yaml を改訂する開発者
I want to `bin/gh-project-cli.sh ensure-fields` を再実行した際に、spec.yaml に追加された field options が既存 field に差分追加される
So that Status / Priority / Cycle 等のフィールド options を spec.yaml で管理し、再実行で冪等に同期できる（v2.6.0 Unit 006 設計の「冪等性」要件を完成させる）

**受け入れ基準（正常系）**:

- [ ] `bin/gh-project-cli.sh ensure-fields --spec <path>` で既存 field（`field:exists` 分岐）に対して、spec 側 `fields[*].options` と既存 field options の差分（追加すべき option name）を計算し、`bin/lib/gh-project-repo.sh::gh_project_repo_add_field_option` で順次追加する
- [ ] 既存 options に存在する option は再追加しない（冪等性）
- [ ] field 自体が存在しない場合の `field:create` 経路は従来通り動作する（変更なし）
- [ ] 同期処理の出力に追加した option 名と件数が含まれる（`field:<name>:options-added:<count>:names=<n1>,<n2>,...` 等）

**受け入れ基準（異常系・モード対応）**:

- [ ] `--dry-run` モード: 差分を計算して「追加予定 option 名と件数」を出力し、実際の `add_field_option` API 呼び出しはしない
- [ ] `--strict` モード: spec 側にない既存 option を検出した場合 exit 非 0（予期しない options が残っている状態を fail とする）
- [ ] `--soft` モード: API 呼び出し失敗を warn 扱いで継続する（既存挙動踏襲）

**受け入れ基準（テスト）**:

- [ ] bats テストで「options 追加なし / 1 件追加 / 複数件追加 / 全件既存（no-op）」の 4 シナリオの差分同期動作を検証する
- [ ] dry-run / strict / soft モードの差を検証するテストが追加される

**技術的考慮事項**:

- Issue #682 推奨対応: `_subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期ロジックを追加
- GitHub Projects API の option 順序は不定。spec.yaml 順序通りに追加される保証はないため、テストは「集合として一致」で判定する
- 関連設計: `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md` §gh-project-repo.sh

---

### ストーリー 5: Unit 006 副作用 bats テスト整備（gh API モックフレームワーク）

**優先順位**: Should-have（v2.6.0 Unit 006 R1 defer-from-review）

As a AI-DLC Starter Kit のメタ開発者として GitHub Projects 関連スクリプトを保守する開発者
I want to `setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh` の本体動作（副作用）が gh API モック環境で bats テストされている
So that 実際の GitHub API 呼び出しなしで CI 上で副作用ロジックの正常系・異常系を検証でき、v2.6.0 Unit 006 計画書のテスト整備約束を完成できる

**段階完了条件（Phase 分割）**:

本ストーリーは規模上、以下 2 Phase の段階完了条件で進める。Construction Phase の Unit 内部で Phase 1 完了 → Phase 2 着手の順序を守る:

| Phase | 内容 | 完了条件（Phase 完了マーカー） |
|------|------|----------------------------|
| Phase 1 | gh API モック基盤整備 | モックヘルパー（`bin/tests/gh-project/_helpers.bash` 等）が `setup-github-project.sh.bats` 1 本で動作確認できる最小スイートで pass。`gh` モック対象 API（list / create / field-list / item-add / item-list / item-edit）の擬装が機能する |
| Phase 2 | 4 スクリプトの副作用テスト追加 | 4 つの bats ファイル（setup / migrate / probe / audit）のすべてが Phase 1 で整備されたモック基盤上で pass。既存 28 件と並存し全件 green |

**受け入れ基準（Phase 1: モック基盤）**:

- [ ] `bin/tests/gh-project/_helpers.bash`（または等価ファイル）に gh API モックヘルパーが新設され、以下の API を fixture JSON で擬装できる:
   - `gh project list`
   - `gh project create`
   - `gh project field-list`
   - `gh project item-add`
   - `gh project item-list`
   - `gh project item-edit`（必要に応じて）
- [ ] モックヘルパーが `setup-github-project.sh.bats`（最小スイート）から呼び出せ、想定外引数で fail することが確認できる

**受け入れ基準（Phase 2: 4 スクリプト副作用テスト）**:

- [ ] `setup-github-project.sh.bats`: 全 subcommand orchestrator（init / create / link 等）の正常系・異常系を網羅
- [ ] `migrate-issue-524.bats`: dry-run 時の diff 出力 / バックアップ作成 / strict 時の scope 検証を網羅
- [ ] `probe-github-project.bats`: dry-run の evidence JSON 構造 / sandbox 失敗時の cleanup / strict 時の scope 検証を網羅
- [ ] `audit-github-project.bats`: SLA 判定（within_sla / sla_exceeded / unknown）の 3 ケース + probe-evidence 不在時の exit 5 を網羅
- [ ] 既存 28 件の引数 / エラー系テストと並存し、`make test` 相当で全件 pass する

**受け入れ基準（異常系）**:

- [ ] gh API モックが想定外の引数で呼び出された場合、テストヘルパーが明示的に fail し、未モック API の検出が可能
- [ ] fixture JSON の構造不一致（GitHub API レスポンスの仕様変更想定）が発生した場合、bats テストが fail し検出される

**受け入れ基準（テスト範囲の境界）**:

- [ ] 本ストーリーで追加するモック対象 API は v2.6.0 Unit 006 計画書記載の 4 スクリプトが必要とする最小限に限定し、`gh` 全 API のフルモックは構築しない（YAGNI / Intent 制約事項に明示）
- [ ] 必要に応じた拡張は別 Issue で defer する

**技術的考慮事項**:

- Issue #683 推奨対応: モックフレームワーク整備 + 4 スクリプトの副作用テスト追加
- 関連設計: `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md` §テスト整備
- `gh` / `dasel` モックの実装方針（PATH override / function override / wrapper script）は Construction 設計レビューで確定する
