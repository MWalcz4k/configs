export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:~/go/bin

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="xiong-chiamiov-plus"

zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13

plugins=(git)

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8
export EDITOR='vim'

# Functions
kubectlspace(){
  kubectl config set-context --current --namespace=$1
}
nicefiles () {
  gci write --skip-generated --skip-vendor -s localmodule -s standard -s default -s 'prefix(go.efg-tech.gg,github.com/faceit,gitlab.com/eslfaceitgroup)'  $@ && gofmt -s -w $@
}

# Aliases
alias kubespace="kubectlspace"
alias gofimp="formatimport"
