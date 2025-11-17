# Enopax Lightweight Identity Provider Concept

**Version**: 2.0
**Date**: 2025-11-17
**Status**: Architecture Design - Lightweight, DB-Free Solution

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Revised Requirements](#revised-requirements)
3. [Solution Options](#solution-options)
4. [Recommended Architecture](#recommended-architecture)
5. [User Registration Flow](#user-registration-flow)
6. [Technical Implementation](#technical-implementation)
7. [Deployment](#deployment)
8. [Security Considerations](#security-considerations)
9. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

Based on the updated requirements for a **lightweight, database-free, self-hosted** solution using only **free open-source tools**, this document proposes a new architecture for Enopax's Identity Provider.

### Key Requirements

- ✅ **Self-hosted** (no SaaS)
- ✅ **No database** (file-based storage)
- ✅ **No Redis** (stateless or file-based sessions)
- ✅ **Lightweight** (minimal resources)
- ✅ **Free & open source**
- ✅ **Language**: Rust, Go, or TypeScript

### Critical Question: User Registration

**How do users get registered?**

There are **three main approaches**:

1. **Admin-provisioned users** (static file, manual management)
2. **Platform-driven registration** (Platform app manages users, IdP validates)
3. **Custom lightweight IdP with built-in registration** (build your own)

---

## Revised Requirements

### Must Have
- OIDC provider for authentication
- File-based user storage (JSON, YAML, or similar)
- Support for web app (Next.js), Kubernetes, and infrastructure tools
- Minimal resource footprint (< 100MB RAM, < 0.5 vCPU)
- Written in Rust, Go, or TypeScript

### Must NOT Have
- Database (PostgreSQL, MySQL, etc.)
- Redis or other caching layers
- Heavy Java-based solutions (Keycloak)
- External SaaS dependencies

### Nice to Have
- MFA support
- Social login (optional)
- Admin UI (or simple CLI)

---

## Solution Options

### Option 1: Dex (Lightweight Go-based OIDC Provider)

**GitHub**: https://github.com/dexidp/dex

**Overview**: Dex is a lightweight OIDC identity provider written in Go. It's designed as a "shim" that federates with other identity providers but can also manage static users via configuration files.

#### Pros
- ✅ **Extremely lightweight** (single binary, ~50MB RAM)
- ✅ **File-based configuration** (YAML)
- ✅ **Static user support** (no database required for small deployments)
- ✅ **Written in Go** (meets language requirement)
- ✅ **Kubernetes-native** (CRD support)
- ✅ **Well-documented** and actively maintained
- ✅ **Used in production** by many Kubernetes distributions (MicroK8s, etc.)

#### Cons
- ❌ **No built-in user registration UI** (static users only in file mode)
- ❌ **Limited user management** (file edits + restart for user changes)
- ❌ **No self-service password reset**
- ❌ **Basic UI** (functional but not modern)

#### Storage Options
1. **Static passwords in config file** (YAML)
2. **SQLite storage** (lightweight, file-based database)
3. **gRPC API** for dynamic user management (requires custom app)

#### User Registration Approach with Dex

**Option A: Static File Management**
- Admin manually adds users to `config.yaml`
- Password hashes generated via `htpasswd` or bcrypt
- Restart Dex to apply changes
- **Best for**: Small teams (< 20 users), internal tools

**Option B: gRPC API + Custom Registration App**
- Build a lightweight registration API (Go/TypeScript/Rust)
- Registration app writes to Dex via gRPC API
- Dex stores users in SQLite (file-based, no server needed)
- **Best for**: Self-service registration with lightweight storage

**Example Dex Config (Static Users)**:
```yaml
issuer: https://auth.enopax.io

storage:
  type: sqlite3
  config:
    file: /var/dex/dex.db

web:
  http: 0.0.0.0:5556

enablePasswordDB: true

staticPasswords:
  - email: "admin@enopax.io"
    hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
    username: "admin"
    userID: "08a8684b-db88-4b73-90a9-3cd1661f5466"

staticClients:
  - id: enopax-platform
    secret: YOUR_CLIENT_SECRET
    name: "Enopax Platform"
    redirectURIs:
      - "https://platform.enopax.io/api/auth/callback/oidc"

connectors:
  - type: github
    id: github
    name: GitHub
    config:
      clientID: $GITHUB_CLIENT_ID
      clientSecret: $GITHUB_CLIENT_SECRET
      redirectURI: https://auth.enopax.io/callback
```

---

### Option 2: Ory Hydra (Headless OIDC Provider)

**GitHub**: https://github.com/ory/hydra

**Overview**: Ory Hydra is a headless OAuth2/OIDC provider. It does NOT manage users directly but delegates to your custom login/consent app.

#### Pros
- ✅ **Lightweight** (~30MB RAM for Hydra alone)
- ✅ **Headless/API-first** (complete UI control)
- ✅ **Written in Go** (meets language requirement)
- ✅ **OpenID Certified**
- ✅ **Can use SQLite** (file-based storage)

#### Cons
- ❌ **Requires custom login/consent app** (you build the UI)
- ❌ **More complex setup** (two components: Hydra + your app)
- ❌ **No user management** (you implement everything)

#### Architecture with Ory Hydra

```
User → Hydra → Redirects to YOUR Login App → User logs in → Your app validates →
Your app tells Hydra "user is authenticated" → Hydra issues tokens
```

**Your responsibilities**:
- Build login UI (TypeScript/React, Go, or Rust)
- Manage users (file-based JSON, YAML, or lightweight DB like SQLite)
- Validate credentials
- Handle registration, password reset, etc.

**Hydra's responsibilities**:
- OIDC/OAuth2 token issuance
- Token validation
- Session management

#### User Registration Approach with Hydra

Since Hydra is headless, **you control everything**:

1. **Your Platform handles registration**
   - User clicks "Sign Up" on Platform
   - Platform shows registration form
   - Platform validates and stores user in a file (JSON/YAML)
   - Platform redirects to login flow

2. **Login flow**:
   - Hydra redirects to your login app
   - Your app checks credentials from file
   - Your app tells Hydra "user authenticated"
   - Hydra issues tokens to Platform

**Best for**: Full control over UX, custom requirements, willing to build custom app

---

### Option 3: Custom Lightweight IdP (Build Your Own)

**Languages**: TypeScript (Node.js), Go, or Rust

**Approach**: Build a minimal OIDC provider from scratch using libraries.

#### Available Libraries

**TypeScript (Node.js)**:
- `node-oidc-provider` - Full OIDC provider implementation
- Express.js for API
- File-based user storage (JSON)

**Go**:
- `github.com/zitadel/oidc` - OIDC library (server & client)
- `github.com/ory/fosite` - OAuth2/OIDC framework
- Gin or Echo for API framework

**Rust**:
- `oxide-auth` - OAuth2 framework
- `jsonwebtoken` - JWT handling
- Actix-web or Axum for API framework

#### Pros
- ✅ **Complete control** over features, UX, storage
- ✅ **Minimal dependencies** (only what you need)
- ✅ **Custom registration logic** (exactly how you want it)
- ✅ **Lightweight** (< 50MB RAM easily achievable)
- ✅ **File-based storage** (JSON, YAML, or even TOML)

#### Cons
- ❌ **More development effort** (weeks, not days)
- ❌ **OIDC compliance testing** required
- ❌ **Security responsibility** (you own all vulnerabilities)
- ❌ **Ongoing maintenance** (updates, patches)

#### User Registration Approach (Custom)

**Full control** - You design the entire flow:

1. User visits `/register` on your IdP
2. Fill out form (email, password, name)
3. Server validates and saves to JSON file
4. Email verification (optional)
5. User can now log in

---

## Recommended Architecture

### Recommendation: **Hybrid Approach with Dex + Platform Integration**

**Why?**
- Dex handles OIDC complexity (battle-tested, certified)
- Platform handles user-facing registration
- File-based storage (SQLite = single file, no server)
- Lightweight and production-ready

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER JOURNEY                             │
└─────────────────────────────────────────────────────────────────┘

1. REGISTRATION (New Users)
   ┌─────────┐
   │  User   │
   └────┬────┘
        │ Visits platform.enopax.io/register
        ▼
   ┌─────────────────┐
   │  Platform UI    │  (Next.js registration form)
   └────┬────────────┘
        │ Submit registration
        ▼
   ┌─────────────────┐
   │ Platform API    │  Validates email, password strength, etc.
   └────┬────────────┘
        │
        ▼
   ┌─────────────────┐
   │ User Management │  (File: users.json or Dex gRPC API)
   │     Service     │  Stores: { email, bcrypt_hash, metadata }
   └────┬────────────┘
        │
        ▼
   ┌─────────────────┐
   │      Dex        │  User added to Dex (via gRPC API or SQLite)
   │ (OIDC Provider) │
   └─────────────────┘

2. AUTHENTICATION (Existing Users)
   ┌─────────┐
   │  User   │
   └────┬────┘
        │ Clicks "Login" on platform.enopax.io
        ▼
   ┌─────────────────┐
   │  Platform       │  Redirects to Dex authorize endpoint
   │  (NextAuth.js)  │
   └────┬────────────┘
        │
        ▼
   ┌─────────────────┐
   │      Dex        │  Shows login form
   │  (Login UI)     │
   └────┬────────────┘
        │ User enters email + password
        ▼
   ┌─────────────────┐
   │      Dex        │  Validates credentials (from SQLite or file)
   │ (Auth Backend)  │
   └────┬────────────┘
        │ Issues authorization code
        ▼
   ┌─────────────────┐
   │  Platform       │  Exchanges code for tokens
   │  (NextAuth.js)  │  Gets id_token + access_token
   └────┬────────────┘
        │
        ▼
   ┌─────────────────┐
   │  User Session   │  Logged in!
   │   (Platform)    │
   └─────────────────┘

3. KUBERNETES AUTHENTICATION
   ┌─────────┐
   │Developer│
   └────┬────┘
        │ kubectl oidc-login
        ▼
   ┌─────────────────┐
   │      Dex        │  Browser-based login
   │  (OIDC Flow)    │
   └────┬────────────┘
        │ Returns id_token to kubectl
        ▼
   ┌─────────────────┐
   │   Kubernetes    │  Validates token with Dex
   │   API Server    │  Checks groups for RBAC
   └─────────────────┘

```

---

## User Registration Flow

### Approach 1: Platform-Managed Registration (Recommended)

**Overview**: Platform handles user registration, writes to Dex storage

#### Flow Diagram

```
┌──────────┐
│   User   │
└────┬─────┘
     │
     │ 1. Visit /register
     ▼
┌─────────────────────────┐
│  Platform Frontend      │
│  (Next.js)              │
│  - Email input          │
│  - Password input       │
│  - Terms acceptance     │
└────┬────────────────────┘
     │
     │ 2. Submit form
     ▼
┌─────────────────────────┐
│  Platform API           │
│  (Server Action / API)  │
│                         │
│  - Validate email       │
│  - Check password       │
│  - Hash password        │
│  - Generate user ID     │
└────┬────────────────────┘
     │
     │ 3. Create user
     ▼
┌─────────────────────────┐
│  User Storage Layer     │
│                         │
│  Option A: Write to     │
│  users.json file        │
│                         │
│  Option B: Call Dex     │
│  gRPC API to create     │
│  user in Dex SQLite     │
└────┬────────────────────┘
     │
     │ 4. Send verification email (optional)
     ▼
┌─────────────────────────┐
│  Email Service          │
│  - Verification link    │
└────┬────────────────────┘
     │
     │ 5. User clicks link
     ▼
┌─────────────────────────┐
│  Platform API           │
│  - Mark email verified  │
│  - Enable user in Dex   │
└────┬────────────────────┘
     │
     │ 6. Redirect to login
     ▼
┌─────────────────────────┐
│  Dex Login Page         │
│  - User can now log in  │
└─────────────────────────┘
```

#### Implementation Details

**Option A: File-Based User Management**

Platform maintains a `users.json` file:

```json
{
  "users": [
    {
      "id": "user-001",
      "email": "alice@example.com",
      "password_hash": "$2b$10$...",
      "name": "Alice Developer",
      "email_verified": true,
      "created_at": "2025-11-17T10:00:00Z",
      "groups": ["org-acme", "org-acme-developers"]
    }
  ]
}
```

**Sync to Dex**:
- Write a sync script that reads `users.json` and updates Dex config
- Restart Dex to apply changes (acceptable for low-frequency registrations)
- OR use Dex gRPC API to add users dynamically (no restart needed)

**Option B: Dex gRPC API**

Platform calls Dex gRPC API directly to create users:

```typescript
// Platform registration handler (TypeScript example)
import { createDexClient } from './dex-grpc-client'

async function registerUser(email: string, password: string, name: string) {
  // 1. Validate input
  if (!isValidEmail(email)) throw new Error('Invalid email')
  if (password.length < 12) throw new Error('Password too short')

  // 2. Hash password
  const passwordHash = await bcrypt.hash(password, 10)

  // 3. Generate user ID
  const userId = uuidv4()

  // 4. Call Dex API to create user
  const dexClient = createDexClient()
  await dexClient.createPassword({
    email,
    hash: passwordHash,
    username: name,
    userId,
  })

  // 5. Store additional metadata in Platform DB (optional)
  // Platform can maintain its own user table for app-specific data
  await prisma.user.create({
    data: { id: userId, email, name }
  })

  return { success: true, userId }
}
```

---

### Approach 2: Admin-Provisioned Users

**Overview**: Admins manually create users, best for small internal teams

#### Process
1. Admin edits `dex-config.yaml` file
2. Add new user to `staticPasswords` section
3. Generate password hash: `echo "password123" | htpasswd -BinC 10 user | cut -d: -f2`
4. Restart Dex to apply changes

**Example**:
```yaml
staticPasswords:
  - email: "newuser@enopax.io"
    hash: "$2a$10$..."
    username: "newuser"
    userID: "unique-uuid-here"
```

**Pros**: Simple, no registration code needed
**Cons**: Manual, doesn't scale beyond ~20 users

---

### Approach 3: External Identity Provider (GitHub/Google OAuth)

**Overview**: Users authenticate via GitHub/Google, no password storage needed

#### Flow
1. User clicks "Login with GitHub" on Platform
2. Platform redirects to Dex
3. Dex redirects to GitHub OAuth
4. User authorizes on GitHub
5. GitHub redirects back to Dex with authorization code
6. Dex issues OIDC tokens to Platform
7. Platform creates user record (first-time users)

**Dex Config**:
```yaml
connectors:
  - type: github
    id: github
    name: GitHub
    config:
      clientID: $GITHUB_CLIENT_ID
      clientSecret: $GITHUB_CLIENT_SECRET
      redirectURI: https://auth.enopax.io/callback
      orgs:
        - name: enopax  # Optional: restrict to org members
```

**Pros**: No password management, easier onboarding
**Cons**: Requires GitHub/Google accounts, users depend on external providers

---

## Technical Implementation

### Recommended Stack

**OIDC Provider**: Dex (Go)
**User Registration**: Platform (Next.js + TypeScript)
**User Storage**:
  - Option A: SQLite file (managed by Dex)
  - Option B: JSON file (synced to Dex via gRPC API or config reload)

### Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────┐           │
│  │          Enopax Platform (Next.js)               │           │
│  │  - Registration UI (app/register/page.tsx)      │           │
│  │  - Login redirect (NextAuth.js → Dex)           │           │
│  │  - User management API                           │           │
│  └──────────────┬───────────────────────────────────┘           │
│                 │                                               │
│                 │ OIDC Auth Flow                                │
│                 │ User Registration (gRPC or file write)        │
│                 │                                               │
│  ┌──────────────▼───────────────────────────────────┐           │
│  │              Dex (OIDC Provider)                 │           │
│  │  - OIDC endpoints (/auth, /token, /userinfo)    │           │
│  │  - User authentication                           │           │
│  │  - Token issuance                                │           │
│  │  - Optional: gRPC API for user management       │           │
│  └──────────────┬───────────────────────────────────┘           │
│                 │                                               │
│                 │ Reads/Writes                                  │
│                 │                                               │
│  ┌──────────────▼───────────────────────────────────┐           │
│  │         File-Based Storage                       │           │
│  │  - dex.db (SQLite) - users, sessions, clients   │           │
│  │  OR                                              │           │
│  │  - users.json (JSON file, synced to Dex)        │           │
│  └──────────────────────────────────────────────────┘           │
│                                                                 │
│  ┌──────────────────────────────────────────────────┐           │
│  │         Kubernetes API Server                    │           │
│  │  - OIDC authentication enabled                   │           │
│  │  - Validates tokens with Dex                     │           │
│  └──────────────────────────────────────────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### File Structure

```
/data/
├── dex/
│   ├── config.yaml          # Dex configuration
│   ├── dex.db               # SQLite storage (if using DB mode)
│   └── tls/
│       ├── cert.pem
│       └── key.pem
└── users/
    └── users.json           # Optional: separate user file for Platform
```

---

## Deployment

### Kubernetes Deployment (Recommended)

**Namespace**: `auth-system`

#### Dex Deployment

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dex-config
  namespace: auth-system
data:
  config.yaml: |
    issuer: https://auth.enopax.io

    storage:
      type: sqlite3
      config:
        file: /var/dex/dex.db

    web:
      http: 0.0.0.0:5556

    grpc:
      addr: 0.0.0.0:5557

    enablePasswordDB: true

    staticClients:
      - id: enopax-platform
        secret: ${PLATFORM_CLIENT_SECRET}
        name: "Enopax Platform"
        redirectURIs:
          - "https://platform.enopax.io/api/auth/callback/oidc"

      - id: kubernetes
        secret: ${K8S_CLIENT_SECRET}
        name: "Kubernetes"
        redirectURIs:
          - "http://localhost:8000"
          - "http://localhost:18000"

    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: ${GITHUB_CLIENT_ID}
          clientSecret: ${GITHUB_CLIENT_SECRET}
          redirectURI: https://auth.enopax.io/callback

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dex
  namespace: auth-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dex
  template:
    metadata:
      labels:
        app: dex
    spec:
      containers:
      - name: dex
        image: ghcr.io/dexidp/dex:v2.38.0
        command:
          - /usr/local/bin/dex
          - serve
          - /etc/dex/config.yaml
        ports:
        - name: http
          containerPort: 5556
        - name: grpc
          containerPort: 5557
        volumeMounts:
        - name: config
          mountPath: /etc/dex
        - name: storage
          mountPath: /var/dex
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 500m
            memory: 128Mi
      volumes:
      - name: config
        configMap:
          name: dex-config
      - name: storage
        persistentVolumeClaim:
          claimName: dex-storage

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dex-storage
  namespace: auth-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: v1
kind: Service
metadata:
  name: dex
  namespace: auth-system
spec:
  selector:
    app: dex
  ports:
  - name: http
    port: 5556
    targetPort: 5556
  - name: grpc
    port: 5557
    targetPort: 5557

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dex
  namespace: auth-system
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - auth.enopax.io
    secretName: dex-tls
  rules:
  - host: auth.enopax.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dex
            port:
              number: 5556
```

### Resource Requirements

**Dex**:
- CPU: 100m (request), 500m (limit)
- Memory: 64Mi (request), 128Mi (limit)
- Storage: 1Gi (for SQLite database)

**Total**: ~100MB RAM, < 0.5 vCPU

---

## Security Considerations

### Password Security

**Hashing Algorithm**: bcrypt with cost factor 10
```bash
# Generate hash for user password
echo "password123" | htpasswd -BinC 10 username | cut -d: -f2
```

**Password Requirements** (enforced in Platform registration):
- Minimum 12 characters
- At least one uppercase, lowercase, number
- No common passwords (check against known breach list)

### Token Security

**Access Tokens**:
- Short-lived: 1 hour
- JWT format (RS256 signing)
- Contains user claims: email, groups

**ID Tokens**:
- Used for authentication proof
- Valid for 1 hour
- Verified by Platform and Kubernetes

**Refresh Tokens**:
- Long-lived: 30 days
- Stored securely (httpOnly cookies in Platform)
- Revocable via Dex API

### TLS/HTTPS

**Certificate Management**:
- Let's Encrypt via cert-manager (Kubernetes)
- Automatic renewal
- TLS 1.3 minimum

### File Permissions

**SQLite Database**:
```bash
chmod 600 /var/dex/dex.db
chown dex:dex /var/dex/dex.db
```

**Configuration Files**:
```bash
chmod 640 /etc/dex/config.yaml
chown dex:dex /etc/dex/config.yaml
```

### Secrets Management

**Environment Variables**:
- Client secrets via Kubernetes Secrets
- Never commit secrets to Git
- Use `.env` for local development (gitignored)

**Example Kubernetes Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dex-secrets
  namespace: auth-system
type: Opaque
stringData:
  PLATFORM_CLIENT_SECRET: "random-generated-secret"
  K8S_CLIENT_SECRET: "another-random-secret"
  GITHUB_CLIENT_ID: "your-github-oauth-app-id"
  GITHUB_CLIENT_SECRET: "your-github-oauth-app-secret"
```

---

## Implementation Roadmap

### Phase 1: Dex Setup (Week 1)

**Goals**: Deploy Dex with static users for testing

**Tasks**:
- [ ] Create Kubernetes namespace `auth-system`
- [ ] Deploy Dex with SQLite storage
- [ ] Configure TLS certificates (Let's Encrypt)
- [ ] Set up DNS: `auth.enopax.io`
- [ ] Create static admin user for testing
- [ ] Test OIDC discovery endpoint: `https://auth.enopax.io/.well-known/openid-configuration`

**Deliverables**:
- Dex running at `https://auth.enopax.io`
- Static admin user can log in
- OIDC endpoints functional

---

### Phase 2: Platform Integration (Week 2)

**Goals**: Connect Next.js Platform to Dex for authentication

**Tasks**:
- [ ] Configure NextAuth.js with Dex OIDC provider
- [ ] Implement login flow (redirect to Dex)
- [ ] Implement logout flow
- [ ] Test authentication end-to-end
- [ ] Map OIDC groups to Platform organisations/teams

**Deliverables**:
- Platform users can log in via Dex
- Session management working
- Group-based access control

---

### Phase 3: User Registration (Week 3)

**Goals**: Build self-service user registration

**Approach Decision**: Choose one:
- **Option A**: Platform UI + Dex gRPC API
- **Option B**: Platform UI + File sync to Dex

**Tasks** (Option A - gRPC API):
- [ ] Set up Dex gRPC API endpoint
- [ ] Create gRPC client in Platform (TypeScript)
- [ ] Build registration form (`/platform/app/register/page.tsx`)
- [ ] Implement password validation
- [ ] Call Dex gRPC API to create user
- [ ] Send email verification (optional)
- [ ] Test registration flow

**OR Tasks** (Option B - File Sync):
- [ ] Create `users.json` file structure
- [ ] Build registration form
- [ ] Write user to `users.json`
- [ ] Create sync script to update Dex config
- [ ] Trigger Dex config reload
- [ ] Test registration flow

**Deliverables**:
- Users can self-register via Platform
- New users can immediately log in
- Email verification (if implemented)

---

### Phase 4: Kubernetes Integration (Week 4)

**Goals**: Enable OIDC authentication for K8s API server

**Tasks**:
- [ ] Configure `kube-apiserver` with Dex OIDC parameters
- [ ] Create OIDC client in Dex for Kubernetes
- [ ] Set up group claims for RBAC
- [ ] Create ClusterRoles and RoleBindings
- [ ] Install `kubelogin` plugin for developers
- [ ] Document kubectl OIDC setup
- [ ] Test authentication and RBAC

**Deliverables**:
- Developers can authenticate to K8s via Dex
- RBAC based on groups from Dex
- Documentation for team onboarding

---

### Phase 5: Infrastructure Tools (Week 5)

**Goals**: Integrate Grafana and other tools

**Tasks**:
- [ ] Configure Grafana with Dex OIDC
- [ ] Set up role mapping (admin/viewer from groups)
- [ ] Test Grafana SSO
- [ ] Document access for team

**Deliverables**:
- Grafana uses Dex for authentication
- Consistent SSO across all tools

---

### Phase 6: Enhancements (Week 6)

**Goals**: Add MFA, social login, polish

**Tasks**:
- [ ] Enable GitHub connector in Dex
- [ ] Test social login flow
- [ ] Implement MFA (if Dex supports, or via Platform pre-auth)
- [ ] Create user management CLI/UI for admins
- [ ] Set up monitoring (Prometheus metrics from Dex)
- [ ] Security audit

**Deliverables**:
- Social login working (GitHub)
- Optional MFA for users
- Admin tools for user management

---

## Alternative: Custom Lightweight IdP

If you decide to **build your own** instead of using Dex, here's a high-level architecture:

### Stack Recommendation

**Language**: TypeScript (Node.js) or Go
**Framework**:
- TypeScript: `node-oidc-provider` library
- Go: `github.com/zitadel/oidc` library

**Storage**: JSON file or YAML

### Minimal Feature Set

1. **OIDC Endpoints**:
   - `/.well-known/openid-configuration` (discovery)
   - `/authorize` (authorization endpoint)
   - `/token` (token endpoint)
   - `/userinfo` (user info endpoint)

2. **User Management**:
   - Registration API (`POST /register`)
   - Login UI (HTML form)
   - File-based user storage (`users.json`)

3. **Security**:
   - Password hashing (bcrypt)
   - JWT signing (RS256)
   - HTTPS only

### Example Structure (TypeScript)

```
idp/
├── src/
│   ├── index.ts              # Main server
│   ├── oidc-provider.ts      # OIDC provider setup
│   ├── auth/
│   │   ├── registration.ts   # Registration logic
│   │   ├── login.ts          # Login logic
│   │   └── users.ts          # User file operations
│   ├── storage/
│   │   └── file-adapter.ts   # JSON file read/write
│   └── views/
│       ├── login.html        # Login form
│       └── register.html     # Registration form
├── data/
│   └── users.json            # User storage
├── keys/
│   ├── private.key           # RSA private key for JWT signing
│   └── public.key            # RSA public key
└── package.json
```

### Users JSON Format

```json
{
  "users": [
    {
      "id": "user-001",
      "email": "alice@example.com",
      "password_hash": "$2b$10$...",
      "name": "Alice Developer",
      "email_verified": true,
      "groups": ["org-acme", "enopax-admins"],
      "created_at": "2025-11-17T10:00:00Z"
    }
  ]
}
```

### Effort Estimate

- **Basic OIDC provider**: 2-3 weeks (using library)
- **User registration + login**: 1 week
- **Security hardening**: 1 week
- **Testing + documentation**: 1 week

**Total**: 5-6 weeks for MVP

**Recommendation**: Start with Dex, build custom later if needed

---

## Comparison Summary

| Aspect | Dex | Ory Hydra | Custom IdP |
|--------|-----|-----------|------------|
| **Effort** | Low (days) | Medium (weeks) | High (5-6 weeks) |
| **OIDC Compliance** | ✅ Certified | ✅ Certified | ⚠️ You must test |
| **User Registration** | Via gRPC API or file | You build | You build |
| **Resource Usage** | ~50MB RAM | ~30MB RAM + your app | ~30MB RAM (depends on stack) |
| **Maintenance** | Updates available | Updates available | You maintain |
| **File Storage** | SQLite (single file) | SQLite (single file) | JSON/YAML |
| **Production Ready** | ✅ Yes | ✅ Yes | ⚠️ After thorough testing |
| **Language** | Go | Go | Your choice (Rust/Go/TS) |

---

## Recommended Decision

### Start with: **Dex + Platform Registration**

**Why?**
1. **Fast to production**: Dex is ready to deploy today
2. **OIDC certified**: No compliance worries
3. **Lightweight**: Meets your resource requirements
4. **Proven**: Used by MicroK8s, major cloud platforms
5. **File-based**: SQLite is just one file, easy to backup
6. **Flexible**: Can add custom registration via Platform + gRPC API

**Path Forward**:
1. Deploy Dex (Phase 1)
2. Integrate Platform (Phase 2)
3. Build registration in Platform (Phase 3)
4. Connect Kubernetes (Phase 4)
5. If you later need more control → build custom IdP (swap Dex out)

---

## Questions for You

Before proceeding with implementation, please clarify:

1. **User Registration Preference**:
   - [ ] Platform handles registration UI, writes to Dex via gRPC
   - [ ] Platform handles registration UI, syncs to file, reloads Dex
   - [ ] Admin-provisioned users only (manual, no self-service)
   - [ ] Social login only (GitHub/Google, no passwords)

2. **Initial User Count**:
   - How many users initially? (helps decide on approach)

3. **Email Verification**:
   - [ ] Required for registration?
   - [ ] Optional?
   - [ ] Not needed?

4. **MFA Priority**:
   - [ ] Must-have for MVP?
   - [ ] Nice-to-have for later?
   - [ ] Not needed?

5. **Social Login**:
   - [ ] GitHub (primary)?
   - [ ] Google?
   - [ ] Both?
   - [ ] None (password only)?

---

## Next Steps

Once you answer the questions above, I can:

1. Create detailed implementation code for chosen approach
2. Write Kubernetes manifests for deployment
3. Build Platform registration UI (React/Next.js)
4. Write gRPC client code for Dex integration
5. Create admin scripts for user management

---

**End of Document**
