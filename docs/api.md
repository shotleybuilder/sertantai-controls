# API Documentation

## Authentication

### Login

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}

Response:
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "organization_id": "uuid"
  },
  "access_token": "jwt_token",
  "expires_in": 3600
}
```

### Gatekeeper - Request Shape Token

```
POST /api/gatekeeper/:table
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "params": {
    "where": "organization_id='uuid'",
    "columns": ["id", "name", "created_at"]
  }
}

Response:
{
  "token": "shape_scoped_jwt",
  "shape": {
    "table": "tasks",
    "where": "organization_id='uuid'",
    "columns": ["id", "name", "created_at"]
  },
  "expires_in": 3600
}
```

## ElectricSQL Shapes

### Request Shape Data

```
GET /v1/shape?table=tasks&where=organization_id='uuid'&token=<shape_token>

Response: Server-sent events stream
```

## REST API Endpoints

TODO: Add resource-specific endpoints as they are implemented.

## Rate Limiting

- 100 requests per minute per user
- 1000 requests per hour per user
- Burst limit: 20 requests per second

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {}
}
```

Common error codes:
- `UNAUTHORIZED` - Missing or invalid authentication
- `FORBIDDEN` - Insufficient permissions
- `NOT_FOUND` - Resource not found
- `VALIDATION_ERROR` - Invalid request data
- `RATE_LIMIT_EXCEEDED` - Too many requests
