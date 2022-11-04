FROM alpine

RUN apk add --no-cache curl jq bash
RUN curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.2.2/clusterctl-linux-amd64 -o /usr/local/bin/clusterctl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v1.25.3/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/clusterctl /usr/local/bin/kubectl
