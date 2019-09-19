# Call SVs on a hgsvc graph
# EX ./call.sh -c my-cluster -f ./call_conf.yaml my-jobstore my-bucket/hgsvc/call s3://my-bucket/hgsvc/HGSVC-chroms.xg HG00514  s3://my-bucket/hgsvc/HGSVC-chroms/map-HG00514/HG00514-ERR903030-map_chr


#!/bin/bash

BID=0.53
RESUME=0
REGION="us-west-2"
HEAD_NODE_OPTS=""
CONFIG_PATH=""
HEAD_NODE=""
RECALL=1
CHR_PREFIX="chr"
GENOTYPE_VCF=0
ALT_PATH_GAM=0
ID_RANGES_FILE=0 
SNARLS_FILE=0

usage() {
    # Print usage to stderr
    exec 1>&2
    printf "Usage: $0 [OPTIONS] <JOBSTORE-NAME> <OUTSTORE-NAME> <XG-INDEX> <SAMPLE> <GAM>\n"
	 printf "Arguments:\n"
	 printf "   JOBSTORE-NAME: Name of Toil S3 Jobstore (without any prefix). EX: my-job-store \n"
	 printf "   OUTSTORE-NAME: Name of output bucket (without prefix or trailing slash). EX my-bucket/hgsvc\n"
	 printf "   XG-INDEX:    Full path of xg index\n"
	 printf "   SAMPLE:      SAMPLE NAME\n"
	 printf "   GAM:         Path of GAM.  Or path of gam up to chrom number. Ex s3://bucket/hgsvc_chr.\n"
	 printf "Options:\n"
	 printf "   -b BID  Spot bid in dollars for r3.8xlarge nodes [${BID}]\n"
	 printf "   -r      Resume existing job\n"
	 printf "   -g      Aws region [${REGION}]\n"
	 printf "   -c      Toil Cluster Name (created with https://github.com/vgteam/toil-vg/blob/master/scripts/create-ec2-leader.sh).  Only use if not running from head node.\n"
	 printf "   -f      (local) Path of config file\n"
	 printf "   -a      Augment the graph (do not use --recall mode)\n"
	 printf "   -p      No chr prefix in chromosome names\n"
	 printf "   -v FILE Genotype given VCF file\n"
	 printf "   -i FILE Use given alt path gam index (required for -v)\n"
	 printf "   -d FILE id ranges file (to enable pack support)\n"
	 printf "   -l FILE snarls file\n"
    exit 1
}

while getopts "b:re:c:f:apv:i:d:l:" o; do
    case "${o}" in
        b)
            BID=${OPTARG}
            ;;
        r)
            RESUME=1
            ;;
		  e)
            REGION=${OPTARG}
            ;;
		  c)
				HEAD_NODE=${OPTARG}
				HEAD_NODE_OPTS="-l ${OPTARG}"
				;;
		  f)
				CONFIG_PATH=${OPTARG}
				;;
		  a)
				RECALL=0
				;;
		  p)
				CHR_PREFIX=""
				;;
		  v)
				GENOTYPE_VCF=${OPTARG}
				;;
		  i)
				ALT_PATH_GAM=${OPTARG}
				;;
		  d)
				ID_RANGES_FILE=${OPTARG}
				;;
		  l)
				SNARLS_FILE=${OPTARG}
				;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [[ "$#" -lt "5" ]]; then
    # Too few arguments
    usage
fi

# of the form aws:us-west:name
JOBSTORE_NAME="${1}"
shift
OUTSTORE_NAME="${1}"
shift
XG_INDEX="${1}"
shift
SAMPLE="${1}"
shift
GAM="${1}"
shift

# assume interleaved if READS2 not given
if [ -z ${READS2} ]
then
	 READS_OPTS="--fastq ${READS1} --interleaved"
else
	 READS_OPTS="--fastq ${READS1} ${READS2}"
fi

# pull in ec2-run from git if not found in current dir
wget -nc https://raw.githubusercontent.com/vgteam/toil-vg/master/scripts/ec2-run.sh
chmod 777 ec2-run.sh

# without -r we start from scratch!
RESTART_FLAG=""
if [ $RESUME == 0 ]
then
	 toil clean aws:${REGION}:${JOBSTORE_NAME}
else
	 RESTART_FLAG="--restart"
fi

if [ -z ${CONFIG_PATH} ]
then
	 CONFIG_OPTS="--whole_genome_config"
else
	 # pass a local config to our job by way of the S3 outstore
	 CONF_NAME=`basename $CONFIG_PATH`
	 aws s3 cp $CONFIG_PATH s3://${OUTSTORE_NAME}/${CONF_NAME}
	 toil ssh-cluster --insecure --logOff --zone=us-west-2a ${CLUSTER_NAME} ${HEAD_NODE} /venv/bin/aws s3 cp s3://${OUTSTORE_NAME}/${CONF_NAME} .
	 CONFIG_OPTS="--config $CONF_NAME"
fi

if [ "${GAM##*.}" = "gam" ]
then
	 GAM_OPTS="--gams ${GAM}"
else
	 GAM_OPTS="--gams $(for i in $(seq 22 -1 1; echo X; echo Y); do echo ${GAM}${i}.gam; done)"
fi

if [ $RECALL == 1 ]
then
	 RECALL_OPTS="--recall"
else
	 RECALL_OPTS=""
fi

GT_OPTS=""
if [ $GENOTYPE_VCF != 0 ]
then
	 GT_OPTS="--genotype_vcf ${GENOTYPE_VCF} ${GT_OPTS}"
fi
if [ $ALT_PATH_GAM != 0 ]
then
	 GT_OPTS="--alt_path_gam ${ALT_PATH_GAM} ${GT_OPTS}"
fi

PACK_OPTS=""
if [ $ID_RANGES_FILE != 0 ]
then
	 PACK_OPTS="--id_ranges ${ID_RANGES_FILE} --pack"
fi
if [ $SNARLS_FILE != 0 ]
then
	 PACK_OPTS="--snarls ${SNARLS_FILE} ${PACK_OPTS}"
fi

# run the job
./ec2-run.sh ${HEAD_NODE_OPTS} -m 1 -n r3.8xlarge:${BID},r3.8xlarge "call aws:${REGION}:${JOBSTORE_NAME} ${XG_INDEX} ${SAMPLE} aws:${REGION}:${OUTSTORE_NAME} ${CONFIG_OPTS} ${GAM_OPTS} --chroms  $(for i in $(seq 22 -1 1; echo X; echo Y); do echo ${CHR_PREFIX}${i}; done) ${RECALL_OPTS} --logFile call.hgsvc.$(basename ${OUTSTORE_NAME}).log ${RESTART_FLAG} ${GT_OPTS} ${PACK_OPTS}" | tee call.$(basename ${OUTSTORE_NAME}).stdout

TOIL_ERROR=!$

exit $TOIL_ERROR
