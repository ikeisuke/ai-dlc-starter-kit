# Unit 003 計画: 設計レビュー 5R 到達時の千日手・議論密度ガード強化

> **設計レビュー反映後の最終仕様**（統合レビュー Round 1 指摘 #2 反映）: 本計画書は計画段階の前提を保持しつつ、Phase 1 設計レビューおよびコードレビューで確定した最終仕様に追従する形で更新済み。最終仕様の SoT は `skills/aidlc/steps/common/review-flow.md` の独立セクション「設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）」と `design-artifacts/logical-designs/unit_003_design_review_thousand_day_guard_logical_design.md` の追記文言案ブロック。本計画書の細部表現と乖離が生じた場合は SoT 側を正とする。

## 概要

`skills/aidlc/steps/common/review-flow.md` に **独立セクション**「`## 設計レビュー特化の早期 defer ガイド`」（実装最終形では `（Unit 003 / #658 / v2.5.4+）` 注記付き）として追加する。配置位置は「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」セクションの直後、「`## レビュー完了時の共通処理`」セクションの直前（設計レビュー Round 1 で「指摘対応判断フロー内」配置案から変更確定）。

**4 系統**（Round 別指摘件数閾値 / 既存 Round 4+ 新領域 backlog 化 / 設計仮説追加検出 / 議論個別点漸進パターン検出）の予兆を判定順序通りに検出してユーザー判断（OUT_OF_SCOPE 化）を促す。発火タイミングは各 Round の `ReviewSession.is_completed()` 判定直後。適用範囲は `caller_context = 設計レビュー`（review-routing.md §3）に限定（`Phase` enum 新規定義は撤廃、caller_context 直接参照方式）。

既存の「千日手検出（過去 5R 中 3R 連続同種）」は **置き換えず**、本ガイドはその前倒しの予兆検出として位置付ける。`5R 上限`・`1R clean / last_round_clean 完了条件`・`defer 自動 Issue 起票`・`Round 4+ 新領域 backlog 化` は **完全に維持**する。

## 関連 Issue

- #658（[Backlog] 設計レビュー 5R 到達時の千日手・議論密度ガード強化）
- 関連: v2.5.3 Unit 004 review-summary（設計 5R 到達ケース）/ Round 4 新領域判定（v2.5.3 Unit 003）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 早期 defer ガイド（SoT） | Round 別閾値 / 新規仮説追加検出 / 議論個別点漸進パターン | `skills/aidlc/steps/common/review-flow.md` の「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」直後に新規 **独立セクション**「`## 設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）`」として追加（設計レビュー Round 1 指摘 #1 反映で「指摘対応判断フロー内」配置案から変更確定） |
| 既存千日手検出 | 過去 5R 中 3R 連続同種（変更なし） | 同上ファイル「指摘対応判断フロー」既存記述 |
| 既存 Round 4+ 新領域 backlog 化 | 機械判定（手順 0〜7、領域キー正規化） | 同上ファイル「Round 4 以降の新領域指摘の自動 backlog 化フロー」（変更なし） |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit03.md` |

**ドリフト防止策**:

- 適用範囲を **「Construction Phase の設計レビュー（ドメインモデル / 論理設計）に限定。Inception / Operations Phase のレビューには適用しない」** とサブセクション冒頭に明示し、共通手順内で他フェーズ副作用を防ぐ
- 既存「千日手検出（過去 5R 中 3R 連続同種）」記述を grep で再確認し、削除や縮約が起きていないことを検証
- 既存 Round 4+ 新領域 backlog 化フロー（K_old / K_new / K_diff の機械判定）と本ガイドの「新規仮説追加検出」は **対象が異なる**（既存: パス領域 / 本: 設計仮説の根本見直し）ことを文言で明示
- **判定順序・競合解決規則の明文化**（Round 1〜2 計画レビュー + 設計レビュー Round 1 を経て **4 系統** に拡張、設計レビュー Round 1 指摘 #2 で件数閾値が優先順位 1 に確定）: 設計レビューに適用される **4 系統** の同時成立時の出力責務を以下のディシジョンテーブルで一意化する:

| 優先順位 | 系統 | 起源 | 判定手段 | 記録先セクション | 排他/併記ルール |
|---------|------|------|---------|----------------|----------------|
| 1（最優先） | Round 別指摘件数閾値 | 本ガイド | 自然言語判定（件数集計） | `## Round N OUT_OF_SCOPE 推奨アラート`（Round 3）/ `## Round N 千日手予兆警告`（Round 4） | `AskUserQuestion` で「修正続行 / OUT_OF_SCOPE 化」を選択。OUT_OF_SCOPE 選択時は当該 Round の全指摘について後続 2/3/4 を **スキップ** |
| 2 | 既存 Round 4+ 新領域 backlog 化 | review-flow.md 既存セクション | 機械判定（K_old / K_new / K_diff） | `## Round 4 新領域判定`（review-summary 末尾） | 自動 Issue 起票実行。後続 3/4 系統で同一パスを検出した場合は当該パス分を **後続でスキップ**（除外） |
| 3 | 設計仮説追加検出 | 本ガイド | 自然言語判定（H_old / H_new） | `## Round N 新規仮説追加判定`（review-summary 末尾） | 1/2 で吸収済みパスを除外した残差で `AskUserQuestion` → 「修正続行 / OUT_OF_SCOPE 化」 |
| 4 | 議論個別点漸進パターン | 本ガイド | 自然言語判定（連続 round 同一ディレクトリ重複 + 修正範囲漸進） | `## Round N 漸進パターン警告`（review-summary 末尾） | 1/2/3 でカバー済みのパスは除外。残差を warn 表示のみ（Issue 起票なし、ユーザー判断は併発した 1/3 で吸収） |

