#!/bin/bash

# Reset
ResetCl='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BOLD='\033[0;1m'          # Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

function run_command() {
    command=$@
    logging_message "CMD" "$@"    
    eval "${command}" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        logging_message "OK"
        return 0
    else
        logging_message "FAIL"
        return 1
    fi
}

function logging_message() {
    # cmd_log="tee -a ${SCRIPT_LOG}/script_${TODAY}.log"
    run_today=$(date "+%y%m%d")
    run_time=$(date "+%H:%M:%S.%3N")
  
    log_time="${run_today} ${run_time}"
    log_type=$1
    log_msg=$2

    # printf "%-*s | %s\n" ${STR_LEGNTH} "Server Serial" "Unknown" |tee -a ${LOG_FILE} >/dev/null
    case ${log_type} in
        "CMD"   ) printf "%s | ${BOLD}%-*s${ResetCl} | ${BOLD}%s${ResetCl}\n"  "${log_time}" 7 "${log_type}" "${log_msg}"   ;;
        "OK"    ) printf "%s | ${Green}%-*s${ResetCl} | ${Green}%s${ResetCl}\n"  "${log_time}" 7 "${log_type}" "command ok."   ;;
        "FAIL"  ) printf "%s | ${Red}%-*s${ResetCl} | ${Red}%s${ResetCl}\n"      "${log_time}" 7 "${log_type}" "command fail." ;;
        "INFO"  ) printf "%s | ${Cyan}%-*s${ResetCl} | %s${ResetCl}\n"           "${log_time}" 7 "${log_type}" "${log_msg}"   ;;
        "WARR"  ) printf "%s | ${Red}%-*s${ResetCl} | %s${ResetCl}\n"            "${log_time}" 7 "${log_type}" "${log_msg}"   ;;
        "SKIP"  ) printf "%s | ${Yellow}%-*s${ResetCl} | %s${ResetCl}\n"         "${log_time}" 7 "${log_type}" "${log_msg}"   ;;
        "ERROR" ) printf "%s | ${BRed}%-*s${ResetCl} | %s${ResetCl}\n"           "${log_time}" 7 "${log_type}" "${log_msg}"   ;;
        # "CMD"   ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "${log_msg}"   |tee -a ${LOG_FILE} >/dev/null ;;
        # "OK"    ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "command ok."   |tee -a ${LOG_FILE} >/dev/null ;;
        # "FAIL"  ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "command fail." |tee -a ${LOG_FILE} >/dev/null ;;
        # "INFO"  ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "${log_msg}"   |tee -a ${LOG_FILE} >/dev/null ;;
        # "WARR"  ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "${log_msg}"   |tee -a ${LOG_FILE} >/dev/null ;;
        # "ERROR" ) printf "%s | %-*s | %s\n" "${log_time}" 7 "${log_type}" "${log_msg}"   |tee -a ${LOG_FILE} >/dev/null ;;
    esac
}

function help_message() {
    echo -e "$(cat <<EOF
Usage: ${BOLD}$0 [Options] -c --vcpu 4 --mem 4 --disk 4${ResetCl}
Options:
-c                    : Falvor create
-r                    : Flavor remove
-n [ flavor name]     : Flavor name (Use only when in delete mode.)
--vcpu  [ int ]       : vCPU cores
--mem   [ int ]       : Memory size(GiB)
--disk  [ int ]       : Disk size(GiB)
-p [ Auth file path ] : Openstack API Enviroment file path (default. $(dirname $0)/adminrc)
-h, --help            : Script Help
EOF
)"
    exit 0
}

function set_opts() {
    arguments=$(getopt --options p:n:crh \
    --longoptions vcpu:,mem:,disk:,help: \
    --name $(basename $0) \
    -- "$@")

    eval set -- "${arguments}"
    while true; do
        case "$1" in
            -c  ) MODE="create"  ; shift   ;;
            -r  ) MODE="remove"   ; shift   ;;
            -n  ) FLAVOR_NAME=$2  ; shift 2 ;;
            -p  ) OPENSTACK_API_PATH=$2 ; shift 2 ;;
            --vcpu  ) CORE=$2     ; shift 2 ;;
            --mem   ) MEM=$2      ; shift 2 ;;
            --disk  ) DISK=$2     ; shift 2 ;;
            -h | --help     ) help_message              ;;            
            --              ) shift           ; break   ;;
            ?               ) help_message              ;;
        esac
    done

    if [ -n ${MODE} ]; then
        shift $((OPTIND-1))
    else
        logging_message "ERROR" "using option requried [ -c or -r ] and [ -n ]."
        exit 1
    fi
}

function flavor_create() {
    _MEM_SIZE=$(expr ${MEM} \* 1024)
    FLAVOR_NAME="${CORE}c${MEM}g${DISK}g"
    if openstack flavor list |grep -q "${FLAVOR_NAME}" ; then
        logging_message "ERROR" "Exist flaovr name."
        return 1
    else
        run_command "openstack flavor create --vcpus ${CORE} --ram ${_MEM_SIZE} --disk ${DISK} --public -f json -c name -c id -c vcpus -c ram -c disk ${FLAVOR_NAME} >.flavor_out.json"
        if [ $? -eq 0 ]; then
            _FLAVOR_ID=$(jq -r .id .flavor_out.json)
            _FLAVOR_NAME=$(jq -r .name .flavor_out.json)
            [ -f .flavor_out.json ] && rm -f .flavor_out.json
            logging_message "INFO" "NAME: ${_FLAVOR_NAME} | UUID: ${_FLAVOR_ID}"
            return 0
        else
            return 1
        fi
    fi
}

function flavor_remove() {
    if ! openstack flavor list |grep -q "${FLAVOR_NAME}" ; then
        logging_message "ERROR" "Not found flavor name."
        return 1
    else
        run_command "openstack flavor delete ${FLAVOR_NAME}"
        if [ $? -eq 0 ]; then
            return 0
        else
            logging_message "ERROR" "Delete fail."
            return 1
        fi
    fi
}

function main() {
    [ $# -eq 0 ] && help_message
    set_opts "$@"
    
    if [ -n "${OPENSTACK_API_PATH}" ]; then
        source ${OPENSTACK_API_PATH}
    else
        OPENSTACK_API_PATH="$(dirname $0)/adminrc"
        if [ -f ${OPENSTACK_API_PATH} ]; then
            source ${OPENSTACK_API_PATH}
        else
            logging_message "ERROR" "File not found ${OPENSTACK_API_PATH}"
            exit 1
        fi
    fi

    case ${MODE} in
        "create" )
            if [[ -n "${CORE}" && "${MEM}" && "${DISK}" ]]; then
                FLAVOR_SPEC=$(echo "${CORE}c${MEM}g${DISK}g")
                flavor_create "${FLAVOR_SPEC}"
            else
                logging_message "ERROR" "using option requried [ --vcpu, --mem, --disk]."
                exit 1
            fi
        ;;
        "remove"  )
            if [ -n "${FLAVOR_NAME}" ]; then
                flavor_remove
            else
                logging_message "ERROR" "Use wit [ -n ] optin when using the remove mode."
                exit 1
            fi
        ;;
    esac
}
main $*