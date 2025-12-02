# 既存コード分析

## 分析日
2025-11-30

## 分析対象
v1.1.0 の4機能に関連する既存ファイル

---

## 機能1: Operations Phase再利用性

### 関連ファイル
| ファイル | 役割 |
|---------|------|
| `docs/aidlc/prompts/operations.md` | Operations Phase プロンプト |
| `prompts/setup-prompt.md` | セットアップ時のディレクトリ構成 |

### 現状の課題
- 各サイクルごとに `docs/cycles/vX.X.X/operations/` に成果物を作成
- CI/CD構築（ステップ2）、監視・ロギング戦略（ステップ3）は毎回新規作成
- サイクル横断での再利用の仕組みがない
- 一度構築したCI/CDを次サイクルで流用できない

### 変更方針
- 共通Operations成果物を `docs/aidlc/operations/` に配置するオプションを追加
- 既存設定がある場合は「再利用/更新」の選択肢を提示
- operations.md に再利用フローを追加

---

## 機能2: 軽量サイクル（Lite版）

### 関連ファイル
| ファイル | 役割 |
|---------|------|
| `prompts/setup-prompt.md` | セットアップ時にサイクルタイプを選択 |
| `docs/aidlc/prompts/inception.md` | Inception Phase プロンプト |
| `docs/aidlc/prompts/construction.md` | Construction Phase プロンプト |
| `docs/aidlc/prompts/operations.md` | Operations Phase プロンプト |

### 現状の課題
- フル版のみ存在
- 軽いバグ修正でも全ステップを経由する必要がある
- 小さな変更に対してオーバーヘッドが大きい

### 変更方針
- Lite版プロンプトを新規作成
  - `docs/aidlc/prompts/lite/inception-lite.md`
  - `docs/aidlc/prompts/lite/construction-lite.md`
  - `docs/aidlc/prompts/lite/operations-lite.md`
- セットアップ時に `CYCLE_TYPE = full / lite` を選択
- Lite版は以下を簡略化:
  - Inception: Intent + 簡易Unit定義のみ
  - Construction: 設計スキップ、直接実装
  - Operations: 必要な場合のみ

---

## 機能3: ブランチ確認機能

### 関連ファイル
| ファイル | 役割 |
|---------|------|
| `prompts/setup-prompt.md` | セットアップ時に確認を追加 |

### 現状の課題
- `BRANCH` 変数は定義されているが、実際のブランチ名との比較は行われていない
- 誤ったブランチで作業を開始するリスクがある
- 手動でブランチを確認する必要がある

### 変更方針
- セットアップ時に `git branch --show-current` で現在のブランチを取得
- `CYCLE` がブランチ名に含まれていない場合、警告を表示
- ブランチ切り替えの提案を行う
- 例: CYCLE=v1.1.0 で現在ブランチが main の場合
  - 「ブランチ名に v1.1.0 が含まれていません。`feature/v1.1.0` に切り替えますか？」

---

## 機能4: コンテキストリセット提案機能

### 関連ファイル
| ファイル | 役割 |
|---------|------|
| `docs/aidlc/prompts/inception.md` | 「次のステップ」セクション |
| `docs/aidlc/prompts/construction.md` | 「次のステップ」「Unit完了時の必須作業」セクション |
| `docs/aidlc/prompts/operations.md` | 「次のステップ」セクション |

### 現状の課題
- フェーズ移行時に「新しいセッションで」という記載はあるが、強調されていない
- リセット+呼び出しプロンプトの明示的な提示がない
- ユーザーがリセットを忘れてコンテキストが膨らむリスク

### 変更方針
- フェーズ完了時に「コンテキストリセット推奨」セクションを追加
- コピペ可能な呼び出しプロンプトを明示
- Unit完了時にも同様の案内を追加
- 追加する発動タイミング:
  1. Inception Phase 完了時 → Construction Phase 開始プロンプトを提示
  2. Unit完了時 → 次Unit開始プロンプトを提示
  3. Construction Phase 完了時 → Operations Phase 開始プロンプトを提示

---

## 影響範囲まとめ

| 機能 | 新規作成 | 変更 |
|------|---------|------|
| Operations Phase再利用性 | `docs/aidlc/operations/` ディレクトリ | `operations.md`, `setup-prompt.md` |
| 軽量サイクル（Lite版） | `docs/aidlc/prompts/lite/*.md` | `setup-prompt.md` |
| ブランチ確認機能 | なし | `setup-prompt.md` |
| コンテキストリセット提案機能 | なし | `inception.md`, `construction.md`, `operations.md` |
