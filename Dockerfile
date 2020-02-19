FROM ubuntu:latest

COPY root root

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install wget zsh git nano vim build-essential \
                       python3-dev python-pip libtool autotools-dev \
                       automake pkg-config

RUN mkdir -p /root

# Setup ZSH for those who prefer it
ENV TERM xterm
ENV ZSH_THEME agnoster
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN echo "source /root/set_constants.sh;" >> /root/.zshrc

# OpenOCD
WORKDIR "/root"
RUN git clone git://git.code.sf.net/p/openocd/code openocd-code
RUN apt-get -y install libusb-1.0-0-dev
WORKDIR "/root/openocd-code"
RUN ./bootstrap
RUN ./configure
RUN make
RUN make install
WORKDIR "/root"

# Project Trellis (libtrellis)
RUN git clone --recursive https://github.com/SymbiFlow/prjtrellis
RUN apt-get -y install cmake python3-pip libboost-all-dev
RUN pip3 install boost
WORKDIR "/root/prjtrellis/libtrellis"
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr .
RUN make
RUN make install
WORKDIR "/root"

# Yaosys
RUN export DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN apt-get install tzdata
RUN dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get -y install build-essential clang bison flex \
	libreadline-dev gawk tcl-dev libffi-dev git \
	graphviz xdot pkg-config python3 libboost-system-dev \
	libboost-python-dev libboost-filesystem-dev zlib1g-dev
RUN git clone https://github.com/YosysHQ/yosys.git
WORKDIR "/root/yosys"
RUN make config-gcc
RUN make
RUN make install
WORKDIR "/root"

# Nextpnr
RUN git clone https://github.com/YosysHQ/nextpnr.git
RUN apt-get -y install build-essential qtcreator qt5-default \
        qt5-doc qt5-doc-html qtbase5-doc-html qtbase5-examples
RUN apt-get -y install libeigen3-dev
WORKDIR "/root/nextpnr"
RUN cmake -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=/usr .
RUN make -j$(nproc)
RUN make install
WORKDIR "/root"

# RiscV GNU Toolchain
RUN apt-get -y install autoconf automake autotools-dev curl \
         python3 libmpc-dev libmpfr-dev libgmp-dev gawk \
         build-essential bison flex texinfo gperf libtool \
         patchutils bc zlib1g-dev libexpat-dev
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
WORKDIR "/root/riscv-gnu-toolchain"
RUN ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32
RUN make
RUN echo "export PATH=$PATH:/opt/riscv/bin" >> /root/.zshrc

# TESTING: Build Examples
WORKDIR /root/prjtrellis/examples/versa5g
RUN make

RUN apt-get -y install x11-apps
RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      policykit-1-gnome && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      dbus-x11 \
      lxde \
      lxlauncher \
      lxmenu-data \
      lxtask \
      procps \
      psmisc

# OpenGL / MESA
# adds 68 MB to image, disabled
RUN apt-get install -y mesa-utils mesa-utils-extra libxv1

# GTK 2 and 3 settings for icons and style, wallpaper
RUN echo '\n\
gtk-theme-name="Raleigh"\n\
gtk-icon-theme-name="nuoveXT2"\n\
' > /etc/skel/.gtkrc-2.0 && \
\
mkdir -p /etc/skel/.config/gtk-3.0 && \
echo '\n\
[Settings]\n\
gtk-theme-name="Raleigh"\n\
gtk-icon-theme-name="nuoveXT2"\n\
' > /etc/skel/.config/gtk-3.0/settings.ini && \
\
mkdir -p /etc/skel/.config/pcmanfm/LXDE && \
echo '\n\
[*]\n\
wallpaper_mode=stretch\n\
wallpaper_common=1\n\
wallpaper=/usr/share/lxde/wallpapers/lxde_blue.jpg\n\
' > /etc/skel/.config/pcmanfm/LXDE/desktop-items-0.conf && \
\
mkdir -p /etc/skel/.config/libfm && \
echo '\n\
[config]\n\
quick_exec=1\n\
terminal=lxterminal\n\
' > /etc/skel/.config/libfm/libfm.conf && \
\
mkdir -p /etc/skel/.config/openbox/ && \
echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<theme>\n\
  <name>Clearlooks</name>\n\