review-summary への記録は **指摘単位の個別行記録は上位優先順位の 1 セクションのみ** で行い、下位系統セクションには当該指摘の個別行を生成しない。複数系統で検出された場合は別枠の集計サマリ `## Round N 早期 defer ガード吸収サマリ` セクションに「優先順位 N で吸収: <件数> 件」を 1 行ずつ記録する（設計レビュー Round 1 指摘 #3 反映で計画段階の「下位セクションに 1 行記録」案から変更確定）
- 自動判定スクリプトは導入せず、自然言語ルールとして AI レビュワー / メインエージェントが判断する（Intent 制約準拠）

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/steps/common/review-flow.md` | 改修 | 新規 **独立セクション**「`## 設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）`」を「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」直後に追加（設計レビュー Round 1 で「指摘対応判断フロー内」配置案から変更確定） |
| `.aidlc/cycles/v2.5.4/design-artifacts/domain-models/unit_003_design_review_thousand_day_guard_domain_model.md` | 新規 | 早期 defer ガイドの概念モデル（Round / Finding / Hypothesis / Pattern の関係、適用範囲、既存千日手検出との位置関係） |
| `.aidlc/cycles/v2.5.4/design-artifacts/logical-designs/unit_003_design_review_thousand_day_guard_logical_design.md` | 新規 | review-flow.md への追記文言案、サブセクション構造、検証 grep クエリ |
| `.aidlc/cycles/v2.5.4/history/construction_unit03.md` | 新規 | Unit 003 進捗履歴（変更ファイル / レビュー round / 検証結果） |

## 実装計画

### Phase 1（設計）

`depth_level=standard` 準拠 + **新規概念導入規模**（`DesignReviewSession` / `RoundFindingCount` / `Hypothesis` / `IndividualPointProgressionPattern` / `DesignReviewEarlyDeferGuardSet` 集約 / `EarlyDeferEvaluationService` の 6 概念導入。設計レビュー Round 1 指摘 #4 で `Phase` enum 新規定義は撤廃され、既存 SoT `caller_context`（review-routing.md §3）を直接参照する方針に変更確定）に対する独立分割の妥当性根拠（計画レビュー Round 1 指摘 #3 への応答）:

- Unit 005（docs only / 0.5 日 / 規則表現の書き換えのみ）は domain-models 統合形を選択
- Unit 003（1.5 日 / うち設計 0.5 日 / 新規概念 5 件 / 既存 review-flow.md の複数フローとの位置関係明示が必要）は **規模・概念数・既存ガードとの相互作用の複雑さ** を理由に独立分割を採用

ドメインモデルと論理設計を独立ファイルとして作成する:

1. **ドメインモデル**: `unit_003_design_review_thousand_day_guard_domain_model.md`
   - エンティティ: `DesignReviewSession`（既存 `ReviewSession` の subtype として扱う、`caller_context` 文字列属性を持つ）
   - 値オブジェクト: `RoundFindingCount`（Round 別指摘件数）, `Hypothesis`（指摘対象キーワード集合 H_old / H_new）, `IndividualPointProgressionPattern`（個別点漸進パターン）
   - 適用範囲ガード: 既存 SoT `caller_context`（review-routing.md §3）を直接参照する対応表（caller_context = 設計レビュー ↔ 本ガイド適用）を不変条件として固定（設計レビュー Round 1 指摘 #4 反映、Phase enum 新規定義は撤廃）
   - 既存ガード（千日手検出 / Round 4+ 新領域 backlog 化）との配置関係を概念図で示す
