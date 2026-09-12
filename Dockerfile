FROM ubuntu:26.04
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 libgcc-s1 libgomp1 libssl3t64 libzstd1 libz1 curl || \
    apt-get install -y --no-install-recommends libstdc++6 libgcc-s1 libgomp1 libssl3 libzstd1 libz1 curl; \
    rm -rf /var/lib/apt/lists/*
COPY bin/llama-server /usr/local/bin/llama-server
COPY bin/llama-cli /usr/local/bin/llama-cli
COPY lib/*.so* /usr/local/lib/
COPY lib/*.so* /usr/local/bin/
ENV LD_LIBRARY_PATH=/usr/local/lib
VOLUME ["/models"]
EXPOSE 8080
COPY entrypoint.sh /entrypoint.sh
COPY entrypoint-qwen.sh /entrypoint-qwen.sh
COPY entrypoint-qwen36.sh /entrypoint-qwen36.sh
RUN chmod +x /entrypoint.sh /entrypoint-qwen.sh /entrypoint-qwen36.sh
ENTRYPOINT ["/entrypoint.sh"]
