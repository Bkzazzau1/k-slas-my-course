# Identity Trust Bootstrap

File:

lib/features/identity_trust/services/identity_trust_bootstrap.dart

## Purpose

IdentityTrustBootstrap is the clean startup registration service for the identity trust system.

It registers two services in GetX:

- IdentityTrustRepository
- FaceEmbeddingConnector

## Internals

It uses:

- IdentityTrustRepositorySelector
- FaceEmbeddingConnectorSelector

## Recommended startup call

Use IdentityTrustBootstrap.register during app startup after GetStorage is initialized.

## Compatibility

IdentityTrustDemoBootstrap still exists and now delegates to IdentityTrustBootstrap.

This means older local startup code will continue to work while the project gradually moves to the cleaner name.

## Current default

The default connector target is demo, so frontend testing remains safe.

For later production deployment, pass the proper connector target:

- mobile
- desktop
