# zsh-local
My local zsh config.

    git clone https://github.com/huawenyu/zsh-local.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-local

## How to add a new zsh-completion

For example, we'll put our zsh-completion function to our "<dir-plugin>/src"
1. Add the follow line to your zsh plugin file:

    fpath+="${0:h}/src"
    $ echo 'fpath+="${0:h}/src"' >> ~/.oh-my-zsh/custom/plugins/zsh-local/zsh-local.plugin.zsh

2. Put our completion function to that dir, `~/.oh-my-zsh/custom/plugins/zsh-local/src`

    $ ls ~/.oh-my-zsh/custom/plugins/zsh-local/src
    _hello  _traceme-py

