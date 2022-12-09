#!/bin/bash


AVAILABLE_MODES=(init plan validate apply destroy)

############################################################
# Help                                                     #
############################################################
Help() {
   # Display Help
   echo "Welcome to Terraform CLI Extended"
   echo
   echo 
   echo "This is used the enrich the standard Terraform CLI with additional features like"
   echo "   - Support for dynamic git refs for module sources"
   echo
   echo 
   echo "Available options:"
   echo "-h     Displays help"
   echo "-m     terraform command. Choose from: ${AVAILABLE_MODES[*]}"
   echo \
   "-r     If GIT is used as module soures. 
       Replaces a given placeholder with -p without value of -r as the remote ref.
       This allows to use different refs for module input."
   echo \
   "-p     The placeholder that is used for the GIT remote ref.
       The script searches for occurences of ?ref=<your placeholder>, so make sure to use an unique placeholder.
       Do not use \\ in your placeholder!
       Should be used with -r!!"
   echo "-w     Terraform workspace name"
   echo "-b     Terraform backend config file"
   echo "-v     Terraform environment file to be used"
   echo "-c     Delete .terraform/modules and pull modules"
   echo "-o     Uses stored terraform plans"
   echo
   exit 0
}

while getopts hm:r:p:cb:w:v:o flag
do
    case "${flag}" in
        h) Help
           exit;;
        m) MODE=${OPTARG};;
        p) PLACEHOLDER=${OPTARG};;
        r) REMOTE_REF=${OPTARG};;
        b) BACKEND_CONFIG=${OPTARG};;
        w) WORKSPACE=${OPTARG};;
        v) VARS==${OPTARG};;
        c) CLEAR=true;;
        o) OUT=true;;
        \?) # Invalid option
         echo "[ERROR] Invalid option"
         exit;;
    esac
done

##########################################
##########  Dependency checks   ##########
##########################################

if ! terraform -v; then
    echo "[ERROR] Missing Terraform!"
    exit 1
fi

if ! git --version; then
    echo "[ERROR] Missing git!"
    exit 1
fi

##########################################
###############  Mode check   ############
##########################################

if [[ ${AVAILABLE_MODES[*]} =~ (^|[[:space:]])"$MODE"($|[[:space:]]) ]]; then
    echo "Preparing terraform $MODE ..."
else
    echo "[ERROR] Invalid mode! Set -m to: ${AVAILABLE_MODES[*]}";
    echo "        Aborting!"
    exit 1
fi

##########################################
############ Implementation   ############
##########################################

ADDITIONAL_ARGS=""
appendAdditionalParameters() {
    if ! [[ -z "$VARS" ]]; then
        ADDITIONAL_ARGS="$ADDITIONAL_ARGS -var-file=$VARS"
    fi

    if [[ "$MODE" == "destroy" ]]; then
        ADDITIONAL_ARGS="${ADDITIONAL_ARGS} -auto-approve"        
    fi

    if [[ "$MODE" == "apply" ]]; then
        if ! [[ "$OUT" == "true" ]]; then
            ADDITIONAL_ARGS="${ADDITIONAL_ARGS} -auto-approve"
        fi
        if [[ "$OUT" == "true" ]]; then
            ADDITIONAL_ARGS="terraform.plan ${ADDITIONAL_ARGS}"
        fi
    fi

    if [[ "$MODE" == "plan" ]]; then
        if [[ "$OUT" == "true" ]]; then
            ADDITIONAL_ARGS="${ADDITIONAL_ARGS} -out terraform.plan"
        fi
    fi
}

checkPlaceholder(){
    if [[ $PLACEHOLDER == *['!@\$%^\&*\\']* ]]; then
        echo
        echo -e "[ERROR] Your placeholder contains invalid characters!"
        echo    "        Avoid using !@\$%^\&*\\"
        echo    "        Aborting!"
        STATE=1
        exit 1
    fi
}

runTerraform() {
    if ! [[ -z "$WORKSPACE" ]]; then
        echo "Using terraform workspace $WORKSPACE"
        terraform workspace select $WORKSPACE

        rsp=$?
        if [ $rsp -ne 0 ]; then
            echo "[ERROR] Could not complete execution"
            STATE=$rsp
            exit 1
        fi
    fi

    if [[ "$CLEAR" == "true" ]]; then
        echo "Clearing .terraform/modules ..."
        rm -rf .terraform/modules
        echo "Re-pulling terraform modules..."
        terraform get 

        rsp=$?
        if [ $rsp -ne 0 ]; then
            echo "[ERROR] Could not complete execution"
            STATE=$rsp
            exit 1
        fi
    fi


    if [[ "$MODE" == "init" ]]; then
        echo "init"
        terraform $MODE -backend-config=$BACKEND_CONFIG

        rsp=$?
        if [ $rsp -ne 0 ]; then
            echo "[ERROR] Could not complete execution"
            STATE=$rsp
            exit 1
        fi
    fi

    appendAdditionalParameters
    echo "Running terraform $MODE $ADDITIONAL_ARGS"
    terraform $MODE $ADDITIONAL_ARGS

    rsp=$?
    if [ $rsp -ne 0 ]; then
        echo "[ERROR] Could not complete execution"
        return $rsp
    fi
}

replacePlaceholder() {
    if ! [ -z "$PLACEHOLDER" ]; then
        echo "Replacing placeholder $PLACEHOLDER with $REMOTE_REF"
        sed -i "s\\?ref=$PLACEHOLDER\\?ref=$REMOTE_REF\g" ./**/*.tf
    fi
}

revertPlaceholder() {
    if ! [ -z "$PLACEHOLDER" ]; then
        echo "Reverting $REMOTE_REF with $PLACEHOLDER"
        sed -i "s\\?ref=$REMOTE_REF\\?ref=$PLACEHOLDER\g" ./**/*.tf
    fi

}

##########################################
#################  RUN  ##################
##########################################

checkPlaceholder
replacePlaceholder

runTerraform 
STATE=$?

revertPlaceholder

exit $STATE
