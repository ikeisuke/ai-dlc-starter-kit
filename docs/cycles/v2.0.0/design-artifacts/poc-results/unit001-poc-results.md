# PoC検証結果: スキル機能検証

検証日: 2026-03-26

## 検証1: オンデマンドRead（on-demand-read）

- **capability**: on-demand-read
- **status**: supported
- **observed_output**: Readツールがスキルベースディレクトリからの相対パスで `steps/sample-step.md` を正常に読み込み、検証マーカーがコンテキストに出力された
- **constraints**: なし
- **decision**: step-splitting（steps/ディレクトリによるステップ分割方式を採用）

### 詳細

- SKILL.md内の「`steps/sample-step.md` を読み込んでください」の指示に対し、Claude Codeがスキルのベースディレクトリからの相対パスとして解決
- Readツールで絶対パス `{base_directory}/steps/sample-step.md` に変換して読み込みを実行
- ファイル内容（検証マーカー含む）が正常にコンテキストに読み込まれた

### 確認済み範囲

- 正常系: 存在するファイルの相対パス読み込み（1パターン）
- 未確認: ファイル未存在時の挙動、ネストされたディレクトリからの読み込み、権限不足時の挙動

## 検証2: スキル間呼び出し（skill-invocation）

- **capability**: skill-invocation
- **status**: supported
- **observed_output**: Skillツールでcallee側スキルが正常にロードされ、callee側の固定応答がcaller側のコンテキストに返された
- **constraints**: なし
- **decision**: skill-tool-invocation（Skillツール経由でreviewing-*を呼び出し）

### 詳細

- poc-callerのSKILL.md内の「Skillツールを使って `poc-callee` スキルを呼び出してください」の指示に対し、Claude CodeがSkillツールを使用
- `Skill(poc-callee)` → `Successfully loaded skill` と表示され、callee側のSKILL.mdが正常にロード
- callee側の固定応答がcaller側のコンテキストに正常に返された
- Skillツールはallowed-toolsに明示指定しなくてもデフォルトで利用可能（暗黙的依存）

### 確認済み範囲

- 正常系: 登録済みスキルのSkillツール呼び出し（1パターン）
- 未確認: 未登録スキル呼び出し時の挙動、引数付き呼び出し、呼び出し拒否時の挙動

## v2.0.0 実装方針サマリ

両検証とも正常系で **supported** を確認。現時点ではフォールバック戦略は不要と判断する。異常系の挙動は後続Unitの実装時に必要に応じて追加検証する。

| 機能 | 方針 | 根拠 |
|------|------|------|
| ファイル読み込み | **steps/ディレクトリによるステップ分割** | SKILL.md内のRead指示で相対パスが正常に解決される |
| スキル間連携 | **Skillツール経由でreviewing-*を直接呼び出し** | Skillツールによるスキル間呼び出しが正常に動作する |

### 制約・前提条件

- Skillツールはallowed-toolsに明示指定しなくてもデフォルトで利用可能（PoC検証時点の挙動。将来のClaude Codeアップデートで変更される可能性あり）
- 検証はローカルの `~/.claude/skills/` にインストールしたスキルで実施。プラグイン経由のインストール時も同様に動作する前提

### 後続Unitへの影響

- **Unit 002（リポジトリ構造基盤）**: skills/ディレクトリにsteps/サブディレクトリを含む構造を採用可能
- **Unit 004（共通基盤）**: steps/common/ に共通ステップを配置し、SKILL.mdからRead指示で参照
- **Unit 005-008（各フェーズスキル）**: steps/{phase}/ にフェーズ固有ステップを配置
- **レビュー連携**: review-flow内からSkillツールでreviewing-*スキルを直接呼び出し可能（内容コピー不要）

### テストスキルの後処理

検証完了後、以下のテストスキルは削除可能:
- `~/.claude/skills/poc-read-test/` → 削除済み
- `~/.claude/skills/poc-caller/` → 削除済み
- `~/.claude/skills/poc-callee/` → 削除済み
- `prompts/poc/`（ソースファイル）→ リポジトリに残置（検証の再現性のため）
