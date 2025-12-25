# narou.rb Docker イメージ (カスタムビルド)

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

## 概要

TrueNAS Scale での運用を想定し、現在更新が止まっている narou.rb に対して必要なパッチや設定を適用したカスタムビルド版です。

本イメージは、依存関係・小説ページ構造の変更・Linux User-Agent問題・ハーメルン403エラーなどを修正された [Rumia-Channel/narou (dockerブランチ)](https://github.com/Rumia-Channel/narou/tree/docker) をベースに、WebSocket機能の修正パッチを適用して構築しています。

> **謝辞**: narou.rb を開発された [whiteleaf7](https://github.com/whiteleaf7) 氏、narou.rb の改良・拡張を継続されている [Rumia-Channel](https://github.com/Rumia-Channel) 氏、改造版 AozoraEpub3 を開発された [kyukyunyorituryo](https://github.com/kyukyunyorituryo) 氏に深く感謝いたします。

## 特徴

- **Ruby 3.4** - Rumia版が要求する最新の安定版
  - 3.4系の最新パッチバージョンを自動取得
- **Oracle OpenJDK Java 21（LTS）** - 最新の安定版 JDK
  - Oracle 公式の Java を利用し、安定性を重視
  - LTS バージョンのため、長期的なサポートが受けられる
- **[改造版 AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3) 最新版** - GitHub から最新リリースを自動取得
- **Rumia's narou fork (docker branch)** - Linux User-Agent問題とハーメルン403エラーを解決
  - Web サーバーの代替として tilt が不要になり、依存関係を削減
  - 小説の取得方法を wget ベースに変更し、Linux/Docker 環境に最適化
- **kindlegen 統合** - Kindle (MOBI) 形式への変換対応
- **WebSocket修正パッチ適用** - リアルタイムログ表示機能を完全動作
  - Rumia-Channel 氏の dockerブランチは nginx 経由での運用を想定（443ポート一本化）
  - 本イメージではポート分離環境での動作を実現するため、WebSocket接続部分に[WebSocket 修正パッチ](fix-websocket-port.patch)を適用
- **iBooks変換修正パッチ適用** - Apple iBooks 形式への変換も安定動作
  - iBooks形式を含む、EPUB/i文庫/Kindle/Kobo/SonyReader等すべての端末形式への変換が成功
  - [iBooks 修正パッチ](fix-ibooks-args.patch)を適用し、iBooks形式の変換エラー（引数不一致）を解消

> **注意**: narou.rb 本体は [Rumia-Channel/narou (dockerブランチ)](https://github.com/Rumia-Channel/narou/tree/docker) を使用しています。

## 構成

```
narou-docker/
├── dockerfile                # イメージ定義
├── docker-compose.yml        # 起動設定
├── init.sh                   # 初期化スクリプト
├── fix-websocket-port.patch  # WebSocket修正パッチ
├── LICENSE                   # MIT License
├── .gitignore                # Git除外設定
└── README.md                 # このファイル
```

## 使用方法

### 基本的な使い方

```bash
# ビルド
docker compose build

# 起動（バックグラウンド）
docker compose up -d

# 停止
docker compose down
```

### アクセス

ブラウザで http://localhost:9200 にアクセス

## 設定

### ポート

| ポート | 用途 |
|--------|------|
| 9200 | Web UI |
| 9201 | WebSocket |

### ボリューム

カレントディレクトリが `/home/narou/novel` にマウントされます。  
小説データ、設定ファイル（`.narou`, `.narousetting`）はここに保存されます。

### UID/GID のカスタマイズ

デフォルトは `1000:1000` です。変更する場合は `docker-compose.yml` を編集：

```yaml
args:
  UID: 1001
  GID: 1001
```

## TrueNAS Scale での使用

### 1. Docker Hub へのプッシュ（推奨）

```bash
docker tag narou:iruka your-username/narou:iruka
docker push your-username/narou:iruka
```

### 2. Custom Apps での設定

- **Image**: `your-username/narou:iruka`
- **Port Forwarding**: 
  - Host: 9200 → Container: 33000
  - Host: 9201 → Container: 33001
- **Storage**: Host Path を指定（小説データの保存先）

## トラブルシューティング

### 権限エラー

```bash
docker compose down
sudo rm -rf .narou .narousetting
docker compose up
```

### 403 Forbidden エラー

サイト側のアクセス制限により発生する可能性があります。  
Web UI の設定からダウンロード間隔を長くしてください。

### kindlegen について

**重要**: kindlegen は Amazon が配布を終了しています。

現在は **Web Archive** から取得していますが、以下のリスクがあります：

- Web Archive のポリシー変更によりアクセス不可になる可能性
- 将来的にビルドが失敗する可能性

**ビルドが失敗した場合の対応**:
- EPUB 形式のみでの利用を検討してください
- Kindle への転送は、Kindle の「Send to Kindle」機能で EPUB を直接送信できます（最近の Kindle は EPUB をサポート）

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

## 謝辞・参考

このプロジェクトは以下を参考・使用して作成されました：

- **[whiteleaf7/narou](https://github.com/whiteleaf7/narou)** (MIT License) - narou.rb 本体
- **[Rumia-Channel/narou (dockerブランチ)](https://github.com/Rumia-Channel/narou/tree/docker)** - Linux/Docker 環境に最適化された改良版
  - Linux User-Agent 問題とハーメルン403エラーの解決
  - 依存関係の削減と wget ベースの実装
- **[kokotaro/narou-docker](https://github.com/kokotaro/narou)** - Docker 実装のベース
- **[kyukyunyorituryo/AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3)** - EPUB 変換ツール
- **[参考記事](https://qiita.com/kokotaro@github/items/5c8da7281407b7484507)** - Docker 化の参考

### 主な変更点

- Ruby 3.4.1 固定 → **Ruby 3.4 自動更新**（Rumia版の要件に対応）
- Adoptium Temurin 21 → **Oracle OpenJDK Java 21（LTS）** への変更
- AozoraEpub3 の**最新版自動取得**
- **kindlegen の統合**（Web Archive から取得）
- **Rumia's narou fork (docker branch)** 採用で Linux 環境の問題を解決
- **[WebSocket 修正パッチ](fix-websocket-port.patch)**でリアルタイムログ表示を復活
- ハーメルンなど各種サイトからのダウンロード動作を改善
- ドキュメントとコードの整備
