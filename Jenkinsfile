pipeline {
    agent any
    
    environment {
        // Lấy tên branch và commit ID
        BRANCH_NAME = "${env.BRANCH_NAME}"
        COMMIT_ID = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        
        // Credentials Docker Hub
        DOCKER_REGISTRY = 'chitaialm/petclinic'
    }
    
    stages {
        stage('Build and Push Docker Images') {
            steps {
                script {
                    // Hiển thị thông tin
                    echo "Building for branch: ${BRANCH_NAME}"
                    echo "Commit ID: ${COMMIT_ID}"
                    
                    def services = [
                        ['spring-petclinic-config-server', '8888'],
                        ['spring-petclinic-discovery-server', '8761'],
                        ['spring-petclinic-customers-service', '8081'],
                        ['spring-petclinic-visits-service', '8082'],
                        ['spring-petclinic-vets-service', '8083'],
                        ['spring-petclinic-genai-service', '8084'],
                        ['spring-petclinic-api-gateway', '8080'],
                        ['spring-petclinic-admin-server', '9090'],
                    ]
                    
                    // Đăng nhập vào Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    }
                    
                    // Build và push image cho từng service
                    services.each { service ->
                        def serviceName = service[0]
                        def servicePort = service[1]
                        echo "Building service: ${serviceName} on port: ${servicePort}"
                        
                        // Build Docker image với tag là commit ID và truyền SERVICE_NAME và SERVICE_PORT
                        sh """
                            docker build \
                            --build-arg SERVICE_NAME=${serviceName} \
                            --build-arg SERVICE_PORT=${servicePort} \
                            -t ${DOCKER_REGISTRY}:${serviceName}-${COMMIT_ID} .
                        """
                        
                        // Push image lên Docker Hub
                        sh "docker push ${DOCKER_REGISTRY}:${serviceName}-${COMMIT_ID}"
                        
                        // Nếu là branch main, cũng tag và push như main
                        if (BRANCH_NAME == 'main') {
                            sh "docker tag ${DOCKER_REGISTRY}:${serviceName}-${COMMIT_ID} ${DOCKER_REGISTRY}:${serviceName}-main"
                            sh "docker push ${DOCKER_REGISTRY}:${serviceName}-main"
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Successfully built and pushed all images with commit ID: ${COMMIT_ID}"
        }
        failure {
            echo "Pipeline failed. Please check the logs for details."
        }
        always {
            // Cleanup
            sh "docker system prune -f"
        }
    }
}
