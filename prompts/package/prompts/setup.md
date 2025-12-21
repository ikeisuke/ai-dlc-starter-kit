# サイクルセットアップ プロンプト

---

## AI-DLC手法の要約

AI-DLCは、AIを開発の中心に据えた新しい開発手法です。従来のSDLCやAgileが「人間中心・長期サイクル」を前提としているのに対し、AI-DLCは「AI主導・短サイクル」で開発を推進します。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **冪等性の保証**: 各ステップで既存成果物を確認し、差分のみ更新

**3つのフェーズ**: Inception（要件定義）→ Construction（実装）→ Operations（運用）
- **Inception**: Intentを具体的なUnitに分解し、ユーザーストーリーを作成
- **Construction**: ドメイン設計・論理設計・コード・テストを生成
- **Operations**: デプロイ・監視・運用を実施

**主要アーティファクト**:
- **Intent**: 開発の目的と狙い
- **Unit**: 独立した価値提供ブロック（Epic/Subdomainに相当）
- **Domain Design**: DDDに従ったビジネスロジックの構造化
- **Logical Design**: 非機能要件を反映した設計層

---

## プロジェクト情報

### プロジェクト概要
AI-DLC (AI-Driven Development Lifecycle) スターターキット - AIを開発プロセスの中心に据えた新しい開発方法論の実践キット

### ディレクトリ構成
- `docs/aidlc/`: 全サイクル共通の共通プロンプト・テンプレート
- `docs/cycles/{{CYCLE}}/`: サイクル固有成果物
- `prompts/`: セットアッププロンプト

---

## あなたの役割

あなたはプロジェクトセットアップ担当者です。新しいサイクルのディレクトリ構造を作成します。

---

## 最初に必ず実行すること

### 1. サイクルバージョンの決定

#### 1.1 既存サイクルの検出

```bash
ls -d docs/cycles/*/ 2>/dev/null | sort -V
```

#### 1.2 バージョン提案

**ケース A: 既存サイクルがある場合**

最新バージョンから次バージョンを提案:

```
既存サイクル: [一覧]
最新バージョン: v{X}.{Y}.{Z}

次バージョンの提案:
1. v{X}.{Y}.{Z+1}（パッチ - バグ修正・小さな変更）[推奨]
2. v{X}.{Y+1}.0（マイナー - 新機能追加）
3. v{X+1}.0.0（メジャー - 破壊的変更）
4. その他（カスタム入力）

どれを選択しますか？
```

**ケース B: 既存サイクルがない場合（初回サイクル）**

プロジェクトのバージョン情報を調査（package.json, pyproject.toml 等）:

```
プロジェクトバージョン [検出されたバージョン] を検出しました（ソース: [ファイル名]）。

このバージョンをサイクルバージョンとして使用しますか？
1. はい、v[検出されたバージョン] を使用する
2. いいえ、別のバージョンを入力する
```

バージョンが検出されなかった場合は `v1.0.0` を提案。

#### 1.3 重複チェック

選択されたバージョンが既存サイクルと重複する場合、エラーを表示して再選択。

### 2. ブランチ確認【推奨】

現在のブランチを確認し、サイクル用ブランチでの作業を推奨：

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "現在のブランチ: ${CURRENT_BRANCH}"
```

`docs/aidlc.toml` の `[rules.worktree]` 設定を確認:

```bash
grep -A1 "^\[rules.worktree\]" docs/aidlc.toml 2>/dev/null | grep "enabled" | grep -q "true" && echo "WORKTREE_ENABLED" || echo "WORKTREE_DISABLED"
```

**判定**:
- **main または master の場合**: サイクル用ブランチの作成を提案

  **worktree が有効な場合（WORKTREE_ENABLED）**:
  ```
  現在 main/master ブランチで作業しています。
  サイクル用ブランチで作業することを推奨します。

  1. git worktreeを使用して新しい作業ディレクトリを作成する
  2. 新しいブランチを作成して切り替える: git checkout -b cycle/{{CYCLE}}
  3. 現在のブランチで続行する（非推奨）

  どれを選択しますか？
  ```

  **worktree が無効な場合（WORKTREE_DISABLED）- デフォルト**:
  ```
  現在 main/master ブランチで作業しています。
  サイクル用ブランチで作業することを推奨します。

  1. 新しいブランチを作成して切り替える: git checkout -b cycle/{{CYCLE}}
  2. 現在のブランチで続行する（非推奨）

  どちらを選択しますか？
  ```

  - **worktree を選択**: worktree 作成手順を案内（セクション末尾参照）
  - **ブランチ作成を選択**: `git checkout -b cycle/{{CYCLE}}` を実行
  - **続行を選択**: 警告を表示して続行
    ```
    警告: main/master ブランチで直接作業しています。
    変更は直接 main/master に反映されます。
    ```
- **それ以外のブランチ**: 次のステップへ進行

### 3. サイクル存在確認

`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

- **存在する場合**: 既存サイクルへの案内
  ```
  サイクル {{CYCLE}} は既に存在します。

  Inception Phase を開始するには、以下のプロンプトを読み込んでください：
  docs/aidlc/prompts/inception.md
  ```
- **存在しない場合**: ステップ4（バージョン確認）へ進む

### 4. バージョン確認

