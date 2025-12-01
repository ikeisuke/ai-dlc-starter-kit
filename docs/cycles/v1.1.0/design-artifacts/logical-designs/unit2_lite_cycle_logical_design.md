# Unit 2: 軽量サイクル（Lite版）論理設計

## 1. ディレクトリ構成

### 新規ディレクトリ

```
docs/aidlc/prompts/lite/
├── inception.md
├── construction.md
└── operations.md
```

### 既存ディレクトリ（変更なし）

```
docs/aidlc/prompts/
├── inception.md        # Full版（変更なし）
├── construction.md     # Full版（変更なし）
└── operations.md       # Full版（変更なし）
```

## 2. setup-prompt.md の変更

### 変数定義への追加

```markdown
## 変数定義

```
...既存の変数...

CYCLE_TYPE = Full  # Full / Lite
```
```

### CYCLE_TYPE の説明

```markdown
**CYCLE_TYPE の値**:
- `Full`: 全ステップを実行する完全版サイクル（新機能開発向け）
- `Lite`: 一部ステップを省略する軽量版サイクル（バグ修正・軽微な変更向け）
```

### セットアップ完了メッセージへの追加

Lite版選択時のプロンプト参照先を追記：

```markdown
## 次のステップ: Inception Phase の開始

【Full版の場合】
以下のファイルを読み込んで、Inception Phase を開始してください：
{{AIDLC_ROOT}}/prompts/inception.md

【Lite版の場合】
以下のファイルを読み込んで、Inception Phase (Lite) を開始してください：
{{AIDLC_ROOT}}/prompts/lite/inception.md
```

## 3. Lite版プロンプトの構造

### 共通構造

各Lite版プロンプトは以下の構造を持つ：

```markdown
# [Phase名] Phase プロンプト（Lite版）

## Full版プロンプトの参照【必須】

**まず以下のFull版プロンプトを読み込んでください**:
`docs/aidlc/prompts/[phase].md`

Full版の内容を理解した上で、以下の変更点を適用してください。

---

## Lite版での変更点

### スキップするステップ
- ステップX: [理由]

### 簡略化するステップ
- ステップY: [簡略化の内容]

### 維持するルール
- [Lite版でも維持する重要なルール]

---

## Lite版専用の完了基準

[Lite版固有の完了基準]
```

### 3.1 inception-lite.md

```markdown
# Inception Phase プロンプト（Lite版）

## Full版プロンプトの参照【必須】

**まず以下のFull版プロンプトを読み込んでください**:
`docs/aidlc/prompts/inception.md`

---

## Lite版での変更点

### スキップするステップ
- **ステップ5: PRFAQ作成** → スキップ（Lite版では不要）

### 簡略化するステップ
- **ステップ1: Intent明確化** → 簡潔に1ファイルで記述（詳細な対話不要）
- **ステップ3: ユーザーストーリー作成** → 箇条書きレベルでOK
- **ステップ4: Unit定義** → 1ファイルにまとめる（個別ファイル不要）
- **ステップ6: progress.md作成** → 最小限の管理

### 維持するルール
- 人間の承認プロセス
- Gitコミット
- 履歴記録（history.md）
- コンテキストリセット対応

---

## Lite版の完了基準

- Intent作成済み
- 簡易ユーザーストーリー作成済み
- Unit定義（1ファイル）作成済み
- progress.md作成済み
```

### 3.2 construction-lite.md

```markdown
# Construction Phase プロンプト（Lite版）

## Full版プロンプトの参照【必須】

**まず以下のFull版プロンプトを読み込んでください**:
`docs/aidlc/prompts/construction.md`

---

## Lite版での変更点

### スキップするステップ
- **Phase 1 全体（設計フェーズ）をスキップ**
  - ステップ1: ドメインモデル設計 → スキップ
  - ステップ2: 論理設計 → スキップ
  - ステップ3: 設計レビュー → スキップ

### 簡略化するステップ
- **ステップ4: コード生成** → 設計ドキュメントなしで直接実装
- **ステップ5: テスト生成** → 最小限のテスト（変更箇所のみ）
- **ステップ6: 統合とレビュー** → 簡略化した実装記録

### 維持するルール
- 人間の承認プロセス（実装開始前）
- ビルド・テスト実行
- Gitコミット
- 履歴記録（history.md）
- コンテキストリセット対応

---

## Lite版の完了基準

- コード実装完了
- ビルド成功
- テストパス
- 簡易実装記録作成
```

