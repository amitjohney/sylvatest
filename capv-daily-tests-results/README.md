# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-05-22 02:35|rke2-capv|bf764a2ebf38c48adfa0fb0b141e3990c182f80a|:white_check_mark:|:x:||
|2024-05-22 02:30|kubeadm-capv|bf764a2ebf38c48adfa0fb0b141e3990c182f80a|:white_check_mark:|:x:||
|2024-05-21 02:30|rke2-capv|dc2c50873ffc0b6fd36bc1c7b6532bf27c538283|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/0f323afd9eb460c0c401b24f6ea8583d/capv-logs.gz)|
|2024-05-21 02:30|kubeadm-capv|dc2c50873ffc0b6fd36bc1c7b6532bf27c538283|:white_check_mark:|:x:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/0f323afd9eb460c0c401b24f6ea8583d/capv-logs.gz)|
|2024-05-08 02:30|rke2-capv|be13817adbed3760ef33b8b7f5e8a1fc148f222c|:white_check_mark:|:x:||
|2024-05-08 02:32|kubeadm-capv|be13817adbed3760ef33b8b7f5e8a1fc148f222c|:white_check_mark:|:x:||
|2024-05-07 02:37|rke2-capv|16f216b588903bc264f070d716e3d44c7cd7a2b5|:white_check_mark:|:x:||
|2024-05-07 02:34|kubeadm-capv|16f216b588903bc264f070d716e3d44c7cd7a2b5|:white_check_mark:|:x:||
|2024-05-03 02:35|rke2-capv|af401ecf561077f073b28a61f0c2521a28f6c2e8|:white_check_mark:|:x:||
|2024-05-03 02:27|kubeadm-capv|af401ecf561077f073b28a61f0c2521a28f6c2e8|:white_check_mark:|:x:||
|2024-05-02 02:43|rke2-capv|af5750d9e74b08f913542d7129027668795a8413|:white_check_mark:|:x:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/ed8d060995cc87bea28a305d56dddb95/capv-logs.gz)|
|2024-05-02 02:32|kubeadm-capv|af5750d9e74b08f913542d7129027668795a8413|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/ed8d060995cc87bea28a305d56dddb95/capv-logs.gz)|
|2024-05-01 02:30|rke2-capv|a99abf9ec27e7aba874287a4684d15a570583c86|:white_check_mark:|:x:||
|2024-05-01 02:31|kubeadm-capv|a99abf9ec27e7aba874287a4684d15a570583c86|:white_check_mark:|:x:||
|2024-04-30 02:33|rke2-capv|ce43927e9740e2ee57c3c3d96d95e8bc22541878|:white_check_mark:|:x:||
|2024-04-30 02:37|kubeadm-capv|ce43927e9740e2ee57c3c3d96d95e8bc22541878|:white_check_mark:|:x:||
|2024-04-27 02:31|rke2-capv|d48edb3b35e2beec16195a11b6ba7d88b16c5a90|:white_check_mark:|:x:||
|2024-04-27 02:31|kubeadm-capv|d48edb3b35e2beec16195a11b6ba7d88b16c5a90|:white_check_mark:|:x:||
|2024-04-26 02:30|rke2-capv|2658fc25327fcd142ba75d9813b8292d337cbd34|:white_check_mark:|:x:||
|2024-04-26 02:27|kubeadm-capv|2658fc25327fcd142ba75d9813b8292d337cbd34|:white_check_mark:|:x:||
|2024-04-25 02:32|rke2-capv|71695ffe4ab95d32add8321f2a2af272cecd0ad3|:white_check_mark:|:white_check_mark:||

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

