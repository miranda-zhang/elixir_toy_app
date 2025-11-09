# Elixir_Toy App Backend
Free Render.com PostgreSQL database suspended on 2025-11-16.
Backend free plan not working please try locally.

Render.com endpoint [https://elixir-toy-app-backend.onrender.com/api](https://elixir-toy-app-backend.onrender.com/api)



```bash
# Test connection
curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hello }"}'

# Register user
curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { registerUser(email: \"test@example.com\", password: \"123456\") { id email } }"}'

# Login user
curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { loginUser(email: \"test@example.com\", password: \"123456\")}"}'

# Add phone number (requires JWT)
curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{"query": "mutation { addPhoneNumber(phoneNumber: \"+61412345678\") { id email phoneNumber } }"}'
```
See [docs](./doc/toy_app.md)
