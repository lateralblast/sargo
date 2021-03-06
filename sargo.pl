#!/usr/bin/perl


# Name:         sargo (Sar to Google Charts)
# Version:      0.0.2
# Release:      1
# License:      Open Source
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Solaris
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Sar graphing tool

use strict;
use Getopt::Std;

my $sar_file;
my $date;
my $time;
my $mins;
my $hours;
my %option      = ();
my $script_name = $0;
my $tmp_dir     = "/tmp/$script_name";
my $tmp_file    = "$tmp_dir/rawdata";

getopts("i:o:t:s:d:w:DhSg",\%option);

if ($option{'h'}) {
  usage();
  exit;
}

if ($option{'s'}) {
  $date = $option{'s'};
}

if ($option{'w'}) {
  $tmp_dir = $option{'w'};
}

# Some help on using the script

sub usage {
  print "\n";
  print "Usage:\n";
  print "\n";
  print "$script_name [OPTION] -i [INPUT] -o [OUTPUT] -s [START] -d [DELTA]\n";
  print "\n";
  print "-h: Help\n";
  print "-D: Do disk stats (takes some time thus not done by default)\n";
  print "-i: Input file\n";
  print "-o: Output file\n";
  print "-g: Output Google Graphs Javascript\n";
  print "-s: Start Date (used for data from mpstat etc)\n";
  print "-d: Delta in secs (user for data from mpstat etc)\n";
  print "-S: Process directly from sar and output to directory $tmp_dir\n";
  print "-w: Set work directory (overrides $tmp_dir)\n";
  print "\n";
  print "Example: Process raw sar output from a file\n";
  print "\n";
  print "sar2cvs -i RAW_SAR_INPUT -o CVS_OUTPUT\n";
  print "\n";
  print "Example: Process sar directly\n";
  print "\n";
  print "sar2cvs -S\n";
  print "\n";
  print "Example: Process mpstat output\n";
  print "\n";
  print "sar2cvs -i RAW_INPUT -o CVS_OUTPUT -s START -d DELTA\n";
  print "\n";
  return;
}

# If the sar data exists start processing

if ((-e "$option{'i'}")||($option{'S'})) {
  process_sar();
}
else {
  # If the input file doesn't exist exit
  print "File $option{'i'} does not exist.\n";
}

# Process the disk header

sub process_device_header {

  my $record = $_[0];
  my $device_header;

  if ($record =~ /device/) {
  $device_header = $record;
  $device_header =~ s/device\,//g;
  $device_header =~ s/00\:00\:01\,//g;
  }
  $device_header =~ s/busy/ Busy/g;
  $device_header =~ s/avqueue/Average queue/g;
  $device_header =~ s/,r+w/,Reads and writes/g;
  $device_header =~ s/,blks/,Blocks/g;
  $device_header =~ s/,avwait/,Average wait time in ms/g;
  $device_header =~ s/,avserv/,Average service time in ms/g;
  return($device_header);
}

