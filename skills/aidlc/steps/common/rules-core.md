# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 設定読み込み【重要】

AI-DLCの設定は `.aidlc/config.toml` と `.aidlc/config.local.toml`（個人設定）からマージして取得する。

```bash
# 単一キー
scripts/read-config.sh <key>

# バッチモード
scripts/read-config.sh --keys <key1> [key2] ...
```

- 終了コード: 0=値あり、1=キー不在、2=エラー
- `.local` の値は上書き、配列は完全置換。詳細は `guides/config-merge.md` を参照

### dasel 呼び出し規約（CLI v3）

`.aidlc/config.toml` の TOML 値読取は **`scripts/read-config.sh` 経由を第一推奨** とする。

**理由**:

- 4 階層マージ（defaults / HOME / project / local）と key alias を一元的に処理
- 終了コード規約（0=値あり、1=キー不在、2=エラー）が定義済み
- AI エージェントが `dasel -f` のような不正フラグを誤生成するリスクを排除

**公開 API スクリプト層としての位置付け**:

`scripts/read-config.sh` は AI-DLC スターターキット内の **公開 API スクリプト** として位置付けられ、`.aidlc/rules.md` の「スキル間依存ルール」が禁じる「他スキル内部実装への依存」には該当しない（`.aidlc/rules.md` 本体に例外規定済み）。これにより、aidlc-feedback / aidlc-setup / aidlc-migrate / reviewing-* など全スキルから参照可。`scripts/lib/*` 等は引き続き内部実装として扱う。

**呼び出し記法**:

| 用途 | 記法 |
|------|------|
| AI 手順内コマンド（aidlc スキル内プロンプト `.md`） | `bash scripts/read-config.sh <key>`（SKILL.md パス解決でスキルベースディレクトリ相対を絶対化） |
| AI 手順内コマンド（他スキル：aidlc-feedback / aidlc-setup / aidlc-migrate / reviewing-* など） | `bash skills/aidlc/scripts/read-config.sh <key>`（リポジトリルート相対の絶対参照。各スキル配下に `scripts/read-config.sh` は存在しないため、aidlc プラグイン内のパスを直接指定する） |
| 検証コマンド（人間 / CI） | `bash skills/aidlc/scripts/read-config.sh <key>`（リポジトリルート相対の絶対参照） |

**dasel 直接呼び出しの例外**:

`read-config.sh` 自身が動作不能な低レイヤー（bootstrap 内部・stdlib 系）、または `read-config.sh` が必須前提とする `.aidlc/config.toml` 自身の存在検証段階（aidlc-setup の早期判定）でのみ、dasel CLI を直接呼んでよい。その場合、以下の **2 形式のみ許容** する:

- `cat <file> | dasel -i toml '<key>'`
- `dasel -i toml '<key>' < <file>`

**dasel CLI v3 の制約**:

- `-f <file>` フラグは **存在しない**（`unknown flag` エラー、exit 80）。これは v2 系の構文との混同による AI 誤生成パターンであり、絶対に使用してはならない

### 禁止呼び出しパターン

AI エージェントが誤生成しがちな anti-pattern を以下に列挙する。これらは絶対に使用してはならない。

| パターン | エラー | 正しい代替 |
|---------|-------|----------|
| `dasel -f <file> '<key>'` | `unknown flag -f`（exit 80、dasel v3） | `bash scripts/read-config.sh <key>` または `cat <file> \| dasel -i toml '<key>'` |
| `dasel -f <file> -r toml '<key>'` | 同上、`-r`/`-f` 混在 | 同上 |

**拡張余地**: 将来の anti-pattern は別 Issue / Unit で追加（初版は dasel 関連 2 例に限定）。

## 実行前の検証

- **指示の妥当性検証**: 実行前に指示が明確か、リスクはないか確認

## フェーズ固有のルール

