# Unit 004 計画: aidlc-setup の prompts/package/ 遺物純削除

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/004-aidlc-setup-prompts-package-removal.md`
- **担当ストーリー**: ストーリー 5（aidlc-setup の prompts/package/ 遺物削除、#595）
- **関連 Issue**: #595 / 関連 PR #449（v2.0.5 で `prompts/package/` 削除）/ 関連 CHANGELOG L482（v2.0.5 削除記録）
- **依存 Unit**: なし
- **見積もり**: 0.5 時間
- **実装優先度**: Medium

## 課題と修正方針

### 課題

`skills/aidlc-setup/steps/01-detect.md:89-91` に v2.0.5 で削除済みの `prompts/package/` ディレクトリへの言及が残存している。実体ディレクトリは存在せず判定式として無効だが、メタ開発判定時の混乱を生んでいる（ユーザーが「prompts/package/ がないとメタ開発できない」と誤解する余地）。

### 修正方針

L89-L91 の 3 行を **純削除** する（代替判定条件の追加は本 Unit 対象外、v2.5.0 以降のバックログ）:

```text
89: もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合:
90: - **メタ開発モード**: `prompts/package/` ディレクトリが存在する場合は、スターターキット自体の開発として続行できます
91: - **通常利用**: 対象プロジェクトのルートディレクトリに移動してから、このファイルのフルパスを指定して再度実行してください
```

削除後の前後文脈:

- L87: `**このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**`
- L88: 空行
- L92: 空行 → L88 と連続するため **片方を削除** して空行 1 つに整理（**可読性・体裁統一のため**。Markdown 上は空行 2 つでもアウトラインは破綻しないため、純削除の厳密性を優先する場合は任意整形）
- L93: `### 早期判定（ユーザー確認の前に実行）`

純削除後の構造（L87 → 空行 1 行 → 早期判定見出し）に整え、ファイル全体の空行ポリシー（セクション間 1 空行）と統一する。

### 削除に伴う影響評価

**L93 以降の早期判定ロジック自体は不変**。ただし、`ai-dlc-starter-kit` 内で `.aidlc/config.toml` がない状態では、L89-L91 が果たしていた「通常利用なら対象プロジェクトへ移動して再実行」という事前ガイダンスが消えるため、AI が初回セットアップ案内（L143「いずれも存在しない場合 → 初回セットアップ」）にそのまま進む可能性がある:

| ケース | 現状の挙動 | 削除後の挙動 | 評価 |
|--------|----------|------------|------|
| (a) メタ開発リポジトリ + `.aidlc/config.toml` あり | L89-91 ガイダンスを表示後、L97 `.aidlc/config.toml` 存在判定 → setup 済み遷移 | L97 `.aidlc/config.toml` 存在判定 → setup 済み遷移 | 変化なし（実体動作） |
| (b) 外部プロジェクト + `.aidlc/config.toml` あり | L97 setup 済み遷移（L89-91 はメタ開発リポジトリ内のときのみ表示される説明文） | 同上 | 変化なし |
| (c) 外部プロジェクト + `.aidlc/config.toml` なし | L143 「いずれも存在しない場合 → 初回セットアップ」 | 同上 | 変化なし |
| **(d) ai-dlc-starter-kit クローン直後 + `.aidlc/config.toml` なし**（メタ開発の新規セットアップ前） | L89-91 が「メタ開発モード判定 / 通常利用は対象プロジェクトへ移動」という事前説明文を表示 | L143 初回セットアップ案内に直接遷移し、確認プロンプト「このディレクトリで AI-DLC セットアップを実行してよろしいですか？」のみが出る | **挙動変化あり**（事前ガイダンスが失われ、誤ってリポジトリ直下で setup を進める余地が増える） |

**根拠**: L89-L91 は「もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合」の説明文であり、AI への判定指示ではない（早期判定は L93 以降の独立フロー）。よって判定ロジック自体は無変化。ただし (d) のケースで事前ガイダンスが失われ、`ai-dlc-starter-kit` クローン直下で誤って setup を進める余地が増える点は、後述「リスク評価」の運用リスクに条件付きで記録する。

### CHANGELOG `#595` 節の記載案

v2.4.0 セクションに `### Removed` 見出しを新規追加し、以下を含める:

```markdown
### Removed

- `skills/aidlc-setup/steps/01-detect.md` から `prompts/package/` ディレクトリへの言及（メタ開発モード判定の旧条件）を純削除。`prompts/package/` は v2.0.5 で削除済み（#449）であり、判定式として無効だった。代替判定条件（例: `version.txt` + `.claude-plugin/` ベース）の追加は本 Unit 対象外であり、必要性が確認された場合は v2.5.0 以降のバックログ Issue で別扱いとする（#595 / Unit 004）
```

