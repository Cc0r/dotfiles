# Make pushd default to $HOME if no arguments given, much like cd
pushd() {
    # shellcheck disable=SC2164
    builtin pushd "${@:-"$HOME"}"
}

# Requires Bash >= 4.0 for read -i and ${!name}
((BASH_VERSINFO[0] >= 4)) || return

# Edit named variables' values
vared() {
    local opt prompt
    local OPTERR OPTIND OPTARG
    while getopts 'p:' opt ; do
        case $opt in
            p)
                prompt=$OPTARG
                ;;
            \?)
                printf 'bash: %s: -%s: invalid option\n' \
                    "${FUNCNAME[0]}" "$opt" >&2
                return 2
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    if ! (($#)) ; then
        printf 'bash: %s: No variable names given\n' \
            "${FUNCNAME[0]}" >&2
        return 2
    fi
    local name
    for name do
        IFS= read -e -i "${!name}" -p "${prompt:-"$name"=}" -r -- "${name?}"
    done
}


# Shortcut to show current shell version
ver() {
    printf '%s\n' "${BASH_VERSION:-unknown}"
}

which() {
    printf >&2 'Whichcraft detected! Did you mean: type -P %s\n' "$*"
    return 2
}
