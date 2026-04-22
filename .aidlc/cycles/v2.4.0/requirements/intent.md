# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.4.0 — Milestone 運用本採用 + 周辺 patch 解消

## 開発の目的

**主目的**: AI-DLC のサイクル管理を `cycle:v*` ラベル運用から GitHub Milestone 運用へ本採用として移行し、メタ開発フロー（Inception/Operations）と利用者向けドキュメントに反映する。あわせて、メタ開発時の整合性に影響している関連 patch 3 件（#595 / #596 / #588）を同サイクルで解消し、v2.4.0 を「Milestone 運用本採用 + メタ開発時の意図不一致と Operations スクリプト bug の解消」リリースとする。

### 背景・経緯

1. **#597 Milestone 運用移行**: v2.3.6 で試験運用（Milestone #1 + 6 件紐付け）を実施し、UI 挙動・進捗バー・closed 折りたたみなど十分実用に耐えると確認済み。1 サイクル = 1 Milestone（Kubernetes/release モデル）方針で本採用する。`cycle:v*` ラベル累積（90 件超）の UI ノイズ・持ち越し表現の煩雑さ・進捗可視化の欠如を解消する。
2. **#595 prompts/package/ 遺物削除**: aidlc-setup スキルにメタ開発判定のヒントとして残存している v1 遺物の記述を削除。実装上は無効だが、メタ開発時の判定混乱を生んでいる。
3. **#596 update-version.sh の starter_kit_version 上書き bug**: v1 流儀のまま `bin/update-version.sh` が `.aidlc/config.toml.starter_kit_version` を毎リリース更新し、メタ開発時のバージョン三角検証（local / skill / remote）が常に一致判定となる。アップグレードモードがメタ開発で発火しなくなる構造的問題を修正する。
4. **#588 pr-ready の closes_list 空配列 bug**: Operations Phase で関連 Issue がないサイクルの PR Ready 化が `set -u` 環境で `unbound variable` 失敗。ユーザー回避策（直接 `gh pr ready` 実行）を強いている。

### スコープ縮小判断

#597 が提案する Unit A〜F のうち、**Unit D-F（過去 v2 サイクル v2.0.0〜v2.3.5 の遡及 Milestone 化、v1 系サイクルラベル約 90 件の一括削除、v2 系ラベル整理）は本サイクル外**とする。理由:

- D-F は blast radius が大きく（90 件超のラベル削除は undo が手動）、本サイクルでは Operations/Inception/docs のフロー本採用と周辺 patch 解消にスコープを絞る
- D-F は本採用のフロー（A-C）が稼働確認できた後に minor/patch サイクルで段階実施する方が安全

## ターゲットユーザー

- **メタ開発者（一次）**: ai-dlc-starter-kit 自体を開発する利用者。Milestone 運用の本採用フローと、メタ開発時の整合性向上の恩恵を直接受ける
- **AI-DLC 利用者（二次）**: 外部プロジェクトで AI-DLC を使う利用者。Inception/Operations フローの Markdown 手順書更新により、Milestone 作成・紐付け・close が標準手順として案内されサイクル進捗の可視化が標準で得られる（手順は AI/人間が `gh api` を実行する形式、専用スクリプト自動実行は本サイクル外）

## ビジネス価値

- **サイクル進捗可視化**: Milestone の進捗バー・close 状態でサイクル進行が一目で把握可能になる
- **持ち越し運用の単純化**: ラベル運用での煩雑な「持ち越し表現」が、Milestone の付け替え/Backlog 保持の 2 択に集約される
- **UI ノイズ削減**: ラベル選択 UI から「サイクル管理用ラベル」を切り離すことで、本来の分類用ラベルだけが残る
- **メタ開発時の正しい挙動**: starter_kit_version の自動上書き解消により、メタ開発でもアップグレード経路が試験可能になる
- **Operations スクリプトの堅牢性**: pr-ready bug 解消により、関連 Issue を持たないサイクルでも PR Ready 化がスクリプト経由で完結する

## 含まれるもの

### #597 Milestone 運用移行（Unit A-C）

#### 責務分担【内部矛盾防止】

| 責務 | 担当 Unit | 配置 |
|------|----------|------|
| Milestone **作成** + 対象 Issue/PR 紐付け（サイクル開始時） | **Unit B のみ**（Inception 担当） | `skills/aidlc/steps/inception/` |
| Milestone **close** + 紐付け確認（サイクル完了時） | **Unit A のみ**（Operations 担当） | `skills/aidlc/steps/operations/` |
| Milestone 不在時の fallback 作成（Operations 開始時） | Unit A（fallback として明示） | `skills/aidlc/steps/operations/` |

