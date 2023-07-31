#!/bin/bash
/bin/mkdir -p /usr/lib/postgresql/13/lib
/bin/mkdir -p /usr/share/postgresql/13/extension
/usr/bin/install -c -m 755  hll.so /usr/lib/postgresql/13/lib/hll.so
/usr/bin/install -c -m 644 ./hll.control /usr/share/postgresql/13/extension/
/usr/bin/install -c -m 644  hll--2.13--2.14.sql hll--2.10--2.11.sql hll--2.12--2.13.sql hll--2.15--2.16.sql hll--2.16--2.17.sql hll--2.14--2.15.sql hll--2.11--2.12.sql hll--2.10.sql /usr/share/postgresql/13/extension/
/bin/mkdir -p /usr/lib/postgresql/13/lib/bitcode/hll
/bin/mkdir -p /usr/lib/postgresql/13/lib/bitcode/hll/src/
/usr/bin/install -c -m 644 src/hll.bc /usr/lib/postgresql/13/lib/bitcode/hll/src/
/usr/bin/install -c -m 644 src/MurmurHash3.bc /usr/lib/postgresql/13/lib/bitcode/hll/src/
# cd /usr/lib/postgresql/13/lib/bitcode && /usr/lib/llvm-9/bin/llvm-lto -thinlto -thinlto-action=thinlink -o hll.index.bc hll/src/hll.bc hll/src/MurmurHash3.bc
# cp hll.index.bc /usr/lib/postgresql/13/lib/bitcode
echo 'OK'
