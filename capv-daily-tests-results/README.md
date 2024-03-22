# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-03-22 01:33|rke2-capv|57363590a43c89a2abb50af120fc1fced7ad0770|:white_check_mark:|:white_check_mark:||
|2024-03-22 01:33|kubeadm-capv|57363590a43c89a2abb50af120fc1fced7ad0770|:white_check_mark:|:white_check_mark:||
|2024-03-20 17:02|rke2-capv|ccdeda1cb9b44dcca59955f5fb7b7a6488acba57|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d898b4011e2287cac766503704b393c6/capv-logs.gz)|
|2024-03-20 16:27|kubeadm-capv|ccdeda1cb9b44dcca59955f5fb7b7a6488acba57|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d898b4011e2287cac766503704b393c6/capv-logs.gz)|
|2024-03-19 01:32|rke2-capv|ccdeda1cb9b44dcca59955f5fb7b7a6488acba57|:white_check_mark:|:white_check_mark:||
|2024-03-19 01:33|kubeadm-capv|ccdeda1cb9b44dcca59955f5fb7b7a6488acba57|:white_check_mark:|:white_check_mark:||
|2024-03-18 01:33|rke2-capv|2c213128f810593ebd0be3ceca4aeeff6489b55f|:white_check_mark:|:white_check_mark:||
|2024-03-18 01:35|kubeadm-capv|2c213128f810593ebd0be3ceca4aeeff6489b55f|:white_check_mark:|:white_check_mark:||
|2024-03-17 01:31|rke2-capv|2371e776aa4b94e202d8d5d0756cd33937fa7298|:white_check_mark:|:white_check_mark:||
|2024-03-17 01:26|kubeadm-capv|2371e776aa4b94e202d8d5d0756cd33937fa7298|:white_check_mark:|:white_check_mark:||
|2024-03-16 01:31|rke2-capv|d23cec7d9b80ea2aa49d60e66352d1e71ba21bc8|:white_check_mark:|:white_check_mark:||
|2024-03-16 01:26|kubeadm-capv|d23cec7d9b80ea2aa49d60e66352d1e71ba21bc8|:white_check_mark:|:white_check_mark:||
|2024-03-15 01:26|rke2-capv|13033fe6e7aeb2e75f334353ee1d621b68c43543|:white_check_mark:|:white_check_mark:||
|2024-03-15 01:32|kubeadm-capv|13033fe6e7aeb2e75f334353ee1d621b68c43543|:white_check_mark:|:white_check_mark:||
|2024-03-14 01:30|rke2-capv|d6ce4301155f5d1b8d8b54253b2ec0e35139ce8e|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/faae185f5c05d13647ce9bf98c738f1d/capv-logs.gz)|
|2024-03-14 01:30|kubeadm-capv|d6ce4301155f5d1b8d8b54253b2ec0e35139ce8e|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/faae185f5c05d13647ce9bf98c738f1d/capv-logs.gz)|
|2024-03-13 01:57|rke2-capv|66df7b64e2a09674366621f39052308a501e1c67|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/6d3c3bfcd6ad310f715cde1b3953a5c6/capv-logs.gz)|
|2024-03-13 01:35|kubeadm-capv|66df7b64e2a09674366621f39052308a501e1c67|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/6d3c3bfcd6ad310f715cde1b3953a5c6/capv-logs.gz)|
|2024-03-12 01:57|rke2-capv|1002af4f58523d7717c783613dfedb33688d432f|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/e534abeb192a398f956d3e4b65426752/capv-logs.gz)|
|2024-03-12 01:29|kubeadm-capv|1002af4f58523d7717c783613dfedb33688d432f|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/e534abeb192a398f956d3e4b65426752/capv-logs.gz)|
|2024-03-09 01:23|kubeadm-capv|1fdb30bd96ae5adc5745a8320a1685a839255a03|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/7139b76989db56609770e5df68c523bb/capv-logs.gz)|

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

