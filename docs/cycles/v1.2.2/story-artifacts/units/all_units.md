# Unit定義（v1.2.2）

## Unit一覧

| Unit | 名前 | 依存関係 | 対象ストーリー |
|------|------|----------|----------------|
| Unit 1 | 気づき記録フロー定義 | なし | US-1 |
| Unit 2 | ホームディレクトリ共通設定 | なし | US-2 |
| Unit 3 | ファイルコピー判定改善 | Unit 6 | US-3 |
| Unit 4 | Lite版案内追加 | なし | US-4 |
| Unit 5 | サイクル固有バックログ確認 | なし | US-5 |
| Unit 6 | ファイル構成整理 | なし | - |
| Unit 7 | Lite版設計ステップ見直し | なし | - |
| Unit 8 | 継続プロンプト必須化 | なし | - |

---

## Unit 1: 気づき記録フロー定義

### 概要
Unit作業中に別Unitに関する気づきがあった場合の対応フローを定義する

### 対象ファイル
- `docs/aidlc/prompts/construction.md`（またはadditional-rules.md）

### 実装内容
- 気づきをサイクル固有バックログに記録する手順を追加
- 現在のUnit作業を中断せずに記録する方法を明記

---

## Unit 2: ホームディレクトリ共通設定

### 概要
`~/.aidlc/` にユーザー共通設定を配置できるようにする

### 対象ファイル
- `prompts/setup-prompt.md`
- `docs/aidlc/prompts/additional-rules.md`（読み込み優先順位の説明）

### 実装内容
- ホームディレクトリの設定ファイル読み込みロジックを追加
- 読み込み優先順位: ホーム設定 → プロジェクト設定

---

## Unit 3: ファイルコピー判定改善

### 概要
セットアップ時のファイルコピーをrsyncで効率化する

### 依存関係
- Unit 6（ファイル構成整理）完了後に実施

### 背景・目的
- 現状: 個別ファイルを `\cp -f` でコピー、存在チェックで分岐
- 問題: 同一内容でも毎回上書き、git履歴に不要な変更が残る
- 解決: rsync --checksum で差分のみ更新、--delete で不要ファイル削除

### 対象ファイル
- `prompts/setup-init.md`

### 実装内容
1. **rsyncコマンドに置き換え**
   ```bash
   rsync -av --checksum --delete prompts/package/prompts/ docs/aidlc/prompts/
   rsync -av --checksum --delete prompts/package/templates/ docs/aidlc/templates/
   ```

2. **オプション説明**
   - `--checksum`: ハッシュで比較、同一内容ならスキップ
   - `--delete`: コピー元にないファイルを削除
   - `-av`: アーカイブモード + 詳細出力

3. **macOS/Linux共通**
   - rsyncは両環境でプリインストール済み
   - shasum/sha256sumの分岐が不要になる

### 出力例
```
>fcst....... file.md   # 内容が異なる → 更新
.f..t....... file2.md  # タイムスタンプのみ → スキップ（--checksumにより）
```

---

## Unit 4: Lite版案内追加

### 概要
サイクルセットアップ完了メッセージにLite版の案内を追加

### 対象ファイル
- `prompts/setup-cycle.md`

### 実装内容
- 完了メッセージにLite版プロンプトのパスを追記

---

## Unit 5: サイクル固有バックログ確認

### 概要
Inception Phaseでサイクル固有バックログも確認するようにする

### 対象ファイル
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/lite/inception.md`

### 実装内容
- バックログ確認ステップに `docs/cycles/{{CYCLE}}/backlog.md` の確認を追加

---

## Unit 6: ファイル構成整理

### 概要
docs/aidlc/ をスターターキット由来のファイルのみにし、rsync --delete で完全同期可能にする

### 背景・目的
- 現状: `docs/aidlc/` にユーザー固有ファイル（project.toml, additional-rules.md）が混在
- 問題: rsync --delete でスターターキットと同期すると、ユーザー固有ファイルが削除される
- 解決: ユーザー固有ファイルを `docs/aidlc/` の外に移動し、完全同期可能にする

### 変更後のファイル構成
```
docs/
├── aidlc.toml              # プロジェクト設定（旧 docs/aidlc/project.toml）
├── aidlc/                  # rsync --delete で完全同期可能
│   ├── prompts/
│   ├── templates/
│   └── (version.txtは廃止、aidlc.tomlに統合)
└── cycles/
    ├── additional-rules.md # プロジェクト固有ルール（移動）
    ├── operations.md
    ├── backlog.md
    └── v1.2.2/
