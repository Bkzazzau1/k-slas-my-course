# Face Embedding Connector Selector

File:

lib/features/identity_trust/services/face_embedding_connector_selector.dart

## Purpose

The selector chooses the correct local face embedding connector for the current runtime target.

## Selection rules

- Demo mode uses StaticFaceEmbeddingConnector.
- Production with mobile target uses TfliteFaceEmbeddingConnector.
- Production with desktop target uses OnnxFaceEmbeddingConnector.
- Explicit demo target always uses StaticFaceEmbeddingConnector.

## Runtime targets

- demo
- mobile
- desktop

## Bootstrap

IdentityTrustDemoBootstrap.register now accepts connectorTarget.

Default frontend testing should keep connectorTarget as demo.

Later production desktop can pass desktop.

Later production mobile or tablet can pass mobile.

## Warning

TFLite and ONNX connectors are scaffolds until real inference runtime packages are connected.
