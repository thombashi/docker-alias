#----------------------------------------------
# Docker alias and functions
#   https://github.com/thombashi/docker-alias
#----------------------------------------------

if command -v fzf > /dev/null 2>&1 ; then
    SELECTOR=\fzf
elif command -v peco > /dev/null 2>&1 ; then
    SELECTOR=\peco
else
    SELECTOR=
fi

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

sel-dimg-tag() {
    if ! command -v "$SELECTOR" > /dev/null 2>&1; then
        echo "${FUNCNAME[0]}: require fzf|peco" 1>&2
        return 1
    fi

    docker images | $SELECTOR | awk '{print $1,$2}' OFS=:
}

sel-dimg-id() {
    if ! command -v "$SELECTOR" > /dev/null 2>&1; then
        echo "${FUNCNAME[0]}: require fzf|peco" 1>&2
        return 1
    fi

    docker images | $SELECTOR | awk '{print $3}'
}

# Stop containers
dstop() {
    local container=$1

    if [ "$container" = "" ] && [ "$SELECTOR" != "" ]; then
        container=$(dps | $SELECTOR | awk '{print $1}')
    fi

    if [ "$container" = "" ]; then
        return 0
    fi

    docker stop $(did "$container" | tr '\n' ' ')
}

# Stop and remove container(s)
drmi() {
    local image_id=$1
    local container_id

    if [ "$image_id" = "" ] && [ "$SELECTOR" != "" ]; then
        image_id=$(sel-dimg-id)
    fi

    if [ "$image_id" = "" ]; then
        return 0
    fi

    # stop running containers which created by the selected docker image
    container_id=$(dps --quiet --filter ancestor="$image_id" | tr '\n' ' ')
    if [ "$container_id" != "" ]; then
        # shellcheck disable=SC2086
        docker stop $container_id
    fi

    container_id=$(dpsa --quiet --filter "status=exited" --filter ancestor="$image_id")
    if [ "$container_id" != "" ]; then
        # shellcheck disable=SC2086
        docker rm $container_id
    fi

    # shellcheck disable=SC2086
    docker rmi $image_id
}

# Stop and remove all of the containers
alias drmall='docker stop $(dpsa --quiet) --time 5 && docker rm $(dpsa --quiet)'


# Remove all of the containers which Exited/Created status
dclean() {
    local container

    # find not executed docker containers
    container=$(dpsa --filter "status=exited" --filter "status=created" --quiet)

    if [ "$container" != "" ]; then
        # shellcheck disable=SC2086
        docker rm $container
    fi

    dprecated_images=$(docker images | \grep '<none>' | awk '{print $3}')

    if [ "$dprecated_images" != "" ]; then
        # shellcheck disable=SC2086
        docker rmi $dprecated_images
    fi
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
