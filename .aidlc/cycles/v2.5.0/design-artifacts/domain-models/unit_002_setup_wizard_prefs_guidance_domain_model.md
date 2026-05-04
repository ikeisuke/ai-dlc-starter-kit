# ドメインモデル: Unit 002 aidlc-setup ウィザードの個人好み推奨案内

## 概要

`aidlc-setup` の対話フロー内で「個人好みは `~/.aidlc/config.toml`（user-global）に書くことを推奨」する**案内テキスト（GuidanceMessage）**を、4 階層設定システム（Unit 001 で確立）の設計意図とともに新規セットアップユーザーに伝達するドメインモデル。本 Unit は markdown-driven な aidlc-setup スキルへ「指示文（Instruction）」を追加することで、LLM が解釈実行する案内表示の振る舞いを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

## エンティティ（Entity）

### GuidanceMessage

新規セットアップユーザーに表示する**案内テキスト**を表すエンティティ。markdown ステップファイル内に 1 回だけ定義され、LLM が解釈実行時にユーザー向けコンソール出力として再現する。

- **ID**: `stable_id` — 文言・見出しに依存しない**安定識別子**。markdown 内には HTML コメントアンカー（例: `<!-- guidance:id=unit002-user-global -->`）として埋め込み、Unit 003 など外部からの参照キーとなる
- **属性**:
  - `stable_id`: String — 例: `unit002-user-global`
  - `section_anchor`: String — markdown 内の見出しアンカー（例: `## 9b. 個人好み user-global 推奨案内`）。**人間可読の表示用ラベル**であり、安定 ID ではない（文言変更時にも stable_id が一意性を維持する）
  - `host_step_file`: Path — 案内が定義されているステップファイル（本 Unit では `skills/aidlc-setup/steps/03-migrate.md`）
  - `position_constraint`: PositionConstraint — 配置位置制約（後述の値オブジェクト）
  - `body_elements`: List<GuidanceElement> — 本文要素（タイトル / 説明 / キー例示 / コード例 / 注記）
  - `applicable_setup_path`: SetupPath — 表示対象モード（本 Unit では `InitialSetup` のみ）
  - `automation_mode_policy`: AutomationModePolicy — automation_mode 全モード対応指示の有無
- **振る舞い**:
  - `is_singly_defined()`: Boolean — 同一案内本文が host_step_file 全体で 1 回のみ定義されているか
  - `references_canonical_keys()`: Boolean — Unit 001 正規 7 キーから代表 3 キーを正しく参照しているか
  - `documents_stderr_routing()`: Boolean — 非対話モード時の stderr 出力指示が含まれるか

### GuidanceElement

GuidanceMessage の本文を構成する要素エンティティ。LLM の表示時に各要素が**意味を保ったまま再現**される必要がある。

- **ID**: `(message_id, element_kind)` の複合キー
- **属性**:
  - `message_id`: String — 親 GuidanceMessage の stable_id
  - `element_kind`: ElementKind — `Title` / `LayerHierarchyOverview` / `KeyExamples` / `UserGlobalCodeSnippet` / `TeamImpactNote` / `ModeApplicabilityNote` / `StderrRoutingNote` / `IdempotencyNote`
  - `content`: String — markdown 文字列
  - `semantic_requirements`: List<SemanticRequirement> — 本要素が満たすべき**抽象的な意味要件**（例: `KeyExamples` 要素なら「Unit 001 正規 7 キーから代表 3 キー（reviewing.mode / automation.mode / linting.enabled）が言及されていること」）。具体的な検証トークン文字列やマッチ方式は論理設計／テスト設計層に委譲する
- **振る舞い**:
  - `satisfies_semantic_requirements()`: Boolean — 全 semantic_requirements が content によって意味的に満たされるか

### SetupStepFile

`aidlc-setup` の各ステップファイル（markdown）を表すエンティティ。LLM が順次解釈実行する指示集合のホスト。

- **ID**: `path`
- **属性**:
  - `path`: Path — 例: `skills/aidlc-setup/steps/03-migrate.md`
  - `sections`: List<MarkdownSection> — `##` プレフィックス 見出しで区切られたセクション
- **振る舞い**:
  - `find_section_by_anchor(anchor: String)`: MarkdownSection? — アンカーで検索
  - `assert_section_position(target: String, after: String, before: String)`: Boolean — 位置制約検証（観点 A2）

## 値オブジェクト（Value Object）

### PositionConstraint

GuidanceMessage の配置位置制約を表す不変値オブジェクト。

- **属性**:
  - `host_file`: Path
  - `after_section_anchor`: String — このセクションの後に配置（本 Unit では `## 9. Git コミット`）
  - `before_section_anchor`: String — このセクションの前に配置（本 Unit では `## 10. 完了メッセージと次のステップ`）
