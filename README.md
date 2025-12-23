# narou.rb Docker イメージ (カスタムビルド)

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

TrueNAS Scale での運用を想定し、現在更新が止まっている narou.rb に対して必要なパッチや設定を適用したカスタムビルド版です。

## 特徴

- **Oracle OpenJDK 21 (LTS)** - 最新の安定版 JDK
- **AozoraEpub3 最新版** - GitHub から最新リリースを自動取得
- **narou 3.9.1 + PR446 パッチ** - [Issues #446](https://github.com/whiteleaf7/narou/issues/446) 対応
- **kindlegen 統合** - Kindle (MOBI) 形式への変換対応
- **User-Agent 設定** - Chrome 131、[Issues #430](https://github.com/whiteleaf7/narou/issues/430) 対応

> **注意**: narou 3.9.1 で固定しています。公式で不具合修正された場合、このパッチは不要になる可能性があります。

## 構成

```
narou-docker/
├── dockerfile          # イメージ定義
├── docker-compose.yml  # 起動設定
├── init.sh            # 初期化スクリプト
├── LICENSE            # MIT License
├── .gitignore         # Git除外設定
└── README.md          # このファイル
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
docker tag narou:3.9.1 your-username/narou:3.9.1
docker push your-username/narou:3.9.1
```

### 2. Custom Apps での設定

- **Image**: `your-username/narou:3.9.1`
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
- **[kokotaro/narou-docker](https://github.com/kokotaro/narou)** - Docker 実装のベースと PR446 パッチ
- **[kyukyunyorituryo/AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3)** - EPUB 変換ツール
- **[参考記事](https://qiita.com/kokotaro@github/items/5c8da7281407b7484507)** - Docker 化の参考

### 主な変更点

- Adoptium Temurin → **Oracle OpenJDK 21 (LTS)** への変更
- AozoraEpub3 の**最新版自動取得**
- **kindlegen の統合**（Web Archive から取得）
- **User-Agent 設定**の改善
- ドキュメントとコードの整備
