# Setting up prometheus multi-cluster monitoring

## Install prometheus
```
kubectl create configmap prometheus-cm --from-file 01-prometheus-config-map.yaml
kubectl apply -f 02-prometheus-deployment.yaml
```

```
kubectl port-forward deploy/prometheus-deployment 9090:9090
```
Open your browser at http://localhost:9090/targets

You should see that prometheus is up and running and monitoring itself.

## Change the config to scrape k8s metrics
Create a cluster role to allow prometheus to scrape cluster metrics
```
kubectl apply -f 03-clusterrole-prometheus.yaml
```

Apply the new scrape config to also scrape k8s metrics:
```
kubectl apply -f 04-k8s-scrape-config.yaml
```
> More k8s metrics can be added from checking out this sample config: https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml

Change the deployment to use the service account we created:
```
kubectl delete -f 02-prometheus-deployment.yaml
kubectl apply -f 05-adjusted-prom-deployment.yaml
```

## Scrape metrics from a different cluster
Change the kubectl context to the second cluster and run
```
kubectl apply -f 03-clusterrole-prometheus.yaml
```
This will create the same cluster role binding and service account in prometheus so that we're able to scrape.

Now you need to find out the API server IP address, the bearer token of the created service account and the ca.crt to talk to the API server. For this run
`./06-get-tokens.sh`.

Switch the kubectl context back to the cluster running prometheus.

Paste the certifacte from the console output into the right spot in 07-remote-cluster-secrets.yaml. Same for the bearer token.

In 08-remote-scrape-config.yaml replace the API server IP in two positions under the `kubernetes-nodes-scrape-target` job.

Run the following:
```
kubectl apply -f 07-remote-cluster-secrets.yaml
kubectl apply -f 08-remote-scrape-config.yaml
kubectl delete -f 05-adjusted-prom-deployment.yaml
kubectl apply -f 09-remote-scrape-deployment.yaml
```

# Setup all the above with kind

> kind doesn't show all the resources that a hyperscaler cluster does.

```
kind create cluster --name prom-cluster
kind create cluster --name scrape-cluster
kubectl apply -f 03-clusterrole-prometheus.yaml
./06-get-tokens.sh
```

Now change the `08-remote-scrape-config.yaml`.

```
kubectl config use-context kind-prom-cluster
kubectl apply -f 03-clusterrole-prometheus.yaml
kubectl apply -f 07-remote-cluster-secrets.yaml
kubectl apply -f 08-remote-scrape-config.yaml
kubectl apply -f 09-remote-scrape-deployment.yaml
```

Now everything should be started and you can do
```
kubectl port-forward deploy/prometheus-deployment 9090:9090
```
Open your browser at http://localhost:9090/targets