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

これにより、デフォルトの3002ポートでサーバーが起動します。起動が完了すると、以下のようなメッセージが表示されます：

```
playwright-sse-mcp-server  | Server is running on port 3002
```

### カスタムポートの設定

デフォルトポート（3002）以外のポートでサーバーを起動したい場合は、環境変数`PORT`を設定します：

```bash
PORT=4000 docker compose up --build
```

これにより、指定したポート（この例では4000）でサーバーが起動します：

```
playwright-sse-mcp-server  | Server is running on port 4000
```

## 使用方法

### 同じmcp-networkに参加しているコンテナからの接続

同じmcp-networkに参加している他のコンテナからは、以下のURLでサーバーに接続できます（`PORT`はサーバーの起動ポート）：

```
playwright-sse-mcp-server:${PORT}/sse
```

デフォルトポートを使用している場合：

```
playwright-sse-mcp-server:3002/sse
```

これにより、PlaywrightのMCP機能を利用することができます。

### ホスト側からの接続

ホストマシンからは、以下のURLでサーバーに接続できます（`PORT`はサーバーの起動ポート）：

```
localhost:${PORT}/sse
```

デフォルトポートを使用している場合：

```
localhost:3002/sse
```

### Roo Codeからの接続

MCP Servers -> MCP設定を編集 -> 以下を記入します（`PORT`はサーバーの起動ポート）：

```json
{
  "mcpServers": {
    "playwright-sse-mcp-server-local": {
      "url": "http://localhost:${PORT}/sse"
    }
  }
}
```

デフォルトポートを使用している場合：

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

### シェル関数を使用した方法

1. ホームディレクトリに`mcps`ディレクトリを作成し、そこにプロジェクトを配置します：

```bash
mkdir -p ~/mcps
# プロジェクトをmcpsディレクトリに移動またはクローン
git clone https://github.com/your-username/playwright-sse-mcp-server.git ~/mcps/playwright-sse-mcp-server
```

2. `.bashrc`（または`.zshrc`など使用しているシェルの設定ファイル）に以下のシェル関数を追加します：

```bash
vim ~/.bashrc
# Playwright MCP Server
playwright-mcp-start() {
  local port=${1:-3002}  # 引数が指定されていない場合はデフォルト値3002を使用
  (cd ~/mcps/playwright-sse-mcp-server && PORT=$port docker compose up -d)
  echo "Playwright MCP Server started on port $port"
}

playwright-mcp-stop() {
  (cd ~/mcps/playwright-sse-mcp-server && docker compose down)
  echo "Playwright MCP Server stopped"
}

playwright-mcp-logs() {
  (cd ~/mcps/playwright-sse-mcp-server && docker compose logs -f)
}
```

3. シェルを再起動するか、設定ファイルを再読み込みします：

```bash
source ~/.bashrc
```

これで、どこからでも以下のコマンドを使用できるようになります：

- `playwright-mcp-start` - デフォルトポート（3002）でサーバーを起動
- `playwright-mcp-start 4000` - 指定したポート（この例では4000）でサーバーを起動
- `playwright-mcp-stop` - サーバーを停止
- `playwright-mcp-logs` - サーバーのログを表示

この方法では、ポート番号を引数として渡すことができるため、固定のエイリアスを複数用意する必要がなく、より柔軟に使用できます。

## 注意事項

- このサーバーはheadlessモードでPlaywrightを実行します
- サーバーはSSE（Server-Sent Events）を使用してMCPクライアントと通信します