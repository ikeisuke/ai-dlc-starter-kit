# 意思決定記録 - v2.6.2

<!--
このファイルはInception Phaseで発生した重要な意思決定を記録します。
記録対象: AIが2つ以上の選択肢を提示し、ユーザーが選択した場面
記録対象外: Yes/Noの単純な承認確認、手続き的な選択
-->

## DR-001: 本サイクル主題を「v2.6.0 関連調整（バグ修正 + defer 完成）」に確定

- **ステップ**: Inception §16 Issue 確認
- **日時**: 2026-05-11

### 背景

新規サイクル開始時、未対応 Issue は v2.6.0 振り返り由来 4 件（#691/#692/#693/#694）と v2.6.0 以前由来の defer / feedback 多数。患者 patch / minor のいずれにも振り分け得る候補があり、サイクル主題の方向性確定が必要だった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | v2.6.0 振り返り由来 Issue（#691-#694）を中心に対応 | priority:high の #691 を含み、振り返りの即時フィードバックを次サイクルで反映 | reviewing 系評価軸追加 / squash 本体取り込み設計検討は規模大、patch に収まりにくい |
| 2 | v2.6.0 関連調整（3領域: 振り返り分離 / marketplace SoT / GitHub Projects 移行）の defer 完成 + 致命的バグ修正 | v2.6.0 で打ち立てた設計約束を完遂し、機能完成版を固定。バグ修正は patch 適合 | 振り返り由来 Issue は v2.7.0 へ送り |
| 3 | 個別の致命的バグ修正のみ（小規模 patch） | 最短期完了 | v2.6.0 defer の積み残し解消されない |

### 決定

**選択肢 2（v2.6.0 関連調整 + 致命的バグ修正）** を採用

### トレードオフと判断根拠

- **得たもの**: v2.6.0 で立てた設計約束（aidlc-retrospective 分離 / marketplace SoT / GitHub Projects 移行）の defer 完了。Operations フローのバグ（#677 / #678）を実害発生前に予防。aidlc-migrate のセキュリティ強化（#680, security:high）。
- **犠牲にしたもの**: v2.6.0 振り返り由来 4 件（#691-#694）は v2.7.0 以降に送り、reviewing 評価軸の改善が遅れる。
- **判断根拠**: ユーザーの方向性「振り返り分離などの 2.6.0 でやったことに関連する調整」と明確に整合。priority:high の #680（security）を含み、Operations フローの致命バグ修正は実害発生済（v1.16.1）であり緊急性が高い。reviewing 系の評価軸追加は次サイクル（minor）でまとめて対応する方が一貫性が出る。

---

## DR-002: 本サイクルバージョンを v2.6.2（patch）に確定

- **ステップ**: Inception §8 サイクルバージョン決定
- **日時**: 2026-05-11

### 背景

DR-001 で確定したスコープ（5 Issue: #677 / #678 / #680 / #682 / #683）に対する適切なリリース粒度（patch / minor）を決める必要があった。`suggest-version.sh` 推奨値: patch=v2.6.2 / minor=v2.7.0 / major=v3.0.0。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | v2.6.2（patch） | バグ修正 + defer 実装中心、互換性破壊なし、短期リリース可能 | feature 扱いの defer 実装も含むため厳密な patch 定義からはやや踏み込む |
| 2 | v2.7.0（minor） | feature 系 #682 / #683 を堂々と minor で扱える | バグ #677 / #678 の急ぎリリースが minor 規模に引きずられて遅れる |

### 決定

**v2.6.2（patch）** を採用

### トレードオフと判断根拠

- **得たもの**: 致命的バグ #677 / #678 を最短経路で patch リリースできる。後方互換性方針が明確になる。
- **犠牲にしたもの**: defer 実装（#682 / #683）も patch に乗るため、CHANGELOG 上で「機能追加」と明示する必要がある。
- **判断根拠**: スコープの大半（3/5）がバグ修正・security であり、patch 性質が支配的。defer 実装は v2.6.0 で打ち立てた設計約束の完遂であり、新機能追加というより「未完了部分の補完」と解釈できる。後方互換性は完全維持。

---

## DR-003: #677 採用案制約を「案 A/B のいずれか必須（A+B 併用可）、案 C 単独不可」に確定

- **ステップ**: Intent AI レビュー Round 1（codex 高指摘 #1）
- **日時**: 2026-05-11

### 背景

