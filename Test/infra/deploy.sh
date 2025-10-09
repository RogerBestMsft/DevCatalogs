#!/bin/bash

usage() { 
	echo "======================================================="
	echo "Usage: $0"
	echo "======================================================="
	echo " [REQUIRED] -c | --config 	        Config file"
    echo " [OPTIONAL] -s | --subscriptionId 	Subscription Id"
    echo " [OPTIONAL] -d | --debug 	        Show detailed output"
    echo "======================================================="
    echo ""
	exit 1; 
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEBUG=false

for i in "$@"; do
    case $1 in
        "" ) break ;;
        -c | --config ) CONFIGFILE="$2"; shift ;;
        -s | --subscriptionId ) SUBSCRIPTIONID="$2"; shift ;;
        -d | --debug ) DEBUG=true ;;
        -* | --*) echo "Unknown option: '$1'"; exit 1 ;;
        * ) echo "Unknown argument: '$1'"; exit 1 ;;
    esac
    shift
done

if [ -z "$CONFIGFILE" ]
then
    echo ""
    echo "Missing required -c | --config option"
    echo ""
    usage
    exit 1
fi

if [ -z "$SUBSCRIPTIONID" ]; then
    SUBSCRIPTIONID="$(jq --raw-output .subscriptionId $CONFIGFILE)"
fi

if [ -z "$SUBSCRIPTIONID" ] || [ "$SUBSCRIPTIONID" == "null" ]; then
    echo ""
    echo "A subscriptionId value must be provided in the specified config or by using the -s | --subscriptionId option"
    echo ""
    usage
    exit 1
fi

SECRETS_FILE="${CONFIGFILE%.*}-secrets.json"

if [ ! -f "$SECRETS_FILE" ]; then
    echo '{}' > "$SECRETS_FILE"
fi

echo "Deploying WinGit infrastructure from '$CONFIGFILE' ..."

if [ "$DEBUG" = true ]; then
    echo "Subscription ID: $SUBSCRIPTIONID"
    echo "Config file: $CONFIGFILE"
    echo "Secrets file: $SECRETS_FILE"
    echo "Location: $(jq --raw-output .location $CONFIGFILE)"
    echo ""
    echo "Starting Azure deployment..."
fi

# Build deployment command with conditional --only-show-errors flag
DEPLOYMENT_CMD="az deployment sub create \
    --subscription \"$SUBSCRIPTIONID\" \
    --name $(uuidgen) \
    --location \"$(jq --raw-output .location $CONFIGFILE)\" \
    --template-file ./bicep/main.bicep"

if [ "$DEBUG" != true ]; then
    DEPLOYMENT_CMD="$DEPLOYMENT_CMD --only-show-errors"
fi

DEPLOYMENT_CMD="$DEPLOYMENT_CMD \
    --parameters \
        config=@$CONFIGFILE \
        secrets=@$SECRETS_FILE \
    --query properties.outputs > ${CONFIGFILE%.*}.output.json && echo \"... done\""

eval $DEPLOYMENT_CMD