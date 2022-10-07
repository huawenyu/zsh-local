#!/bin/bash
#
# Global {{{1
# locale {{{2
# fix issue:
#    "perl: warning: Please check that your locale settings:"
# Howto profile zsh:
#    patch ~/.oh-my-zsh/oh-my-zsh.sh:
#		#Load all of the plugins that were defined in ~/.zshrc
#		for plugin ($plugins); do
#		  if [ ! -z ${zsh_timestamp+x} ]; then SECONDS=0; fi
#		      ....
#		  if [ ! -z ${zsh_timestamp+x} ]; then echo $SECONDS":" $plugin; fi
#		done
# Howto use shell-integrate fzf:
# https://www.freecodecamp.org/news/fzf-a-command-line-fuzzy-finder-missing-demo-a7de312403ff/
#   `**` sequence triggers fzf finder and it resembles * which is for native shell expansion.
#   cd **<TAB>
#   vi **<TAB>
#   Shortkey:
#     Ctrl-z+r    Search command history [Ctrl-R]
#     Atl-c       List/Change dir
#     Ctrl-t      Like the ** sequence
#     kill -9<TAB>
#
#
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

[ -d $HOME/dotwiki/lib/python ] && { export PYTHONPATH=".:$HOME/dotwiki/lib/python:$PYTHONPATH"; }
[ -d $HOME/script/awk/awk-libs ] && { export AWKPATH=".:$HOME/script/awk/awk-libs:$AWKPATH"; }
[ -d $HOME/script/awk ] && { export AWKPATH=".:$HOME/script/awk:$AWKPATH"; }
[ -d $HOME/go ] && { export GOPATH=$HOME/go; }
[ -d "/usr/lib/jvm/java-8-oracle" ] && { export JAVA_HOME="/usr/lib/jvm/java-8-oracle"; }
# export JAVA_HOME="/usr/java/latest"

## debug neovim python plugin:
#export NVIM_PYTHON_LOG_FILE=/tmp/log
#export NVIM_PYTHON_LOG_LEVEL=DEBUG
[ -d $HOME/dotwiki/script/pretty-print ] && { export GDB_PRETTY_PRINT=$HOME/dotwiki/script/pretty-print; }

# minicom line wrap: sudo -E minicom
export MINICOM="-w"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SSLKEYLOGFILE=~/sslkey.log

#export JEMALLOC_PATH=$HOME/project/jemalloc
#export MALLOC_CONF="prof:true,prof_prefix:jeprof.out"

# batcat: sudo apt install bat
export BAT_THEME="Monokai Extended"

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
	"$HOME/bin" \
	"/opt/ActiveTcl-8.6/bin" \
	"$HOME/script/git-scripts" \
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

# local define zsh-completion
fpath+="${0:h}/src"

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

# basic helper functions {{{2
#
# https://mrigank11.github.io/2018/03/zsh-auto-completion/
# function Usage {{{3
function _Usage()
{
# @Note:
#    indent tabs (i.e., '\t') will be stripped out,
#     indent with spaces will be left in.
#     ${FUNCNAME[0]} not show current function name, but $0 works
USAGE=$(cat <<-END
	  dryrun: dryrun=1 _do_cmd ls -lart
	      tshare add user1
	      tshare del user1
	      ssh user1@work -t 'tmux -S /tmp/tmux_share attach -t share'
	  tlayout: new | list | set | clone
END
)

    echo "${USAGE}"

    fcmd="/tmp/my_tmp_cmd"
    rm -f $fcmd
    if test -n "$ZSH_VERSION"; then
        # ${(k)aliases} ${(k)functions}
        print -rl -- ${(k)aliases} | grep -v zsh | awk 'length($0)>3' | fzf | xargs -r -I{} echo '{}' > $fcmd
    elif test -n "$BASH_VERSION"; then
        # ${(k)aliases} ${(k)functions}
        declare -F | grep -v zsh | awk 'length($0)>3' | fzf | xargs -r -I{} echo '{}' > $fcmd
    fi

    if [ -f "$fcmd" ]; then
        source $fcmd
        rm -f $fcmd
    fi
    return 0
}
compdef _usage help
alias help='_Usage'


# function dry _do_cmd {{{3
# dryrun="" _do_cmd ls -lart
function _do_cmd()
{
    if [ -v "dryrun" ]; then
        echo "[dryrun]:	$*"
        return 0
    elif [ -v "verbose" ]; then
        echo "Executing $*"
        eval "$@"
    else
        eval "$@"
    fi
}