sub process_header {

  my $record = $_[0];

  $record =~ s/,atch/,Page faults/g;
  $record =~ s/,write/,Writes/g;
  $record =~ s/,bread/,Buffer reads/g;
  $record =~ s/,bwrit/,Buffer writes/g;
  $record =~ s/,lread/,System buffer reads/g;
  $record =~ s/,lwrit/,System buffer writes/g;
  $record =~ s/rcache/ Read cache hit ratio/g;
  $record =~ s/wcache/ Write cache hit ratio/g;
  $record =~ s/,pread/,Physical reads/g;
  $record =~ s/,pwrit/,Physical writes/g;
  $record =~ s/,scall/,System calls/g;
  $record =~ s/,sread/,System reads/g;
  $record =~ s/,swrit/,System writes/g;
  $record =~ s/,fork/,Process forks/g;
  $record =~ s/,exec/,Process execs/g;
  $record =~ s/,rchar/,System read character transfers/g;
  $record =~ s/,wchar/,System write character transfers/g;
  $record =~ s/busy/ Busy/g;
  $record =~ s/,avque/,Average queue/g;
  $record =~ s/,blks/,Blocks/g;
  $record =~ s/,reads/,Reads/g;
  $record =~ s/,ppgout/,Pages paged out/g;
  $record =~ s/,pgout/,Page out requests/g;
  $record =~ s/,pgfree/,Pages freed/g;
  $record =~ s/,pgscan/,Pages scanned/g;
  $record =~ s/ufs\_ipf/ UFS inodes taken off free list/g;
  $record =~ s/,sml\_mem,alloc,fail/,Small memory pool in bytes,Small memory pool allocated,Small memory allocation fails/g;
  $record =~ s/,lg\_mem,alloc,fail/,Large memory pool in bytes,Large memory pool allocated,Large memory allocation fails/g;
  $record =~ s/,ovsz\_alloc,fail/,Oversize memory allocation in bytes,Oversize memory allocation fails/g;
  $record =~ s/,ppgin/,Pages paged in/g;
  $record =~ s/,pgin/,Page in requests/g;
  $record =~ s/,pflt/,Page faults/g;
  $record =~ s/,vflt/,Page address translation faults/g;
  $record =~ s/,slock/,Software lock requests requiring IO/g;
  $record =~ s/,runq-sz/,Run queue size/g;
  $record =~ s/,swpq-sz/,Swap queue size/g;
  $record =~ s/runocc/ Run queue occupied/g;
  $record =~ s/swpocc/ Swap queue occupied/g;
  # The google charts code displays memory in GB
  if ($option{'g'}) {
    $record =~ s/,freemem/,Pages available to user processes [GB]/g;
    $record =~ s/,freeswap/,Disk blocks available for page swapping [GB]/g;
  }
  else {
    $record =~ s/,freemem/,Pages available to user processes/g;
    $record =~ s/,freeswap/,Disk blocks available for page swapping/g;
  }
  $record =~ s/usr/ CPU used in user mode/g;
  $record =~ s/sys/ CPU used in system mode/g;
  $record =~ s/wio/ CPU used waiting on IO/g;
  $record =~ s/,iget/,inodes not in DNLC/g;
  $record =~ s/,dirblk/,Directory block reads/g;
  $record =~ s/,namei/,Filesystem path searches/g;
  $record =~ s/,msg/,Messages/g;
  $record =~ s/,sema/,Semaphores/g;
  $record =~ s/idle/ CPU idle/g;
  $record =~ s/,swpin/,Swap ins/g;
  $record =~ s/,swpot/,Swap outs/g;
  $record =~ s/,bswin/,512 byte swap ins/g;
  $record =~ s/,bswot/,512 byte swap outs/g;
  $record =~ s/,pswch/,Process switches/g;
  $record =~ s/,proc-sz/,Process table size/g;
  $record =~ s/,inod-sz/,inode table size/g;
  $record =~ s/,file-sz/,File table size/g;
  $record =~ s/,lock-sz/,Lock table size/g;
  #$record =~ s///g;
  return($record);
}

sub create_html_header {

  my $out_file = $_[0];

  open OUTPUT,">>$out_file";
  print  OUTPUT "<html>\n";
  print  OUTPUT "  <head>\n";
  print  OUTPUT "    <script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>\n";
  print  OUTPUT "    <script type=\"text/javascript\">\n";
  print  OUTPUT "      google.load(\"visualization\", \"1\", {packages:[\"corechart\"]});\n";
  print  OUTPUT "      google.setOnLoadCallback(drawChart);\n";
  print  OUTPUT "      function drawChart() {\n";
  print  OUTPUT "        var data = google.visualization.arrayToDataTable([\n";
  return;
}