- **不変条件**:
  - `host_file` 内で `after_section_anchor` < target_anchor < `before_section_anchor` の行番号順序

### SetupPath

`aidlc-setup` のモード分岐経路を表す列挙型。

- **値**: `InitialSetup` / `Migration` / `Upgrade`
- **本 Unit のスコープ**: `InitialSetup` のみで GuidanceMessage を表示。他経路では非表示

### AutomationModePolicy

initial setup 経路における automation_mode 対応方針を表す不変値オブジェクト。

- **属性**:
  - `applies_within`: SetupPath — このポリシーが適用される経路（本 Unit では `InitialSetup`）
  - `covered_modes`: Set<AutomationMode> — `{Manual, SemiAuto, FullAuto}` 全モード
  - `skip_behavior`: SkipBehavior — `NeverSkip`（initial setup 経路に入った場合は automation_mode によらず案内を表示）
- **不変条件**:
  - covered_modes は automation_mode の全列挙値を含む
  - applies_within は SetupPath の単一値（`InitialSetup`）に限定

### AutomationMode

`automation_mode` の取り得る値を表す列挙型。

- **値**: `Manual` / `SemiAuto` / `FullAuto`
- **由来**: `.aidlc/config.toml` の `[rules.automation] mode` キー（Unit 001 で defaults.toml に集約済み）

### ElementKind

GuidanceElement の種類を表す列挙型。

- **値**:
  - `Title` — 案内タイトル（`## 9b. 個人好み user-global 推奨案内`）
  - `LayerHierarchyOverview` — 4 階層マージ仕様の 1 行説明
  - `KeyExamples` — 代表 3 キーの例示
  - `UserGlobalCodeSnippet` — `~/.aidlc/config.toml` への記述例コードブロック
  - `TeamImpactNote` — project 共有に書くとチームに反映される旨の注記
  - `ModeApplicabilityNote` — 「初回セットアップ経路 + automation_mode 全モード対応」のスコープ注記
  - `StderrRoutingNote` — 非対話モード時の stderr 出力指示
  - `IdempotencyNote` — 1 回のみ表示する旨の冪等性指示

### LayerKind / IndividualPreferenceKey

Unit 001 で定義済みの値オブジェクトを参照する。本 Unit では新規定義しない。

- `LayerKind` ∈ `{Defaults, UserGlobal, ProjectShared, ProjectLocal}` — 4 階層
- `IndividualPreferenceKey` — 個人好み 7 キー集合（user_stories.md ストーリー 1 / Unit 001 正規定義）

## ドメインサービス（Domain Service）

### GuidanceTemplateService

GuidanceMessage の生成・配置・検証を担うドメインサービス。本 Unit では markdown 静的構造の検証ロジックを概念モデルとして定義し、実装は bats テストヘルパに反映する（具象クラスは作らない）。

- **責務**:
  - host_step_file 内に GuidanceMessage を 1 回のみ配置する（冪等性保証）
  - PositionConstraint を満たす位置への挿入を検証する
  - 必須 GuidanceElement（各要素の `semantic_requirements` を満たす）が全て揃っているかを検証する（具体トークン展開は論理設計／テスト設計層）
  - 同一本文が `01-detect.md` / `02-generate-config.md` に重複定義されていないことを検証する（単一ソース原則）

### GuidanceVisibilityResolver

LLM が aidlc-setup を実行する際、現在の SetupPath と AutomationMode から GuidanceMessage を表示すべきか判定する概念サービス。markdown 内の指示文として表現される（具象クラスは作らない）。

- **責務**:
  - 現在の SetupPath が `InitialSetup` の場合のみ表示
  - SetupPath = InitialSetup のとき、AutomationMode によらず表示（NeverSkip）
  - 出力先は AutomationMode が `Manual` のときは標準のコンソール出力、`SemiAuto` / `FullAuto`（およびフォワード互換の `--non-interactive`）のときは stderr リダイレクト推奨

## 集約（Aggregate）

### SetupGuidanceAggregate

SetupStepFile（`03-migrate.md`）をルートに、その内部の GuidanceMessage と関連 GuidanceElement を凝集する集約。markdown 物理ファイルが集約整合性の境界。

- **集約ルート**: SetupStepFile（`03-migrate.md`）
- **メンバー**:
  - GuidanceMessage（1 件）
  - GuidanceElement（複数件、ElementKind ごと）
  - PositionConstraint（GuidanceMessage に紐づく値オブジェクト）
- **不変条件**:
  - GuidanceMessage は集約内で 1 回のみ存在
  - PositionConstraint の after/before 制約が host_file 内で成立
  - 必須 ElementKind（`Title` / `LayerHierarchyOverview` / `KeyExamples` / `UserGlobalCodeSnippet` / `ModeApplicabilityNote` / `StderrRoutingNote` / `IdempotencyNote`）が全て存在
