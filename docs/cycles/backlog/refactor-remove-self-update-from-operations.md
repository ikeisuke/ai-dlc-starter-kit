# Operations Phaseでのセルフアップデートを廃止

- **発見日**: 2025-12-20
- **発見フェーズ**: サイクル開始時
- **発見サイクル**: -
- **優先度**: 中

## 概要

ai-dlc-starter-kit リポジトリの Operations Phase でセルフアップデート（AI-DLCの更新）を行う処理を廃止する。

## 詳細

現在、ai-dlc-starter-kit 自体の Operations Phase で AI-DLC のバージョンアップデートを実行しているが、これは他のリポジトリと異なる特殊な処理となっている。

他のリポジトリと同様に、通常のセットアップフロー（setup-prompt.md → アップグレード選択）でアップデートを行うように統一する。

## 対応案

- operations.md からセルフアップデート関連の処理を削除
- ai-dlc-starter-kit も他のプロジェクトと同じアップグレードフローを使用
