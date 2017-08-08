function extract_remote_script {
    awk "/^[[:space:]]*$*/,EOF" |tail -n +2
}

function route_deploy_start {
    if ! [[ "$target" =~ [-_.[:alnum:]]+@[0-9.]+ ]]; then
        echo "参数错误: \`$target', 示例: ./$(basename $0) admin@192.168.1.1"
        exit
    fi

    local preinstall="$(cat ${0%/*}/functions/$FUNCNAME.sh |sed -e "1,/^export -f $FUNCNAME/d")
$export_hooks
export target=$target
export targetip=$(echo $target |cut -d'@' -f2)
echo '***********************************************************'
echo Remote deploy scripts is started !!
echo '***********************************************************'
set -ue
"
    local deploy_script="$preinstall$(cat $0 |extract_remote_script $FUNCNAME)"

    if ! [ "$SSH_CLIENT$SSH_TTY" ]; then
        set -ue
        scp -r route/* $target:/
        ssh $target 'opkg install bash'
        ssh $target /opt/bin/bash <<< "$deploy_script"
        exit 0
    fi
}

export -f route_deploy_start

function add_service {
    [ -e /jffs/scripts/$1 ] || echo '#!/bin/sh' > /jffs/scripts/$1
    chmod +x /jffs/scripts/$1
    fgrep -qs -e "$2" /jffs/scripts/$1 || echo "$2" >> /jffs/scripts/$1
}

function regexp_escape () {
    sed -e 's/[]\/$*.^|[]/\\&/g'
}

function replace_escape () {
    sed -e 's/[\/&]/\\&/g'
}

function replace_string () {
    local regexp="$(echo "$1" |regexp_escape)"
    local replace="$(echo "$2" |replace_escape)"
    local config_file=$3

    sed -i -e "s/$regexp/$replace/g" "$config_file"
}

function replace_regex () {
    local regexp=$1
    local replace="$(echo "$2" |replace_escape)"
    local config_file=$3

    sed -i -e "s/$regexp/$replace/g" "$config_file"
}

function __export () {
    export_hooks="$export_hooks $@"
    builtin export "$@"
}
alias export=__export
