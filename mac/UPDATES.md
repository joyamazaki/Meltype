# macOS: notify, then update on click

The IME uses Sparkle 2.10.0. The input menu offers 「更新を確認…」 and 「新しいバージョンを通知」. Scheduled checks default to once per day and may be disabled. Sparkle asks the user before downloading/installing; automatic installation and automatic background download are disabled. No profile data is sent.

Before relaunch, the active composition is committed. If no input client is available to accept it, installation remains pending. After relaunch the existing registration helper repairs input-source registration once, and restores Meltype only if it was selected before updating. This does not guarantee recovery from a runtime crash in a new release.

## Maintainer setup (required before public distribution)

1. Generate and securely back up a Sparkle Ed25519 signing seed using the official Sparkle tools. Keep the same key for subsequent releases. Do not share the private key with contributors. See https://sparkle-project.org/documentation/ . The workflow expects the base64 32-byte private seed, not a Keychain identifier or a 64-byte combined secret.
2. Add repository variable `MELTYPE_SPARKLE_PUBLIC_KEY` (base64 32-byte public key), and repository secret `MELTYPE_SPARKLE_PRIVATE_KEY` (base64 private seed). `tools/sparkle-public-key.swift <seed-file>` derives the matching public key without using the Keychain.
3. Configure the existing Developer ID signing and notarization secrets in `.github/workflows/mac.yml`. Test on a separate macOS account, with the IME installed in `~/Library/Input Methods` or `/Library/Input Methods`.
4. On stable `vX.Y.Z` tags, CI embeds the public key, signs a separate `Meltype-X.Y.Z-mac-update.zip`, verifies the signature, and publishes it with `appcast.xml`. The manual installer ZIP remains separate; Sparkle must receive a direct app archive, not the installer package. The feed points at the official repository's latest release asset. Do not mark a stable release as latest until all macOS assets are available.
5. The first updater-capable version must be installed manually. Later versions use the same bundle ID, installation location and signing key. Versions must increase numerically. Prerelease tags do not publish the stable feed.

Without a valid embedded public key, local builds show an explanation under 「更新を確認…」 and do not start network update checks. Do not put a test private key into release artifacts. The included local confirmation build deliberately has no production public key.

## Build compatibility

The default macos-15 CI image uses Swift 6.1. Pin swift-collections to 1.1.4 (tools version 5.7), which satisfies both the converter and Jinja constraints, rather than resolving 1.7.2 (requires tools version 6.4). Keep Package.resolved in sync. This dependency change does not enable production update delivery.

## Validation

- `swiftc mac/Sources/MeltypeIME/MacUpdatePolicy.swift tools/test-mac-updater.swift -o /tmp/test-updater && /tmp/test-updater`
- After resolving Swift packages: `python3 tools/test-mac-appcast.py` (ephemeral keys, real Sparkle sign/verify, no Keychain changes or publication).
- Existing native-boundary, Swift-boundary, event and installer tests still apply.

A real update between two signed/notarized releases, including composition preservation, source reselection, permission prompts and rollback on installer failure, still requires a separate-account end-to-end test before shipping. No automatic rollback after application startup is implemented.