「サイクル開始時に作る／完了時に close」を不変条件とし、Unit A は作成責務を持たない（fallback 例外時のみ作成可能、その旨をステップに警告として明記）。

#### Unit 詳細

- **Unit A: Operations Phase へ Milestone close + 紐付け確認を組込み**
  - `skills/aidlc/steps/operations/` の該当ステップに、サイクル完了時の対象 PR/Issue の Milestone 紐付け確認、および Milestone close 手順を追加
  - **Milestone 作成は Unit B 責務**。Operations 開始時に Milestone 不在を検出した場合のみ、警告表示 + fallback で作成（Inception でのスキップ漏れリカバリ用）
  - `gh api repos/OWNER/REPO/milestones --method PATCH -f state=closed`（close）/ `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N`（紐付け確認・必要時の追加紐付け）
  - **実装形態**: 本サイクルでは Markdown ステップ手順書更新（AI/人間が `gh api` を実行する手順を記述）まで。専用スクリプト化（`bin/` や `skills/aidlc/scripts/` 配下）は任意（Unit 内で実装してもよいが、必須ではない）。スクリプト化は v2.5.0 以降で別途検討
- **Unit B: Inception Phase へ Milestone 作成ステップを追加**
  - サイクルバージョン確定時に Milestone を作成し、対象 Issue（backlog / feedback）を紐付ける手順を `skills/aidlc/steps/inception/` に追加
  - `gh api repos/OWNER/REPO/milestones --method POST -f title=vX.Y.Z`（`gh milestone` サブコマンド非存在のため REST API 直叩き）
  - `gh issue/pr edit --milestone` がトークンスコープで失敗するケース向けに `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` フォールバック手順を明示
  - **既存「サイクルラベル付与」ステップの処理（ファイル単位確定）**:
    - `skills/aidlc/steps/inception/02-preparation.md` ステップ16 内の「サイクルラベル付与」記述（`scripts/label-cycle-issues.sh` 呼び出し）: **削除**し、Milestone 紐付け手順に置換
    - `skills/aidlc/steps/inception/05-completion.md` ステップ1「サイクルラベル作成・Issue紐付け」: **削除**し、Milestone 作成・紐付け手順に置換
    - `skills/aidlc/scripts/cycle-label.sh`: **deprecated として残置**（CHANGELOG とスクリプト先頭コメントで非推奨明記。物理削除は Unit E（後続サイクル）で実施）
    - `skills/aidlc/scripts/label-cycle-issues.sh`: 同上（deprecated として残置）
  - **実装形態**: Unit A と同方針で、Markdown ステップ手順書更新まで。スクリプト化は任意
- **Unit C: ドキュメント更新**
  - `docs/configuration.md` のサイクル運用セクション: ラベル参照 → Milestone 参照に書き換え
  - `README.md` のバッジ・説明該当箇所: Milestone バッジ採用検討、サイクル運用記述更新
  - `skills/aidlc/guides/` 配下: 以下のファイル単位で対応
    - `guides/issue-management.md`: サイクルラベル付与記述を Milestone 紐付けに書き換え
    - `guides/backlog-management.md` / `guides/backlog-registration.md`: Milestone 紐付け文脈を追記（必要時）
    - `guides/glossary.md`: 「サイクルラベル」「Milestone」用語定義の更新
  - `skills/aidlc/rules.md` の運用ルール更新: サイクル運用前提を Milestone に書き換え

### patch バンドル

