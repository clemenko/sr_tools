#argoCD Notes



kubectl apply -f ../k8s_yaml/traefik_crd_deployment.yml

./rancher.sh rox

kubectl apply -f ../k8s_yaml/stackrox_traefik_crd.yml

kubectl apply -f ../k8s_yaml/argocd.yml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2 | pbcopy





argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default

argocd app create sock --repo https://github.com/argoproj/argocd-example-apps.git --path sock-shop --dest-server https://kubernetes.default.svc --dest-namespace default

argocd app create jenkins --repo https://github.com/clemenko/stackargo.git --path jenkins --dest-server https://kubernetes.default.svc --dest-namespace jenkins



argocd app create stackrox --repo https://github.com/clemenko/stackargo.git --path central-bundle/central --dest-server https://kubernetes.default.svc --dest-namespace stackrox

argocd app create jenkins --repo https://github.com/clemenko/k8s_yaml.git --file https://raw.githubusercontent.com/clemenko/k8s_yaml/master/jenkins.yaml --dest-server https://kubernetes.default.svc --dest-namespace jenkins 
