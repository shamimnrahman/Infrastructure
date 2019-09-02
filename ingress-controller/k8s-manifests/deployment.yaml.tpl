apiVersion: apps/v1
kind: Deployment
metadata:
  name: alb-ingress-controller
  namespace: kube-system
  labels:
    app: alb-ingress-controller
    component: controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alb-ingress-controller
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: alb-ingress-controller
        component: controller
    spec:
      serviceAccountName: alb-ingress
      containers:
        - name: server
          image: quay.io/coreos/alb-ingress-controller:1.0-beta.6
          imagePullPolicy: IfNotPresent
          args:
            - /server
            - --cluster-name=${cluster_name}
            - --alb-name-prefix=${cluster_name}
            - --target-type=ip
          env:
            - name: AWS_REGION
              value: ${aws_region}
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
          ports:
            - containerPort: 10254
              protocol: TCP
          readinessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 1
          livenessProbe:
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 60
      terminationGracePeriodSeconds: 60
