# Enopax Organisational Overview

**Last Updated**: 2025-10-09

---

## Mission & Vision

**Enopax** is building a modern infrastructure-as-a-service platform that makes cloud resource provisioning as simple as clicking a button. We enable users to deploy IPFS storage clusters, databases, and other services through an intuitive web interface with a focus on European infrastructure and GDPR compliance.

---

## Organisation Structure

**Enopax** is the organisation that contains multiple projects. Each project has its own repository and can contain multiple sub-components.

### Project Structure

```
Enopax (Organisation)
├── Project 1: Platform
│   └── platform/ (Next.js production platform)
├── Project 2: ResourceAPI
│   ├── resource-api/ (API server + script framework)
│   └── resource-api-frontend/ (Vue.js API testing tool)
├── Project 3: GitProvider
│   └── provider-git/ (Git repository provisioning)
├── Project 4: AgentProvider
│   └── provider-agent/ (AI agent provisioning)
└── Project 5: Test
    └── web-test/ (Test repository for development)
```

---

## 📁 Project Details

### Project 1: Platform
**Purpose**: Full-featured production platform for infrastructure provisioning
**Repositories**: 1
**Status**: ✅ Production Ready

#### Repository: **Platform** (`/platform`)
**Type**: Next.js 15 + TypeScript Web Application
**Purpose**: Full-featured production platform for deploying and managing infrastructure services

**Key Features**:
- User authentication (NextAuth.js v5)
- Organisation, team, and project management
- Resource provisioning with templates
- File management and storage
- Role-based access control
- RESTful API for external integrations
- Real-time deployment progress tracking
- Comprehensive testing strategy (130+ tests)

**Tech Stack**:
- Next.js 15 with App Router
- TypeScript
- PostgreSQL + Prisma ORM
- Tailwind CSS + Radix UI
- Docker (PostgreSQL, Grafana, Prometheus)

**Deployment**:
- Development: `npm run docker:dev && npm run dev`
- Production: `./deploy.sh` (Git-pull workflow)

---

### Project 2: Resource API
**Purpose**: Script-based provider framework with testing tools
**Repositories**: 2
**Status**: ✅ Production Ready

#### 2.1 Repository: **Resource-API** (`/resource-api`)
**Type**: Express REST API with Bash Script Interface
**Purpose**: Bridge infrastructure to the Enopax platform using simple bash scripts

**Key Features**:
- Multi-provider architecture (one API, multiple providers)
- Script-based resource operations (provision, status, metrics, update, delete)
- JSON Schema-driven configuration
- Optional authentication with API keys
- Provider discovery endpoint
- Custom endpoint support with token authentication

**Tech Stack**:
- Node.js + Express
- Bash scripts for resource operations
- JSON for configuration and I/O

**Providers**:
- Example Provider (skeleton for learning)
- Git Repository Provider (full implementation)

**Deployment**:
- Development: `pnpm dev`
- Production: `pnpm start` (background)

#### 2.2 Repository: **Resource API Frontend** (`/resource-api-frontend`)
**Type**: Vue.js 3 Frontend-Only Application
**Purpose**: Testing and demonstration tool for Resource API integration

**Key Features**:
- Organisation → Project → Resource hierarchy
- Provider discovery and dynamic UI generation
- SSH key management
- Resource provisioning through Resource APIs
- Custom endpoint access with SSO
- No backend - localStorage-based persistence

**Tech Stack**:
- Vue 3.5 (Composition API)
- TypeScript
- Pinia (state management)
- Vue Router
- Tailwind CSS v4

**Deployment**:
- Development: `pnpm dev` (runs on localhost:5173)
- No backend server required

---

### Project 3: Git Provider
**Purpose**: Git repository provisioning and management
**Repositories**: 1
**Status**: ✅ Production Ready

#### Repository: **Provider-Git** (`/provider-git`)
**Type**: Provider Implementation
**Purpose**: Bare Git repository hosting with SSH access

**Key Features**:
- Bare Git repository creation
- SSH access configuration
- Organisation/project hierarchy
- Soft delete with 30-day retention
- Repository metrics (size, commits, branches)
- Integration with Resource-API

**Tech Stack**:
- Bash scripts (provider implementation)
- Git (repository management)
- SSH (secure access)
- File system (organised storage)

**Implementation**:
- Scripts located in `resource-api/scripts/git-repo/`
- Integrated with Resource API multi-provider architecture
- ID format: `orgslug-projectslug-reponame-random`

