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
#
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

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
	  dryrun: dryrun=1 Run ls -lart
	      tshare add user1
	      tshare del user1
	      ssh user1@work -t 'tmux -S /tmp/tmux_share attach -t share'
	  tlayout: new | list | select | clone
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


# function dry Run {{{3
# dryrun="" Run ls -lart
function Run()
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


# function HasCmd {{{3
# Usage: if HasCmd boxes; then echo "has boxes"; else echo "nopes"; fi
function HasCmd()
{
    if [ ! -z ${1} ]; then
        if ! command -v $1 &> /dev/null
        then
            # 1 = false
            return 1
        else
            # 0 = true
            return 0
        fi
    else
        # 1 = false
        return 1
    fi
}

# function Echo {{{3
# if [ -x boxes ]; then echo "exist"; else echo "not exist"; fi
function Echo()
{
    if HasCmd boxes; then
        echo "$*" | boxes
    else
        echo "$*"
    fi
}

# function IsNum {{{3
# https://stackoverflow.com/questions/5431909/returning-a-boolean-from-a-bash-function
# Usage: if IsNum $1; then echo "is number"; else echo "nopes"; fi
function IsNum()
{
    if [ -n "$var" ] && [ "$var" -eq "$var" ] 2>/dev/null; then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}


# function IsDir {{{3
function IsDir()
{
    if [ -d "$1" ]
    then
        # 0 = true
        return 0
    else
        # 1 = false
        return 1
    fi
}


# function HasVar {{{3
# Usage: if HasVar $var; then echo "has var"; else echo "nopes"; fi
function HasVar()
{
    if [ -z ${1+x} ]; then
        # 1 = false
        return 1
    else
        # 0 = true
        return 0
    fi
}

# Comtomize config {{{1
# local encode info
if [ -f "$HOME/.local/local" ]; then
    #echo "load local succ!"
    source $HOME/.local/local
else
    Echo "[$me] no local-env loaded from '$HOME/.local/local', but it's harmless!"
fi

# dev-var
conf_fort=true
# Also should set ftpsvr in /etc/hosts
conf_use_ftps=false
export MYPATH_HEYTMUX="$HOME/script/heytmux"
export MYPATH_WORKREF="$HOME/workref"
export MYPATH_WORK="$HOME/work"
export MYPATH_WIKI="$HOME/doc"


# PS1 {{{2
#parse_git_branch() {
#     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}
#export PS1="\[\033[32m\]\W\[\033[31m\]\$(parse_git_branch)\[\033[00m\] $ "


# alias: pwd, dict, sharepatch {{{2
alias pwd=" pwd | sed 's/^/ /g'"
alias dict="$HOME/tools/dict"
alias eclipse="env SWT_GTK3=0 $HOME/tools/eclipse/eclipse &> /dev/null &"
#alias meld="nohup $HOME/tools/meld/bin/meld"
alias xnview="nohup $HOME/tools/XnView/XnView &> /dev/null &"
alias tmuxkill="tmux ls | grep -v attached | cut -d: -f1 | xargs -r -I{} tmux kill-session -t {}"
#alias ls='ls -lart'
alias sharepatch="cp patch.diff ~/share/.; cp fgtcoveragebuild.tar.xz ~/share/.; cp ../doc/checklist.txt ~/share/."

# fake sudo vim ~/root/etc/hosts
#    ln -s /drives/c/Windows/System32/drivers/ ./root
alias sync-push="rsync -avrz --progress ~/share/ hyu@work:${MYPATH_WORKREF}/share/"
alias sync-pull="rsync -avrz --progress hyu@work:${MYPATH_WORKREF}/share/ ~/share/"


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
            Run sudo ln -s /bin/bash /bin/rbash
        fi
        Run cd /home
        Run sudo mkdir -p ${userName}
        Run sudo chmod 755 ${userName}
        Run sudo useradd -s /bin/rbash -d /home/${userName} ${userName}
        Run sudo passwd ${userName}

        # create the 'share' session but not attach it.
        Run tmux -S /tmp/tmux_${sesName} new -d -s ${sesName}
        Run sudo chmod 777 /tmp/tmux_${sesName}
        Run tmux -S /tmp/tmux_${sesName} attach -t ${sesName}

        echo "ShareLink: ssh ${userName}@work -t 'tmux -S /tmp/tmux_${sesName} attach -t ${sesName}'"
    elif [ ${action} == "del" ]; then
        #Run sudo userdel -r ${userName}
        Run tmux -S /tmp/tmux_${sesName} kill -t ${sesName}
        Run sudo killall -u ${userName}
        Run sudo deluser --remove-home -f ${userName}
        Run sudo rm -fr /tmp/tmux_${sesName}
    fi
};
alias tshare='_task_share_screen'