- **#595 prompts/package/ 記述削除**: `skills/aidlc-setup/steps/01-detect.md:89-91` の v1 遺物記述を削除、または starter kit 本体判定を別の明確な条件（例: ルート直下に `version.txt` と `.claude-plugin/` が存在）に書き換える
- **#596 update-version.sh の starter_kit_version 上書き bug**:
  - `bin/update-version.sh` の更新対象から `.aidlc/config.toml` の `starter_kit_version` を除外
  - `starter_kit_version` の書き換え経路を `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路に限定する設計を明文化
  - メタ開発時の `.aidlc/config.toml` の扱いを明示（固定 vs 同期）
  - `skills/*/version.txt` は引き続き `update-version.sh` 対象（starter kit 本体のリリース版数）
  - **既存スクリプト契約の変更点（hidden breaking change 防止）**:
    - **`.aidlc/config.toml` 必須入力チェック**: 残置（リポジトリの整合性検証目的で読み取り自体は維持。書き込みのみ廃止）。`config-toml-not-found` エラーは引き続き発生する
    - **dry-run 出力 `aidlc_toml_current` / `aidlc_toml_new`**: **削除**（書き込み対象から外れたため出力する意味を失う）
    - **成功出力 `aidlc_toml:${VERSION}`**: **削除**（同上）
    - **テンポラリファイル / バックアップ / ロールバック処理**: `.aidlc/config.toml` 関連分は削除（version.txt / skills/*/version.txt のみ対象）
    - **CHANGELOG**: v2.4.0 リリースノートで「`bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外、出力フォーマットから `aidlc_toml_*` 行を削除」を明記（hidden breaking change としてユーザー周知）
    - **README**: `bin/update-version.sh` の使用方法説明箇所があれば追従（更新対象一覧）
    - **既存テスト**: `bin/update-version.sh` のテスト（あれば）の期待出力を追従更新。出力 diff 検証スナップショットの再生成
- **#588 pr-ready の closes_list 空配列 bug**: `skills/aidlc/scripts/pr-ops.sh:245` の `closes_list[@]` 空配列展開を `set -u` 環境で安全に扱うよう修正（`"${closes_list[@]:-}"` 形式または事前ガード）。期待出力例（`issues:none / closes:none / relates:none`）に従う

### v2.4.0 サイクル自体の Milestone 運用（DR-001 候補）

- v2.4.0 サイクルの開始時に Milestone `v2.4.0` を作成し、本 Intent で対象とする Issue（#597, #595, #596, #588）と本サイクルの PR を紐付ける
- v2.3.6 試験運用の Milestone #1 はそのまま維持（削除・リセット不要、本採用の一部として継続）

## 含まれないもの

### #597 のスコープ外（後続サイクルへ）

- **Unit D**: 過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化
- **Unit E**: v1 系サイクルラベル（`cycle:v1.*`）約 90 件の一括削除
- **Unit F**: v2 系サイクルラベル（`cycle:v2.0.*` 等）の整理

理由: blast radius が大きく、本採用フロー（A-C）の稼働確認後に minor/patch サイクルで段階実施する方が安全。`cycle:v*` ラベル付与の停止（Unit B 内）と整理（D-F）は分離して扱う。

### 他 Issue（v2.5.0 以降での候補）

- **#586** progress.md / 判定仕様 / fixture の 3 層整合化リファクタ
- **#592** config.toml.template の個人好み分離
- **#590** AI-DLC 振り返りステップ追加（#592 完了が前提）
- **#594** Construction Phase の Squash ステップ「オプション」表記見直し
- **#545** セットアップ時の変更検出によるブランチ・PR 自動化
- **#598** 必須 Checks が paths フィルタ / Draft skip で発火せず PR が merge 不可になる（v2.4.0 Inception 中にユーザー補足要件として浮上、本サイクル外でバックログ起票）
- 他 backlog 一覧

## 成功基準

### Milestone 運用本採用（#597 Unit A-C）

- v2.4.0 マージ後、新規サイクル開始時に **Unit B（Inception 担当）の手順に従って** Milestone が作成され、対象 Issue（backlog / feedback）が紐付けされる
  - 「自動作成」=「Inception Phase の Markdown 手順書に従って AI/人間が `gh api` を実行し、対話なしで Milestone 作成と紐付けが完了できる」状態を意味する。専用スクリプト化は本サイクルでは任意（v2.5.0 以降で別途検討）
- v2.4.0 マージ後、サイクル完了時に **Unit A（Operations 担当）の手順に従って** Milestone が close される。同手順内で対象 PR/Issue の紐付け確認が行われる
- Operations 開始時に Milestone 不在を検出した場合、Unit A の fallback 手順で警告表示 + 作成が行われる（Inception でのスキップ漏れリカバリ）
- `skills/aidlc/steps/inception/02-preparation.md` ステップ16 と `05-completion.md` ステップ1 から「サイクルラベル付与」記述が削除され、Milestone 紐付け手順に置換されている
- `skills/aidlc/scripts/cycle-label.sh` / `label-cycle-issues.sh` がスクリプト先頭コメントと CHANGELOG で deprecated 明記されている（物理削除は本サイクル外）

### patch バンドル

- メタ開発時、`bin/update-version.sh` 実行で `.aidlc/config.toml.starter_kit_version` が変更されない（`version.txt` と `skills/*/version.txt` のみ更新される）
- `bin/update-version.sh` の dry-run / 成功出力から `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行が削除されている
- CHANGELOG / README の `bin/update-version.sh` 関連記述が新仕様に追従している
- 関連 Issue を持たないサイクルでも `operations-release.sh pr-ready` が成功する（関連 Issue 一覧は `issues:none` / `closes:none` / `relates:none` として扱う）
- aidlc-setup スキルから `prompts/package/` 記述が削除済みで、メタ開発判定が現行構成（`.claude-plugin/` 等）に整合する

### サイクル自身の Milestone

- v2.4.0 サイクル自体が Milestone `v2.4.0` で管理され、本サイクルの全 Issue（#597 / #595 / #596 / #588）と PR が紐付け・close される
- v2.4.0 Milestone は Inception 完了時に手動で作成される（自己参照を避けるため、Unit B で更新する Inception の Milestone 作成手順は v2.5.0 以降の新規サイクルで標準手順として用いる）

### v1 遺物の除去

- メタ開発フローの v1 遺物（prompts/package 言及・starter_kit_version 上書き・サイクルラベル運用前提）が、対応スコープ内で除去される

## 期限とマイルストーン

- v2.4.0 minor リリースとして単一サイクル内で完結
- Construction Phase は Unit 数 4-6 程度を想定（Unit A / Unit B / Unit C / patch #595 / patch #596 / patch #588、結合の余地あり）
- 完了後 Operations Phase で Milestone close + リリースタグ作成

## 制約事項

### 技術的制約

- `gh milestone` サブコマンドは存在しないため、Milestone 操作は全て `gh api repos/OWNER/REPO/milestones` 経由で行う
- `gh issue edit --milestone` / `gh pr edit --milestone` はトークンスコープ制約で失敗するケースがあり、`gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` フォールバックが必要
- 1 Issue = 1 Milestone 制約（GitHub 側の仕様）。持ち越し運用は「付け替え or Backlog 保持」の 2 択
- `set -u` 環境での Bash 配列空展開は `unbound variable` 扱い（#588 の根本原因）

### 運用上の制約

- メタ開発時のバージョン三角検証（local / skill / remote）が現状機能していない（#596 修正後に検証可能化）
- v1 系ラベル削除（Unit E）の undo は手動再作成のみ（本サイクル外で慎重実施）

### 後方互換性

- #596 の修正は `bin/update-version.sh` の更新対象を変更するため、既存リリース手順を踏襲する利用者には影響しない（メタ開発時のみ挙動変化）
- #597 の Inception/Operations フロー変更は、v2.5.0 以降の新規サイクルで更新済み Markdown 手順を標準手順として用いる（専用スクリプト自動実行は本サイクルのスコープ外）。既存の v2.0.0〜v2.3.5 サイクルは Unit D-F（後続サイクル）で遡及対応

## 不明点と質問（Inception Phase中に記録）

[Question] v2.4.0 サイクル自体の Milestone（`v2.4.0`）の作成タイミングは Construction Phase 着手前（Inception 完了時）でよいか、それとも本 Issue で追加する Inception Phase の Milestone 作成ステップ（Unit B）を v2.4.0 の Inception で適用するか（自己参照）？
[Answer] Inception 完了時に手動で Milestone `v2.4.0` を作成し、対象 Issue（#597 / #595 / #596 / #588）と本サイクル PR を紐付ける。Unit B で更新する Inception の Milestone 作成手順は v2.5.0 以降の新規サイクルで標準手順として用いる（自己参照を避ける、専用スクリプト自動実行は本サイクルのスコープ外）。

[Question] 既存コード分析（Reverse Engineering）の範囲をどうするか？
[Answer] メタ開発リポジトリかつ限定スコープのため、影響範囲に絞ったミニマル分析を `requirements/existing_analysis.md` に記録する。対象は `skills/aidlc/steps/{operations,inception}/`、`bin/update-version.sh`、`skills/aidlc/scripts/pr-ops.sh`、`skills/aidlc-setup/steps/01-detect.md`、`docs/configuration.md`、`README.md`、`skills/aidlc/guides/`、`skills/aidlc/rules.md`。フル分析（4セクション網羅）は本サイクル外。
