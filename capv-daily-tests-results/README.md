# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-02-12 15:00|rke2-capv|8a41d262080fa079c333df2c5fee1eb585f5b161|:white_check_mark:|:white_check_mark:||
|2024-02-12 15:01|kubeadm-capv|8a41d262080fa079c333df2c5fee1eb585f5b161|:white_check_mark:|:white_check_mark:||
|2024-02-10 01:57|rke2-capv|18f2c256e38889b2f5236fec5ead1742a95e56a9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/a54a7f26933eb694096f68497b0b3a35/capv-logs.gz)|
|2024-02-10 01:57|kubeadm-capv|18f2c256e38889b2f5236fec5ead1742a95e56a9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/a54a7f26933eb694096f68497b0b3a35/capv-logs.gz)|
|2024-02-09 01:57|rke2-capv|92d5c2a514c4603b1924f71c6d7435886a9b6170|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/2d4b6fa8c2803afabe5aeb81f850feda/capv-logs.gz)|
|2024-02-09 01:57|kubeadm-capv|92d5c2a514c4603b1924f71c6d7435886a9b6170|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/2d4b6fa8c2803afabe5aeb81f850feda/capv-logs.gz)|
|2024-02-08 01:30|rke2-capv|f8ed5e856f87a35481d397c948cfeb8612e6e8a2|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7614ed7daaff4447c5cc6e03a858ad0e/capv-logs.gz)|
|2024-02-08 01:30|kubeadm-capv|f8ed5e856f87a35481d397c948cfeb8612e6e8a2|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7614ed7daaff4447c5cc6e03a858ad0e/capv-logs.gz)|
|2024-02-07 01:30|rke2-capv|557e4e5fe5e8bed5f8e5c3a1f9f1e340132a9719|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/fd74787d4296c0c88a93f398411bc714/capv-logs.gz)|
|2024-02-07 01:22|kubeadm-capv|557e4e5fe5e8bed5f8e5c3a1f9f1e340132a9719|:white_check_mark:|:x:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/fd74787d4296c0c88a93f398411bc714/capv-logs.gz)|
|2024-02-06 00:57|rke2-capv|4561510f13e9331fab637d36639a6c49e086f505|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/5dcdfa9d00ab9ccfa53997a1e800baf5/capv-logs.gz)|
|2024-02-06 00:57|kubeadm-capv|4561510f13e9331fab637d36639a6c49e086f505|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/5dcdfa9d00ab9ccfa53997a1e800baf5/capv-logs.gz)|
|2024-02-03 01:23|kubeadm-capv|dce3d8bdeb80b431410a41a8183f146a0fd4ae24|:white_check_mark:|:white_check_mark:||
|2024-02-03 01:24|rke2-capv|dce3d8bdeb80b431410a41a8183f146a0fd4ae24|:white_check_mark:|:white_check_mark:||
|2024-02-03 01:24|rke2-capv|dce3d8bdeb80b431410a41a8183f146a0fd4ae24|:white_check_mark:|:white_check_mark:||
|2024-02-03 01:23|kubeadm-capv|dce3d8bdeb80b431410a41a8183f146a0fd4ae24|:white_check_mark:|:white_check_mark:||
|2024-02-02 01:23|rke2-capv|e1eb8ae232a3d8a051a0009e6f719b0f928c882f|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/62f476a89c637cf7c9a514309f2c4a22/capv-logs.gz)|
|2024-02-02 01:55|kubeadm-capv|e1eb8ae232a3d8a051a0009e6f719b0f928c882f|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/62f476a89c637cf7c9a514309f2c4a22/capv-logs.gz)|
|2024-02-01 01:22|rke2-capv|f99f11fff0ff74831ee60cc6fb146e7a43fef885|:white_check_mark:|:x:||
|2024-02-01 01:21|kubeadm-capv|f99f11fff0ff74831ee60cc6fb146e7a43fef885|:white_check_mark:|:x:||
|2024-01-31 01:02|rke2-capv|9f4761d8c869ddecf478645792f220a7417fca65|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d06a59e9cbbd767b6097c9e6ef47d89a/capv-logs.gz)|

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

