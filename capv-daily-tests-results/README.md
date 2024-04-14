# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-04-13 02:37|rke2-capv|2850a47fb5d2c760db5f91b842ec8a96ecde5a4c|:white_check_mark:|:white_check_mark:||
|2024-04-13 02:37|rke2-capv|2850a47fb5d2c760db5f91b842ec8a96ecde5a4c|:white_check_mark:|:white_check_mark:||
|2024-04-13 02:29|kubeadm-capv|2850a47fb5d2c760db5f91b842ec8a96ecde5a4c|:white_check_mark:|:white_check_mark:||
|2024-04-12 02:37|rke2-capv|c8cecca87a0a054141a9a555a264999c4e7de303|:white_check_mark:|:white_check_mark:||
|2024-04-12 02:27|kubeadm-capv|c8cecca87a0a054141a9a555a264999c4e7de303|:white_check_mark:|:white_check_mark:||
|2024-04-11 02:34|rke2-capv|bb6c373da70db4f28695e1f76ba36ad598cbef65|:white_check_mark:|:white_check_mark:||
|2024-04-11 02:35|kubeadm-capv|bb6c373da70db4f28695e1f76ba36ad598cbef65|:white_check_mark:|:white_check_mark:||
|2024-04-10 02:33|rke2-capv|4e7a1ebcedebdbfd7dd4e0122d24786b9ec19de3|:white_check_mark:|:white_check_mark:||
|2024-04-10 02:37|kubeadm-capv|4e7a1ebcedebdbfd7dd4e0122d24786b9ec19de3|:white_check_mark:|:white_check_mark:||
|2024-04-09 02:57|rke2-capv|62f45274e7200a95594c77ba61cb0a2ce5d3e673|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/93302f05a95fd7771ad91a85640d7f21/capv-logs.gz)|
|2024-04-09 02:57|kubeadm-capv|62f45274e7200a95594c77ba61cb0a2ce5d3e673|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/93302f05a95fd7771ad91a85640d7f21/capv-logs.gz)|
|2024-04-06 02:56|kubeadm-capv|967bf4222ce4e898fa075569eca266bee96eea90|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/35843afc86432e40a559e3a04f434c2a/capv-logs.gz)|
|2024-04-06 02:49|rke2-capv|967bf4222ce4e898fa075569eca266bee96eea90|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/b8ee6c198d6ba3b574035d765e57ab9c/capv-logs.gz)|
|2024-04-06 02:49|rke2-capv|967bf4222ce4e898fa075569eca266bee96eea90|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4258945ffa97dba400326ab1b3dde301/capv-logs.gz)|
|2024-04-06 02:56|kubeadm-capv|967bf4222ce4e898fa075569eca266bee96eea90|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4258945ffa97dba400326ab1b3dde301/capv-logs.gz)|
|2024-04-05 01:57|rke2-capv|5f6dcc73780338773caf35dc10f7f38a712a871d|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3135e5c3975e411569008056681c31cc/capv-logs.gz)|
|2024-04-05 01:57|kubeadm-capv|5f6dcc73780338773caf35dc10f7f38a712a871d|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3135e5c3975e411569008056681c31cc/capv-logs.gz)|
|2024-04-04 01:57|rke2-capv|c0335a739c938225d1633278ab30380732b194cf|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/ccb515add349cf06683823c11091183e/capv-logs.gz)|
|2024-04-04 01:57|kubeadm-capv|c0335a739c938225d1633278ab30380732b194cf|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/ccb515add349cf06683823c11091183e/capv-logs.gz)|
|2024-04-03 01:57|rke2-capv|e783a82c76eddb0804151504feecac6a7b116d85|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8ac7f3174e1421737ceb6a0aa321b8f2/capv-logs.gz)|
|2024-04-03 01:57|kubeadm-capv|e783a82c76eddb0804151504feecac6a7b116d85|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8ac7f3174e1421737ceb6a0aa321b8f2/capv-logs.gz)|

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