```bash
# スターターキットの最新バージョン（GitHubから取得、タイムアウト5秒）
LATEST_VERSION=$(curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null | tr -d '\n' || echo "")

# 現在使用中のバージョン（aidlc.toml の starter_kit_version）
CURRENT_VERSION=$(grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml 2>/dev/null || echo "")

echo "最新: ${LATEST_VERSION:-取得失敗}, 現在: ${CURRENT_VERSION:-なし}"
```

**判定**:
- **最新バージョン取得失敗**: ステップ5（プロジェクトタイプ確認）へ進む
- **CURRENT_VERSION が空**: ステップ5（プロジェクトタイプ確認）へ進む（aidlc.tomlなし）
- **LATEST_VERSION > CURRENT_VERSION**: アップグレード推奨を表示
  ```
  AI-DLCスターターキットの新しいバージョンが利用可能です。
  - 現在: [CURRENT_VERSION]
  - 最新: [LATEST_VERSION]

  アップグレードを推奨します。どうしますか？
  1. アップグレードする
  2. 現在のバージョンで続行する
  ```
  - **1 を選択**: セットアップを案内して終了
    ```
    アップグレードするには、スターターキットの setup-prompt.md を読み込んでください。
    ```
  - **2 を選択**: ステップ5（プロジェクトタイプ確認）へ進む
- **LATEST_VERSION = CURRENT_VERSION**: ステップ5（プロジェクトタイプ確認）へ進む

### 5. プロジェクトタイプ確認

`docs/aidlc.toml` の `[project]` セクションで `type` を確認。

**未設定の場合**:

```
プロジェクトタイプを選択してください:

1. web - Webアプリケーション
2. backend - バックエンドAPI/サーバー
3. cli - コマンドラインツール
4. desktop - デスクトップアプリ
5. ios - iOSアプリ
6. android - Androidアプリ
7. general - 汎用/未分類（デフォルト）

どれを選択しますか？
```

選択後、`docs/aidlc.toml` の `[project]` セクションに `type = "{選択した値}"` を追加。

**設定済みの場合**:
現在の設定を表示して次のステップへ進む。

```
プロジェクトタイプ: {現在の値}
```

### 6. サイクルディレクトリ作成

ユーザーに確認：
```
サイクル {{CYCLE}} のディレクトリを作成します。
よろしいですか？（Y/n）
```

- **拒否された場合**: 終了
  ```
  サイクル作成を中止しました。
  ```

- **承認された場合**: 以下を実行

**ディレクトリ構造作成**:
```bash
mkdir -p docs/cycles/{{CYCLE}}/plans
mkdir -p docs/cycles/{{CYCLE}}/requirements
mkdir -p docs/cycles/{{CYCLE}}/story-artifacts/units
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/domain-models
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/logical-designs
mkdir -p docs/cycles/{{CYCLE}}/design-artifacts/architecture
mkdir -p docs/cycles/{{CYCLE}}/inception
mkdir -p docs/cycles/{{CYCLE}}/construction/units
mkdir -p docs/cycles/{{CYCLE}}/operations
```

**history/ ディレクトリ初期化**:
```bash
mkdir -p docs/cycles/{{CYCLE}}/history
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF > docs/cycles/{{CYCLE}}/history/inception.md
# Inception Phase 履歴

## ${TIMESTAMP}

- **フェーズ**: サイクルセットアップ
- **実行内容**: サイクル開始
- **プロンプト**: -
- **成果物**: docs/cycles/{{CYCLE}}/（サイクルディレクトリ）
- **備考**: -

---
EOF
```

**共通バックログディレクトリ確認**:
```bash
mkdir -p docs/cycles/backlog
mkdir -p docs/cycles/backlog-completed
```

**注意**: サイクル固有バックログは廃止されました。気づきは共通バックログ（`docs/cycles/backlog/`）に直接記録します。

---

## 完了時の作業

### 1. Gitコミット（任意）

```
サイクル {{CYCLE}} を作成しました。Gitコミットを作成しますか？（Y/n）
```

承認された場合:
```bash
git add docs/cycles/{{CYCLE}}/
git add docs/cycles/backlog/
git add docs/cycles/backlog-completed/
git commit -m "feat: サイクル {{CYCLE}} 開始"
```

### 2. 完了メッセージと次のステップ

```
サイクル {{CYCLE}} の準備が完了しました！

作成されたファイル:
- docs/cycles/{{CYCLE}}/history/inception.md
- docs/cycles/{{CYCLE}}/（各種ディレクトリ）
- docs/cycles/backlog/（共通バックログ、初回のみ）

---
## 次のステップ

Inception Phase を開始するには、以下のプロンプトを読み込んでください：
docs/aidlc/prompts/inception.md
```

---

## 補足: git worktree の使用

worktree を選択した場合の手順:

```
## git worktree の使用

git worktreeを使うと、同じリポジトリの複数ブランチを別ディレクトリで同時に開けます。
複数サイクルの並行作業に便利です。

**推奨ディレクトリ構成**:

~/projects/
├── my-project/              # メインディレクトリ（mainブランチ）
├── my-project-v1.4.0/       # worktree（cycle/v1.4.0ブランチ）
└── my-project-v1.5.0/       # worktree（cycle/v1.5.0ブランチ）

**worktree作成コマンド**:

# 親ディレクトリに移動してworktreeを作成
cd ..
git -C [元のディレクトリ名] worktree add -b cycle/{{CYCLE}} [元のディレクトリ名]-{{CYCLE}}
cd [元のディレクトリ名]-{{CYCLE}}

作成後、新しいディレクトリでセッションを開始してください。
```
