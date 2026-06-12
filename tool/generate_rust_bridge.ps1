$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $repoRoot

try {
  $codegen = Get-Command flutter_rust_bridge_codegen -ErrorAction SilentlyContinue
  if (-not $codegen) {
    throw "flutter_rust_bridge_codegen is not installed. Install it first, for example: cargo binstall flutter_rust_bridge_codegen --version 2.11.1 -y"
  }

  flutter_rust_bridge_codegen generate `
    --rust-root native/brain_core `
    --rust-input crate::api `
    --dart-output lib/rust `
    --dart-entrypoint-class-name BrainCoreApi `
    --no-deps-check `
    --no-auto-upgrade-dependency `
    --no-build-runner
}
finally {
  Pop-Location
}
