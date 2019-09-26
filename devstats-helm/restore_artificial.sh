#!/bin/bash
if [ ! -z "${NOBACKUP}" ]
then
  exit 0
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide database name as an argument"
  exit 1
fi
db=$1
if [ "$db" = "devstats" ]
then
  exit 0
fi
cd /root || exit 2
function finish {
  cd /root
  rm $db.*.tsv
}
trap finish EXIT
if [ ! -z "$RESTORE_FROM" ]
then
  wget "${RESTORE_FROM}/backups/${db}.tar.xz" || exit 3
fi
xz -k -d $db.tar.xz || exit 4
tar xf $db.tar || exit 5
rm $db.tar || exit 6
db.sh psql $db -tAc "\copy gha_events from '/root/$db.events.tsv'" || exit 7
db.sh psql $db -tAc "\copy gha_payloads from '/root/$db.payloads.tsv'" || exit 8
db.sh psql $db -tAc "\copy gha_issues from '/root/$db.issues.tsv'" || exit 9
db.sh psql $db -tAc "\copy gha_pull_requests from '/root/$db.prs.tsv'" || exit 10
db.sh psql $db -tAc "\copy gha_milestones from '/root/$db.milestones.tsv'" || exit 11
db.sh psql $db -tAc "\copy gha_issues_labels from '/root/$db.labels.tsv'" || exit 12
db.sh psql $db -tAc "\copy gha_issues_assignees from '/root/$db.issue_assignees.tsv'" || exit 13
db.sh psql $db -tAc "\copy gha_pull_requests_assignees from '/root/$db.pr_assignees.tsv'" || exit 14
db.sh psql $db -tAc "\copy gha_pull_requests_requested_reviewers from '/root/$db.pr_reviewers.tsv'" || exit 15
db.sh psql $db -tAc "\copy gha_issues_events_labels from '/root/$db.issues_events_labels.tsv'" || exit 16
db.sh psql $db -tAc "\copy gha_texts from '/root/$db.texts.tsv'" || exit 17
