#!/usr/bin/env perl

while($#ARGV >= 0) {
    $arg = shift(@ARGV);
    $verbose = 1 if($arg eq '-v');
    $host = shift(@ARGV) if($arg eq '-host');
    $database = shift(@ARGV) if($arg eq '-database');
    $interval = shift(@ARGV) if($arg eq '-interval');
}
$host = $ENV{'INFLUX_HOST'} unless($host);
$database = $ENV{'INFLUX_DATABASE'} unless($database);
$interval = '1h' unless($interval);

die("Usage: $0 [-v] [-host <host>] [-database <database>] [-interval <interval>]\n") unless($host && $database && $interval);

$| = 1;

$measurements = `influx -host $host -database $database -execute 'show measurements' -format csv`;
foreach $l (split("\n", $measurements)) {
    if($l =~ /^measurements,(.+)$/) {
        $measurement = $1;
        $m = $measurement =~ s/\"/\\\"/gr;
        $series = `influx -host $host -database $database -execute 'show series from "$m" where time > now() - $interval' | wc -l`;
        $count->{$measurement} = $series;
        printf STDERR ("%s: %d\n", $measurement, $series) if($verbose);
    }
}

foreach $measurement (sort { $count->{$a} <=> $count->{$b} } keys %$count) {
    printf("%s: %d\n", $measurement, $count->{$measurement}) if($count->{$measurement}) > 0;
}