2. **論理設計**: `unit_003_design_review_thousand_day_guard_logical_design.md`
   - 新規 **独立セクション** の **完全な文言案**（review-flow.md に追記する markdown ブロックそのまま）
   - 配置: 「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」セクションの直後・「`## レビュー完了時の共通処理`」セクションの直前（設計レビュー Round 1 指摘 #1 反映で「指摘対応判断フロー」内配置案から変更確定。発火タイミングを各 Round の `is_completed()` 直後に独立化することで、5R 後 unresolved 限定の既存「指摘対応判断フロー」とは分離）
   - 数値閾値の根拠表（Round 3 ≥ 5 件 / Round 4 ≥ 3 件）と参考実観測（v2.5.3 Unit 004）
   - 新規仮説追加検出の手順 1〜5（H_old / H_new 抽出 → 差分判定 → AskUserQuestion → review-summary 記録）
   - **H_old / H_new 抽出の最小契約**（Round 1 review 指摘 #2 + Round 2 review 指摘 #1 反映、Intent 制約「自動判定スクリプト導入禁止 / 自然言語ルール」と両立）:
     - **抽出元セクション**: 各 Round の review-summary「指摘一覧」テーブル `内容` 列。**準用元の固定アンカー**: `skills/aidlc/steps/common/review-flow.md` § 「Round 4 以降の新領域指摘の自動 backlog 化フロー」 § 「判定手順（再現可能、固定）」 手順 0（パス記法規約）+ 手順 1（Round 1〜3 抽出）+ 手順 2（Round 4+ 抽出）のパス記法規約 / 正規表現 / warn 規則を準用する
     - **変更連動ルール**: 上記準用元の見出し名・手順番号・正規表現が変更された場合、本契約も **同 PR 内** で同時改訂すること（review-flow.md 既存フロー側の変更が本ガイドの抽出仕様に黙示的に伝播することを防ぐ）。改訂時の検証 grep: `grep -E "判定手順（再現可能、固定）|新領域指摘の自動 backlog" skills/aidlc/steps/common/review-flow.md` で準用元アンカー存在を確認
     - **キーワード語彙境界**: 「設計仮説の根本見直し」を示す名詞句に限定する。具体的には (a) ドメインモデル要素名（エンティティ / 値オブジェクト / 集約 / ドメインイベント）、(b) 責務境界に関する用語（責務 / 境界 / 役割 / レイヤ）、(c) 主要エンティティの追加削除（追加 / 削除 / 統合 / 分離）、(d) アーキテクチャ用語（依存方向 / インターフェース / 抽象化）。形容詞・副詞・修正動詞（「直す」「変える」等）は語彙境界外
     - **同義語統合ルール**: 表記揺れ（半角/全角・大小文字・送り仮名）はレビュワーが判断時に統合する。明示的な辞書は持たない（例: 「責務」と「責任」は同一語彙として扱う、「Entity」と「エンティティ」は同一として扱う）。判断の根拠は「同義語統合: `<原語>` ≒ `<統合語>`」形式で review-summary に併記
     - **判定ログ形式**: review-summary 末尾に `## Round N 新規仮説追加判定` セクションを追加し、`H_old`（Round 1〜3 で抽出された語彙集合、JSON 配列）/ `H_new`（Round 4 以降で抽出された語彙集合、JSON 配列）/ `H_new - H_old`（差分集合、JSON 配列）/ 各差分項目について「設計仮説の根本見直しか」の判定（`true` / `false` + 1 行根拠）を記録
   - 議論個別点漸進パターンの検出ガイド（指摘パスが連続 round で同一ディレクトリ内重複 + 修正範囲漸進）
   - **既存「Round 4 新領域 backlog 化」との関係明示**（対象が異なる: パス領域 vs 設計仮説）と **判定順序・競合解決規則**（責務分離原則のドリフト防止策で確定した **4 系統順序**「1. Round 別指摘件数閾値 → 2. 既存新領域判定 → 3. 仮説追加判定 → 4. 漸進パターン判定」、排他出力ルール、二重記録回避を集計サマリに集約。設計レビュー Round 1 指摘 #2 反映で 3 系統 → 4 系統に拡張、件数閾値が優先順位 1）
   - 検証 grep クエリ集（合格判定用）

