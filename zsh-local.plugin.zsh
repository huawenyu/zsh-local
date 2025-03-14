#!/usr/bin/env zsh
# vim: ft=zsh
# vim: set copyindent preserveindent et sts=0 sw=4 ts=4 :
#
# fix issue:
#    "perl: warning: Please check that your locale settings:"
#
# Global {{{1
# locale {{{2
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# The last path has highest priority, inserted in the front
the_insert_paths=( \
	"/snap/bin" \
	"/bin" \
	"/usr/bin" \
	"/usr/sbin" \
	"/usr/local/bin" \
	"/usr/local/sbin" \
	"/usr/.local/bin" \
	"$HOME/.cargo/bin" \
	"$HOME/perl5/bin" \
	"$HOME/.linuxbrew/bin" \
	"$HOME/.linuxbrew/sbin" \
	"/home/linuxbrew/.linuxbrew/bin" \
	"/home/linuxbrew/.linuxbrew/sbin" \
	"$HOME/.local/bin" \
	"$HOME/.atuin/bin" \
	"$HOME/bin" \
	"/opt/ActiveTcl-8.6/bin" \
	"$HOME/script/python" \
	"$HOME/script" \
	"$HOME/generator" \
	"$HOME/dotwiki/tool" \
)

# The first path has higher-priority, but the whole has low-priority then existed PATH
the_append_paths=( \
	"$GOPATH/bin" \
	"/usr/lib64/qt-3.3/bin" \
	"/usr/lib64/ccache" \
)

# Don't do this, will make tmux C-x=clear-screen not work.
# - can't resolve the urxvt/window-terminal C-L make the screen blinking,
# - alacritty/gnome-terminal/xfce-terminal have no such issue
## Check keybinding:  bindkey
## https://unix.stackexchange.com/questions/285208/how-to-remove-a-zsh-keybinding-if-i-dont-know-what-it-does
## default Ctrl-L clear-screen, which cause the terminal blinking when tmux bindto select-left-pane
## bindkey -r "^L"

# Plugin define functions and zsh-completion
# avoid duplicate append
if [[ $PMSPEC != *f* ]]; then
    tmp=( "${0:h}/functions" )
    case ":$FPATH:" in
      *:"$tmp":*)
        ;;
      *)
        fpath+=$tmp
    esac
fi

