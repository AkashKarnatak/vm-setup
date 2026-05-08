# Command to open file or folder using the default application
alias xopen=xdg-open
alias diff="diff --color=always"
alias ip='ip -color=auto'
alias less="less -R"
function lt {
  ls -t --color=always --hyperlink=always $@ | head
}
function rgf {
  rg -L --hidden --files $2 | rg $1
}
