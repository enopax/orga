# Enopax Identity Provider (IdP) Concept

**Version**: 1.0
**Date**: 2025-11-17
**Status**: Concept / Architecture Design

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Requirements](#requirements)
3. [Solution Architecture](#solution-architecture)
4. [Technology Stack Comparison](#technology-stack-comparison)
5. [Recommended Solution](#recommended-solution)
6. [Integration Architecture](#integration-architecture)
7. [Security Considerations](#security-considerations)
8. [Deployment Strategy](#deployment-strategy)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Operational Considerations](#operational-considerations)
11. [Appendix](#appendix)

---

## Executive Summary

This document outlines the architecture and technology stack for implementing a centralised OpenID Connect (OIDC) Identity Provider (IdP) for the Enopax ecosystem. The IdP will serve as the single source of truth for user authentication across:

- **Web Platform** (Next.js application)
- **Kubernetes Clusters** (API server authentication)
- **Infrastructure Tools** (Grafana, monitoring, databases, etc.)
- **Custom Services** (Resource API, providers, etc.)

### Key Goals

1. **Single Sign-On (SSO)**: Users authenticate once and access all Enopax services
2. **Centralised Identity**: One identity system for all users, services, and infrastructure
3. **GDPR Compliance**: EU-hosted infrastructure with full data sovereignty
4. **Developer Experience**: Simple integration via OIDC for all services
5. **Security**: Industry-standard authentication with MFA, audit logging, and RBAC
6. **Scalability**: Support growth from MVP to enterprise scale

---

## Requirements

### Functional Requirements

#### User Registration & Authentication
- Self-service user registration via web interface
- Email/password authentication (primary method)
- Social login integration (GitHub, Google) for user convenience
- Multi-factor authentication (TOTP, WebAuthn)
- Password reset and account recovery flows
- Email verification for new registrations

#### Authorisation & Access Control
- Role-Based Access Control (RBAC)
- Support for Enopax's organisational hierarchy:
  - Organisations
  - Teams within organisations
  - Projects within organisations
  - User roles at each level
- Group management for Kubernetes RBAC mapping
- Fine-grained permissions for resources

#### OIDC Protocol Support
- Full OpenID Connect 1.0 compliance
- OAuth 2.0 support for service-to-service authentication
- PKCE (Proof Key for Code Exchange) for enhanced security
- Token refresh mechanisms
- Logout and session management

#### Integration Requirements
- **Next.js Platform**: NextAuth.js v5 (Auth.js) integration
- **Kubernetes**: API server OIDC authentication
  - Group claims for RBAC mapping
  - Token validation
  - Short-lived tokens with refresh capability
- **Infrastructure Tools**:
  - Grafana
  - Prometheus
  - PostgreSQL (connection pooling with OIDC)
  - Any OIDC-compliant application
- **API Services**: Machine-to-machine authentication with service accounts

#### User Management
- Admin UI for user management
- Organisation/team/project hierarchy management
- User invitation workflows
- User deactivation and deletion (GDPR right to be forgotten)
- Audit logging of authentication events

### Non-Functional Requirements

#### Performance
- Support 1,000+ concurrent users (initial scale)
- < 200ms authentication response time (95th percentile)
- Token validation < 50ms
- Horizontal scalability for future growth

#### Security
- Industry-standard security practices (OWASP)
- Secure token storage and rotation
- Rate limiting and brute-force protection
- Security headers (HSTS, CSP, etc.)
- Regular security updates

#### Availability
- 99.9% uptime target
- High availability deployment (multiple replicas)
- Automatic failover
- Backup and disaster recovery

#### Compliance
- **GDPR Compliance**:
  - EU-based infrastructure
  - Data minimisation
  - Right to access, rectify, erase
  - Data portability
  - Audit trails
- **Security Standards**:
  - HTTPS/TLS 1.3
  - Encrypted data at rest
  - Secure password hashing (bcrypt, Argon2)

#### Maintainability
- Open-source solution (avoid vendor lock-in)
- Active community and regular updates
- Clear documentation
- Infrastructure as Code (IaC) deployment
- Automated backup and updates

---

## Solution Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ENOPAX ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Platform   │  │ Kubernetes   │  │ Infrastructure│         │
│  │   (Next.js)  │  │   Clusters   │  │     Tools     │         │
│  │              │  │              │  │  (Grafana,    │         │
│  │  NextAuth.js │  │  API Server  │  │   Prometheus) │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘         │
│         │                 │                 │                  │
│         │                 │                 │                  │
│         └─────────────────┼─────────────────┘                  │
│                           │                                    │
│                           │ OIDC Protocol                      │
│                           │                                    │
│         ┌─────────────────▼─────────────────┐                  │
│         │                                   │                  │
│         │     IDENTITY PROVIDER (IdP)       │                  │
│         │                                   │                  │
│         │  ┌─────────────────────────────┐  │                  │
│         │  │   OIDC / OAuth 2.0 Endpoints│  │                  │
│         │  │  - Authorization            │  │                  │
│         │  │  - Token                    │  │                  │
│         │  │  - UserInfo                 │  │                  │
│         │  │  - Discovery (.well-known)  │  │                  │
│         │  └─────────────────────────────┘  │                  │
│         │                                   │                  │
│         │  ┌─────────────────────────────┐  │                  │
│         │  │    User Management          │  │                  │
│         │  │  - Registration             │  │                  │
│         │  │  - Authentication           │  │                  │
│         │  │  - Profile Management       │  │                  │
│         │  │  - MFA                      │  │                  │
│         │  └─────────────────────────────┘  │                  │
│         │                                   │                  │
│         │  ┌─────────────────────────────┐  │                  │
│         │  │   Organisation/Team/Project │  │                  │
│         │  │   Hierarchy Management      │  │                  │
│         │  │  - RBAC                     │  │                  │
│         │  │  - Group Management         │  │                  │
│         │  │  - Claims/Scopes            │  │                  │
│         │  └─────────────────────────────┘  │                  │
│         │                                   │                  │
│         │  ┌─────────────────────────────┐  │                  │
│         │  │      Admin Interface        │  │                  │
│         │  │  - User Management UI       │  │                  │
│         │  │  - Audit Logs               │  │                  │
│         │  │  - Configuration            │  │                  │
│         │  └─────────────────────────────┘  │                  │
│         │                                   │                  │
│         └───────────────┬───────────────────┘                  │
│                         │                                      │
│                         │                                      │
│         ┌───────────────▼───────────────┐                      │
│         │      PostgreSQL Database      │                      │
│         │  - Users                      │                      │
│         │  - Organisations/Teams        │                      │
│         │  - Sessions/Tokens            │                      │
│         │  - Audit Logs                 │                      │
│         └───────────────────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

                   ┌────────────────────────┐
                   │   External IdPs        │
                   │  - GitHub OAuth        │
                   │  - Google OAuth        │
                   │  (Social Login)        │
                   └────────────────────────┘
```

### Authentication Flow

#### Standard OIDC Authorization Code Flow (for web applications)

```
┌─────────┐                                         ┌─────────┐
│ User    │                                         │Platform │
│ Browser │                                         │(Next.js)│
└────┬────┘                                         └────┬────┘
     │                                                   │
     │  1. Access protected resource                    │
     ├──────────────────────────────────────────────────>│
     │                                                   │
     │  2. Redirect to IdP /authorize                   │
     │     + client_id, redirect_uri, scope, state      │
     │<──────────────────────────────────────────────────┤
     │                                                   │
     │         ┌─────────┐                              │
     │         │   IdP   │                              │
     │         └────┬────┘                              │
     │              │                                   │
     │  3. Login    │                                   │
     ├─────────────>│                                   │
     │              │                                   │
     │  4. Auth     │                                   │
     │     Code     │                                   │
     │<─────────────┤                                   │
     │              │                                   │
     │  5. Redirect to platform with code              │
     ├──────────────────────────────────────────────────>│
     │                                                   │
     │                    6. Exchange code for tokens   │
     │                       (authorization_code)       │
     │              ┌────────────────────────────────────┤
     │              │                                    │
     │              │  7. id_token + access_token       │
     │              │     + refresh_token                │
     │              └───────────────────────────────────>│
     │                                                   │
     │  8. Access granted with user session             │
     │<──────────────────────────────────────────────────┤
     │                                                   │
```

#### Kubernetes OIDC Authentication Flow

```
┌─────────┐                                    ┌─────────────┐
│Developer│                                    │  Kubernetes │
│         │                                    │  API Server │
└────┬────┘                                    └──────┬──────┘
     │                                                │
     │  1. kubectl login (OIDC plugin)               │
     │       ┌─────────┐                             │
     │       │   IdP   │                             │
     │       └────┬────┘                             │
     │            │                                  │
     │  2. Auth   │                                  │
     ├───────────>│                                  │
     │            │                                  │
     │  3. Tokens │                                  │
     │  (id_token)│                                  │
     │<───────────┤                                  │
     │            │                                  │
     │  4. kubectl command + Bearer token            │
     ├──────────────────────────────────────────────>│
     │                                               │
     │            5. Validate token with IdP         │
     │            ┌──────────────────────────────────┤
     │            │                                  │
     │            │  6. Token valid + user claims    │
     │            │     (groups, email, etc.)        │
     │            └─────────────────────────────────>│
     │                                               │
     │                    7. Map groups to RBAC      │
     │                       Check permissions       │
     │                                               │
     │  8. API response (if authorised)              │
     │<──────────────────────────────────────────────┤
     │                                               │
```

---

## Technology Stack Comparison

Based on extensive research of current (2025) OIDC identity provider solutions, here are the leading options:

### Option 1: Keycloak

**Overview**: Enterprise-grade, open-source IAM solution maintained by Red Hat.

**Pros**:
- ✅ Most mature and battle-tested solution
- ✅ Comprehensive features out-of-the-box
- ✅ Excellent protocol support (OIDC, SAML, OAuth2)
- ✅ Built-in admin UI for user/role management
- ✅ Strong LDAP/Active Directory integration
- ✅ Extensive documentation and large community (31k+ GitHub stars)
- ✅ User federation capabilities
- ✅ Advanced customisation options
- ✅ Enterprise support available (Red Hat)
- ✅ Proven at scale (used by Fortune 500 companies)

**Cons**:
- ❌ Resource-intensive (Java-based, high memory usage)
- ❌ Complex to configure for simple use cases
- ❌ Steeper learning curve
- ❌ Heavier operational overhead
- ❌ UI feels dated compared to modern alternatives

**Best For**: Enterprise deployments, complex IAM requirements, legacy system integration

**Deployment**: Docker, Kubernetes (official Helm charts), standalone

**Resource Requirements**:
- Minimum: 2 vCPUs, 2GB RAM
- Recommended: 4 vCPUs, 4-8GB RAM for production

---

### Option 2: Authentik

**Overview**: Modern, Python-based identity provider focused on simplicity and developer experience.

**Pros**:
- ✅ Clean, modern UI (best admin interface)
- ✅ Lightweight and resource-efficient
- ✅ Easy to deploy and configure
- ✅ Excellent documentation
- ✅ Native Kubernetes/Docker support
- ✅ Workflow-based authentication (flexible flows)
- ✅ Built-in application proxy (forward auth)
- ✅ Active development and growing community (18k+ GitHub stars)
- ✅ Modern stack (Python, TypeScript)
- ✅ Great for microservices architectures
- ✅ Enterprise support recently added

**Cons**:
- ❌ Less mature than Keycloak (newer project)
- ❌ Smaller ecosystem and community
- ❌ Limited LDAP/AD integration compared to Keycloak
- ❌ Fewer third-party integrations

**Best For**: Modern cloud-native deployments, small-to-medium teams, developer-focused organisations

**Deployment**: Docker Compose, Kubernetes (Helm charts), embedded PostgreSQL support

**Resource Requirements**:
- Minimum: 1 vCPU, 1GB RAM
- Recommended: 2 vCPUs, 2GB RAM for production

---

### Option 3: Zitadel

**Overview**: Cloud-native, API-first identity platform with strong multi-tenancy.

**Pros**:
- ✅ Built for cloud-native from the ground up
- ✅ Excellent multi-tenancy support (best in class)
- ✅ Modern API-first design
- ✅ TypeScript Login UI (highly customisable)
- ✅ Strong focus on developer experience
- ✅ Built-in audit logging
- ✅ Kubernetes-native (Helm charts)
- ✅ Active development (backed by Swiss company)
- ✅ Good documentation
- ✅ GDPR-compliant by design

**Cons**:
- ❌ Smaller community than Keycloak
- ❌ Relatively new (less battle-tested)
- ❌ Limited third-party integration examples
- ❌ Go-based (may require Go knowledge for customisation)

**Best For**: Multi-tenant SaaS platforms, modern cloud-native deployments, API-heavy architectures

**Deployment**: Kubernetes (Helm), Docker, cloud-managed option available

**Resource Requirements**:
- Minimum: 1 vCPU, 1GB RAM
- Recommended: 2 vCPUs, 2-4GB RAM for production

---

### Option 4: Ory Kratos + Hydra

**Overview**: Microservice-based identity stack (Kratos for identity, Hydra for OAuth2/OIDC).

**Pros**:
- ✅ Ultra-lightweight and performant
- ✅ API-first architecture (maximum flexibility)
- ✅ Cloud-native design
- ✅ Excellent for headless/custom UI
- ✅ Strong security focus
- ✅ Managed option available (Ory Network)
- ✅ Modern Go-based stack

**Cons**:
- ❌ No built-in admin UI (requires custom development)
- ❌ More complex setup (multiple services)
- ❌ Steeper learning curve
- ❌ Requires more custom development
- ❌ Best suited for teams with strong technical expertise

**Best For**: Highly customised deployments, teams with deep technical expertise, headless architectures

**Deployment**: Docker, Kubernetes, Ory Network (managed)

**Resource Requirements**:
- Minimum: 1 vCPU, 512MB RAM per service
- Recommended: 2 vCPUs, 1GB RAM per service

---

### Option 5: Managed Services (Auth0, Cognito, etc.)

**Overview**: Fully managed cloud identity platforms.

**Examples**: Auth0 (Okta), AWS Cognito, Azure AD B2C, Google Identity Platform

**Pros**:
- ✅ Zero operational overhead
- ✅ Instant scalability
- ✅ Professional support
- ✅ Fast time-to-market
- ✅ Enterprise-grade SLAs
- ✅ Compliance certifications

**Cons**:
- ❌ Ongoing costs (usage-based pricing)
- ❌ Vendor lock-in
- ❌ Data hosted outside EU (GDPR concerns for some providers)
- ❌ Less control over customisation
- ❌ Potential cost escalation at scale

**Best For**: Rapid prototyping, teams without ops expertise, enterprise customers with budget

---

## Recommended Solution

### Primary Recommendation: **Authentik**

After evaluating all options against Enopax's requirements, **Authentik** is the recommended solution for the following reasons:

#### Why Authentik?

1. **Modern & Developer-Friendly**
   - Clean, intuitive admin interface (best in class)
   - Easy to configure and maintain
   - Excellent documentation with practical examples
   - Modern tech stack (Python + TypeScript)

2. **Resource Efficiency**
   - Lightweight compared to Keycloak (50-75% less memory)
   - Suitable for MVP and scales to production
   - Lower infrastructure costs

3. **Cloud-Native Design**
   - Native Kubernetes support
   - Docker-first deployment model
   - Fits Enopax's microservices architecture

4. **GDPR Compliance**
   - Self-hosted on EU infrastructure
   - Full data sovereignty
   - Built-in audit logging
   - Right-to-delete workflows

5. **Feature Completeness**
   - Full OIDC/OAuth2 support
   - Built-in admin UI (no custom development needed)
   - Workflow-based authentication (flexible)
   - Application proxy for non-OIDC apps
   - Social login support (GitHub, Google)
   - MFA/2FA support (TOTP, WebAuthn)

6. **Integration Points**
   - Well-documented NextAuth.js integration
   - Kubernetes OIDC authentication guides
   - Grafana, Prometheus integration examples
   - RESTful API for automation

7. **Growing Ecosystem**
   - Active development and community
   - Enterprise support now available
   - Regular security updates

#### Trade-offs

**When Authentik might not be ideal**:
- Very large enterprises with extensive legacy integration needs → Keycloak better
- Multi-tenant SaaS with hundreds of organisations → Zitadel better
- Extreme customisation requirements → Ory better

**For Enopax's use case** (cloud infrastructure platform, modern stack, EU-focused, growing user base), Authentik provides the best balance of features, ease of use, and operational simplicity.

---

### Alternative: Keycloak (if requirements change)

**Consider Keycloak if**:
- You need extensive LDAP/Active Directory integration
- Enterprise customers require SAML support
- You have existing Keycloak expertise
- You need maximum protocol flexibility
- You can allocate more infrastructure resources

Keycloak is a solid alternative and more mature, but requires more operational overhead.

---

## Integration Architecture

### 1. Next.js Platform Integration (NextAuth.js v5)

**Implementation**: NextAuth.js (Auth.js) with custom OIDC provider

**Configuration**:
```typescript
// /platform/auth.config.ts
import type { NextAuthConfig } from "next-auth"

export default {
  providers: [
    {
      id: "authentik",
      name: "Enopax",
      type: "oidc",
      issuer: "https://auth.enopax.io/application/o/enopax-platform/",
      clientId: process.env.AUTHENTIK_CLIENT_ID,
      clientSecret: process.env.AUTHENTIK_CLIENT_SECRET,
      authorization: {
        params: {
          scope: "openid email profile groups",
        },
      },
      profile(profile) {
        return {
          id: profile.sub,
          email: profile.email,
          name: profile.name,
          image: profile.picture,
          groups: profile.groups, // Map to organisations/teams
        }
      },
    },
  ],
  callbacks: {
    async jwt({ token, account, profile }) {
      if (account && profile) {
        token.groups = profile.groups
        token.accessToken = account.access_token
      }
      return token
    },
    async session({ session, token }) {
      session.user.groups = token.groups
      session.accessToken = token.accessToken
      return session
    },
  },
} satisfies NextAuthConfig
```

**Features**:
- Single sign-on for Platform users
- Group-based access control (organisations, teams)
- Automatic user provisioning from IdP claims
- Token refresh handling
- Session management

---

### 2. Kubernetes Cluster Integration

**Implementation**: Kubernetes API Server OIDC authentication

**Configuration** (per cluster):
```yaml
# kube-apiserver configuration
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - command:
    - kube-apiserver
    - --oidc-issuer-url=https://auth.enopax.io/application/o/kubernetes/
    - --oidc-client-id=kubernetes-api
    - --oidc-username-claim=email
    - --oidc-groups-claim=groups
    - --oidc-username-prefix="oidc:"
    - --oidc-groups-prefix="oidc:"
```

**RBAC Configuration**:
```yaml
# ClusterRoleBinding for Enopax administrators
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: enopax-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: oidc:enopax-admins
  apiGroup: rbac.authorization.k8s.io
```

**User Workflow**:
1. Install `kubectl` OIDC plugin (e.g., `kubelogin`)
2. Configure `~/.kube/config` with OIDC settings
3. Run `kubectl oidc-login` → browser opens for authentication
4. Receive tokens (id_token stored in kubeconfig)
5. All kubectl commands use id_token for authentication

**Features**:
- Group-based RBAC (IdP groups → Kubernetes RBAC)
- Short-lived tokens (configurable, e.g., 1 hour)
- Automatic token refresh
- Audit logging of API access

---

### 3. Infrastructure Tools Integration

#### Grafana

**Configuration**:
```ini
# /etc/grafana/grafana.ini
[auth.generic_oauth]
enabled = true
name = Enopax
allow_sign_up = true
client_id = grafana
client_secret = ${AUTHENTIK_GRAFANA_SECRET}
scopes = openid profile email groups
auth_url = https://auth.enopax.io/application/o/authorize/
token_url = https://auth.enopax.io/application/o/token/
api_url = https://auth.enopax.io/application/o/userinfo/
role_attribute_path = contains(groups, 'enopax-admins') && 'Admin' || 'Viewer'
```

#### Prometheus (via OAuth2 Proxy)

**Architecture**: OAuth2 Proxy as reverse proxy in front of Prometheus

```yaml
# oauth2-proxy deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oauth2-proxy
spec:
  template:
    spec:
      containers:
      - name: oauth2-proxy
        image: quay.io/oauth2-proxy/oauth2-proxy:latest
        args:
        - --provider=oidc
        - --oidc-issuer-url=https://auth.enopax.io/application/o/prometheus/
        - --upstream=http://prometheus:9090
        - --email-domain=*
        - --cookie-secret=${COOKIE_SECRET}
```

#### PostgreSQL (Connection Pooling with PgBouncer + OIDC)

**Note**: PostgreSQL doesn't natively support OIDC. For database access:
- Use platform authentication (users access DB via platform)
- For direct DB access by developers: use SSH tunnel + OIDC-authenticated bastion host
- Alternative: PgBouncer with custom auth script validating OIDC tokens

---

### 4. Resource API & Providers

**Implementation**: JWT validation middleware

```javascript
// resource-api/middleware/auth.js
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'https://auth.enopax.io/application/o/resource-api/.well-known/openid-configuration/jwks'
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  jwt.verify(token, getKey, {
    audience: 'resource-api',
    issuer: 'https://auth.enopax.io/application/o/resource-api/',
    algorithms: ['RS256']
  }, (err, decoded) => {
    if (err) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    req.user = decoded;
    next();
  });
};

module.exports = verifyToken;
```

---

## Security Considerations

### 1. Token Security

**Access Tokens**:
- Short-lived (15 minutes to 1 hour)
- JWT format with digital signatures (RS256)
- Include user claims (email, groups, org)
- Validated on every request

**Refresh Tokens**:
- Longer-lived (7-30 days)
- Stored securely (httpOnly cookies for web)
- Rotation on use (refresh token rotation)
- Revocable via admin interface

**ID Tokens**:
- Used for authentication proof
- Contains user identity claims
- Verified by Kubernetes API server
- Not used for authorisation decisions

### 2. Secret Management

**Storage**:
- Client secrets stored in environment variables
- Kubernetes secrets for cluster deployments
- Consider HashiCorp Vault for production

**Rotation**:
- Regular rotation of client secrets (quarterly)
- Automatic key rotation for signing keys
- Emergency rotation procedures documented

### 3. Password Security

**Hashing**:
- Argon2id (recommended) or bcrypt
- Minimum password requirements enforced
- Password breach detection (HaveIBeenPwned integration)

**Policies**:
- Minimum 12 characters
- Complexity requirements (optional, depends on user preference)
- Password expiry (optional, for compliance)
- Account lockout after failed attempts

### 4. Multi-Factor Authentication (MFA)

**Supported Methods**:
- TOTP (Time-based One-Time Password) - Google Authenticator, Authy
- WebAuthn (hardware keys) - YubiKey, platform authenticators
- Backup codes

**Enforcement**:
- Optional by default
- Can be required for specific groups (admins)
- Grace period for enrollment

### 5. Session Management

**Session Policies**:
- Idle timeout (30 minutes)
- Absolute timeout (12 hours for web, configurable for kubectl)
- Concurrent session limits
- Device tracking

**Logout**:
- Single logout (SLO) support
- Revoke all sessions option
- Token revocation endpoints

### 6. Audit Logging

**Logged Events**:
- Authentication attempts (success/failure)
- Password changes
- MFA enrollment/usage
- Admin actions (user creation, deletion)
- Permission changes
- Token issuance and validation

**Log Storage**:
- Minimum 90 days retention (GDPR compliance)
- Immutable logs
- Integration with SIEM (future)

### 7. Network Security

**TLS/HTTPS**:
- TLS 1.3 minimum
- Valid SSL certificates (Let's Encrypt)
- HSTS headers
- Secure cipher suites

**Rate Limiting**:
- Login endpoint: 5 attempts per minute per IP
- Token endpoint: 10 requests per minute per client
- Registration endpoint: 3 per hour per IP

**DDoS Protection**:
- Cloudflare or similar (optional)
- Application-level rate limiting
- IP blocklisting for abuse

---

## Deployment Strategy

### Infrastructure Requirements

#### Production Environment (Authentik)

**Components**:
- Authentik Server (2 replicas for HA)
- Authentik Worker (background tasks)
- PostgreSQL database (HA cluster recommended)
- Redis (session storage, caching)

**Resource Allocation** (Kubernetes):
```yaml
# Authentik Server
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
replicas: 2

# Authentik Worker
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
replicas: 1

# PostgreSQL
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 4Gi

# Redis
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Total Minimum Requirements**:
- **CPU**: ~3 vCPUs
- **Memory**: ~6GB RAM
- **Storage**: 20GB for database (grows with users)

---

### Kubernetes Deployment

**Namespace**: `auth-system`

**Helm Chart** (Authentik official):
```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update

helm install authentik authentik/authentik \
  --namespace auth-system \
  --create-namespace \
  --set authentik.secret_key=${SECRET_KEY} \
  --set authentik.postgresql.password=${DB_PASSWORD} \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=auth.enopax.io \
  --set ingress.tls[0].hosts[0]=auth.enopax.io \
  --set ingress.tls[0].secretName=authentik-tls
```

**Storage**:
- PostgreSQL: Persistent volume (50GB, SSD-backed)
- Redis: Ephemeral (can be recreated)
- Backups: Daily automated snapshots

---

### High Availability Setup

**Components**:
1. **Load Balancer**: Distribute traffic across Authentik replicas
2. **Database**: PostgreSQL with replication (primary + standby)
3. **Redis**: Redis Sentinel for automatic failover
4. **Ingress**: HTTPS termination with cert-manager (Let's Encrypt)

**Failover Strategy**:
- Automatic pod restart on failure
- Database failover (primary → standby)
- Redis Sentinel promotes new master
- Health checks on all components

---

### Backup & Disaster Recovery

**Backup Strategy**:
- **Database**: Daily full backup + continuous WAL archiving
- **Configuration**: Version-controlled Helm values, Kubernetes manifests
- **Secrets**: Encrypted backup in separate location

**Backup Schedule**:
- Daily: Full database backup (retain 7 days)
- Weekly: Long-term backup (retain 4 weeks)
- Monthly: Archive backup (retain 1 year)

**Recovery Time Objective (RTO)**: < 4 hours
**Recovery Point Objective (RPO)**: < 1 hour (via WAL archiving)

**Disaster Recovery Testing**: Quarterly restoration drills

---

### Monitoring & Alerting

**Metrics** (Prometheus):
- Authentication success/failure rate
- Token issuance rate
- Active sessions
- Response time (p50, p95, p99)
- Error rates
- Database connection pool usage

**Dashboards** (Grafana):
- Authentication overview
- User activity
- System health
- Security events

**Alerts**:
- High authentication failure rate (> 10% over 5 minutes)
- Service downtime
- Database connection errors
- Certificate expiry (30 days before)
- Unusual login patterns (anomaly detection)

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Goals**: Deploy basic Authentik instance, configure core OIDC

**Tasks**:
- [ ] Provision Kubernetes namespace and resources
- [ ] Deploy Authentik via Helm chart
- [ ] Configure PostgreSQL database
- [ ] Set up TLS certificates (Let's Encrypt)
- [ ] Configure DNS (auth.enopax.io)
- [ ] Create initial admin user
- [ ] Configure OIDC application for Platform
- [ ] Test basic authentication flow

**Deliverables**:
- Authentik running on `https://auth.enopax.io`
- Admin access configured
- OIDC endpoints accessible

---

### Phase 2: Platform Integration (Weeks 3-4)

**Goals**: Integrate Next.js Platform with Authentik via NextAuth.js

**Tasks**:
- [ ] Configure NextAuth.js with Authentik provider
- [ ] Implement login/logout flows
- [ ] Map OIDC groups to Platform organisations/teams
- [ ] Migrate existing users (if any) or create migration tool
- [ ] Implement group-based access control in Platform
- [ ] Test SSO flow end-to-end
- [ ] Update Platform UI (login page branding)

**Deliverables**:
- Platform uses Authentik for authentication
- Users can log in with SSO
- Group-based permissions working

---

### Phase 3: Kubernetes Integration (Weeks 5-6)

**Goals**: Enable OIDC authentication for Kubernetes clusters

**Tasks**:
- [ ] Configure kube-apiserver with OIDC parameters
- [ ] Create Authentik OIDC application for Kubernetes
- [ ] Set up group claims for RBAC mapping
- [ ] Create ClusterRoles and RoleBindings
- [ ] Document kubectl OIDC setup for developers
- [ ] Test authentication and authorisation
- [ ] Create helper scripts for kubeconfig generation

**Deliverables**:
- Kubernetes API server accepts OIDC tokens
- Developers can authenticate to clusters via Authentik
- RBAC based on IdP groups

---

### Phase 4: Infrastructure Tools (Weeks 7-8)

**Goals**: Integrate Grafana, Prometheus, and other tools

**Tasks**:
- [ ] Configure Grafana OIDC authentication
- [ ] Deploy oauth2-proxy for Prometheus
- [ ] Set up role mapping (admin, viewer)
- [ ] Test SSO for all tools
- [ ] Document access procedures

**Deliverables**:
- Grafana uses Authentik SSO
- Prometheus accessible via OIDC (oauth2-proxy)
- Consistent authentication across monitoring stack

---

### Phase 5: Advanced Features (Weeks 9-10)

**Goals**: Enable MFA, social login, and security hardening

**Tasks**:
- [ ] Enable MFA (TOTP, WebAuthn)
- [ ] Configure social login (GitHub, Google)
- [ ] Implement rate limiting and brute-force protection
- [ ] Set up audit logging and monitoring
- [ ] Create user documentation (how to enable MFA, etc.)
- [ ] Security audit and penetration testing

**Deliverables**:
- MFA available for all users
- Social login options (GitHub, Google)
- Enhanced security posture
- Audit logs and monitoring dashboards

---

### Phase 6: Production Hardening (Weeks 11-12)

**Goals**: HA, backups, disaster recovery, monitoring

**Tasks**:
- [ ] Implement high availability (multiple replicas)
- [ ] Set up PostgreSQL replication
- [ ] Configure automated backups
- [ ] Implement disaster recovery procedures
- [ ] Set up comprehensive monitoring and alerting
- [ ] Load testing and performance tuning
- [ ] Create runbooks for common issues
- [ ] Final security review and GDPR compliance audit

**Deliverables**:
- Production-ready Authentik deployment
- HA configuration with failover
- Automated backups and DR procedures
- Monitoring and alerting in place
- Documentation complete

---

## Operational Considerations

### User Management Workflows

#### New User Registration
1. User visits Platform → clicks "Sign Up"
2. Redirected to Authentik registration page
3. User provides email, password, name
4. Email verification sent
5. User clicks verification link
6. Account activated, user logged in
7. Platform receives user claims, creates local user record
8. User assigned to default organisation/team

#### User Invitation (Admin-initiated)
1. Admin invites user via Platform UI
2. Platform calls Authentik API to create user account
3. Invitation email sent with activation link
4. User sets password and completes profile
5. User gains access to assigned organisation/team

#### Password Reset
1. User clicks "Forgot Password" on login page
2. Authentik sends reset email
3. User clicks link, sets new password
4. Password reset confirmed

#### User Deactivation
1. Admin deactivates user in Authentik
2. All active sessions invalidated
3. Tokens revoked
4. User cannot log in

#### User Deletion (GDPR Right to be Forgotten)
1. User requests account deletion
2. Admin initiates deletion in Authentik
3. User data anonymised/deleted
4. Audit log entry created (cannot be deleted per GDPR audit requirements)

---

### Organisation/Team Management

**Authentik Groups Structure**:
```
enopax-users (all users)
├── org-acme
│   ├── org-acme-admins
│   ├── org-acme-developers
│   └── org-acme-viewers
├── org-example
│   ├── org-example-admins
│   └── org-example-developers
└── enopax-admins (platform administrators)
```

**Group Claims in Tokens**:
```json
{
  "sub": "user-id-123",
  "email": "user@example.com",
  "groups": [
    "enopax-users",
    "org-acme",
    "org-acme-developers"
  ]
}
```

**Platform Mapping**:
- Platform reads `groups` claim
- Maps groups to organisations and roles
- Enforces access control based on group membership

---

### Maintenance Windows

**Planned Maintenance**:
- **Frequency**: Monthly (first Sunday of the month)
- **Window**: 02:00-04:00 UTC
- **Activities**: Software updates, security patches, database maintenance
- **Notification**: 7 days advance notice via platform

**Emergency Maintenance**:
- Critical security patches: immediate
- User notification: via platform banner and email

---

### Cost Estimation

#### Infrastructure Costs (Monthly, EU Region)

**Kubernetes Cluster** (assuming shared with other services):
- Authentik: ~€50-100/month (based on ~3 vCPUs, 6GB RAM)
- PostgreSQL: ~€30-50/month (managed DB or persistent volume)
- Redis: ~€10-20/month
- Load Balancer: ~€10/month
- Backups: ~€10/month

**Total Estimated Cost**: €110-190/month

**Scaling Considerations**:
- Costs scale with user count (database size)
- Network egress costs (minimal for OIDC traffic)
- Additional replicas for HA (+€50/month per replica)

#### Alternative: Managed Authentik Cloud

Authentik offers managed cloud option:
- Estimated: €100-500/month depending on user count
- Zero operational overhead
- Professional support included
- Consider if internal ops resources limited

---

### Compliance & Auditing

#### GDPR Compliance Checklist

- [x] Data stored in EU region
- [x] Right to access (user can download data)
- [x] Right to rectification (user can update profile)
- [x] Right to erasure (user can request deletion)
- [x] Right to data portability (export user data)
- [x] Consent management (registration flow)
- [x] Data breach notification procedures
- [x] Privacy policy and terms of service
- [x] Data retention policies
- [x] Audit logging (who accessed what, when)

#### Security Audits

**Frequency**: Quarterly

**Scope**:
- Access control review (who has admin access?)
- Password policy compliance
- MFA adoption rate
- Inactive user accounts (deactivate after 90 days)
- Audit log review for suspicious activity
- Certificate expiry checks
- Dependency updates (security patches)

---

### Support & Escalation

#### Support Tiers

**Tier 1: Self-Service**
- User documentation (how to log in, enable MFA)
- FAQ and troubleshooting guides
- Platform help centre

**Tier 2: Platform Support**
- Email support for login issues
- Password reset assistance
- Account unlock

**Tier 3: Technical Support**
- Integration issues
- API problems
- Infrastructure team escalation

**Tier 4: Authentik Community/Enterprise**
- Complex configuration issues
- Bugs and feature requests
- Security incidents

#### Incident Response

**Authentication Outage**:
1. Automated alert triggered
2. On-call engineer notified
3. Triage and investigation
4. Failover to standby (if applicable)
5. Root cause analysis post-incident

**Security Incident**:
1. Immediate investigation
2. Revoke compromised credentials
3. Force password reset if needed
4. Notify affected users
5. Post-incident review and remediation

---

## Appendix

### A. Glossary

- **OIDC (OpenID Connect)**: Authentication protocol built on OAuth 2.0
- **OAuth 2.0**: Authorisation framework for delegated access
- **IdP (Identity Provider)**: System that authenticates users and issues tokens
- **SSO (Single Sign-On)**: Authenticate once, access multiple services
- **RBAC (Role-Based Access Control)**: Permissions based on roles
- **MFA (Multi-Factor Authentication)**: Multiple authentication factors (password + TOTP)
- **JWT (JSON Web Token)**: Compact token format for claims
- **PKCE (Proof Key for Code Exchange)**: Security extension for OAuth 2.0
- **SAML (Security Assertion Markup Language)**: XML-based SSO protocol (legacy)

---

### B. Reference Links

**Authentik**:
- Official Documentation: https://docs.goauthentik.io/
- GitHub: https://github.com/goauthentik/authentik
- Helm Chart: https://github.com/goauthentik/helm

**Kubernetes OIDC**:
- Kubernetes OIDC Authentication: https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens
- kubelogin (kubectl OIDC plugin): https://github.com/int128/kubelogin

**NextAuth.js**:
- Documentation: https://authjs.dev/
- Custom OIDC Provider: https://authjs.dev/guides/configuring-oauth-providers

**Security Best Practices**:
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OIDC Security Best Practices: https://openid.net/specs/openid-connect-core-1_0.html#Security

---

### C. Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-17 | Choose Authentik over Keycloak | Modern UI, resource-efficient, easier ops, sufficient features for Enopax scale |
| 2025-11-17 | Self-hosted vs. managed | GDPR compliance, cost control, avoid vendor lock-in |
| 2025-11-17 | EU infrastructure required | GDPR data sovereignty, align with Enopax's European positioning |
| 2025-11-17 | PostgreSQL for IdP database | Consistency with Platform, mature, well-supported by Authentik |

---

### D. Open Questions

| Question | Status | Owner | Target Date |
|----------|--------|-------|-------------|
| Should we enable social login by default or opt-in? | Open | Product Team | Week 1 |
| What is the MFA enforcement policy (optional, required for admins, required for all)? | Open | Security Team | Week 2 |
| Do we need SAML support for enterprise customers? | Open | Sales Team | Phase 5 |
| Should we use managed Authentik Cloud or self-hosted? | Open | Ops Team | Week 1 |
| What is the password expiry policy (if any)? | Open | Security Team | Week 3 |

---

### E. Next Steps

1. **Review & Approval**: Share this document with stakeholders for review
2. **Decision on Open Questions**: Resolve open questions (see Appendix D)
3. **Resource Allocation**: Assign engineering resources for implementation
4. **Infrastructure Provisioning**: Prepare Kubernetes cluster and resources
5. **Begin Phase 1**: Deploy Authentik instance and start integration work

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-17 | AI Assistant | Initial concept document based on research and requirements |

---

**End of Document**
