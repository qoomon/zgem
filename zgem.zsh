autoload +X -U colors && colors

########################## zgem #########################
ZGEM_VERBOSE="${ZGEM_VERBOSE:-false}"

# Variable Modifiers
# :h - like dirname
# :t - like basename
# %  - remove smallest matching pattern from end of value

declare -rx ZGEM_HOME=${ZGEM_HOME:-"$HOME/.zgem"}

declare -rx ZGEM_GEM_DIR=${ZGEM_GEM_DIR:-"$ZGEM_HOME/gems"}

ZGEM_UTILS_DIR=${ZGEM_UTILS_DIR:-"$HOME"}

declare -aU zgems=()

function zgem {
  local cmd="$1"
  shift

  case "$cmd" in
    'bundle')
      __zgem::bundle $@
      ;;
    'list')
      __zgem::list $@
      ;;
    'update')
      __zgem::update $@
      __zgem::reload
      ;;
    'upgrade')
      __zgem::upgrade $@
      __zgem::reload
      ;;
    'clean')
      __zgem::clean $@
      ;;
    *)
      __zgem::log error "Unknown command '$cmd'"
      __zgem::log error "Usage: $0 {bundle|source|update|clean}"
      return 1
      ;;
  esac
}

function __zgem::reload {
  exec "$SHELL" -l
}

function __zgem::clean {

  if [[ -n "$1" ]]; then
    local gem_name="$1"
    __zgem::log info "Press ENTER to remove gem '$gem_name' from '$ZGEM_GEM_DIR/$gem_name'..." && read
    rm -rf "$ZGEM_GEM_DIR/$gem_name"
  else
    __zgem::log info "Press ENTER to remove all gems from '$ZGEM_GEM_DIR/'..." && read
    rm -rf "$ZGEM_GEM_DIR"
  fi
}

function __zgem::list {
  for gem_path in $zgems; do
    __zgem::log info "${fg_bold[magenta]}${gem_path:t} ${fg_bold[black]}($gem_path)${reset_color}";
  done
}

function __zgem::list_gem {
  local gem_name=$1
  local gem_dir="$ZGEM_GEM_DIR/$gem_name"
  __zgem::log info "${fg_bold[magenta]}${gem_name} ${fg_bold[black]}($gem_dir)${reset_color}";
}

