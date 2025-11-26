# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.0.0

## 開発の目的

プロンプトファイルとバージョンごとの成果物を分離し、以下を実現する：

1. **プロンプトの一元管理**: スターターキットの改善がすべてのバージョンに反映される
2. **成果物の分離**: バージョンごとの実装内容は独立して管理される
3. **メンテナンス性向上**: プロンプト更新時に全バージョンを修正する必要がない
4. **再利用性の向上**: 基本的な機能はそのままで、再利用性を高める

## ターゲットユーザー

**既にv0.1.0を使用している既存ユーザー（マイグレーション対象）**

- v0.1.0からv1.0.0への移行を行うユーザー
- 移行後、v1.1.0等の新バージョンを新構造で開始するユーザー

## ビジネス価値

### 既存ユーザーへの価値

1. **イニシャルコストの激減**: v1.0.0以降、新バージョン開始時のセットアップコストが大幅に削減される
2. **継続的な改善の恩恵**: スターターキットの改善が自動的にすべてのバージョンに反映される
3. **一貫性の向上**: すべてのバージョンで同じプロンプトを使用するため、動作が一貫する

### スターターキットメンテナンスへの価値

1. **メンテナンス負荷の軽減**: プロンプト更新が1箇所で完結
2. **スケーラビリティの向上**: 新バージョン追加時の作業量が削減
3. **品質の向上**: 共通化により、バグ修正や改善が全バージョンに即座に反映

## 成功基準

1. **v0.1.0の成果物をそのまま維持しながら、新構造でv1.1.0等の新バージョンを開始できる**
2. **v1.0.0以降、イニシャルコストが激減する**（プロンプトファイルの共通化により）
3. 既存のv0.1.0機能（進捗管理、一問一答、JIT生成等）がすべて動作する
4. 新構造でInception/Construction/Operations Phaseが正常に動作する
5. ドキュメントが新構造を正確に説明している

## 期限とマイルストーン

**期限**: 本日中（2025-11-24）にv1.0.0を完了

### マイルストーン

1. **Inception Phase完了**: Intent、ユーザーストーリー、Unit定義、PRFAQ、進捗管理ファイル作成
2. **Construction Phase完了**: 全Unitの実装完了
3. **Operations Phase完了**: VERSIONファイル更新、Gitタグ作成、リリース

## 制約事項

### 技術的制約

- **技術スタック**: Markdown、Bashスクリプト、Git（v0.1.0と同じ）
- **文字エンコーディング**: UTF-8
- **言語**: 日本語

### 開発上の制約

- **既存のv0.1.0ドキュメントは削除・変更しない**（そのまま保持）
- **docs/example/ は削除する**（新構造への移行のため）
- 基本的な機能（進捗管理、一問一答、JIT生成等）はそのまま維持

## 新しいディレクトリ構造

### 現在の構造（v0.1.0）
```
docs/
├── example/
│   └── v1/
│       ├── prompts/          # バージョンごとに生成（問題点）
│       ├── templates/        # バージョンごとに生成
│       ├── requirements/
│       └── ...
└── versions/
    └── v1.0.0/
        ├── prompts/
        ├── templates/
        └── ...
```

### 新しい構造（v1.0.0以降）
```
docs/
├── aidlc/                    # 共通プロンプト（全バージョン共通）
│   ├── prompts/
│   │   ├── inception.md      # common.mdの内容を含む
│   │   ├── construction.md   # common.mdの内容を含む
│   │   ├── operations.md     # common.mdの内容を含む
│   │   └── additional-rules.md  # 共通の追加ルール
│   ├── templates/            # 共通テンプレート
│   │   ├── intent_template.md
│   │   ├── user_stories_template.md
│   │   ├── unit_definition_template.md
│   │   └── prfaq_template.md
│   └── version.txt           # スターターキットのバージョン（例: 1.0.0）
│
└── versions/                 # バージョンごとの成果物
    └── v1.0.0/
        ├── plans/
        ├── requirements/
        ├── story-artifacts/
        ├── design-artifacts/
        ├── construction/
        │   ├── progress.md   # 進捗管理
        │   └── units/
        ├── operations/
        ├── history.md        # 実行履歴（バージョンごと）
        └── additional-rules.md  # バージョン固有の追加ルール（オプション）
```

### セットアップフロー

1. **初回セットアップ**: ユーザーが`prompts/setup-prompt.md`を参照して実行
2. **セットアップ完了後**: `docs/aidlc/version.txt`にスターターキットのバージョンを記録
3. **アップデート時**: `docs/aidlc/version.txt`を見て、スターターキットの更新を確認

## 主要な変更点

### 1. プロンプトファイルの共通化

- `docs/aidlc/prompts/` に全バージョン共通のプロンプトを配置
- 各フェーズプロンプト（inception.md、construction.md、operations.md）の先頭にcommon.mdの内容を含める
- **ユーザーは各フェーズで1ファイルだけ読めばOK**

### 2. テンプレートの共通化

- `docs/aidlc/templates/` に全バージョン共通のテンプレートを配置
- JIT生成は維持しつつ、生成先を共通ディレクトリに変更

### 3. バージョンごとの成果物を分離

- `docs/versions/{VERSION}/` にバージョン固有の成果物を配置
- 実装記録、進捗管理、履歴などバージョン固有の情報のみ

### 4. additional-rules.mdの扱い

- 共通: `docs/aidlc/prompts/additional-rules.md`
- バージョン固有: `docs/versions/{VERSION}/additional-rules.md`（オプション）

### 5. バージョン管理

- セットアップ完了時に`docs/aidlc/version.txt`を作成し、使用したスターターキットのバージョンを記録
- v1.0.0完了時、`VERSION`ファイルを1.0.0に更新し、Gitタグ（v1.0.0）を作成

## 不明点と質問（Inception Phase中に記録）

### 質問と回答の履歴

[Question 1] 主要ターゲットユーザーは？
[Answer 1] 既にv0.1.0を使用している既存ユーザー（マイグレーション対象）

[Question 2] 成功基準の測定方法は？
[Answer 2] v0.1.0の成果物をそのまま維持しながら、新構造でv1.1.0等の新バージョンを開始できる。それ以降にイニシャルコストが激減する。

[Question 3] 期限とマイルストーンは？
[Answer 3] 本日中（2025-11-24）にv1.0.0を完了

[Question 4] マイグレーション方針は？
[Answer 4] docs/example/ は削除する

[Question 5] 技術的な制約事項は？
[Answer 5] 基本的な機能はそのままで再利用性を高めることを目的とする

[Question 6] バージョン管理の扱いは？
[Answer 6] VERSIONファイルを1.0.0に更新し、Gitタグ（v1.0.0）を作成

[Question 7] additional-rules.mdの扱いは？
[Answer 7] 共通+バージョン固有（両方使用）

[Question 8] プロンプトファイルの読み込み方法は？
[Answer 8] 各フェーズプロンプトの先頭にcommon.mdの内容を含める（ユーザーは1ファイルだけ読めばOK）

[Question 9] 履歴管理ファイル（history.md）の配置は？
[Answer 9] バージョンごと（docs/versions/v1.0.0/history.md）

[Question 10] setup-prompt.mdの配置は？
[Answer 10] セットアップ用の薄いファイルを作成し、セットアップ時のバージョンを記録

[Question 11] テンプレートファイルの配置は？
[Answer 11] 共通テンプレートとして配置（docs/aidlc/templates/）
