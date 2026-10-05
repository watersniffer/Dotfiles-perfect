# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded,ttps://git run: echo $RANDOM_THEME
# See hhub.com/ohmyzsh/ohmyzsh/wiki/Themes
#
# Driven by `theme-switcher` (Super+T).
#
# oh-my-zsh will NOT accept a path here. It appends ".zsh-theme" itself and
# looks for <name>.zsh-theme in exactly three places: $ZSH_CUSTOM,
# $ZSH_CUSTOM/themes, $ZSH/themes. So an absolute path such as
# ~/.config/theme-switcher/zsh/themes/monochrome.zsh-theme is not "a path to a
# theme", it is a theme *name*, and OMZ reports it as not found.
#
# Hence the "theme-" prefix: the switcher symlinks
# ~/.oh-my-zsh/custom/themes/theme-<name>.zsh-theme at the generated file, which
# is where OMZ will look. The prefix is not decoration -- it stops this from
# colliding with OMZ's own themes, and in particular with the existing
# custom/themes/gruvbox.zsh-theme, which would otherwise be overwritten.
#
# The readability check matters as much as the assignment: if the symlink is
# missing, which happens if the theme dir is ever cleaned out, OMZ would print
# a "theme not found" error into every new shell. Falling back to OMZ's gruvbox
# degrades quietly instead.
if [[ -r "$HOME/.config/theme-switcher/current" ]]; then
  _ts_theme="$(<"$HOME/.config/theme-switcher/current")"
  _ts_file="$HOME/.oh-my-zsh/custom/themes/theme-${_ts_theme}.zsh-theme"
  if [[ -r "$_ts_file" ]]; then
    ZSH_THEME="theme-${_ts_theme}"
  else
    ZSH_THEME="gruvbox"
  fi
  unset _ts_theme _ts_file
else
  ZSH_THEME="gruvbox"
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change the frequency the auto-updater is run (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line to set how old an update must be before it's applied, manually or via the auto-updater (in days).
# zstyle ':omz:update' cooldown 10

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
         zsh-autosuggestions
         zsh-syntax-highlighting
         )

source $ZSH/oh-my-zsh.sh

# LS_COLORS from the active theme.
#
# This has to come *after* oh-my-zsh.sh: OMZ runs dircolors during setup, and
# sourcing this before it would mean OMZ's own LS_COLORS won. The file is
# rewritten by `theme-switcher`, so new shells pick up the new palette with no
# further action -- an already-open shell keeps the colours it started with,
# which is why the switcher tells you to run `exec zsh`.
if [[ -r "$HOME/.config/theme-switcher/zsh/lscolors.zsh" ]]; then
  source "$HOME/.config/theme-switcher/zsh/lscolors.zsh"
fi

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Launch fastfetch on shell start
if command -v fastfetch &> /dev/null; then
    fastfetch
fi

