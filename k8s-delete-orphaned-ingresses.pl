#!/usr/bin/env perl

use JSON;

$dryrun = $ARGV[0] =~ /dry/;

$|=1;
$json = JSON->new;

$j = `kubectl get ingress --all-namespaces -o json`;
$ingresses = $json->decode($j);
foreach $ingress (@{$ingresses->{items}}) {
    $ingress_name = $ingress->{metadata}->{name};
    $ingress_namespace = $ingress->{metadata}->{namespace};
    $services = {};
    foreach $rule (@{$ingress->{spec}->{rules}}) {
        foreach $path (@{$rule->{http}->{paths}}) {
            $services->{$path->{backend}->{serviceName}} = 1 if(defined($path->{backend}->{serviceName}));
        }
    }
    $delete = 0;
    foreach $service (keys %$services) {
        $get = `kubectl -n $ingress_namespace get service $service 2>&1`;
        $delete++ if($get =~ /not found/);
    }
    if($delete == length(keys %$services)) {
        print "kubectl -n $ingress_namespace delete ingress $ingress_name\n";
        print `kubectl -n $ingress_namespace delete ingress $ingress_name` unless($dryrun);
    }
}
