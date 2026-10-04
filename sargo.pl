#!/usr/bin/perl

# Name:         sargo (Sar to Google Charts)
# Version:      0.1.7
# Release:      1
# License:      CC BY-NC-SA 4.0 (see LICENSE)
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Solaris
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Sar graphing tool

use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);

my $date        = "";
my $time        = "";
my $elapsed     = 0;
my $mins        = "00";
my $hours       = "00";
my %option      = ();
my $out_fh;
my $script_name = $0;
my $tmp_dir;
my $tmp_file;

# Assumed page size in KB used to convert freemem (pages) to GB
my $page_kb     = 8;

# Chart titles keyed on the output file name, the last match wins

my @chart_titles = (
  [ qr/atchs/,   "Paging Information" ],
  [ qr/breads/,  "Buffer Information" ],
  [ qr/igets/,   "Directory cache information" ],
  [ qr/msgs/,    "Message and Semaphore Information" ],
  [ qr/pgouts/,  "Page In and Out Information" ],
  [ qr/proc-sz/, "Process Table Information" ],
  [ qr/rawchs/,  "Character Buffer Information" ],
  [ qr/runq-sz/, "Run Queue Information" ],
  [ qr/scalls/,  "System Call Information" ],
  [ qr/sml/,     "Memory Allocation Information" ],
  [ qr/swpins/,  "Swap Information" ],
  [ qr/usr/,     "CPU Information" ],
);

$script_name =~ s{.*/}{};

getopts("i:o:s:d:w:DhSg",\%option);

$tmp_dir  = $option{'w'} ? $option{'w'} : "/tmp/$script_name";
$tmp_file = "$tmp_dir/rawdata";

if ($option{'h'}) {
  usage();
  exit;
}

if ($option{'s'}) {
  $date = $option{'s'};
}

# Some help on using the script

sub usage {

  print <<"EOT";

Usage:

$script_name [OPTION] -i [INPUT] -o [OUTPUT] -s [START] -d [DELTA]

-h: Help
-D: Do disk stats (takes some time thus not done by default)
-i: Input file
-o: Output file
-g: Output Google Graphs Javascript
-s: Start Date (used for data from mpstat etc)
-d: Delta in secs (used for data from mpstat etc)
-S: Process directly from sar and output to directory $tmp_dir
-w: Set work directory (overrides $tmp_dir)

Example: Process raw sar output from a file

$script_name -i RAW_SAR_INPUT -o CSV_OUTPUT

Example: Process sar directly

$script_name -S

Example: Process mpstat output

$script_name -i RAW_INPUT -o CSV_OUTPUT -s START -d DELTA

EOT
  return;
}

# Ordered rewrites of the terse sar column names into readable labels
# Order matters as the shorter patterns, eg pgin, overlap the longer ones, eg ppgin

my @device_labels = (
  [ qr/device\,/,     "" ],
  [ qr/00\:00\:01\,/, "" ],
  [ qr/busy/,         " Busy" ],
  [ qr/avqueue/,      "Average queue" ],
  [ qr/,r+w/,         ",Reads and writes" ],
  [ qr/,blks/,        ",Blocks" ],
  [ qr/,avwait/,      ",Average wait time in ms" ],
  [ qr/,avserv/,      ",Average service time in ms" ],
);

