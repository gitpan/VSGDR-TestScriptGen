#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';


use Carp;
use DBI;


use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use VSGDR::TestScriptGen;

use IO::File ;
use File::Basename;


use version ; our $VERSION = qv('0.01');

croak 'no input file'  unless defined($opt_outfile) ;
my $outfile;
$outfile = $opt_outfile;
my($infname, $directories, $insfx)      = fileparse($outfile , qr/\..*/);
croak 'Invalid input file'   unless defined $insfx ;

my $dbh             = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });



my $staticDataScript = VSGDR::TestScriptGen::generateScripts($dbh,$directories) ;
#say $staticDataScript; 

exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genTests.pl - Creates unit test scripts for a database

=head1 VERSION

0.01


=head1 USAGE

genTests.pl --c <odbc connection> [options]


=head1 REQUIRED ARGUMENTS

=over

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=item  -o[ut][file]  [=]<file>

Specify output file (directory)

=for Euclid:
    file.type:    writable




=back


=head1 OPTIONS

=over


=back


=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2014, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

