#!/usr/bin/env groovy

pipeline {
    agent any
    environment {
        GITHUB_TOKEN = credentials('github-token') // ID của credential trong Jenkins
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Detect Changes') {
            steps {
                script {
                    def changedFiles = sh(returnStdout: true, script: "git diff --name-only HEAD^ HEAD").trim().split('\n')
                    def serviceDirs = [
                        "spring-petclinic-config-server",
                        "spring-petclinic-discovery-server",
                        "spring-petclinic-vets-service",
                        "spring-petclinic-customers-service",
                        "spring-petclinic-visits-service",
                        "spring-petclinic-apigateway",
                        "spring-petclinic-genai-service",
                        "spring-petclinic-ui"
                    ]
                    env.CHANGED_SERVICES = changedFiles.collect { file ->
                        serviceDirs.find { dir -> file.startsWith("${dir}/") }
                    }.findAll { it }.unique().join(',')
                    if (!env.CHANGED_SERVICES) {
                        echo "No changes in service directories."
                        notifyGitHub("success", "ci/jenkins", "No changes detected, build skipped.")
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                }
            }
        }
        stage('Test') {
            when { expression { env.CHANGED_SERVICES != null && env.CHANGED_SERVICES != '' } }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.split(',')
                    for (service in services) {
                        dir(service) {
                            sh "mvn test jacoco:report"
                            step([$class: 'JacocoPublisher',
                                  execPattern: 'target/jacoco.exec',
                                  classPattern: 'target/classes',
                                  sourcePattern: 'src/main/java',
                                  exclusionPattern: '**/*Test.class'])
                            junit 'target/surefire-reports/*.xml'
                            def coverageReport = readFile('target/site/jacoco/index.html')
                            def coverage = coverageReport.find(/<td>Total<\/td>.*?<td>(\d+\.\d+)/) { match, cov -> cov.toFloat() }
                            if (coverage < 0.7) {
                                error "Test coverage for ${service} is ${coverage*100}% (< 70%)"
                            }
                        }
                    }
                }
            }
        }
        stage('Build') {
            when { expression { env.CHANGED_SERVICES != null && env.CHANGED_SERVICES != '' } }
            steps {
                script {
                    def services = env.CHANGED_SERVICES.split(',')
                    for (service in services) {
                        dir(service) {
                            sh "mvn package -DskipTests"
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            notifyGitHub("success", "ci/jenkins", "Build and tests passed successfully.")
        }
        failure {
            notifyGitHub("failure", "ci/jenkins", "Build or tests failed.")
        }
    }
}

def notifyGitHub(String state, String context, String description) {
    def commitSha = env.GIT_COMMIT
    def repoUrl = "https://api.github.com/repos/Taihoclaptrinh/spring-petclinic-microservices/statuses/${commitSha}"
    def buildUrl = "${env.BUILD_URL}"
    def payload = """{
        "state": "${state}",
        "target_url": "${buildUrl}",
        "description": "${description}",
        "context": "${context}"
    }"""
    sh """
        curl -X POST \
        -H "Authorization: token ${env.GITHUB_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '${payload}' \
        "${repoUrl}"
    """
}