- **集約境界外との関係**:
  - 他のステップファイル（`01-detect.md` / `02-generate-config.md`）には案内の重複が無いことを単一ソース原則として保証
  - Unit 001 の正規 7 キー集合（IndividualPreferenceKey）は read-only 参照
  - Unit 003（aidlc-migrate）は本集約ルートへの**実装ソース参照**のみで案内を再表示する（本文コピー禁止）

## リポジトリインターフェース

本 Unit は markdown-driven なドキュメント変更が中心であり、ランタイムでの永続化リポジトリは存在しない。**実装非対象**として空に保つ。

## 参考概念（実装非対象）

### IndividualPreferenceKeyCatalog（Unit 001 から継続）

Unit 001 で定義した正規 7 キー集合の単一ソース概念。本 Unit では `KeyExamples` GuidanceElement の `semantic_requirements`（代表 3 キーを言及する）の出処として参照のみ。具体トークン（`rules.reviewing.mode` など）への展開は論理設計／テスト設計層が担う。

### GuidanceMessageRegistry

将来サイクルで案内テキストが複数 Unit にまたがる場合、SetupStepFile 横断の重複検出機構を導入する候補概念。本 Unit では「`03-migrate.md` 単一ファイル定義 + `01-detect.md` / `02-generate-config.md` の grep 検査」で代替する。

## ドメインモデル図（テキスト）

```text
SetupGuidanceAggregate (root: SetupStepFile = 03-migrate.md)
├─ GuidanceMessage (stable_id = "unit002-user-global")
│  ├─ PositionConstraint (after = "## 9.", before = "## 10.")
│  ├─ AutomationModePolicy (applies_within = InitialSetup, covered = {Manual, SemiAuto, FullAuto}, skip = NeverSkip)
│  └─ GuidanceElement[]
│     ├─ Title (semantic: 見出しが GuidanceMessage の役割を表現する)
│     ├─ LayerHierarchyOverview (semantic: 4 階層マージ仕様の概念を伝達する)
│     ├─ KeyExamples (semantic: Unit 001 正規 7 キーから代表 3 キーを言及する)
│     ├─ UserGlobalCodeSnippet (semantic: ~/.aidlc/config.toml への記述例を提示する)
│     ├─ TeamImpactNote (semantic: project 共有がチーム全体に反映される旨を注意喚起する)
│     ├─ ModeApplicabilityNote (semantic: 初回セットアップ経路かつ automation_mode 全モードで表示される旨を明示する)
│     ├─ StderrRoutingNote (semantic: 非対話モード時の stderr ルーティング指示を含む / フォワード互換として --non-interactive に言及する)
│     └─ IdempotencyNote (semantic: 1 回のみ表示する旨の冪等性指示を含む)

外部参照:
- IndividualPreferenceKey (Unit 001 から read-only)
- LayerKind (Unit 001 から read-only)

外部公開契約:
- GuidanceMessage.stable_id を Unit 003（aidlc-migrate）の参照キーとして公開する
  （見出し文言ではなく安定 ID で結合し、文言変更耐性を持つ）
```

## 設計判断

| 論点 | 判断 | 根拠 |
|------|------|------|
| GuidanceMessage の配置先 | `03-migrate.md` の `## 9b` 位置 | 「生成サマリ表示直前」AC を満たし、`## 9. Git コミット` 直後に配置することで初回セットアップ完了直前のタイミングで自然に案内できる |
| GuidanceElement の細分化 | ElementKind を 8 種類に分類 | bats 静的検証で「どの要素が抜けたか」を粒度高く検出するため。各要素の `semantic_requirements` を論理設計層で具体トークンに展開し、観点 A〜D の検証として網羅性を担保する |
| AutomationModePolicy のスコープ | InitialSetup 経路の内部に限定 | 「アップグレード／移行で再表示しない」というモード限定原則と、「automation_mode によらず表示する」という実動作保証の**直交関係**を不変条件で表現 |
| stderr 出力の扱い | StderrRoutingNote として Element 化 | AC「`--non-interactive` でもログ記録」を markdown 上の指示文で実動作保証する根拠を、要素単位で検証可能にするため |
| Unit 003 との結合 | 実装ソース（`03-migrate.md` 内の **stable_id** `unit002-user-global`）を単一ソースとし、Unit 003 は安定 ID で参照のみ | 計画書ベースではなく実装資産ベース、かつ見出し文言ではなく安定 ID で結合することで、計画書改訂・案内文言変更の双方からデカップリングする（境界明確化 + 文言変更耐性） |
