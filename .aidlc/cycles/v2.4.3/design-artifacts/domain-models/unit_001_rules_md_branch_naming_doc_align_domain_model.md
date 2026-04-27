# ドメインモデル: rules.md ブランチ運用文言の実装整合（Unit 001）

## 概要

ダウンストリーム消費プロジェクトおよびスターターキット自身（メタ開発リポジトリ）で使用される **ブランチ命名ポリシー** をドキュメントレベルで整理し、用途と命名の対応関係を読者が誤読なく把握できるようにする。

**重要**: 本ドメインモデルでは**コードは書かず**、ブランチ命名ポリシーの概念モデル（用途・命名・作成主体・削除契機の対応）のみを定義する。

## エンティティ（Entity）

### `BranchNamingPolicyEntry`

ブランチ命名と用途の対応関係を表す概念単位。`.aidlc/rules.md` の対比節および `bin/post-merge-sync.sh` の削除対象パターンが参照する論理的な単位。

- **ID**: 命名パターン（例: `cycle/vX.X.X`）
- **属性**:
  - `pattern`: string — ブランチ命名パターン（glob 形式 / 具象例）
  - `purpose`: enum — 用途分類（`release` / `downstream-upgrade` / `downstream-migration` / `legacy`）
  - `createdBy`: enum — 作成主体（`developer` / `aidlc-setup` / `aidlc-migrate` / `none`）。`none` は `purpose=legacy` のときのみ取り得る
  - `deletionTrigger`: enum — 削除契機（`post-merge-sync` / `aidlc-setup-followup` / `aidlc-migrate-followup` / `none`）
  - `applicableContext`: enum — 適用文脈（`starter-kit-self` / `downstream-consumer` / `both`）
- **振る舞い**:
  - `isCurrentlyCreated()`: 現在のスキル実装が新規にこのブランチを作成するか（`legacy` は false）
  - `isInPostMergeSyncScope()`: `bin/post-merge-sync.sh` のマージ済み削除対象に含まれるか

## 値オブジェクト（Value Object）

### `BranchPattern`

ブランチ命名のパターン文字列（glob 形式）を表す値。

- **属性**: `value: string`
- **不変性**: パターン文字列は変更されない。新しいパターンが必要な場合は別の `BranchPattern` を生成する
- **等価性**: 文字列値の完全一致

## 集約（Aggregate）

### `BranchNamingPolicy`

`BranchNamingPolicyEntry` の集合体で、`.aidlc/rules.md` の「ブランチ命名と用途対比」節が参照する論理的な集約。

- **集約ルート**: `BranchNamingPolicy`
- **含まれる要素**: `BranchNamingPolicyEntry` のリスト
- **境界**: 本サイクル時点で稼働しているスキル実装が作成する（または過去に作成した）すべての命名パターン
- **不変条件**:
  - `purpose=release` のエントリは `applicableContext=starter-kit-self` 限定
  - `purpose=downstream-upgrade` / `downstream-migration` のエントリは `applicableContext=downstream-consumer` 限定
  - `purpose=legacy` のエントリは `isCurrentlyCreated()=false` でなければならない
  - 同一 `pattern` のエントリは集約内で一意

## 現サイクル時点のエントリ一覧

集約の不変条件を満たす具体的なインスタンス。本ユニットの実装（`.aidlc/rules.md` の対比節）はこのリストを反映する。

| pattern | purpose | createdBy | deletionTrigger | applicableContext | 備考 |
|---------|---------|-----------|-----------------|-------------------|------|
| `cycle/vX.X.X` | release | developer | post-merge-sync | starter-kit-self | スターターキット自身のサイクル開発・リリース用 |
| `chore/aidlc-v<version>-upgrade` | downstream-upgrade | aidlc-setup | aidlc-setup-followup | downstream-consumer | `aidlc-setup` のアップグレードフロー（ケースC）が作成する一時ブランチ |
| `aidlc-migrate/v2` | downstream-migration | aidlc-migrate | aidlc-migrate-followup | downstream-consumer | `aidlc-migrate` の v1→v2 マイグレーション専用ブランチ |
| `upgrade/v*` | legacy | none（現スキルは作成しない） | post-merge-sync | downstream-consumer | 過去サイクル名残。`bin/post-merge-sync.sh` の安全制約として削除対象に残置 |

