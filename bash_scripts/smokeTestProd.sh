#!/bin/bash

# Function to check if the pod is running
function check_pod_status {
    status=$(kubectl get pods -l app=school-backend-deployment-prod -o jsonpath='{.items[0].status.phase}' -n production)
    if [ "$status" != "Running" ]; then
        echo "Pod is not yet running. Waiting..."
        sleep 5
        check_pod_status
    fi
}

# Wait for the pod to be running
check_pod_status

# Run the command and store the output in a variable
url=$(minikube service school-backend-service-prod -n production --url)

url="${url}/api/student/getStudents"

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