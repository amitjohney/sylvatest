# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summarized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-11-12 01:18|rke2-capv|8294bc26f6443e771778cb6bce0b338bfd6e59bd|:white_check_mark: success||
|2023-11-12 01:14|kubeadm-capv|8294bc26f6443e771778cb6bce0b338bfd6e59bd|:white_check_mark: success||
|2023-11-11 01:18|rke2-capv|5a326d02f1a7262320aef195023782b0d2ed2d5d|:white_check_mark: success||
|2023-11-11 01:15|kubeadm-capv|5a326d02f1a7262320aef195023782b0d2ed2d5d|:white_check_mark: success||
|2023-11-10 01:17|rke2-capv|7edca9c139d6a167b4826f7c0f1cc27614107fe6|:white_check_mark: success||
|2023-11-10 01:14|kubeadm-capv|7edca9c139d6a167b4826f7c0f1cc27614107fe6|:white_check_mark: success||
|2023-11-09 01:22|rke2-capv|0468bf8acf4d4a982ef951a9af06a96d2b23b623|:white_check_mark: success||
|2023-11-09 01:18|kubeadm-capv|0468bf8acf4d4a982ef951a9af06a96d2b23b623|:white_check_mark: success||
|2023-11-08 12:38|rke2-capv|21830acde64245f732909a86ff6e50617ecfcce3|:white_check_mark: success||
|2023-11-08 12:36|kubeadm-capv|21830acde64245f732909a86ff6e50617ecfcce3|:white_check_mark: success||
|2023-11-08 01:30|kubeadm-capv|2b36a1948bb625faf0c9f49313ace4bfafdd23d3|:x: failed|[link](https://gitlab.com/sylva-projects/sylva-core/-/wikis/uploads/8327ba87c5514b3f62065e40559f0d87/test-kubeadm-capv.zip)|
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

