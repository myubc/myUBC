# Scripts

This folder contains project maintenance scripts that are not part of the app runtime.

## `prepare_open_source.sh`

Creates a sanitized export of the repository for public release.

Default output:

```bash
.open-source-export/myUBC
```

Usage:

```bash
./Scripts/prepare_open_source.sh
./Scripts/prepare_open_source.sh /path/to/export
```

Optional environment overrides:

```bash
APP_BUNDLE_ID=org.example.myubc
WIDGET_BUNDLE_ID=org.example.myubc.widgets
TESTS_BUNDLE_ID=org.example.myubcTests
UITESTS_BUNDLE_ID=org.example.myubcUITests
LOGGER_SUBSYSTEM=org.example.myubc
SANITY_CHECK_URL=https://example.com/myubc.json
```

What the script does:

- copies the repository into a fresh export directory
- excludes `.git`, Xcode user data, build output, and Finder metadata
- rewrites bundle identifiers to public-safe values
- removes `DEVELOPMENT_TEAM` from the Xcode project
- rewrites the sanity-check URL and logger subsystem
- rewrites first-party file headers from personal authorship to `Created by myUBC`

Recommended release flow:

1. Run the script.
2. Review the exported copy.
3. Initialize a new public repository from the exported directory.

The script is intended for publishing a sanitized copy, not for modifying the working tree in place.
