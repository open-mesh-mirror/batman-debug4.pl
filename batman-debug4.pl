#!/usr/bin/perl

use strict;
use utf8;


my ( %myself_hash, %receive_hash, $last_orig, $last_neigh, $orig_interval, $total_seconds );

$orig_interval = 1000;


if ( ! -e $ARGV[0] ) {

	print "B.A.T.M.A.N log file could not be found: $ARGV[0]\n";
	exit;

}


open(BATMANLOG, "< $ARGV[0]");

while (<BATMANLOG>) {


	if ( m/Received\ BATMAN\ packet\ from\ ([\d]+\.[\d]+\.[\d]+\.[\d]+).*?originator\ ([\d]+\.[\d]+\.[\d]+\.[\d]+)/ ) {

		$receive_hash{ $2 }{ $1 }{ "num_recv" }++;
		$last_orig = $2;
		$last_neigh = $1;

	} elsif ( m/Forwarding\ packet\ \(originator\ ([\d]+\.[\d]+\.[\d]+\.[\d]+)/ ) {

		if ( $1 eq $last_orig ) {

			$receive_hash{ $last_orig }{ $last_neigh }{ "num_forw" }++;

		} elsif ( $myself_hash{ $1 } ) {

			$myself_hash{ $1 }{ "sent" }++

		} else {

			print "Not equal: $_\n"

		}

	} elsif ( m/not\ my\ best\ neighbour/ ) {

		$receive_hash{ $last_orig }{ $last_neigh }{ "not_best" }++;

	} elsif ( m/Duplicate\ packet/ ) {

		$receive_hash{ $last_orig }{ $last_neigh }{ "dup" }++;

	} elsif ( m/Using\ interface\ (.*?)\ with\ address\ ([\d]+\.[\d]+\.[\d]+\.[\d]+)/ ) {

		$myself_hash{ $2 }{ "if" } = $1;

	} elsif ( m/orginator interval: ([\d]+)/ ) {

		$orig_interval = $1;

	}

}


close(BATMANLOG);


print "\nSent:\n^^^^\n";

foreach my $my_ip ( keys %myself_hash ) {

	$total_seconds = ( $myself_hash{ $my_ip }{ "sent" } * $orig_interval ) / 1000;
	print " => $my_ip (" . $myself_hash{ $my_ip }{ "if" } . "): send " . $myself_hash{ $my_ip }{ "sent" } . " packets in $total_seconds seconds\n";

}


print "\n\nReceived:\n^^^^^^^^";

foreach my $orginator ( keys %receive_hash ) {

	my $sum = 0;
	my $string = "";

	foreach my $neighbour ( keys %{ $receive_hash{ $orginator } } ) {

		$sum += $receive_hash{ $orginator }{ $neighbour }{ "num_recv" };
		$string .= " => $neighbour" . ( $myself_hash{ $neighbour } ? " (myself):\t" : ":\t\t" );
		$string .= " recv = " . $receive_hash{ $orginator }{ $neighbour }{ "num_recv" };
		$string .= ", forw = " . ( $receive_hash{ $orginator }{ $neighbour }{ "num_forw" } ? $receive_hash{ $orginator }{ $neighbour }{ "num_forw" } : "0" );
		$string .= " [ not best = " . ( $receive_hash{ $orginator }{ $neighbour }{ "not_best" } ? $receive_hash{ $orginator }{ $neighbour }{ "not_best" } : "0" );
		$string .= "; duplicate = " . ( $receive_hash{ $orginator }{ $neighbour }{ "dup" } ? $receive_hash{ $orginator }{ $neighbour }{ "dup" } : "0" ) . " ]\n";

	}

	print "\norginator $orginator" . ( $myself_hash{ $orginator } ? " (myself)" : "" ) . ": total recv = $sum\n";
	print $string;

}
