# gist-generator

Create gists from the command line.

To activate the executable `gist`:

```
pub global activate --source git https://github.com/kasperpeulen/gist-generator
```

`gist generate` will try to create gists from all directories in the project. Here is an example of how such a project may look:
https://github.com/kasperpeulen/dartpads

Only the directories that are "dartpadable" will be converted to gists. 
This means that the directory contains a `web` directory. And that files in this directory can only be named `index.html`, `main.dart` or `styles.css`.

```
$ gist generate --help
Generate gists from the current directory.

Usage: gist generate [directory]
-h, --help         Print this usage information.
-v, --verbose      Show extra information about why a directory is skipped.
-n, --dry-run      Show which directories would be converted to gists.
-t, --test-gist    Create anonymous test gist, instead of creating public gists.

Run "gist help" to see global options.
```