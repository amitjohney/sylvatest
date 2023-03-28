# Sylva tests on vSphere infrastructure

The Sylva stack is automatically tested **daily** at TIM labs on vSphere infrastructure.

Tests logs of failed jobs are published as attachments of the project wiki.

The results are summirized by the following table:

| Date                      | Management Cluster CAPI Providers | Sylva-Core main commit ID        | Result                                       | Test logs (only for failed tests) |
|---------------------------|-----------------------------------|----------------------------------|----------------------------------------------|-----------------------------------|
|2023-03-15 09:33:58+00:00|kubeadm-capv|71142a2235a1f291e47a263d0e4eacf882aeb871|:white_check_mark:<span style="color:green">success</span>| |
|2023-03-14 09:33:58+00:00|kubeadm-capv|3d16e3c1889ad424ff08c3dc49fabba4309d0a92|:x:<span style="color:red">failed</span>| [test logs](https://sylva2023.atlassian.net/wiki/download/attachments/3014658/2023-03-15-sylva-kubeadm-capv.log?api=v2) |
