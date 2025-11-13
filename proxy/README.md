# ElectricSQL Authorizing Proxy

A lightweight Node.js proxy that validates JWT tokens and authorizes ElectricSQL shape requests.

## Features

- JWT token validation
- Shape claim verification
- Request/response proxying to Electric
- WebSocket support
- User context logging

## Environment Variables

- `PORT` - Proxy server port (default: 3000)
- `ELECTRIC_URL` - ElectricSQL service URL
- `JWT_SECRET` - Secret for JWT validation (must match backend)
- `JWT_ISSUER` - JWT issuer (must match backend)

## Development

```bash
npm install
npm run dev
```

## Production

```bash
npm install --production
npm start
```

## Docker

```bash
docker build -t sertantai-controls-proxy .
docker run -p 3000:3000 --env-file .env sertantai-controls-proxy
```
