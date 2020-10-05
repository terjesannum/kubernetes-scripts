#!/usr/bin/env perl

use Getopt::Long;
use Net::DNS;
use Time::HiRes qw(usleep ualarm);

$| = 1;

my $host = undef;
my $nameserver = undef;
my $sleep = 10;
my $stats = 1000;
my $timeout = 200;

GetOptions("host=s", \$host,
           "nameserver=s", \$nameserver,
           "sleep=i", \$sleep,
           "stats=i", \$stats,
           "timeout=i", \$timeout
    );

die "Usage: $0 --host <host> [--nameserver <nameserver>] [--sleep <sleep>] [--stats <stats>] [--timeout <timeout>]\n" unless $host;


$SIG{INT} = $SIG{TERM} = \&signal;

printf("Starting hostname lookup of %s%s, pause %dms, timeout %dms%s\n",
       $host, ($nameserver ? sprintf(" using %s", $nameserver) : ""), $sleep, $timeout, $stats ? sprintf(", stats every %d lookups.", $stats) : ".");

my $resolver = Net::DNS::Resolver->new;
$resolver->nameservers($nameserver) if($nameserver);
my ($results, $count);

while(1) {
    my ($reply, $result);
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        ualarm($timeout * 1000);
        $reply = $resolver->search($host);
        ualarm(0);
    };
    if($@ =~ /timeout/) {
        $result = "timeout";
    } elsif($@) {
        $result = "($@)";
    } elsif($reply) {
        $result = "n/a";
        foreach my $rr ($reply->answer) {
            if($rr->can("address")) {
                $result = $rr->address;
                last;
            }
        }
    } else {
        $result = $resolver->errorstring;
    }
    $results->{$result}++;
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
