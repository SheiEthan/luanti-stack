FROM debian:bookworm-slim AS builder

# Dependances de compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake g++ make \
    libirrlicht-dev libgettextpo-dev libfreetype6-dev \
    libsqlite3-dev libleveldb-dev libhiredis-dev \
    libcurl4-openssl-dev liblua5.1-0-dev libluajit-5.1-dev \
    libpng-dev libjpeg-dev libzstd-dev zlib1g-dev \
    libprotobuf-dev protobuf-compiler \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Compiler prometheus-cpp depuis les sources (pas dispo dans les repos Debian)
WORKDIR /build
RUN git clone --depth 1 --branch v1.1.0 https://github.com/jupp0r/prometheus-cpp.git \
    && cd prometheus-cpp \
    && git submodule init && git submodule update --depth 1 \
    && mkdir build && cd build \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_TESTING=OFF \
        -DENABLE_PUSH=OFF \
        -DENABLE_COMPRESSION=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    && make -j$(nproc) \
    && make install

# Clone Luanti (anciennement Minetest)
RUN git clone --depth 1 --branch 5.11.0 https://github.com/minetest/minetest.git luanti

# Compilation avec support Prometheus active
WORKDIR /build/luanti
RUN cmake . \
    -DBUILD_SERVER=TRUE \
    -DBUILD_CLIENT=FALSE \
    -DENABLE_PROMETHEUS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DRUN_IN_PLACE=FALSE \
    && make -j$(nproc) \
    && make install

# Telecharger Backroomtest game
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends curl unzip && rm -rf /var/lib/apt/lists/* && \
    curl -sL https://content.luanti.org/packages/Sumianvoice/backroomtest/releases/33970/download/ -o backroomtest.zip && \
    unzip -q backroomtest.zip -d /usr/local/share/luanti/games/ && \
    rm backroomtest.zip

#Runtime - Image legere pour execution
FROM debian:bookworm-slim

# Dependances runtime uniquement (pas besoin de prometheus-cpp en .so, lié statiquement)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 libleveldb1d libhiredis0.14 \
    libcurl4 libluajit-5.1-2 libfreetype6 libpng16-16 libjpeg62-turbo \
    libzstd1 zlib1g libprotobuf32 libncursesw6 \
    && rm -rf /var/lib/apt/lists/*

# Copier le binaire, les libs prometheus-cpp et le game depuis le stage builder
COPY --from=builder /usr/local/bin/minetestserver /usr/local/bin/luantiserver
COPY --from=builder /usr/local/lib/libprometheus* /usr/local/lib/
COPY --from=builder /usr/local/share/luanti /usr/local/share/luanti

# Mettre a jour le cache des libs dynamiques
RUN ldconfig

# Creer les repertoires necessaires
RUN mkdir -p /etc/minetest /var/lib/minetest/worlds /usr/local/share/luanti/games

# Exposer les ports (UDP pour le jeu, TCP pour les metriques Prometheus)
EXPOSE 30000/udp
EXPOSE 30000/tcp

# Lancer le serveur
CMD ["luantiserver", "--config", "/etc/minetest/minetest.conf", "--gameid", "backroomtest", "--worldname", "world"]