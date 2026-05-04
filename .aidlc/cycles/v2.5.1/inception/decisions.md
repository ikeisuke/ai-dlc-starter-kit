# 意思決定記録 - v2.5.1

## DR-001: サイクルテーマを「振り返りエコシステム総仕上げ」に決定

- **ステップ**: Inception 02-preparation（テーマ選定）
- **日時**: 2026-05-04

### 背景

v2.5.0 リリース直後で複数のオープン Issue（#627 / #621 / #617 / #616 / #624-622 等）から次サイクルのスコープを選定する必要があった。ユーザーは「振り返り関連を v2.5.x で完成させたい」と明確な方針を示した。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | A: #627 wizard 化のみ | 最小規模、検証集中 | 振り返りエコシステムの完成度が低い |
| 2 | B: #627 + #621 mirror Issue 重複統合 | 振り返り課題 2 主要を解消 | 規模やや大、#621 は v2.6.x 想定 |
| 3 | C: 振り返りエコシステム総仕上げ（#627 + 主因切り分け機械判定 + predecessor 自動配置 + 廃止刷新等） | v2.5.x で完成度最高、再リリース不要 | 規模大（minor 相当） |

### 決定

**C: 振り返りエコシステム総仕上げ** を採用。

### トレードオフと判断根拠

- **得たもの**: 振り返りエコシステムを v2.5.x で実用形態に到達させる完成度。次サイクル以降の派生バックログを最小化
- **犠牲にしたもの**: patch リリースとしては規模大（minor 相当のスコープ）
- **判断根拠**: ユーザーが v2.5.x 完成を明示。トレードオフスライダーは「品質: 最大 / 納期: 最小 / 予算: 小」、品質最大を優先。Construction Phase で Unit 化することで Self-Healing ループによる確実な検証が可能

---

## DR-002: #621 mirror Issue 自動重複統合 workflow を v2.5.1 から除外

- **ステップ**: Inception 03-intent（スコープ確定）
- **日時**: 2026-05-04

### 背景

DR-001 で「振り返りエコシステム総仕上げ」を決めたが、ユーザーが #621 を「今回から除外」と明示。#621 自体も Issue 本文で「v2.6.x で別サイクル」と記載されており、本サイクルでは含めない判断が合理的。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | #621 段階 1 dry-run のみ含める | 起動を v2.5.1 でも始められる | #621 本文で v2.6.x 想定の経緯と矛盾 |
| 2 | 含めない | スコープを振り返り Issue 化に集中 | 派生バックログとして残る |

### 決定

**#621 を含めない**。`OUT_OF_SCOPE` として Intent に明記。

### トレードオフと判断根拠

- **得たもの**: スコープ集中、Issue 化基盤に注力
- **犠牲にしたもの**: mirror Issue が増えた場合の手動整理負荷が当面残る
- **判断根拠**: ユーザー明示の除外指示 + Issue 本文の v2.6.x 想定。振り返り Issue 化基盤（v2.5.1）が完成してから自動重複統合（v2.6.x）が連動する順序が自然

---

## DR-003: `retrospective.md` ローカルファイルを完全廃止し、最初から Issue のみ

- **ステップ**: Inception 03-intent（predecessor 仕様確定）
- **日時**: 2026-05-05

### 背景

predecessor handoff の Issue 化を検討する中で、ユーザーが「retrospective.md を完全に廃止して、最初から Issue のみ」と明示。これは v2.5.0 設計（ローカルファイル + mirror Issue の二重保持）の方針転換となる。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 現行 mirror Issue を「次サイクルへの引き継ぎ」用途に拡張 | 既存設計の最小変更 | 二重管理は残る、cycle ブランチ削除後の参照経路が引き続き複雑 |
| 2 | predecessor 専用ラベルを新設 | 用途分離が明確 | mirror Issue と別仕様で複雑化 |
| 3 | retrospective.md を完全廃止 → Issue のみ | 単一情報源、cycle ブランチ削除後も完全参照可能 | v2.5.0 仕様との整合チェックが必要、互換性に注意 |

