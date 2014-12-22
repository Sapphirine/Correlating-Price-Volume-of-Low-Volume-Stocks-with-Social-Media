#Jeff Ho
#Mahout Naive Bayes Classification
#Require Hadoop & Mahout installation



if [ "$1" = "--help" ] || [ "$1" = "--?" ]; then
  echo "This script runs Bayes classifiers."
  exit
fi


SCRIPT_PATH=${0%/*}
if [ "$0" != "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "" ]; then
  cd $SCRIPT_PATH
fi
START_PATH=`pwd`


if [ "$HADOOP_HOME" != "" ] && [ "$MAHOUT_LOCAL" == "" ] ; then
  HADOOP="$HADOOP_HOME/bin/hadoop"
  if [ ! -e $HADOOP ]; then
    echo "Can't find hadoop in $HADOOP, exiting"
    exit 1
  fi
fi


WORK_DIR=tmp/ALSK

alg=naivebayes


#echo $START_PATH
cd $START_PATH
cd ../..


set -e


if [ "x$alg" == "xnaivebayes"  -o  "x$alg" == "xcnaivebayes" ]; then
  c=""

  if [ "x$alg" == "xcnaivebayes" ]; then
    c=" -c"
  fi

  set -x
  echo "Preparing ALSK data"
  rm -rf ${WORK_DIR}/ALSK-all
  mkdir ${WORK_DIR}/ALSK-all
  cp -R ${WORK_DIR}/ALSK-bydate/*/* ${WORK_DIR}/ALSK-all

  if [ "$HADOOP_HOME" != "" ] && [ "$MAHOUT_LOCAL" == "" ] ; then
    echo "Copying ALSK data to HDFS"
    set +e
    $HADOOP dfs -rmr ${WORK_DIR}/ALSK-all
    set -e
    $HADOOP dfs -put ${WORK_DIR}/ALSK-all ${WORK_DIR}/ALSK-all
  fi

  echo "Creating sequence files from ALSK data"
  ./bin/mahout seqdirectory \
    -i ${WORK_DIR}/ALSK-all \
    -o ${WORK_DIR}/ALSK-seq -ow

  echo "Converting sequence files to vectors"
  ./bin/mahout seq2sparse \
    -i ${WORK_DIR}/ALSK-seq \
    -o ${WORK_DIR}/ALSK-vectors  -lnorm -nv  -wt tfidf

  echo "Creating training and holdout set with a random 80-20 split of the generated vector dataset"
  ./bin/mahout split \
    -i ${WORK_DIR}/ALSK-vectors/tfidf-vectors \
    --trainingOutput ${WORK_DIR}/ALSK-train-vectors \
    --testOutput ${WORK_DIR}/ALSK-test-vectors  \
    --randomSelectionPct 20 --overwrite --sequenceFiles -xm sequential

  echo "Training Naive Bayes model"
  ./bin/mahout trainnb \
    -i ${WORK_DIR}/ALSK-train-vectors -el \
    -o ${WORK_DIR}/model \
    -li ${WORK_DIR}/labelindex \
    -ow $c

  echo "Self testing on training set"
  ./bin/mahout testnb \
    -i ${WORK_DIR}/ALSK-train-vectors\
    -m ${WORK_DIR}/model \
    -l ${WORK_DIR}/labelindex \
    -ow -o ${WORK_DIR}/ALSK-testing $c

  echo "Testing on holdout set"
  ./bin/mahout testnb \
    -i ${WORK_DIR}/ALSK-test-vectors\
    -m ${WORK_DIR}/model \
    -l ${WORK_DIR}/labelindex \
    -ow -o ${WORK_DIR}/ALSK-testing $c



elif [ "x$alg" == "xsgd" ]; then
  if [ ! -e "/tmp/news-group.model" ]; then
    echo "Training on ${WORK_DIR}/ALSK-bydate/ALSK-bydate-train/"
    ./bin/mahout org.apache.mahout.classifier.sgd.TrainNewsGroups ${WORK_DIR}/ALSK-bydate/ALSK-bydate-train/
  fi
  echo "Testing on ${WORK_DIR}/ALSK-bydate/ALSK-bydate-test/ with model: /tmp/news-group.model"
  ./bin/mahout org.apache.mahout.classifier.sgd.TestNewsGroups --input ${WORK_DIR}/ALSK-bydate/ALSK-bydate-test/ --model /tmp/news-group.model



elif [ "x$alg" == "xclean" ]; then
  rm -rf ${WORK_DIR}
  rm -rf /tmp/news-group.model
  fi
  


#END
