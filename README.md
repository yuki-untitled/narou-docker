# narou.rb Docker イメージ (カスタムビルド)

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

## 特徴

- **Oracle OpenJDK 21 (LTS)** - 最新の LTS バージョン
- **AozoraEpub3 最新版** - 自動取得
- **narou 3.9.1** - PR446 パッチ適用済み
- **kindlegen 対応** - Kindle (MOBI) 形式への変換可能
- **User-Agent 設定済み** - Chrome 131 として動作

## 構成

```
my-narou/
├── dockerfile          # イメージ定義
├── docker-compose.yml  # 起動設定
├── init.sh            # 初期化スクリプト
└── README.md          # このファイル
```

## 使用方法

### 1. ビルド

```bash
docker compose build
```

### 2. 起動

```bash
docker compose up -d
```

### 3. アクセス

ブラウザで `http://localhost:9200` にアクセス

### 4. 停止

```bash
docker compose down
```

## 設定

### ポート

- `9200`: Web UI
- `9201`: WebSocket

### ボリューム

カレントディレクトリが `/home/narou/novel` にマウントされます。
小説データ、設定ファイルはここに保存されます。

### UID/GID

デフォルトは `1000:1000` です。変更する場合は docker-compose.yml を編集：

```yaml
args:
  UID: 1001
  GID: 1001
```

## TrueNAS Scale での使用

1. Docker Hub にイメージを push（オプション）
2. Custom Apps で設定：
   - Image: ビルドしたイメージ名
   - Ports: 9200→33000, 9201→33001
   - Storage: Host Path を指定

## トラブルシューティング

### 権限エラーが出る

```bash
docker compose down
sudo rm -rf .narou .narousetting
docker compose up
```

### 403 Forbidden エラー

アクセス間隔を長くしてください（Web UI から設定可能）

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

## 謝辞・参考

このプロジェクトは以下を参考・使用して作成されました：

- **[whiteleaf7/narou](https://github.com/whiteleaf7/narou)** - narou.rb 本体 (MIT License)
- **[kokotaro/narou-docker](https://github.com/kokotaro/narou)** - ベースとなった Docker 実装と PR446 パッチ
- **[kyukyunyorituryo/AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3)** - EPUB 変換ツール
- [元記事](https://qiita.com/kokotaro@github/items/5c8da7281407b7484507)

### 変更点（オリジナル）

- Oracle OpenJDK 21 (LTS) への変更
- AozoraEpub3 最新版の自動取得
- kindlegen の統合
- User-Agent 設定の改善
- 各種最適化とドキュメント整備
