# git-utils

Modularized configuration and helper scripts around [git][git]¹ usage with multiple repositories and branches.

All these scripts are NOT speed optimized!
I'm using these scripts often in my daily work, and they do what they have to do.

## 1. Requirements

* [git][git]¹

Most of these scripts are requires UNIX/Linux standard tools and commands like:

* [GNU core-utils][core-utils]⁵
* [GNU bash][bash]⁶

All scripts are daily used with `GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin17)` on macOS High Sierra and also tested with:

* `GNU bash, Version 4.4.12(3)-release (x86_64-unknown-cygwin)` on [_Cygwin_ 2.11.1][cygwin]
* `GNU bash, version 4.4.19(2)-release (x86_64-pc-msys)` on [_Git for Windows_ 2.18.0][git-bash]

Each script checks the required tools and exits with an error if a required tool is not available.
Please check the script documentation for additional and/or deviating requirements.

## 2. Install and Usage

Clone this repository and add it to your `PATH` environment variable.

Most of these scripts has a _help_-option (`-h`, `-?`), a _quiet_-option (`-q`) and a multi-level _verbose_-option (`-vv...`).

The _usage_ information will be displayed if a script will execute without any arguments or with a help-option (`-h`, `-?`).

## 3. [Modularized git Configuration](./doc/gitconfig.md "doc/gitconfig.md")

A modularized git configuration offers the possibility to work quickly and easily in various git repositories without manual changes. \
This behavior based on [Conditional includes](git-conditional-includes) in [git](git).

See [here](./doc/gitconfig.md "doc/gitconfig.md") for more information about.
## 4. ShellCheck

[ShellCheck][shellcheck]³ is a static analysis tool for shell scripts and I'm use it to check my scripts and try to prevent pitfalls.
[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091] to validate these scripts correctly.

## 5. License

All these scripts and configuration files are licensed under the [Apache License, Version 2.0][apl]⁴.
A copy of this license could be also found in the `LICENSE` file.

```bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## 6. Attic

The directory `_attic` is the place where the old and not supported scripts will be moved into it. These scripts are not maintained anymore.

## 7. Links

[//]: # "https://unicode-table.com/en/blocks/superscripts-and-subscripts - ¹ ² ³ ⁴ ⁵ ⁶ "

* ¹ [git][git]
* ³ [ShellCheck][shellcheck]
* ⁴ [Apache License, Version 2.0][apl]
* ⁵ [GNU core-utils][core-utils]
* ⁶ [GNU bash][bash]

[git]:https://git-scm.com/
[shellcheck]:https://www.shellcheck.net
[SC1091]:https://github.com/koalaman/shellcheck/wiki/SC1091
[apl]:http://www.apache.org/licenses/LICENSE-2.0
[core-utils]:https://www.gnu.org/software/coreutils/manual/coreutils.html
[bash]:https://www.gnu.org/software/bash/bash.html
[git-bash]:https://git-scm.com/download/win
[cygwin]:https://cygwin.com/install.html