Issue #677 は3案（案 A: write-history auto-commit 化 / 案 B: squash-712 fail-fast 化 / 案 C: 手順書 SoT 明示化）を提示。Intent 初版では「案 A / B / C のいずれか / 組合せ」と幅広く解釈可能な記述だったが、codex Round 1 高指摘で「案 C 単独では成功基準（実動作改善）を満たせない」と整合性不足を指摘された。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 案 A/B/C すべてを許容（Construction 設計レビュー判断） | 設計自由度最大 | 成功基準（実動作改善）と矛盾、案 C 単独で完了判定可能になる |
| 2 | 案 A / B のいずれか必須（A+B 併用可）、案 C は単独不可で補助併用のみ | 成功基準と整合、判定可能性 Estimable / Testable 担保 | 案 C 単独の手順書改善のみのケースを排除 |

### 決定

**選択肢 2（案 A/B 必須、A+B 併用可、案 C 単独不可）** を採用

### トレードオフと判断根拠

- **得たもの**: Intent §成功基準と §スコープ確認の整合性確保。Construction Phase で何を満たせば完了かが一意に決定。
- **犠牲にしたもの**: 案 C 単独（手順書 SoT 明示化のみ）の選択肢を失う。
- **判断根拠**: 案 C 単独では「force push を伴う手動回復手順なしで 1 commit 構成完結」という Intent 成功基準を満たせない。codex の高指摘は妥当であり修正必須。

---

## DR-004: #678 修正方針を「案 A+B 必須、案 C は別 Issue defer」に確定

- **ステップ**: Intent AI レビュー Round 2（codex 低指摘 #2）
- **日時**: 2026-05-11

### 背景

Issue #678 案 A（pr-ready 側 body-file サイズ検証）+ 案 B（REST PATCH fallback 経路の二重防御）+ 案 C（テンプレ生成 helper 追加）。Intent 初版では案 C を Construction 判断に委ねる記述だったが、Round 2 低指摘で本文との整合に「スコープ再拡張の余地」が残ると指摘された。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 案 A+B 必須、案 C は Construction 判断（含めるか defer 判断） | 設計柔軟性 | 本文と [Question] の整合性が緩い、スコープ再拡張のリスク |
| 2 | 案 A+B 必須、案 C は別 Issue で defer 確定（Construction 再拡張不可） | スコープ確定、本文と整合、再拡張防止 | 案 C のテンプレ helper 追加が次サイクル送り |

### 決定

**選択肢 2（案 A+B 必須、案 C 本サイクル対象外で defer 確定）** を採用

### トレードオフと判断根拠

- **得たもの**: スコープ固定により Construction Phase の見積もり精度向上。本文 / [Question] / [Answer] の整合性確保。
- **犠牲にしたもの**: 案 C テンプレ helper 追加が defer。AI エージェントが空 mktemp を渡す経路自体は残る（ただし案 A+B で検出されるため事故防止は完了）。
- **判断根拠**: 案 A+B で根本予防は完了。案 C は予防的テンプレ helper 追加であり、副次的な利便性向上（必須ではない）。本サイクルを patch に収めるためのスコープ縮減として妥当。

---

## DR-005: existing_analysis.md / PRFAQ をスキップ（v2.6.1 patch precedent 踏襲）

- **ステップ**: Inception §3 ステップ2（Reverse Engineering）/ §3 ステップ5（PRFAQ 作成）
- **日時**: 2026-05-11

### 背景

depth_level=standard では通常 Reverse Engineering（brownfield のため）と PRFAQ 作成を実行する。一方、直前 patch サイクル v2.6.1（同条件）はいずれもスキップしていた。本サイクルは v2.6.1 同等の patch であり、Issue 本文が影響範囲・該当ファイルを明示している。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | existing_analysis.md / PRFAQ を作成 | depth_level=standard の手順厳格遵守 | patch サイクルとして overhead、各 Issue 本文と重複情報になる |
| 2 | v2.6.1 precedent に従い両方スキップ | 短期完了、patch 性質に適合 | depth_level 仕様からは逸脱（standard で通常実行） |

### 決定

**選択肢 2（両方スキップ）** を採用

### トレードオフと判断根拠

- **得たもの**: 短期完了に貢献。Issue 本文 / Unit 定義の「技術的考慮事項」「関連 Issue」「関連設計」セクションで影響範囲・該当ファイル・既存設計参照は十分に記録済。
- **犠牲にしたもの**: depth_level=standard の手順厳格遵守からはやや外れる。
- **判断根拠**: v2.6.1 同条件 patch サイクルの precedent。本サイクルは新規探索ではなく v2.6.0 で実施済の領域への調整であり、コードベース解析を Cycle 単位で再実施する追加価値は限定的。CONFIG 上の depth_level は次サイクル以降の minor / major で本来の使い方に戻す。

