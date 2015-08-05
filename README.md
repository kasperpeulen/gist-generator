# gist-generator
Create gists from the command line.

`gist generate` will try to create gists from all directories in the project. Here is an example of how such a project may look:
https://github.com/kasperpeulen/dartpads

Only the directories that are "dartpadable" will be converted to gists. 
This means that the directory contains a `web` directory. And that files in this directory can only be named `index.html`, `main.dart` or `styles.css`.