### 決定

**選択肢 3: retrospective.md ローカルファイル完全廃止 → Issue のみ** を採用。

### トレードオフと判断根拠

- **得たもの**: 永続化先の単一化、cycle ブランチ削除後も参照可能、ファイル/Issue 二重管理解消
- **犠牲にしたもの**: 既存 v2.5.0 ユーザーへの後方互換コスト（読み取り側互換、マイグレーション、`mirror_state` ラベル化等）
- **判断根拠**: ユーザーの強い意向。Intent §「リスク 1〜4」で互換性リスクの緩和策を MUST 要件化（スプール、`mirror_state` ラベル、読み取り fallback）

---

## DR-004: 主因分類 LLM 下書きの primary 実装は Claude Code 自身

- **ステップ**: Inception 03-intent（LLM 実装方針確定）
- **日時**: 2026-05-05

### 背景

主因分類 3 値 + `skill_caused_judgment` の機械判定をどの LLM で実装するかの方針が必要。v2.5.0 の retrospective フローは Claude Code 駆動、CI 連携は別途検討対象。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | retrospective 専用 LLM 設定を新設（GitHub Models / codex / claude） | CI 連携・ローカル両対応 | 設定軸が増え、複雑化 |
| 2 | rules.reviewing.tools をそのまま再利用 | 最小設定 | レビュー用と振り返り用の責務混同 |
| 3 | GitHub Models 固定（actions/ai-inference） | CI/ローカル統一・追加 secret 不要 | ローカル実行時の依存追加 |
| 4 | Claude Code 自身（または subagent） | AI-DLC フロー全体と整合、追加依存ゼロ | CI 環境では skip、外部実装の柔軟性は低下 |

### 決定

**選択肢 4: Claude Code 自身（または `retrospective-drafter` subagent）** を採用。

### トレードオフと判断根拠

- **得たもの**: AI-DLC フロー全体との整合、追加依存ゼロ、subagent 化でコンテキスト分離可能
- **犠牲にしたもの**: CI 環境での自動下書きは将来対応（v2.5.1 では skip）、外部 LLM への切替柔軟性は次サイクル以降
- **判断根拠**: ユーザーの「自身あるいはそのサブエージェントでいい」発言。AI-DLC は Claude Code が主軸であり、振り返りも同一エージェントで完結させる設計が自然

---

## DR-005: predecessor handoff の Issue 検索キー = closed Milestone + retrospective ラベル

- **ステップ**: Inception 03-intent（検索キー確定）
- **日時**: 2026-05-05

### 背景

retrospective.md を廃止後、新サイクル Inception 開始時に前サイクル振り返りを Issue から取得する経路が必要。検索キー設計が複数選択肢あり。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | label のみ（cycle:vX.X.X） | milestone_enabled=false でも動く | Issue 量が増えると複数ヒットしやすい |
| 2 | closed Milestone + retrospective ラベル AND | 検索精度高、v2.5.0 Milestone 自動作成基盤を再利用 | milestone_enabled=false 環境で fallback 必要 |
| 3 | 全文検索 | 柔軟性高 | 精度低、誤検出リスク |

### 決定

**選択肢 2: closed Milestone + retrospective ラベル AND 検索**（`milestone_enabled=false` 環境では label のみ fallback）。

### トレードオフと判断根拠

- **得たもの**: 高い検索精度、既存 v2.4.0 Milestone 自動作成基盤の再利用、実装コスト最小
- **犠牲にしたもの**: milestone_enabled=false 環境での fallback 経路が必要
- **判断根拠**: 既存基盤を活用、ダウンストリーム互換のため fallback も担保

---

## DR-006: feedback_mode マイグレーション写像（破壊的動作変更の防止）

- **ステップ**: Inception 03-intent（Codex レビュー反映）
- **日時**: 2026-05-05