alias swork="ssh hyu@work -t 'tmux attach -t work || tmux new -s work'"
alias mwork="mosh hyu@work -- sh -c 'tmux attach -t work || tmux new -s work'"


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
USAGE=$(cat <<-END
	  $0  list
	  $0  new|select [layout, 'default']
	  $0  clone [nameLayout] [nameWindow] [bugNum]
END
)

    usage=0
    # @args:action
    if [ -z ${1} ]; then
        action='list'
        Echo "${USAGE}"
    else
        action=$1
        shift
    fi

    # @args:layout
    if [ ${action} == "list" ]; then
        Run cat /tmp/tmux.layout| cut -d "=" -f 1
        return 0
    elif [ ${action} == "new" ] || [ ${action} == "select" ]; then
        if [ -z ${1} ]; then
            layout='default'
        else
            layout=$1
            shift
        fi
    elif [ ${action} == "clone" ]; then
        # @args: layout
        if [ -z ${1} ]; then
            # Echo "${USAGE}"
            # Echo2 "\t args: $0 clone [${RED}nameLayout${NC}] [nameWindow] [bugNum]"
            layout='default'
        else
            layout=$1
            shift
        fi

        # @args: nameWindow
        if [ -z ${1} ]; then
            # Echo "${USAGE}"
            # Echo2 "\t args: $0 clone $layout ${RED}nameWindow${NC} bugNum"
            nameWindow=$(tmux display-message -p '#W')
        else
            nameWindow=$1
            shift
        fi

        # @args: bugNum
        if [ -z ${1} ]; then
            # Echo "${USAGE}"
            # Echo2 "\t args: $0 clone $layout $nameWindow [${RED}bugNum${NC}]"
            bugNum=0
        else
            bugNum=$1
            shift
        fi
    else
        # Echo "${USAGE}"
        return 1
    fi


    # do-task
    if [ ${action} == "new" ]; then
        Run tmux display-message -p "${layout}='#{window_layout}'" >> /tmp/tmux.layout
        Run tlayout list
        return 0
    elif [ ${action} == "select" ]; then
        # <nameLayout>='layoutString'
        source /tmp/tmux.layout

        eval layoutString='$'${layout}
        if [ ! -z ${layoutString+x} ]; then
            echo "Tmux-layout '${layout}': ${layoutString}"
            Run tmux select-layout "'${layoutString}'"
            return 0
        fi
    elif [ ${action} == "clone" ]; then
        #   #!/bin/bash
        #
        #   source /tmp/tmux.layout
        #
        #   nameLayout='mylayout1'
        #   echo ${nameLayout}
        #   echo ${!nameLayout2}
        #
        #   if [ ! -z "${!nameLayout}" ]; then
        #   	echo "\$var is NOT empty"
        #   fi
        #
        #   if [ ! -z "${!nameLayout2}" ]; then
        #   	echo "\$var2 is NOT empty"
        #   fi
        #
        #   exit 1
        #
        #   suffix=bzz
        #   declare prefix_$suffix=mystr
        #
        #   # Then
        #   varname=prefix_$suffix
        #   echo ${varname}
        #   echo ${!varname}

        if HasCmd heytmux; then
            : #
        else
            Echo -e "According https://github.com/junegunn/heytmux \n Install: gem install heytmux" | boxes
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
                    Run heyWindow=${nameWindow} heyBug=${bugNum} heytmux "${MYPATH_HEYTMUX}/${layout}.yml"
                    Run tmux select-layout -t   "'${nameWindow}'"   "'${layoutString}'"
                else
                    echo "[$me] Please create heytmux layout file ${RED}'${layout}.yml'${NC} into '${MYPATH_HEYTMUX}'"
                    return 1
                fi
            fi
        } || { # catch
            # save log for exception 
            echo "[$me] Please create the layout ${RED}'${layout}'${NC} into /tmp/tmux.layout:"
            echo "$0 new ${layout}"
            return 1
        }

    elif [ ${layout} == "top" ]; then
        Run tmux kill-pane -a
        Run tmux split-window -v -p 80
        Run tmux split-window -h -p 70 -t 1
        Run tmux split-window -h -p 50
        Run tmux select-pane -t 4
        Run tmux send-keys "new-doc.sh" Space "${bugnumber}" Enter
        #Run tmux send-keys 'echo music' 'Enter'
        #Run tmux select-pane -t 2
    elif [ ${product} == "right" ]; then
        Run tmux kill-pane -a
        Run tmux split-window -v -p 80
        Run tmux split-window -h -p 70 -t 1
        Run tmux split-window -h -p 50
        #Run tmux send-keys 'echo key' 'Enter'
        #Run tmux send-keys 'echo music' 'Enter'
        #Run tmux select-pane -t 2
    else
        echo "Support layouts: gen,cp; top,right"
    fi
    return 0
};
alias tlayout='_tmux_layout_man'