my @header_labels = (
  [ qr/,atch/,                ",Page faults" ],
  [ qr/,write/,               ",Writes" ],
  [ qr/,bread/,               ",Buffer reads" ],
  [ qr/,bwrit/,               ",Buffer writes" ],
  [ qr/,lread/,               ",System buffer reads" ],
  [ qr/,lwrit/,               ",System buffer writes" ],
  [ qr/rcache/,               " Read cache hit ratio" ],
  [ qr/wcache/,               " Write cache hit ratio" ],
  [ qr/,pread/,               ",Physical reads" ],
  [ qr/,pwrit/,               ",Physical writes" ],
  [ qr/,scall/,               ",System calls" ],
  [ qr/,sread/,               ",System reads" ],
  [ qr/,swrit/,               ",System writes" ],
  [ qr/,fork/,                ",Process forks" ],
  [ qr/,exec/,                ",Process execs" ],
  [ qr/,rchar/,               ",System read character transfers" ],
  [ qr/,wchar/,               ",System write character transfers" ],
  [ qr/busy/,                 " Busy" ],
  [ qr/,avque/,               ",Average queue" ],
  [ qr/,blks/,                ",Blocks" ],
  [ qr/,reads/,               ",Reads" ],
  [ qr/,ppgout/,              ",Pages paged out" ],
  [ qr/,pgout/,               ",Page out requests" ],
  [ qr/,pgfree/,              ",Pages freed" ],
  [ qr/,pgscan/,              ",Pages scanned" ],
  [ qr/ufs\_ipf/,             " UFS inodes taken off free list" ],
  [ qr/,sml\_mem,alloc,fail/, ",Small memory pool in bytes,Small memory pool allocated,Small memory allocation fails" ],
  [ qr/,lg\_mem,alloc,fail/,  ",Large memory pool in bytes,Large memory pool allocated,Large memory allocation fails" ],
  [ qr/,ovsz\_alloc,fail/,    ",Oversize memory allocation in bytes,Oversize memory allocation fails" ],
  [ qr/,ppgin/,               ",Pages paged in" ],
  [ qr/,pgin/,                ",Page in requests" ],
  [ qr/,pflt/,                ",Page faults" ],
  [ qr/,vflt/,                ",Page address translation faults" ],
  [ qr/,slock/,               ",Software lock requests requiring IO" ],
  [ qr/,runq-sz/,             ",Run queue size" ],
  [ qr/,swpq-sz/,             ",Swap queue size" ],
  [ qr/runocc/,               " Run queue occupied" ],
  [ qr/swpocc/,               " Swap queue occupied" ],
  [ qr/usr/,                  " CPU used in user mode" ],
  [ qr/sys/,                  " CPU used in system mode" ],
  [ qr/wio/,                  " CPU used waiting on IO" ],
  [ qr/,iget/,                ",inodes not in DNLC" ],
  [ qr/,dirblk/,              ",Directory block reads" ],
  [ qr/,namei/,               ",Filesystem path searches" ],
  [ qr/,msg/,                 ",Messages" ],
  [ qr/,sema/,                ",Semaphores" ],
  [ qr/idle/,                 " CPU idle" ],
  [ qr/,swpin/,               ",Swap ins" ],
  [ qr/,swpot/,               ",Swap outs" ],
  [ qr/,bswin/,               ",512 byte swap ins" ],
  [ qr/,bswot/,               ",512 byte swap outs" ],
  [ qr/,pswch/,               ",Process switches" ],
  [ qr/,proc-sz/,             ",Process table size" ],
  [ qr/,inod-sz/,             ",inode table size" ],
  [ qr/,file-sz/,             ",File table size" ],
  [ qr/,lock-sz/,             ",Lock table size" ],
);

my @memory_labels = (
  [ qr/,freemem/,  ",Pages available to user processes" ],
  [ qr/,freeswap/, ",Disk blocks available for page swapping" ],
);

# Apply a list of [ pattern, replacement ] rewrites to a string in order

sub apply_labels {

  my ($record,@labels) = @_;
  my $label;

  foreach $label (@labels) {
    $record =~ s/$label->[0]/$label->[1]/g;
  }
  return($record);
}

# Process the disk header

sub process_device_header {

  my $record        = $_[0];
  my $device_header = "";

  if ($record =~ /device/) {
    $device_header = $record;
    $device_header =~ s/device,//g;
    $device_header =~ s/00:00:01,//g;
  }
  return(apply_labels($device_header,@device_labels));
}

sub process_header {

  my $record = apply_labels($_[0],@header_labels);

  # The google charts code displays memory in GB

  my $unit = $option{'g'} ? " [GB]" : "";

  return(apply_labels($record,map { [ $_->[0],"$_->[1]$unit" ] } @memory_labels));
}

sub create_html_header {

  my $out_file = $_[0];

  open_output($out_file);
  print $out_fh <<'EOT';
<html>
  <head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
EOT
  return;
}

