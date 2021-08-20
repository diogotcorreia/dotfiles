# Git

## Force all subdirectories to have custom settings

This could be used to have a work folder where the commit email
is different from the global one.

From [this StackOverflow answer](https://stackoverflow.com/questions/21307793/set-git-config-values-for-all-child-folders):

> First, create a new config file somewhere with the settings you want to take effect in the sub-folders - using the original question's folders, let's say it's at `~/topLevelFolder1/.gitconfig_include`
>
> In `~/.gitconfig`, add:
>
> ```git
> [includeIf "gitdir:~/toplevelFolder1/"]
>     path = ~/topLevelFolder1/.gitconfig_include
> ```
>
> Any subfolder of `~/topLevelFolder1` will now include the config in `~/toplevelFolder1/.gitconfig_include` - there isn't a need to manually change the `.git/config` in each subfolder's repo. (This doesn't override whatever's in the subfolder config - it just adds to it, as "include" implies.)
