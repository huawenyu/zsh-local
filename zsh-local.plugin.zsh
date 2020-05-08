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

alias pwd=' pwd'
alias dict="$HOME/tools/dict"
alias eclipse="env SWT_GTK3=0 $HOME/tools/eclipse/eclipse &> /dev/null &"
#alias meld="nohup $HOME/tools/meld/bin/meld"
alias xnview="nohup $HOME/tools/XnView/XnView &> /dev/null &"
alias tmuxkill="tmux ls | grep -v attached | cut -d: -f1 | xargs -I{} tmux kill-session -t {}"

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
export TERM=screen-256color
export EDITOR='vim'

if [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

if [ -d "/usr/.local/bin" ]; then
  export PATH="/usr/.local/bin:$PATH"
fi

if [ -d "/usr/bin" ]; then
  export PATH="/usr/bin:$PATH"
fi

if [ -d "/bin" ]; then
  export PATH="/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ -d "/usr/local/sbin" ]; then
  export PATH="/usr/local/sbin:$PATH"
fi

if [ -d "/usr/sbin" ]; then
  export PATH="/usr/sbin:$PATH"
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


export PATH="$HOME/generator:$HOME/script:$HOME/script/git-scripts:$HOME/dotwiki/tool:$PATH";


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

