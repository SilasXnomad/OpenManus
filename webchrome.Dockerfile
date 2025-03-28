FROM ubuntu:24.04

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
# Set display for X11
ENV DISPLAY=:0
# Set environment for D-Bus
ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket

# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    x11vnc \
    xvfb \
    dbus \
    dbus-x11 \
    ca-certificates \
    openbox \
    pulseaudio \
    git \
    python3 \
    python3-pip \
    net-tools

# 添加 Google Chrome 存储库
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable git curl python3.12-venv

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置 VNC 密码
RUN mkdir ~/.vnc \
    && x11vnc -storepasswd 1234 ~/.vnc/passwd

# Install noVNC for HTTP access to VNC
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify /opt/novnc/utils/websockify

# Create the startup script
RUN echo '#!/bin/bash\n\
# Start system bus\n\
mkdir -p /var/run/dbus\n\
/usr/bin/dbus-daemon --system --nofork --nopidfile &\n\
sleep 1\n\
\n\
# Start session bus\n\
/usr/bin/dbus-daemon --session --nofork --print-address 2 --nopidfile &\n\
sleep 1\n\
\n\
# Start Xvfb\n\
Xvfb :0 -screen 0 1920x1080x24 &\n\
sleep 2\n\
\n\
# Start window manager\n\
openbox &\n\
\n\
# Start VNC server\n\
x11vnc -display :0 -usepw -forever &\n\
\n\
# Start noVNC web server\n\
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &\n\
\n\
# Start Chrome with appropriate flags\n\
google-chrome --display=:0 --no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --disable-setuid-sandbox\n\
' > /start.sh \
    && chmod +x /start.sh

# 设置工作目录
WORKDIR /app

COPY . .

RUN python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

EXPOSE 5900 9222 6080 8080
CMD ["/bin/bash", "-c", "/start.sh && .venv/bin/python3 app.py"]

# docker build -t silasxnomad/openmanus:v0.0.1 .
# docker push silasxnomad/openmanus:v0.0.1
# docker run -d -p 5900:5900 -p 9222:9222 -p 6080:6080 -p 8080 --name temp temp
