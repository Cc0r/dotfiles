# Use lynx as our terminal browser
BROWSER=lynx
export BROWSER

# Use ed as our line editor and vi as our visual editor
EDITOR=ed
VISUAL=nano
export EDITOR VISUAL

# Set the POSIX interactive startup file to ~/.shinit
ENV=$HOME/.shinit
export ENV

# Use less as my pager
PAGER=less
export PAGER

# Source all scripts in ~/.profile.d; many of them will be modifying $PATH, so
# we'll get that sorted out first
for sh in "$HOME"/.profile.d/*.sh ; do
    [ -e "$sh" ] || continue
    . "$sh"
done
unset -v sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
