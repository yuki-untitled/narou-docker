# narou.rb Docker イメージ (公式版ベース・カスタムビルド)

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

このブランチでは、公式 [whiteleaf7/narou](https://github.com/whiteleaf7/narou) をベースにビルドしています。Rumia-Channel 版フォークをベースにしたイメージは [`rumia-narou` ブランチ](https://github.com/yuki-untitled/narou-docker/tree/rumia-narou) を参照してください。

> 本ブランチの技術的な方針（narou.rb の入手元、パッチの適用要否など）は [docs/spec/official-narou-policy.md](docs/spec/official-narou-policy.md) を参照してください。

## 概要

TrueNAS Scale での運用を想定し、公式 narou.rb（[whiteleaf7/narou](https://github.com/whiteleaf7/narou), rubygems.org 配信の最新リリース）をそのまま利用したカスタムビルド版です。

> **謝辞**: narou.rb を開発された [whiteleaf7](https://github.com/whiteleaf7) 氏、改造版 AozoraEpub3 を開発された [kyukyunyorituryo](https://github.com/kyukyunyorituryo) 氏に深く感謝いたします。

## 特徴

- **Ruby 3.4** - 3.4系の最新パッチバージョンを自動取得
- **Oracle OpenJDK Java 21（LTS）** - 最新の安定版 JDK を利用
- **[改造版 AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3) 最新版** - GitHub から最新リリースを自動取得
- **公式 narou.rb** - rubygems.org から `gem install narou` で最新リリースを取得
  - WebSocket のポートは `server-port + 1` が自動的に使われる仕様のため、追加のパッチは不要（詳細は [docs/spec/official-narou-policy.md](docs/spec/official-narou-policy.md)）
- **kindlegen 統合** - Kindle (MOBI) 形式への変換対応

> **注意**: narou.rb 本体は [whiteleaf7/narou](https://github.com/whiteleaf7/narou)（公式・rubygems.org 配信版）を使用しています。開発が止まっているため、依存関係やサイト構造の変化への追従は遅れる可能性があります。Linux 環境での既知の問題（User-Agent問題、ハーメルン403エラーなど）への対応が必要な場合は [`rumia-narou` ブランチ](https://github.com/yuki-untitled/narou-docker/tree/rumia-narou) を検討してください。

## 構成

```
narou-docker/
├── dockerfile                        # イメージ定義
├── docker-compose.yml                # 起動設定
├── init.sh                           # 初期化スクリプト
├── docs/spec/official-narou-policy.md # 本ブランチの方針（仕様）
├── LICENSE                           # MIT License
└── README.md                         # このファイル
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
| 9201 | WebSocket（server-port + 1 が自動的に使われる） |

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
docker tag narou:official your-username/narou:official
docker push your-username/narou:official
```

### 2. Custom Apps での設定

- **Image**: `your-username/narou:official`
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
Web UI の設定からダウンロード間隔を長くしてください。公式版では Rumia 版のようなハーメルン403対策は入っていないため、頻発する場合は [`rumia-narou` ブランチ](https://github.com/yuki-untitled/narou-docker/tree/rumia-narou) の利用も検討してください。

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
- **[kokotaro/narou-docker](https://github.com/kokotaro/narou)** - Docker 実装のベース
- **[kyukyunyorituryo/AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3)** - EPUB 変換ツール
- **[参考記事](https://qiita.com/kokotaro@github/items/5c8da7281407b7484507)** - Docker 化の参考
