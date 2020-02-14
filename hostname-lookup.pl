#!/usr/bin/env perl

use Socket;
use Time::HiRes qw(usleep ualarm);

die "Usage: $0 <host> [sleep] [stats]\n" unless $#ARGV >= 0;

$| = 1;
$host = $ARGV[0];
$sleep = $ARGV[1] // 1000;
$stats = $ARGV[2] // 1000;
$timeout = $ARGV[3] // 1000;

$SIG{INT} = $SIG{TERM} = \&signal;

printf("Starting hostname lookup of %s, pause %dms, timeout %dms%s\n",
       $host, $sleep, $timeout, $stats ? sprintf(", stats every %d lookup.", $stats) : ".");

while(1) {
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        ualarm($timeout * 1000);
        $ip = gethostbyname($host);
        ualarm(0);
    };
    if($@) {
        $ip = $@ eq "alarm" ? "timeout" : "fail";
    } else {
        $ip = $ip ? inet_ntoa($ip) : "n/a";
    }
    $results->{$ip}++;
    &print_stats if($stats && ++$count % $stats == 0);
    usleep($sleep * 1000);
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