</theme>\n\
' > /etc/skel/.config/openbox/lxde-rc.xml && \
\
mkdir -p /etc/skel/.config/ && \
echo '[Added Associations]\n\
text/plain=mousepad.desktop;\n\
' > /etc/skel/.config/mimeapps.list

RUN echo "#! /bin/bash\n\
echo 'x11docker/lxde: If the panel does not show an appropriate menu\n\
  and you encounter high CPU usage (seen with kata-runtime),\n\
  please run with option --init=systemd.\n\
' >&2 \n\
startlxde\n\
" >/usr/local/bin/start && chmod +x /usr/local/bin/start


# QtcVerilog
RUN apt-get -y install qtbase5-dev unzip qttools5-dev
RUN mkdir /opt/qtverilog
WORKDIR "/opt/qtverilog"
RUN wget https://github.com/rochus-keller/QtcVerilog/archive/master.zip
RUN unzip master.zip
RUN rm master.zip
RUN mv QtcVerilog-master QtcVerilog
WORKDIR "/opt/qtverilog/QtcVerilog"
RUN qmake -r
RUN make
# RUN echo "export PATH=$PATH:/opt/qtverilog/QtcVerilog/bin" >> /root/.zshrc
WORKDIR "/opt/qtverilog"
RUN wget https://github.com/rochus-keller/VerilogCreator/archive/master.zip && unzip master.zip && rm master.zip
RUN wget https://github.com/rochus-keller/Verilog/archive/master.zip && unzip master.zip && rm master.zip
RUN wget https://github.com/rochus-keller/Sdf/archive/master.zip && unzip master.zip && rm master.zip
RUN wget http://software.rochus-keller.info/tcl_headers.zip
RUN mv Sdf-master Sdf
RUN mv Verilog-master Verilog
RUN mv VerilogCreator-master VerilogCreator
RUN unzip tcl_headers.zip -d tcl
RUN export QTC_SOURCE=/opt/qtverilog/QtcVerilog
RUN export QTC_BUILD=/usr/bin
WORKDIR "/opt/qtverilog/VerilogCreator"
RUN qmake VerilogCreator.pro
# RUN make

# Apply example fixes
WORKDIR "/root/prjtrellis"
COPY fix_make.patch fix_make.patch
RUN git apply fix_make.patch

# Build example test projects
WORKDIR /root/prjtrellis/examples/picorv32_versa5g
RUN export PATH=$PATH:/opt/riscv/bin && make attosoc.svf
WORKDIR /root/prjtrellis/examples/soc_versa5g
RUN export PATH=$PATH:/opt/riscv/bin && make attosoc.svf
WORKDIR "/root"

# Chisel3 HDL
RUN apt-get -y install default-jdk
RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
RUN apt-get update
RUN apt-get -y install sbt
RUN apt-get -y install git make autoconf g++ flex bison
RUN git clone http://git.veripool.org/git/verilator
WORKDIR /root/verilator
RUN git pull
# RUN git checkout verilator_4_016
RUN unset VERILATOR_ROOT && autoconf && ./configure
RUN make && make install
WORKDIR "/root"

# Sample Project Working Dir
RUN mkdir /root/ChiselProjects
WORKDIR /root/ChiselProjects
RUN git clone https://github.com/ucb-bar/chisel-template.git MyChiselProject
WORKDIR /root/ChiselProjects/MyChiselProject
RUN rm -rf .git
RUN git init
RUN git add .gitignore *
RUN git commit -m 'Starting MyChiselProject'
RUN sbt 'testOnly gcd.GCDTester -- -z Basic'

CMD ["/usr/local/bin/start"]
