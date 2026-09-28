# narou-docker

「小説家になろう」の小説をダウンロード・変換するツール narou.rb の Docker イメージです。

narou.rb は、公式版（[whiteleaf7/narou](https://github.com/whiteleaf7/narou)）をベースに、サイト構造変更への追従と Linux/Docker 環境向けの対策を加えてビルドしています。

## ブランチ一覧

| ブランチ | ベースとする narou.rb | 特徴 |
|---|---|---|
| [`official-narou`](https://github.com/yuki-untitled/narou-docker/tree/official-narou) | [whiteleaf7/narou](https://github.com/whiteleaf7/narou)（公式） | 公式版をベースに構築。サイト構造変更への自動追従（PR456）と、`wget` ベース取得方式による Linux User-Agent 問題・403エラー対策を含む。詳細は当該ブランチの `docs/spec/official-narou-policy.md` を参照 |

導入・利用する際は、上記ブランチをチェックアウトし、そのブランチの README.md に従ってください。

## 廃止したブランチ

| ブランチ | 廃止理由 | 過去の内容 |
|---|---|---|
| `rumia-narou` | ベースとしていた [Rumia-Channel/narou](https://github.com/Rumia-Channel/narou) が 2026-04-21 以降の更新を停止したため | [`archive/rumia-narou` タグ](https://github.com/yuki-untitled/narou-docker/tree/archive/rumia-narou) |

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照
