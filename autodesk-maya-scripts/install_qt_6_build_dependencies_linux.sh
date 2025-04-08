# Red Hat Enterprise Linux 8.6 (or Rocky Linux 8.6)

# Install dependencies to build Qt
sudo yum install -y gperf
sudo yum install -y patchel
sudo yum install -y libicu-devel
sudo yum install -y libpqxx-devel
sudo yum install -y mesa-libGL-devel 
sudo yum install -y mesa-libGLU-devel 
sudo yum install -y mesa-libGLw-devel
sudo yum install -y mesa-libEGL-devel
sudo yum install -y alsa-lib-devel 
sudo yum install -y alsa-plugins-pulseaudio 
sudo yum install -y alsa-utils
sudo yum install -y pulseaudio-libs-devel	
sudo yum install -y audiofile-devel	
sudo yum install -y PackageKit-gstreamer-plugin 
sudo yum install -y gstreamer1-devel
sudo yum install -y gstreamer1-plugins-base-devel
sudo yum install -y gstreamer1-plugins-good
sudo yum install -y dbus-devel
sudo yum install -y fontconfig-devel
sudo yum install -y cups-devel
sudo yum install -y libmng-devel
sudo yum install -y libdrm
sudo yum install -y libcap-devel
sudo yum install -y nss-devel
sudo yum install -y libXcomposite-devel
sudo yum install -y libXcursor-devel
sudo yum install -y libXtst-devel
sudo yum install -y libXScrnSaver
sudo yum install -y libXp-devel 
sudo yum install -y libXi-devel 
sudo yum install -y libXinerama-devel 
sudo yum install -y libXpm-devel 
sudo yum install -y libXrandr-devel
sudo yum install -y libXext-devel
sudo yum install -y libXfixes-devel
sudo yum install -y libXrender-devel
sudo yum install -y libxshmfence-devel
sudo yum install -y flite-devel
sudo yum install -y speech-dispatcher-devel
sudo yum install -y libX11-devel
sudo yum install -y libxkbcommon-devel  
sudo yum install -y libxkbcommon-x11-devel
sudo yum install -y freetype-devel
sudo yum install -y libxcb-devel
sudo yum install -y xcb-util-keysyms-devel
sudo yum install -y xcb-util-image-devel
sudo yum install -y xcb-util-wm-devel
sudo yum install -y xcb-util-renderutil-devel
sudo yum install -y xcb-util-devel

# Install additional dependencies required to build PySide6
sudo yum install -y python-setuptools
sudo yum install -y python-devel
