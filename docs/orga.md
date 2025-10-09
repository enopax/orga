# Enopax Organisation

## Overview

Enopax is building a modern infrastructure-as-a-service platform that makes cloud resource provisioning as simple as clicking a button. We enable users to deploy IPFS storage clusters, databases, and other services through an intuitive web interface with a focus on European infrastructure and GDPR compliance.

## Mission

Provide reliable, GDPR-compliant cloud infrastructure with an emphasis on:
- **Simplicity** - One-click deployment of complex services
- **European Infrastructure** - EU-based servers for data sovereignty
- **Flexibility** - Support for traditional and cryptocurrency payments
- **Decentralisation** - IPFS and distributed storage solutions

## Project Structure

The organisation uses a project structure where each project manages its own repositories:

- **Platform** - Full-featured production platform (Next.js 15 + TypeScript)
- **ResourceAPI** - Script-based provider framework with testing tools
- **GitProvider** - Git repository provisioning and management
- **AgentProvider** - AI agent provisioning for infrastructure automation
- **Test** - Test repository for development and experimentation

Projects are auto-discovered through convention: Each project has a `.repos` file to define which repositories should be cloned.

## Getting Started

```bash
# Clone the organisation repository
git clone git@github.com:enopax/orga.git enopax
cd enopax

# Run setup to discover projects and clone repositories
./setup.sh
```

For more details, see the main [README.md](../README.md).
