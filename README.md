# narou.rb Docker イメージ (カスタムビルド)

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

## 概要

本イメージは、[kokotaro/narou-docker](https://github.com/kokotaro/narou-docker) をベースに、各種パッチや機能追加・修正を加えた改良版です。

> **重要: LinuxやDocker環境でnarou.rbを安定して利用したい場合は、[yuki-untitled/narou-docker](https://github.com/yuki-untitled/narou-docker/tree/master) のご利用をおすすめします。**
> 
> 本リポジトリ（originalブランチ）は「どうしてもオリジナル版をご利用になりたい方」向けです。User-Agent問題などの制約があるため、通常は上記の推奨版をご検討ください。

> **謝辞**: narou.rb を開発された [whiteleaf7](https://github.com/whiteleaf7) 氏、Dockerイメージを公開された [kokotaro](https://github.com/kokotaro) 氏、改造版 AozoraEpub3 を開発された [kyukyunyorituryo](https://github.com/kyukyunyorituryo) 氏に深く感謝いたします。

## 特徴

- **Ruby 3.4** - Rumia版が要求する最新の安定版
  - 3.4系の最新パッチバージョンを自動取得
- **Oracle OpenJDK Java 21（LTS）** - 最新の安定版 JDK
  - Oracle 公式の Java を利用し、安定性を重視
  - LTS バージョンのため、長期的なサポートが受けられる
- **[改造版 AozoraEpub3](https://github.com/kyukyunyorituryo/AozoraEpub3) 最新版** - GitHub から最新リリースを自動取得
- **narou 3.9.1 + PR446 パッチ** - [Issues #446](https://github.com/whiteleaf7/narou/issues/446) 対応
  - narou 3.9.1 で固定しています。
  - 公式で不具合修正された場合、このパッチは不要になる可能性があります。
- **User-Agent 設定** - Chrome 131、[Issues #430](https://github.com/whiteleaf7/narou/issues/430) 対応
  - Windows や MacOS では正常にUser-Agentが反映されます。
  - **Linux（特にDocker環境）ではUser-Agentの上書きが仕様上反映されず、反映できません。**
  - そのため、一部小説サイトでは正常にダウンロードできず、**403 Forbiddenエラー**が生じる場合があります。
  - これはnarou.rb本体やDockerの仕様によるもので、現状Linux環境では回避が困難です。
- **kindlegen 統合** - Kindle (MOBI) 形式への変換対応

> **注意**: 
> - narou 3.9.1 で固定しています。公式で不具合修正された場合、このパッチは不要になる可能性があります。
> - **User-Agent設定はLinux（Docker）では反映できず、403 Forbiddenエラーが発生する場合があります。**
>   WindowsやMacOSでは正常動作しますが、Linux環境では仕様上困難です。
> - **LinuxやDocker環境で動かしたい・このエラーを解消したい場合は、[yuki-untitled/narou-docker](https://github.com/yuki-untitled/narou-docker/tree/master) の利用もご検討ください。**

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

- Ruby 3.4.1 固定 → **Ruby 3.4 自動更新**（Rumia版の要件に対応）
- Adoptium Temurin 21 → **Oracle OpenJDK Java 21（LTS）** への変更
- 改造版 AozoraEpub3 の**最新版自動取得**
- **kindlegen の統合**（Web Archive から取得）
- **User-Agent 設定**の改善
- **PR446パッチを適用**
- ドキュメントとコードの整備
