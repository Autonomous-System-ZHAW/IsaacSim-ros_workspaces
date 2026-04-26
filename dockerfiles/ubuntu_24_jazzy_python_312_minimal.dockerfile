FROM osrf/ros:jazzy-desktop-full-noble

ARG USERNAME=tommy
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG WS_BASENAME=repo

# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi

# Create the user + Basis-Setup
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        python3-pip python3-dev build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && mkdir -p /home/$USERNAME/ros2_ws/$WS_BASENAME \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/ros2_ws

ENV SHELL=/bin/bash

RUN usermod -a -G dialout ${USERNAME}

CMD ["/bin/bash"]