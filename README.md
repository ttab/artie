# artie

 * Creates release packages from node.js projects. The packages
   are self-contained executables.
 * Uploads packages as attached files to GitHub releases.
 * Downloads the latest package from GitHub and sets up permissions
   and symlinks.

## Usage

### `artie upload [-o <os>] [-a <arch>] [-n <node version>] [-t <token>]`

Packages the node.js project in the current directory as an executable
archive using [nar]. The archive layout can be
[configured in package.json][narcfg].

If the current commit also has a tag, the package is uploaded and
attached to the GitHub release with the same tag.

If we are *not* on a tag, we assume that this package is for
development purposes, and a new GitHub draft release is created using
the abbreviated commit object as the name.

### `artie download <owner> <repo> [-o <os>] [-a <arch>] [-p] [-t <token>]`

Queries GitHub for the latest package matching the supplied `os` and
`arch`, and downloads the package (if it doesn't already exist) to the
current directory. Creates a symlink with the same name as `<repo>`
pointing to the newly downloaded file.

If `-p` is specified, we will only download fully tagged production
releases. Otherwise, we will also consider draft releases.

Releases marked as `pre-release` will never be downloaded.

## Node.js version

The version of the embedded node.js executable is determined as follows:

 1. If the `-n` options is specified, we will use that.
 2. If `.nvmrc` exists in the project root, we will look for a node.js
    version there.
 3. Otherwise, fall back to the system default.

## Authentication

`artie` needs a personal access token to be able to work with
GitHub. It can be supplied either with the `-t <token>` option or by
setting the `GITHUB_OAUTH_TOKEN` environment variable.


[nar]:https://github.com/h2non/nar
[narcfg]:https://github.com/h2non/nar#configuration
