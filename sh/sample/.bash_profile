# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=$PATH:$ORACLE_HOME/bin
export NLS_LANG=Japanese_Japan.AL32UTF8

export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.linuxbrew/bin:$PATH"

export PATH="/home/user1/.pyenv/shims:${PATH}"
export PYENV_SHELL=bash
source '/home/user1/.linuxbrew/Cellar/pyenv/1.0.8/libexec/../completions/pyenv.bash'
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig
export LD_LIBRARY_PATH=/usr/lib64:/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=/usr/local/lib/python2.7/site-packagesexport PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [[ -s ~/.nvm/nvm.sh ]];
  then source ~/.nvm/nvm.sh
fi
export PATH=$PATH:./node_modules/.bin

