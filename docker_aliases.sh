# ------------------------------------
# Docker alias and function
# ------------------------------------

# Get latest container ID
alias dl="docker ps -l --quiet"

# Get container logs
alias dlogs="docker logs"

# Get container process
alias dps="docker ps"

# Get process included stop container
alias dpsa="docker ps --all"

# List container images
alias dimgs="docker images"

# Get container IP address
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Get container process ID
alias dpid="docker inspect --format '{{ .State.Pid }}'"

# ping to a container
dping() {
    local container=$1
    local return_code

    container_id=$(did "$1" 2> /dev/null)
    return_code=$?
    if [ "$return_code" != "0" ]; then
        echo "Usage: ${FUNCNAME[0]} CONTAINER_ID_OR_NAME " 1>&2
        return $return_code
    fi

    ping "$(dip $container_id)"
}

alias drun="docker run"

# Run deamonized container. e.g. $ drund base /bin/echo hello
alias drund="docker run --detach --tty"

# Run interactive container. e.g. $dki base /bin/bash
alias drunit="docker run --interactive --tty"
#alias druni="docker run --interactive --tty -P"

# Execute interactive container, e.g., $dex base /bin/bash
alias dexec="docker exec --interactive --tty"

# Get container ID from name/ID/image
did() {
    local container=$1

    if [ "$container" = "" ]; then
        echo "Usage: ${FUNCNAME[0]} CONTAINER_ID_OR_NAME " 1>&2
        return 22
    fi

    # try to convert from container name to id
    container_id=$(dps --quiet --filter name="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    # try to convert from container image to id
    container_id=$(dps --quiet --filter ancestor="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    # check weather exist id
    container_id=$(dps --quiet --filter id="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    echo "$container not found " 1>&2

    return 22
}

# Get container ID from name/ID/image
dida() {
    local container=$1

    if [ "$container" = "" ]; then
        echo "Usage: ${FUNCNAME[0]} CONTAINER_ID_OR_NAME " 1>&2
        return 22
    fi

    # try to convert from container name to id
    container_id=$(dpsa --quiet --filter name="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    # try to convert from container image to id
    container_id=$(dpsa --quiet --filter ancestor="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    # check weather exist id
    container_id=$(dpsa --quiet --filter id="$container")
    if [ "$container_id" != "" ]; then
        echo "$container_id"
        return 0
    fi

    echo "$container not found " 1>&2

    return 22
}

# Convert container id to container name
didtoname() {
    local container_id

    container_id=$(dida "$1") && dpsa --filter id="$container_id" --format "{{ .Names }}"
}

# Stop containers
dstop() {
    local container=$1

    if [ "$container" = "" ]; then
        echo "Usage: ${FUNCNAME[0]} CONTAINER_ID_OR_NAME " 1>&2
        return 22
    fi

    docker stop $(did "$container" | tr '\n' ' ')
}

# Stop and remove container(s)
drm() {
    local container_id

    container_id=$(did "$1" 2> /dev/null)
    if [ "$?" = "0" ]; then
        docker stop $($container_id | tr "\n" " ")
    fi

    docker rm $1
}

# Stop and remove all of the containers
alias drmall='docker stop $(dpsa --quiet) --time 5 && docker rm $(dpsa --quiet)'


# Remove all of the containers which Exited/Created status
dclean() {
    local container

    container=$(dpsa --filter "status=exited" --filter "status=created" --quiet)

    if [ "$container" = "" ]; then
        return 0
    fi

    # shellcheck disable=SC2086
    docker rm $container
}

# Remove all images
#dri() { docker rmi $(docker images --quiet); }

# Dockerfile build, e.g., $dbu tcnksm/test
dbuild() { docker build --tag="$1" .; }

# Show all alias related docker
dalias() { alias | \grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }

# Bash into running container
dbash() {
    local container_id

    container_id=$(did "$1") && docker exec -it $(dpsa -q --filter id="$container_id") bash
}

# Print Docker service journal
alias dockerdlog='journalctl --unit docker.service'