sub process_sar {

  my $output = "";
  my $record;
  my $counter;
  my @lines;
  my $device_header = "";
  my $data_name;
  my $out_file;
  my @values;
  my @output_files;
  my %seen_file;
  my $free_gb;

  # Open file and put data into array and process

  if ($option{'S'}) {
    if (! -d $tmp_dir) {
      mkdir($tmp_dir) or die "Cannot create $tmp_dir: $!\n";
    }
    unlink($tmp_file);
    system("cd /var/adm/sa && for i in `ls sa[0-9]*` ; do sar -A -f \$i >> '$tmp_file' ; done");
    $option{'i'} = $tmp_file;
  }
  open(my $input,"<",$option{'i'}) or die "Cannot open $option{'i'}: $!\n";
  @lines = <$input>;
  close($input);

  for ($counter = 0; $counter < @lines; $counter++) {
    $record = $lines[$counter];
    chomp($record);
    $record =~ s/,//g;

    # When reading from the sar file the system information is given
    # This will appear at the start of each days sar output
    # Use it to grab the date for charting multiple days
    # Eg processing:
    # SunOS hostname 5.10 Generic_144488-XX sun4u    07/15/2012
    # Gives us:
    # 07/15/2012
    # If an output file hasn't been specified use hostname from header
    # If sar is process raw with -S insert hostname in output file name

    if ($record =~ /SunOS/) {
      @values = split(/\s+/,$record);
      $date   = $values[5];
      if (!$option{'o'}) {
        if ($option{'S'}) {
          $option{'o'} = "$tmp_dir/$values[1]";
        }
        else {
          $option{'o'} = $values[1];
        }
      }
    }
    else {

      # This section processes any line with [a-z]
      # This allows us to handle headers and create output files
      # It also allows us to process disk stats
      # Non disk stats are handled in the else loop
      # Ignore Average line

      if (($record =~ /[a-z]/)&&($record !~ /Average/)) {

        if ((!defined($option{'o'}))||($option{'o'} !~ /[A-Za-z0-9]/)) {
          $option{'o'} = "sargo_out";
        }
        # Convert white space to comma

        $record =~ s/\s+/,/g;

        # Close any open files

        close_output();

        # Extract data type/name from line
        # Eg processing:
        # 00:00:01    %usr    %sys    %wio   %idle
        # Gives us a data type/name usr
        # A more informative data type could be derived

        @values    = split(/,/,$record);
        $data_name = $values[1];
        $data_name =~ s/%//g;
        $data_name =~ s{/}{}g;
        if ($option{'g'}) {
          $out_file = "$option{'o'}_$data_name.html";
        }
        else {
          $out_file = "$option{'o'}_$data_name.csv";
        }
        if (!$seen_file{$out_file}) {
          $seen_file{$out_file} = 1;
          push(@output_files,$out_file);
        }

        # On startup cleanup old files

        if ($counter < 5) {
          if (-e $out_file) {
            print "Removing any previous output\n";
            remove_previous_output($option{'o'});
          }
        }

        # If data file has not been created create it with a header
        # Eg: Date Time,runq-sz,%runocc,swpq-sz,%swpocc
        # Convert to lay mans terms (Requested by AT)
        # Eg: Date Time,Run Queue Size,...
        # This will allow us to easily import into Excel
        # The first column becomes the X axis
        # The other columns are plotted on the Y axis
        # This code is only run the first time the file is created
        # Create a generic device header for all the disk output

        if ($option{'D'}) {
          $device_header = process_device_header($record);
        }
        else {
          if (($record =~ /[a-z]/)&&($record !~ /[a-z][0-9]/)&&(!$option{'d'})&&($record !~ /device/)&&($record !~ /^CPU/)) {
            $record = process_header($record);
          }
        }
        if ($record =~ /^CPU/) {
          if ($option{'d'}) {
            $elapsed = $elapsed+$option{'d'};
            $hours   = sprintf("%02d",($elapsed/(60*60))%24);
            $mins    = sprintf("%02d",($elapsed/60)%60);
          }
          else {
            $time = "";
          }
        }
        if ((! -e $out_file)&&($out_file !~ /device/)) {
          if ($option{'g'}) {
            if (($device_header =~ /[a-z]/)&&($option{'D'})) {
              create_html_header($out_file);
            }
            else {
              if ((!$option{'D'})&&($out_file !~ /md[0-9]|sd[0-9]|nfs[0-9]/)) {
                create_html_header($out_file);
              }
            }
          }
          $record =~ s/00:00:01,//g;
          if ($record =~ /[a-z][0-9]/) {
            if ($option{'D'}) {
              $device_header =~ s/[0-9][0-9]:[0-9][0-9]:[0-9][0-9],//g;
              if ($option{'g'}) {
                $device_header =~ s/,/', '/g;
                $device_header = "$device_header'";
                $output = "'Date Time','$device_header";
              }
              else {
                $output = "Date Time,$device_header";
              }
              if ($option{'g'}) {
                $output = "          [$output],";
              }
              open_output($out_file);
              print $out_fh "$output\n";
            }
          }
          else {
            $record =~ s/[0-9][0-9]:[0-9][0-9]:[0-9][0-9],//g;
            if ($option{'g'}) {
              $record =~ s/,/', '/g;
              $record = "$record'";
              $output = "'Date Time','$record";
            }
            else {
              $output = "Date Time,$record";
            }
            if (!$option{'g'}) {
              if ($out_file =~ /freemem/) {
                $output = "$output,Free Memory (GB)";
              }
            }
            if ($option{'g'}) {
              $output = "          [$output],";
            }
            open_output($out_file);
            print $out_fh "$output\n";
          }
          close_output();
        }

        # Open file for writing

        if ($out_file !~ /device/) {
          if ($record =~ /[a-z][0-9]/) {
            if ($option{'D'}) {
              open_output($out_file);
            }
          }
          else {
            open_output($out_file);
          }
        }

        # Handle disk stats
        # Create a separate file for each disk
        # This could be handled better

        if (($record =~ /[a-z][0-9]/)&&($record !~ /device/)) {
          if ($option{'D'}) {
            $record =~ s/\Q$data_name\E//g;
            if ($record =~ /^[0-9]/) {
              @values = split(/,/,$record);
              $time   = $values[0];
            }
            if ($record !~ /^[0-9]/) {
              if ($option{'g'}) {
                $output = "'$date $time', $record";
              }
              else {
                $output = "$date $time,$record";
              }
            }
            else {
              if ($option{'g'}) {
                $record =~ s/,/', '/g;
                $output = "'$date, $record";
              }
              else {
                $output = "$date $record";
              }
            }
            $output =~ s/,,/,/g;
            $output =~ s/,,/,/g;
            if ($option{'g'}) {
              $output = "          [$output],\n";
            }
            print $out_fh "$output\n" if (defined($out_fh));
          }
        }
      }
      else {

        # Process anything that isn't a disk status or header info

        if (($record =~ /[0-9]/)&&($record !~ /Average/)&&($record !~ /device/)) {
          $record =~ s/\s+/,/g;
          $record =~ s/^,/CPU /g;
          if (($record !~ /^[0-9]/)&&($record !~ /^CPU/)) {
            if ($option{'g'}) {
              $output = "'$date $time',$record";
              $output =~ s/' / /;
              $output =~ s/,/',/;
            }
            else {
              $output = "$date $time,$record";
            }
          }
          else {
            if ($record =~ /^CPU/) {

              # Handle mpstat
              # If no date is specified use todays date
              # Increment time by delta

              if (!$option{'s'}) {
                $option{'s'} = strftime("%m/%d/%Y",localtime());
                $date = $option{'s'};
              }
              if ($option{'g'}) {
                $output = "'$date $hours:$mins:00' $record";
                $output =~ s/' / /;
                $output =~ s/,/',/;
              }
              else {
                $output = "$date $hours:$mins:00 $record";
              }
            }
            else {
              if ($option{'g'}) {
                $output = "'$date' $record";
                $output =~  s/' / /;
                $output =~  s/,/',/;
              }
              else {
                $output = "$date $record";
              }
              # If we are processing freemem, convert pages to MB
              if (!$option{'g'}) {
                if ($out_file =~ /freemem/) {
                  @values  = split(",",$output);
                  $free_gb = ($values[1]*$page_kb)/(1024*1024);
                  $free_gb = sprintf("%.2f",$free_gb);
                  $output  = "$output,$free_gb";
                }
              }
              else {
                if ($out_file =~ /freemem/) {
                  @values    = split(",",$output);
                  # freemem is in pages, freeswap is in 512 byte blocks
                  $values[1] = sprintf("%.2f",($values[1]*$page_kb)/(1024*1024));
                  $values[2] = sprintf("%.2f",($values[2]*512)/(1024*1024*1024));
                  $output    = "$values[0],$values[1],$values[2]";
                }
              }
            }
          }
          $output =~ s/,,/,/g;
          $output =~ s/,,/,/g;
          if ($option{'g'}) {
            $output = "          [$output],";
          }
          print $out_fh "$output\n" if (defined($out_fh));
        }
      }
    }
  }
  if ($option{'g'}) {
    foreach $out_file (@output_files) {
      if ((-e $out_file)&&($out_file !~ /device/)) {
        if (($device_header =~ /[a-z]/)&&($option{'D'})) {
          create_html_footer($out_file);
        }
        else {
          if ((!$option{'D'})&&($out_file !~ /md[0-9]|nfs[0-9]|sd[0-9]/)) {
            create_html_footer($out_file);
          }
        }
      }
    }
  }
}

