set ignore-comments

import "./compose.justfile"

project_root := env("PROJECT_ROOT", justfile_directory())
compose_file := env("COMPOSE_FILE", join(justfile_directory(), "docker", "dev", "compose.yml"))

default:
  @just --list

lg:
  lazygit --path {{project_root}}

setup:
  just build
  just install-deps
  echo "The project was successfully configured."

build:
  USER_UID=$(id --user) USER_GID=$(id --group) docker compose --progress tty --file {{compose_file}} build

install-deps:
  docker compose --file {{compose_file}} run --rm app mix setup

prod-build tag release_cookie="":
  docker build \
    --build-arg RELEASE_COOKIE="{{release_cookie}}" \
    --file {{join(project_root, "docker", "prod", "Dockerfile")}} \
    --tag "{{tag}}" {{project_root}}
