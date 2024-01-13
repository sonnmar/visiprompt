#!/usr/bin/env zsh


# base settings
autoload -U colors && colors
setopt transientrprompt
setopt prompt_subst


# git information
prs_git () {
    # TODO: Integrate merge conflicts (local git path with directory "MERGE_HEAD"?)
    # return value

    # branch name
    local bra="$(git symbolic-ref --short --quiet HEAD 2> /dev/null)"


    # if there is a branche name it should be a git repository
    if [[ -n "$bra" ]]; then

        local str="%F{yellow}[%f%F{blue}"

        # is there a remote host?
        if [[ -n $(git config --get remote.origin.url) ]]; then

            # local commits ahead and behind
            local ahead="${$(git log --oneline @{u}.. 2> /dev/null | wc -l)/' '#/}"
            local behind="${$(git log --oneline ..@{u} 2> /dev/null | wc -l)/' '#/}"

            if [[ $ahead -gt 0 ]]; then
                str+="A$ahead"
            elif [[ $behind -gt 0 ]]; then
                str+="B$behind"
            else
                # local commits are equal to remote repository
                str+="+-"
            fi

            str+="%f"
        else
            # no remote repository
            str+="--"
        fi

        str+="%F{yellow}|%f"

        # number of staged modified files
        str+="%F{green}${$(git diff --cached --numstat 2> /dev/null | wc -l)/' '#/}%f"

        # number of unstaged modified files
        str+="%F{yellow}${$(git ls-files --modified --exclude-standard 2> /dev/null | wc -l)/' '#/}%f"

        # Number of untracked files
        str+="%F{red}${$(git ls-files --other --exclude-standard 2> /dev/null | wc -l)/' '#/}%f"

        str+="%F{yellow}|$bra]%f"
        echo "$str"
    fi
}


# User- and Hostname if not equal to logon names
function prs_adr() {
    local str=""
    if [[ "$USER" != "$LOGNAME" || -v "SSH_CONNECTION" ]]; then
        str="$USER"
    fi
    if [[ -v "SSH_CONNECTION" ]]; then
        str+="@${$(uname -n)%%.*}"
    fi
    echo "$str"
}


# Virtual Environment in Python
function prs_venv() {
    local str=""
    local line=""
    if [[ -v "VIRTUAL_ENV" ]]; then
        line=$(grep '^prompt' "$VIRTUAL_ENV/pyvenv.cfg")
        if [[ -n $line ]]; then
            str="[${line[11,-2]}]"
        else
            str="[${VIRTUAL_ENV##*/}]"
        fi
    fi
    echo "$str"
}


# register Functions
zle -N zle-line-init
zle -N zle-keymap-select


# call on line-init and keymap-select to build prompt and set cursor
function zle-line-init zle-keymap-select () {

    # set cursor and prompt by editor mode
    PROMPT="%F{blue}"
    case $KEYMAP in
        viins|main)
            echo -ne '\e[5 q'
            PROMPT+="<I>"
            ;;
        vicmd)
            echo -ne '\e[1 q'
            PROMPT+="<N>"
            ;;
        *)
            PROMPT="<>"
    esac
    PROMPT+="%f"

    # user- and hostname
    PROMPT+="%F{green}\$(prs_adr)>%f"

    # path
    PROMPT+="%F{cyan}%~>%f "

    # on the right side: git-information
    RPROMPT="\$(prs_git)"

    # Python virtuel environment
    RPROMPT+="%F{blue}\$(prs_venv)%f"

    # infos about backgground jobs
    RPROMPT+="%(1j.%F{magenta}[%j]%f.)"

    # and return number of the last command
    RPROMPT+="%(?..%F{red}[%?]%f)"

    # reset the prompt
    zle reset-prompt
}