# Open an output file for appending, closing any previously opened one

sub open_output {

  my $out_file = $_[0];

  close_output();
  open($out_fh,">>",$out_file) or die "Cannot open $out_file: $!\n";
  return;
}

# Close the current output file, if any

sub close_output {

  if (defined($out_fh)) {
    close($out_fh);
    undef($out_fh);
  }
  return;
}

# Remove output files from a previous run, ie files named PREFIX_*

sub remove_previous_output {

  my $prefix = $_[0];
  my $dir    = ".";
  my $base   = $prefix;
  my $file;
  my @files;

  if ($prefix =~ m{^(.*)/([^/]*)$}) {
    $dir  = ($1 eq "") ? "/" : $1;
    $base = $2;
  }
  if (opendir(my $dh,$dir)) {
    @files = readdir($dh);
    closedir($dh);
    foreach $file (@files) {
      if ((index($file,"$base\_") == 0)&&(-f "$dir/$file")) {
        unlink("$dir/$file");
      }
    }
  }
  return;
}

sub create_html_footer {

  my $out_file = $_[0];
  my $chart_title = $out_file;
  my $axis_option = "";
  my $entry;

  # Default to the output file name, minus any directory and extension

  $chart_title =~ s{.*/}{};
  $chart_title =~ s/\.html$//;

  # The last matching title wins

  foreach $entry (@chart_titles) {
    if ($out_file =~ $entry->[0]) {
      $chart_title = $entry->[1];
    }
  }
  $chart_title =~ s/'/\\'/g;

  # Use a log scale for free memory so that machines with large amounts of swap
  # don't dwarf the system memory output

  if ($out_file =~ /freemem/) {
    $axis_option = ",\n          vAxis: {logScale: 'True'}";
  }

  open_output($out_file);
  print $out_fh <<"EOT";
        ]);

        var options = {
          title: 'Sar Graph: $chart_title'$axis_option
        };

        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
    </script>
  </head>
  <body>
    <div id="chart_div" style="width: 900px; height: 500px;"></div>
  </body>
</html>
EOT
  close_output();
  return;
}

# If the sar data exists start processing

sub main {

  if ($option{'S'}||(defined($option{'i'})&&(-e $option{'i'}))) {
    process_sar();
  }
  elsif (defined($option{'i'})) {
    # If the input file doesn't exist exit
    print "File $option{'i'} does not exist.\n";
    exit 1;
  }
  else {
    print "No input file specified, use -i or -S.\n";
    usage();
    exit 1;
  }
  return;
}

main();
exit 0;
