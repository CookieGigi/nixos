# MCP Configuration Reference

## MCP Server Configuration Options

### Local MCP Server

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `type` | String | Yes | Must be `"local"` |
| `command` | Array | Yes | Command and arguments to start the server |
| `environment` | Object | No | Environment variables for the server process |
| `enabled` | Boolean | No | Enable/disable on startup. Default: `true` |
| `timeout` | Number | No | Timeout in ms for fetching tools. Default: `5000` |

Example:
```json
{
  "mcp": {
    "my-local-server": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-everything"],
      "environment": {
        "DEBUG": "true"
      },
      "enabled": true,
      "timeout": 10000
    }
  }
}
```

### Remote MCP Server

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `type` | String | Yes | Must be `"remote"` |
| `url` | String | Yes | URL of the remote MCP server |
| `enabled` | Boolean | No | Enable/disable on startup. Default: `true` |
| `headers` | Object | No | HTTP headers to send with requests |
| `oauth` | Object / Boolean | No | OAuth config or `false` to disable auto-OAuth |
| `timeout` | Number | No | Timeout in ms. Default: `5000` |

Example:
```json
{
  "mcp": {
    "my-remote-server": {
      "type": "remote",
      "url": "https://mcp.example.com",
      "headers": {
        "Authorization": "Bearer {env:MY_API_KEY}"
      },
      "oauth": false
    }
  }
}
```

## Common MCP Server Recipes

### Context7 (Documentation Search)

Remote server for searching library documentation.

```json
{
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "enabled": true
    }
  }
}
```

With API key for higher rate limits:
```json
{
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
      }
    }
  }
}
```

### DuckDuckGo (Web Search)

Local server for web search via DuckDuckGo.

```json
{
  "mcp": {
    "duckduckgo": {
      "type": "local",
      "command": ["npx", "-y", "duckduckgo-mcp-server"],
      "enabled": true
    }
  }
}
```

### PostgreSQL

Local server for PostgreSQL database interaction.

```json
{
  "mcp": {
    "postgres": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-postgres"],
      "environment": {
        "POSTGRES_URL": "{env:POSTGRES_URL}"
      },
      "enabled": true
    }
  }
}
```

### SQLite

Local server for SQLite database files.

```json
{
  "mcp": {
    "sqlite": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sqlite"],
      "enabled": true
    }
  }
}
```

### GitHub

Remote server for GitHub integration.

```json
{
  "mcp": {
    "github": {
      "type": "remote",
      "url": "https://mcp.github.com",
      "oauth": {},
      "enabled": true
    }
  }
}
```

After configuration, authenticate with:
```bash
opencode mcp auth github
```

### Sentry

Remote server for error tracking.

```json
{
  "mcp": {
    "sentry": {
      "type": "remote",
      "url": "https://mcp.sentry.dev/mcp",
      "oauth": {}
    }
  }
}
```

### Filesystem

Local server for filesystem operations.

```json
{
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/path/to/allow"],
      "enabled": true
    }
  }
}
```

## OAuth Authentication

### Automatic OAuth

Most OAuth-enabled servers work without explicit configuration:

```json
{
  "mcp": {
    "my-oauth-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp"
    }
  }
}
```

OpenCode will prompt for authentication on first use.

### Pre-registered Credentials

If you have client credentials from the provider:

```json
{
  "mcp": {
    "my-oauth-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "oauth": {
        "clientId": "{env:MY_MCP_CLIENT_ID}",
        "clientSecret": "{env:MY_MCP_CLIENT_SECRET}",
        "scope": "tools:read tools:execute"
      }
    }
  }
}
```

### Disabling OAuth

For servers using API keys instead of OAuth:

```json
{
  "mcp": {
    "my-api-key-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "oauth": false,
      "headers": {
        "Authorization": "Bearer {env:MY_API_KEY}"
      }
    }
  }
}
```

## Tool Management

### Global Disable

Disable specific MCP tools globally:

```json
{
  "mcp": {
    "my-mcp": {
      "type": "local",
      "command": ["bun", "x", "my-mcp-command"]
    }
  },
  "tools": {
    "my-mcp_search": false,
    "my-mcp_list": false
  }
}
```

### Glob Patterns

Disable all tools from a server:

```json
{
  "tools": {
    "my-mcp_*": false
  }
}
```

### Per-Agent Enablement

Enable MCP tools only for specific agents:

```json
{
  "mcp": {
    "my-mcp": {
      "type": "local",
      "command": ["bun", "x", "my-mcp-command"],
      "enabled": true
    }
  },
  "tools": {
    "my-mcp_*": false
  },
  "agent": {
    "researcher": {
      "tools": {
        "my-mcp_*": true
      }
    }
  }
}
```

## Troubleshooting

### Server Not Appearing in `opencode mcp list`

1. Verify `.opencode.json` is in the current working directory
2. Check JSON syntax with `cat .opencode.json | python3 -m json.tool`
3. Ensure the server has `"enabled": true` (or omit `enabled`, which defaults to `true`)

### Connection Timeout

Increase the timeout:
```json
{
  "timeout": 30000
}
```

### Local Command Not Found

- Verify the binary is in `$PATH` (e.g., `which npx`)
- For NixOS: add the package to `home.packages` or the project devShell
- Use absolute paths if necessary: `["/nix/store/.../bin/my-mcp-server"]`

### OAuth Issues

1. Check auth status: `opencode mcp auth list`
2. Debug specific server: `opencode mcp debug <server-name>`
3. Re-authenticate: `opencode mcp auth <server-name>`
4. Clear credentials: `opencode mcp logout <server-name>`

### NixOS Specific

- `~/.config/opencode/opencode.json` is generated by home-manager; do not edit manually
- Project-local `.opencode.json` is mutable and safe to edit
- For `npx` commands, ensure `pkgs.nodejs` is in the system or home packages
- Token storage is at `~/.local/share/opencode/mcp-auth.json` (persisted via impermanence)
