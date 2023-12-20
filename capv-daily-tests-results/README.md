# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-12-20 01:30|rke2-capv|b35e73dc268daa88a515133780b81231be12b7ac|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8ff2e86ac7a644c70a8ca6d9a4a9987d/capv-logs.gz)|
|2023-12-20 01:21|kubeadm-capv|b35e73dc268daa88a515133780b81231be12b7ac|:white_check_mark: success||
|2023-12-19 01:32|rke2-capv|b61273b01122127b026aa57a3e82192b26ae3950|:white_check_mark: success||
|2023-12-19 01:57|kubeadm-capv|b61273b01122127b026aa57a3e82192b26ae3950|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/cf84ea4603a78ee42b2b668743f17355/capv-logs.gz)|
|2023-12-18 01:30|kubeadm-capv|38e05b9f79f33309b62cd27c422abf4a21e1234a|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/bf3e2899c64789df966177c5f62a1190/capv-logs.gz)|
|2023-12-17 01:30|kubeadm-capv|2800f93e11cbdebb62768cfa96d88fa4effa949a|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/0c1d1cbffc41ef41ebac7e93a7f50dd0/capv-logs.gz)|
|2023-12-16 01:30|kubeadm-capv|625166711466de58c6db4e83f404c9c21c6e15ff|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/f1e57e00b03fd7aadd75a940c5f16158/capv-logs.gz)|
|2023-12-15 01:57|rke2-capv|6c2a3b874e4764a1e1b765b5ff8adbe1e515625e|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/362dcb2afc0de4ddb51656076695e319/capv-logs.gz)|
|2023-12-15 01:22|kubeadm-capv|6c2a3b874e4764a1e1b765b5ff8adbe1e515625e|:white_check_mark: success||
|2023-12-14 01:31|rke2-capv|26b2ba9497a3f056ca1aacba3d7cfe68defdc2c6|:white_check_mark: success||
|2023-12-14 01:30|kubeadm-capv|26b2ba9497a3f056ca1aacba3d7cfe68defdc2c6|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/9448a4efd27e0cdfbf5adeb17d7879dc/capv-logs.gz)|
|2023-12-13 01:34|rke2-capv|df5eb2fddcbcee4b9f0c184ce82943823dc8f58f|:white_check_mark: success||
|2023-12-13 01:32|kubeadm-capv|df5eb2fddcbcee4b9f0c184ce82943823dc8f58f|:white_check_mark: success||
|2023-12-12 01:30|kubeadm-capv|aaaed1e336e04dc97b03354da214f83a7bf0d6da|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:32|rke2-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-09 01:25|kubeadm-capv|96761ed484f56c02c0ce7d1d1b07050e5b63e153|:white_check_mark: success||
|2023-12-08 01:27|rke2-capv|cf2abc8699b09b53cce4272c9e3179dae00a3f90|:white_check_mark: success||