```

### 対象ファイル
- `prompts/setup-init.md` - セットアップ処理の変更
- `prompts/setup-prompt.md` - パス参照の修正
- `prompts/package/templates/` - project.tomlテンプレートをaidlc.tomlに変更
- `prompts/package/prompts/*.md` - パス参照の修正（additional-rules.mdの新パス）

### 実装内容
1. **aidlc.toml への移行**
   - `docs/aidlc/project.toml` → `docs/aidlc.toml` に移動・リネーム
   - `starter_kit_version` フィールドを追加（version.txtの内容を統合）
   - スターターキットの `/version.txt` から読み取ってセットアップ時に書き込む

2. **additional-rules.md の移動**
   - `docs/aidlc/prompts/additional-rules.md` → `docs/cycles/additional-rules.md`
   - 各フェーズプロンプト内の参照パスを更新

3. **version.txt の廃止**
   - `docs/aidlc/version.txt` は作成しない
   - バージョン情報は `aidlc.toml` の `starter_kit_version` で管理

4. **パス参照の更新**
   - construction.md, inception.md, operations.md 内の参照を更新
   - `docs/aidlc/prompts/additional-rules.md` → `docs/cycles/additional-rules.md`
   - `docs/aidlc/project.toml` → `docs/aidlc.toml`

### 注意事項
- このUnit完了後、Unit 3（rsync対応）を実施可能になる
- 既存プロジェクトの移行手順も考慮が必要（アップグレード時）

---

## Unit 7: Lite版設計ステップ見直し

### 概要
Lite版でも最低限の設計確認ステップを残し、実装先の判断ミスを防ぐ

### 背景・目的
- 現状: Lite版は設計フェーズ（Phase 1）を全てスキップ
- 問題: 実装先ファイルの判断ミスが起きやすい（Unit 1で発生）
- 解決: 「どこに実装するか」の確認ステップを残す

### 対象ファイル
- `prompts/package/prompts/lite/construction.md`

### 実装内容
1. **簡易設計確認ステップの追加**
   - 対象ファイルの確認（ツール側 vs 成果物側）
   - 実装先の明示的な記載を計画に含める

2. **スキップ内容の見直し**
   - ドメインモデル設計 → スキップ維持
   - 論理設計 → スキップ維持
   - 設計レビュー → 「実装先確認」として簡略化して残す

### バックログ参照
- 「Lite版でも設計フェーズをスキップしない方が良い」（優先度: 高）

---

## Unit 8: 継続プロンプト必須化

### 概要
Unit完了時・フェーズ移行時に継続プロンプトを必ず提示する

### 背景・目的
- 現状: コンテキストリセット推奨のみで、具体的なプロンプトがない場合がある
- 問題1: ユーザーがプロンプトを自分で探す必要がある
- 問題2: 「推奨」だとAIが判断で省略してしまう（v1.2.2で発生）
- 解決: 完了メッセージに継続プロンプトを必ず含める

### 追加要件（v1.2.2で追加）
- **コンテキストリセットのルール強化**
  - 現状: 「推奨」→ AIが勝手に省略してしまう
  - 変更: 「ユーザーから連続実行の指示がない限り必須」
  - ユーザーが「続けて」「上からで」等と明示した場合のみスキップ可能
  - デフォルトは毎回リセット提示

### 対象ファイル
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/operations.md`
- `prompts/package/prompts/lite/*.md`

### 実装内容
1. **Unit完了時のメッセージ**
   ```
   ## Unit [名前] 完了

   **次のUnitを開始するプロンプト**:
   ```
   以下のファイルを読み込んで...
   ```
   ```

2. **フェーズ移行時のメッセージ**
   - 各フェーズの「次のステップ」セクションにプロンプトを明記
   - コピー&ペースト可能な形式で提示

3. **全フェーズに適用**
   - Inception → Construction
   - Construction → Operations
   - Unit間の移動

### バックログ参照
- 「Unit/フェーズ完了時に継続プロンプトを必ず提示する」（優先度: 高）
