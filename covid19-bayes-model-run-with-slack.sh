if ! bash "/covid19-bayes-model-docker-run.sh"; then
    echo "JOBFAIL: covid19-bayes-model job"
    if [[ -n "$slackWebHook" && "$slackWebHook" != "None" ]]; then
        echo "Posting failed message to slack.."
        payload="{\"attachments\": [{\"fallback\": \"JOBFAIL: covid19-bayes-model job on ${gen3Env}\",\"color\": \"#ff0000\",\"pretext\": \"JOBFAIL: covid19-bayes-model job on ${gen3Env}\",\"author_name\": \"Pod name: ${HOSTNAME}\",\"title\": \"COVID19-BAYES-MODEL JOB FAILED\",\"text\": \"JOBFAIL: covid19-bayes-model job on ${gen3Env}\",\"ts\": "$(date +%s)"}]}"
        echo "${payload}"
        curl -X POST --data-urlencode "payload=${payload}" "${slackWebHook}"
    fi
else
    echo "JOBSUCCESS: covid19-bayes-model job"
    if [[ -n "$slackWebHook" && "$slackWebHook" != "None" ]]; then
        echo "Posting success message to slack.."
        payload="{\"attachments\": [{\"fallback\": \"JOBSUCCESS: covid19-bayes-model job on ${gen3Env}\",\"color\": \"#2EB67D\",\"pretext\": \"JOBSUCCESS: covid19-bayes-model job on ${gen3Env}\",\"author_name\": \"Pod name: ${HOSTNAME}\",\"title\": \"COVID19-BAYES-MODEL JOB SUCCEDED :tada:\",\"text\": \"JOBSUCCESS: covid19-bayes-model job on ${gen3Env}\",\"ts\": \"$(date +%s)\"}]}"
        curl -X POST --data-urlencode "payload=${payload}" "${slackWebHook}"
    fi
fi
