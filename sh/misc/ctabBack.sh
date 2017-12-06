#!/bin/bash

DT=`date -u -d '9 hours' '+%Y%m%d_%H%M%S'`
BKFILE="ctab"

crontab -l > "${BKFILE}_${DT}.txt"


