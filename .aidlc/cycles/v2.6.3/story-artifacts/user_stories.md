# ユーザーストーリー

## Epic: v2.6.3 patch — 規約 SoT・AI 実行再現性・セキュリティ・保守性の底上げ

v2.6.2 サイクルの振り返り・Codex レビュー指摘・実運用フィードバック由来の 7 件のバックログ Issue を解決する。各ストーリーは 1 つの Issue に対応する。

---

### ストーリー 1: result-out 関数の local 命名規約整備と path-guard.sh の予防的リファクタ
**優先順位**: Must-have
**関連 Issue**: #706

As a AI-DLC スターターキットのメンテナ
I want to `printf -v "$result_var"` パターンを使う result-out 関数の local 命名規約を規約 SoT に明文化し、`path-guard.sh` の既存 result-out 関数群を namespace 統一する
So that bash dynamic scope shadowing による「caller の変数が空のまま残る」致命的バグ（v2.6.2 で CI を停止させた da212aea の原因）の再発を構造的に防げる

**受け入れ基準**:
- [ ] `CLAUDE.md` の「AI エージェント Bash ツール経由の安全パターン」セクション、または `skills/aidlc/steps/common/bash-tool-safety.md` のいずれか（SoT 側）に「`printf -v` 系 result-out 関数の local 命名規約」セクションが追加されている
- [ ] 追加された規約セクションは「関数引数で結果書き込み先変数名を受け取る関数の内部 local は関数固有プレフィックス（例: `_local_<func_shorthand>_<name>`）で namespace 化する」旨と、namespace 化しない場合の dynamic scope shadowing バグの説明を含む
- [ ] `skills/aidlc-migrate/scripts/lib/path-guard.sh` の result-out 関数（`_aidlc_migrate_realpath` / `_aidlc_migrate_path_guard_init` / `_aidlc_migrate_validate_path` を含む全 result-out 関数）の内部 local が `_local_<関数省略名>_<名>` 形式で namespace 統一されている
- [ ] 上記関数の docstring に「result-out 関数のため内部 local は namespace 化必須」のメモが追加されている
- [ ] `path-guard.sh` の外部公開関数のシグネチャ（引数の数・順序・意味）は変更されていない
- [ ] `tests/migration` の既存 bats 49 件が引き続き全 pass する
- [ ] markdownlint で新規エラー 0 件

**技術的考慮事項**:
- 規約本文は単一の SoT（CLAUDE.md または bash-tool-safety.md）に置き、他ドキュメントは参照に留める（配布物 baseline 規約の重複回避）
- shellcheck SC2030/SC2031 はこの dynamic scope shadowing を捕捉しないため、規約による予防が主防御線
- `CLAUDE.md` を編集する場合の追記先は「AI エージェント Bash ツール経由の安全パターン」セクション内の新規サブセクションであり、ストーリー2（#703）の追記先（Codex 連携記述）とは相互に分離している

---

### ストーリー 2: codex exec の `</dev/null` 必須運用の明文化
**優先順位**: Must-have
**関連 Issue**: #703

As a AI-DLC レビューフローを実行する AI エージェント
I want to 非対話 subprocess 環境で `codex exec` / `codex exec resume` を呼ぶ際に `</dev/null` で stdin を閉じる運用が SoT に明文化されている
So that stdin EOF 待ちによるハング（タイムアウト）を起こさず、セルフレビューへの無自覚な降格を防げる

**受け入れ基準**:
- [ ] `skills/aidlc/steps/common/` 配下の reviewing-common-base（正本）の `codex exec` 実行コマンド例に `</dev/null` が追加されている
- [ ] セッション継続版（`codex exec resume`）のコマンド例にも `</dev/null` が追加されている
- [ ] reviewing-common-base（正本）に「非対話 subprocess 環境（Bash tool / hooks / CI 等）で codex を呼ぶ際は `</dev/null` 必須」を説明するセクションが新設されている
- [ ] 正本の変更が同期コピー（reviewing-* スキル配下のコピー）に伝播し、CI の同期 verify が pass する
- [ ] `CLAUDE.md` / `AGENTS.md` の該当箇所に「`codex exec` / `codex exec resume` は `</dev/null` 必須」の横断ルールが追記されている（既存の Codex 連携記述がある場合）
- [ ] reviewing-common-base（正本）内の **全** `codex exec` 系コマンド例（`codex exec` / `codex exec resume` / 他バリアント）を網羅的に確認し、`</dev/null` 追加漏れがないことをレビュー観点として検証している（異常系: 追記漏れの検出）
- [ ] markdownlint で新規エラー 0 件

