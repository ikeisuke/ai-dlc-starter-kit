# Unit 2: セットアップスキップ 実装計画

## 概要

アップグレード不要時にセットアップをスキップしてInception Phaseを直接開始できるようにする。
サイクルディレクトリの自動作成と最新バージョン通知を含む。

## 含まれるユーザーストーリー

- ストーリー2: セットアップスキップ（サイクル自動作成）
- ストーリー3: 最新バージョン通知

---

## Phase 1: 設計

### ステップ1: ドメインモデル設計

**変更対象**: `prompts/package/prompts/inception.md`

このUnitはプロンプトファイルの修正のみで、コード実装は不要。
ドメインモデル設計は以下の概念整理に限定:

- **サイクル存在確認フロー**: 存在しない場合の自動作成提案
- **バージョン比較フロー**: 最新バージョン通知の判断ロジック

**成果物**: `docs/cycles/v1.3.1/design-artifacts/domain-models/unit2_setup_skip_domain_model.md`

### ステップ2: 論理設計

inception.md の「ステップ1: サイクル存在確認」を以下のように改修:

1. **現在のフロー**:
   - サイクルが存在しない → エラー表示、セットアップを促す

2. **新しいフロー**:
   - サイクルが存在しない場合:
     1. バージョン比較: `prompts/package/version.txt` と `docs/aidlc/version.txt`
     2. バージョンが異なる場合: アップグレード推奨を通知
     3. バージョンが同じ、またはバージョンファイルがない場合:
        - サイクルディレクトリの自動作成を提案
        - ユーザー承認後、`setup-cycle.md` のステップ4〜6を実行
        - 作成完了後、Inception Phaseのステップ2へ継続

**成果物**: `docs/cycles/v1.3.1/design-artifacts/logical-designs/unit2_setup_skip_logical_design.md`

### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る。

---

## Phase 2: 実装

### ステップ4: コード生成

`prompts/package/prompts/inception.md` の「ステップ1: サイクル存在確認」セクションを改修:

```markdown
### 1. サイクル存在確認
`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

- **存在する場合**: 処理を継続
- **存在しない場合**: 以下のサブフローを実行

#### 1-1. バージョン確認
`prompts/package/version.txt` と `docs/aidlc/version.txt` を比較:

```bash
PACKAGE_VERSION=$(cat prompts/package/version.txt 2>/dev/null || echo "")
AIDLC_VERSION=$(cat docs/aidlc/version.txt 2>/dev/null || echo "")
echo "Package: ${PACKAGE_VERSION:-なし}, AIDLC: ${AIDLC_VERSION:-なし}"
```

- **バージョンが異なる場合**:
  ```
  AI-DLCツールキットの新しいバージョンが利用可能です。
  - 現在: [AIDLC_VERSION]
  - 最新: [PACKAGE_VERSION]

  アップグレードを推奨します。続行しますか？
  1. アップグレードする（setup-prompt.md を読み込み）
  2. 現在のバージョンで続行する
  ```

- **バージョンが同じ、またはバージョンファイルがない場合**: サイクル作成を提案

#### 1-2. サイクルディレクトリ作成
ユーザーに確認:
```
サイクル {{CYCLE}} のディレクトリが存在しません。
新規作成しますか？（Y/n）
```

承認後、以下を実行:
1. ディレクトリ構造作成
2. history.md 初期化
3. backlog.md 作成
4. Git コミット（任意）
```

### ステップ5: テスト生成

プロンプトの修正のみのため、テストコードは不要。
手動テスト手順を実装記録に記載。

### ステップ6: 統合とレビュー

- ビルド: N/A（プロンプトファイルのみ）
- テスト: 手動確認（新しいサイクルでInception Phase開始を試行）
- 実装記録作成

---

## 完了基準

- [x] ドメインモデル設計完了
- [x] 論理設計完了
- [ ] 設計レビュー承認
- [ ] inception.md の改修完了
- [ ] 手動テスト完了
- [ ] 実装記録作成
- [ ] Unit定義ファイルの状態を「完了」に更新
- [ ] 履歴記録
- [ ] Gitコミット

---

## 作成日

2025-12-12
