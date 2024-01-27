# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-01-27 01:29|rke2-capv|8dbcf32a7fd29db2eba5fc8fb1e139a1070144b0|:white_check_mark:|:white_check_mark:||
|2024-01-27 01:26|kubeadm-capv|8dbcf32a7fd29db2eba5fc8fb1e139a1070144b0|:white_check_mark:|:white_check_mark:||
|2024-01-26 01:26|rke2-capv|8fde65e219510515e306544b7cdf8059833dad5f|:white_check_mark:|:white_check_mark:||
|2024-01-26 01:23|kubeadm-capv|8fde65e219510515e306544b7cdf8059833dad5f|:white_check_mark:|:white_check_mark:||
|2024-01-25 01:23|rke2-capv|54fe662cb7a3d4248469883cf830428c490070b4|:white_check_mark:|:white_check_mark:||
|2024-01-25 01:23|kubeadm-capv|54fe662cb7a3d4248469883cf830428c490070b4|:white_check_mark:|:white_check_mark:||
|2024-01-24 01:22|rke2-capv|8e7159c438a3a2e6da26ab2e42285ed4546c8a7a|:white_check_mark:|:white_check_mark:||
|2024-01-24 01:20|kubeadm-capv|8e7159c438a3a2e6da26ab2e42285ed4546c8a7a|:white_check_mark:|:white_check_mark:||
|2024-01-23 01:33|rke2-capv|587721499c5ab00cc37da10a182ce920505305df|:white_check_mark:|:white_check_mark:||
|2024-01-23 01:24|kubeadm-capv|587721499c5ab00cc37da10a182ce920505305df|:white_check_mark:|:white_check_mark:||
|2024-01-22 01:22|rke2-capv|0bed8ebd060ed3b00b8bafad649699004e84b90c|:white_check_mark:|:white_check_mark:||
|2024-01-22 01:21|kubeadm-capv|0bed8ebd060ed3b00b8bafad649699004e84b90c|:white_check_mark:|:white_check_mark:||
|2024-01-20 01:25|rke2-capv|a4b06a29985c11e488ec9e170db139002016b54e|:white_check_mark:|:white_check_mark:||
|2024-01-20 01:25|rke2-capv|a4b06a29985c11e488ec9e170db139002016b54e|:white_check_mark:|:white_check_mark:||
|2024-01-20 01:24|kubeadm-capv|a4b06a29985c11e488ec9e170db139002016b54e|:white_check_mark:|:white_check_mark:||
|2024-01-19 01:23|rke2-capv|df23a9871f64ea3d7772b0c63a4354acab3f22ad|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/c3399506e19ffed2d26997425eb33877/capv-logs.gz)|
|2024-01-19 01:10|kubeadm-capv|df23a9871f64ea3d7772b0c63a4354acab3f22ad|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/c3399506e19ffed2d26997425eb33877/capv-logs.gz)|
|2024-01-18 10:34|rke2-capv|416c1fa1403f536d9017867c51ae7cbbb6b0c406|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/dc44dc266c4354c196f489753a643050/capv-logs.gz)|
|2024-01-18 10:34|kubeadm-capv|416c1fa1403f536d9017867c51ae7cbbb6b0c406|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/dc44dc266c4354c196f489753a643050/capv-logs.gz)|
|2024-01-16 17:38|rke2-capv|5a6686b37125346868b83e3fee125ecb6d7ed870|:white_check_mark:|:white_check_mark:||
|2024-01-16 17:37|kubeadm-capv|5a6686b37125346868b83e3fee125ecb6d7ed870|:white_check_mark:|:white_check_mark:||

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