**v2.4.0 セクション既存構造との整合**: Unit 003 が追加した `### Changed`（#596 節 2 項目）の直後に `### Removed` を追加する。Keep a Changelog 標準順序（Added / Changed / Deprecated / Removed / Fixed / Security）に準拠。

### バックログ起票の取り扱い

Unit 定義 L25 で「必要性が確認された場合は別 Issue / 別ストーリー（v2.5.0 以降のバックログ）で扱う旨を CHANGELOG または GitHub Issue（後続バックログ Issue を起票）に記録するのみ」とある。本 Unit では:

- **CHANGELOG 記載**: 上記 #595 節に「v2.5.0 以降のバックログ Issue で別扱い」を明記 → 履歴として永続化
- **GitHub Issue 起票**: 本 Unit では起票しない（Unit 定義の文言「CHANGELOG または GitHub Issue」の選言、CHANGELOG 記載で十分。必要性確認は将来の利用者フィードバックや Operations Phase で判断）

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc-setup/steps/01-detect.md` | L89-L91 削除 + L88/L92 連続空行を 1 行に整理 | -3〜-4 行 |
| `CHANGELOG.md` | v2.4.0 セクションに `### Removed` 見出し + `#595` 節 1 項目を追加 | +3〜4 行 |

## 動作確認手順

Unit 定義 L15-L19 の 3 ケース + 影響評価で追加した (d) ケースを **実 fixture ベース** で検証する。`/aidlc setup` の完全実行ではなく、削除後 01-detect.md の早期判定セクション（L93 以降）の **分岐条件述語** を fixture 上で確認することにスコープを限定する（分岐遷移そのものではない）。

### 検証スコープ限定

本 Unit のスコープは **L89-L91 純削除と、早期判定 #1/#3 の分岐条件述語の成立確認** までである。早期判定 #1 内の 1a バージョン比較フロー（dasel 取得・version.txt 比較・アップグレードモード遷移メッセージ）の検証は本 Unit 対象外（既存挙動として維持される）。

### Fixture 準備

```bash
# (a) メタ開発リポジトリ dev worktree（config.toml 既存）
FIXTURE_A=/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/.worktree/dev
test -f "$FIXTURE_A/.aidlc/config.toml" && echo "(a) ok"

# (b) 外部プロジェクト想定 + config.toml あり
FIXTURE_B=$(mktemp -d /tmp/aidlc-setup-test-b.XXXXXX)
mkdir -p "$FIXTURE_B/.aidlc"
printf '[project]\nname = "test-b"\nstarter_kit_version = "2.4.0"\n' > "$FIXTURE_B/.aidlc/config.toml"
test -f "$FIXTURE_B/.aidlc/config.toml" && echo "(b) ok"

# (c) 外部プロジェクト想定 + config.toml / v1 toml なし
FIXTURE_C=$(mktemp -d /tmp/aidlc-setup-test-c.XXXXXX)
echo "(c) prepared at $FIXTURE_C"

# (d) ai-dlc-starter-kit 配下シミュレーション + config.toml なし（メタ開発新規セットアップ前を想定）
# パス文字列に `ai-dlc-starter-kit` を含むのは「ケース (d) の説明用ラベル」であり、
# 現行 01-detect.md はパス判定をしていないため挙動には影響しない
FIXTURE_D=$(mktemp -d /tmp/aidlc-setup-test-d-ai-dlc-starter-kit.XXXXXX)
echo "(d) prepared at $FIXTURE_D"
```

### 期待分岐検証

各 fixture について、削除後 01-detect.md の早期判定セクションを評価する:

| ケース | 検証コマンド | 期待結果 |
|--------|------------|---------|
| (a) | `test -f "$FIXTURE_A/.aidlc/config.toml"` | exit 0 → 早期判定 #1「`.aidlc/config.toml` が存在する場合」の前提条件が成立（1a 以降のバージョン比較・遷移メッセージは本 Unit 検証対象外） |
| (b) | `test -f "$FIXTURE_B/.aidlc/config.toml"` | exit 0 → 早期判定 #1 の前提条件が成立（同上） |
| (c) | `! test -f "$FIXTURE_C/.aidlc/config.toml" && ! test -f "$FIXTURE_C/docs/aidlc.toml" && ! test -f "$FIXTURE_C/docs/aidlc/project.toml"` | exit 0（3 条件全て不在）→ 早期判定 #3「いずれも存在しない場合 → 初回セットアップ」の前提条件が成立 |
| (d) | `! test -f "$FIXTURE_D/.aidlc/config.toml" && ! test -f "$FIXTURE_D/docs/aidlc.toml" && ! test -f "$FIXTURE_D/docs/aidlc/project.toml"` | exit 0（3 条件全て不在）→ 早期判定 #3 の前提条件が成立 |

