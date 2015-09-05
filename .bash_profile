
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

export TERM=xterm-color
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# Color shortcuts
export RESET_COLOR='\e[0m' # No Color
export BLACK='\e[0;30m'
export RED='\e[1;31m'
export GREEN='\e[1;32m'
export YELLOW='\e[1;33m'
export BLUE='\e[1;34m'
export PURPLE='\e[1;35m'
export CYAN='\e[1;36m'
export WHITE='\e[0;37m'

export BLUE='\e[0;36m'

# Format for git_prompt_status()
BASH_THEME_GIT_PROMPT_UNMERGED=" $RED unmerged"
BASH_THEME_GIT_PROMPT_DELETED=" $RED deleted"
BASH_THEME_GIT_PROMPT_RENAMED=" $YELLOW renamed"
BASH_THEME_GIT_PROMPT_MODIFIED=" $YELLOW modified"
BASH_THEME_GIT_PROMPT_ADDED=" $GREEN added"
BASH_THEME_GIT_PROMPT_UNTRACKED=" $WHITE untracked"

BASH_THEME_GIT_PROMPT_PREFIX="$RESET_COLOR $BLUE"
BASH_THEME_GIT_PROMPT_SUFFIX="$RESET_COLOR"
BASH_THEME_GIT_PROMPT_DIRTY="$RED (*)$RESET_COLOR"
BASH_THEME_GIT_PROMPT_CLEAN=""

# Colors vary depending on time lapsed.
BASH_THEME_GIT_TIME_SINCE_COMMIT_SHORT="$GREEN"
BASH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM="$YELLOW"
BASH_THEME_GIT_TIME_SINCE_COMMIT_LONG="$RED"
BASH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL="$BLUE"

# Format for git_prompt_ahead()
#BASH_THEME_GIT_PROMPT_AHEAD=" ${WHITE}(⚡)"
BASH_THEME_GIT_PROMPT_AHEAD=" ${WHITE}(↑)"

# Format for git_prompt_long_sha() and git_prompt_short_sha()
BASH_THEME_GIT_PROMPT_SHA_BEFORE="$YELLOW::$BLUE"
BASH_THEME_GIT_PROMPT_SHA_AFTER="$WHITE"

current_branch () {
  local ref
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret="$?"
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return
    ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

# Outputs if current branch is ahead of remote
git_prompt_ahead () {
  if [[ -n "$(git rev-list origin/$(current_branch)..HEAD 2> /dev/null)" ]]; then
    echo "$BASH_THEME_GIT_PROMPT_AHEAD"
  fi
}

# Checks if working tree is dirty
parse_git_dirty () {
  local STATUS=''
  local FLAGS
  FLAGS=('--porcelain')
  if [[ "$(git config --get oh-my-zsh.hide-dirty)" != "1" ]]; then
    if [[ $POST_1_7_2_GIT -gt 0 ]]; then
      FLAGS+='--ignore-submodules=dirty'
    fi
    if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]; then
      FLAGS+='--untracked-files=no'
    fi
    STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1)
  fi
  if [[ -n $STATUS ]]; then
    echo "$BASH_THEME_GIT_PROMPT_DIRTY"
  else
    echo "$BASH_THEME_GIT_PROMPT_CLEAN"
  fi
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
git_time_since_commit () {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Only proceed if there is actually a commit.
    if [[ $(git log 2>&1 > /dev/null | grep -c "^fatal: bad default revision") == 0 ]]; then
      # Get the last commit.
      last_commit=`git log --pretty=format:'%at' -1 2> /dev/null`
      now=`date +%s`
      seconds_since_last_commit=$((now-last_commit))

      # Totals
      MINUTES=$((seconds_since_last_commit / 60))
      HOURS=$((seconds_since_last_commit/3600))

      # Sub-hours and sub-minutes
      DAYS=$((seconds_since_last_commit / 86400))
      SUB_HOURS=$((HOURS % 24))
      SUB_MINUTES=$((MINUTES % 60))
      if [[ -n $(git status -s 2> /dev/null) ]]; then
        if [ "$MINUTES" -gt 30 ]; then
          COLOR="$BASH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
        elif [ "$MINUTES" -gt 10 ]; then
          COLOR="$BASH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
        else
          COLOR="$BASH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
        fi
      else
        COLOR="$BASH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
      fi

      if [ "$HOURS" -gt 24 ]; then
        echo "${COLOR}${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m${RESET_COLOR}"
      elif [ "${MINUTES}" -gt 60 ]; then
        echo "$COLOR${HOURS}h${SUB_MINUTES}m${RESET_COLOR}"
      else
        echo "$COLOR${MINUTES}m${RESET_COLOR}"
      fi
    else
      COLOR="${BASH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL}"
      echo "${RESET_COLOR}"
    fi
  fi
}

my_git_time () {
  echo "$RESET_COLOR (${RESET_COLOR}`git_time_since_commit`${RESET_COLOR})"
}

color_prompt=yes;
force_color_prompt=yes;

# old pos was after current_branch for... $(git_prompt_short_sha)
# old pos was before dirty status for...$(git_prompt_status)
git_custom_status () {
  local cb=$(current_branch)
  if [ -n "$cb" ]; then
    echo -e "${RESET_COLOR} on ${BASH_THEME_GIT_PROMPT_PREFIX}`current_branch`${BASH_THEME_GIT_PROMPT_SUFFIX}`my_git_time``parse_git_dirty``git_prompt_ahead`"
  fi
}

PS1="\[$PURPLE\]\u \[$RESET_COLOR\]at \[$YELLOW\]\h \[$RESET_COLOR\]in \[$CYAN\]\w\$(git_custom_status) \n\[$BLUE\]> \[$RESET_COLOR\]"
