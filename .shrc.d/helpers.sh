
# I don't like the LS_COLORS environment variable, but GNU tree(1) doesn't
# color its output by default without it; this will coax it into doing so with
# the default colors when writing to a terminal.
tree() {

    # Subshell will run the tests to check if we should color the output
    if (

        # Not if -n is in the arguments and -C isn't
        # Don't tell me about missing options, either
        while getopts 'nC' opt 2>/dev/null ; do
            case $opt in
                n) n=1 ;;
                C) C=1 ;;
                *) ;;
            esac
        done
        [ -z "$C" ] || exit 0
        [ -z "$n" ] || exit 1

        # Not if output isn't a terminal
        [ -t 1 ] || exit

        # Not if output terminal doesn't have at least 8 colors
        [ "$(exec 2>/dev/null;tput colors||tput Co||echo 0)" -ge 8 ]

    ) ; then
        set -- -C "$@"
    fi

    # Run the command with the determined arguments
    command tree "$@"
}

# Function to manage contents of PATH variable within the current shell
path() {

    # Check first argument to figure out operation
    case $1 in

        # List current directories in PATH
        list|'')
            set -- "$PATH":
            while [ -n "$1" ] ; do
                case $1 in
                    :*) ;;
                    *) printf '%s\n' "${1%%:*}" ;;
                esac
                set -- "${1#*:}"
            done
            ;;

        # Helper function checks directory argument makes sense
        _argcheck)
            shift
            if [ "$#" -gt 2 ] ; then
                printf >&2 'path(): %s: too many arguments\n' "$1"
                return 2
            fi
            case $2 in
                *:*)
                    printf >&2 'path(): %s: %s contains colon\n' "$@"
                    return 2
                    ;;
            esac
            return 0
            ;;

        # Add a directory at the start of $PATH
        insert)
            if ! [ "$#" -eq 2 ] ; then
                set -- "$1" "$PWD"
            fi
            path _argcheck "$@" || return
            if path check "$2" ; then
                printf >&2 'path(): %s: %s already in PATH\n' "$@"
                return 1
            fi
            PATH=${2}${PATH:+:"$PATH"}
            ;;

        # Add a directory to the end of $PATH
        append)
            if ! [ "$#" -eq 2 ] ; then
                set -- "$1" "$PWD"
            fi
            path _argcheck "$@" || return
            if path check "$2" ; then
                printf >&2 'path(): %s: %s already in PATH\n' "$@"
                return 1
            fi
            PATH=${PATH:+"$PATH":}${2}
            ;;

        # Remove a directory from $PATH
        remove)
            if ! [ "$#" -eq 2 ] ; then
                set -- "$1" "$PWD"
            fi
            path _argcheck "$@" || return
            if ! path check "$2" ; then
                printf >&2 'path(): %s: %s not in PATH\n' "$@"
                return 1
            fi
            PATH=$(
                path=:$PATH:
                path=${path%%:"$2":*}:${path#*:"$2":}
                path=${path#:}
                printf '%s:' "$path"
            )
            PATH=${PATH%%:}
            ;;

        # Remove the first directory in $PATH
        shift)
            case $PATH in
                '')
                    printf >&2 'path(): %s: PATH is empty!\n' "$@"
                    return 1
                    ;;
                *:*)
                    PATH=${PATH#*:}
                    ;;
                *)
                    # shellcheck disable=SC2123
                    PATH=
                    ;;
            esac
            ;;

        # Remove the last directory in $PATH
        pop)
            case $PATH in
                '')
                    printf >&2 'path(): %s: PATH is empty!\n' "$@"
                    return 1
                    ;;
                *:*)
                    PATH=${PATH%:*}
                    ;;
                *)
                    # shellcheck disable=SC2123
                    PATH=
                    ;;
            esac
            ;;

        # Check whether a directory is in PATH
        check)
            path _argcheck "$@" || return
            if ! [ "$#" -eq 2 ] ; then
                set -- "$1" "$PWD"
            fi
            case :$PATH: in
                *:"$2":*) return 0 ;;
            esac
            return 1
            ;;

        # Print help output (also done if command not found)
        help)
            cat <<'EOF'
path(): Manage contents of PATH variable

USAGE:
  path [list]
    Print the current directories in PATH, one per line (default)
  path insert [DIR]
    Add directory DIR (default $PWD) to the front of PATH
  path append [DIR]
    Add directory DIR (default $PWD) to the end of PATH
  path remove [DIR]
    Remove directory DIR (default $PWD) from PATH
  path shift
    Remove the first directory from PATH
  path pop
    Remove the last directory from PATH
  path check [DIR]
    Return whether directory DIR (default $PWD) is in PATH
  path help
    Print this help message
EOF
            ;;

        # Command not found
        *)
            printf >&2 \
                'path(): %s: Unknown command (try "help")\n' \
                "$1"
            return 2
            ;;
    esac
}

# Our ~/.profile should already have made a directory with the supported
# options for us; if not, we won't be wrapping ls(1) with a function at all
[ -d "$HOME"/.cache/sh/opt/ls ] || return

# If the system has already aliased ls(1) for us, like Slackware or OpenBSD
# does, just get rid of it
unalias ls >/dev/null 2>&1

# Discard GNU ls(1) environment variables if the environment set them
unset -v LS_OPTIONS LS_COLORS

# Define function proper
ls() {

    # POSIX options:
    ## -F to show trailing indicators of the filetype
    ## -q to replace control chars with '?'
    set -- -Fq "$@"
    ## -x to format entries across, not down, if output looks like a terminal
    if [ -t 1 ] ; then
        set -- -x "$@"
    fi

    # GNU options:
    ## Add --block-size=K to always show the filesize in kibibytes
    if [ -e "$HOME"/.cache/sh/opt/ls/block-size ] ; then
        set -- --block-size=1024 "$@"
    fi
    ## Add --color if the terminal has at least 8 colors
    if [ -e "$HOME"/.cache/sh/opt/ls/color ] &&
            [ "$(exec 2>/dev/null;tput colors||tput Co||echo 0)" -ge 8 ] ; then
        set -- --color=auto "$@"
    fi
    ## Force the new entry quoting off
    if [ -e "$HOME"/.cache/sh/opt/ls/quoting-style ] ; then
        set -- --quoting-style=literal "$@"
    fi
    ## Add --time-style='+%Y-%m-%d %H:%M:%S' to show the date in my preferred
    ## (fixed) format
    if [ -e "$HOME"/.cache/sh/opt/ls/time-style ] ; then
        set -- --time-style='+%Y-%m-%d %H:%M:%S' "$@"
    fi

    # Run ls(1) with the concluded arguments
    command ls "$@"
}

