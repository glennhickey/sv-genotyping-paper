# SVPOP

```
# Construct the graph and index for svpop (15 sv samples) including inversions
./construct.sh -p -i -c ${CLUSTER}1 ${JOBSTORE}1 ${OUTSTORE}

# Mapping, Calling, Evaluation

./mce.sh -c ${CLUSTER}1 -C "-v s3://${OUTSTORE}/sv-pop.vcf.gz -i s3://${OUTSTORE}/SVPOP_alts.gam" ${JOBSTORE}1 ${OUTSTORE} s3://${OUTSTORE}/SVPOP HG00514 HG00514 s3://${OUTSTORE}/sv-pop-explicit.vcf.gz ${COMPARE_REGIONS_BED} ${FQBASE}/HG00514/ERR903030_1.fastq.gz ${FQBASE}/HG00514/ERR903030_2.fastq.gz

./mce.sh -c ${CLUSTER}2 -C "-v s3://${OUTSTORE}/sv-pop.vcf.gz -i s3://${OUTSTORE}/SVPOP_alts.gam" ${JOBSTORE}2 ${OUTSTORE} s3://${OUTSTORE}/SVPOP HG00733 HG00733 s3://${OUTSTORE}/sv-pop-explicit.vcf.gz ${COMPARE_REGIONS_BED} ${FQBASE}/HG00733/ERR895347_1.fastq.gz ${FQBASE}/HG00733/ERR895347_2.fastq.gz 

./mce.sh -c ${CLUSTER}3 -C "-v s3://${OUTSTORE}/sv-pop.vcf.gz -i s3://${OUTSTORE}/SVPOP_alts.gam" ${JOBSTORE}3 ${OUTSTORE} s3://${OUTSTORE}/SVPOP NA19240 NA19240 s3://${OUTSTORE}/sv-pop-explicit.vcf.gz ${COMPARE_REGIONS_BED} ${FQBASE}/NA19240/ERR894724_1.fastq.gz ${FQBASE}/NA19240/ERR894724_2.fastq.gz

# Download

rm -rf ./SVPOP-jan10-eval-HG00514 ; aws s3 sync s3://${OUTSTORE}/eval-HG00514 ./SVPOP-jan10-eval-HG00514
rm -rf ./SVPOP-jan10-eval-HG00733 ; aws s3 sync s3://${OUTSTORE}/eval-HG00733 ./SVPOP-jan10-eval-HG00733
rm -rf ./SVPOP-jan10-eval-NA19240 ; aws s3 sync s3://${OUTSTORE}/eval-NA19240 ./SVPOP-jan10-eval-NA19240

#### SMRTSV

# Smrtsv2 was run on courtyard, then made explicity using the same process as the original svpop graph (see construg.sh)
# (all three samples are in one VCF: svpop-smrtsv-explicit.vcf.gz)

./eval.sh -c ${CLUSTER}1 ${JOBSTORE}1 ${OUTSTORE}/eval-HG00514-smrtsv s3://${OUTSTORE}/sv-pop-explicit.vcf.gz  s3://glennhickey/outstore/SVPOP-jan10/call-all-smrtsv/svpop-smrtsv-explicit.vcf.gz ${COMPARE_REGIONS_BED} HG00514

./eval.sh -c ${CLUSTER}1 ${JOBSTORE}1 ${OUTSTORE}/eval-HG00733-smrtsv s3://${OUTSTORE}/sv-pop-explicit.vcf.gz  s3://glennhickey/outstore/SVPOP-jan10/call-all-smrtsv/svpop-smrtsv-explicit.vcf.gz ${COMPARE_REGIONS_BED} HG00733

./eval.sh -c ${CLUSTER}1 ${JOBSTORE}1 ${OUTSTORE}/eval-NA19240-smrtsv s3://${OUTSTORE}/sv-pop-explicit.vcf.gz  s3://glennhickey/outstore/SVPOP-jan10/call-all-smrtsv/svpop-smrtsv-explicit.vcf.gz ${COMPARE_REGIONS_BED} NA19240

rm -rf ./SVPOP-jan10-eval-HG00514-smrtsv ; aws s3 sync s3://${OUTSTORE}/eval-HG00514-smrtsv ./SVPOP-jan10-eval-HG00514-smrtsv
rm -rf ./SVPOP-jan10-eval-HG00733-smrtsv ; aws s3 sync s3://${OUTSTORE}/eval-HG00733-smrtsv ./SVPOP-jan10-eval-HG00733-smrtsv
rm -rf ./SVPOP-jan10-eval-NA19240-smrtsv ; aws s3 sync s3://${OUTSTORE}/eval-NA19240-smrtsv ./SVPOP-jan10-eval-NA19240-smrtsv
