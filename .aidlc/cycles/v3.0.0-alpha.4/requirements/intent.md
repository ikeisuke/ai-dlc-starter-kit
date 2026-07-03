# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v3.0.0-alpha.4（v3 本体: `skills/aidlc-v3/`）

## 開発の目的

v3.0.0 GA に向けた仕上げの一環として、`skills/aidlc-v3/` の **frontmatter パースの安全境界を単一の共有 parser ライブラリへ集約**し、「寛容な line ベース regex / `jq` coerce が malformed YAML・JSON を通すバリデーションクラス」の**反復再発を構造的に断つ**（振り返り Issue #733 の T1/T2'/T4/T6）。

**本サイクルの主対象は frontmatter パース集約**である。JSON（`state-*.sh`）パースは既に `state-validate.sh` に集約済み（#731）のため、本サイクルでは**現状維持し再設計・共有 parser への移管は行わない**（既存テストでの整合確認のみ）。「JSON を通すバリデーションクラス」を断つ狙いは、frontmatter 側の line ベース regex に対して適用される（JSON 側は既存集約で担保済み）。

#733 では同クラスのバグが alpha.2（`state-*.sh`）→ alpha.3（`work-item-*.sh`）で反復再発し、per-Unit の Construction レビューをすり抜け、Operations premerge の全差分レビューで初めて 8 件まとめて検出された。release / reflect / doctor 等パース面が増える前の今が、再発コストを断つ設計改善の最適タイミング。

## ターゲットユーザー

- **v3 本体の保守者（メタ開発）**: パース境界が 1 箇所に集約され、拒否理由・受理仕様が中央化されることで保守・拡張コストが下がる
- **将来の v3 consumer / AI エージェント**: malformed な work item / state を確実に拒否し、誤った継続（partial parse による undefined behavior）を防ぐ

## ビジネス価値

- **再発防止の構造化**: 「共有する」だけでなく**個別スクリプトでの構造解釈を禁止する規約 + 実行可能契約 + 機械検出**まで含めて締めることで、後続フローでローカル実装が再び足される余地を断つ
- **DRY 違反の解消**: スカラー抽出・配列パース・frontmatter ブロック抽出 + malformed guard の 3 クラス重複（各 2〜3 箇所）を単一実装へ統合
- **GA 品質**: per-Unit レビューでは横展開を見逃すバグクラスを、仕様 fixture と CI ガードで先回り検出

## 成功基準

- `skills/aidlc-v3/scripts/lib/` に共有 frontmatter parser ライブラリが新設され、`work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` が**個別パース実装（スカラー抽出 / dependencies 配列 / frontmatter ブロック抽出 + malformed guard）を撤去して共有ライブラリを source**している（T1）。`state-*.sh`（JSON）は対象外（現状維持）
- 共有 parser API の責務境界（構造抽出・型/必須キー/範囲検証・拒否理由の標準化）が明文化され、**個別 consumer スクリプトでの frontmatter 構造解釈**に `grep`/`sed`/`awk`/permissive `jq` を使うことを**禁止する規約**が文書化されている（T1）。共有 parser ライブラリ本体・テスト fixture・非構造用途（ログ整形等）は規約の対象外
- 受理 / 拒否ケースを固定する **conformance test suite** が存在し、validate / next / status が同一 fixture を通る。Unit 完了条件に「新たに構造データを読む場合、共有 parser を使い conformance fixture にケース追加済みであること」が組み込まれている（T2'）
- `skills/aidlc-v3/scripts/`（`lib/` 配下と `tests/` を除く個別 consumer スクリプト）に対し、frontmatter の構造解釈に禁止パターンが混入していないかを**機械検出する CI チェック**が追加され、共有境界からの逸脱を自動で弾く（T4）。検出対象は「個別 consumer スクリプトでの frontmatter 構造解釈」、allowlist は `lib/`（共有 parser 本体）と `tests/`（fixture）、禁止 `jq` coerce の例として `// 既定値`・`?`（型エラー抑制）・暗黙型変換を明示する
- v3 の **cycle 解決入口**（`state.json` の `current_cycle` を SoT とする読取経路 / `state-read.sh` ほか）が、**明示指定 / `current_cycle` 値を最優先**し git 履歴・周辺ファイル名・ディレクトリ走査順に影響されないことを固定する**回帰テスト**が追加されている（T6 / framework 側 `skills/aidlc/` の CycleResolver 修正は除外のまま）
- v3 全テストが緑（既存の回帰テスト規律を維持）。**互換維持**: 既存で正しく受理/拒否されているケースの境界は変えない（純粋なリファクタ + 規約追加）。**意図的な拒否強化**: #733 で検出された既知の malformed / partial-parse クラスは、共有 parser の**拒否 fixture として固定**する（既存に取りこぼしがあった場合はこの範囲で拒否側に倒す）

## 期限とマイルストーン

v3.0.0-alpha.4 サイクル内で完結。GA（v3.0.0）前のもう一段の alpha 増分として、構造改善を検証してから GA へ進む。

## スコープ

### 含まれるもの

- **T1**: `skills/aidlc-v3/scripts/lib/` への共有 frontmatter parser 集約（スカラー抽出 / dependencies 配列パース / frontmatter ブロック抽出 + malformed guard / 拒否理由標準化）と、個別構造解釈を禁止する規約の明文化
- **T2'**: 共有 parser の受理/拒否を固定する conformance test suite（既存 `put_wi()` / 自己完結型 bash ハーネス形式を踏襲）と Unit 完了条件への組み込み
- **T4**: 禁止パースパターンの機械検出 CI チェック（独立検出スクリプト + GitHub Actions ジョブ）
- **T6**: v3 CycleResolver の「明示指定最優先」を固定する回帰テスト追加

### 明示的に除外するもの

- **doctor コマンドの新設**（未実装・予約）。T4 は CI チェックで実装し、doctor 統合は対象外
- **framework 側（`skills/aidlc/`）の CycleResolver 修正**。#733 P4 で v2.6.6 を返した CycleResolver は framework 側ツールの可能性が高いが、本サイクル（v3 GA 仕上げ）のスコープ外。v3 本体は既に明示指定一本化済みのため回帰テストのみで担保する
- **JSON（state-*.sh）パースの再設計**。schema 検証は既に state-validate.sh に集約済み（#731）であり、本サイクルでは frontmatter 集約を主対象とする（必要に応じ整合確認のみ）
- **AI-DLC フレームワーク側 backlog Issue 群**（#640/#586/#700 等）。`skills/aidlc/` 対象であり v3 GA スコープ外
- **release / reflect / develop normal・risky フローの新規実装**（予約フロー / 別サイクル）

## 不明点と質問（Inception Phase中に記録）

[Question] 本サイクルに含める Try は？
[Answer] T1 + T2' + T4 + T6（ユーザー選択 / 2026-06-18）

[Question] T4（禁止パターン機械検出）の実装先は CI か doctor か？
[Answer] CI チェック（doctor は未実装・予約のため。ユーザー選択 / 2026-06-18）

[Question] T6（CycleResolver 明示指定優先）の扱いは？
[Answer] v3 に回帰テストのみ追加（v3 本体は gitlog 推定が存在せず明示指定一本化済みのため。framework 側の修正はスコープ外。ユーザー選択 / 2026-06-18）

[Question] サイクルバージョンとブランチは？
[Answer] CYCLE=v3.0.0-alpha.4 / ブランチ=cycle/v3.0.0（v3.0.0 統合ライン）。ユーザー選択 / 2026-06-18
