#!/bin/zsh

# fix debian-based servers not having alacritty terminfo
alias ssh="TERM=xterm-256color ssh"
# don't use vim, use nvim instead
alias vim="nvim"
# to use when i'm too lazy to write a makefile
alias gccist="gcc -ansi -pedantic -Wall -Wextra -Werror"
alias xopen="xdg-open"
# cool terminal weather website
alias weather="curl https://wttr.in"
# hacky fix to have maven 3.6.3
alias mvn-dsi="/opt/intellij-idea-ultimate-edition/plugins/maven/lib/maven3/bin/mvn"
