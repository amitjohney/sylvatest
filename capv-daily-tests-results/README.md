# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-03-01 01:30|rke2-capv|9c0de311540f3403aa4e718fa118354d9d4aff44|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4be085afc8ee1c96c862b760e8fd79b4/capv-logs.gz)|
|2024-03-01 01:30|kubeadm-capv|9c0de311540f3403aa4e718fa118354d9d4aff44|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4be085afc8ee1c96c862b760e8fd79b4/capv-logs.gz)|
|2024-02-29 01:57|rke2-capv|9525021e46af21a6f7dafc1b338a52afea50a0c9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4044c26e869842d3cb0c7d329ef4b88a/capv-logs.gz)|
|2024-02-29 01:57|kubeadm-capv|9525021e46af21a6f7dafc1b338a52afea50a0c9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4044c26e869842d3cb0c7d329ef4b88a/capv-logs.gz)|
|2024-02-28 01:31|rke2-capv|bdaf1aac2f9ed009a9e668b70a0a389f793b6f28|:white_check_mark:|:white_check_mark:||
|2024-02-28 01:30|kubeadm-capv|bdaf1aac2f9ed009a9e668b70a0a389f793b6f28|:white_check_mark:|:white_check_mark:||
|2024-02-27 01:32|rke2-capv|60ec6437ddf8b0f2bb8b6741888f9ef17c4d3da5|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/59fb08f3e9a4e83c0ae67515ce11fac0/capv-logs.gz)|
|2024-02-27 01:57|kubeadm-capv|60ec6437ddf8b0f2bb8b6741888f9ef17c4d3da5|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/59fb08f3e9a4e83c0ae67515ce11fac0/capv-logs.gz)|
|2024-02-24 01:57|rke2-capv|6ecae1585f14cd53be2fa86b38194ad9a636a33e|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/efc20827cc017b59863a1e384c0f7c04/capv-logs.gz)|
|2024-02-24 01:57|kubeadm-capv|6ecae1585f14cd53be2fa86b38194ad9a636a33e|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/efc20827cc017b59863a1e384c0f7c04/capv-logs.gz)|
|2024-02-23 01:57|rke2-capv|07b849013fbbdb8d39d31a5916dae88e52398de6|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/46b7d3a1d1f962c131a98a1949c9c790/capv-logs.gz)|
|2024-02-23 00:57|kubeadm-capv|07b849013fbbdb8d39d31a5916dae88e52398de6|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/46b7d3a1d1f962c131a98a1949c9c790/capv-logs.gz)|
|2024-02-22 11:11|rke2-capv|6cc4efa3867b4d80ae7c3f56c70d07b90cbae779|:white_check_mark:|:white_check_mark:||
|2024-02-22 11:06|kubeadm-capv|6cc4efa3867b4d80ae7c3f56c70d07b90cbae779|:white_check_mark:|:white_check_mark:||
|2024-02-22 01:33|rke2-capv|6cc4efa3867b4d80ae7c3f56c70d07b90cbae779|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7d96e31d8276263e6de7783e221f3971/capv-logs.gz)|
|2024-02-22 01:24|kubeadm-capv|6cc4efa3867b4d80ae7c3f56c70d07b90cbae779|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7d96e31d8276263e6de7783e221f3971/capv-logs.gz)|
|2024-02-21 01:32|rke2-capv|1dfe2ca46514a0fd2476da2259bd4c279897f282|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d162fdba5ca513c27f84ce0f8f35abe3/capv-logs.gz)|
|2024-02-21 01:30|kubeadm-capv|1dfe2ca46514a0fd2476da2259bd4c279897f282|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d162fdba5ca513c27f84ce0f8f35abe3/capv-logs.gz)|
|2024-02-20 01:33|rke2-capv|34aefef00a214c93551135fb47b56857b6deb5d0|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4c2ee47f28004dd9bb1dbd22679c7bdb/capv-logs.gz)|
|2024-02-20 01:23|kubeadm-capv|34aefef00a214c93551135fb47b56857b6deb5d0|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4c2ee47f28004dd9bb1dbd22679c7bdb/capv-logs.gz)|
|2024-02-17 01:21|kubeadm-capv|b734aa6bf86c76f8572d8e591907578c01e08dc8|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/820206134d4faa4404092795d14ce0e6/capv-logs.gz)|

