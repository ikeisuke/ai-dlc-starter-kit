# Unit 008 計画: KiroCLIインストーラー

## 概要

KiroCLIエージェント設定ファイル（`aidlc.json`）を `~/.kiro/agents/` に配置するインストーラースキルを作成する。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/install-kiro-agent/SKILL.md` | 新規作成 | インストーラースキル（オーケストレーション層） |
| `skills/install-kiro-agent/bin/install-kiro-agent.sh` | 新規作成 | インストール実行スクリプト（実行層） |

## アーキテクチャ設計方針

### 責務分離

- **SKILL.md（オーケストレーション層）**: 対話制御（上書き確認等）、エラーメッセージの案内、手動コピーコマンドの表示
- **install-kiro-agent.sh（実行層）**: ファイル配置の副作用処理のみ。引数（`--force`, `--source`, `--target-dir`）で振る舞いを制御

### CLI契約（exit-code-convention.md準拠）

| 終了コード | 意味 | ケース |
|-----------|------|--------|
| 0 | 成功 | 配置完了（kiro未導入でも配置成功ならexit 0 + `status:warning`） |
| 1 | バリデーションエラー | テンプレート不存在、引数不正 |
| 2 | システムエラー | 権限不足、ディレクトリ作成失敗 |

- stdout: `status:success` / `status:warning` / `status:skipped`（同一内容でno-op時）
- stderr: 人間向けエラー説明

### KiroCLI存在確認

`kiro` バイナリの存在は必須依存としない。本スキルの本質は「テンプレートをユーザー領域に配置すること」。

- kiro導入済み: 配置 + 認識確認 → `status:success`
- kiro未導入: 配置のみ実行 → `status:warning`（「配置済みだがCLI未検証」）

### 上書き戦略（冪等性）

- 同一内容: no-op → `status:skipped`
- 差分あり + `--force`なし: スクリプトはexit 1（上書き拒否）。SKILL.md側で差分表示・確認後に `--force` で再実行
- 差分あり + `--force`: バックアップ（`.bak`）作成後に置換

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: インストーラーの責務・入出力・エラーケースの整理
2. **論理設計**: スキル構造（SKILL.md + シェルスクリプト）のインターフェース設計

### Phase 2: 実装

1. **シェルスクリプト作成** (`bin/install-kiro-agent.sh`):
   - 引数パース（`--source`, `--target-dir`, `--force`）
   - テンプレートファイル存在確認
   - 配置先ディレクトリの作成（不在時）
   - 冪等性チェック（既存ファイルとの差分比較）
   - ファイルコピー実行（`--force`時はバックアップ作成）
   - kiro存在時のみ認識確認（post-install verify）

2. **SKILL.md作成**: スキルメタ情報・対話制御フロー・手動コピーコマンド案内

3. **テスト**: インストーラーの動作確認

## 完了条件チェックリスト

- [ ] インストーラースキルが作成されている（`skills/install-kiro-agent/SKILL.md`）
- [ ] エージェント設定ファイルが所定場所（`~/.kiro/agents/aidlc.json`）に配置される
- [ ] 配置先ディレクトリの自動作成（不在時）が動作する
- [ ] 配置後のKiroCLI認識確認が実装されている（kiro導入済みの場合のみ）
- [ ] 既存設定の上書き確認が実装されている（冪等性: 同一内容はno-op、差分ありはバックアップ後置換）
- [ ] 異常系対応（権限不足時は手動コマンド案内、KiroCLI未導入時はwarning）が実装されている
- [ ] exit-code-convention.md に準拠した終了コード設計