### 3.3 operations-lite.md

```markdown
# Operations Phase プロンプト（Lite版）

## Full版プロンプトの参照【必須】

**まず以下のFull版プロンプトを読み込んでください**:
`docs/aidlc/prompts/operations.md`

---

## Lite版での変更点

### 全ステップが任意
Lite版では Operations Phase 自体が任意です。

**スキップ可能な条件**:
- CI/CDが既に構築済み
- 監視・ロギングが既に設定済み
- 配布プロセスが確立済み

### 実施する場合
必要なステップのみを選択して実施：
- デプロイ準備（必要な場合）
- リリース後確認（推奨）

### 維持するルール
- Gitコミット
- 履歴記録（history.md）

---

## Lite版の完了基準

- 必要な運用作業の完了（または「スキップ」の明示的な選択）
- サイクル完了の記録
```

## 4. セットアップフロー

### Full版選択時（既存フローそのまま）

```
setup-prompt.md 実行
    ↓
docs/aidlc/prompts/*.md を作成
    ↓
「inception.md を読み込んでください」
```

### Lite版選択時（新規フロー）

```
setup-prompt.md 実行（CYCLE_TYPE=Lite）
    ↓
docs/aidlc/prompts/*.md を作成（Full版、既存と同じ）
    ↓
docs/aidlc/prompts/lite/*.md を作成（Lite版、新規）
    ↓
「inception-lite.md を読み込んでください」
```

## 5. 実装順序

1. `prompts/setup-prompt.md` に CYCLE_TYPE 変数を追加
2. `prompts/setup/common.md` に Lite版ディレクトリ作成を追加
3. `docs/aidlc/prompts/lite/inception.md` を作成
4. `docs/aidlc/prompts/lite/construction.md` を作成
5. `docs/aidlc/prompts/lite/operations.md` を作成
6. セットアップ完了メッセージを更新

## 6. サイクルタイプの識別（`.lite`ファイル方式）

### 概要

Lite版サイクルかどうかを識別するため、サイクルディレクトリに`.lite`ファイルを配置する。

### ディレクトリ構成

```
docs/cycles/v1.1.0/
├── .lite          ← Lite版サイクルの場合のみ存在
├── plans/
├── requirements/
├── history.md
...
```

### 確認方法

```bash
test -f docs/cycles/vX.X.X/.lite && echo "Lite" || echo "Full"
```

### `.lite`ファイルの内容

```
このサイクルはLite版です。
```

### セットアップ時の動作

- **CYCLE_TYPE=Full**: `.lite`ファイルを作成しない
- **CYCLE_TYPE=Lite**: `.lite`ファイルを作成する

### 各プロンプトでの確認

各フェーズプロンプト（Full版）の冒頭で`.lite`ファイルの存在を確認し、存在する場合はLite版プロンプトへの切り替えを案内する：

```markdown
### サイクルタイプ確認

`.lite`ファイルが存在するか確認してください：

```bash
test -f docs/cycles/{{CYCLE}}/.lite && echo "Lite版サイクルです"
```

Lite版の場合は、代わりに以下を読み込んでください：
`docs/aidlc/prompts/lite/[phase].md`
```

## 7. 実装順序（更新）

1. `prompts/setup-prompt.md` に CYCLE_TYPE 変数を追加
2. `prompts/setup/common.md` に Lite版ディレクトリ作成と`.lite`ファイル作成を追加
3. `docs/aidlc/prompts/lite/inception.md` を作成
4. `docs/aidlc/prompts/lite/construction.md` を作成
5. `docs/aidlc/prompts/lite/operations.md` を作成
6. セットアップ完了メッセージを更新

## 8. 注意事項

- Full版プロンプトは変更しない
- Lite版は必ずFull版を先に読み込む設計
- Full版の更新は自動的にLite版に反映される（Single Source of Truth）
- `.lite`ファイルの有無でサイクルタイプを識別可能