Old layout table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2024-01-16 01:34|rke2-capv|5256dbf34a7ce7cb6618ecb8d0179a7eae5fbd46|:white_check_mark: success||
|2024-01-16 01:21|kubeadm-capv|5256dbf34a7ce7cb6618ecb8d0179a7eae5fbd46|:white_check_mark: success||
|2024-01-14 01:33|rke2-capv|2695f09635cce6e4c1f5991efe718e497702f32b|:white_check_mark: success||
|2024-01-14 01:24|kubeadm-capv|2695f09635cce6e4c1f5991efe718e497702f32b|:white_check_mark: success||
|2024-01-14 01:33|rke2-capv|2695f09635cce6e4c1f5991efe718e497702f32b|:white_check_mark: success||
|2024-01-14 01:24|kubeadm-capv|2695f09635cce6e4c1f5991efe718e497702f32b|:white_check_mark: success||
|2024-01-13 01:35|rke2-capv|e3b0dd7ad10c7af250a016da36564264287586bf|:white_check_mark: success||
|2024-01-13 01:19|kubeadm-capv|e3b0dd7ad10c7af250a016da36564264287586bf|:white_check_mark: success||
|2024-01-12 01:32|rke2-capv|18c76e1dc3b307979d78c54f81b07fec0d80d511|:white_check_mark: success||
|2024-01-12 01:25|kubeadm-capv|18c76e1dc3b307979d78c54f81b07fec0d80d511|:white_check_mark: success||
|2024-01-11 01:57|rke2-capv|8826cb80b3b12514a05b5686da9e52505c577704|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f8332c73b645753fb674c6ec8d7eeabf/capv-logs.gz)|
|2024-01-11 01:24|kubeadm-capv|8826cb80b3b12514a05b5686da9e52505c577704|:white_check_mark: success||
|2024-01-10 01:34|rke2-capv|3f2a72a466200d1a5371a70c00cf5f57d35b73fe|:white_check_mark: success||
|2024-01-10 01:57|kubeadm-capv|3f2a72a466200d1a5371a70c00cf5f57d35b73fe|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8138bd7fc116d62d656f66aab4c677ac/capv-logs.gz)|
|2023-12-30 01:40|rke2-capv|e320370a481772acbe361046585b779bc4c772fe|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/17d4ffbdc8036903ad000196987782ea/capv-logs.gz)|
|2023-12-30 01:30|kubeadm-capv|e320370a481772acbe361046585b779bc4c772fe|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/17d4ffbdc8036903ad000196987782ea/capv-logs.gz)|
|2023-12-23 01:30|rke2-capv|cf4b9dee6b0addb94b54b70530d0a25365ba937e|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/758ab1ecc725e797a06261c62cc77788/capv-logs.gz)|
|2023-12-23 01:26|kubeadm-capv|cf4b9dee6b0addb94b54b70530d0a25365ba937e|:white_check_mark: success||
|2023-12-23 01:30|rke2-capv|cf4b9dee6b0addb94b54b70530d0a25365ba937e|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d3bb7c8c3be36d81a9f9930f81189f56/capv-logs.gz)|
|2023-12-23 01:26|kubeadm-capv|cf4b9dee6b0addb94b54b70530d0a25365ba937e|:white_check_mark: success||
|2023-12-23 01:30|rke2-capv|cf4b9dee6b0addb94b54b70530d0a25365ba937e|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/6e58c059b348d378ad25155a7f3ed1c8/capv-logs.gz)|

