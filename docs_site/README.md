# NDU Platform Docs Site

Static documentation site for Firebase Hosting.

## Local Preview

Open `docs_site/index.html` in a browser for a quick static preview, or serve the repository with any local static file server.

## Firebase Hosting

The root `firebase.json` is configured to publish this directory:

```bash
firebase use ndu-d3f60
firebase deploy --only hosting
```

## Scope Covered

- Platform overview and architecture
- UI page guide for major screens and screen clusters
- Route atlas and major product clusters
- Shared data model and Firestore persistence
- KAZ AI and secure proxy model
- Billing, subscriptions, and admin operations
- Integrations and deployment guidance
