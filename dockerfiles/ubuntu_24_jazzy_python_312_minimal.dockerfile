ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
ENV ROS_ROOT=/ros2_ws/jazzy_ws
ENV ROS_PYTHON_VERSION=3

ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG USERNAME=kaey
ARG WS_BASENAME=repo

# ----------------------------------------------------------
# User Setup
# ----------------------------------------------------------

RUN if id -u ${USER_UID} >/dev/null 2>&1; then userdel $(id -un ${USER_UID}); fi

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# ----------------------------------------------------------
# Base Dependencies
# ----------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    cmake \
    build-essential \
    gnupg2 \
    lsb-release \
    locales \
    python3-pip \
    python3-dev \
    python3-yaml \
    pkg-config \
    cmake-extras \
    ros-dev-tools \
    python3-rosinstall-generator \
    libtinyxml2-dev \
    libasio-dev \
    libcunit1-dev \
    libacl1-dev \
    liblttng-ust-dev \
    libbullet-dev \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Locale
# ----------------------------------------------------------

RUN locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

# ----------------------------------------------------------
# ROS repository
# ----------------------------------------------------------

RUN apt-get update && apt-get install -y curl gnupg lsb-release

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
 | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/ros2.list

# ----------------------------------------------------------
# Graphics + RViz dependencies
# ----------------------------------------------------------

RUN apt-get update && apt-get install -y \
    libboost-all-dev \
    libeigen3-dev \
    libqhull-dev \
    libassimp-dev \
    liboctomap-dev \
    libconsole-bridge-dev \
    libfcl-dev \
    libx11-dev \
    libxrandr-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libglew-dev \
    libgles2-mesa-dev \
    libopengl-dev \
    libfreetype-dev \
    libfontconfig1-dev \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libqt5core5a \
    libqt5gui5 \
    libqt5opengl5 \
    libqt5widgets5 \
    libxcursor-dev \
    libxinerama-dev \
    libxi-dev \
    libyaml-cpp-dev \
    libzzip-dev \
    freeglut3-dev \
    libogre-1.9-dev \
    libpng-dev \
    libjpeg-dev \
    python3-pyqt5.qtwebengine

# ----------------------------------------------------------
# Python dependencies
# ----------------------------------------------------------

RUN python3 -m pip install --break-system-packages setuptools==70.0.0

RUN python3 -m pip uninstall -y em empy || true
RUN python3 -m pip install --break-system-packages empy==3.3.4

RUN python3 -m pip install --break-system-packages -U \
    argcomplete \
    flake8-blind-except \
    flake8-builtins \
    flake8-class-newline \
    flake8-comprehensions \
    flake8-deprecated \
    flake8-docstrings \
    flake8-import-order \
    flake8-quotes \
    pytest-repeat \
    pytest-rerunfailures \
    pytest \
    lark

RUN python3 -m pip install --break-system-packages \
    numpy \
    pybind11 \
    PyYAML \
    "pybind11[global]"

# ----------------------------------------------------------
# ROS workspace
# ----------------------------------------------------------

RUN mkdir -p ${ROS_ROOT}/src

WORKDIR ${ROS_ROOT}

RUN rosinstall_generator \
    --deps \
    --rosdistro ${ROS_DISTRO} \
    rosidl_runtime_c \
    rcutils \
    rcl \
    rmw \
    tf2 \
    tf2_msgs \
    common_interfaces \
    geometry_msgs \
    nav_msgs \
    std_msgs \
    rosgraph_msgs \
    sensor_msgs \
    vision_msgs \
    rclpy \
    ros2topic \
    ros2pkg \
    ros2doctor \
    ros2run \
    ros2node \
    ros_environment \
    ackermann_msgs \
    example_interfaces \
    > ros2.${ROS_DISTRO}.rosinstall

RUN vcs import src < ros2.${ROS_DISTRO}.rosinstall

RUN rosdep init && rosdep update

RUN colcon build --merge-install

# ----------------------------------------------------------
# Secondary workspace
# ----------------------------------------------------------

RUN mkdir -p /ros2_ws/build_ws/src

# IMPORTANT:
# This path must exist in the build context
COPY src/IsaacSim-ros_workspaces/jazzy_ws/src /ros2_ws/build_ws/src

RUN rm -rf /ros2_ws/build_ws/src/moveit || true

WORKDIR /ros2_ws

RUN /bin/bash -c "source ${ROS_ROOT}/install/setup.bash && cd build_ws && colcon build"

# ----------------------------------------------------------
# User environment
# ----------------------------------------------------------

RUN mkdir -p /home/${USERNAME}/ros2_ws \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

RUN echo "source ${ROS_ROOT}/install/setup.bash" >> /home/${USERNAME}/.bashrc

USER ${USERNAME}

WORKDIR /home/${USERNAME}/ros2_ws

SHELL ["/bin/bash", "-c"]