### 背景

Intent 初版で `silent` → `local-issue-only` を写像案としていたが、Codex レビューで「v2.5.0 silent は記録のみ、新値は Issue 起票あり、自動昇格は破壊的」と指摘。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | silent → local-issue-only 自動昇格 | マイグレーションの 1 命令が単純 | 知らないうちに Issue 起票が始まる、破壊的 |
| 2 | silent-legacy 互換モードを 1 リリース残す | 完全な動作互換 | 設定軸が増え、技術負債が残る |
| 3 | silent → interactive ＋同意プロンプト必須 | 動作変更を明示同意で行う、非対話時は disabled fallback | マイグレーション処理が wizard 統合される複雑化 |

### 決定

**選択肢 3: silent → interactive ＋同意プロンプト必須**（非対話環境では disabled fallback）。

### トレードオフと判断根拠

- **得たもの**: 破壊的動作変更を排除、ユーザー認知負荷を下げ、CI 環境での安全性を担保
- **犠牲にしたもの**: マイグレーション処理に対話フローが入り、非対話処理パスが複雑化
- **判断根拠**: Codex レビューの妥当指摘 + ユーザー保護優先。`disabled` fallback で非対話環境を保護できれば動作変更を完全に止められる

---

## DR-007: feedback_max_per_cycle はモード横断の合算上限を共有

- **ステップ**: Inception 03-intent（Codex レビュー #5 反映）
- **日時**: 2026-05-05

### 背景

`feedback_mode` 5 値拡張に伴い、`feedback_max_per_cycle = 3` の cap を新モード（特に `local-and-mirror`）でどう適用するかを定義する必要があった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 各モードに独立した cap を持つ（個別カウンタ） | モード切替時の干渉なし | local-and-mirror で実質 cap が 2 倍化、過剰起票リスク |
| 2 | モード横断で 1 つの cap を共有（合算上限） | 過剰起票抑制、設計シンプル | モード切替時のカウンタリセット仕様要検討 |

### 決定

**選択肢 2: モード横断で 1 つの cap を共有（合算上限）** を採用。

### トレードオフと判断根拠

- **得たもの**: 過剰起票抑制の意図に合致、設計シンプル、v2.5.0 の `feedback_max_per_cycle = 3` を変更せず維持できる
- **犠牲にしたもの**: モード切替時のカウンタ仕様を Construction で詳細設計
- **判断根拠**: cap の本質は「振り返りでの過剰起票を防ぐ」ものなので、起票先が増えても合算で抑制するのが意図に合致

---

## DR-008: 共有契約を Intent §「判断 6」として一元化、04-completion §1.5 編集主体は Unit 002

- **ステップ**: Inception 04-stories-units（Codex Unit レビュー #1, #3 反映）
- **日時**: 2026-05-05

### 背景

Codex の Unit 定義レビューで「Unit 001 と Unit 002 で 04-completion §1.5 改修責務が二重化」「Unit 002 と Unit 004 で命名規約の正本が暗黙」と指摘。複数 Unit から参照される命名規約・データ契約・編集主体の正本確定が必要だった。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | Unit 002 を「正本」として他 Unit が追従 | 1 Unit に集中 | 暗黙仕様化、Unit 004 が「追従」する構造的弱さ |
| 2 | shared constants ファイルを別途作成 | 仕様の独立性 | ファイルが分散、参照経路が増える |
| 3 | Intent §「判断 6: 共有契約」として一元化 | 既存 Intent 構造との整合、一覧性高 | Intent が肥大化 |

### 決定

**選択肢 3: Intent §「判断 6: 共有契約」として一元化**。各 Unit 定義はここを正本として参照する形。04-completion §1.5 編集主体は Unit 002 に固定（§「判断 6.5」）。

### トレードオフと判断根拠

