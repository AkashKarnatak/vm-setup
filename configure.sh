#!/bin/bash

LOCATION=$HOME

echo -e "\n\nBacking up .bashrc, .bash_aliases, .inputrc and .tmux.conf"

if [ -f $HOME/.bashrc ]; then
  mv $HOME/.bashrc $HOME/.bashrc.bak
fi

if [ -f $HOME/.bash_aliases ]; then
  mv $HOME/.bash_aliases $HOME/.bash_aliases.bak
fi

if [ -f $HOME/.inputrc ]; then
  mv $HOME/.inputrc $HOME/.inputrc.bak
fi

if [ -f $HOME/.tmux.conf ]; then
  mv $HOME/.tmux.conf $HOME/.tmux.conf.bak
fi

cat << EOF >> $HOME/.gitconfig
[alias]
  lg = lg2
  lg1 = lg1-specific --all
  lg2 = lg2-specific --all
  lg3 = lg3-specific --all

  lg1-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'
  lg2-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C("#bbbbbb")%s%C(reset) %C(white)- %an%C(reset)'
  lg3-specific = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'
EOF

echo -e "\nInstalling required software..."

sudo apt update && sudo apt install -y neovim xclip

mkdir -p $HOME/.config/nvim
cat << EOF >> $HOME/.config/nvim/init.vim
set number
set nowrap
set cursorline
set tabstop=2
set shiftwidth=2
set splitbelow
set splitright
set expandtab
set smartindent
colorscheme habamax
set clipboard=unnamedplus

nnoremap 0 $
nnoremap $ ^
nnoremap ^ 0
vnoremap 0 $
vnoremap $ ^
vnoremap ^ 0
onoremap 0 $
onoremap $ ^
onoremap ^ 0
EOF

echo -e "\nDownloading new config..."

curl https://raw.githubusercontent.com/AkashKarnatak/vm-setup/main/.bashrc -o ~/.bashrc
curl https://raw.githubusercontent.com/AkashKarnatak/vm-setup/main/.bash_aliases -o ~/.bash_aliases
curl https://raw.githubusercontent.com/AkashKarnatak/vm-setup/main/.inputrc -o ~/.inputrc
curl https://raw.githubusercontent.com/AkashKarnatak/vm-setup/main/.tmux.conf -o ~/.tmux.conf

echo -e "\n\nLoad new configuration using,\n\tsource ~/.bashrc && bind -f  ~/.inputrc"
