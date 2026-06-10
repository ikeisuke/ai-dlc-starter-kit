# Unit 004 論理設計: v3 移行方針（migration.md 確定）

> docs-only の設計文書 Unit のため、ドメインモデルは N/A。本 logical design に「migration.md のアウトライン + 移行モード比較表 + データ変換マッピング + 非互換点 + 条件付き EOL/v2 共存方針 + 推奨モード/片方向移行 + config 変換 SoT ガード」を集約する。これが Phase 2（`docs/v3/migration.md` 執筆）の設計入力となる。

## 0. 事前コード読込み（既存実装の参照）

docs 設計 Unit のため新規 v3 実装コードは存在しない。設計判断の根拠となる入力は、RFC（DG-3 / DG-5 / §5.7 / §7 引き継ぎマトリクス / §4.3 `aidlc-migrate` 分類）・data-model.md（Unit 003 確定構造）・workflow.md（コマンド名 / フェーズコマンド体系）・計画書 renewal-plan の移行セクションである（`/aidlc-migrate` の位置付け根拠は RFC §4.3）。

### (a) Read 対象 + 目的

| 対象 | Read 目的 |
|------|----------|
| `docs/v3/rfc.md`（§5.3 DG-3 / §5.5 DG-5 / §5.7 v2 共存方針 / §7 引き継ぎマトリクス L309） | 条件付き EOL の 3 条件・v2 凍結（クリーンカット）・consumer runtime 非影響・片方向移行・core/extension 境界（GitHub Projects/Milestone/Release は extension/廃止）を非互換点と EOL 方針の設計制約として取り込む |
| `docs/v3/data-model.md`（§2 ディレクトリ構造 / §3 state.json schema / §4 work item frontmatter / §8 config スコープ注記 L290） | データ変換マッピングの変換先正本（ディレクトリ構造 / state.json / frontmatter）を参照。config 終端 schema が data-model.md スコープ外であることを SoT ガードの根拠とする |
| `docs/v3/workflow.md`（コマンド名 develop / フェーズコマンド体系） | コマンド名 develop 整合の確認。workflow.md が定義するのは define/develop/release/reflect/status/doctor/express であり migration はスコープ外。migrate がフェーズコマンドに含まれないことを確認 |
| `docs/v3/rfc.md` §4.3 L136（v1/v2 migration = aidlc-migrate = extension(opt-in) / v3 同梱） | `/aidlc-migrate` の位置付け（フェーズコマンドではなく一時的・移行専用の extension スキル）の根拠 |
| `docs/v3-renewal-plan.md`（v2→v3 移行 L941-983 / 非互換点 L1338-1350 / リスク L1241-1245） | 移行モード 3 種・データ変換表・移行コマンド手順・非互換点 10 項目・consumer 移行コストリスクの原案を一次入力とする |

### (b) 設計時に意識すべき挙動

- **完全自動変換は目指さない**（renewal-plan L947）。変換できないケースは人間に確認する前提。migration.md は「方針」を確定し、変換スクリプトの実装は本サイクル対象外。
- **コマンド名は develop を正本**とする（RFC DG-1 / workflow.md 確定）。renewal-plan の移行表・実装計画に残る `build` 表記は使用しない。
- **変換先 schema は data-model.md が正本**。本書は変換**規則**（どの v2 資産をどの v3 成果物にどう変換するか）を定義し、変換先 schema（state.json フィールド / frontmatter キー / ディレクトリ構造）を二重定義しない。
- **config 終端 schema（34→8）は未確定**: RFC §6.4 は「data-model.md で確定」と委譲し、data-model.md §8 L290 は「RFC §6 で別途確定予定」と差し戻している（相互委譲で宙に浮く既知ギャップ）。migration.md の config 変換は「キーマッピング方針 + 不要キー警告の挙動」のみを記述し、8 キーの具体集合を本書で新規定義しない。
- **DG-3 引き継ぎ受け**: RFC §7 マトリクスが migration.md に渡す「EOL 3 条件・移行期間中 v2 非変更・consumer runtime 非影響・片方向移行」の相互関係を方針レベルで記述する（EOL の運用実行・告知作業の実施は対象外）。
- **片方向移行（rollback 不可）**: v2 runtime 互換は維持しない（RFC §5.7）。推奨は new-cycle-only（過去資産を触らない）でリスク最小。

