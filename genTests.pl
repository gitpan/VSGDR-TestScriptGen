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


use version ; our $VERSION = qv('0.02');

croak 'no input file'           unless defined($main::opt_outfile) ;
my $outfile;
$outfile                                = $main::opt_outfile;
my($infname, $directories, $insfx)      = fileparse($outfile , qr/\..*/);
croak 'Invalid input file'      unless defined $insfx ;

my $dbh                                 = DBI->connect("dbi:ODBC:${main::opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });
my $dbh_typeinfo                        = DBI->connect("dbi:ODBC:${main::opt_connection}", q{}, q{}, { LongReadLen => 512000, AutoCommit => 1, RaiseError => 1 });



my $void = VSGDR::TestScriptGen::generateScripts($dbh,$dbh_typeinfo,$directories) ;


exit ;

END {
    $dbh->disconnect()          if $dbh ;
}




__DATA__


=head1 NAME


genTests.pl - Creates unit test scripts for a database

=head1 VERSION

0.02


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

