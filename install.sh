#!/bin/bash
# Generate config and secrets required to host your own outline server
set -e
shopt -s expand_aliases

HOST=${1:-localhost}
BUCKET_NAME=${3:-outline-bucket}

# download latest sample env for outline 
wget --quiet https://raw.githubusercontent.com/outline/outline/develop/.env.sample -O env.outline

if [ "$(uname)" == "Darwin" ]; then
    echo "sed commands here are tested only with GNU sed"
    echo "Installing gnu-sed"
    # https://unix.stackexchange.com/a/131940
    # brew install gnu-sed
    alias sed=gsed
fi

function env_add {
    key=$1
    val=$2
    filename=$3
    echo "${key}=${val}" >> $filename
}

function env_replace {
    key=$1
    val=$2
    filename=$3
    # sed -i "0,/name:/{s/${key}=.*/${key}='${val}'/}" $filename
    sed "s|${key}=.*|${key}=${val}|" -i $filename
}

function env_delete {
    key=$1
    filename=$2
    sed "/${key}/d" -i env.outline 
}

SECRET_KEY=`openssl rand -hex 32`
UTILS_SECRET=`openssl rand -hex 32`

env_replace SECRET_KEY $SECRET_KEY env.outline
env_replace UTILS_SECRET $UTILS_SECRET env.outline

env_delete DATABASE_URL
env_delete DATABASE_URL_TEST
env_delete REDIS_URL

env_replace URL "http://${HOST}" env.outline
env_replace PORT 3000 env.outline

echo "=> Open https://api.slack.com/apps and Create New App"
echo "=> After creating, scroll down to 'App Credentials'"

read -p "Enter App ID : " SLACK_APP_ID
read -p "Enter Client ID : " SLACK_KEY
read -p "Enter Client Secret : " SLACK_SECRET
read -p "Enter Verification Token (*not* Signing Secret): " SLACK_VERIFICATION_TOKEN

env_replace SLACK_APP_ID $SLACK_APP_ID env.outline
env_replace SLACK_KEY $SLACK_KEY env.outline
env_replace SLACK_SECRET $SLACK_SECRET env.outline
env_replace SLACK_VERIFICATION_TOKEN $SLACK_VERIFICATION_TOKEN env.outline

# Setup datastore
sed "s|outline-bucket|${BUCKET_NAME}|" -i nginx.conf
mkdir -p minio_root/$BUCKET_NAME pgdata
MINIO_ACCESS_KEY=`openssl rand -hex 8`
MINIO_SECRET_KEY=`openssl rand -hex 32`

rm -f env.minio
env_add MINIO_ACCESS_KEY $MINIO_ACCESS_KEY env.minio
env_add MINIO_SECRET_KEY $MINIO_SECRET_KEY env.minio
env_add MINIO_BROWSER off env.minio

env_replace AWS_ACCESS_KEY_ID $MINIO_ACCESS_KEY env.outline
env_replace AWS_SECRET_ACCESS_KEY $MINIO_SECRET_KEY env.outline
env_replace AWS_S3_UPLOAD_BUCKET_NAME $BUCKET_NAME env.outline
env_replace AWS_S3_UPLOAD_BUCKET_URL "http://${HOST}" env.outline
