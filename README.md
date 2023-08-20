    # Task description

-  1  => Create a github repo
-  2  => Create a Jenkins a multibranch pipeline
-  3  => Unit test stage
-  4  => Build stage
-  5  => Deploy springboot app to local Minikub
-  6  => Dev deployment
-  7  => Prod deployment
-  8 => README file to explain the above



### prerequisite
- ##### Docker
- ##### Kubernetes
- ##### minikube
- ##### jenkins with Docker pipeline plugin

#### deployment design
```diff 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-app-deployment-dev
  labels:
    app: spring-app-deployment-dev

spec:
  selector:
    matchLabels:
      app: spring-app-deployment-dev
  replicas: 1
  template:
    metadata:
      labels:
        app: spring-app-deployment-dev
    spec:
      containers:
        - name: spring-app-container-dev
          image: DockerImageToPull
          ports:
            - containerPort: 8081
          resources:
            limits:
              cpu: 100m  
              memory: 200Mi  
            requests:
              cpu: 5m  
              memory: 20Mi  
          livenessProbe:
            httpGet:
              path: /hello
              port: 8081
            initialDelaySeconds: 30
            periodSeconds: 25
          readinessProbe:
            httpGet:
              path: /hello
              port: 8081
            initialDelaySeconds: 60
            periodSeconds: 20
```  

## Maven test stage
```diff 
--    Maven test stage 

    stage('Maven test') {
        agent {
            docker { 
                image 'openjdk:latest'
            }
        }

        steps {
            dir("./app") {
                sh "./mvnw test"
            }
        }
    }

```
<!-- ![plot](/images/999.png) -->

#### maven build stage

```diff
--  Maven build stage
    stage('Maven build') {
        agent {
            docker {
                image 'openjdk:latest'
            }
        }

        steps {
            dir("./app") {
                sh "./mvnw clean"
                sh "./mvnw install"
            }
        }
    }

 ```
<!-- ![plot](/images/5.png) -->

## Buliding a docker image for the attached spring boot project and pushing to dockerhub stage

```diff 
    stage('Docker Build') {
        steps {
            dir("./app") {
                sh "docker build -t sherifemad21/spring-deployment:spring-app-${env.BUILD_ID} ."
            }
        }
    }

    stage('Docker Push') {
        steps {
            sh "docker push sherifemad21/spring-deployment:spring-app-${env.BUILD_ID}"
            sh "docker rmi -f sherifemad21/spring-deployment:spring-app-${env.BUILD_ID}"
        }
    }
-- Docker file ------------------------------------
    FROM openjdk:latest

    #To add the runnable jar file of the backend project to the container
    ADD ./target/spring-app-docker.jar spring-app-docker.jar

    #To specify the command that runs the jar files in the /bin/bash in the container
    ENTRYPOINT ["java" ,"-jar", "/spring-app-docker.jar"]

-- ---------------------------------------------------     

```
<!-- ![plot](/images/6.png)
![plot](/images/7.png)
![plot](/images/101010.png) -->

## Deploy springboot app to local Minikub
```diff 
-- we need to check for the namespace first
    stage('Check namespaces') {
        steps {
            dir("./bash_scripts") {
                sh "chmod +x namespaceCheck.sh"
                sh "./namespaceCheck.sh"
            }
        }
    }
--  namespaceCheck script -----------------------
    #!/bin/bash

    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
    echo "Minikube is not running."
    exit 1
    fi

    # Check if the 'dev' namespace exists
    if kubectl get namespace dev &> /dev/null; then
    echo "Namespace 'dev' exists."
    else
    echo "Namespace 'dev' does not exist. Creating..."
    kubectl create namespace dev
    echo "Namespace 'dev' created."
    fi

    # Check if the 'production' namespace exists
    if kubectl get namespace production &> /dev/null; then
    echo "Namespace 'production' exists."
    else
    echo "Namespace 'production' does not exist. Creating..."
    kubectl create namespace production
    echo "Namespace 'production' created."
    fi


```

