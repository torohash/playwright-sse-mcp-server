# playwright-sse-mcp-server

PlaywrightをMCP（Model Context Protocol）サーバーとして提供するためのサービスです。このサーバーを使用することで、MCPクライアントからPlaywrightの機能を利用することができます。

## 前提条件

- Dockerがインストールされていること
- docker-composeがインストールされていること
- mcp-networkという名前のDockerネットワークが作成されていること

mcp-networkが存在しない場合は、以下のコマンドで作成できます：

```bash
docker network create mcp-network
```

## セットアップと起動方法

1. リポジトリをクローンまたはダウンロードします
2. プロジェクトのルートディレクトリで以下のコマンドを実行します：

```bash
docker compose up --build
```

これにより、3002ポートでサーバーが起動します。起動が完了すると、以下のようなメッセージが表示されます：

```
playwright-sse-mcp-server  | Server is running on port 3002
```

## 使用方法

### 同じmcp-networkに参加しているコンテナからの接続

同じmcp-networkに参加している他のコンテナからは、以下のURLでサーバーに接続できます：

```
playwright-sse-mcp-server:3002/sse
```

これにより、PlaywrightのMCP機能を利用することができます。

### ホスト側からの接続

ホストマシンからは、以下のURLでサーバーに接続できます：

```
localhost:3002/sse
```

### Roo Codeからの接続

MCP Servers -> MCP設定を編集 -> 以下を記入します

```json
{
  "mcpServers": {
    "playwright-sse-mcp-server-local": {
      "url": "http://localhost:3002/sse"
    }
  }
}
```

※2025/03/27現在、ClineはSSEをサポートしていない為使えません。

## 便利な使用方法

毎回プロジェクトディレクトリに移動してdocker composeコマンドを実行するのは面倒です。以下の方法を使用すると、どこからでも簡単にサーバーを起動・停止できます。

### エイリアスを使用した方法

1. ホームディレクトリに`mcps`ディレクトリを作成し、そこにプロジェクトを配置します：

```bash
mkdir -p ~/mcps
# プロジェクトをmcpsディレクトリに移動またはクローン
git clone https://github.com/your-username/playwright-sse-mcp-server.git ~/mcps/playwright-sse-mcp-server
```

2. `.bashrc`（または`.zshrc`など使用しているシェルの設定ファイル）に以下のエイリアスを追加します：

```bash
# Playwright MCP Server
alias playwright-mcp-start='(cd ~/mcps/playwright-sse-mcp-server && docker compose up -d)'
alias playwright-mcp-stop='(cd ~/mcps/playwright-sse-mcp-server && docker compose down)'
alias playwright-mcp-logs='(cd ~/mcps/playwright-sse-mcp-server && docker compose logs -f)'
```

3. シェルを再起動するか、設定ファイルを再読み込みします：

```bash
source ~/.bashrc
```

これで、どこからでも以下のコマンドを使用できるようになります：

- `playwright-mcp-start` - サーバーを起動
- `playwright-mcp-stop` - サーバーを停止
- `playwright-mcp-logs` - サーバーのログを表示

## 注意事項

- このサーバーはheadlessモードでPlaywrightを実行します
- サーバーはSSE（Server-Sent Events）を使用してMCPクライアントと通信します