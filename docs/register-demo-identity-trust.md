# Register Demo Identity Trust Services

The demo services are ready but must be registered during app startup.

## Files added

```text
lib/features/identity_trust/services/demo_identity_trust_repository.dart
lib/features/identity_trust/services/identity_trust_demo_bootstrap.dart
```

## Add this import in `lib/main.dart`

```dart
import 'features/identity_trust/services/identity_trust_demo_bootstrap.dart';
```

## Add this line before `runApp`

```dart
IdentityTrustDemoBootstrap.register();
```

## Target startup flow

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DistanceLearningMigrationService.run();
  IdentityTrustDemoBootstrap.register();
  runApp(const StudentAIApp());
}
```

## What it registers

```text
IdentityTrustRepository -> DemoIdentityTrustRepository
FaceEmbeddingConnector -> StaticFaceEmbeddingConnector
```

The demo repository creates a temporary active face profile for any logged-in student ID. This is only for the frontend demo while backend enrollment and real model inference are still pending.
