pipeline {
    agent any

    environment {
        APP_NAME        = 'demo-app'
        REGISTRY_PUSH   = 'registry:5000'
        REGISTRY_PULL   = 'host.docker.internal:5000'
        IMAGE_TAG       = "${env.BUILD_NUMBER ?: 'latest'}"
        KUBECONFIG      = "${WORKSPACE}/kubeconfig"
        K8S_NAMESPACE   = 'demo'
        CLUSTER_NAME    = 'cicd-lab'
        SONAR_HOST      = 'http://sonarqube:9000'
        HELM_RELEASE    = 'demo-app'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    if (env.GIT_URL) {
                        checkout scm
                    } else {
                        echo 'Using workspace files (local mount or manual trigger).'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                dir('app') {
                    sh 'mvn -B -DskipTests clean package'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir('app') {
                    sh 'mvn -B test'
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'app/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    dir('app') {
                        sh """
                            mvn -B sonar:sonar \
                              -Dsonar.projectKey=${APP_NAME} \
                              -Dsonar.host.url=${SONAR_HOST} \
                              -Dsonar.login=\${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Terraform') {
            steps {
                sh 'chmod +x scripts/*.sh || true'
                sh './scripts/connect-jenkins-to-kind.sh || true'
                dir('terraform') {
                    sh 'terraform init -input=false'
                    sh 'terraform apply -auto-approve -input=false'
                }
                sh './scripts/connect-registry-to-kind.sh'
                sh './scripts/connect-jenkins-to-kind.sh'
            }
        }

        stage('Docker Build') {
            steps {
                dir('app') {
                    sh """
                        docker build -t ${REGISTRY_PUSH}/${APP_NAME}:${IMAGE_TAG} .
                        docker tag ${REGISTRY_PUSH}/${APP_NAME}:${IMAGE_TAG} ${REGISTRY_PULL}/${APP_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Push to Registry') {
            steps {
                sh """
                    docker push ${REGISTRY_PUSH}/${APP_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    helm upgrade --install ${HELM_RELEASE} ./helm/demo-app \
                      --namespace ${K8S_NAMESPACE} \
                      --create-namespace \
                      --set image.repository=${REGISTRY_PULL}/${APP_NAME} \
                      --set image.tag=${IMAGE_TAG} \
                      --wait --timeout 5m
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl rollout status deployment/${HELM_RELEASE} -n ${K8S_NAMESPACE} --timeout=120s
                    kubectl get pods,svc -n ${K8S_NAMESPACE}
                    curl -sf http://localhost:30080/health
                    curl -sf http://localhost:30080/
                """
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check stage logs above.'
        }
    }
}