### (c) 既存実装に基づく代替案検討（migration.md の記述方式）

| 方式 | 適合性 | 採否 |
|------|-------|------|
| `refactor`: renewal-plan 移行セクションをそのまま転記 | 低（コマンド名 build 残存・config 二重定義リスク・DG-3 引き継ぎ未整理・非互換点の consumer 影響分類なし） | 却下 |
| `replace`: 確定方針として再構成（develop 整合・変換先正本を data-model.md に委譲・config SoT ガード・DG-3 引き継ぎ受け・非互換点に consumer 影響列を追加） | 高（RFC §7 引き継ぎ・data-model.md SoT 委譲方針と整合） | **採用** |
| `extend`: renewal-plan 転記 + 追記 | 中（build 混在・config 二重定義リスク温存） | 却下 |

## 1. migration.md アウトライン（章立て）

Phase 2 で以下の構成で執筆する。

```text
1. 概要 / 目的（完全自動変換は目指さない / 推奨 new-cycle-only / 片方向移行 rollback 不可）
2. 移行モード（new-cycle-only / best-effort / archive-only の定義 + 比較表）
3. v2 → v3 データ変換マッピング（config / units / progress / history / release_notes / intent）
4. v2 との非互換点（10 項目 + consumer への影響分類）
5. 条件付き EOL と v2 共存方針（DG-3 / §5.7 引き継ぎ受け / 方針記述）
6. 移行コマンドの方針概要（/aidlc-migrate の手順方針 / 実装は対象外）
7. 推奨移行モードと片方向移行の明記（まとめ）
8. RFC / data-model.md との整合（SoT 二重定義回避 / config SoT ガード）
```

> **章対応の注記**: 上記 1〜8 が migration.md（Phase 2 成果物）の章立て。本論理設計の §9（完了条件への対応）は論理設計のメタ章であり、migration.md には載せない（Phase 2 執筆対象外）。

## 2. 移行モード設計（定義 + 比較表）

3 モードを定義し、比較表で「推奨対象 / 前提条件 / 変換有無 / 既知リスク」を確定する。

| モード | 概要 | 推奨対象 | 前提条件 | 変換有無 | 既知リスク |
|-------|------|---------|---------|---------|-----------|
| **new-cycle-only**（推奨） | v2 過去資産は触らず v3 cycle を新規開始 | 大半の consumer / 過去サイクルを参照不要にできるプロジェクト | v3 を新 cycle として始められること | なし（過去資産は v2 のまま archive 的に残置） | 過去サイクルの状態は v3 ツールから参照不可（v2 ファイルとして残るのみ） |
| **best-effort** | intent / unit / history を v3 形式に変換 | 進行中サイクルを v3 で継続したいプロジェクト | 変換不能ケースを人間が補完できること | あり（§3 変換マッピング適用） | 完全変換は保証されない / 変換不能箇所は人間確認が必要 / 片方向（rollback 不可） |
| **archive-only** | v2 cycle を archive 扱いとし index だけ作る | 過去資産の所在記録のみ残したいプロジェクト | - | なし（index 生成のみ） | v3 ツールでの内容操作は不可（参照用 index のみ） |

**推奨は new-cycle-only**（renewal-plan L957）。理由: 過去資産を触らないため変換失敗リスクがなく、移行コストが最小。

## 3. データ変換マッピング設計（best-effort 適用時）

主要 v2 資産の変換先と変換方法を確定する。**変換先 schema の正本は data-model.md（Unit 003）**であり、本表は変換**規則**を示す。変換先パスはすべて `.aidlc/` 配下の正本パスで記述する（data-model.md §2 と粒度を統一）。

| v2 資産 | v3 変換先 | 変換方法 | 変換先正本 |
|---------|----------|---------|-----------|
| `requirements/intent.md` or `inception/intent.md` | `.aidlc/cycles/<cycle>/intent.md` | パスコピー | data-model.md §2 |
| `story-artifacts/units/*.md` | `.aidlc/cycles/<cycle>/work-items/*.md` | テンプレート差分を埋める（frontmatter 必須キー: id/status/size/risk/assigned/dependencies を生成） | data-model.md §4 |
| `progress.md` | `.aidlc/state.json` | パース + schema 生成（define_completed / release 状態を導出） | data-model.md §3 |
| `history/*.md` | `.aidlc/cycles/<cycle>/journal.md` | 要約統合（追記型の軽量形式に集約） | data-model.md §7 |
| `operations/release_notes.md` | `.aidlc/cycles/<cycle>/release.md` | パスコピー | data-model.md §2 |
| `.aidlc/config.toml`（v2: 多数キー） | `.aidlc/config.toml`（v3: 削減キー集合） | **キーマッピング + 不要キー警告**（§8 SoT ガード参照） | （終端 schema 未確定 / §8） |

