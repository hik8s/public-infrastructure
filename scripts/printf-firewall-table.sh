#!/bin/bash
ROW_FORMAT='%-10s | %-8s | %-8s | %-14s | %-4s | %-7s\n'
printf "$ROW_FORMAT" 'Name' 'Version' 'Protocol' 'Source IP' '...' 'Action'
printf "$ROW_FORMAT" | tr ' ' '-'
printf "$ROW_FORMAT" 'Allow home' 'ipv4' '*' '$YOUR_HOME_IP' '...' 'accept'
printf "$ROW_FORMAT" 'Drop all' '*' '*' '0.0.0.0/32' '...' 'discard'