## Dev deployment
```diff
--  dev deployment 

    stage('Deploy to dev') {
-- on dev
        when {
            branch 'dev'
        }
        steps {
            dir("./k8s_files") {
                sh """
                    sed "s|DockerImageToPull|docker.io/sherifemad21/spring-deployment:
                    spring-app-${BUILD_ID}|g" spring-deployment-template-dev.yaml > 
                    spring-deployment-dev.yaml
                """

                sh "kubectl apply -f spring-deployment-dev.yaml -n dev"
            }
        }
        post {
            success {
                sh """
                    echo "Development deployment successful" 
                """
            }
            failure {

                sh """
                    echo "Development deployment failed" 
                """

                sh 'kubectl rollout undo deployment/spring-app-deployment-dev -n dev'
                sh 'kubectl rollout undo svc/spring-app-service-dev -n dev'
            }
        }
    }

```
<!-- ![plot](/images/9.png) -->
## Smake Test for dev
```diff
-- Smoke Test on Dev
    stage('Smoke test dev') {
        when{
            branch 'dev'
        }
        steps {
            dir("./bash_scripts") {
                sh "chmod +x smokeTestDev.sh"
                sh "./smokeTestDev.sh"
            }
        }
    }

--  smokeTestDev script -----------------------
    #!/bin/bash

    # Function to check if the pod is running
    function check_pod_status {
        status=$(kubectl get pods -l app=spring-app-deployment-dev -o jsonpath=
        '{.items[0].status.phase}' -n dev)
        if [ "$status" != "Running" ]; then
            echo "Pod is not yet running. Waiting..."
            sleep 5
            check_pod_status
        fi
    }

    # Wait for the pod to be running
    check_pod_status

    # Run the command and store the output in a variable
    url=$(minikube service spring-app-service-dev -n dev --url)

    url="${url}/hello"

    echo $url

    num_requests=1

    for ((i=1; i<=5; i++))
    do
        for ((j=1; j<=$num_requests; j++)); do
            while true; do
                curl "$url" && break  # Break the loop on successful connection
                sleep 1
            done
        done

        sleep 1;

    done

```


<!-- ![plot](/images/10.png) -->

## Prod deployment
```diff
-- production deployment
    stage('Deploy to production') {
-- on master
        when {
            branch 'master'
        }
        steps {
            dir("./k8s_files") {
                sh """
                    sed "s|DockerImageToPull|docker.io/sherifemad21/spring-deployment:
                    spring-app-${BUILD_ID}|g" spring-deployment-template-prod.yaml > 
                    spring-deployment-prod.yaml
                """
                
                sh "kubectl apply -f spring-deployment-prod.yaml -n production"
            }
        }
        post {
            success {
                sh """
                    echo "Production deployment successful" 
                """

            }
            failure {
                sh """
                    echo "Production deployment failed" 
                """

                sh 'kubectl rollout undo deployment/spring-app-deployment-prod -n prod'
                sh 'kubectl rollout undo svc/spring-app-service-prod -n prod'
            }
        }
    }

```
<!-- ![plot](/images/10.png) -->


## Smoke Test for prod
```diff 
    stage('Smoke test prod') {
        when{
            branch 'master'
        }
        steps {
            dir("./bash_scripts") {
                sh "chmod +x smokeTestProd.sh"
                sh "./smokeTestProd.sh"
            }
        }
    }
--  smokeTestProd script -----------------------
    #!/bin/bash

    # Function to check if the pod is running
    function check_pod_status {
        status=$(kubectl get pods -l app=spring-app-deployment-prod -o jsonpath=
        '{.items[0].status.phase}' -n production)
        if [ "$status" != "Running" ]; then
            echo "Pod is not yet running. Waiting..."
            sleep 5
            check_pod_status
        fi
    }

    # Wait for the pod to be running
    check_pod_status

    # Run the command and store the output in a variable
    url=$(minikube service spring-app-service-prod -n production --url)

    url="${url}/hello"

    echo $url

    num_requests=1

    for ((i=1; i<=5; i++))
    do
        for ((j=1; j<=$num_requests; j++)); do
            while true; do
                curl "$url" && break  # Break the loop on successful connection
                sleep 1
            done
        done

        sleep 1;

    done
```
<!-- ![plot](/images/55.png) -->
