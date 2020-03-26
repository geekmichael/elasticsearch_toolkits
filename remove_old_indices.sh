#!/bin/bash
#
# A script to delete elasticsearch indices created 7-day ago
#
searchIndex=network
elastic_url=localhost
elastic_port=9200
elastic_log=/var/log/elasticsearch/
age=7

date2stamp () {
    date --utc --date "$1" +%s
}

dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}

for index in $(curl -s "${elastic_url}:${elastic_port}/_cat/indices?v" | grep -E " ${searchIndex}-20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]" | awk '{     print $3 }'); do
  date=$(echo ${index: -10} | sed 's/\./-/g')
  cond=$(date +%Y-%m-%d)
  diff=$(dateDiff -d $date $cond)
  echo -n "${index} (${diff})"
  if [ $diff -gt $age ]; then
    echo "${date} / DELETE"
    curl -XDELETE "${elastic_url}:${elastic_port}/${index}?pretty"
    # Delete all related logs
    rm -f "${elastic_log}/elasticsearch-${date}*.gz" 
  else
    echo ""
  fi
done