## ドメインサービス

### `BranchNamingDocumentationService`

`BranchNamingPolicy` 集約を `.aidlc/rules.md` の対比節（Markdown 表形式）にレンダリングするサービス。

- **責務**: 集約の状態を読者向けの対比表として可視化し、用途の混同を抑止する
- **操作**:
  - `renderPolicyTable()` — 対比表を Markdown 形式で生成する論理的な操作（実装としては rules.md への手書き反映）

## ユビキタス言語

`.aidlc/rules.md` および本 Unit の文書群で使用する共通用語:

- **ダウンストリーム消費プロジェクト（downstream consumer）**: AI-DLC Starter Kit を依存として取り込んでいるプロジェクト。`aidlc-setup` / `aidlc-migrate` は主にこの文脈で実行される
- **スターターキット自身（starter kit self）**: AI-DLC Starter Kit 本体（`ikeisuke/ai-dlc-starter-kit`）のメタ開発リポジトリ。サイクル開発・リリースは `cycle/vX.X.X` で行う
- **アップグレードフロー（upgrade flow / ケースC）**: `aidlc-setup` がダウンストリーム側の `starter_kit_version` 不一致を検出した際のフロー。`chore/aidlc-v<version>-upgrade` ブランチを作成する
- **マイグレーションフロー（migration flow）**: `aidlc-migrate` が v1→v2 への構造変換を実施するフロー。`aidlc-migrate/v2` 固定ブランチを作成する
- **過去サイクル名残（legacy residue）**: 過去サイクルで `upgrade/v*` 命名で作成された既存ブランチ。新規作成はされないが、`bin/post-merge-sync.sh` の削除対象に残置されている
- **`BranchNamingPolicyEntry`**: ブランチ命名 1 エントリの論理単位（本ドメインモデルのエンティティ）

## 不明点と質問

[Question] aidlc-migrate の `aidlc-migrate/v2` 固定ブランチを対比節に含めるべきか
[Answer] 含める。grep 結果（`skills/aidlc-migrate/scripts/`, `skills/aidlc-migrate/steps/`）で実装が `aidlc-migrate/v2` 固定で稼働しており、ダウンストリーム消費プロジェクトでは `cycle/vX.X.X` / `chore/aidlc-v<version>-upgrade` / `aidlc-migrate/v2` の 3 種が共存し得る。対比節の網羅性のため明示する

[Question] 対比節挿入位置 (a)/(b) の選択
[Answer] (a) を採用。「Worktree 運用ルール」セクション全体の冒頭に対比節を置くことで、読者が「ブランチ運用フロー」サブセクションを読む前に用途分類を把握できる。読み順として誤読を最も早期に抑止する

[Question] L298 の文言整合は L298-A / L298-B のどちらか
[Answer] L298-A（post-merge-sync.sh は修正しない、過去サイクル名残として `upgrade/*` の安全範囲を残す注記のみ）。理由: (1) `chore/aidlc-v*-upgrade` は `aidlc-setup` ステップ §10 で対話的に削除されるため重複対応となる、(2) Unit 定義「境界: post-merge-sync.sh の対応プレフィックス追加は最小限」に従い、必要不可欠でなければ追加しない

[Question] aidlc-setup / aidlc-migrate SKILL.md への追記は必要か
[Answer] 不要。grep 結果で SKILL.md にブランチ命名に関する記述は無く（概要レベルに留まる）、詳細はステップファイル（`steps/`配下）に記述済み。`.aidlc/rules.md` 対比節での網羅で十分。SKILL.md への追記は本サイクルのスコープから外す

[Question] aidlc-setup / aidlc-migrate の steps/ 配下への追記は必要か
[Answer] 不要。`skills/aidlc-setup/steps/03-migrate.md` および `skills/aidlc-migrate/steps/{01-preflight.md, 03-verify.md}` は既に各々の命名理由・用途を文脈付きで明示しており、`.aidlc/rules.md` 対比節と重複する形での追加文言は冗長。grep 検証で残存違反がないことのみ確認する