# auto load all functions
autoload -Uz "${0:h}/functions"/*(.:t)
autoload -Uz compinit; compinit

# avoid duplicate append
if [[ $PMSPEC != *b* ]]; then
    tmp=( "${0:h}/bingit" )
    case ":$PATH:" in
      *:"$tmp":*)
        ;;
      *)
        path+=$tmp
    esac
fi

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# By default 0.4 second delay after hit the <ESC>
export KEYTIMEOUT=0

# basic {{{2
# If  set,  the shell does not follow symbolic links when executing commands
#   such as cd that change the current working directory
set -P

SAVEHIST=10000 # Number of entries
HISTSIZE=10000
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTCONTROL=erasedups
HISTIGNORE="?:??:???:&:ls:[bf]g:exit:pwd:free*:ls*:man*:clear:[ \t]*:hisotry*"
setopt append_history       # Don't erase history
setopt extended_history     # Add additional data to history like timestamp
setopt inc_append_history   # Add immediately
unsetopt hist_find_no_dups    # Don't show duplicates in search
setopt hist_ignore_space    # Don't into history if have space pre-command.
setopt histignorespace
setopt no_hist_beep         # Don't beep
setopt share_history        # Share history between session/terminals

# color {{{2
#   Black        0;30     Dark Gray     1;30
#   Red          0;31     Light Red     1;31
#   Green        0;32     Light Green   1;32
#   Brown/Orange 0;33     Yellow        1;33
#   Blue         0;34     Light Blue    1;34
#   Purple       0;35     Light Purple  1;35
#   Cyan         0;36     Light Cyan    1;36
#   Light Gray   0;37     White         1;37
#And then use them like this in your script:
#
#    .---------- constant part!
#    vvvv vvvv-- the code from above
RED='\033[0;31m'
NC='\033[0m' # No Color

apath="$HOME/dotwiki/lib/python" && \
    [ -d "$apath" ]  && [[ ":$PYTHONPATH:" != *":$apath:"* ]] && \
    { export PYTHONPATH=".:$apath:$PYTHONPATH"; }
apath="$HOME/script/awk/awk-libs" && \
    [ -d "$apath" ]  && [[ ":$AWKPATH:" != *":$apath:"* ]] && \
    { export AWKPATH=".:$apath:$AWKPATH"; }
apath="$HOME/script/awk" && \
    [ -d "$apath" ]  && [[ ":$AWKPATH:" != *":$apath:"* ]] && \
    { export AWKPATH=".:$apath:$AWKPATH"; }
apath="$HOME/go" && \
    [ -d "$apath" ]  && [[ ":$GOPATH:" != *":$apath:"* ]] && \
    { export GOPATH=".:$apath:$GOPATH"; }
apath="/usr/lib/jvm/java-8-oracle" && \
    [ -d "$apath" ]  && [[ ":$JAVA_HOME:" != *":$apath:"* ]] && \
    { export JAVA_HOME=".:$apath:$JAVA_HOME"; }
apath="/usr/java/latest" && \
    [ -d "$apath" ]  && [[ ":$JAVA_HOME:" != *":$apath:"* ]] && \
    { export JAVA_HOME=".:$apath:$JAVA_HOME"; }

## debug neovim python plugin:
#export NVIM_PYTHON_LOG_FILE=/tmp/log
#export NVIM_PYTHON_LOG_LEVEL=DEBUG
apath="$HOME/dotwiki/script/pretty-print" && \
    [ -d "$apath" ]  && [[ ":$JAVA_HOME:" != *":$apath:"* ]] && \
    { export GDB_PRETTY_PRINT=".:$apath:$GDB_PRETTY_PRINT"; }

# minicom line wrap: sudo -E minicom
export MINICOM="-w"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SSLKEYLOGFILE=~/sslkey.log

#export JEMALLOC_PATH=$HOME/project/jemalloc
#export MALLOC_CONF="prof:true,prof_prefix:jeprof.out"

# batcat: sudo apt install bat
export BAT_THEME="Monokai Extended"

# basic helper functions {{{2
#
# https://mrigank11.github.io/2018/03/zsh-auto-completion/

# Comtomize config {{{1
## Loading path {{{2}}}
for a_path in "${the_insert_paths[@]}"; do
	[ -d $a_path ] && {  insertpath $a_path;  }
done

for a_path in "${the_append_paths[@]}"; do
	[ -d $a_path ] && {  appendpath $a_path;  }
done

path-chk-dup
export PATH=${PATH}

## Loading customize local bashrc {{{2}}}
if [ -f "$HOME/.local/local" ]; then
    #echo "load local succ!"
    source $HOME/.local/local
else
    do-echo "Harmless! [$me] no local-env loaded from '$HOME/.local/local', silent by `touch $HOME/.local/local`!"
fi


# dev-var
export conf_fort=true
# Also should set ftpsvr/sftpsvr in /etc/hosts
export conf_use_sftp=true
chk-var $MYPATH_HEYTMUX || { export MYPATH_HEYTMUX="$HOME/script/heytmux"; }
chk-var $MYPATH_WORKREF || { export MYPATH_WORKREF="$HOME/workref"; }
chk-var $MYPATH_WORK    || { export MYPATH_WORK="$HOME/work"; }
chk-var $MYPATH_WIKI    || { export MYPATH_WIKI="$HOME/work-doc"; }

# Cheat:
# - Don't use the python version
# - Install download the bin from https://github.com/cheat/cheat/releases
if is-callable cheat; then
	export CHEAT_CONFIG_PATH="$HOME/.cheat.yml"
	# Using config to support multiple dirs
	#export DEFAULT_CHEAT_DIR=$HOME/dotwiki/cheat
	if is-callable fzf; then
		export CHEAT_USE_FZF=true
	fi
fi

# PS1 {{{2
#parse_git_branch() {
#     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}
#export PS1="\[\033[32m\]\W\[\033[31m\]\$(parse_git_branch)\[\033[00m\] $ "


# alias: pwd, dict, sharepatch {{{2
## Cause fail: cd $(pwd)
#alias pwd=" pwd | sed 's/^/ /g'"
#alias pwd=' pwd -L'

# https://stackoverflow.com/questions/12996397/command-not-found-when-using-sudo
alias mysudo='sudo -E env "PATH=$PATH"'

## pip3 install thefuck --user
#if command -v thefuck &> /dev/null; then
#	alias x=thefuck
#else
#	echo "Install theFuck: pip3 install --user thefuck"
#fi

is-callable eclipse && { alias eclipse="env SWT_GTK3=0 $HOME/tools/eclipse/eclipse &> /dev/null &"; }
is-callable xnview && { alias xnview="nohup $HOME/tools/XnView/XnView &> /dev/null &"; }
is-callable tmux && { alias tmuxkill="tmux ls | grep -v attached | cut -d: -f1 | xargs -r -I{} tmux kill-session -t {}"; }
#alias sharepatch="cp patch.diff ~/share/.; cp fgtcoveragebuild.tar.xz ~/share/.; cp ../doc/checklist.txt ~/share/."

# fake sudo vim ~/root/etc/hosts
#    ln -s /drives/c/Windows/System32/drivers/ ./root

# Use these lines to enable search by globs, e.g. gcc*foo.c
#bindkey "^R" history-incremental-pattern-search-backward
#bindkey "^S" history-incremental-pattern-search-forward

# function foreground-vi {{{2
# This will make C-z on the command line resume vi again, so you can toggle between them easily
foreground-vi() {
  fg %vi
}
zle -N foreground-vi
bindkey '^Z' foreground-vi

# # Try zman fc or zman HIST_IGNORE_SPACE! (Use n if the first match is not what you were looking for.)
# zman() {
#   PAGER="less -g -s '+/^       "$1"'" man zshall
# }

# cd -<TAB>                 use dirs to display the dirstack,
# zmv '(*).lis' '$1.txt'    dry-run mode -n

unsetopt correct_all
unsetopt nomatch


#is-callable direnv && { eval "$(direnv hook zsh)"; }
is-callable rustc && { export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src/; }

# Setup env vars {{{1
#
# ENV-TERM {{{2
# Customize to your needs...
# Tmux recognize
export TERM=screen-256color
export EDITOR='vim'

export LIBVIRT_DEFAULT_URI="qemu:///system"
export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5";
export PERL_MB_OPT="--install_base $HOME/perl5";
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5";
export PERL5LIB="./lib:$HOME/perl5/lib:$PERL5LIB";
alias  perldoctest='perl -MTest::Doctest -e run'

[ -f  $HOME/.cargo/env ] && source $HOME/.cargo/env

# used develop {{{2
if $conf_fort ; then
    export USESUDO=$(which sudo)
    export FORTIPKG=$HOME/fortipkg
fi


## https://unix.stackexchange.com/questions/103898/how-to-start-tmux-with-attach-if-a-session-exists
##   Avoid nestted when `sudo -s` (which would dutifully load my .bashrc again and double nest),
## https://superuser.com/questions/48783/how-can-i-pass-an-environment-variable-through-an-ssh-command
##   Pass TMUX to remote to avoid ssh tmux-nested
##     ~/.ssh/config (locally)
##        SendEnv TMUX
##     /etc/ssh/sshd_config (on the remote end)
##        AcceptEnv TMUX
#if [ -z "$TMUX" ] && [ ${UID} != 0 ]; then
#    tmux new-session -A -s default
#fi

# Disable warning messsage:
#   WARNING: gnome-keyring:: couldn't connect to: /run/user/1000/keyring-s99rSr/pkcs11: Connection refused
unset GNOME_KEYRING_CONTROL

# fzf {{{2
if ! is-callable fzf; then
	if [ -f "$HOME/.fzf/bin/fzf" ]; then
		mkdir -p "$HOME/bin"
		ln -s "$HOME/.fzf/bin/fzf" "$HOME/bin/fzf"
	fi
fi

if command -v fzf &> /dev/null; then
	# https://github.com/junegunn/fzf/issues/1625
	#   fzf acts like an interactive filter. Default search program is find, but can be changed via FZF_DEFAULT_COMMAND
	if command -v rg &> /dev/null; then
		export FZF_DEFAULT_COMMAND='rg --files --hidden --follow'
		# To apply the command to CTRL-T as well: avoid cd **<TAB>, vi **<TAB> fail
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	fi

	# fzf: global config {{{3
	_FZF_OPT='--header "Copy:C-y Toggle:C-/ Select:<tab> C-np|A-np"'
	_FZF_OPT+=' --multi'
	_FZF_OPT+=' --reverse'
	_FZF_OPT+=' --bind=ctrl-q:select-all,ctrl-p:up,ctrl-n:down,alt-p:preview-up,alt-n:preview-down'
	_FZF_OPT+=' --bind="ctrl-y:execute-silent(readlink -f {} | xclip)+abort"'
	_FZF_OPT+=' --bind "ctrl-alt-y:execute-silent(xclip {})+abort"'
	_FZF_OPT+=' --bind "ctrl-/:toggle-preview"'

	if command -v batcat &> /dev/null; then
	    _FZF_OPT+=' --preview "batcat --color=always --style=numbers,header --line-range :500 {} 2> /dev/null"'
	else
	    _FZF_OPT+=' --preview "cat --style=numbers --color=always --line-range :500 {} 2> /dev/null"'
	fi

	_FZF_OPT+=' --ansi '
	_FZF_OPT+=' --preview-window "wrap"'
	_FZF_OPT+=' --color fg:-1,bg:-1,hl:178,fg+:3,bg+:233,hl+:220'
	_FZF_OPT+=' --color info:150,prompt:110,spinner:150,pointer:167,marker:174'

	export FZF_DEFAULT_OPTS="${_FZF_OPT}"
	export FZF_CTRL_R_OPTS=" --preview-window 'up:3:hidden:wrap'    ${_FZF_OPT}"
    export FZF_CTRL_T_OPTS=" --preview-window 'down:3:nohidden:wrap' ${_FZF_OPT}"
    export FZF_ALT_C_OPTS="  --preview 'tree -C {}'    ${_FZF_OPT}"

	# see zplugin-init.zsh with Turbo Mode
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# Vi keybinding
#bindkey -v

# if command -v vim &> /dev/null; then
#   export MANPAGER="vim -c 'set wrap' -c MANPAGER -"
#   export MANWIDTH=999
# fi

# Don't use nvimpager:
# - can't support tmux-vim-jump
# - can't support git log color
## Install:
##   sudo apt-get install pandoc
##   git clone https://github.com/lucc/nvimpager.git
##   cd nvimpager && make PREFIX=$HOME/.local install
##export MANPAGER=nvimpager


# tmux-zsh-environment.plugin
# https://github.com/MikeDacre/tmux-zsh-environment/blob/master/tmux-zsh-environment.plugin.zsh
#
#   git clone https://github.com/MikeDacre/tmux-zsh-environment.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/tmux-zsh-environment
#       Share environmental variables more seamlessly between tmux and ZSH
#       https://github.com/MikeDacre/tmux-zsh-environment
#       Usage:
#          Publish a var: $ tmux set-env name2 wilson2
#          Check at another shell (<enter> to tigger hook-cmd): $ echo $name2
#######################################################################
#                    Tmux ZSH Environment Sharing                     #
#######################################################################
# Don't run if @delphij's version is running
[[ -n "$ZSH_TMUX_AUTOREFRESH" ]] || ZSH_TMUX_AUTOREFRESH=false

if "$ZSH_TMUX_AUTOREFRESH"; then
    return
fi

# Control running with TMUX_ZSH_SYNC
[[ -n "$TMUX_ZSH_SYNC" ]] || TMUX_ZSH_SYNC=true

if ! "$TMUX_ZSH_SYNC"; then
    return
fi

# Do nothing at all if we are not in tmux, second test is needed in
# case of an ssh session being run from within tmux, which could result
# in $TMUX from the parent session being set without tmux being
# connected.
if [ -n "$TMUX" ] && tmux ls >/dev/null 2>/dev/null; then
    # Update shell environment from variables, don't unset
    _tmux_zsh_env__preexec() {
        eval "$(tmux show-environment -s | grep -v "^unset")"
    }

    # Add the function as a precmd, to be run at every new prompt
    autoload -Uz add-zsh-hook
    #add-zsh-hook precmd _zsh_title__preexec
    add-zsh-hook precmd _tmux_zsh_env__preexec
fi
#######################################################################

export LFTP_ATCMD="lftp --norc -c 'open -u ftpuser,ftpuser 172.16.80.139; set ftp:ssl-allow off; set xfer:clobber on; set ssl:verify-certificate no;'"
