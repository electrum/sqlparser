#!/bin/bash

test -f Test.class || exit 100

dotest()
{
   CLASSPATH=$CLASSPATH:antlr:. java Test
   if [ $? -eq 0 ] ; then echo "passed"; else echo "failed"; fi
}

echo "*** testing ddl ***"
cat ~/tpch/dss.ddl | dotest

for n in {1..22}
do
   test $n -eq 15 && continue

   echo "*** testing query $n ***"
   < ~/tpch/queries/$n.sql tr -d '\r' | \
   sed 's/^:[xo]$//' | \
   perl -pe 's/^:n -?[0-9]+//' | \
   perl -pe "s/([^']):([0-9]+)/\\1\\2/g" | \
   dotest
done