- **得たもの**: 命名規約・データ契約・編集主体の正本が一元化、Unit 間責務境界が明確、検証時の参照経路が短い
- **犠牲にしたもの**: Intent §「主要設計判断」セクションが肥大化（4 → 6 判断）
- **判断根拠**: AI-DLC の Inception 成果物として Intent が「決定の正本」を担うのが自然。Unit 定義はそれを参照する設計が読み手にも親切

---

## DR-009: Unit 001 wizard 対話手段を AskUserQuestion ではなく `read -p` に固定

- **ステップ**: Construction Unit 001 設計レビュー（指摘 #6 への対応）
- **日時**: 2026-05-05

### 背景

設計初期は AskUserQuestion 連携を含む形を検討したが、Codex 設計レビューで「AskUserQuestion 依存と read -p 案が混在し、対話レイヤー責務が揺れている」と指摘された。bash スクリプトから AskUserQuestion を直接呼ぶ手段がない。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | 純シェル対話（`read -p`）で完結 | 既存 v2.5.0 対話パターンと整合、shell 単独完結 | UI が素朴 |
| 2 | エージェント側で AskUserQuestion を起動 → 環境変数経由で結果受渡 | リッチ UI | bash 単体テスト困難、責務混在 |
| 3 | Claude Code 経由のみ AskUserQuestion、CLI 単体は read -p | 両対応 | 二重実装 |

### 決定

**選択肢 1: 純シェル対話（`read -p`）で完結**を Unit 001 範囲に固定。Claude Code 経由の AskUserQuestion 連携は将来の拡張（本サイクル外）。

### トレードオフと判断根拠

- **得たもの**: 対話レイヤー責務が単一に確定 / shell スクリプト単独で実行可能 / BATS テスト可能（AIDLC_FORCE_INTERACTIVE で tty バイパス）
- **犠牲にしたもの**: AskUserQuestion のリッチ UI（数値選択メニューと比べて少しシンプル）
- **判断根拠**: bash から AskUserQuestion を呼べない以上、二択（責務混在を許容するか単一化するか）。レビュー指摘の解消優先で単一化を採用

---

## DR-010: Unit 001 マイグレーション適用経路を manifest 拡張（resource_type=feedback_mode_migrate）に固定

- **ステップ**: Construction Unit 001 設計レビュー（指摘 #4 への対応）
- **日時**: 2026-05-05

### 背景

設計初期は migrate-feedback-mode.sh が直接書込みする独立フローも候補だったが、レビューで「manifest 拡張 vs 独立フロー が未確定 / responsibility boundary 曖昧」と指摘。

### 選択肢

| # | 選択肢 | メリット | デメリット |
|---|--------|---------|-----------|
| 1 | manifest 拡張（resource_type=feedback_mode_migrate） | 既存 aidlc-migrate の 3 層構造（detect / apply / cleanup）と整合、書込責務が migrate-apply-config.sh に集約 | manifest スキーマ拡張が必要 |
| 2 | 独立フロー（migrate-feedback-mode.sh が write-config.sh を直接呼出） | シンプル | aidlc-migrate のトランザクション境界（バックアップ/rollback）外で書込が発生、責務分散 |

### 決定

**選択肢 1: manifest 拡張**。`migrate-feedback-mode.sh` は decide 層（旧値検出 + 同意取得 + manifest 積み込み）に限定。実書込みは `migrate-apply-config.sh` が manifest 経由で行う。バックアップ / rollback は上位 aidlc-migrate の既存責務を再利用。

### トレードオフと判断根拠

- **得たもの**: 3 層責務分離（decide / apply / backup-rollback）が明確 / 既存 rollback 経路を再利用 / 書込失敗時 exit 1 伝播で上位 rollback が発火する単一経路
- **犠牲にしたもの**: manifest スキーマに新 resource_type を追加する必要
- **判断根拠**: 既存 v2.0.x の migrate スクリプト群と同じパターンを踏襲することで、マイグレーション全体の挙動が一貫する。書込失敗 → rollback の経路を一本化することで失敗時の状態遷移が機械的に検証可能になる
