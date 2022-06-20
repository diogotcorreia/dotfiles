#!/bin/zsh

# fix debian-based servers not having alacritty terminfo
alias ssh="TERM=xterm-256color ssh"
# don't use vim, use nvim instead
alias vim="nvim"
# use exa instead of ls
alias ls="exa --git"
# to use when i'm too lazy to write a makefile
alias gccist="gcc -ansi -pedantic -Wall -Wextra -Werror"
alias xopen="xdg-open"
# cool terminal weather website
alias weather="curl https://wttr.in"
# shutdown alias
alias sdnow="shutdown now"
# copy to clipboard using xorg
alias clip="xclip -sel clip"
# set my work's development environment
alias setenv-dsi='export JAVA_HOME="/usr/lib/jvm/java-8-openjdk" && export JAVA_OPTS="-server -Xms256m -Xmx1024m -XX:PermSize=384m" && export MAVEN_OPTS="$JAVA_OPTS -Dorg.apache.jasper.compiler.Parser.STRICT_QUOTE_ESCAPING=false"'

if (( $+commands[paru] )) {
  alias paupg='paru -Syu'
  alias paupd='paru -Sy'
  alias pain='paru -S'
  alias parem='paru -Rns'
}

