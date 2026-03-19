fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions ~/.zfunc $fpath)
autoload -U compinit && compinit
