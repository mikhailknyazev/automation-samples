#!/bin/bash
for i in {1..50}
do
   curl -s http://node3 | grep -A1 -E 'node1|node2'
   echo
   sleep 5
done