**Deployment**:
- Managed through Resource-API
- Storage location: `/data/repos/`
- SSH access: `git@git.enopax.io:org/project/repo.git`

**Repository**: https://github.com/enopax/provider-git

---

### Project 4: Agent Provider
**Purpose**: AI agent provisioning for automated infrastructure management
**Repositories**: 1
**Status**: 🚧 In Planning

#### Repository: **Provider-Agent** (`/provider-agent`)
**Type**: Provider Implementation
**Purpose**: Provision and manage AI agents for infrastructure automation

**Planned Features**:
- AI agent deployment
- Agent configuration management
- Integration with Claude, OpenAI, or other LLM providers
- Custom agent workflows
- Integration with Resource-API
- Intelligent resource management
- Automated infrastructure optimization

**Tech Stack**:
- TBD (likely Python or Node.js)
- LLM API integration (Claude, OpenAI)
- Docker for agent isolation
- Container orchestration

**Development Status**:
- ✅ Repository created
- ✅ Initial documentation (README.md, CLAUDE.md)
- 📋 Architecture design in progress
- 📋 Technology stack selection pending
- 📋 Resource API scripts to be implemented

**Repository**: https://github.com/enopax/provider-agent

---

### Project 5: Test
**Purpose**: Test repository for development and experimentation
**Repositories**: 1
**Status**: 🧪 Test Project

#### Repository: **Web-Test** (`/web-test`)
**Type**: Test Repository
**Purpose**: Development testing and experimentation

**Development Status**:
- ✅ Repository created
- 📋 Purpose to be defined

**Repository**: https://github.com/enopax/web-test

---

## <� System Architecture

```

                                                               
                   ENOPAX ECOSYSTEM                            
                                                               

                                                               
  
     Platform (Full)           Platform (Simple)        
     Next.js 15 + DB           Vue.js 3 (Frontend)      
                                                        
    " Authentication           " No Auth                
    " PostgreSQL               " localStorage           
    " Team Management          " Demo-Friendly          
    " File Storage             " Testing Tool           
    " RESTful APIs                                      
  
                                                           
             
                                                           
                    
                                                            
                     Resource API                           
                      Express +                             
                     Bash Scripts                           
                                                            
                     " Discovery                            
                     " Provision                            
                     " Status                               
                     " Metrics                              
                     " Update                               
                     " Delete                               
                    
                                                             
                    
                     Infrastructure                          
                                                             
                     " Git Repos                             
                     " IPFS Nodes                            
                     " Databases                             
                     " Containers                            
                     " VM/K8s                                
                    
                                                               

```

---

## = Data Flow

### Resource Provisioning Flow

1. **User Action**: User selects resource template in Platform/Resource API Frontend
2. **Request Formation**: Platform creates provision request with:
   - Resource name and configuration
   - SSH keys from project
   - Organisation and project identifiers
3. **API Call**: POST to Resource API endpoint (`/v1/{endpoint}`)
4. **Script Execution**: Resource API executes `provision.sh` with JSON input
5. **Infrastructure Creation**: Bash script provisions actual infrastructure
6. **Response**: Script returns resource ID, status, endpoint, credentials
7. **Status Tracking**: Platform polls status endpoint for progress
8. **Completion**: Resource becomes active, credentials displayed to user

### Authentication & Access Flow

**Platform (Full)**:
- NextAuth.js session-based authentication
- Role-based access control (organisation, team, project levels)
- API endpoints protected by session validation

**Resource API Frontend**:
- No authentication (frontend-only demo)
- All data in browser localStorage
- Not for production use

**Provider-API**:
- Optional API key authentication (X-API-Key header)
- Discovery endpoint (`/providers/info`) always public
- Configurable in `config.json`

---

## =� Resource Templates

Current templates available in **Platform**:

### IPFS Storage
- `ipfs-cluster-small` - 3-node cluster, 25GB storage, automatic replication
- `small-storage` - Single node, 5GB storage
- `medium-storage` - Single node, 25GB storage
- `large-storage` - Single node, 100GB storage

### Databases
- `postgres-small` - 2 vCPUs, 4GB RAM, 10GB storage, daily backups
- `postgres-medium` - 4 vCPUs, 16GB RAM, 50GB storage, read replica

### Git Repositories
- Implemented in Resource-API (Git provider)
- Bare Git repositories with SSH access
- Automatic organisation/project hierarchy

---

## = Security Model