- **Inception Phase**: Intent作成は対話形式、Unit定義では依存関係を明確化
- **Construction Phase**: 設計と実装を分離（Phase 1で設計、Phase 2で実装）
- **Operations Phase**: デプロイ前にチェックリスト確認、ロールバック手順必須

## Gitコミットのルール

コミットタイミング、メッセージフォーマット、Co-Authored-By設定は `steps/common/commit-flow.md` を参照。

## バックログ管理【重要】

バックログはGitHub Issueに記録する（`gh issue create`）。

### 即時実装優先ルール

バックログに登録するだけでなく、以下の条件をすべて満たす場合は現サイクルでの即時実装を優先する:

- 現在のサイクルのスコープ内である（Intent の「含まれるもの」に該当）
- 修正が小規模（1ファイル以内、または既存Unitの責務に含まれる）
- ブロッカーでない他の作業に影響しない

### 改善提案のバックログ登録ルール

改善提案を行う場合は**必ずバックログに登録**すること。口頭提案のみは禁止。

1. **スコープチェック**: Intent「含まれるもの」に該当する場合は現サイクル内で処理（バックログに外出ししない）
   - **例外**: 「スコープ保護ルール」に基づきユーザーが明示的にOUT_OF_SCOPEを承認した場合は、Intent内要件であってもバックログ登録を許可する（ユーザー承認済みのスコープ縮小）
2. 該当しない場合: GitHub Issueに記録（`guides/backlog-management.md` 参照）

### 適用場面の違い

- **即時実装優先ルール**: ユーザーから依頼された作業や、現在のUnit作業中に発見した問題で、現サイクル内で対応可能なもの
- **改善提案のバックログ登録ルール**: 現サイクルのスコープ外の改善提案や、大規模な変更が必要なもの

## スコープ保護ルール【重要】

Intentの「含まれるもの」に記載された要件を制限・除外する判断（スコープ縮小）は、`automation_mode` に関わらずユーザー確認を必須とする。

**スコープ縮小の定義**: レビュー指摘への対応やその他の判断で、Intentの「含まれるもの」セクションに列挙された要件の全部または一部を実装対象から除外すること。

**適用条件**: `automation_mode`（`manual` / `semi_auto`）やエクスプレスモードの有無に関わらず、常時適用する。

**実行ポイント**: 実際の強制は `review-flow.md` の「指摘対応判断フロー」で実施する。OUT_OF_SCOPE選択時にIntent内要件への影響を判定し、該当する場合はユーザー確認を必須とする。詳細は `review-flow.md` の「スコープ保護確認」セクションを参照。

**判定不能時**: Intentの「含まれるもの」セクションが存在しない、または対象の該当性が曖昧な場合は、ユーザー確認へフォールバックする（安全側に倒す）。

## コード品質基準

コード品質基準、Git運用の原則は `.aidlc/rules.md` を参照。

## 禁止事項

- 既存履歴の削除・上書き（historyは追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）

## コンテキスト要約時の情報保持

会話が長くなりコンテキストが自動要約（コンパクション）される際、以下のAI-DLC関連情報を必ず保持すること：

**保持必須の情報**:

- **現在のサイクル**: 例: `v1.9.1`
- **現在のフェーズ**: `Inception` / `Construction` / `Operations`
- **作業中のUnit**: Unit名と番号（例: `Unit 005: コンテキスト情報保持`）
- **Unitの進行状況**: 現在のステップ（例: `Phase 2: 実装 - ステップ4`）
- **完了済みUnit**: 完了したUnit番号のリスト
- **次に実行すべきアクション**: 中断時の継続ポイント
- **automation_mode**: `semi_auto` または `manual`（コンパクション後に `read-config.sh` で再取得。詳細は `common/compaction.md` を参照）

**保持形式の例**:

```text
[AI-DLC Context]
- Cycle: v1.9.1
- Phase: Construction
- Current Unit: 005 (コンテキスト情報保持) - Phase 2 実装中
- Completed Units: 001
- Next Action: AGENTS.md への変更完了後、テスト実行
- Automation Mode: semi_auto
```
