#!/usr/bin/env perl

use Getopt::Long;
use POSIX qw(strftime);
use LWP::UserAgent;

$influx_host = $ENV{'INFLUX_HOST'} || 'localhost';
$influx_port = $ENV{'INFLUX_PORT'} || '8086';
$influx_url = "http://$influx_host:$influx_port";
$influx_db = $ENV{'INFLUX_DATABASE'} || 'metrics';
$influx_user = $ENV{'INFLUX_USERNAME'} || 'user';
$influx_password = $ENV{'INFLUX_PASSWORD'} || 'password';
$measurement = 'test.foo';
$tag = 'zot';
$series = 10;
$batch = 50;
$total = 10000;
$base = 0;
$scale = 1;
$generator = 'sine';
$start_time = time - 60*60;
$end_time = time;

GetOptions("influx_url=s", \$influx_url,
           "influx_db=s", \$influx_db,
           "influx_user=s", \$influx_user,
           "influx_password=s", \$influx_password,
           "measurement=s", \$measurement,
           "tag=s", \$tag,
           "series=i", \$series,
           "batch=i", \$batch,
           "total=i", \$total,
           "base=f", \$base,
           "scale=i", \$scale,
           "generator=s", \$generator,
           "start_time=i", \$start_time,
           "end_time=i", \$end_time
    );

$ua = LWP::UserAgent->new;
$data = [];

for($i=0; $i<$total; $i++) {
    $t = $start_time + $i * ($end_time - $start_time) / $total;
    if($generator eq 'sine') {
        push(@$data, sprintf("%s,%s=%d value=%f %d", $measurement, $tag, $i % $series, $scale*($base+sin(2*3.14*($i%$series)/$series + $i*2*3.14/$total)), ($t*1000*1000*1000)+($i%1000)));
    } elsif($generator eq 'random') {
        push(@$data, sprintf("%s,%s=%d value=%f %d", $measurement, $tag, $i % $series, $scale*($base+rand), ($t*1000*1000*1000)+($i%1000)));
    } else {
        push(@$data, sprintf("%s,%s=%d value=%f %d", $measurement, $tag, $i % $series, $scale*$base, ($t*1000*1000*1000)+($i%1000)));
    }
    if($i && !($i % $batch)) {
        write_data($data);
        $data = [];
    }
}
write_data($data) if(@$data > 0);

printf("Wrote %d entries in %d series from %s to %s\n", $total, $series, strftime("%Y-%m-%d %H:%M:%S", localtime($start_time)), strftime("%Y-%m-%d %H:%M:%S", localtime($end_time)));

sub write_data {
    my($data) = @_;
    my($req) = HTTP::Request->new(POST => "$influx_url/write?db=$influx_db&u=$influx_user&p=$influx_password");
    $req->content(join("\n", @$data));
    my($res) = $ua->request($req);
    warn(sprintf("write error: %s\n", $res->code)) if(!$res->is_success);
}
