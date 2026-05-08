# 論理設計: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加

## 概要

`skills/aidlc/steps/operations/04-completion.md` のステップ 3（バージョンタグ付け）に「リモート CI 自動 tag 競合確認」セクションを差し込み、`TagConflictDetector` / `FallbackResolver` / `UserDecisionService` のドメインサービスを **文書化形態で** 表現する。実装は markdown 追記のみで完結し、bats テスト・config 構造変更は伴わない（Unit 境界）。

**重要**: この論理設計では**コードは書かず**、文書追加の構造・挿入位置・検証手段の定義のみを行います。具体的な markdown 文言は Phase 2 で確定します。

## アーキテクチャパターン

**文書追加型ドキュメント駆動**（既存の Operations Phase 04-completion.md ステップ 3 内に判定マトリクス + fallback 手順を埋め込む）。コード実装層は持たず、`git ls-remote` / `git fetch` / `git rev-parse` の標準 git 仕様を直接呼び出す手順書として表現する。3 ケース判定の論理は markdown table の構造そのものに埋め込み、人間が手順実行時に分岐判断する。

## コンポーネント構成

### レイヤー構成

```text
skills/aidlc/steps/operations/04-completion.md（単一ファイル改修）
└── ステップ 3（バージョンタグ付け）
    ├── 設定確認（既存: version_tag = false/true 分岐）           # 不変
    ├── version_tag = false 経路（既存: スキップ）                # 不変
    └── version_tag = true 経路
        ├── 【新規】事前確認: git ls-remote --tags origin vX.X.X  # 責務 1
        ├── 【新規】判定マトリクス（3 ケース × 4 列以上）           # 責務 2
        │   ├── ケース A: 不在（既存手順への合流）
        │   ├── ケース B: 同 SHA 衝突（fallback 手順 §1 参照）
        │   └── ケース C: 異 SHA 衝突（fallback 手順 §2 参照）
        ├── 【新規】fallback 手順 §1: 同 SHA 衝突（3 項目）         # 責務 3
        │   ├── 1. ローカル tag 削除（git tag -d）
        │   ├── 2. リモート版取得（git fetch origin tag）
        │   └── 3. 同期検証（git show）
        ├── 【新規】fallback 手順 §2: 異 SHA 衝突（3 項目）         # 責務 4
        │   ├── 1. 自動 push 中止
        │   ├── 2. 差分提示（双方向 git log）
        │   └── 3. ユーザー選択肢提示
        │       ├── (i) リモート優先（推奨）
        │       ├── (ii) ローカル優先（破壊的・明示確認必須）
        │       └── (iii) 中断（Operations Phase 中断 → 調査）
        ├── 既存: git tag -a + git push origin vX.X.X            # 不変（ケース A から合流）
        └── 既存: GitHub Release 作成（オプション）                # 不変
```

### コンポーネント詳細

#### 事前確認手順（責務 1）

- **配置**: `version_tag = true` 経路の **冒頭**（既存 `git tag -a` の前）
- **挿入境界**: `git pull origin main` 完了後、`git tag -a` 開始前
- **役割**: 以下 3 値の取得（`TagConflictDetector` の入力データ収集）
  1. `RemoteTagPresence`: `git ls-remote --tags origin vX.X.X`（存在検出のみ）
  2. `RemoteTagCommitSha`: `git ls-remote origin "refs/tags/vX.X.X^{}"` の第 1 列（**peeled commit SHA** / annotated tag に対する誤分類防止 / Round 1 指摘 #1 対応）。出力空かつ手順 1 が非空なら lightweight tag と判断し手順 1 の SHA をそのまま採用
  3. `LocalMergeCommitSha`: `git rev-parse HEAD`
- **失敗時の扱い**: ネットワーク失敗等は既存の `git push` 失敗時と同等の挙動（手順実行者が再試行 / 手動介入を判断）

#### 判定マトリクス（責務 2）

- **形式**: markdown table（GFM）
- **列構造**（4 列固定）:

  | 列名 | 内容 | 例 |
  |------|------|----|
  | ケース名 | A / B / C と短いラベル | ケース B: 同 SHA 衝突 |
  | 検出コマンド出力 | `git ls-remote --tags origin vX.X.X` の期待 stdout 形 | `<sha> refs/tags/vX.X.X`（マージコミット SHA と一致） |
  | 期待結果 / 動作 | 観測された状態の解釈 | CI 側が先に作成済み。最終 SHA が同じなのでリモート版が正規 |
  | 次アクション | 進むべき経路 | 同 SHA fallback でローカル同期 |

- **3 行固定**: A（不在）/ B（同 SHA 衝突）/ C（異 SHA 衝突）。順序固定
- **SHA 比較規則**（Round 1 指摘 #1 対応）: 比較対象は **peeled commit SHA 同士**。`git ls-remote origin "refs/tags/vX.X.X^{}"` で取得した `RemoteTagCommitSha`（40 文字 full SHA、annotated tag でも commit SHA を返す）と `git rev-parse HEAD` の `LocalMergeCommitSha`（同じく 40 文字 full SHA）を **文字列完全一致** で判定する。tag object SHA（`git ls-remote --tags` の素の出力）とコミット SHA を直接比較してはならない（誤分類防止）。短縮 SHA / 部分一致は使わない（不変条件）