**config 変換の扱い**: migration.md は「v2 キー → v3 キーの対応方針」と「v3 で未サポートになった v2 キーを警告（エラーにしない / 非互換点 #3 と整合）する挙動」のみを記述する。v3 config の 8 キー終端集合は本書で確定しない（§8 参照）。

## 4. v2 との非互換点設計（consumer 影響分類）

renewal-plan L1340-1350 の 10 項目に **consumer への影響分類** を付与して確定する。

| # | 非互換点 | consumer への影響 |
|---|---------|------------------|
| 1 | ステップファイル構造（35→5 ファイル） | カスタムステップは**再作成が必要** |
| 2 | 状態管理（progress.md 推論ベース → state.json 明示 schema） | **マイグレーション対象**（progress.md は v3 で認識されない） |
| 3 | 設定キー削減（多数 → 少数） | 未サポートキーは**無視される**（エラーにしない） |
| 4 | レビュースキル統合（perspective を持つ reviewing-* 9 スキル + 共有基盤 reviewing-common の複製解消 → aidlc-review 1 本 / workflow.md §6.1 と同粒度） | **再インストール必要**（marketplace.json 更新） |
| 5 | スクリプト API（廃止スクリプト直接呼び出し） | 直接呼ぶ consumer は**壊れる**（非推奨パスのため**マイグレーション対象外**） |
| 6 | recovery 動作（ファイル存在推論 → state.json 明示） | progress.md は v3 で**認識されない**（**マイグレーション対象**） |
| 7 | コマンド名（旧名 → 新名 develop 等） | 旧名は**エイリアスとして維持**（ヘルプ/ドキュメントは新名が主） |
| 8 | 成果物構造（history/*.md → journal.md 単一追記型） | **マイグレーション対象**（要約統合） |
| 9 | GitHub Projects 連携 | **廃止**（core 責務外。外部運用へ） |
| 10 | Milestone 自動管理 / GitHub Release・version_tag 自動作成 | core から **extension 化（opt-in / 既定 off）**（core 既定では実行されず、利用には extension 有効化が必要） |

非互換点は RFC の core/extension 境界（DG-5 / §4.3: Projects は廃止、Milestone 自動管理・GitHub Release/version_tag 自動作成は extension(opt-in)）と整合する。renewal-plan 非互換点リスト（L1349-1350）の Milestone 項に、RFC §4.3 L135 が extension 分類した GitHub Release/version_tag を統合して #10 とした。

## 5. 条件付き EOL と v2 共存方針設計（DG-3 / §5.7 引き継ぎ受け）

RFC §7 が migration.md に引き継ぐ DG-3 関連事項を**方針レベル**で記述する（実際の EOL 宣言・告知掲載・メンテナンスモード運用の実施作業は対象外）。

- **条件付き EOL の 3 条件**（RFC §5.3）: (1) マイグレーションが最低 2 consumer でテスト済み / (2) v3 で 1 cycle のドッグフーディング完了 / (3) EOL 告知が README/CHANGELOG に 1 バージョン前から掲載済み。3 条件すべて充足で v2 を EOL とする。
- **移行期間中の v2 凍結（クリーンカット）**: EOL までの期間、v2 `skills/aidlc` には通常改善・v3 互換対応を行わない。セキュリティ/クリティカル修正のみ例外的に最小変更を許容。
- **consumer runtime 非影響**: v3 リリースは v2 利用者の runtime を壊さない。v3 を導入するまで consumer の v2 はそのまま動作する。
- **片方向移行（rollback 不可）**: 移行は片方向で v2 runtime 互換は維持しない。条件付き EOL・v2 凍結・runtime 非影響・片方向移行は、「v2 を温存しつつ v3 へ一方向に移る」という移行成立の前提として相互に関係する（これらの関係性を migration.md に明示する）。

## 6. 移行コマンドの方針概要設計（実装は対象外）

`/aidlc-migrate` スキルが担う移行手順の**方針**を記述する（スクリプト実装は本サイクル対象外）。

手順方針（renewal-plan L976-983）:

1. v2 config.toml を読み、v3 config.toml を生成（キーマッピング + 不要キー警告）
2. 移行モード選択を人間に確認（new-cycle-only / best-effort / archive-only）
3. 選択に応じてデータ変換（best-effort 時は §3 マッピング適用 / new-cycle-only・archive-only は変換最小）
4. 変換結果を人間に確認（完全自動変換は目指さない）
5. state.json を初期化

> 本書はこの手順を**方針として記述する**のみで、スクリプト実装・引数仕様・終了コードは確定しない（後続フェーズ）。

## 7. 推奨移行モードと片方向移行の明記設計（まとめ）

migration.md の結論として以下を明記する:

- **推奨移行モードは new-cycle-only**（過去資産を触らない＝変換失敗リスクなし・移行コスト最小）。
- **v2 → v3 は片方向移行（rollback 不可）**。best-effort で変換した場合も v2 への巻き戻しは保証しない。
- consumer は本書の非互換点（§4）と変換マッピング（§3）から移行コストを見積もれる（NFR: 明確性）。

## 8. RFC / data-model.md との整合設計（SoT 二重定義回避 / config SoT ガード）

- **変換先 schema の SoT**: データ変換の変換先（ディレクトリ構造 / state.json / work item frontmatter）は data-model.md（Unit 003）が正本。本書は変換規則のみを定義し、schema 本体を再定義しない。各変換行に変換先正本（data-model.md §N）を併記する（§3 参照）。
- **config 変換の SoT ガード（重要）**: v3 config.toml のキー終端設計（34→8 のキー集合・命名）は RFC §6.4 と data-model.md §8 L290 が相互委譲しており、現時点でどの確定文書にも存在しない（既知の SoT ギャップ）。migration.md は config 変換について「キーマッピング方針 + 不要キー警告の挙動」のみを記述し、8 キーの具体集合を**新規定義しない**。終端 schema 未確定の事実を注記し、確定は別途（RFC §6 / data-model.md `defaults.toml` 設計）に委ねる。data-model.md §8 が確定済みの `depth_level`（保存場所/enum/既定値）のみは確定参照可。
- **コマンド名整合**: develop を正本とし build を使用しない（RFC DG-1 / workflow.md）。
- **core/extension 境界整合**: 非互換点（§4 #9/#10）は DG-5（Projects/Milestone/Release は extension・廃止）と整合する。core は extension 不在でも成立する。

## 9. 完了条件への対応（unit-004-plan.md チェックリスト）

| 完了条件 | migration.md での対応箇所 |
|---------|----------------------|
| migration.md 作成 | 成果物が migration.md のみ |
| 移行モード 3 種 + 比較表（推奨対象/前提条件/変換有無/既知リスク） | §2 |
| データ変換マッピング網羅（config/units/progress/history/release_notes）+ 変換方法明示 | §3 |
| 変換先が data-model.md 正本参照・schema 二重定義なし | §3（変換先正本列）+ §8 |
| config 変換はキーマッピング方針+不要キー警告のみ・終端 schema 新規定義なし・未確定注記 | §3 + §8 |
| 非互換点列挙 + consumer 影響明示 | §4 |
| 推奨 new-cycle-only + 理由（過去資産を触らない） | §2 + §7 |
| 片方向移行（rollback 不可）明記 | §5 + §7 |
| DG-3 引き継ぎ（EOL 3 条件/v2 非変更/runtime 非影響/片方向移行 の相互関係）方針記述 | §5 |
| 移行コスト見積もり可能な粒度（NFR: 明確性） | §3 + §4 + §7 |
| migration スクリプト実装が対象外（方針のみ）明示 | §6 |
| コマンド名 develop 整合（build 不使用） | 全節（develop 統一） |
| RFC core/extension 境界・非互換点の前提と矛盾しない | §4 + §8 |
| docs/v3 限定・コード非生成 | 成果物が migration.md のみ |
| markdownlint | Phase 2 で実行 |