---

## DR-006: Inception 中に Unit 006（#697 / AI Bash プロンプト zsh OOM クラス予防）を追加（スコープ拡張）

- **ステップ**: Inception 完了処理直後の追加対応決定（codex Round 2 レビュー時の実発生検出に起因）
- **日時**: 2026-05-11

### 背景

v2.6.2 Inception Phase 中、codex Round 2 レビューを発行する際に、私（AI エージェント）が `codex exec resume <id> "...プロンプトに backtick が混入..."` を bash 経由で実行したところ、bash がプロンプト内 backtick をコマンド置換として解釈 → 未定義コマンド呼び出し → zsh `command_not_found_handler` 無限再帰により OOM クラッシュが発生。これは v2.6.1 で対応した #688 の **兄弟バグ**（同一根本原因クラス）であり、`/aidlc v` 経路だけでなく **「AI エージェントが Bash ツール経由で long-text を bash 引数文字列として直接渡す全経路」** に存在する。

「Intent 改訂と再承認」のガードレール（user_stories §圧縮方針）に従い、ユーザーに判断を求めた結果、本サイクル内で対応することが選択された。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | v2.6.2 に Unit 006 として追加（Intent 改訂・再承認） | 同一サイクル内で予防策確立、本サイクル中の AI レビュー安全性向上、Operations フローのバグ Unit 群と一貫した品質改善 | サイクル工数 +0.5 日、Inception 完了処理を再実行する必要あり |
| 2 | 新規 Issue を起票して v2.6.3 に defer | 現サイクルのスコープを膨らませずに済む | 本サイクル中の Construction / Operations Phase の AI レビュー安全性は次パッチまで担保されない |
| 3 | CLAUDE.md ルール追記のみ（最小） | 最短期完了 | スクリプト本体改訂・SKILL.md 一般化が defer されるため改善が部分的 |

### 決定

**選択肢 1（v2.6.2 に Unit 006 として追加、Intent 改訂・再承認）** を採用

### トレードオフと判断根拠

- **得たもの**: 本サイクル内で AI 運用安全化の予防策を確立。Construction Phase / Operations Phase での codex / claude / gemini 呼び出しが改訂後の推奨経路（一時ファイル + wrapper / file-based interface）で安全実施できる。v2.6.0 関連調整の一貫した品質改善として位置付け可能。
- **犠牲にしたもの**: サイクル工数 +0.5 日（5〜8.5 日 → 5.5〜9 日）。Inception 完了処理（commit / PR body / history / progress）の再走行が必要。
- **判断根拠**: 「結構危険なエラー」とユーザー判断、かつ v2.6.2 Inception Phase 中に実発生（実害顕在化）したため、同サイクル内で予防策を確立するほうが運用上の整合性・安全性の点で勝る。スクリプト本体動作は変更しないため patch リリース性質を維持できる。Intent / user_stories / Unit 006 の改訂レビュー（codex / 3 ラウンド / unresolved=0 / defer=0 / resolved=4）で整合性検証済。

---

## DR-007: Unit 002 スコープを aidlc-migrate 書き込み系3ファイルに拡張

- **ステップ**: Construction Phase / Unit 002 計画ファイル作成時
- **日時**: 2026-05-11

### 背景

Unit 002（aidlc-migrate manifest 由来パスのトラバーサル検証 / Issue #680）の責務には「`migrate-apply-config.sh` の `_apply_resource()` 系」と書かれているが、実コードでは関数化されておらず、各ループ内に直接展開されている。実態調査の結果、同一脆弱パターンが書き込み系3ファイル（`migrate-apply-config.sh` / `migrate-apply-data.sh` / `migrate-cleanup.sh`）に存在することを確認した。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | aidlc-migrate 書き込み系3ファイルすべて | Issue #680 タイトル「aidlc-migrate: manifest 由来パスのトラバーサル検証」と整合、同質脆弱性の同時解消、defer 残骸ゼロ化、共通 lib で DRY 化 | 工数微増、Unit 定義§責務の「migrate-apply-config の `_apply_resource()` 系」表現とは厳密一致しない |
| 2 | migrate-apply-config.sh のみに限定 | Unit 定義§責務と Issue #680 本文の言及範囲に厳密準拠、見積もり 1〜1.5 日内で確実 | apply-data / cleanup の同質脆弱性が defer 残骸として残る、新規 Issue 起票で別 Unit 化が必要 |

