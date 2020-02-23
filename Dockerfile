FROM osrf/ros:melodic-desktop-full-bionic

RUN apt update && apt full-upgrade -y && DEBIAN_FRONTEND=noninteractive apt install -y ros-melodic-joy \
    wget nano python-rosinstall python-rosinstall-generator python-wstool build-essential python-catkin-tools nano \
    xserver-xorg libccgnu2-1.8.0 libccrtp-dev libcommoncpp2-dev libgeographic-dev libgstreamer-plugins-base1.0-dev

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

USER developer
ENV HOME /home/developer

RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc

RUN sudo rosdep fix-permissions

USER root
COPY base.yaml /etc/ros/rosdep/base.yaml

RUN echo "yaml file:///etc/ros/rosdep/base.yaml\n$(cat /etc/ros/rosdep/sources.list.d/20-default.list)" > /etc/ros/rosdep/sources.list.d/20-default.list
USER developer

RUN rosdep update --verbose

RUN mkdir -p /home/developer/catkin_ws/src

RUN bash -c "source ~/.bashrc && cd /home/developer/catkin_ws/src && catkin_init_workspace"

RUN bash -c "source ~/.bashrc && cd /home/developer/catkin_ws && catkin_make"

RUN bash -c "source ~/.bashrc && mkdir -p /home/developer/ros_catkin_ws/src \
    && cd /home/developer/ros_catkin_ws/src \
    && catkin_init_workspace"

RUN bash -c "source ~/.bashrc && cd /home/developer/ros_catkin_ws/ && catkin_make"

COPY ./.rosinstall /home/developer/ros_catkin_ws/.

RUN bash -c "source ~/.bashrc && cd /home/developer/ros_catkin_ws/ \
    && rosws update \
    && rosdep install --from-paths src --ignore-src --rosdistro melodic -y \
    && catkin_make_isolated --install"

COPY ./.rosinstall_base /home/developer/catkin_ws/.rosinstall

RUN sudo rosdep fix-permissions
RUN sudo chown -R developer:developer /home/developer/ros_catkin_ws


RUN bash -c "source ~/.bashrc \
    && source /home/developer/ros_catkin_ws/install_isolated/setup.bash \
    && cd /home/developer/catkin_ws && rosws update"
RUN bash -c "source ~/.bashrc \
    && source /home/developer/ros_catkin_ws/install_isolated/setup.bash \
    && cd /home/developer/catkin_ws \
    && rosdep install --from-paths src --ignore-src --rosdistro melodic -y"
RUN bash -c "source ~/.bashrc \
    && source /home/developer/ros_catkin_ws/install_isolated/setup.bash \
    && cd /home/developer/catkin_ws && catkin_make install"

RUN sudo geographiclib-get-geoids best
RUN sudo ln -s /usr/local/share/GeographicLib/ /usr/share/GeographicLib

WORKDIR /home/developer/catkin_ws

RUN echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc

COPY arrows_hls.zip /home/developer/catkin_ws/src/.
COPY ucat_simulator.zip /home/developer/catkin_ws/src/.

RUN bash -c "source ~/.bashrc && cd src \
    && unzip ucat_simulator.zip"

RUN bash -c "source ~/.bashrc \
    && cd src \
    && unzip arrows_hls.zip \
    && rosmake auv_msgs"

RUN bash -c "source ~/.bashrc \
    && catkin_make --pkg tut_arrows_msgs"

RUN bash -c "source ~/.bashrc && catkin_make"

CMD roscore
