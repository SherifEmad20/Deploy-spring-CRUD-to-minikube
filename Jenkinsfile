pipeline {
    agent any

    environment {
        USER_CREDENTIALS = credentials('docker_account')
    }

    stages {
        stage('Maven test') {
            agent {
                docker { 
                    image 'openjdk:latest'
                }
            }

            steps {
                dir("./app") {
                    sh "chmod +x mvnw"
                    sh "./mvnw test"
                }
            }
        }
        
        stage('Maven build') {
            agent {
                docker {
                    image 'openjdk:latest'
                }
            }

            steps {
                dir("./app") {
                    sh "chmod +x mvnw"
                    sh "./mvnw clean"
                    sh "./mvnw install"
                }
            }
        }

        stage('Docker Credentials') {
            steps {
                sh 'docker logout'
                sh "echo ${USER_CREDENTIALS_USR}"
                sh "echo ${USER_CREDENTIALS_PSW}"
                sh "docker login -u ${USER_CREDENTIALS_USR} -p ${USER_CREDENTIALS_PSW}"
            }
        }

        stage('Docker Build') {
            steps {
                dir("./app") {
                    sh "docker build -t sherifemad21/school-backend:spring-app-${env.BUILD_ID} ."
                }
            }
        }

        stage('Docker Push') {
            steps {
                sh "docker push sherifemad21/school-backend:spring-app-${env.BUILD_ID}"
                sh "docker rmi -f sherifemad21/school-backend:spring-app-${env.BUILD_ID}"
            }
        }

        stage('Check namespaces') {
            steps {
                dir("./bash_scripts") {
                    sh "chmod +x namespaceCheck.sh"
                    sh "./namespaceCheck.sh"
                }
            }
        }

        stage('Deploy to dev') {
            when {
                branch 'dev'
            }
            steps {
                dir("./k8s_files") {
                    sh """
                        sed "s|DockerImageToPull|docker.io/sherifemad21/school-backend:spring-app-${BUILD_ID}|g" school-backend-deployment-template-dev.yaml > school-backend-deployment-dev.yaml
                    """

                    // sh "kubectl config set-context --current --namespace=dev"
                    sh "kubectl apply -f school-backend-deployment-dev.yaml -n dev"
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

                    sh 'kubectl rollout undo deployment/school-backend-deployment-deployment-dev -n dev'
                    sh 'kubectl rollout undo svc/school-backend-deployment-service-dev -n dev'
                }
            }
        }

        stage('Deploy to production') {
            when {
                branch 'master'
            }
            steps {
                dir("./k8s_files") {
                    sh """
                        sed "s|DockerImageToPull|docker.io/sherifemad21/school-backend:spring-app-${BUILD_ID}|g" school-backend-deployment-template-prod.yaml > school-backend-deployment-prod.yaml
                    """
                    
                    // sh "kubectl config set-context --current --namespace=production"
                    sh "kubectl apply -f school-backend-deployment-prod.yaml -n production"
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

                    sh 'kubectl rollout undo deployment/school-backend-deployment-prod -n prod'
                    sh 'kubectl rollout undo svc/school-backend-service-prod -n prod'
                }
            }
        }

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
    }
}
