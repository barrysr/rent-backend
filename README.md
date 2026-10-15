# Houserent — Backend API

Cloudflare Worker API for the houserent app. Handles all `/api/*` routes with Supabase as the database and Google Maps Geocoding API for address lookups.

## 🚀 Deployment to Cloudflare Workers

### Prerequisites
- Node.js 18+ installed
- Wrangler CLI: `npm install -g wrangler`
- A [Cloudflare account](https://dash.cloudflare.com)
- A [Supabase project](https://supabase.com)
- A [Google Maps API key](https://console.cloud.google.com) (enable Geocoding API)

### 1. Install dependencies
```bash
npm install
```

### 2. Authenticate Wrangler
```bash
wrangler login
```

### 3. Set up Supabase database
1. Go to your Supabase project → **SQL Editor**
2. Copy the contents of `database-migrations/schema.sql`
3. Paste and run it to create the `users`, `listings`, and `favorites` tables

### 4. Set environment secrets

**For local development**, fill in `.dev.vars`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

**For production**, use Wrangler secrets:
```bash
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_ANON_KEY
wrangler secret put GOOGLE_MAPS_API_KEY
```

### 5. Local development
```bash
npm run dev
# API available at http://localhost:8787/api/*
```

### 6. Deploy to production
```bash
npm run deploy
```

---

## 📁 Project Structure

```
houserent-backend/
├── src/
│   └── index.js                    # Worker entry point & all API routes
├── database-migrations/
│   └── schema.sql                  # Supabase table definitions
├── wrangler.toml                   # Cloudflare Worker config
├── package.json
├── .dev.vars                       # Local secrets (gitignored)
└── .gitignore
```

---

## 📝 API Endpoints

### Auth
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register a new user (`email`, `password`, `name`, `role`) |
| POST | `/api/auth/login` | Login (`email`, `password`) → returns user object |

### Listings
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/listings` | Get all available listings. Query params: `q`, `type`, `minPrice`, `maxPrice`, `bedrooms` |
| POST | `/api/listings` | Create a listing |
| PUT | `/api/listings/:id` | Update a listing |
| DELETE | `/api/listings/:id` | Delete a listing |
| GET | `/api/listings/owner/:ownerId` | Get all listings by an owner |
| GET | `/api/listings/nearby` | Listings near a location. Params: `lat`, `lng`, `radius` (km, default 10) |

### Maps / Geocoding
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/maps/geocode` | Convert address → lat/lng via Google Maps. Param: `address` |

### Favorites
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/favorites/:userId` | Get all listing IDs favorited by a user |
| POST | `/api/favorites/toggle` | Toggle a favorite (`user_id`, `listing_id`) |

### Health
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/health` | Health check |

---

## 🔧 Testing locally

```bash
# Health check
curl http://localhost:8787/api/health

# Register
curl -X POST http://localhost:8787/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@test.com","password":"pass123","name":"Test Owner","role":"owner"}'

# Get listings
curl http://localhost:8787/api/listings

# Search listings
curl "http://localhost:8787/api/listings?q=bangalore&type=apartment&maxPrice=30000"

# Geocode an address
curl "http://localhost:8787/api/maps/geocode?address=MG+Road+Bangalore"
```

---

## 🔒 Security Notes
- **Never commit** `.dev.vars` or secrets to version control
- Use `wrangler secret` for all production credentials
- The Worker runs on Cloudflare's global edge network with built-in DDoS protection
- Passwords in this demo are stored as plain text — in production, use **Supabase Auth** for proper hashed password handling
