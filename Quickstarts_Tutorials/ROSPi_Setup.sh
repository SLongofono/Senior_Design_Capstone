sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' 

wget http://packages.ros.org/ros.key -O - | sudo apt-key add -

sudo apt-get update

sudo apt-get install ros-kinetic-desktop-full

sudo rosdep init

rosdep update

echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc

source ~/.bashrc

mkdir -p ~/catkin_workspace/src

cd catkin_workspace/src

catkin_init_workspace

cd ~/catkin_workspace/

catkin_make

source ~/catkin_workspace/devel/setup.bash

echo “source ~/catkin_workspace/devel/setup.bash” >> ~/.bashrc

export | grep ROS

source /opt/ros/kinetic/setup.bash
