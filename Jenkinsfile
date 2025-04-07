pipeline {
    agent any
    
    environment {
        // Lấy tên branch và commit ID
        BRANCH_NAME = ${env.BRANCH_NAME}
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
                        [name: 'spring-petclinic-config-server', port: '8888'],
                        [name: 'spring-petclinic-discovery-server', port: '8761'],
                        [name: 'spring-petclinic-customers-service', port: '8081'],
                        [name: 'spring-petclinic-visits-service', port: '8082'],
                        [name: 'spring-petclinic-vets-service', port: '8083'],
                        [name: 'spring-petclinic-genai-service', port: '8084']
                        [name: 'spring-petclinic-api-gateway', port: '8080'],
                        [name: 'spring-petclinic-admin-server', port: '9090'],
                    ]
                    
                    // Đăng nhập vào Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    }
                    
                    // Build và push image cho từng service
                    services.each { service ->
                        echo "Building service: ${service.name} on port: ${service.port}"
                        
                        // Build Docker image với tag là commit ID và truyền SERVICE_NAME và SERVICE_PORT
                        sh """
                            docker build \
                            --build-arg SERVICE_NAME=${service.name} \
                            --build-arg SERVICE_PORT=${service.port} \
                            -t ${DOCKER_REGISTRY}:${service.name}-${COMMIT_ID} .
                        """
                        
                        // Push image lên Docker Hub
                        sh "docker push ${DOCKER_REGISTRY}:${service.name}-${COMMIT_ID}"
                        
                        // Nếu là branch main, cũng tag và push như main
                        if (BRANCH_NAME == 'main') {
                            sh "docker tag ${DOCKER_REGISTRY}:${service.name}-${COMMIT_ID} ${DOCKER_REGISTRY}:${service.name}-main"
                            sh "docker push ${DOCKER_REGISTRY}:${service.name}-main"
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
    }
}
