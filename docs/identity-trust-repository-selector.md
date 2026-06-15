# Identity Trust Repository Selector

File:

```text
lib/features/identity_trust/services/identity_trust_repository_selector.dart
```

## Purpose

The selector chooses the correct identity trust repository for the current runtime mode.

## Selection rules

```text
Demo mode -> DemoIdentityTrustRepository
Production mode + API configured -> ApiIdentityTrustRepository
Production mode + API missing -> DemoIdentityTrustRepository fallback
```

## Runtime mode source

```text
LiveSessionRuntimeModeStore.load()
```

## Backend config source

```text
CourseCatalogBackendConfig.fromRuntime()
```

This uses the same API base URL and access token pattern already used by course catalog and student login services.

## Bootstrap behavior

`IdentityTrustDemoBootstrap.register()` now uses this selector when registering `IdentityTrustRepository`.

That means your local startup line remains the same:

```dart
IdentityTrustDemoBootstrap.register();
```

But the repository behind it can switch between demo and production automatically.
