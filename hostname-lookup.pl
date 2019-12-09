#!/usr/bin/env perl

use Socket;

die "Usage: $0 <host> [sleep] [stats]\n" unless $#ARGV >= 0;

$| = 1;
$host = $ARGV[0];
$sleep = $ARGV[1] // 1000;
$stats = $ARGV[2] // 1000;

$SIG{INT} = $SIG{TERM} = \&signal;

printf("Starting hostname lookup of %s, pause %dms%s\n",
       $host, $sleep, $stats ? sprintf(", stats every %d lookup.", $stats) : ".");

while(1) {
    $ip = gethostbyname($host);
    $ip = $ip ? inet_ntoa($ip) : "n/a";
    $results->{$ip}++;
    &print_stats if($stats && ++$count % $stats == 0);
    select(undef, undef, undef, $sleep / 1000);       
}

sub print_stats {
    foreach $r (keys %$results) {
        printf("%d %s\n", $results->{$r}, $r);
    }
    printf("%d total\n", $count);
}
            
sub signal {
    print "Lookup results:\n";
    &print_stats;
    exit;
}
