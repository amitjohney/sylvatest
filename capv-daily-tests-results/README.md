# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Management cluster result                    | Workload cluster result              | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|--------------------------------------|-----------------------------------|
|2024-03-30 01:39|rke2-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-30 01:38|kubeadm-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-30 01:38|kubeadm-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-30 01:39|rke2-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-30 01:39|rke2-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-30 01:38|kubeadm-capv|690dc7591718a292799661f06a6c10ec9ba09820|:white_check_mark:|:white_check_mark:||
|2024-03-29 01:33|rke2-capv|60c09b59d9cb407507f40d22e63b06a15cc9fbf5|:white_check_mark:|:white_check_mark:||
|2024-03-29 01:34|kubeadm-capv|60c09b59d9cb407507f40d22e63b06a15cc9fbf5|:white_check_mark:|:white_check_mark:||
|2024-03-28 01:43|rke2-capv|3e6bdaef0198bb8f4c2aa6ca8c5b7c439d49824b|:white_check_mark:|:white_check_mark:||
|2024-03-28 01:43|kubeadm-capv|3e6bdaef0198bb8f4c2aa6ca8c5b7c439d49824b|:white_check_mark:|:white_check_mark:||
|2024-03-27 01:30|rke2-capv|ec4e2ed373d7a73f486954b38777ba0e875915ff|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f473386d84ed3a5fee71ccb90177d604/capv-logs.gz)|
|2024-03-27 01:30|kubeadm-capv|ec4e2ed373d7a73f486954b38777ba0e875915ff|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f473386d84ed3a5fee71ccb90177d604/capv-logs.gz)|
|2024-03-26 01:30|rke2-capv|da23495ec29658e999c6040b5affd7809ebfb7b7|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1289e7c0ac7493605a81c4eeb2b6a6d6/capv-logs.gz)|
|2024-03-26 01:57|kubeadm-capv|da23495ec29658e999c6040b5affd7809ebfb7b7|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1289e7c0ac7493605a81c4eeb2b6a6d6/capv-logs.gz)|
|2024-03-25 01:34|rke2-capv|30a98551edfda9f64247e9a5977569f54acc9b3b|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3c8741d3738dc8b816b48e007b43a74f/capv-logs.gz)|
|2024-03-25 01:30|kubeadm-capv|30a98551edfda9f64247e9a5977569f54acc9b3b|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3c8741d3738dc8b816b48e007b43a74f/capv-logs.gz)|
|2024-03-23 01:33|rke2-capv|ca60555d817ed53586e1b9a4e5f75ef9ed9200ac|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8e0502d734e1a3e2211380b336b3a171/capv-logs.gz)|
|2024-03-23 01:33|rke2-capv|ca60555d817ed53586e1b9a4e5f75ef9ed9200ac|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/279441c956ee0c13a6685c20d6a00921/capv-logs.gz)|
|2024-03-23 01:30|kubeadm-capv|ca60555d817ed53586e1b9a4e5f75ef9ed9200ac|:x:|N/A|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/279441c956ee0c13a6685c20d6a00921/capv-logs.gz)|
|2024-03-22 01:33|rke2-capv|57363590a43c89a2abb50af120fc1fced7ad0770|:white_check_mark:|:white_check_mark:||
|2024-03-22 01:33|kubeadm-capv|57363590a43c89a2abb50af120fc1fced7ad0770|:white_check_mark:|:white_check_mark:||

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