function __zgem::bundle {
  
  if [[ "$1" == 'all' ]]; then
    for file in "$ZGEM_UTILS_DIR/"*'.zsh'; do
      __zgem::bundle "$file"
    done
    return 0
  fi

  if [[ "$1" != */* ]]; then
    __zgem::bundle "$ZGEM_UTILS_DIR/$1.zsh"
    return $status
  fi

  local location="$1"
  shift
  ################ parse parameters ################

  local protocol
  local gem_file
  local gem_type='plugin'
  for param in "$@"; do
    local param_key=${param[(ws|:|)1]}
    local param_value=${param[(ws|:|)2]}

    case "$param_key" in
      'from')
        protocol=$param_value
        ;;
      'use')
        gem_file=$param_value
        ;;
      'as')
        gem_type=$param_value
        ;;
      *)
        __zgem::log error "Unknown parameter '$param_key'"
        __zgem::log error "Parameter: {from|use|as}"
        return 1
        ;;
    esac
  done
    
  if [[ -z $protocol ]]; then
    ### determin default protocol
    if [[ $location = *'.git' ]]; then
      protocol='git'
    elif [[ $location = 'https://' ]] || [[ $location = 'http://' ]]; then
      protocol='http'
    else
      protocol='file'
    fi
  fi

  if [[ -z $gem_file ]]; then
    ### determin default gem_file
    if [[ $protocol = 'git' ]]; then
      gem_file="${${location:t}%.git}.plugin.zsh"
    elif [[ $protocol = 'http' ]]; then
      gem_file=${location:t}
    else
      gem_file=${location:t}
    fi
  fi

  ################ determine gem dir and file ################
  local gem_name
  local gem_dir

  if [[ "$protocol" == 'file' ]]; then
    location=$(cd ${location:h} && echo "$PWD/${location:t}") # resolve relative path
    gem_name=${location:t}
    gem_dir=${location:h}
  elif type "__zgem::name::$protocol" > /dev/null; then
    gem_name="$(__zgem::name::$protocol "$location")"
    gem_dir="${ZGEM_GEM_DIR}/${gem_name}"
  else
    __zgem::log error "command not found '__zgem::name::$protocol'"
    return 1
  fi

  if [[ ! -e "$gem_dir" ]]; then
    if ! type "__zgem::download::$protocol" > /dev/null; then
      __zgem::log error "command not found '__zgem::download::$protocol'"
      return 1
    fi

    mkdir -p "$gem_dir"
    echo "$protocol" > "$gem_dir/.gem"
    __zgem::log info "${fg_bold[green]}download ${fg_bold[magenta]}${gem_name}${reset_color}\n       ${fg_bold[yellow]}into${reset_color} '$gem_dir'\n       ${fg_bold[yellow]}from${reset_color} $protocol '$location'"
    __zgem::download::$protocol "$location" "$gem_dir"
  fi
  

  ################ add gem ################
  local gem_path="$gem_dir/$gem_file"
  __zgem::log debug "${fg_bold[green]}add ${reset_color}${(r:10:: :)gem_type}${gem_type:10}   ${fg_bold[magenta]}${(r:32:: :)gem_name}${gem_name:32} ${fg_bold[black]}($gem_path)${reset_color}"

  if [[ "$protocol" == 'file' ]]; then
    zgems+=${gem_path}
  else
    zgems+=${gem_dir}
  fi

  case "$gem_type" in
    'plugin')
      source "$gem_path"
      ;;
    'completion')
      # only add if not present already
      [[ -z "${fpath[(r)${gem_path:h}]}" ]] && fpath+=${gem_path:h}
      ;;
    *)
      __zgem::log error  "Unknown gem type '$protocol'"
      __zgem::log error  "Gem Type: {plugin|completion}"
      return 1 ;;
  esac
}

function __zgem::update {
  local gem_name=$1
  if [[ -n "$gem_name" ]]; then
    __zgem::update_gem "$gem_name"
  else
    __zgem::log info "${fg_bold[green]}update ${fg_bold[black]}($ZGEM_HOME)${reset_color}";
    (cd "$ZGEM_HOME"; git pull; echo  "Last Commit Date : $(git log -1 --format=%cd)";  )
  fi
}

function __zgem::update_gem {
  local gem_name=$1
  local gem_dir="$ZGEM_GEM_DIR/$gem_name"
  local protocol="$(< "$gem_dir/.gem")"
  if type "__zgem::update::$protocol" > /dev/null; then
    local gem_name=${gem_dir:t}
    __zgem::log info "${fg_bold[green]}upgrade ${fg_bold[magenta]}${gem_name} ${fg_bold[black]}($gem_dir)${reset_color}";
    __zgem::update::$protocol $gem_dir
  else
    __zgem::log error "command not found '__zgem::upgrade::$protocol' gem directory: '${gem_dir}'"
  fi
}

function __zgem::upgrade {
  __zgem::update
  for gem_path in ${(M)zgems:#$ZGEM_GEM_DIR*}; do
    __zgem::update ${gem_path:t}
  done
}

function __zgem::log {
  local level="$1"
  shift

  case "$level" in
    'error')
      echo "${fg_bold[red]}[zgem]${reset_color}" $@ >&2
      ;;
    'info')
      echo "${fg_bold[blue]}[zgem]${reset_color}" $@
      ;;
    'debug')
      $ZGEM_VERBOSE && echo "${fg_bold[yellow]}[zgem]${reset_color}" $@
      ;;
    *)
      __zgem::log error "Unknown log level '$protocol'"
      __zgem::log error "Log Level: {error|info|debug}"
      ;;
  esac
}


############################# http ############################

function __zgem::name::http {
  local http_url="$1"
  echo ${http_url:t}
}

function __zgem::download::http {
  local http_url="$1"
  local gem_dir="$2"
  (
    cd "$gem_dir"
    echo "$http_url" > ".http" # store url into meta file for allow updating
    echo "Downloading into '$gem_dir'"
    curl -L -O "$http_url"
  )
}

function __zgem::update::http {
  local gem_dir="$1"
  (
    cd "$gem_dir"
    local http_url=$(< "$gem_dir/.http")
    local file_name=${http_url:t}
    local cksum_before=$(cksum "$file_name")
    curl -s -L -w %{http_code} -o "$file_name" -z "$file_name" $http_url | read -r response_code
    local cksum_after=$(cksum "$file_name")
    if [[ $response_code == '200' ]]; then
      if [[ $cksum_after != $cksum_before ]]; then
        echo "From $http_url"
        echo "Updated."
      else
        echo "Current file is up to date"
      fi
    elif [[ $response_code == '304' ]]; then
      echo "Current file is up to date"
    else
      __zgem::log error "http update error response code: $response_code from '$http_url'"
    fi
  )
}

############################# git #############################

function __zgem::name::git {
  local repo_url=${${1/%/#}[(ws:#:)1]} # get repo url without branch
  echo ${${repo_url:t}%'.git'}
}

function __zgem::download::git {  
  local repo_url=${${1/%/#}[(ws:#:)1]} # get repo url
  local repo_branch=${${1/%/#}[(ws:#:)2]} # get repo branch
  local gem_dir="$2"
  local clone_dir="git_repo"
  (
    cd "$gem_dir"
    git clone \
      ${(Q)=${repo_branch:+"--branch '$repo_branch'"}} \
      --single-branch  "$repo_url" "$clone_dir" \
    && mv "$clone_dir/"*(DN) . \
    && rmdir "$clone_dir"
  )
}

function __zgem::update::git {
  local gem_dir="$1"
  (
    cd "$gem_dir"
    local latest_commit_before=$(git rev-parse HEAD)
    git pull # --depth 1
    echo  "Last Commit Date : $(git log -1 --format=%cd)"; 
    local latest_commit_after=$(git rev-parse HEAD)
    if [ $latest_commit_after != $latest_commit_before ]; then
      git diff --name-status $latest_commit_before $latest_commit_after
    fi
  )
}
