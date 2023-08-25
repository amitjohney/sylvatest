# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-08-25 02:31|kubeadm-capv|d7516d7084566f79886b7d6000e3985663221d81|:white_check_mark: success||
|2023-08-24 02:22|kubeadm-capv|b9178599f4f57d5aabe8b81d8bd2677472e93847|:white_check_mark: success||
|2023-08-23 02:19|kubeadm-capv|3b5b195bdae609d5cf1716c8eadaadc7ed4999ec|:white_check_mark: success||
|2023-08-22 02:22|kubeadm-capv|b2dc9904aaf2337bbf0f77017e013d67d2f3cae4|:white_check_mark: success||
|2023-08-18 02:53|kubeadm-capv|1eb2994f30fd994743736a572ded4bf06ae21476|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/2c672d79579e5c9e6936fa24f5b060cb/test-kubeadm-capv.gz)|
|2023-08-17 02:26|kubeadm-capv|a9e495950b2950fb3f71fef0ab8b608c58da687b|:white_check_mark: success||
|2023-08-15 02:20|kubeadm-capv|04fbbf398960af05bbc2e7b94401e286b821f3a9|:white_check_mark: success||
|2023-08-12 02:19|kubeadm-capv|ae1ada53f0bdc1aa6aa2ece20c2ba7128ee85c8c|:white_check_mark: success||
|2023-08-11 02:32|kubeadm-capv|3f847ffa1e806df0a27456b790d23e6fbe41c147|:white_check_mark: success||
|2023-08-10 02:18|kubeadm-capv|5519a794cedf21a0fb237665388dc9040d85fe63|:white_check_mark: success||
|2023-08-09 02:27|kubeadm-capv|63a0799a1da09bba5e7590a0b932f97c7a908676|:white_check_mark: success||
|2023-08-08 02:21|kubeadm-capv|e7c4ca61005bb3694eb9778bf7141a42f7ba2ad6|:white_check_mark: success||
|2023-08-05 02:52|kubeadm-capv|baff46170525e0c1bfd71fa302f68f82abe18563|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/57d2252f42e447b82339c9f2497fc0bf/test-kubeadm-capv.gz)|
|2023-08-04 02:52|kubeadm-capv|8d1841eb2afe95f26bef5704ccaa75979f40ff7a|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/1e6e6b61287eba9f09064a1b695f07c5/test-kubeadm-capv.gz)|
|2023-08-01 02:18|kubeadm-capv|73f908caade58645324f190a544c76f97b6c298d|:white_check_mark: success||
|2023-07-29 02:18|kubeadm-capv|87c1a4442cd931c401e9a01415345fb6ff5dd0cc|:white_check_mark: success||
|2023-07-27 02:20|kubeadm-capv|012de198ed16db94a2bb3a31afa05e02d0dd2c85|:white_check_mark: success||
|2023-07-25 12:41|kubeadm-capv|5d530a22fcb043ea63ff368bcc457a40dc1bf551|:white_check_mark: success||
|2023-07-25 13:05|kubeadm-capv|5d530a22fcb043ea63ff368bcc457a40dc1bf551|:white_check_mark: success||
|2023-05-31 02:12|kubeadm-capv|bf88c6bd0260c7736b4e8ab43a3ed26ad76023de|:white_check_mark: success||
|2023-05-30 02:11|kubeadm-capv|22811e85844001cdc4643c45a57a9599e74909f8|:white_check_mark: success||