# https://stackoverflow.com/questions/62873982/linux-check-if-path-exists
# Append our default paths
# Usage: _path_append '/what_i_want_to_add'
function _path_append()
{
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

# Insert our default paths
# Usage: _path_insert '/what_i_want_to_insert'
function _path_insert()
{
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="$1:${PATH:+$PATH}"
    esac
}

function _path_chk_dup()
{
    OLD_IFS=$IFS
    IFS=:
    NEWPATH=
    unset EXISTS
    declare -A EXISTS
    for p in $PATH; do
        #if [ -d $p ] && [ -z ${EXISTS[$p]} ]; then
        # check dir exist cause error
        if [ -z ${EXISTS[$p]} ]; then
            NEWPATH=${NEWPATH:+$NEWPATH:}$p
            EXISTS[$p]=yes
        fi
    done
    IFS=$OLD_IFS
    PATH=$NEWPATH
}

# function _has_cmd {{{3
# Usage: if _has_cmd boxes; then echo "has boxes"; else echo "nopes"; fi
function _has_cmd()
{
    if [ ! -z ${1} ]; then
        if ! command -v $1 &> /dev/null; then
            # 1 = false
            return 1
        fi
        # 0 = true
        return 0
    fi
    # 1 = false
    return 1
}

# function _has_var {{{3
# Usage: if _has_var $var; then echo "has var"; else echo "nopes"; fi
function _has_var()
{
    if [ -z ${1+x} ]; then
        # 1 = false
        return 1
    fi
    # 0 = true
    return 0
}

# function _do_echo {{{3
# if [ -x boxes ]; then echo "exist"; else echo "not exist"; fi
function _do_echo()
{
    if _has_cmd boxes; then
        echo "$*" | boxes
    else
        echo "$*"
    fi
}

# function _is_num {{{3
# https://stackoverflow.com/questions/5431909/returning-a-boolean-from-a-bash-function
# Usage: if _is_num $1; then echo "is number"; else echo "nopes"; fi
function _is_num()
{
    if [ -n "$var" ] && [ "$var" -eq "$var" ] 2>/dev/null; then
        # 0 = true
        return 0
    fi
    # 1 = false
    return 1
}


# Comtomize config {{{1

## Loading path {{{2}}}
for a_path in "${the_insert_paths[@]}"; do
	[ -d $a_path ] && {  _path_insert $a_path;  }
done

for a_path in "${the_append_paths[@]}"; do
	[ -d $a_path ] && {  _path_append $a_path;  }
done

_path_chk_dup
export PATH=${PATH}

## Loading customize local bashrc {{{2}}}
if [ -f "$HOME/.local/local" ]; then
    #echo "load local succ!"
    source $HOME/.local/local
else
    _do_echo "Harmless! [$me] no local-env loaded from '$HOME/.local/local', silent by `touch $HOME/.local/local`!"
fi


# dev-var
conf_fort=true
# Also should set ftpsvr/sftpsvr in /etc/hosts
conf_use_sftp=false
_has_var $MYPATH_HEYTMUX || { export MYPATH_HEYTMUX="$HOME/script/heytmux"; }
_has_var $MYPATH_WORKREF || { export MYPATH_WORKREF="$HOME/workref"; }
_has_var $MYPATH_WORK    || { export MYPATH_WORK="$HOME/work"; }
_has_var $MYPATH_WIKI    || { export MYPATH_WIKI="$HOME/work-doc"; }

# Cheat:
# - Don't use the python version
# - Install download the bin from https://github.com/cheat/cheat/releases
if _has_cmd cheat; then
	export CHEAT_CONFIG_PATH="$HOME/.cheat.yml"
	# Using config to support multiple dirs
	#export DEFAULT_CHEAT_DIR=$HOME/dotwiki/cheat
	if _has_cmd fzf; then
		export CHEAT_USE_FZF=true
	fi
fi

# PS1 {{{2
#parse_git_branch() {
#     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}
#export PS1="\[\033[32m\]\W\[\033[31m\]\$(parse_git_branch)\[\033[00m\] $ "


# alias: pwd, dict, sharepatch {{{2
alias pwd=" pwd | sed 's/^/ /g'"
#alias pwd=' pwd -L'

# sudo apt install -y tldr
_has_cmd tldr && { alias m=tldr; }

## pip3 install thefuck --user
#if command -v thefuck &> /dev/null; then
#	alias x=thefuck
#else
#	echo "Install theFuck: pip3 install --user thefuck"
#fi

_has_cmd icdiff && { alias vimdiff="icdiff --line-numbers"; }
_has_cmd vimdiff || { alias vimdiff="nvim -d"; }

alias eclipse="env SWT_GTK3=0 $HOME/tools/eclipse/eclipse &> /dev/null &"
alias xnview="nohup $HOME/tools/XnView/XnView &> /dev/null &"

_has_cmd icdiff && { alias vimdiff="icdiff --line-numbers"; }
alias tmuxkill="tmux ls | grep -v attached | cut -d: -f1 | xargs -r -I{} tmux kill-session -t {}"

alias sharepatch="cp patch.diff ~/share/.; cp fgtcoveragebuild.tar.xz ~/share/.; cp ../doc/checklist.txt ~/share/."

# fake sudo vim ~/root/etc/hosts
#    ln -s /drives/c/Windows/System32/drivers/ ./root

# https://github.com/dooblem/bsync
# Suppose we can define the DIRs in `~/.local/local`
if [ -n ${MY_SYNC_LOCAL} ] && [ -n ${MY_SYNC_REMOTE} ]; then
	for i in {1}; do
		if _has_cmd rsync; then
			if _has_cmd bsync; then
				alias syncme="bsync -v -i ${MY_SYNC_LOCAL}  ${MY_SYNC_REMOTE}"
				break
			fi
			alias sync-push="rsync -avrz --progress ${MY_SYNC_LOCAL}  ${MY_SYNC_REMOTE}"
			alias sync-pull="rsync -avrz --progress ${MY_SYNC_REMOTE} ${MY_SYNC_LOCAL}"
		fi
	done
fi


# pair-programer: share terminal screen {{{2
# @param action=add|del username
function _task_share_screen()
{
USAGE=$(cat <<-END
	  server:
	      $0 add|del user1 ses_name
	      tshare add user1
	      tshare del user1
	  user1:
	      ssh user1@work -t 'tmux -S /tmp/tmux_share attach -t share'
END
)

    if [ -z ${1} ]; then
        echo "${USAGE}"
        return 1
    else
        action=${1}

        if [ ${action} == "add" ]; then
            # donothing
            :
        elif [ ${action} == "del" ]; then
            :
        else
            echo "${USAGE}"
            return 1
        fi
    fi

    if [ -z ${2} ]; then
        userName="guest"
    else
        userName=${2}
    fi

    if [ -z ${3} ]; then
        sesName="share"
    else
        sesName=${3}
    fi

    if [ ${action} == "add" ]; then
        if [ ! -f "/bin/rbash" ]; then
            _do_cmd sudo ln -s /bin/bash /bin/rbash
        fi
        _do_cmd cd /home
        _do_cmd sudo mkdir -p ${userName}
        _do_cmd sudo chmod 755 ${userName}

        _do_cmd sudo touch /home/$userName/share
        _do_cmd sudo chmod 777 /home/$userName/share
        echo "tmux -S /tmp/tmux_${sesName} attach -t ${sesName}" > /home/$userName/share

        #_do_cmd sudo useradd -s /bin/rbash -d /home/$userName -p $(openssl passwd -crypt $userName) $userName
        _do_cmd sudo useradd -d /home/$userName -p $(openssl passwd -crypt $userName) $userName

        # create the 'share' session but not attach it.
        _do_cmd tmux -S /tmp/tmux_${sesName} new -d -s ${sesName}
        _do_cmd sudo chmod 777 /tmp/tmux_${sesName}
        _do_cmd tmux -S /tmp/tmux_${sesName} attach -t ${sesName}
    elif [ ${action} == "del" ]; then
        #_do_cmd sudo userdel -r ${userName}
        _do_cmd tmux -S /tmp/tmux_${sesName} kill -t ${sesName}
        _do_cmd sudo killall -u ${userName}
        _do_cmd sudo deluser --remove-home -f ${userName}
        _do_cmd sudo rm -fr /tmp/tmux_${sesName}
    fi
};
alias tshare='_task_share_screen'

if _has_cmd autossh; then
    alias swork="autossh hyu@work -t 'tmux attach -t work || tmux new -s work'"
elif _has_cmd ssh; then
    alias swork="ssh hyu@work -t 'tmux attach -t work || tmux new -s work'"
fi

if _has_cmd mosh; then
	alias mwork="mosh hyu@work -- sh -c 'tmux attach -t work || tmux new -s work'"
	alias mwork2="mosh hyu@work2 -- sh -c 'tmux attach -t work || tmux new -s work'"
fi

# tmux layout manage {{{2
# We also can use `heytmux` to do this job, pls remember change the window's name
# The tmux `default` name:
#    Nested-tmux by another sock-name: tmux -L child -f ~/.tmux.conf.child
#    Kill them:                        tmux -L child kill-session
# @param mode[top|side] #bugnumber 'bug-summary'
function _tmux_layout_man()
{
#     ${FUNCNAME[0]} not show current function name, but $0 works
#	  $0 gen|cp|top|side,default=cp 0123456 "summary block traffic under proxy"
cmd="tlayout"
USAGE=$(cat <<-END
	  $cmd alias "$0"
	  Sample:
	    $cmd [default=list]
	    $cmd list	+=== list current layout, we can create by 'tlayout save'
	    $cmd del	+=== delete current tmux-window/project-directory
	    $cmd save|set [layout, 'default']
	    $cmd create	+=== apply the selected layout, [default]
	    $cmd create [nameLayout] [nameWindow] [bugNum]
END
)

    usage=0
    # @args:action
    if [ -z ${1} ]; then
        action='list'
        _do_echo "${USAGE}"
        USAGE=''
    else
        action=$1
        shift
    fi

    # @args:layout
    if [ ${action} == "list" ]; then
        _do_cmd cat /tmp/tmux.layout| cut -d "=" -f 1
        return 0
    elif [ ${action} == "del" ]; then
        nameWindow=$(tmux display-message -p '#W')
        _do_cmd rm -fr ${MYPATH_WORK}/${nameWindow}
        _do_cmd tmux kill-window -t "${nameWindow}"
        return 0
    elif [ ${action} == "save" ] || [ ${action} == "set" ]; then
        if [ -z ${1} ]; then
            layout='default'
        else
            layout=$1
            shift
        fi
    elif [ ${action} == "create" ]; then
        # @args: layout
        if [ -z ${1} ]; then
            _do_echo "${USAGE}"
            USAGE=''
            _do_echo "\t args: $0 create [${RED}nameLayout${NC}] [nameWindow] [bugNum]"
            layout='default'
        else
            layout=$1
            shift
        fi

        # @args: nameWindow
        if [ -z ${1} ]; then
            _do_echo "${USAGE}"
            USAGE=''
            _do_echo "\t args: $0 create $layout ${RED}nameWindow${NC} bugNum"
            nameWindow=$(tmux display-message -p '#W')
        else
            nameWindow=$1
            shift
        fi

        # @args: bugNum
        if [ -z ${1} ]; then
            _do_echo "${USAGE}"
            USAGE=''
            _do_echo "\t args: $0 create $layout $nameWindow [${RED}bugNum${NC}]"
            bugNum=0
        else
            bugNum=$1
            shift
        fi
    else
        # _do_echo "${USAGE}"
        return 1
    fi


    # do-task
    if [ ${action} == "save" ]; then
        _do_cmd tmux display-message -p "${layout}='#{window_layout}'" >> /tmp/tmux.layout
        _do_cmd tlayout list
        return 0
    elif [ ${action} == "set" ]; then
        # <nameLayout>='layoutString'
        source /tmp/tmux.layout

        eval layoutString='$'${layout}
        if [ ! -z ${layoutString+x} ]; then
            echo "Tmux-layout '${layout}': ${layoutString}"
            _do_cmd tmux select-layout "'${layoutString}'"
            return 0
        fi
    elif [ ${action} == "create" ]; then
        if _has_cmd heytmux; then
            : #
        else
            _do_echo "${USAGE}"
            USAGE=''
            _do_echo -e "According https://github.com/junegunn/heytmux \n Install: gem install heytmux" | boxes
            return 1
        fi

        # <nameLayout>='layoutString'
        source /tmp/tmux.layout

        { # try

            #command1 &&
            ##save your output

            eval layoutString='$'${layout}
            if [ ! -z ${layoutString+x} ]; then
                echo "Tmux-layout '${layout}': ${layoutString}"

                if [ -f "${MYPATH_HEYTMUX}/${layout}.yml" ]; then
                    #indexWindow=$(tmux display-message -p '#I')
                    mkdir -p ${MYPATH_HEYTMUX}/${nameWindow}
                    _do_cmd heyWindow=${nameWindow} heyBug=${bugNum} heytmux "${MYPATH_HEYTMUX}/${layout}.yml"
                    _do_cmd tmux select-layout -t   "'${nameWindow}'"   "'${layoutString}'"
                else
                    _do_echo "${USAGE}"
                    USAGE=''
                    echo "[$me] Please create heytmux layout file ${RED}'${layout}.yml'${NC} into '${MYPATH_HEYTMUX}'"
                    return 1
                fi
            fi
        } || { # catch
            # save log for exception
            _do_echo "${USAGE}"
            USAGE=''
            echo "[$me] Please create the layout ${RED}'${layout}'${NC} into /tmp/tmux.layout:"
            echo "$0 save ${layout}"
            return 1
        }

    elif [ ${layout} == "top" ]; then
        _do_cmd tmux kill-pane -a
        _do_cmd tmux split-window -v -p 80
        _do_cmd tmux split-window -h -p 70 -t 1
        _do_cmd tmux split-window -h -p 50
        _do_cmd tmux select-pane -t 4
        _do_cmd tmux send-keys "new-doc.sh" Space "${bugnumber}" Enter
        #_do_cmd tmux send-keys 'echo music' 'Enter'
        #_do_cmd tmux select-pane -t 2
    elif [ ${product} == "right" ]; then
        _do_cmd tmux kill-pane -a
        _do_cmd tmux split-window -v -p 80
        _do_cmd tmux split-window -h -p 70 -t 1
        _do_cmd tmux split-window -h -p 50
        #_do_cmd tmux send-keys 'echo key' 'Enter'
        #_do_cmd tmux send-keys 'echo music' 'Enter'
        #_do_cmd tmux select-pane -t 2
    else
        _do_echo "${USAGE}"
        USAGE=''
        echo "Support layouts: gen,cp; top,right"
    fi
    return 0
};
alias tlayout='_tmux_layout_man'


# Show current task's document {{{2
function _task_document()
{
USAGE=$(cat <<-END
	  $0  <null>      +--- list current project doc
	  $0  anystring   +--- list all doc
END
)
    nameWindow=$(tmux display-message -p '#W')
    projDir=$(find ${MYPATH_WORKREF}/doc -type d -name "*${nameWindow}")

    if [ ! -z ${projDir} ]; then
        tree -if --noreport $projDir \
            | fzf --keep-right --preview 'bat --color=always --style=numbers --line-range=:500 {} 2> /dev/null' --preview-window +{2}-/2 \
            | xargs -r -o $EDITOR
    else
        tree -if --noreport ${MYPATH_WORKREF}/doc \
            | fzf --keep-right --preview 'bat --color=always --style=numbers --line-range=:500 {}  2> /dev/null' --preview-window +{2}-/2 \
            | xargs -r -o $EDITOR
    fi
    echo $USAGE
};
alias tdoc='_task_document'


function _task_preview()
{
    unset fname
    unset fline
    IN=$1
    mails=$(echo $IN | tr ":" "\n")

    for addr in $mails; do
        if [ ! -v fname ]; then
            fname=$addr
        elif [ ! -v fline ]; then
            fline=$addr
        fi
    done

    # echo ${fname}
    # echo ${fline}
    # echo "done"

    sed -n "$fline,+20p" $fname
};
alias tpreview='_task_preview'


# Show current task's document {{{2
function _task_wiki()
{
USAGE=$(cat <<-END
	  $0 file  [text]  +--- list all files
	  $0 [subdir] [text]
END
)

    unset greptext
    argExtra=''
    grepdir=$MYPATH_WIKI

    # @args:subdir
    if [ -z ${1} ]; then
        greptext=' '
        _do_echo "${USAGE}"
    else
        subdir=$1
        if [ ${subdir} == "file" ]; then
            # list all file name only
            argExtra='l'
        else
            if [ -d "$MYPATH_WIKI/${subdir}" ]; then
                grepdir="$MYPATH_WIKI/${subdir}"
            else
                greptext=$1
            fi
        fi
        shift
    fi

    if [ ! -v "greptext" ]; then
        # @args:greptext
        if [ -z ${1} ]; then
            greptext=' '
        else
            greptext=$1
            shift
        fi
    fi


    # echo "length=${#greptext}"
    # echo "rg -n${argExtra}L " "'"${greptext}"'" "$grepdir"
    # _do_cmd rg -n${argExtra}L "'"${greptext}"'" $grepdir
    # rg -nlL ' ' /home/hyu/doc | wc -l
    # rg -n${argExtra}L "'"${greptext}"'" $grepdir > /tmp/tmp_filelist
    #

    if [ ! -v "dryrun" ]; then
        if [ ${greptext} == ' ' ]; then
            rg -n${argExtra}L ' ' $grepdir \
                | fzf --keep-right --preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=up:40% \
                | cut -d ':' -f 1,2 | xargs -r -o $EDITOR
        else
            rg -n${argExtra}L ${greptext} $grepdir \
                | fzf --keep-right --preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=up:40% \
                | cut -d ':' -f 1,2 | xargs -r -o $EDITOR
        fi
    else
        _do_cmd rg -n${argExtra}L "'"${greptext}"'" $grepdir
    fi
};
alias twiki='_task_wiki'


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

# Try zman fc or zman HIST_IGNORE_SPACE! (Use n if the first match is not what you were looking for.)
zman() {
  PAGER="less -g -s '+/^       "$1"'" man zshall
}

# cd -<TAB>                 use dirs to display the dirstack,
# zmv '(*).lis' '$1.txt'    dry-run mode -n

unsetopt correct_all
unsetopt nomatch

# function _mysmbget {{{2
# add user/pass to: ~/.smbclient.conf
# disable log in /etc/samba/smb.conf
#      syslog = 0
# @param model buildnum product
function _mysmbget()
{
USAGE=$(cat <<-END
	  $0 buildnum (fos6|fos701|fpx|ls) model
	  Sample:
	    smbget 1561 ls

	    smbget 1561 fos6 FGT_600E
	    smbget 0288 fpx  FPX_400E

	    smbget 1561 fos6 FGT_VM64_KVM
	    smbget 0288 fpx  FPX_VMWARE

	    smbget 0066 fos701 FGT_VM64
	    smbget 0066 v7.0.0 FGT_VM64
	  $0 [subdir] [text]
END
)
    unset buildnum
    unset product
    unset model

    # @args:buildnum
    if [ -z ${1} ]; then
        _do_echo $USAGE
        USAGE=''
        echo "no buildnum."
        return 1
    else
        buildnum=${1}
        shift
    fi

    # @args:product
    if [ -z ${1} ]; then
        _do_echo $USAGE
        USAGE=''
        echo "no product."
        return 1
    else
        product=${1}
        shift
    fi

    # @args:model
    if [ -z ${1} ]; then
        _do_echo $USAGE
        USAGE=''
        product='ls'
        echo "no model, change product to 'ls'"
    else
        model=${1}
        shift
    fi


    #get ${model}-v6-build${buildnum}-FORTINET.deb;
    #get ${model}-v6-build${buildnum}-FORTINET.out;
    #get ${model}-v6-build${buildnum}-FORTINET.deb.extra.tgz;
    #get ${model}-v6-build${buildnum}-FORTINET.out.extra.tgz;
    if [ ${product} = "fpx" ]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiProxy/v1.00/images/build${buildnum}; get ${model}-v100-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiProxy/v1.00/images/build${buildnum}; get ${model}-v100-build${buildnum}-FORTINET.out.extra.tgz;'"
    elif [ ${product} = "ls" ]; then
        #eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; ls *-FORTINET.deb;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; ls *-FORTINET.out.extra.tgz;'"
    elif [ ${product} = "fos6" ]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; get ${model}-v6-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c '\
            cd FortiOS/v6.00/images/build${buildnum}; \
            get ${model}-v6-build${buildnum}-FORTINET.deb.extra.tgz; \
            get ${model}-v6-build${buildnum}-FORTINET.out.extra.tgz; \
            '"
    elif [ ${product} = "fos7" ]; then
        # echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v7.00/images/build${buildnum}; get ${model}-v7.0.0-build${buildnum}-FORTINET.out.extra.tgz;'"
        # eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c '\
        #     cd FortiOS/v7.00/images/build${buildnum}; \
        #     get ${model}-v7.0.0-build${buildnum}-FORTINET.deb.extra.tgz; \
        #     get ${model}-v7.0.0-build${buildnum}-FORTINET.out.extra.tgz; \
        #     '"
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v7.00/images/build${buildnum}; get ${model}-v7-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c '\
            cd FortiOS/v7.00/images/build${buildnum}; \
            get ${model}-v7-build${buildnum}-FORTINET.deb.extra.tgz; \
            get ${model}-v7-build${buildnum}-FORTINET.out.extra.tgz; \
            '"
    elif [ ${product} = "fos701" ]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v7.00/images/build${buildnum}; get ${model}-v7.0.1-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c '\
            cd FortiOS/v7.00/images/build${buildnum}; \
            get ${model}-v7.0.1-build${buildnum}-FORTINET.deb.extra.tgz; \
            get ${model}-v7.0.1-build${buildnum}-FORTINET.out.extra.tgz; \
            '"
    elif [[ ${product} = v7* ]]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v7.00/images/build${buildnum}; get ${model}-${product}-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c '\
            cd FortiOS/v7.00/images/build${buildnum}; \
            get ${model}-${product}-build${buildnum}-FORTINET.deb.extra.tgz; \
            get ${model}-${product}-build${buildnum}-FORTINET.out.extra.tgz; \
            '"
    else
        _do_echo $USAGE
        USAGE=''
        return 1
    fi
};
alias smbget='_mysmbget'

# function _mysmbme {{{2
# config: ~/.smbclient.conf
function _mysmbme()
{
put_files=("patch.diff" \
  "patch.eco.diff" \
  "image.out" \
  "fgtcoveragebuild.tar.xz" \
  "fgtcoveragebuild.tar.bz2" \
  "checklist.txt" \
  "fortios.qcow2" \
  "fortiproxy.qcow2" \
  "image.out.vmware.zip" \
  "image.out.ovf.zip" \
  "image.out.hyperv.zip" \
  "image.out.gcp.tar.gz" \
  "image.out.kvm.zip" \
  "image.out.gcp.tar.gz" \
)

    if [ -z ${1} ]; then
        dname=${PWD##*/}
        echo "  Working dir '$dname'!"

        #eval "$LFTP_CMD 'cd $LFTP_DIR; rm -fr $dname; quit;'"
        #eval "smbclient //imagesvr/images -U 'fortinet-us/hyu' -c 'mkdir hyu; cd hyu; rmdir $dname; mkdir $dname; cd $dname; put image.out; q;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day -c 'mkdir hyu; q;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day -c 'cd hyu; rmdir $dname; q;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day -c 'cd hyu; mkdir $dname; q;'"

        for one_file in "${put_files[@]}"
        do
            if [ -f ${one_file} ]; then
                eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day -c 'cd hyu/$dname; put ${one_file}; q;'"
            fi
        done

        eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day -c 'cd hyu/$dname; pwd; ls; q;'"
    fi
};
alias smbme='_mysmbme'

# function _mysmblogin {{{2
# image: Swap-1Day
# devqa: DevQA/Image
function _mysmblogin()
{
    if [ -z ${1} ]; then
        dname=${PWD##*/}
        echo "self <server-type>  Working dir '$dname'!"

        eval "smbclient -A ~/.smbclient.conf //imagesvr/Swap-1Day"
    else
        duttype=${1}
        if [ "$duttype" = "image" ]; then
            svr="imagesvr"
            subpath1="/Swap-1Day"
        elif [ "$duttype" = "devqa" ]; then
            svr="devqasvr"
            subpath1="/DevQA"
        else
            echo "self <server> like 'image|devqa' Working dir '$dname'!"
        fi

        eval "smbclient -A ~/.smbclient.conf //$svr$subpath1"
    fi
};
alias smblogin='_mysmblogin'


# function _mytail {{{2
function _mytail()
{
  if [ -t 0 ]; then
    \tail "$@" 2> >(grep -v truncated >&2)
  else
    \tail "$@" 2> >(grep -v truncated >&2)
  fi
};
alias tail='_mytail'


# function prepare ftp {{{2
function _my_pre_ftp()
{
    #if ! _has_var $LFTP_CMD; then
        if $conf_fort ; then
            if $conf_use_sftp ; then
                ftpAddr=$(getent hosts sftpsvr | awk '{ print $1 }')
                echo "### @Note the ftpsvr is ${ftpAddr} ###"
                #
                # sftpserver
                # sshpass -p ${MY_SSH_PASSWORD0} sftp -oBatchMode=no -b YOUR_COMMAND_FILE_PATH USER@HOST
                # lftp sftp://admin:password123@serial.local
                export LFTP_CMD="lftp sftp://hyu:${MY_SSH_PASSWORD0}@${ftpAddr} -e "
                export LFTP_DIR=$USER
            else
                ftpAddr=$(getent hosts ftpsvr | awk '{ print $1 }')
                echo "### @Note the ftpsvr is ${ftpAddr} ###"
                #
                # ftpserver
                export LFTP_CMD="lftp -u test,test ${ftpAddr} -e "
                export LFTP_DIR=upload/$USER
            fi
        fi
    #fi
};


# function _myftpls {{{2
function _myftpls()
{
    _my_pre_ftp
    eval "$LFTP_CMD 'cd $LFTP_DIR; ls; quit;'"
};
alias ftpls='_myftpls'


# function _myftpget {{{2
function _myftpget()
{
    if [ -z ${1} ]; then
        dname=${PWD##*/}
    else
        dname=${1}
    fi

    _my_pre_ftp
    for var in "$@"
    do
        eval "$LFTP_CMD 'cd $LFTP_DIR; get $var; quit;'"
    done
};
alias ftpget='_myftpget'


# function _myftpmirror {{{2
function _myftpmirror()
{
  if [ -z ${1} ]; then
    echo "  Please give a mirror dir name!"
  else
    dname=${1}
    echo "  Mirror '$dname'!"
    _my_pre_ftp
    eval "$LFTP_CMD 'cd $LFTP_DIR; mirror $dname; quit;'"
  fi
};
alias ftpmirror='_myftpmirror'


# function _myftpput {{{2
function _myftpput()
{
    if [ -z ${1} ]; then
        dname=${PWD##*/}
    else
        dname=${1}
    fi

    _my_pre_ftp
    for var in "$@"
    do
        eval "$LFTP_CMD 'cd $LFTP_DIR; put $var; quit;'"
    done
};
alias ftpput='_myftpput'


# function _myftprm {{{2
function _myftprm()
{
    _my_pre_ftp
    if [ -z ${1} ]; then
        dname=${PWD##*/}
        echo "  Removing '$dname'!"
        eval "$LFTP_CMD 'cd $LFTP_DIR; rm -fr $dname; quit;'"
    else
        for var in "$@"
        do
            echo "  Removing '$var'!"
            eval "$LFTP_CMD 'cd $LFTP_DIR; rm -fr $var; quit;'"
        done
    fi

    eval "$LFTP_CMD 'cd $LFTP_DIR; ls; quit;'"
};
alias ftprm='_myftprm'


# function _myftp {{{2
function _myftp()
{
    if [ -z ${1} ]; then
        dname=${PWD##*/}
    else
        dname=${1}
    fi

    _my_pre_ftp
    if [ -f image.out ]; then
        file=image.out
        eval "$LFTP_CMD 'cd $LFTP_DIR; ls; mkdir $dname; cd $dname; put $file; put patch.diff; put patch.eco.diff; put fgtcoveragebuild.tar.xz; put fgtcoveragebuild.tar.bz2; put checklist.txt; put fortios.qcow2; put fortiproxy.qcow2; put image.out.vmware.zip; put image.out.ovf.zip; put image.out.hyperv.zip; put image.out.gcp.tar.gz;put image.out.kvm.zip; put image.out.gcp.tar.gz;lpwd; pwd; ls; quit;'"
    else
        if [ -z "$1" ]; then
            echo "File $1 not found!"
            return 1
        else
            file=$1
            eval "$LFTP_CMD 'cd $LFTP_DIR; mkdir $dname; cd $dname; put $file; ls; quit;'"
        fi
    fi
};
alias ftpme='_myftp'

if _has_cmd bear; then
	# function _bear {{{2
	# used to generate the c/c++ ccls indexer db: ccls clang makefile
	function _bear()
	{
		if [ -f compile_commands.json ]; then
			;
		else
			if [ -z ${branch+x} ]; then
				branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
			fi
			cp ~/workref/compile_commands.json-${branch} compile_commands.json || { echo 'The file ~/workref/compile_commands.json-${branch} not exist!' ; exit 1; }
		fi
		sample_dir=$(awk 'match($0, /-I(.*)\/daemon\/wad\//, arr) {print arr[1]; exit}' compile_commands.json)
		#echo $sample_dir
		cur_dir=$(realpath .)
		#sed -i "s;$sample_dir;$cur_dir;g" compile_commands.json
		_do_cmd "sed -i 's;$sample_dir;$cur_dir;g' compile_commands.json"
	};
	alias bearme='_bear'

	# Wrap make(gcc) to generate compile_commands.json used by clangd-language-server
	#   sudo apt-get install -y clangd bear
	if [ -f '/usr/lib/x86_64-linux-gnu/bear/libear.so' ]; then
		alias Bear='bear -l /usr/lib/x86_64-linux-gnu/bear/libear.so '
	elif [ -f '/usr/local/lib/x86_64-linux-gnu/bear/libexec.so' ]; then
		alias Bear='bear -l /usr/lib/x86_64-linux-gnu/bear/libear.so -- '
	fi
fi


if _has_cmd clang; then
	alias myclang='clang -fms-extensions -Wno-microsoft-anon-tag '
fi


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

# Python virtual env
	# Silent direnv, thefuck
	if _has_cmd direnv; then
		eval "$(direnv hook zsh)"
	fi

	# export PYENV_ROOT="${HOME}/.pyenv"
	# if [ -d "${PYENV_ROOT}" ]; then
	#   export PATH="${PYENV_ROOT}/bin:${PATH}"
	#   eval "$(pyenv init -)"
	# fi


#if [ -d "$HOME/..fzf_browser" ]; then
#  export PATH=${PATH}:~/.fzf_browser
#fi


# used develop {{{2
if $conf_fort ; then
    export USESUDO=$(which sudo)
    export FORTIPKG=$HOME/fortipkg
fi

# lang-Rust {{{2
if hash rustc 2>/dev/null; then
    export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src/
fi

# Disable warning messsage:
#   WARNING: gnome-keyring:: couldn't connect to: /run/user/1000/keyring-s99rSr/pkcs11: Connection refused
unset GNOME_KEYRING_CONTROL

# fzf {{{2
if ! _has_cmd fzf; then
	if [ -f "$HOME/.fzf/bin/fzf" ]; then
		mkdir -p "$HOME/bin"
		ln -s "$HOME/.fzf/bin/fzf" "$HOME/bin/fzf"
	fi
fi

if _has_cmd fzf; then
	# https://github.com/junegunn/fzf/issues/1625
	#   fzf acts like an interactive filter. Default search program is find, but can be changed via FZF_DEFAULT_COMMAND
	if _has_cmd rg; then
		export FZF_DEFAULT_COMMAND='rg --files --hidden --follow'
		# To apply the command to CTRL-T as well: avoid cd **<TAB>, vi **<TAB> fail
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	fi

	# fzf: global config {{{3
	export FZF_DEFAULT_OPTS="
	--bind=ctrl-q:select-all,ctrl-p:up,ctrl-n:down,alt-p:preview-up,alt-n:preview-down
	--color fg:-1,bg:-1,hl:178,fg+:3,bg+:233,hl+:220
	--color info:150,prompt:110,spinner:150,pointer:167,marker:174
	"

	# see zplugin-init.zsh with Turbo Mode
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# Vi keybinding
#bindkey -v

# manpager cannot use pipe to link the commands
#export MANPAGER="col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -"
#export MANPAGER="/bin/sh -c \"col -b | /usr/bin/vim.gtk3 -c 'set ft=man ts=8 nomod nolist nonu noma' -\""
#
# https://www.onooks.com/linux-mint-man-pages-require-sudo-when-pager-is-neovim/
## The issue come from when change the man to nvim:
# $ man ls
#     fuse: mount failed: Permission denied
#     Cannot mount AppImage, please check your FUSE setup.
if _has_cmd nvim; then
	#export MANPAGER="nvim -u $HOME/.config/nvim/init_for_man.vim -c 'set ft=man' -"
	#export MANPAGER="nvim -c 'set ft=man' -"
	export MANPAGER="nvim +Man!"
	export MANWIDTH=999
fi

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

