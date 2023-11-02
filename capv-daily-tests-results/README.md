# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-11-02 01:23|kubeadm-capv|83dfbca043350c52e4ae3d37ea587de4ba703c2f|:white_check_mark: success||
|2023-11-01 01:18|kubeadm-capv|fb57fb3621fa7c8698756980f0360f059f02a092|:white_check_mark: success||
|2023-10-31 01:20|kubeadm-capv|94b6961376a6f67bbe8f501fbf857cba455b8579|:white_check_mark: success||
|2023-10-28 02:55|kubeadm-capv|1170e33faaff6af33571a05b275948884096306e|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/daf387c7bfde0a6c2471ce4b70d8faed/test-kubeadm-capv.zip)|
|2023-10-27 02:19|kubeadm-capv|18c05ff322f14ccb65bb69eef7849a4c359da7bb|:white_check_mark: success||
|2023-10-26 02:21|kubeadm-capv|26cd3efedf907c097c8c79cad83e6dc468f950c1|:white_check_mark: success||
|2023-10-25 02:34|kubeadm-capv|616ef09cbe11b88b4788fc1d9bf7aa5880fdeff4|:white_check_mark: success||
|2023-10-24 02:24|kubeadm-capv|ba4a3c2d6966cb63a5f77f8263c971be86441a90|:white_check_mark: success||
|2023-10-21 02:22|kubeadm-capv|4fcb2b8a0a84e6522333ea3db4701656260084b1|:white_check_mark: success||
|2023-10-20 02:18|kubeadm-capv|b229d93f450a61aacea3006e32fd2618173e4636|:white_check_mark: success||
|2023-10-19 02:53|kubeadm-capv|2b708bf991cf5aafedb06063a8c86c4d82371813|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/5a18469b25031a6760583156fcad233e/test-kubeadm-capv.zip)|
|2023-10-17 18:22|kubeadm-capv|d0b6180e3f03b48c8ff5ac63d40548f34626f4ee|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/3a9ccb4b1db7f8a94ffb8cfe59f9ea60/test-kubeadm-capv.zip)|
|2023-10-17 02:30|kubeadm-capv|bd2446305f273a1eb2e974928646f216907bb83d|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/89f2fc1cb0a59f216bc210bf04d6a3e3/test-kubeadm-capv.zip)|
|2023-10-14 02:16|kubeadm-capv|a931d3fd9fa917d85eee22af773ee560c0fe614c|:white_check_mark: success||
|2023-10-13 02:16|kubeadm-capv|58a20d2e7c011e9f355fc29cab262e1edcdaf9d2|:white_check_mark: success||
|2023-10-12 02:31|kubeadm-capv|38dbdb9878224fe1799d139ca7667182e8db98d1|:white_check_mark: success||
|2023-10-11 02:52|kubeadm-capv|980c71e0b7cceac17eda3dce791506f038e5eeba|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/d8f892f914d30462e9eb55d7dd5f7841/test-kubeadm-capv.zip)|
|2023-10-10 02:16|kubeadm-capv|dccc762dc537564d80628098de21427f82e2e171|:white_check_mark: success||
|2023-10-07 02:24|kubeadm-capv|e9698ff960662443d70c29cb112f0c1b16d5364a|:white_check_mark: success||
|2023-10-06 02:24|kubeadm-capv|ffbb0cc1f98be0f6f4c2118d7150bf00d486e972|:white_check_mark: success||
|2023-10-05 02:16|kubeadm-capv|dde7eb673c465ddb199c7caf485a8fa9fd74167d|:white_check_mark: success||

