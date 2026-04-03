# 論理設計: aidlc-setupバージョン比較修正

## 概要
01-detect.mdのバージョン取得指示を、存在しないスクリプト参照からdasel直接呼び出しに変更する。

## 変更内容

### 変更箇所: skills/aidlc-setup/steps/01-detect.md 101行目

**現状**:
```
1. `scripts/read-config.sh starter_kit_version` でローカルバージョンを取得
```

**変更後**:
```
1. `.aidlc/config.toml` から `dasel -f .aidlc/config.toml 'starter_kit_version'` でローカルバージョンを取得（dasel未インストール時やキー不在時はフェイルセーフに委譲）
```

## フェイルセーフとの整合性

既存の103-107行目のフェイルセーフ判定ロジック:
- read-config.sh exit 1/2 → dasel失敗（exit非0）に読み替え
- version.txt不在/空 → 変更なし
- 正規化後の値が空 → 変更なし

フェイルセーフ判定の文面にも `read-config.sh exit 1/2` を `dasel実行失敗` に修正が必要。

## 実装上の注意事項
- daselコマンドの出力には引用符が付く場合があるため、正規化（引用符除去）が必要
- 01-detect.mdはAIエージェントへの指示文書であり、AIが指示に従ってコマンドを実行する形式
