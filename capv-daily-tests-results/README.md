# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-03-09 01:57|rke2-capv|1fdb30bd96ae5adc5745a8320a1685a839255a03|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/483250877fc174cd6bb08c3db063d624/capv-logs.gz)|
|2024-03-09 01:57|rke2-capv|1fdb30bd96ae5adc5745a8320a1685a839255a03|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1598a22d81cf3f42ba4e2a5f1689220e/capv-logs.gz)|
|2024-03-09 01:23|kubeadm-capv|1fdb30bd96ae5adc5745a8320a1685a839255a03|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1598a22d81cf3f42ba4e2a5f1689220e/capv-logs.gz)|
|2024-03-08 01:57|rke2-capv|2c79efeb70ca9d805869eb5d4d2b72a454503f51|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/470bdbc8046547eaee9ece82b30be49a/capv-logs.gz)|
|2024-03-08 01:30|kubeadm-capv|2c79efeb70ca9d805869eb5d4d2b72a454503f51|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/470bdbc8046547eaee9ece82b30be49a/capv-logs.gz)|
|2024-03-07 01:57|rke2-capv|e3bea1c59b97aa791d1f7728770dbeaafa77570b|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1ebf752c5b531c12a1e95393e04b5dd1/capv-logs.gz)|
|2024-03-07 01:57|kubeadm-capv|e3bea1c59b97aa791d1f7728770dbeaafa77570b|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1ebf752c5b531c12a1e95393e04b5dd1/capv-logs.gz)|
|2024-03-06 01:36|rke2-capv|86f6cd9d88eb9af0685d5e28f5a4d2120e30ee70|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/e966b41f633239912126339fc54cb596/capv-logs.gz)|
|2024-03-06 01:30|kubeadm-capv|86f6cd9d88eb9af0685d5e28f5a4d2120e30ee70|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/e966b41f633239912126339fc54cb596/capv-logs.gz)|
|2024-03-05 01:54|rke2-capv|d3426961ac7f7edbd514dbad8d082004e3e6887f|:white_check_mark:|:white_check_mark:|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/de54b9a5282f451ee7470dabcda30871/capv-logs.gz)|
|2024-03-05 01:57|kubeadm-capv|d3426961ac7f7edbd514dbad8d082004e3e6887f|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/de54b9a5282f451ee7470dabcda30871/capv-logs.gz)|
|2024-03-04 01:33|rke2-capv|ffff511044f5bbb3ef13de555c7ac5462589e19a|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/927d22155301ba3665d42a4d47209689/capv-logs.gz)|
|2024-03-04 01:33|kubeadm-capv|ffff511044f5bbb3ef13de555c7ac5462589e19a|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/927d22155301ba3665d42a4d47209689/capv-logs.gz)|
|2024-03-03 01:57|rke2-capv|8ba98b0bd341afec143e031845e60a0a86d73975|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f2a412a55a1ad0d8bb9eb6ec78de85bf/capv-logs.gz)|
|2024-03-03 01:57|kubeadm-capv|8ba98b0bd341afec143e031845e60a0a86d73975|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f2a412a55a1ad0d8bb9eb6ec78de85bf/capv-logs.gz)|
|2024-03-01 01:30|rke2-capv|9c0de311540f3403aa4e718fa118354d9d4aff44|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4be085afc8ee1c96c862b760e8fd79b4/capv-logs.gz)|
|2024-03-01 01:30|kubeadm-capv|9c0de311540f3403aa4e718fa118354d9d4aff44|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4be085afc8ee1c96c862b760e8fd79b4/capv-logs.gz)|
|2024-02-29 01:57|rke2-capv|9525021e46af21a6f7dafc1b338a52afea50a0c9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4044c26e869842d3cb0c7d329ef4b88a/capv-logs.gz)|
|2024-02-29 01:57|kubeadm-capv|9525021e46af21a6f7dafc1b338a52afea50a0c9|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/4044c26e869842d3cb0c7d329ef4b88a/capv-logs.gz)|
|2024-02-28 01:31|rke2-capv|bdaf1aac2f9ed009a9e668b70a0a389f793b6f28|:white_check_mark:|:white_check_mark:||
|2024-02-28 01:30|kubeadm-capv|bdaf1aac2f9ed009a9e668b70a0a389f793b6f28|:white_check_mark:|:white_check_mark:||

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