### 決定

**選択肢 1（書き込み系3ファイルすべて）** を採用

### トレードオフと判断根拠

- **得たもの**: 同質脆弱性の同時解消、`lib/path-guard.sh` の単一 SoT 化で DRY 確保、Issue #680 タイトルとの整合性
- **犠牲にしたもの**: 工数微増（Unit 005 ほどではない / 既存パターン横展開で完結）
- **判断根拠**: Unit 定義§境界「aidlc-migrate スコープに閉じる」と Issue #680 タイトルがスコープ拡張を許容。共通 lib に集約することで型崩れも防げる。`apply-data` / `cleanup` を defer すると同質バグの追跡コストが残るのを避ける

---

## DR-008: 全拒否ケースで exit 1 統一（exit-code-convention.md 準拠）

- **ステップ**: Construction Phase / Unit 002 計画レビュー Round 1（codex 指摘 #3）対応
- **日時**: 2026-05-11

### 背景

Unit 002 当初設計（Unit 定義§技術的考慮事項）では「exit code は全拒否ケースで `2` 固定」としていたが、codex 計画レビュー Round 1 で `guides/exit-code-convention.md`「exit 1=バリデーションエラー / exit 2=システムエラー」との乖離が指摘された。CLAUDE.md「設計レビュー時のガイド照合ルール」も既存ガイドとの整合性チェックを求めている。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 規約準拠（exit 1）に修正 | exit-code-convention.md 準拠、他の参考実装（migrate-config.sh / squash-unit.sh）と同一ハンドリング、AI ガイド照合ルールに合致 | Unit 定義§技術的考慮事項の同期更新が必要 |
| 2 | Unit 定義通り exit 2 を維持 | 当初設計通り、規約に例外規定を追加すれば説明可能 | 規約ドキュメント側の例外追加が必要、他参考実装と挙動が分散 |

### 決定

**選択肢 1（規約準拠 / exit 1）** を採用

### トレードオフと判断根拠

- **得たもの**: exit-code-convention.md 準拠、二層 exit code 契約（バリデーション拒否=1 / shim システムエラー=2）の明文化、他参考実装との一貫したハンドリング
- **犠牲にしたもの**: Unit 定義§技術的考慮事項の同期更新（影響は文書のみ）
- **判断根拠**: 規約ドキュメント側の例外追加よりも、参考実装側の規約準拠を選ぶほうが「規約はそのまま」の原則を維持できる。AI ガイド照合ルール（v1.27.3 経緯）の存在自体が、規約逸脱に倒さない判断を支持する

---

## DR-009: Unit 003 採用案を A+B 併用に確定（auto-commit + fail-fast 二層防御）

- **ステップ**: Construction Phase / Unit 003 計画作成直後（採用案選定）
- **日時**: 2026-05-11

### 背景

Unit 003（Issue #677、致命的バグ）の Unit 定義で「案 A（write-history.sh auto-commit 化）/ 案 B（squash-712 fail-fast 化）/ A+B 併用のいずれを採用するかは Construction 設計レビューで確定（**案 C「手順書 SoT 明示化のみ」は単独不可、補助併用のみ可**）」と明示されており、設計レビュー前に採用案決定が必要。Issue #677 は「force push で手動復旧した」事例があり、本ユニット見積もり上限（1.5 日）内で最も堅牢な解を求めた。

### 選択肢

| # | 選択肢 | メリット | デメリット | 実装規模 |
|---|--------|---------|-----------|--------|
| 1 | A + B 併用 | auto-commit で通常運用自動化 + fail-fast で街道外入力・運用ミス検知の二層防御。`--no-commit` 経路 / write-history.sh 経由でない append 漏れ / バグ回帰時も検知可能 | 実装規模が最大（1.5 日 / Unit 見積もり上限） | 約 1.5 日 |
| 2 | 案 A 単独（auto-commit のみ） | 通常運用は楽になる。実装規模最小 | `--no-commit` opt-out 時は §7.13 pre-flight check のみが検知層。write-history.sh 経由でない append 漏れには対応不可 | 約 0.5 日 |
| 3 | 案 B 単独（fail-fast のみ） | 運用ミス検知は確実。実装規模最小 | 通常運用の手間（手動 commit）は残る | 約 0.5 日 |

### 決定

**選択肢 1（A + B 併用）** を採用

