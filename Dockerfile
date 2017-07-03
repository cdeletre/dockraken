FROM ubuntu:16.04
LABEL name="dockraken"
LABEL maintener="cdeletre"
LABEL description="An ubuntu-based and docker image of kraken A5/1 tools"

# Environement Variables:
# - TZ: Container timezone (default: Europe/Paris)
# - USERNAME: Container username (default: kraken)

# Update the package index and install minimal packages
RUN apt-get update && apt-get -y install tzdata sudo

# Setting up Paris FR TZ
RUN ln -snf /usr/share/zoneinfo/${TZ:-Europe/Paris} /etc/localtime \
&& echo ${TZ:-Europe/Paris} > /etc/timezone


# Add a user account 'kraken' with default password 'kraken'
RUN adduser --disabled-password --gecos '' ${USER:-kraken}
RUN echo "${USER:-kraken}:kraken" | chpasswd
RUN usermod -a -G sudo ${USER:-kraken}
RUN echo "${USER:-kraken} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_${USER:-kraken}-nopasswd

# Switch to kraken user
USER ${USER:-kraken}
WORKDIR /home/${USER:-kraken}

# Copy and extract kraken tools
COPY ressources/kraken.tgz .
RUN tar -xzf kraken.tgz
RUN mv kraken tools

# Expose kraken port
EXPOSE 1982

# Switch to Kraken directory (kraken looks for ./A5Cpu.so library)
WORKDIR /home/${USER:-kraken}/tools/Kraken/

# Start kraken server listening on TCP port 1982
ENTRYPOINT /home/${USER:-kraken}/tools/Kraken/kraken /home/${USER:-kraken}/tools/indexes 1982
