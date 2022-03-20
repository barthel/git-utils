# Modularized git Configuration

A modularized git configuration offers the possibility to work quickly and easily in various git repositories without manual changes. \
This behavior based on [Conditional includes](git-conditional-includes) in [git](git)¹.

## 1. Setup
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

## 2. `gitignore_global`

## 3. `gitconfig_default`

## 4. `gitconfig_meld`

## 5. `gitconfig_aliases`

## 6. Conditional includes

## 7. Links

[//]: # "https://unicode-table.com/en/blocks/superscripts-and-subscripts - ¹ ² ³ ⁴ ⁵ ⁶ "

* ¹ [git][git]

[git]:https://git-scm.com/
