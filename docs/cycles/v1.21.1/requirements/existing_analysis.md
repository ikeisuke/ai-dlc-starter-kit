# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回の変更対象に絞った構成：

```
prompts/package/
├── bin/
│   ├── setup-branch.sh       # ブランチ作成スクリプト
│   ├── write-history.sh      # 履歴記録スクリプト
│   └── ...
├── prompts/
│   ├── inception.md           # Inception Phaseプロンプト
│   ├── construction.md        # Construction Phaseプロンプト
│   ├── operations.md          # Operations Phaseプロンプト
│   ├── operations-release.md  # Operations Phaseリリース手順
│   └── common/
│       └── review-flow.md     # AIレビューフロー
└── ...
```

## アーキテクチャ・パターン

- **プロンプト駆動**: AIエージェントがプロンプト内の手順に従い、シェルスクリプトを呼び出す構造
- **設定管理**: `aidlc.toml` + `aidlc.toml.local`（個人設定上書き）のマージ方式
- **スクリプトバリデーション**: 各スクリプトは入力検証を自前で実施（正規表現チェック等）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| スクリプト言語 | Bash | prompts/package/bin/*.sh |
| 設定フォーマット | TOML | docs/aidlc.toml |
| 設定パーサー | dasel | prompts/package/bin/read-config.sh |

## 依存関係

### 変更対象ファイル間の依存

- `inception.md` → `setup-branch.sh`（ステップ7でブランチ作成を呼び出し）
- `construction.md` → ブランチ確認ステップなし（Inceptionで作成済み前提）
- `operations-release.md` → `validate-git.sh`（ローカル/リモート同期チェック、main最新化チェックなし）
- `review-flow.md` → `which` コマンドでcodex/claude/geminiのCLI可用性チェック
- 全フェーズ → `write-history.sh`（履歴記録）

## 特記事項

### 重要な発見

1. **write-history.sh の validate_cycle() が `/` を拒否する（#301）**:
   - `validate_cycle()` 関数内で `if [[ "$cycle" == */* ]]; then return 1` としており、名前付きサイクル（`name/v1.0.0` 形式）を明示的に拒否している
   - 修正方針: バリデーションロジックを拡張し、`name/vX.X.X` 形式を許可する

2. **setup-branch.sh は名前付きサイクルのブランチ名を既にサポート（#307部分）**:
   - 正規表現 `^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` で `name/vX.X.X` 形式を許可済み
   - ただし、main最新化チェック機能は未実装

3. **main最新化チェックが全フェーズで不在（#307）**:
   - Inception Phase ステップ7: ブランチ作成前にmainの最新化チェックなし
   - Operations Phase: `validate-git.sh` でローカル/リモート同期チェックはあるが、mainとの乖離チェックなし
   - Construction Phase: ブランチ確認ステップ自体がない

4. **非正規ブランチ時の対応が未実装（#303）**:
   - inception.md ステップ7は main/master の場合のみ分岐、それ以外は「次のステップへ進行」のみ
   - `cycle/vX.X.X` 形式でもそれ以外（feature/xxx等）でも区別なく進行

5. **名前付きサイクル候補表示は inception.md ステップ5.6 に部分実装済み（#302）**:
   - 既存の名前付きサイクルディレクトリを検出し選択肢を提示する仕組みは存在
   - ただし `mode = "named"` の場合にサイクル名入力時の候補表示は未実装

6. **ツールチェック回避設定が未実装（#306）**:
   - review-flow.md ステップ3で `which codex/claude/gemini` を毎回実行
   - 設定による無効化の仕組みがない
