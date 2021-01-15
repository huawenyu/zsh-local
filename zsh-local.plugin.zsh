# fix issue:
#    "perl: warning: Please check that your locale settings:"
#
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# By default 0.4 second delay after hit the <ESC>
export KEYTIMEOUT=0

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

# Comtomize config {{{1
conf_fort=true

# Also should set ftpsvr in /etc/hosts
conf_use_ftps=false
# }}}

alias pwd=" pwd | sed 's/^/ /g'"
alias dict="$HOME/tools/dict"
alias eclipse="env SWT_GTK3=0 $HOME/tools/eclipse/eclipse &> /dev/null &"
#alias meld="nohup $HOME/tools/meld/bin/meld"
alias xnview="nohup $HOME/tools/XnView/XnView &> /dev/null &"
alias tmuxkill="tmux ls | grep -v attached | cut -d: -f1 | xargs -I{} tmux kill-session -t {}"
#alias ls='ls -lart'
alias sharepatch="cp patch.diff ~/share/.; cp fgtcoveragebuild.tar.xz ~/share/."

# Use these lines to enable search by globs, e.g. gcc*foo.c
#bindkey "^R" history-incremental-pattern-search-backward
#bindkey "^S" history-incremental-pattern-search-forward


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

function Run()
{
    if [ "$dryrun" == "off" ]; then
        echo "Executing $*"
        eval "$@"
    else
        echo "Executing $*"
        return 0
    fi
}


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
        return 1
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


function _mytail()
{
  if [ -t 0 ]; then
    \tail "$@" 2> >(grep -v truncated >&2)
  else
    \tail "$@" 2> >(grep -v truncated >&2)
  fi
};
alias tail='_mytail'


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


function _myftpls()
{
    eval "$LFTP_CMD 'cd $LFTP_DIR; ls; quit;'"
};
alias ftpls='_myftpls'

function _myftpget()
{
  if [ -z ${1} ]; then
    dname=${PWD##*/}
  else
    dname=${1}
  fi

  for var in "$@"
  do
    eval "$LFTP_CMD 'cd $LFTP_DIR; get $var; quit;'"
  done
};
alias ftpget='_myftpget'


function _myftpmirror()
{
  if [ -z ${1} ]; then
    echo "  Please give a mirror dir name!"
  else
    dname=${1}
    echo "  Mirror '$dname'!"
    eval "$LFTP_CMD 'cd $LFTP_DIR; mirror $dname; quit;'"
  fi
};
alias ftpmirror='_myftpmirror'


function _myftpput()
{
  if [ -z ${1} ]; then
    dname=${PWD##*/}
  else
    dname=${1}
  fi

  for var in "$@"
  do
    eval "$LFTP_CMD 'cd $LFTP_DIR; put $var; quit;'"
  done
};
alias ftpput='_myftpput'

function _myftprm()
{
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

function _myftp()
{
  if [ -z ${1} ]; then
    dname=${PWD##*/}
  else
    dname=${1}
  fi

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

# Customize to your needs...
# Tmux recognize
export TERM=screen-256color
export EDITOR='vim'

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

#parse_git_branch() {
#     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}
#export PS1="\[\033[32m\]\W\[\033[31m\]\$(parse_git_branch)\[\033[00m\] $ "

# fake sudo vim ~/root/etc/hosts
#    ln -s /drives/c/Windows/System32/drivers/ ./root
alias sync-push="rsync -avrz --progress ~/share/ hyu@work:/home/hyu/workref/share/"
alias sync-pull="rsync -avrz --progress hyu@work:/home/hyu/workref/share/ ~/share/"


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

export TASKDDATA=/var/lib/taskd

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

# Rust
if hash rustc 2>/dev/null; then
    export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src/
    export PATH="$HOME/.cargo/bin:$PATH";
fi

# todo.txt-cli
export TODOTXT_DEFAULT_ACTION=ls
#alias t='$HOME/tools/todo.txt-cli-ex/todo.sh -d $HOME/tools/todo.txt-cli-ex/todo.cfg'
alias t='$HOME/tools/todo.txt-cli-ex/todo.sh'

# Disable warning messsage:
#   WARNING: gnome-keyring:: couldn't connect to: /run/user/1000/keyring-s99rSr/pkcs11: Connection refused
unset GNOME_KEYRING_CONTROL

if ! type "fzf" > /dev/null; then
	if [ -f "$HOME/.fzf/bin/fzf" ]; then
		mkdir -p "$HOME/bin"
		ln -s "$HOME/.fzf/bin/fzf" "$HOME/bin/fzf"
	fi
fi

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
