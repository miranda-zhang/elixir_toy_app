# Elixir_Toy App Backend
👉 [https://elixir-toy-app-backend.onrender.com/api](https://elixir-toy-app-backend.onrender.com/api)
(Note: it may take about 10 seconds to wake up after inactivity.)

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