### Platform (Full)
- **Authentication**: NextAuth.js with multiple providers
- **Authorisation**: Role-based access control
- **Data Protection**: PostgreSQL with Prisma ORM
- **API Security**: Session-based API protection
- **Secrets**: Environment variables, never logged or exposed

### Resource API Frontend
- **Authentication**: None (by design)
- **Data Storage**: Browser localStorage only
- **Deployment**: Trusted environments only
- **Purpose**: Development and demos

### Provider-API
- **Authentication**: Optional API key (X-API-Key header)
- **Authorisation**: Organisation/project scoping in requests
- **List Security**: Requires both org and project parameters
- **Secrets**: Never logged, only in JSON output
- **Validation**: Input validation in bash scripts

---

## =� Development Workflows

### Platform Development

```bash
# Start development environment
cd /Users/felix/work/IIIII/platform
npm run docker:dev              # Start PostgreSQL
npm run dev                     # Start Next.js

# Run tests
npm test                        # All tests
npm run test:watch              # Watch mode
npm run test:coverage           # Coverage report

# Production deployment
./deploy.sh                     # Git-pull + rebuild + migrate
```

### Resource API Frontend Development

```bash
# Start development
cd /Users/felix/work/IIIII/resource-api-frontend
pnpm install
pnpm dev                        # Runs on localhost:5173

# Type checking
pnpm type-check

# Build for production
pnpm build
pnpm preview
```

### Provider-API Development

```bash
# Start development
cd /Users/felix/work/IIIII/resource-api
pnpm install
pnpm dev                        # Runs on localhost:3001

# Background mode
pnpm start
pnpm stop

# Test scripts manually
echo '{"name":"test"}' | bash scripts/example/provision.sh

# Test API
curl http://localhost:3001/providers/info
```

---

## <
 Target Markets

### Primary Audiences
- **Digital Service Providers** - Businesses needing reliable, decentralised storage
- **Independent Journalists** - Professionals requiring censorship-resistant data storage
- **Gaming Asset Creators** - Developers storing game assets and NFTs

### Competitive Advantages
- **European Infrastructure** - GDPR-compliant, EU-based servers
- **Free Storage Tier** - Complimentary storage with GitHub integration
- **Flexible Payments** - PayPal, Stripe, cryptocurrency options
- **Intuitive Interface** - Drag-and-drop file management
- **Developer-Friendly** - API, CLI, cURL support

---

## =� Business Model

### Pricing Options

**Monthly Subscription**:
- PayPal integration
- Stripe credit card processing
- Cryptocurrency payments (Coinbase)

**Pay-Per-Use**:
- Token system: 5000 tokens = 5000MB monthly storage
- 1-month grace period before unpinning
- Flexible scaling based on usage

### Platform Features
- **Visual Cluster Builder** - Point-and-click configuration
- **Database Creation** - Railway-style provisioning interface
- **API Access** - Token-based authentication
- **CLI Tools** - Command-line file management
- **Context Menu Integration** - Native OS integration

---

## =� Documentation Structure

Each repository follows a structured documentation approach:

### Platform (`/platform`)
- `README.md` - Quick start and overview
- `CLAUDE.md` - AI assistant guidance
- `ARCHITECTURE.md` - Technical architecture
- `SPECS.md` - Application specifications
- `COMPONENTS.md` - Component structure
- `BEST-PRACTICES.md` - Development guidelines
- `JEST-TESTS.md` - Testing documentation
- `DEPLOYMENT.md` - Production deployment
- `BUSINESS-STRATEGY.md` - Market positioning

### Resource API Frontend (`/resource-api-frontend`)
- `README.md` - User documentation
- `CLAUDE.md` - AI assistant guidance
- `docs/concept.md` - Core concepts
- `docs/architecture.md` - Technical architecture
- `docs/local-setup.md` - Local development

### Resource-API (`/resource-api`)
- `README.md` - API documentation
- `CLAUDE.md` - AI assistant guidance
- `docs/architecture.md` - System design
- `docs/concept.md` - Design philosophy
- `docs/authentication.md` - Auth guide
- `docs/testing.md` - Testing strategies

---

## =' Technology Stack Summary

### Frontend
- **Platform**: Next.js 15, React, TypeScript, Tailwind CSS, Radix UI
- **Resource API Frontend**: Vue.js 3, TypeScript, Pinia, Tailwind CSS v4

### Backend
- **Platform**: Next.js App Router (Server Actions + API Routes)
- **Resource-API**: Node.js, Express

