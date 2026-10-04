![alt tag](https://raw.githubusercontent.com/lateralblast/sargo/master/sargo.jpg)

> Diplodus sargus, called White seabream and Sargo, is a species of seabream
> native to the eastern Atlantic and western Indian Oceans.

SARGO
======

Sar to Google Charts (and CSV)

Informtaion
------------

Script to process sar data and output CSV or web page and javascript for google
charts.

Version
-------

Current version: 0.1.7

See CHANGELOG.md for the release history.

License
-------

This software is licensed as CC BY-NC-SA 4.0 (Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International)

https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode

See the LICENSE file for the full text.

Usage
-----

```
$ sargo.pl [OPTION] -i [INPUT] -o [OUTPUT] -s [START] -d [DELTA]

-h: Help
-D: Do disk stats (takes some time thus not done by default)
-i: Input file
-o: Output file
-g: Output Google Graphs Javascript
-s: Start Date (used for data from mpstat etc)
-d: Delta in secs (user for data from mpstat etc)
-S: Process directly from sar and output to directory $tmp_dir
-w: Set work directory (overrides default)
```

This script has support to process multiple days of sar output
An example of a command to capture all the sar output to a single file:

```
$ cd /var/adm/sa ; for i in `ls sa[0-9]*` ; do sar -A -f $i >> /tmp/`hostname`.sarout ; done
```

The -s switch will do this for you if you want.

This output file then can be input into this script using a command like:

```
$ sargo.pl -i /tmp/sarout -o /tmp/sarcvs
```

This will generate a number of files /tmp/sarcvs_METRIC.csv
METRIC is the the name of the first column pulled from the sar data
For example /tmp/sarcvs_runq-sz
An output file will be generated for each disk device.

This script can also produce a web page with javascript to use google charts.

Examples
--------

Process raw sar output from a file:

```
$ sargo.pl -i RAW_SAR_INPUT -o CSV_OUTPUT
```

Process sar directly:

```
$ sargo.pl -S
```

Help Support Development
------------------------

If you find this software useful and would like to support its development, please consider buying me a coffee:

https://ko-fi.com/richardatlateralblast
