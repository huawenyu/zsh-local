# zsh-local
My local zsh config.
Copy from:
- https://github.com/zpm-zsh/helpers.git

    git clone https://github.com/huawenyu/zsh-local.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-local

## How to write a plugin
https://wiki.zshell.dev/community/zsh_plugin_standard

## How to troubleshooting performance of zsh-profile

Patch ~/.oh-my-zsh/oh-my-zsh.sh:

		#Load all of the plugins that were defined in ~/.zshrc
		for plugin ($plugins); do
		  if [ ! -z ${zsh_timestamp+x} ]; then SECONDS=0; fi
		      ....
		  if [ ! -z ${zsh_timestamp+x} ]; then echo $SECONDS":" $plugin; fi
		done

## How to parse arguments
https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

## How to add a new zsh-completion

For example, we'll put our zsh-completion function to our "<dir-plugin>/functions"
1. Add the follow line to your zsh plugin file:

    fpath+="${0:h}/functions"
    $ echo 'fpath+="${0:h}/functions"' >> ~/.oh-my-zsh/custom/plugins/zsh-local/zsh-local.plugin.zsh

2. Put our completion function to that dir, `~/.oh-my-zsh/custom/plugins/zsh-local/functions`

    $ ls ~/.oh-my-zsh/custom/plugins/zsh-local/functions
    _hello  _traceme-py

## Howto use shell-integrate fzf:
https://www.freecodecamp.org/news/fzf-a-command-line-fuzzy-finder-missing-demo-a7de312403ff/

Letters `**` sequence triggers fzf finder and it resembles * which is for native shell expansion.

	cd **<TAB>
	vi **<TAB>

Shortkey:

	Ctrl-z+r    Search command history [Ctrl-R]
	Atl-c       List/Change dir
	Ctrl-t      Like the ** sequence
	kill -9<TAB>