### トレードオフと判断根拠

- **得たもの**: 二層防御による Issue #677 致命的バグの構造的封じ込め。通常運用の自動化（案 A）+ 街道外入力・運用ミス・バグ回帰の検知（案 B）
- **犠牲にしたもの**: 実装規模が最大（Unit 見積もり上限 1.5 日）。設計レビューと bats / integration テストの両面で網羅性を求めるため検証コスト増
- **判断根拠**: Issue #677 が「致命的バグ」かつ「force push で手動復旧した」事例がある以上、再発を構造的に封じる多層防御が妥当。Unit 見積もり上限内に収まる範囲で最堅牢な解を選択。ユーザーが A+B 併用を明示選択（AskUserQuestion）

---

## DR-010: Unit 005 で bin/setup-github-project.sh の subject bug を即時 fix（Unit scope との緊張関係）

- **ステップ**: Construction Phase / Unit 005 Phase 2 実装中
- **日時**: 2026-05-12

### 背景

Unit 005 計画は「含まれるもの: テスト追加 + Unit 004 既存 bats のモック経由化」「含まれないもの: 4 スクリプト本体の挙動変更（設計上の不整合が見つかった場合は別 Issue / 別 Unit へ defer）」と明記。

Phase 2 で `bin/setup-github-project.sh` の `setup-github-project.bats` Case 1 (`--dry-run で 5 subcommand 順次実行 + setup-github-project: completed`) を実装中、subject 内部の audit step 呼出 `"$_CLI" audit --check spec-conformance "${_OPTS[@]/--dry-run/}"` のパラメータ展開が空文字列要素を残し、下位 CLI が `unknown_option:` で exit 1 する bug を検出。設計書の Phase 2 ケース表 #1 を成立させるには、この bug を修正する必要があった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 即時 fix（配列フィルタに置換 / 5 行 + コメント） | 設計書ケース表どおりの bats が成立 / Issue #683 受け入れ基準達成可 / CLAUDE.md「即時実装優先ルール」に整合（同サイクル / 小規模 / ブロッカーでない他作業に影響なし） | Unit 005 plan「含まれないもの」との一見矛盾 |
| 2 | 別 Issue へ defer + bats 期待を「exit 1 (現状 bug)」に書き換え | Unit 005 plan の文言を厳守 | 設計書ケース表が成立しない / Unit 完了マーカー未達 / 現状 bug を「期待挙動」として固定化する技術負債 |
| 3 | 別 Issue へ defer + Case 1 のみスキップ | 他 3 ケースは成立 | 主要シナリオ（dry-run + 5 subcommand 完走）が未検証のまま Unit 完了 / Phase 2 完了マーカー未達 |

### 決定

**選択肢 1（即時 fix）** を採用

### トレードオフと判断根拠

- **得たもの**: 設計書 Phase 2 ケース表 18 ケース全件成立 / Issue #683 受け入れ基準達成 / 現状 bug の技術負債を発生させない
- **犠牲にしたもの**: Unit 005 plan「含まれないもの」との表面上の矛盾（ただし「設計上の不整合」という defer 例外条件には該当しない / 単純な実装 bug）
- **判断根拠**: CLAUDE.md「即時実装優先ルール」の 3 条件（現サイクルスコープ内 ✓ / 修正小規模 1 ファイル 5 行 ✓ / 他作業に影響なし ✓）を満たす。bats 追加によって発見された subject bug を defer すると bats 期待値が「現状 bug の固定化」になり、回帰検知の目的に反する。修正範囲は audit step 呼出 1 箇所、影響範囲は限定的。コード AI レビュー R1 / R2 / R3 で fix の妥当性を確認済み（auto_approved）。



---

## DR-011: Unit 006 で SKILL.md 一般化の「案 b（共通ガイド分離）」を採用

- **ステップ**: Construction Phase / Unit 006 Phase 1 設計
- **日時**: 2026-05-12

### 背景

Issue #697 への対応で「`skills/aidlc/SKILL.md` §バージョン表示 §注意セクション」（v2.6.1 Unit 001 で導入された `/aidlc v` 経路固有の zsh OOM 注意書き）を Bash ツール経由全般の一般化規約に拡張する必要があった。一般化の実装形態として 2 つの選択肢が存在し、計画 §「案 a / b 選定基準」の 4 基準スコアリングで案 b 採用が確定した。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| a | SKILL.md 内で一般化（注意セクション自体を「Bash ツール経由の zsh OOM 回避ルール」として全文書き換え） | 参照ホップ数 1（SKILL.md 内完結） | 他 SKILL.md（write-history 等）から参照する場合に重複記述発生 / 将来拡張時に SKILL.md 編集範囲が広がる |
| b | `skills/aidlc/steps/common/<新設>.md`（運用ガイド）を新設し、SKILL.md は一般化要約 1〜2 文 + 詳細参照 | 規約 SoT を CLAUDE.md ① に一本化 / 他 SKILL.md から再利用可能 / 将来拡張時に 1 ファイル編集 | 参照ホップ数 2 / 新規ファイル追加 |

