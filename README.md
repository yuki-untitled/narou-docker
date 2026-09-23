# narou-docker

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

narou.rb には、開発が止まっている公式版と、Linux/Docker 環境向けの改良を含む非公式フォーク（Rumia-Channel 版）があります。どちらをベースにするかによって必要なパッチや依存関係が異なるため、本プロジェクトでは単一の構成で両対応するのではなく、**ベースとする narou.rb のソースごとにブランチを分けて管理**しています。

## ブランチ一覧

| ブランチ | ベースとする narou.rb | 特徴 |
|---|---|---|
| [`rumia-narou`](https://github.com/yuki-untitled/narou-docker/tree/rumia-narou) | [Rumia-Channel/narou (docker ブランチ)](https://github.com/Rumia-Channel/narou/tree/docker) | Linux User-Agent 問題・ハーメルン 403 エラー対応済みの非公式フォークを使用。WebSocket/iBooks 修正パッチ適用済み |
| [`official-narou`](https://github.com/yuki-untitled/narou-docker/tree/official-narou) | [whiteleaf7/narou](https://github.com/whiteleaf7/narou)（公式） | 公式版をベースに構築。サイト構造変更への自動追従（PR446）と、Rumia版由来のwgetベース取得方式でLinux User-Agent問題・403エラーにも対応。詳細は当該ブランチの `docs/spec/official-narou-policy.md` を参照 |

導入・利用する際は、目的に応じて上記いずれかのブランチをチェックアウトし、そのブランチの README.md に従ってください。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照
