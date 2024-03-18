in service="app":
  docker compose --file {{compose_file}} run --rm {{service}} /bin/bash

attach service="app":
  docker attach "$(just --quiet image-name {{service}})"

up:
  docker compose --file {{compose_file}} up --detach

down:
  docker compose --file {{compose_file}} down --remove-orphans

restart service="app":
  docker compose --file {{compose_file}} restart {{service}}

logs service="":
  docker compose --file {{compose_file}} logs --follow {{service}}

remove-dangling:
  if [ -n "$(docker images --filter='dangling=true' --quiet)" ]; then \
    docker rmi $(docker images --filter='dangling=true' --quiet); \
  fi

[private]
image-name service:
  docker compose --file {{compose_file}} images | grep --regexp='.*-{{service}}' | cut --delimiter=' ' --fields=1 | head --lines=1