### Database
- **Platform**: PostgreSQL + Prisma ORM
- **Resource API Frontend**: Browser localStorage

### Infrastructure
- **Platform**: Docker (PostgreSQL, Grafana, Prometheus)
- **Resource-API**: Bash scripts for resource operations

### Testing
- **Platform**: Jest (130+ tests), multi-environment configuration
- **Resource-API**: Manual script testing, API endpoint testing

---

## <� Development Principles

### Code Quality
1. **Type Safety**: Full TypeScript coverage
2. **Testing**: Comprehensive test coverage (Platform)
3. **Documentation**: Structured documentation in all repos
4. **Code Standards**: Consistent patterns and conventions
5. **Security**: Never expose secrets, proper validation

### Development Workflow
1. **Branching**: Feature branches for all changes
2. **Commits**: Semantic commit messages
3. **Pull Requests**: Required for all changes
4. **Code Review**: Before merging to main
5. **Testing**: Tests must pass before merging

### Best Practices
- **British English**: Consistent spelling (organisation, colour, etc.)
- **No Direct Main Pushes**: Always use PRs
- **Semantic PRs**: Follow semantic PR specifications
- **Task-Based PRs**: Each task/feature has its own PR
- **Include Tests**: Tests and docs with each feature

---

## = Integration Points

### Platform � Resource-API
**Discovery**:
- Platform calls `/providers/info` to discover available providers
- Dynamic UI generation based on JSON schemas

**Provisioning**:
- Platform sends provision request with flat structure
- Includes SSH keys, org/project identifiers
- Provider returns resource ID, endpoint, credentials

**Monitoring**:
- Platform polls `/v1/{endpoint}/:id` for status
- Real-time progress tracking during deployment

### Resource API Frontend � Resource-API
**Same endpoints as Platform**, but:
- No authentication required (configurable in Resource-API)
- Simpler request structure
- localStorage persistence instead of database

---

## =� Current Implementation Status

###  Completed
- Platform core functionality (auth, teams, projects, resources)
- Platform API endpoints (teams, projects, files)
- Resource provisioning wizard
- Mock deployment with progress tracking
- Resource API Frontend (full feature set)
- Resource-API (multi-provider architecture)
- Git repository provider (full implementation)
- Comprehensive testing (Platform)
- Production deployment workflow (Platform)

### =� In Progress
- Real infrastructure deployment (Docker phase)
- Additional resource providers
- Custom endpoint implementations
- Cloud provider integrations

### =� Planned
- Multi-server deployment orchestration
- Kubernetes/Docker Swarm integration
- AWS/DigitalOcean/Hetzner integrations
- Advanced monitoring and metrics
- Billing and subscription management
- Additional resource types (Redis, MongoDB, etc.)

---

## =� Support & Communication

### Development Team
- **Repository**: GitHub (platform in `/platform` folder)
- **Issues**: GitHub Issues for bug reports and feature requests
- **Documentation**: In-repo documentation for all systems

### User Support
- **Website**: See `BUSINESS-STRATEGY.md` for platform website
- **Support Email**: Listed in provider configs
- **Documentation**: User-facing docs in README files

---

## =� Roadmap

### Phase 1: Foundation (Completed)
-  Platform core development
-  Resource API Frontend for demos and testing
-  Provider-API architecture
-  Mock deployment system
-  Testing infrastructure

### Phase 2: Real Deployment (Current)
- =� Docker-based provisioning
- =� Additional providers (PostgreSQL, Redis)
- =� Custom endpoint implementations
- =� Enhanced monitoring

### Phase 3: Scale (Planned)
- Multi-server orchestration
- Cloud provider integrations
- Advanced networking features
- High availability configurations

### Phase 4: Production (Future)
- Billing system integration
- Payment processing (PayPal, Stripe, crypto)
- Production-grade security
- SLA monitoring and reporting

---

## =� Quick Reference

### Repository Locations
```
/Users/felix/work/IIIII/





```

### Development Ports
- **Platform**: localhost:3000
- **Resource API Frontend**: localhost:5173
- **Resource-API**: localhost:3001
- **PostgreSQL**: localhost:5432

### Common Commands
```bash
# Platform
cd platform && npm run docker:dev && npm run dev

# Resource API Frontend
cd resource-api-frontend && pnpm dev

# Resource-API
cd resource-api && pnpm dev
```

---

*This document provides a comprehensive overview of the Enopax ecosystem. For detailed technical information, consult individual repository documentation files.*
