# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-11-07 09:55|kubeadm-capv|9b9c66e6917af88f01f30daf282768dd87c990c2|:white_check_mark: success||
|2023-11-06 17:04|rke2-capv|d140f10ef71ddc460b23696a8610ef9585ca61c5|:white_check_mark: success||
|2023-11-06 10:11|kubeadm-capv|aed747e2ba2b88f824f2cbe18352d8ba41ca5b02|:white_check_mark: success||
|2023-11-05 01:01|kubeadm-capv|4376759247fad9ff8f5561f0081e677e949d128c|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/cc2766a90f2b323ce915d90e25c5c1ac/test-kubeadm-capv.zip)|
|2023-11-04 01:01|kubeadm-capv|dd7205db314392ba11fb2c932a88076bfbc8d7d5|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/a64b7f15dacf6c45d0187cefb03f6601/test-kubeadm-capv.zip)|
|2023-11-03 01:01|kubeadm-capv|cfc157a554ef8b2cd877d5d2ec6ad3d9b0f401ae|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/bbe265ff311e567d4be8ab8abbabfa0e/test-kubeadm-capv.zip)|
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

