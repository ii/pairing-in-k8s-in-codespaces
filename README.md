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