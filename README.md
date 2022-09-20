# Pairing in k8s in Codespaces

> A pairing environment inside kind inside Codespaces

## Log
### 2022-09-19
I'm able to provision a custom environment.

Minikube is already provided as a _feature_ for Codespaces, so I'm going to use that for the Kubernetes side of it.

I'm having a hard time accessing Services that are set to LoadBalancer via the Codespaces port-forwarding.
They are listening on the Node's IP on their port, but that port is not listing on the _ports_ section for accessible when forwarding manually.

The way of pairing will be quite different if this works out. It will be accessible via GitHub Codespace's managed domains+https.
This means that Ingresses won't be as useful, e.g: I wouldn't be able to set the host of an Ingress to anything besides _'*'_.

Minikube needs to use the none driver in order to bind to _127.0.0.1_, to get the native service exposure.

*Idea*: don't bring the dev to inside the cluster, bring the cluster to where they are (here)

There is a _remote.localPortHost_ setting field for which addresses are forwarded, it can be set to either _localhost_ or _allInterfaces_.

I think that the port-forwarding may not work due to the nested Docker containers to run Kubernetes.

### 2022-09-20
Launching a cluster using Minikube and kind requires pulling a container image down and initalising a container. This takes a really long amount of time. Launching Minikube alone takes 1m36s, and kind takes 38s to launch. Both require pulling images.

Minikube may be more useful than kind due to the `minikube tunnel` command, where the LoadBalancer Services can be made accessible to the outside machine, somehow.

In regards to bringing Environment up, the container image for it is about 7Gi of disk space and as a result will add a significant amount of time to bring up on top of the Kubernetes time.

LoadBalancers are unable to be configured to listen on 127.0.0.1 in the host container due to Kubernetes not allowing that address to be listened on and Kubernetes not running directly in the Codespaces container.

the container is custom, there's some kinda layering of things together with the features. Running Kubernetes components requires an init system.
Somehow Dockerd is able to run inside of the container though.

running `kubectl -n default apply -f ./manifests/nginx.yaml` and then running the VS Code + Kubernetes extention command of _Kubernetes: Port Forward_ and selecting the nginx Pod will bring up a new shell with `kubectl` port-forwarding and then that will show up in the VS Code ports section, then is able to be exposed to the world. All this, if it's a HTTP service.

Ingress controllers expose multiple services on multiple domains.
Multiple sites is simply not possible to expose, due to the preassigned domain in the Codespaces exposer.

In order to utilise the exposing of Services via Codespaces' exposer, exposing of services from inside Kubernetes through Codespaces
must be listening on 127.0.0.1 (i:lo) which is a value that not even ExternalIPs can be set to.

Both Metallb and kube-vip have errors due to the address being not allowed to be listened on.

Minikube in Docker appears to bring up it's own Docker-In-Docker, this promotes more unhelpful (in this case) network isolation.

Using `minikube tunnel`, the `--bind-address=` arg won't function in the value of having it set to _127.0.0.1_ or the node's IP.
It procedes with it's usual behaviour of allocating a shared address on the bridge interface.

There is no difference noticable in the behaviour of changing the value of the VS Code port forwarding setting of _remote.localPortHost_ to _allInterfaces_.

kubeadm will not initialise Kubernetes

```
I0920 04:16:06.218786   26502 version.go:255] remote version is much newer: v1.25.1; falling back to: stable-1.24
[init] Using Kubernetes version: v1.24.5
[preflight] Running pre-flight checks
[preflight] The system verification failed. Printing the output from the verification:
KERNEL_VERSION: 5.4.0-1090-azure
OS: Linux
CGROUPS_CPU: enabled
CGROUPS_CPUACCT: enabled
CGROUPS_CPUSET: enabled
CGROUPS_DEVICES: enabled
CGROUPS_FREEZER: enabled
CGROUPS_MEMORY: enabled
CGROUPS_PIDS: enabled
CGROUPS_HUGETLB: enabled
CGROUPS_BLKIO: enabled
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR CRI]: container runtime is not running: output: time="2022-09-20T04:16:07Z" level=fatal msg="unable to determine runtime AP
I version: rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing dial unix /var/run/containerd/containerd.sock: connect: no such file or directory\""                                                                                      , error: exit status 1
        [ERROR SystemVerification]: failed to parse kernel config: unable to load kernel module: "configs", output: "modprobe: FATAL: Modu
le configs not found in directory /lib/modules/5.4.0-1090-azure\n", err: exit status 1                                                    [preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

It also appears that having a background process in the _postCreateCommand_ doesn't work. E.g:
```bash
(
    while true; do
        date
        sleep 1s
    done
)&
```