### 選定基準（4 軸スコアリング / 計画より）

| 基準 | 本 Unit での判定 | 優位 |
|------|----------------|------|
| 参照経路の単純性 | skills/write-history からも参照したい / 他 skill_spec への再利用余地あり | b |
| 重複記述量 | write-history / aidlc 両方から参照する設計 | b |
| 責務分離 | Unit 006 の対象は「全 Bash ツール経由経路」で aidlc 固有でない | b |
| 保守コスト | 将来 `codex exec` / `claude -p` 等への拡張余地が高い | b |

**スコア**: 案 a 0 / 案 b 4 → 案 b 採用（4 基準すべてで案 b 優位）

### 決定

**選択肢 b（共通ガイド分離 / `skills/aidlc/steps/common/bash-tool-safety.md` 新設）** を採用

### トレードオフと判断根拠

- **得たもの**: 規約 SoT 一本化（CLAUDE.md ① / 重複ゼロ）/ 将来拡張時の編集範囲集約（1 ファイル）/ 複数 SKILL.md からの再利用性
- **犠牲にしたもの**: 参照ホップ数が 2（SKILL.md → steps/common/bash-tool-safety.md → CLAUDE.md ①）に増えるが、各経路は実 Markdown リンクで連結されているため AI / 人間ともに辿りやすい
- **判断根拠**: 4 基準すべてで案 b 優位。設計レビュー R1 指摘 #4 を反映して SKILL.md 内に一般化要約 1〜2 文を残し、Unit 定義「責務」のトレーサビリティを SKILL.md 内で直接充足する形に整えた。codex 設計レビュー 3R / コードレビュー 2R / 統合レビュー 2R すべて auto_approved

---

## DR-012: Unit 006 で AGENTS.md を最小骨格 + 参照リンクで新規作成（MUST 化）

- **ステップ**: Construction Phase / Unit 006 Phase 1 設計（計画レビュー Round 1 反映時）
- **日時**: 2026-05-12

### 背景

Unit 006 計画 Round 1 で codex 指摘 #1（高 / architecture）を受領。当初計画では AGENTS.md の取扱を「案 i: スコープ外」「案 ii: 最小作成」の 2 択で設計レビューに委ねる構成だったが、Unit 定義「責務」が「CLAUDE.md / AGENTS.md / 関連 SKILL.md への追記」を明示しており、Issue #697 受け入れ基準「案 A」とも整合する必要があった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| i | AGENTS.md は本 Unit のスコープ外として明示（別 Issue 化） | スコープを絞れる | Unit 定義責務と矛盾 / 受け入れ基準「案 A」と矛盾 |
| ii | 最小 AGENTS.md（最小骨格 + CLAUDE.md ① 参照リンク）を新規作成 | Unit 定義責務 + 受け入れ基準「案 A」に整合 / Codex CLI / Gemini CLI 等の AGENTS.md 参照 AI への配布物 baseline 規約も同時に整備 | 新規ファイル追加 |

### 決定

**選択肢 ii（最小 AGENTS.md 新規作成）** を採用

### トレードオフと判断根拠

- **得たもの**: Unit 定義 / Issue 受け入れ基準との整合性 / Codex CLI / Gemini CLI 等の AGENTS.md 参照 AI への配布規約整備 / リポジトリ baseline 規約の完備（CLAUDE.md + AGENTS.md）
- **犠牲にしたもの**: 新規ファイル 1 件追加（最小骨格 / 14 行）。将来 AGENTS.md 固有規約が必要になった際は本 Unit の骨格に追記する形で拡張する（CLAUDE.md との重複防止）
- **判断根拠**: codex 計画レビュー R1 指摘 #1（高）の「Unit 責務との整合が崩れる可能性」を解消する必要があった。最小構成（参照リンクのみ）であれば CLAUDE.md ① セクション SoT との重複は発生しない。codex 計画レビュー R2 / R3 で確定構成として承認済み
