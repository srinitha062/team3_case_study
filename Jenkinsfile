pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = 'aws-credentials'                           // AWS credentials stored in Jenkins
        TF_DIR = './terraformfiles'                                   // Path to your Terraform configuration
        ANSIBLE_PLAYBOOK_PATH = './ansiblefiles'  // Path to your Ansible playbook
        ANSIBLE_INVENTORY_PATH = '/etc/ansible/aws_ec2.yml'           // Path to your Dynamic Inventory
    }

    stages {
        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS]]) {
                        sh """
                            cd ${TF_DIR}
                            terraform init
                        """
                    }
                }
            }
        }

        stage('Terraform Plan & Apply') {
            steps {
                script {
                    // Apply Terraform configuration to create EC2 instance
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS]]) {
                        sh """
                            cd ${TF_DIR}
                            terraform plan -out ec2plan
                            terraform apply ec2plan
                        """
                    }
                }
            }
        }

        stage('Root Cause Analysis') {
            steps {
                script {
                    // Run the Ansible RCA playbook to gather CPU and Memory data
                    def rcaOutput = sh(script: 'ansible-playbook ./ansiblefiles/rca.yml', returnStdout: true).trim()

                    echo "RCA Output: ${rcaOutput}"

                    // Extract flags from the playbook output (assuming they're set as debug messages in Ansible)
                    def cpuHigh = rcaOutput.contains("CPU High: True") ? "true" : "false"
                    def memoryHigh = rcaOutput.contains("Memory High: True") ? "true" : "false"

                    // Set flags as environment variables for use in later stages
                    env.CPU_UTILIZATION_HIGH = cpuHigh
                    env.MEMORY_UTILIZATION_HIGH = memoryHigh

                    echo "CPU High: ${env.CPU_UTILIZATION_HIGH}, Memory High: ${env.MEMORY_UTILIZATION_HIGH}"
                }
            }
        }

        stage('Remediation') {
            when {
                expression {
                    // Run remediation if either CPU or Memory is above the threshold
                    return env.CPU_UTILIZATION_HIGH == 'true' || env.MEMORY_UTILIZATION_HIGH == 'true'
                }
            }
            steps {
                script {
                    echo 'Either CPU or Memory utilization is high. Running remediation playbook to clean up /tmp...'
                    sh 'ansible-playbook ${ANSIBLE_PLAYBOOK_PATH}/remediation.yml'
                }
            }
        }

        stage('Post-Check') {
            when {
                expression {
                    // Run remediation if either CPU or Memory is above the threshold
                    return env.CPU_UTILIZATION_HIGH == 'true' || env.MEMORY_UTILIZATION_HIGH == 'true'
                }
            }
            steps {
                script {
                    echo 'Rechecking CPU and Memory utilization after cleanup...'
                    sh 'ansible-playbook ${ANSIBLE_PLAYBOOK_PATH}/post_check.yml'
                }
            }
        }

        stage('Everything is Fine') {
            steps {
                script {
                    echo 'CPU and Memory utilization are within normal limits. Everything is fine.'
                }
            }
        }
    }

    post {
        success {
            echo 'All stages completed successfully.'
        }
    }
}