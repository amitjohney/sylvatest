# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-12-12 01:30|kubeadm-capv|aaaed1e336e04dc97b03354da214f83a7bf0d6da|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-08 01:27|rke2-capv|cf2abc8699b09b53cce4272c9e3179dae00a3f90|:white_check_mark: success||
|2023-12-08 01:20|kubeadm-capv|cf2abc8699b09b53cce4272c9e3179dae00a3f90|:white_check_mark: success||
|2023-12-07 01:30|rke2-capv|9fa645ff8df097aed17b96b36d479405c103bbbf|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/bbf478df4327ea57ebdf93004f9cc95a/capv-logs.gz)|
|2023-12-07 01:20|kubeadm-capv|9fa645ff8df097aed17b96b36d479405c103bbbf|:white_check_mark: success||
|2023-12-06 01:30|rke2-capv|e3720333cf8f1d02cc898531b65d2e085e495bdf|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/ddc15edb0629f9add918ea900dcdd894/capv-logs.gz)|
|2023-12-06 01:20|kubeadm-capv|e3720333cf8f1d02cc898531b65d2e085e495bdf|:white_check_mark: success||
|2023-12-05 01:30|rke2-capv|0b75b88d82ec4091f656e77b66c5f6126240a266|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/6100fe0ed309c941919250900d3a98f4/capv-logs.gz)|
|2023-12-05 01:42|kubeadm-capv|0b75b88d82ec4091f656e77b66c5f6126240a266|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/6100fe0ed309c941919250900d3a98f4/capv-logs.gz)|
|2023-12-02 01:56|rke2-capv|72040834de9e2b4105df8cde6edb562ef0724a67|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/709a26e918301bcda178b18abae73b04/capv-logs.gz)|
|2023-12-02 01:13|kubeadm-capv|72040834de9e2b4105df8cde6edb562ef0724a67|:white_check_mark: success||
|2023-12-01 01:54|rke2-capv|009a92a3d9a2c3f263bb5d768e6acb735107e481|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7dc25dd52b91d42214a5acbcaebff15c/capv-logs.gz)|
|2023-12-01 01:14|kubeadm-capv|009a92a3d9a2c3f263bb5d768e6acb735107e481|:white_check_mark: success||
|2023-11-30 01:56|rke2-capv|836d61be5d69d19a88813db00a752515abf781d0|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3ed2a2ecdbf23c880dad03a45f977f9b/capv-logs.gz)|