# Show current task's document {{{2
function _task_document()
{
    nameWindow=$(tmux display-message -p '#W')
    tree -if --noreport ${MYPATH_WORKREF}/doc/*$nameWindow \
        | fzf --keep-right --preview 'head -qn 30 {1} 2> /dev/null' --preview-window +{2}-/2 \
        | xargs -r -o $EDITOR
};
alias tdoc='_task_document'


function _task_preview()
{
    unset fname
    unset fline
    IN=$1
    mails=$(echo $IN | tr ":" "\n")

    for addr in $mails
    do
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
	  $0 [subdir] [grep-string]
END
)
    # @args:subdir
    if [ -z ${1} ]; then
        grepdir=$MYPATH_WIKI
        greptext="  "
        Echo "${USAGE}"
    else
        subdir=$1
        if [ -d "$MYPATH_WIKI/${subdir}" ]; then
            grepdir="$MYPATH_WIKI/${subdir}"
        else
            greptext=$1
        fi
        shift
    fi

    if [ ! -v "greptext" ]; then
        # @args:greptext
        if [ -z ${1} ]; then
            greptext="  "
        else
            greptext=$1
            shift
        fi
    fi

    rg -nL "$greptext" $grepdir \
        | fzf --keep-right --preview "doc-preview.sh {}" --preview-window=up:40% \
        | cut -d ':' -f 1,2 | xargs -r -o $EDITOR
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
    if [ -z ${1} ]; then
        echo "script model buildnum [product=fos|fpx|<ls>]: no model. 'script 600E 1561'"
        return 1
    else
        model=${1}
    fi

    if [ -z ${2} ]; then
        echo "Args likes, model buildnum [product=fos|fpx|<ls>]: no buildnum."
        echo "Sample: smbget 400E 0288 fpx"
        echo "        smbget VMWARE 0288 fpx"
        return 0
    else
        buildnum=${2}
    fi

    if [ -z ${3} ]; then
        echo "product: 'fos'"
        product="fos"
    else
        product=${3}
    fi

    if [ ${product} == "fos" ]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; get FGT_${model}-v6-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; get FGT_${model}-v6-build${buildnum}-FORTINET.out.extra.tgz;'"
    elif [ ${product} == "fpx" ]; then
        echo "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiProxy/v1.00/images/build${buildnum}; get FPX_${model}-v100-build${buildnum}-FORTINET.out.extra.tgz;'"
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiProxy/v1.00/images/build${buildnum}; get FPX_${model}-v100-build${buildnum}-FORTINET.out.extra.tgz;'"
    elif [ ${product} == "ls" ]; then
        eval "smbclient -A ~/.smbclient.conf //imagesvr/Images -c 'cd FortiOS/v6.00/images/build${buildnum}; ls *-FORTINET.out.extra.tgz;'"
    else
        echo "Args likes, model buildnum [product=fos|fpx|<ls>]: script 600E 1561 ls"
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
    if ! HasVar $LFTP_CMD; then
        if $conf_fort ; then
            ftpAddr=$(getent hosts ftpsvr | awk '{ print $1 }')
            #echo "### @Note the ftpsvr is ${ftpAddr} ###"

            if $conf_use_ftps ; then
                # sftpserver
                export LFTP_CMD="lftp sftp://hyu:@${ftpAddr} -e "
                export LFTP_DIR=$USER
            else
                # ftpserver
                export LFTP_CMD="lftp -u test,test ${ftpAddr} -e "
                export LFTP_DIR=upload/$USER
            fi
        fi
    fi
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


# function _bear {{{2
# used to generate the c/c++ ccls indexer db: ccls clang makefile
function _bear()
{

    if [ -f compile_commands.json ]; then
        ;
    else
        branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
        cp ~/workref/compile_commands.json-${branch} compile_commands.json || { echo 'The file ~/workref/compile_commands.json-${branch} not exist!' ; exit 1; }
    fi
    sample_dir=$(awk 'match($0, /-I(.*)\/fortiweb\/packages\/ext/, arr) {print arr[1]; exit}' compile_commands.json)
    #echo $sample_dir
    cur_dir=$(realpath .)
    #sed -i "s;$sample_dir;$cur_dir;g" compile_commands.json
    Run "sed -i 's;$sample_dir;$cur_dir;g' compile_commands.json"
};
alias bearme='_bear'


# Setup env vars {{{1
#
# ENV-TERM {{{2
# Customize to your needs...
# Tmux recognize
export TERM=screen-256color
export EDITOR='vim'

# ENV-PATH {{{2
if [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

if [ -d "/usr/.local/bin" ]; then
  export PATH="/usr/.local/bin:$PATH"
fi

if [ -d "/snap/bin" ]; then
  export PATH="/snap/bin:$PATH"
fi

if [ -d "/usr/bin" ]; then
  export PATH="/usr/bin:$PATH"
fi

if [ -d "/bin" ]; then
  export PATH="/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ]; then
  export PATH="/usr/local/sbin:$PATH"
fi

if [ -d "/usr/sbin" ]; then
  export PATH="/usr/sbin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi


export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5";
export PERL_MB_OPT="--install_base $HOME/perl5";
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5";
export PERL5LIB="./lib:$HOME/perl5/lib:$PERL5LIB";
alias  perldoctest='perl -MTest::Doctest -e run'

export AWKPATH=".:$HOME/script/awk:$HOME/script/awk/awk-libs:$AWKPATH";

export PYTHONPATH=".:$HOME/dotwiki/lib/python:$PYTHONPATH"
export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  eval "$(pyenv init -)"
fi


# export JAVA_HOME="/usr/java/latest"
export JAVA_HOME="/usr/lib/jvm/java-8-oracle"

export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

if [ -d "/usr/lib64/qt-3.3/bin" ]; then
  export PATH="/usr/lib64/qt-3.3/bin:$PATH"
fi

if [ -d "/usr/lib64/ccache" ]; then
  export PATH="/usr/lib64/ccache:$PATH"
fi

if [ -d "/opt/ActiveTcl-8.6/bin" ]; then
  export PATH="/opt/ActiveTcl-8.6/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "$HOME/perl5/bin" ]; then
  export PATH="$HOME/perl5/bin:$PATH"
fi

if [ -d "$HOME/.linuxbrew/bin" ]; then
  export PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
elif [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
fi

## debug neovim python plugin:
#export NVIM_PYTHON_LOG_FILE=/tmp/log
#export NVIM_PYTHON_LOG_LEVEL=DEBUG

export PATH="$HOME/generator:$HOME/script:$HOME/script/git-scripts:$HOME/script/python:$HOME/dotwiki/tool:$PATH";

# task, todos {{{2
export TASKDDATA=/var/lib/taskd
# todo.txt-cli
export TODOTXT_DEFAULT_ACTION=ls
#alias t='$HOME/tools/todo.txt-cli-ex/todo.sh -d $HOME/tools/todo.txt-cli-ex/todo.cfg'
alias t='$HOME/tools/todo.txt-cli-ex/todo.sh'


# used develop {{{2
if $conf_fort ; then
    export USESUDO=$(which sudo)
    export FORTIPKG=$HOME/fortipkg
fi

#export JEMALLOC_PATH=$HOME/project/jemalloc
#export MALLOC_CONF="prof:true,prof_prefix:jeprof.out"

# minicom line wrap: sudo -E minicom
export MINICOM="-w"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export SSLKEYLOGFILE=~/sslkey.log

# lang-Rust {{{2
if hash rustc 2>/dev/null; then
    export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src/
    export PATH="$HOME/.cargo/bin:$PATH";
fi

# Disable warning messsage:
#   WARNING: gnome-keyring:: couldn't connect to: /run/user/1000/keyring-s99rSr/pkcs11: Connection refused
unset GNOME_KEYRING_CONTROL

# fzf {{{2
if ! type "fzf" > /dev/null; then
	if [ -f "$HOME/.fzf/bin/fzf" ]; then
		mkdir -p "$HOME/bin"
		ln -s "$HOME/.fzf/bin/fzf" "$HOME/bin/fzf"
	fi
fi

# fzf: global config {{{3
export FZF_DEFAULT_OPTS='
--bind=ctrl-p:up,ctrl-n:down,alt-p:preview-up,alt-n:preview-down
--color fg:-1,bg:-1,hl:178,fg+:3,bg+:233,hl+:220
--color info:150,prompt:110,spinner:150,pointer:167,marker:174
'

# see zplugin-init.zsh with Turbo Mode
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Vi keybinding
#bindkey -v

# manpager cannot use pipe to link the commands
#export MANPAGER="col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -"
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

