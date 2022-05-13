#!/bin/zsh

# Adds `~/.local/bin` to $PATH
export PATH="$PATH:${$(find -L ~/.local/bin -type d -printf %p:)%%:}"

export PATH="$PATH:$HOME/.dotfiles/suckless/dmenu/shortcuts"
export PATH="$PATH:$HOME/perl5/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# Default programs:
export EDITOR="nvim"
export TERMINAL="alacritty"
export BROWSER="brave"

# ~/ Clean-up:
export PERL5LIB="/home/dtc/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="/home/dtc/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"/home/dtc/perl5\""
export PERL_MM_OPT="INSTALL_BASE=/home/dtc/perl5"

# User program settings
export HASTEBIN_SERVER_URL="https://bin.diogotc.com" # Self-hosted hastebin server; don't abuse it
export HASTEBIN_CLIPPER="copyq copy -" # TODO change this to new clipboard manager
export R2D2_USERNAME=diogotcorreia # Internal Application
export JAVA_HOME="/usr/lib/jvm/java-18-openjdk"
export GPG_TTY=$(tty)

# Other program settings:
export _JAVA_AWT_WM_NONREPARENTING=1 # Fix for Java applications in dwm
