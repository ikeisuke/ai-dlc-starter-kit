# 論理設計: 旧ディレクトリ移行・削除

## 概要

活性ファイル内の旧パス参照をv2パスに一括置換する。grepで対象ファイルを特定し、sedまたはEditツールで置換を実行する。

## アーキテクチャパターン

**パターン**: Batch Processing（バッチ処理）

1. 検出フェーズ: grepで旧パスパターンを含むファイルを特定
2. 分類フェーズ: 活性ファイルのみをフィルタリング（除外スコープ適用）
3. 置換フェーズ: パスマッピングルールに基づき一括置換
4. 検証フェーズ: 旧パスの残存チェック + 新パスの存在確認

## コンポーネント構成

### 1. パス置換エンジン（手動実行）

Editツールまたはsedによるファイル内文字列置換。

**置換順序**: 長いパスから短いパスへ（部分一致による誤置換防止）

| 優先度 | 置換元 | 置換先 |
|-------|--------|--------|
| 1 | `docs/aidlc/templates/` | `skills/aidlc/templates/` |
| 2 | `docs/aidlc/config/` | `skills/aidlc/config/` |
| 3 | `docs/aidlc/prompts/` | `skills/aidlc/steps/` |
| 4 | `docs/aidlc/skills/` | `skills/` |
| 5 | `docs/aidlc/bin/` | `skills/aidlc/scripts/` |

**注意**: `docs/aidlc/prompts/` → `skills/aidlc/steps/` の置換は文脈に依存する場合がある。以下のケースは個別対応:
- `docs/aidlc/prompts/CLAUDE.md` → `skills/aidlc/CLAUDE.md`（stepsではない）
- `docs/aidlc/prompts/AGENTS.md` → `skills/aidlc/AGENTS.md`（stepsではない）
- `docs/aidlc/prompts/inception.md` → `/aidlc inception`（スキルコマンドにリダイレクト）
- `docs/aidlc/prompts/construction.md` → `/aidlc construction`
- `docs/aidlc/prompts/operations.md` → `/aidlc operations`
- `docs/aidlc/prompts/setup.md` → `/aidlc setup`
- `docs/aidlc/prompts/common/` → `skills/aidlc/steps/common/`（ステップファイル）
- `docs/aidlc/prompts/lite/` → `skills/aidlc/steps/lite/`（Liteステップ）
- `docs/aidlc/prompts/operations-release.md` → `skills/aidlc/steps/operations/`（オペレーション）

### 2. 個別修正コンポーネント

#### `.kiro/agents/aidlc-poc.json`

- `allowedCommands` 内の `docs/aidlc/bin/.*` → `skills/aidlc/scripts/.*`
- `resources` 内の `file://docs/aidlc/prompts/AGENTS.md` → `file://skills/aidlc/AGENTS.md`

#### `docs/aidlc/kiro/agents/aidlc.json`

- resources/allowedCommands 内の旧パス参照を確認・更新

### 3. 検証コンポーネント

#### 残存チェック

対象ディレクトリ: `prompts/`, `skills/`, `docs/aidlc/`, `bin/`, `.kiro/`, `.claude/`

```
grep -r "docs/aidlc/(templates|config|bin|skills|prompts)/" <対象ディレクトリ>
```

期待結果: 0件

#### 新パス存在確認

各置換先ディレクトリが実在すること:
- `skills/aidlc/templates/` ✓
- `skills/aidlc/config/` ✓
- `skills/aidlc/scripts/` ✓
- `skills/` ✓
- `skills/aidlc/steps/` ✓（存在確認要）

#### シンボリックリンク解決確認

`.claude/skills/` 配下の全リンクのターゲットが存在すること。

#### JSON設定の構文・参照先妥当性チェック

`.kiro/agents/aidlc-poc.json` および `docs/aidlc/kiro/agents/aidlc.json`:
- JSONとして構文的に正しいこと（`jq . < file` で検証）
- `resources` 配列の `file://` パスが実在するファイルを指すこと
- `allowedCommands` の正規表現パターンが意図通りのパスにマッチすること

#### 例外変換ルールのサンプル検証

`docs/aidlc/prompts/` → command_redirect の置換が正しく反映されたことを、代表ファイルでスポットチェック。

## 後方互換性方針

- `.kiro/agents/aidlc-poc.json` はリポジトリ内部のPoC設定であり外部公開APIではない。外部consumerは存在しないため、互換レイヤー（シンボリックリンク等）は不要。直接パス更新で対応
- `docs/aidlc/kiro/agents/aidlc.json` も同リポジトリ内の設定ファイルであり、同様に直接更新
- `prompts/package/` 内の参照更新は、次回 `/aidlc-setup` 実行時にユーザープロジェクトへ反映される（aidlc-setupが同期メカニズムとして互換レイヤーの役割を果たす）
- v2.0.0のPR #410マージがバージョン境界。旧パスの互換維持はv2.0.0以降は不要

## 影響範囲

### 変更あり

- `prompts/package/`: 35ファイル（v1プロンプトソース、次回aidlc-setupで反映）
- `skills/`: 5ファイル（v2スキルステップ）
- `docs/aidlc/guides/`: 12ファイル（ガイド文書）
- `.kiro/agents/aidlc-poc.json`: 1ファイル
- `bin/check-bash-substitution.sh`: 1ファイル

### 変更なし（除外）

- `.aidlc/cycles/`: Archive（履歴データ、正確な記録として保持）
- `docs/versions/`: Archive（バージョンアーカイブ）
- `CHANGELOG.md`: Archive（変更履歴）

**注**: `docs/aidlc/guides/`, `docs/aidlc/kiro/`, `docs/aidlc/lib/` はディレクトリとして削除しない（境界で維持）。ただしファイル内の旧パス参照は更新対象（Consumer として正本への参照を修正）。上記「変更あり」に含む。

## 不明点と質問

（なし）