#### fallback 手順 §1: 同 SHA 衝突（責務 3）

- **配置**: 判定マトリクスの直後（責務 2 の後ろ）
- **項目構造**: 番号付きリスト 3 項目（順序固定）
- **論理ステップ**:
  1. ローカル tag 削除: `git tag -d vX.X.X`（未作成ならスキップ。冪等）
  2. リモート版取得: `git fetch origin tag vX.X.X`
  3. 同期検証: `git show vX.X.X` で commit / tagger を確認
- **完了条件**: ローカルの `vX.X.X` がリモート（`github-actions[bot]` 等が tagger）と一致

#### fallback 手順 §2: 異 SHA 衝突（責務 4）

- **配置**: §1 の直後
- **項目構造**: 番号付きリスト 3 項目（順序固定）
- **論理ステップ**:
  1. 自動 push 中止（既に push 試行済みなら reject されているため追加対応不要）
  2. 差分提示（**peeled commit SHA を使う** / Round 2 指摘 #1 反映）:
     - `git ls-remote origin "refs/tags/vX.X.X^{}"` の SHA（`<remote-commit-sha>` / annotated tag の peeled commit）
     - peeled 出力が空の場合は `git ls-remote --tags origin vX.X.X` の SHA を採用（lightweight tag fallback）
     - `git rev-parse HEAD` の SHA（`<local-sha>`）
     - `git log <remote-commit-sha>..<local-sha>` および逆方向 `git log <local-sha>..<remote-commit-sha>`（tag object SHA を `git log` に渡してはならない）
  3. ユーザー選択肢提示:
     - **(i) リモート優先（推奨）**: ローカル tag 削除 → `git fetch origin tag vX.X.X`
     - **(ii) ローカル優先（破壊的・明示確認必須）**: `git push --force origin vX.X.X` + CI/他リリース成果物との整合性破壊リスク警告
     - **(iii) 中断**: tag 操作スキップ + Operations Phase 中断 → 調査モード（`history/operations.md` に「tag 競合により中断」記録、調査完了後ステップ 3 から再開）

## API / インターフェース設計

文書追加のみのため、コード API は新規定義しない。既存の git CLI コマンドを以下の用途で参照する:

| コマンド | 用途 | ステップ 3 内での出現箇所 |
|---------|------|----------------------|
| `git ls-remote --tags origin vX.X.X` | リモート tag **存在検出**（`RemoteTagPresence`） | 事前確認（手順 1）/ 異 SHA 差分提示 |
| `git ls-remote origin "refs/tags/vX.X.X^{}"` | リモート tag の **peeled commit SHA** 取得（`RemoteTagCommitSha`） | 事前確認（手順 2）/ 異 SHA 差分提示 |
| `git rev-parse HEAD` | ローカルマージコミット SHA 取得（`LocalMergeCommitSha`） | SHA 比較根拠（マトリクス記載中） |
| `git rev-parse vX.X.X^{commit}` | （fetch 後の verification 用） tag → commit 解決 | 同 SHA fallback §1.3 同期検証 |
| `git tag -d vX.X.X` | ローカル tag 削除 | 同 SHA fallback §1.1 / 異 SHA (i) |
| `git fetch origin tag vX.X.X` | リモート tag 取得 | 同 SHA fallback §1.2 / 異 SHA (i) |
| `git show vX.X.X` | tag メタデータ確認 | 同 SHA fallback §1.3 |
| `git log <a>..<b>` | 双方向差分提示 | 異 SHA §2.2 |
| `git push --force origin vX.X.X` | ローカル優先 force push | 異 SHA §2.3 (ii) のみ（破壊的） |

## エラーハンドリング設計

| エラー条件 | 検出箇所 | 対応 |
|-----------|---------|------|
| `git ls-remote` ネットワーク失敗 | 事前確認 | 既存の `git push` 失敗時と同等。ユーザー判断にフォールバック（追加運用負荷ゼロ） |
| `git rev-parse HEAD` 失敗 | マトリクス比較時 | ステップ 1（`git checkout main`）/ 2（`git pull`）未完了の可能性。直前ステップへの差し戻しを案内 |
| ケース C で (iii) 中断選択 | 異 SHA fallback §2.3 | tag 操作スキップ + Operations Phase 中断 → `history/operations.md` 記録 → 調査後再開 |
| 同 SHA 比較で短縮 SHA / 部分一致混入 | （仕様上発生しない） | `git ls-remote` / `git rev-parse HEAD` はいずれも 40 文字 full SHA を返すため不発 |
| force push (ii) 選択時の確認漏れ | 異 SHA fallback §2.3 (ii) | `automation_mode` に関わらず明示確認必須（破壊的操作）。文書側で **太字 + 警告アイコン**（必要に応じて）で強調表現 |

## 検証戦略

### grep 検証クエリ（ドリフト検知 / Round 1 指摘 #2 対応）

責務ごとに分割した複数クエリで検証する。各クエリは少なくとも 1 件 hit することを期待値とする:

| 責務 | 検証クエリ | 期待 hit 内容 / 件数下限 |
|------|----------|------------------------|
| 1 | `grep -nE 'git ls-remote --tags origin vX\.X\.X' skills/aidlc/steps/operations/04-completion.md` | 事前確認の存在検出コマンド ≥ 1 |
| 1（誤分類防止） | `grep -nE 'refs/tags/vX\.X\.X\^\{\}\|vX\.X\.X\^\{commit\}' skills/aidlc/steps/operations/04-completion.md` | peeled commit SHA 取得コマンド ≥ 1 |
| 2 | `grep -nE 'ケース A\|ケース B\|ケース C' skills/aidlc/steps/operations/04-completion.md` | 3 ケース見出し すべて hit（合計 ≥ 3） |
| 2 | `grep -nE 'github-actions\[bot\]' skills/aidlc/steps/operations/04-completion.md` | 同 SHA 衝突の典型 tagger 例 ≥ 1 |
| 3 | `grep -nE '同 SHA' skills/aidlc/steps/operations/04-completion.md`（hit 後、同セクション内で `1\\.` / `2\\.` / `3\\.` の 3 項目を順序付きリストとして目視確認） | 同 SHA fallback の 3 項目構造 |
| 4 | `grep -nE '異 SHA' skills/aidlc/steps/operations/04-completion.md`（同上で 3 項目確認） | 異 SHA fallback の 3 項目構造 |
| 4 | `grep -nE '\(i\)\|\(ii\)\|\(iii\)' skills/aidlc/steps/operations/04-completion.md` | 3 つのユーザー選択肢 すべて hit（合計 ≥ 3） |
| 4 | `grep -nE '破壊的\|明示確認' skills/aidlc/steps/operations/04-completion.md` | (ii) ローカル優先の破壊性 + 明示確認契約 ≥ 1 |

### 構造的検証

| 検証項目 | 確認手段 |
|---------|---------|
| 判定マトリクスが markdown table 形式 | `grep -E "^\|.*\|.*\|.*\|.*\|"` 相当のパターンで `04-completion.md` の table 行が 3 行以上 hit することを確認（パイプ `\|` でエスケープ） |
| 3 ケースすべてが含まれる | grep で `ケース A` / `ケース B` / `ケース C` がそれぞれ ≥ 1 件 |
| fallback 手順各 3 項目 | grep で `1\.` / `2\.` / `3\.` が 同 SHA / 異 SHA セクションそれぞれで hit |
| (i)/(ii)/(iii) 3 つの選択肢 | grep で `\(i\)` / `\(ii\)` / `\(iii\)` または `(i)` / `(ii)` / `(iii)` がそれぞれ ≥ 1 件 |
| 既存構造の非破壊 | `git diff` で `version_tag = false` 経路 / `git tag -a` / `git push origin vX.X.X` の文言が破壊的に変更されていないことを目視 + 行単位 diff 確認 |

### 後方互換性

- `version_tag = false`（既定）: ステップ 3 全体スキップ → **未変更**
- `version_tag = true` + ケース A（不在）: 既存手順 `git tag -a` + `git push` に合流 → **挙動不変**
- `version_tag = true` + ケース B/C: **新規分岐**。既存 reject エラーで止まっていたユーザーが事前確認で適切な fallback を選択可能になる

## 配置位置（具体的挿入アンカー）

`skills/aidlc/steps/operations/04-completion.md` の以下のアンカーに挿入:

- **挿入開始**: 行 597 直後（既存 `version_tag = true` の `# アノテーション付きタグを作成` コメントブロックの直前）
- **挿入終了**: 既存 `git tag -a vX.X.X -m "Release vX.X.X"` の前で合流
- **挿入順**: (1) 事前確認手順 → (2) 判定マトリクス → (3) 同 SHA fallback → (4) 異 SHA fallback → 既存コードブロックへフォールスルー

挿入後の論理フロー:

```text
version_tag = true
  → [新規] git ls-remote --tags origin vX.X.X
  → [新規] 判定マトリクス参照
    → ケース A: 既存 git tag -a + git push へ進む
    → ケース B: 同 SHA fallback 実行 → 完了
    → ケース C: 異 SHA fallback 実行 → 選択肢実行 → (i) 完了 / (ii) force push 完了 / (iii) Operations 中断
```

## 履歴記録設計

`construction_unit04.md` に以下を追記:

| イベント | 記録内容 |
|---------|---------|
| 計画承認前レビュー完了 | round / 指摘件数 / セッション ID（既に追記済み） |
| 設計レビュー完了 | round / 指摘件数 / セッション ID |
| コード生成（文書追加）完了 | 変更行数 / 変更箇所アンカー |
| 統合レビュー完了 | round / 指摘件数 / セッション ID |
| grep 検証ログ | 8 クエリ（責務 1 / 1誤分類防止 / 2×2 / 3 / 4×3）それぞれの実行結果（hit 件数 / 判定 pass・fail） |
| 構造的検証ログ | 5 検証項目それぞれの結果 |
| markdownlint 結果 | pass / fail（pass のみ許容） |