(c) と (d) の判定式は同一（`ai-dlc-starter-kit` パス文字列はラベルのみで挙動には影響しない）。(d) における旧 L89-L91 文言喪失の影響は、本「分岐条件述語の確認」では検出できないため、後述「削除内容直接検証」の文言差分確認手順で代替する。

### 削除内容直接検証

削除後の 01-detect.md に対して:

```bash
grep -c "prompts/package" skills/aidlc-setup/steps/01-detect.md  # 期待値: 0
grep -c "メタ開発モード" skills/aidlc-setup/steps/01-detect.md   # 期待値: 0
grep -c "ai-dlc-starter-kit.*リポジトリ内の場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 0
```

### 早期判定セクション残存確認

削除影響が L93 以降に及んでいないことを確認:

```bash
# 早期判定見出しが残存
grep -c "### 早期判定（ユーザー確認の前に実行）" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
# 早期判定 #1 が残存
grep -c "1\. \`.aidlc/config.toml\` が存在する場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
# 早期判定 #3 が残存
grep -c "3\. いずれも存在しない場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
```

### CHANGELOG 検証

```bash
grep -c "Unit 004" CHANGELOG.md     # 期待値: 既存 Unit 004 言及数 + 1
grep -c "prompts/package" CHANGELOG.md  # 期待値: 既存数（v2.0.5 既存記録）+ 1（v2.4.0 #595 節）
# v2.4.0 セクションに #595 節があるか
awk '/^## \[2.4.0\]/,/^## \[2.3.6\]/' CHANGELOG.md | grep -c "#595"  # 期待値: 1
```

### Fixture クリーンアップ

```bash
rm -rf "$FIXTURE_B" "$FIXTURE_C" "$FIXTURE_D"
```

## 境界遵守

- **代替判定条件追加**: 本 Unit 対象外（純削除のみ）。CHANGELOG に「v2.5.0 以降のバックログ Issue で別扱い」を明記
- **aidlc-setup の他セクション変更**: 本 Unit 対象外（バージョン比較・cycle.mode 等の変更は本サイクルでは扱わない）
- **DR-003（純削除固定）/ DR-007（代替判定条件追加は本サイクル対象外）**: Inception 完了処理で `inception/decisions.md` に集約記録済み、本 Unit からは追加実施なし

## リスク評価

### 技術的リスク

- **Low**: 純削除のみ、判定ロジックは L93 以降の独立フローで実現されており影響なし
- **Low**: アウトライン整合（L88/L92 空行整理）も単純な整形作業

### 運用リスク

- **Low**: メタ開発リポジトリ利用者が「メタ開発モード」表記の喪失で混乱する可能性 → CHANGELOG `### Removed` 節で v2.0.5 削除済みの遺物であった旨を明示するため、混乱は起きにくい
- **Low-Medium（条件付き）**: ケース (d)「`ai-dlc-starter-kit` クローン直後 + `.aidlc/config.toml` なし」のメタ開発新規セットアップ時に、L89-L91 が果たしていた「メタ開発モード判定 vs 通常利用」の事前ガイダンスが消える。AI が L143 初回セットアップ案内へ直接遷移し、確認プロンプト「このディレクトリで AI-DLC セットアップを実行してよろしいですか？」のみが提示される。本リポジトリのメタ開発フロー（`.worktree/dev` 上で `.aidlc/config.toml` を持つ）では (a) ケースで吸収されるため定常運用への影響は小さいが、新規ユーザーが ai-dlc-starter-kit クローン直下で誤って setup を進める余地は増える。**確認プロンプトは最終停止点としては機能するが、旧 L89-L91 の「通常利用なら対象プロジェクトへ移動」というガイダンスの代替にはならない**ため、Low-Medium と評価する
- **None**: 既存利用者の自動化への影響なし（判定ロジック自体は不変）

### 将来的な技術的負債

- **Note**: 「メタ開発リポジトリでも `.aidlc/config.toml` 経由で setup 済み判定が成功する」という暗黙の依存が残る。明示的なメタ開発判定が必要になった場合は v2.5.0 以降のバックログで別扱い（DR-007 に記録済み）

## 関連 Issue

- #595（本 Unit で対応）
- #449（参照: v2.0.5 での `prompts/package/` 削除 PR、CHANGELOG L482）