**技術的考慮事項**:
- reviewing-common-base は正本 1 箇所修正 → 9 コピーへ同期伝播する構造。正本のみ編集し同期スクリプト/CI で伝播・検証する
- `</dev/null` 欠落の自動 lint 検知は docs スコープを超え誤検知リスクが高いため導入しない。正本の網羅確認 + 同期 verify を防御線とする
- `CLAUDE.md` の追記先はストーリー1（#706）の「printf -v 命名規約」サブセクションとは異なる「Codex 連携」記述側であり、編集箇所は相互に分離している

---

### ストーリー 3: operations-release.sh cmd_squash_712 への --cycle バリデーション導入
**優先順位**: Must-have
**関連 Issue**: #701

As a AI-DLC スターターキットのメンテナ（セキュリティ観点）
I want to `operations-release.sh` の `cmd_squash_712` が `--cycle` 引数を `validate_cycle` で包括検証する
So that パストラバーサル文字列を受け取っても `.aidlc/cycles/<cycle>/...` の参照先が想定外パスに逸脱しない

**受け入れ基準**:
- [ ] `cmd_squash_712` 起動時に `--cycle` 引数が `validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）で検証される
- [ ] 不正な `--cycle` 値（パストラバーサル `..` を含む等）の場合、exit 1 で停止し、tab 区切り stderr `error\tsquash-712:invalid-cycle\t<value>` を出力する
- [ ] 正常な `--cycle` 値の場合は従来どおり処理が継続する（既存挙動の回帰なし）
- [ ] `cmd_squash_712` 配下の他の `--cycle` 利用経路（`__operations_release_progress_path` 等）も検証後のパスを参照する
- [ ] 不正 cycle / 正常 cycle の両ケースをカバーする bats テストが追加され pass する

**技術的考慮事項**:
- 既存の `validate_cycle` 実装（`skills/aidlc/scripts/lib/validate.sh`）を再利用する。新規バリデーションロジックは作らない
- 本ストーリーの Done は `cmd_squash_712` の `--cycle` 防御実装 + bats テストに限定する。`record-release-prep-commit` 等の他サブコマンドへの同種検証導入の要否は Unit 定義時に判断し、本サイクルで扱うか別 Issue 化するかを intent.md「分離判定基準」(a)(b)(c) に照らして決定する（意思決定は受け入れ基準ではなく Unit 定義の検討事項として扱う）

---

### ストーリー 4: Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化
**優先順位**: Should-have
**関連 Issue**: #694

As a AI-DLC で Operations Phase を実行する AI エージェント
I want to マージ前の「CI 通過確認 + 失敗時の修復経路」が `steps/operations/` 配下に SoT として明文化されている
So that 各サイクルで属人的に対応していた CI 修復が、サイクル横断で再現可能な手順として実行できる

**受け入れ基準**:
- [ ] `skills/aidlc/steps/operations/` の該当マージ前ステップファイルに「マージ前 CI 通過確認ステップ」が追加され、`gh pr checks <PR>` または `gh run list --branch <branch>` で全 CI ジョブ通過を確認する手順が記載されている
- [ ] CI 失敗時の修復経路が 3 分岐（修復可能 = 修正コミット→再 push→再確認 / 修復不能 = ユーザー承認必須（AskUserQuestion） / 構造的不整合 = サイクル内修正として扱い新規 Issue 化しない）で SoT 化されている
- [ ] マージ前ステップで `check-cycle-phase-completion` を明示的に呼び出すよう SoT 化されている
- [ ] 既存の `reviewing-operations-premerge` スキルとマージ前 CI 通過確認フローの「重複する観点」と「補完関係（どちらがどの責務を持つか）」を明示する記述がステップファイルに含まれている（記載構造の細目は Unit 定義で確定）
- [ ] markdownlint で新規エラー 0 件

**技術的考慮事項**:
- マージ前 CI 通過確認の記述が `operations-release.md` / `03-release.md` 等に分散・粒度不揃いのため、どのステップファイルを SoT とするかを Unit 設計時に確定する

---

### ストーリー 5: /aidlc v 経路の再現性向上
**優先順位**: Should-have
**関連 Issue**: #698

As a AI-DLC の `/aidlc v`（バージョン表示）を実行する AI エージェント
I want to SKILL.md「バージョン表示」節に base dir 解決手順と推測禁止の禁則が明示され、`version.sh` が引数なしで marketplace.json を自己解決する
So that バージョンを内部知識から誤推測したり、marketplace.json のパス組み立てを間違えたりせず、確実に正本バージョンを出力できる

**受け入れ基準**:
- [ ] SKILL.md「バージョン表示」節に「実行前に SKILL.md 冒頭の `Base directory for this skill:` 行を参照して base dir を解決する」旨の一文が追加されている（A 案）
- [ ] SKILL.md「バージョン表示」節に「Bash 呼び出しに失敗 / 不存在の場合のみ `(version unknown)`。内部知識から推測値を出してはならない」旨の禁則が追加されている（A 案）
- [ ] `skills/aidlc/scripts/lib/version.sh` が引数なしの CLI モード呼び出しで、スクリプト自身の位置から marketplace.json を内部解決して動作する（C 案）
- [ ] `version.sh` への marketplace.json パス引数渡しは test override として後方互換で残されている
- [ ] SKILL.md「バージョン表示」節の AI 実行に不要な経緯情報（zsh OOM 経緯 / `read_marketplace_version()` 関数仕様詳細 / Unit・Issue メタ情報）が退避され、本文が圧縮されている
- [ ] SKILL.md 本文が 500 行制限を超えていない
- [ ] `/aidlc v` の既存呼び出し経路で従来と同一のバージョン文字列が出力される（互換維持）
- [ ] markdownlint で新規エラー 0 件

**技術的考慮事項**:
- `bootstrap.sh` が既にスクリプト位置からの相対パス算出ロジックを持つため、`version.sh` の自己解決はそれを参考にできる

---

### ストーリー 6: review-flow.md の MD038 違反 3 件の修正
**優先順位**: Should-have
**関連 Issue**: #705

As a AI-DLC スターターキットのメンテナ
I want to `review-flow.md` の既存 MD038/no-space-in-code 違反 3 件を、規約意図を維持したまま解消する
So that markdownlint が clean pass し、lint エラーが新規変更の検証ノイズにならない

**受け入れ基準**:
- [ ] `skills/aidlc/steps/common/review-flow.md` の MD038/no-space-in-code 違反箇所（コード span 内のカンマ + スペース区切り規約表現、3 件）が修正されている
- [ ] 修正後も「複数パスは backtick で囲み `, ` で区切る」という規約の意図が読者に伝わる記述になっている（案 1: 記法書き換え を優先、案 2: `markdownlint-disable` は最終手段）
- [ ] `review-flow.md` に対して markdownlint を実行し MD038 エラーが 0 件である
- [ ] markdownlint で他の新規エラー 0 件

**技術的考慮事項**:
- 違反の正確な行番号は markdownlint 実行で特定する（Issue では line 121/122/283 と記載されているが改訂後の現行行番号を再確認する）

---

### ストーリー 7: write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化
**優先順位**: Could-have
**関連 Issue**: #702

As a AI-DLC スターターキットのメンテナ
I want to `write-history.sh` の `check_history_staged_status()` と `_commit_operations_round_history()` で重複している「symlink 解決 → repo-root 取得 → repo-root 相対パス正規化」処理を共通ヘルパ関数に統一する
So that 片側だけ修正される保守リスクを排除できる

**受け入れ基準**:
- [ ] 共通ヘルパ関数（例: `_resolve_history_filepath_in_repo()`）が追加され、`(repo_root, rel_path)` を出力するインターフェースに統一されている
- [ ] `check_history_staged_status()` と `_commit_operations_round_history()` の双方が共通ヘルパを使用し、重複コードが解消されている
- [ ] パス解決失敗時のスキップ挙動（warning + return 0）が従来どおり維持されている
- [ ] `write-history.sh` の既存 bats テストが回帰なく全 pass する
- [ ] `check_history_staged_status()` と `_commit_operations_round_history()` の双方が同一の共通ヘルパ関数を呼んでいることを bats またはコード差分（静的確認）で検証している（レビュー目視のみで完了としない）

**技術的考慮事項**:
- `bootstrap.sh` が共通ヘルパの配置先候補。配置先は Unit 設計時に確定する