sub process_sar {

  my $output;
  my $record;
  my $counter;
  my @lines;
  my $device_header;
  my $data_name;
  my $out_file;
  my @values;
  my $output_files;
  my $free_mb;

  # Open file and put data into array and process

  if (!$option{'i'}) {
    system("cd /var/adm/sa ; for i in `ls` ; do sar -A -f \$i >> /tmp/sar2cvsout");
    if (! -e "$tmp_dir") {
      system("mkdir $tmp_dir");
    }
    $option{'i'} = "$tmp_file";
  }
  open INPUT,"<$option{'i'}";
  @lines = <INPUT>;

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
      if ($option{'S'}) {
        $tmp_file = "$tmp_file\_$values[1]";
      }
      else {
        if (!$option{'o'}) {
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

        if ($option{'o'} !~ /[A-z]|[0-9]/) {
          $option{'o'} = "sar2cvs_out";
        }
        # Convert white space to comma

        $record =~ s/\s+/,/g;

        # Close any open files

        close OUTPUT;

        # Extract data type/name from line
        # Eg processing:
        # 00:00:01    %usr    %sys    %wio   %idle
        # Gives us a data type/name usr
        # A more informative data type could be derived

        @values    = split(/\,/,$record);
        $data_name = $values[1];
        $data_name =~ s/\%//g;
        $data_name =~ s/\///g;
        if ($option{'g'}) {
          $out_file = "$option{'o'}_$data_name.html";
        }
        else {
          $out_file = "$option{'o'}_$data_name.csv";
        }
        if ($output_files !~ /$out_file/) {
          $output_files = "$out_file,$output_files";
        }

        # On startup cleanup old files

        if ($counter < 5) {
          if (-e "$out_file") {
            print "Removing any previous output\n";
            system("rm $option{'o'}_*");
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
            $time  = $time+$option{'d'};
            $hours = ($time/(60*60))%24;
            if ($hours =~ /^[0-9]$/) {
              $hours = "0$hours";
            }
            $mins = ($time/60)%60;
            if ($mins =~ /^[0-9]$/) {
              $mins = "0$mins";
              }
            }
            else {
              $time = "";
            }
        }
        if ((! -e "$out_file")&&($out_file !~ /device/)) {
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
          $record =~ s/00\:00\:01\,//g;
          if ($record =~ /[a-z][0-9]/) {
            if ($option{'D'}) {
              $device_header =~ s/[0-9][0-9]\:[0-9][0-9]\:[0-9][0-9],//g;
              if ($option{'g'}) {
                $device_header =~ s/,/', '/g;
                $device_header = "$device_header'";
                $output = "'Date Time','$device_header";
              }
              else {
                $output = "Date Time,$device_header";
              }
              if ($option{'g'}) {
                $output = "          [$output],"
              }
              open OUTPUT,">>$out_file";
              print OUTPUT "$output\n";
            }
          }
          else {
            $record =~ s/[0-9][0-9]\:[0-9][0-9]\:[0-9][0-9],//g;
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
              $output = "          [$output],"
            }
            open OUTPUT,">>$out_file";
            print OUTPUT "$output\n";
          }
          close OUTPUT
        }

        # Open file for writing

        if ($out_file !~ /device/) {
          if ($record =~ /[a-z][0-9]/) {
            if ($option{'D'}) {
              open OUTPUT,">>$out_file";
            }
          }
          else {
            open OUTPUT,">>$out_file";
          }
        }

        # Handle disk stats
        # Create a separate file for each disk
        # This could be handled better

        if (($record =~ /[a-z][0-9]/)&&($record !~ /device/)) {
          if ($option{'D'}) {
            $record =~ s/$data_name//g;
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
            print OUTPUT "$output\n";
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
                $option{'s'} = `date +\%d/\%m/\%y`;
                chomp($option{'s'});
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
                  $free_mb = $values[1];
                  $free_mb = ($free_mb*8)/(1024*1024);
                  $free_mb = sprintf("%.0f",$free_mb);
                  $output  = "$output,$free_mb";
                }
              }
              else {
                if ($out_file =~ /freemem/) {
                  @values    = split(",",$output);
                  $values[1] = sprintf("%0.f",($values[1]*8)/(1024*1024));
                  $values[2] = sprintf("%0.f",($values[2]*8)/(1024*1024));
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
          print OUTPUT "$output\n";
        }
      }
    }
  }
  if ($option{'g'}) {
    @values = split(",",$output_files);
    for ($counter = 0; $counter < @values; $counter++) {
      $out_file = $values[$counter];
      if ((-e "$out_file")&&($out_file !~ /device/)) {
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

sub create_html_footer {

  my $out_file = $_[0];
  my $chart_title;

  if ($out_file =~ /atchs/) {
    $chart_title = "Paging Information";
  }
  if ($out_file =~ /breads/) {
    $chart_title = "Buffer Information";
  }
  if ($out_file =~ /igets/) {
    $chart_title = "Directory cache information";
  }
  if ($out_file =~ /msgs/) {
    $chart_title = "Message and Semaphore Information";
  }
  if ($out_file =~ /pgouts/) {
    $chart_title = "Page In and Out Information";
  }
  if ($out_file =~ /proc-sz/) {
    $chart_title = "Process Table Information";
  }
  if ($out_file =~ /rawchs/) {
    $chart_title = "Character Buffer Information";
  }
  if ($out_file =~ /runq-sz/) {
    $chart_title = "Run Queue Information";
  }
  if ($out_file =~ /scalls/) {
    $chart_title = "System Call Information";
  }
  if ($out_file =~ /sml/) {
    $chart_title = "Memory Allocation Information";
  }
  if ($out_file =~ /swpins/) {
    $chart_title = "Swap Information";
  }
  if ($out_file =~ /usr/) {
    $chart_title = "CPU Information";
  }

  open OUTPUT,">>$out_file";
  print OUTPUT "        ]);\n";
  print OUTPUT "\n";
  print OUTPUT "        var options = {\n";
  # Use a log scale for free memory so that machines with large amounts of swap
  # don't dwarf the system memory output
  if ($out_file =~ /freemem/) {
    print OUTPUT "          title: 'Sar Graph: $chart_title',\n";
    print OUTPUT "          vAxis: {logScale: 'True'}\n";
  }
  else {
    print OUTPUT "          title: 'Sar Graph: $chart_title'\n";
  }
  print OUTPUT "        };\n";
  print OUTPUT "\n";
  print OUTPUT "        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));\n";
  print OUTPUT "        chart.draw(data, options);\n";
  print OUTPUT "      }\n";
  print OUTPUT "    </script>\n";
  print OUTPUT "  </head>\n";
  print OUTPUT "  <body>\n";
  print OUTPUT "    <div id=\"chart_div\" style=\"width: 900px; height: 500px;\"></div>\n";
  print OUTPUT "  </body>\n";
  print OUTPUT "</html>\n";
  close OUTPUT;
  return;
}
