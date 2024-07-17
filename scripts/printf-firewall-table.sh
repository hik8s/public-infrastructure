#!/bin/bash
ROW_FORMAT='%-28s | %-8s | %-8s | %-18s | %-4s | %-16s | %-8s\n'
printf "$ROW_FORMAT" 'Name' 'Version' 'Protocol' 'Source IP' '...' 'Destination port' 'Action'
printf "$ROW_FORMAT" | tr ' ' '-'
printf "$ROW_FORMAT" 'Allow home' 'ipv4' '*' "$YOUR_HOME_IP/32" '...' '' 'accept'
printf "$ROW_FORMAT" 'Drop kube-apiserver + talos' '*' '*' ''  '...' '6443,50000-50001' 'discard'
printf "$ROW_FORMAT" 'Allow all' '*' '*' '' '...' '' 'accept'
