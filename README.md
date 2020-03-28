# git-utils

Modularized configuration and helper scripts around [git][git]¹ usage with multiple repositories and branches.

All these scripts are NOT speed optimized!
I'm using these scripts often in my daily work, and they do what they have to do.

## Requirements

* [git][git]¹

Most of these scripts are requires UNIX/Linux standard tools and commands like:

* [GNU core-utils][core-utils]⁵
* [GNU bash][bash]⁶

All scripts are daily used with `GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin17)` on macOS High Sierra and also tested with:

* `GNU bash, Version 4.4.12(3)-release (x86_64-unknown-cygwin)` on [_Cygwin_ 2.11.1][cygwin]
* `GNU bash, version 4.4.19(2)-release (x86_64-pc-msys)` on [_Git for Windows_ 2.18.0][git-bash]

Each script checks the required tools and exits with an error if a required tool is not available.
Please check the script documentation for additional and/or deviating requirements.

## Install and Usage

Clone this repository and add it to your `PATH` environment variable.

Most of these scripts has a _help_-option (`-h`, `-?`), a _quiet_-option (`-q`) and a multi-level _verbose_-option (`-vv...`).

The _usage_ information will be displayed if a script will execute without any arguments or with a help-option (`-h`, `-?`).

## Modularized git Configuration

Create or modify your global git configuration file in your home directory (`~/.gitconfig`) like the following one.
Replace `<PATH OF CLONED REPOSITORY>` with the path of this cloned git repository (e.g. `~/source/github.com/git-utils/`).

`~/.gitconfig`:
```gitconfig
[core]
	excludesfile = <PATH OF CLONED REPOSITORY>/gitignore.global
[include]
	path = <PATH OF CLONED REPOSITORY>/gitconfig_default
[include]
	path = <PATH OF CLONED REPOSITORY>/gitconfig_meld
[include]
	path = <PATH OF CLONED REPOSITORY>/gitconfig_aliases

; https://git-scm.com/docs/git-config#_conditional_includes
[includeIf "gitdir:~/sources/github.com/"]
	path = ~/sources/.gitconfig_github.com
```

The section `[includeIf "gitdir:~/sources/github.com/"]` includes additional settings based on the directory pattern where the git repository was cloned to.
These settings are only used for/in a specific git repository or environment (like directory).
This behavior based on [Conditional includes](git-conditional-includes) in [git](git).

E.g. `~/sources/.gitconfig_github.com`:

```gitconfig
[user]
	name = barthel
	email = barthel@users.noreply.github.com
```

## ShellCheck

[ShellCheck][shellcheck]³ is a static analysis tool for shell scripts and I'm use it to check my scripts and try to prevent pitfalls.
[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091] to validate these scripts correctly.

## License

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

## Links

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
