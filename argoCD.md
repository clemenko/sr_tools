# argoCD Notes



kubectl apply -f ../k8s_yaml/traefik_crd_deployment.yml

kubectl apply -f ../k8s_yaml/stackrox_traefik_crd.yml

kubectl apply -f ../k8s_yaml/argocd.yml

cat << EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: argocd-ingressroute
  namespace: argocd
spec:
  entryPoints:
    - tcp
  routes:
    - match: HostSNI(\`argo.dockr.life\`)
      services:
        - name: argocd-server
          port: 443
  tls:
    passthrough: true
EOF


# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2 | pbcopy

rm -rf ~/.argocd/config

argocd login argo.dockr.life:443 --username admin --password $(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2 )



argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace example

argocd app create jenkins --repo https://github.com/clemenko/stackargo.git --path jenkins --dest-server https://kubernetes.default.svc --dest-namespace jenkins



argocd app create stackrox --repo https://github.com/clemenko/stackargo.git --path central-bundle/central --dest-server https://kubernetes.default.svc --dest-namespace stackrox

argocd app create jenkins --repo https://github.com/clemenko/k8s_yaml.git --file https://raw.githubusercontent.com/clemenko/k8s_yaml/master/jenkins.yaml --dest-server https://kubernetes.default.svc --dest-namespace jenkins 
