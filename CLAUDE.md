# CLAUDE.md - outlook-mcp

MCP server for Microsoft Outlook via Graph API. 55 tools across 9 modules.

## Commands

```bash
npm install              # Install dependencies (run first)
npm start                # Start MCP server
npm run auth-server      # Start OAuth server on :3333 (required for auth)
npm test                 # Run Jest tests
npm run test-mode        # Start with mock data (USE_TEST_MODE=true)
npm run inspect          # MCP Inspector for interactive testing
npx kill-port 3333       # Kill auth server if port blocked
```

## Architecture

```
index.js              # Main entry - combines all module tools
config.js             # Centralized config (API endpoint, defaults, timezone)
outlook-auth-server.js # OAuth server (port 3333)

auth/                 # 3 tools: about, authenticate, check-auth-status
  ├── token-manager.js    # Token load/save/refresh
  └── tools.js            # Tool definitions

email/                # 17 tools: list, search, read, send, attachments, export, delta, headers, MIME, conversations
  ├── folder-utils.js     # Folder name → ID resolution
  ├── attachments.js      # List, download, view attachments
  ├── headers.js          # Email header retrieval
  ├── mime.js             # Raw MIME/EML content
  └── conversations.js    # Thread listing, retrieval, export

calendar/             # 5 tools: list, create, decline, cancel, delete
folder/               # 4 tools: list, create, move, stats
rules/                # 3 tools: list, create, edit-sequence
contacts/             # 7 tools: list, search, get, create, update, delete, people search
categories/           # 7 tools: list, create, update, delete, apply, focused inbox overrides
settings/             # 5 tools: mailbox settings, automatic replies, working hours
advanced/             # 4 tools: shared mailbox, message flags, meeting rooms

utils/
  ├── graph-api.js        # Graph API client with OData encoding
  ├── field-presets.js    # Field selections for token efficiency
  └── response-formatter.js # Verbosity levels (minimal/standard/full)
```

## Key Files

| File | Purpose |
|------|---------|
| `index.js` | MCP protocol handler, combines all tools |
| `config.js` | API endpoint, auth settings, defaults |
| `auth/token-manager.js` | Token storage at `~/.outlook-mcp-tokens.json` |
| `utils/graph-api.js` | All Graph API calls go through here |
| `utils/field-presets.js` | Optimized field selections per operation |

## Configuration

**Environment (.env)**:
```
MS_CLIENT_ID=your-client-id
MS_CLIENT_SECRET=your-secret-VALUE    # NOT the Secret ID!
USE_TEST_MODE=false
```

**Tokens stored at**: `~/.outlook-mcp-tokens.json`

**Defaults**:
- Timezone: `Europe/Amsterdam`
- Page size: 25
- Max results: 100

## Authentication Flow

1. Start auth server: `npm run auth-server`
2. Call `authenticate` tool → get URL
3. Open URL in browser → Microsoft login
4. Grant permissions → tokens saved automatically
5. Tokens auto-refresh on expiration

## Adding New Tools

1. Create handler in module directory (e.g., `email/new-tool.js`)
2. Export from module `index.js`
3. Add to `TOOLS` array in main `index.js`
4. Add test in `test/[module]/`

## Common Issues

| Issue | Solution |
|-------|----------|
| `AADSTS7000215` (invalid secret) | Use secret **VALUE**, not Secret ID from Azure |
| `EADDRINUSE :3333` | `npx kill-port 3333` then restart auth server |
| Module not found | Run `npm install` |
| Auth URL doesn't work | Start auth server first: `npm run auth-server` |
| Empty API response | Check auth status with `check-auth-status` tool |

## Testing

```bash
npm test                    # Jest unit tests
./test-modular-server.sh    # MCP Inspector interactive
./test-direct.sh            # Direct testing
USE_TEST_MODE=true npm start # Mock data mode
```

Mock data defined in `utils/mock-data.js`.

## Graph API Notes

- OData filters use proper URI encoding via `utils/odata-helpers.js`
- Field presets in `utils/field-presets.js` optimize token usage
- Response verbosity: `minimal`, `standard`, `full` (controls output detail)
- Delta sync uses `@odata.deltaLink` for incremental updates

## Deployment (Docker + supergateway)

This fork wraps the STDIO MCP server with `supergateway` for Streamable HTTP transport.

```bash
# Build and run
docker compose up -d --build

# One-time OAuth flow (run from machine with browser access)
docker compose --profile auth up outlook-mcp-auth
# Then open http://localhost:3333/auth in browser

# Stop
docker compose down
```

**Production URL**: `https://omcp.ams.iosharp.com/mcp`
**Traefik config**: `deploy/outlook-mcp.yml`

### Deployment target: optiplex
- Host: `optiplex` (SSH alias)
- Repo path: `/home/tim/outlook-mcp`
- Traefik dynamic config: `/home/tim/media/appdata/traefik/dynamic/outlook-mcp.yml`
- Token volume: `outlook-mcp-tokens` (Docker named volume)

### MSA Auth (Personal Microsoft Accounts)
- OAuth tenant: `/consumers/` (not `/common/`)
- Scopes: `offline_access User.Read Mail.Read Mail.ReadWrite Mail.Send Calendars.Read Calendars.ReadWrite Contacts.Read Contacts.ReadWrite People.Read`
- Excluded (MSA-incompatible): `Mail.Read.Shared`, `Place.Read.All`, `MailboxSettings.*`

## See Also

- `README.md` - Full documentation, Azure setup, tool reference
- `docs/quickrefs/tools-reference.md` - All 55 tools quick reference
- `.env.example` - Environment template
