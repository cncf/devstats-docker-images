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
cd /root || exit 1
function finish {
  cd /root
  rm $db.*.tsv
}
trap finish EXIT
db.sh psql $db -tAc "\copy (select * from gha_events where id > 281474976710656) TO '/root/$db.events.tsv'" || exit 2
db.sh psql $db -tAc "\copy (select * from gha_payloads where event_id > 281474976710656) TO '/root/$db.payloads.tsv'" || exit 3
db.sh psql $db -tAc "\copy (select * from gha_issues where event_id > 281474976710656) TO '/root/$db.issues.tsv'" || exit 4
db.sh psql $db -tAc "\copy (select * from gha_pull_requests where event_id > 281474976710656) TO '/root/$db.prs.tsv'" || exit 5
db.sh psql $db -tAc "\copy (select * from gha_milestones where event_id > 281474976710656) TO '/root/$db.milestones.tsv'" || exit 6
db.sh psql $db -tAc "\copy (select * from gha_issues_labels where event_id > 281474976710656) TO '/root/$db.labels.tsv'" || exit 7
db.sh psql $db -tAc "\copy (select * from gha_issues_assignees where event_id > 281474976710656) TO '/root/$db.issue_assignees.tsv'" || exit 8
db.sh psql $db -tAc "\copy (select * from gha_pull_requests_assignees where event_id > 281474976710656) TO '/root/$db.pr_assignees.tsv'" || exit 9
db.sh psql $db -tAc "\copy (select * from gha_pull_requests_requested_reviewers where event_id > 281474976710656) TO '/root/$db.pr_reviewers.tsv'" || exit 10
db.sh psql $db -tAc "\copy (select * from gha_issues_events_labels where event_id > 281474976710656) TO '/root/$db.issues_events_labels.tsv'" || exit 11
db.sh psql $db -tAc "\copy (select * from gha_texts where event_id > 281474976710656) TO '/root/$db.texts.tsv'" || exit 12
rm -f $db.tar* || exit 13
tar cf $db.tar $db.*.tsv || exit 14
if [ -z "${FASTXZ}" ]
then
  xz $db.tar || exit 15
else
  xz -1 $db.tar || exit 16
fi
