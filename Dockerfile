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


# TESTING: Build Examples
WORKDIR /root/prjtrellis/examples/versa5g
RUN make

ENTRYPOINT zsh
