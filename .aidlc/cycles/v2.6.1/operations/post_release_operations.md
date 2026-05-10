# リリース後の運用記録: v2.6.1

## リリース情報

- **バージョン**: v2.6.1
- **リリース日**: 2026-05-11
- **リリース内容**: v2.6.0 リリース後に検出された 5 件のクリティカル / UX / 設計原則 / CI ノイズ問題を一括解消する patch リリース

## 含まれる修正

| Unit | 内容 | 関連 Issue |
|------|------|----------|
| Unit 001 | `version.sh` の zsh OOM クラッシュ修正（CLI モードガード追加） | #688 |
| Unit 002 | Cycle Phase Completion Check の draft PR skip | #686 |
| Unit 003 | `aidlc-feedback` の `--web` 強制起動解消（opt-in 化） | #690 |
| Unit 004 | dasel 直接呼び出しの `read-config.sh` 経由統一 + 規約追記 | #689 |
| Unit 005 | `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化 | #687 |

## 観測ポイント（次サイクル以降）

- v2.6.1 適用後の consumer プロジェクトで `squash-unit.sh` 実行時、設定不在による集約 skip が観測されること（Unit 005 の新挙動）
- Unit 004 の `dasel -f` anti-pattern 発生再発がないこと（rules-core.md 規約追記の効果測定）
- Unit 001 の zsh OOM 再発がないこと（version.sh 直接実行時の挙動確認）

## バグ対応

### 修正済みバグ

- v2.6.0 適用環境での 5 件（上表）

### 未修正バグ

なし（v2.6.1 時点）

## 次サイクル候補

- Issue #691（汎用 CI チェックの v2.7.0 設計検討）
- read-config.sh への `--format=lines` モード追加（Unit 005 暫定 IF の解消）
- その他 backlog ラベル付き Issue（30 件超 / 振り返り `/aidlc r v2.6.1` で優先度確認推奨）

## 備考

本サイクルは 5 Unit を構造的予防中心に消化する patch リリースとして完了。各 Unit のレビューは codex で 3-4 round 実施し、unresolved 0 で着地。
