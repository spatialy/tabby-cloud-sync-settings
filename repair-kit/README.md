# Tabby FTP reconnect repair

Saved on 14 October 2026 for cloud-settings-sync 1.8.0 on Windows.

## What was fixed

After an FTP control-socket timeout, the plugin retains a closed client object.
Both sync entry points checked only whether that object existed, so later
attempts failed with `Client is closed`. The repair reconnects when the client
is absent **or closed**.

The source change is in `src/utils/cloud-components/FTP.ts`, in both
`sync()` and `syncLocalSettingsToCloud()`:

```diff
-if (!this.ftpClient) {
+if (!this.ftpClient || this.ftpClient.closed) {
```

The initial cause of the timeout was not diagnosed.

## Validation

The reporter applied both guard changes to the installed 1.8.0 bundle and
confirmed that provider Save and synchronization succeeded using FTPS with a
Hetzner Storage Box on Windows. No credentials, hostname, account identifiers,
or configuration contents are included here.

Automated tests and the packaged helper script could not be run in the
assistant's local execution environment. The helper applies the same two
changes as the successful manual repair, with an already-fixed check and
unique backup names.

## Reapply to an unpatched 1.8.0 installation

1. Close Tabby completely.
2. Download `repair-ftp-1.8.0.ps1` from this directory.
3. Open the file in a text editor and copy its contents into a local PowerShell window.
4. Reopen Tabby and test the FTPS provider, then Save.

The helper reads the normal Windows installation under
`%APPDATA%\tabby\plugins\node_modules\terminus-cloud-settings-sync`.
It stops for a different version or unexpected code, and does nothing when
both changes are already present. It creates a uniquely named
`index.js.before-ftp-fix-<id>.bak` beside `dist/index.js` before replacement.

The original manual repair used the fixed backup name
`index.js.before-ftp-fix.bak`; that existing backup is left untouched.

To undo a repair, close Tabby and copy the backup produced by that repair over
`dist/index.js`. A plugin update may replace the locally patched bundle.
This directory is preserved in the fork separately from the upstream PR.

Upstream pull request: https://github.com/niceit/tabby-cloud-sync-settings/pull/81