### Phase 2（実装）

実装順序（設計レビュー Round 1 で配置位置を独立セクション化に変更確定後の最終版）:

1. `skills/aidlc/steps/common/review-flow.md` の「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」セクション直後・「`## レビュー完了時の共通処理`」セクション直前に新規 **独立セクション**「`## 設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）`」を追加（論理設計の追記文言案ブロックを貼り付け）
2. セクション冒頭の適用範囲（`caller_context = 設計レビュー` 限定、Phase enum なし）が記述されていることを目視確認
3. 既存「千日手検出」記述・「Round 4 以降の新領域指摘の自動 backlog 化フロー」が削除・縮約されていないことを grep で確認
4. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
5. markdownlint 実行 / 履歴記録

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 既存「千日手検出」記述が誤って削除・縮約された | grep 検証で検出し、該当箇所を復元してから再レビュー |
| 既存「Round 4 以降の新領域指摘の自動 backlog 化フロー」が誤って削除・縮約された | 同上 |
| 適用範囲（Construction Phase 設計レビュー限定）が冒頭に明記されていない | 記述追加して再レビュー（Inception / Operations 副作用防止のため必須） |
| 数値閾値（Round 3 ≥ 5 件 / Round 4 ≥ 3 件）の根拠が不明確 | logical-design で v2.5.3 Unit 004 の実観測を引用し根拠化 |
| 新規仮説追加検出の手順が自動判定スクリプトに依存（Intent 制約違反） | 自然言語ルールとして書き直し、AI レビュワー判断に委ねる |
| `review-flow.md` の本文行数が 500 行制限を超過 | 数値閾値表や手順を箇条書きで簡潔化、または Round 4+ 新領域フローと共通する境界条件を参照形式に変更 |
| markdownlint 失敗 | 該当ルール（MD013 line-length / MD031 等）を調整 |
| 既存サイクル成果物（過去履歴等）への遡及書き換え発生 | 禁止。`git diff --name-only` で `.aidlc/cycles/v2.5.4/`（本サイクル分）と `skills/aidlc/steps/common/review-flow.md` のみが変更対象であることを確認 |

## NFR

- **パフォーマンス**: docs / 手順改訂のみのためランタイム影響なし。新ガイド適用後は設計レビューが Round 3〜4 で defer 化されるケースが増え、平均所要 round が 0.5〜1 round 削減される見込み（定性的）
- **セキュリティ**: 機密情報の取り扱いに変更なし
- **後方互換**: 既存の千日手検出 / 5R 完了条件 / defer 自動 Issue 起票 / Round 4+ 新領域 backlog 化を破壊しない。新ガイドは追加扱い
- **可用性**: 影響なし
- **適用範囲**: Construction Phase 設計レビュー限定（Inception / Operations Phase は影響なし）

## 完了条件チェックリスト

### 機能要件

- [x] `skills/aidlc/steps/common/review-flow.md` に新規 **独立セクション**「`## 設計レビュー特化の早期 defer ガイド（Unit 003 / #658 / v2.5.4+）`」が「`## Round 4 以降の新領域指摘の自動 backlog 化フロー`」直後に追加されている
- [x] セクション冒頭に適用範囲「`caller_context = 設計レビュー`（review-routing.md §3）に限定、Inception / Operations / Construction コードレビュー / 統合レビューには適用しない」が明示されている
- [x] Round 別指摘件数の数値閾値が **明示的に数値で記載** されている（Round 3 で指摘 ≥ 5 件 → OUT_OF_SCOPE 化推奨アラート / Round 4 で指摘 ≥ 3 件 → 千日手予兆警告）
- [x] 新規仮説追加検出ロジックが手順番号付き（1〜5）で文書化されている（H_old / H_new 抽出 → 差分判定 → AskUserQuestion → review-summary 記録）
- [x] 議論個別点漸進パターンの検出ガイドが文書化されている（指摘対象パスが連続 round で同一ディレクトリ内重複 + 修正範囲漸進）
- [x] 既存千日手検出（過去 5R 中 3R 連続同種）との関係が明示されている（早期 defer ガイドはより前倒しの予兆検出、既存ガードは置き換えない）
- [x] **4 系統判定順序ディシジョンテーブル**（1.件数閾値 → 2.既存新領域 → 3.仮説追加 → 4.漸進）が記述されている（設計レビュー Round 1 指摘 #2 反映で 3 系統 → 4 系統に拡張）
- [x] **発火タイミング**「各 Round の `is_completed()` 判定直後」が明示されている（設計レビュー Round 1 指摘 #1 反映で「指摘対応判断フロー内」配置案から変更確定）

