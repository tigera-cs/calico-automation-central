pipeline {
    agent any
    environment {
        // Existing environment variables
        PROJECT_ID = 'tigera-customer-success'             // Your Google Cloud project ID
        IMAGE_NAME = 'faisal-test'                         // Your desired image name
        BRANCH_NAME = 'main'                               // The branch to build from
        REPO_NAME = 'faisal-test-gcr-artifactory'          // Your Artifact Registry repository name
        LOCATION = 'northamerica-northeast2'               // The location of your Artifact Registry repository
        REGISTRY = 'northamerica-northeast2-docker.pkg.dev'// The Artifact Registry hostname

        // Calico Image Assurance variables
        CALICO_SCANNER_URL = 'https://installer.calicocloud.io/tigera-scanner/v3.20.0-1.0-10/image-assurance-scanner-cli-linux-amd64'
        CALICO_SCANNER_API_URL = 'https://qq9psbdn-management.calicocloud.io/bast'  // Replace with your actual API URL if different
        CALICO_SCANNER_FAIL_THRESHOLD = '9.0'  // Fail build if vulnerabilities exceed this score
        CALICO_SCANNER_WARN_THRESHOLD = '7.0'  // Warn if vulnerabilities exceed this score
    }
    stages {
        stage('Checkout') {
            steps {
                git(
                    url: 'https://github.com/tigera-cs/jenkins-cicd-calico-scanner.git',
                    branch: "${BRANCH_NAME}",
                    credentialsId: 'git-credentials'
                )
            }
        }
        stage('Set COMMIT_HASH') {
            steps {
                script {
                    // Retrieve the short commit hash and assign it to an environment variable
                    env.COMMIT_HASH = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
                // Print the COMMIT_HASH to the console for verification
                echo "COMMIT_HASH is ${COMMIT_HASH}"
            }
        }
        stage('Authenticate with Artifact Registry') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "Activating service account..."
                        gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet

                        echo "Configuring Docker to use Artifact Registry..."
                        gcloud auth configure-docker ${REGISTRY} --quiet
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${REGISTRY}/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${COMMIT_HASH} .
                '''
            }
        }
        stage('Scan Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'calico-scanner-token', variable: 'CALICO_SCANNER_TOKEN')]) {
                    sh '''
                        echo "Downloading and preparing Calico Image Assurance Scanner..."
                        curl -Lo tigera-scanner ${CALICO_SCANNER_URL}
                        chmod +x tigera-scanner

                        echo "Scanning Docker image for vulnerabilities..."
                        ./tigera-scanner scan \
                            --apiurl ${CALICO_SCANNER_API_URL} \
                            --token ${CALICO_SCANNER_TOKEN} \
                            ${REGISTRY}/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${COMMIT_HASH} \
                            --fail_threshold ${CALICO_SCANNER_FAIL_THRESHOLD} \
                            --warn_threshold ${CALICO_SCANNER_WARN_THRESHOLD}
                        
                        # Clean up
                        rm tigera-scanner
                    '''
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "Pushing Docker image to Artifact Registry..."
                    docker push ${REGISTRY}/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${COMMIT_HASH}
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
