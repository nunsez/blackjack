ARG ELIXIR_VERSION
FROM "elixir:${ELIXIR_VERSION}"

# install build dependencies
RUN apt-get update --yes && apt-get install --yes \
    build-essential \
    curl \
    git \
    inotify-tools \
    locales \
    make \
    nano \
    sudo \
    vim \
    && apt-get clean

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

ARG USERNAME="dev"
ARG USER_UID
ARG USER_GID="${USER_UID}"

# Create the docker user with non-root privilegies
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USERNAME} --shell /bin/bash \
    # Add sudo support
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USER_UID}

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV PROJECT_ROOT="/app"
ENV HISTFILE="${PROJECT_ROOT}/tmp/.bash_history"

WORKDIR ${PROJECT_ROOT}