### Intent 成功基準（Unit 003）

- [ ] (a) `grep -E "Round 3.*defer|議論密度" skills/aidlc/steps/common/review-flow.md` で設計レビュー特化の defer ガイド記述が **1 箇所以上**
- [ ] (b) Round 別指摘件数の閾値（例: Round 3 で指摘 ≥ 5 件警告）が **明示的に数値で記載**
- [ ] (c) Round 4 以降の新規仮説追加検出ロジックが文書化

### 既存ガード仕様の維持

`grep -c` をキーワードごとに独立実行し、変更前 HEAD（基準値）と変更後で件数を比較する。基準値取得は変更前に 1 度実行して固定。

- [ ] `grep -c "5R" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -E -c "5[[:space:]]*round" skills/aidlc/steps/common/review-flow.md` の値が基準値以上（POSIX 文字クラスでスペース有無を吸収、BSD/GNU grep 両対応）
- [ ] `grep -c "千日手" skills/aidlc/steps/common/review-flow.md` の値が基準値より **増加**（既存記述維持 + 新サブセクション内での参照追加分）
- [ ] `grep -c "new-area-from-round4plus" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -c "defer 自動 Issue 起票" skills/aidlc/steps/common/review-flow.md` の値が基準値以上
- [ ] `grep -c "last_round_clean" skills/aidlc/steps/common/review-flow.md` の値が基準値以上（v2.5.4 Unit 005 の成果が破壊されていない）
- [ ] レビュー実行手順（パス 1/2/3）・スコープ保護確認・機密情報マスクには変更なし

### 適用範囲の独立性検証

- [ ] サブセクション内の手順・閾値・パターンが Construction Phase 設計レビュー以外（Inception レビュー / Operations レビュー / Construction コードレビュー / 統合レビュー）に副次的に適用されない記述になっている
- [ ] `Inception` / `Operations` Phase のレビュー記述（同ファイル内に存在する場合）に本サブセクションへの参照が混入していない

### スコープ保護

- [ ] 設定ファイル（`config.toml`）への新規キー追加なし
- [ ] レビューサマリの「指摘一覧」テーブル形式・列ガイダンスは変更なし
- [ ] 自動判定スクリプト（指摘件数を機械集計するスクリプト）は導入していない（Intent 制約準拠、自然言語ルール化）
- [ ] review-summary テンプレート（`templates/review_summary_template.md`）の構造変更なし
- [ ] `git diff --name-only` で変更対象が `skills/aidlc/steps/common/review-flow.md` / `.aidlc/cycles/v2.5.4/design-artifacts/...` / `.aidlc/cycles/v2.5.4/history/construction_unit03.md` / `.aidlc/cycles/v2.5.4/plans/unit-003-plan.md` / `.aidlc/cycles/v2.5.4/story-artifacts/units/003-*.md` / `.aidlc/cycles/v2.5.4/construction/progress.md` / `.aidlc/cycles/v2.5.4/construction/units/003-review-summary.md` のみであることを確認

### 履歴

- [ ] `.aidlc/cycles/v2.5.4/history/construction_unit03.md` が新規作成され、変更ファイル / 設計・実装レビュー round / 検証 grep 結果 / 既存ガード維持の証跡が追記されている

### 品質ゲート

- [ ] markdownlint（`markdown_lint=true` 設定）が変更対象ファイルで pass
- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（**`last_round_clean` ベース**: 直近 round が clean）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み
- [ ] `skills/aidlc/SKILL.md` の本文 500 行制限と独立に、`steps/common/review-flow.md` の本文行数が現状（304 行）から大幅増加しすぎないこと（目安 +60〜80 行以内、サブセクション追加分として妥当）

## 見積もり

- 設計フェーズ: 0.5 日（ドメインモデル + 論理設計、追記文言の確定 + grep 検証クエリ整備 + 既存ガードとの位置関係明示）
- 実装フェーズ: 1 日（review-flow.md への追記 + 既存ガード grep 検証 + lint + AI レビュー）
- 合計: **1.5 日**（Unit 定義の見積もりと一致）
