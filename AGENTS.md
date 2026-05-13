# Repository Instructions

## Release Policy

- Public DisplayFit distribution builds must be Developer ID signed and Apple notarized.
- Do not publish or replace GitHub Release assets, Homebrew cask checksums, or public install documentation from a `--local` package.
- Use `NOTARYTOOL_PROFILE=displayfit-notary ./script/package_direct.sh` for release artifacts. The script must staple and validate notarization tickets for both `DisplayFit.app` and the DMG before a release is considered shippable.
- If notarization credentials are missing, stop the release and ask for the credentials to be stored with `xcrun notarytool store-credentials displayfit-notary`. Do not ship an unnotarized workaround.
