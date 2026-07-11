# Intent: v3.0.0-beta.3

## 目的

Phase 7 本流化（7-e）の残り前提である release hard gate の required CI 0 件フォールバック（#745 / 7-d 残り）と v2 → v3 migration 実装（7-c）を完成させ、v3 を本流化可能な状態にする。

## スコープ

### 含むもの

- #745: release Step 3-4 hard gate に「required CI 0 件」時のフォールバック仕様を明文化 + 実装
  - 一般化された挙動として定義する（starter kit 固有判定を本体に埋めない / Issue 論点 b）
  - 発動は opt-in（config フラグ or 明示ユーザー確認手順 / Issue 論点 a）とし、既定は現行 fail-closed を維持する
- v3 config.toml キー終端設計の確定（migration.md §8 記載の SoT ギャップ解消 / migration の config 変換の前提）
- 7-c: v2 → v3 migration 実装（`docs/v3/migration.md` §6 の手順方針準拠）
  - new-cycle-only（推奨モード）を必須実装: v2 config 読み込み → v3 config 生成 + state.json 初期化
  - archive-only（v2 cycles の所在 index 生成のみ）を併せて実装

### 含まないもの

- best-effort モードの変換実装（units → work-items / progress → state.json / history → journal 等の実データ変換）→ 後続サイクルへ defer（変換量が大きく、v2 EOL 3 条件の consumer テストとセットで扱う / Epic #736 に注記）
- 7-e フル本流化（skills/aidlc-v3 → skills/aidlc 置換 / README 刷新 / GA 化）そのもの
- `v3.0.0` 統合ブランチへの CI トリガー追加（#745 論点 c / 別軸の CI 設定変更）

## 受け入れ基準

- [ ] AC-1: release.md hard gate に required CI 0 件フォールバックが opt-in として明文化され、既定挙動（fail-closed）が非影響である
- [ ] AC-2: v3 config.toml のキー終端集合が確定文書に記載され、migration.md §8 の SoT ギャップ注記が解消される
- [ ] AC-3: new-cycle-only migration が実行可能である（v2 config → v3 config 生成 + state.json 初期化 + モード選択・変換結果確認の人間ゲート）
- [ ] AC-4: archive-only migration が実行可能である（v2 cycles の index 生成）
- [ ] AC-5: 片方向移行（rollback 不可）の警告が migration 実行時に明示される
- [ ] AC-6: 全テストスイート / shellcheck / parse-guard が green である

## 制約・前提

- migration は renewal-plan の risky 昇格条件（migration → 自動的に risky）に該当するため、該当 work item は risky（design + 厚いレビュー）で扱う
- 「ドッグフーディング特殊処理を本体に埋めない」原則に従う（構造・環境の判別は opt-in シグナル / 明示フラグで表現する）
- Relates to #736（Epic: Phase 4–7 ロードマップ / 7-c・7-d）/ #745
