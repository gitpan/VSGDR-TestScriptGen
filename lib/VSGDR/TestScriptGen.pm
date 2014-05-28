package VSGDR::TestScriptGen;

use strict;
use warnings;

use 5.010;

use List::Util qw(max);
use POSIX qw(strftime);
use Carp;
use DBI;
use Data::Dumper;
use IO::File ;
use File::Basename;

=head1 NAME

VSGDR::TestScriptGen - Unit test script support package for SSDT unit tests, Ded MedVed..

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


sub databaseName {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2 = $dbh->prepare(databaseNameSQL());
    my $rs   = $sth2->execute();
    my $res  = $sth2->fetchall_arrayref() ;

    return $$res[0][0] ;

}

sub databaseNameSQL {

return <<"EOF" ;

select  db_name()

EOF

}

sub ExecSp {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2    = $dbh->prepare( ExecSpSQL());
    my $rs      = $sth2->execute();
    my $res     = $sth2->fetchall_arrayref() ;

    if ( scalar @{$res} ) { return $res ; } ;
    return [] ;
}



sub ExecSpSQL {

return <<"EOF" ;


; with BASE as (
SELECT  cast([PARAMETER_NAME] + ' = ' + [PARAMETER_NAME] + case when PARAMETER_MODE = 'IN' then '' else  'OUTPUT' + CHAR(10) + CHAR(13) end as VARCHAR(MAX)) as PARAMTER
,		cast([PARAMETER_NAME] + '  ' + DATA_TYPE+coalesce('('+cast(CHARACTER_MAXIMUM_LENGTH as varchar)+')','') + CHAR(10) + CHAR(13) as VARCHAR(MAX)) as DECLARATION
,       [SPECIFIC_CATALOG]
,       [SPECIFIC_SCHEMA]
,       [SPECIFIC_NAME]
,       [ORDINAL_POSITION]
,       [PARAMETER_MODE]
FROM    [CallValidate].[INFORMATION_SCHEMA].[PARAMETERS]
where   1=1 
and     ORDINAL_POSITION = 1
union all 
select  cast(PARAMTER + ',' + N.[PARAMETER_NAME] + ' = ' + N.[PARAMETER_NAME] + case when N.PARAMETER_MODE = 'IN' then '' else  ' OUTPUT' + CHAR(10) + CHAR(13) end as varchar(max))
,		cast(DECLARATION + ',' + [PARAMETER_NAME] + '  ' + DATA_TYPE+coalesce('('+cast(CHARACTER_MAXIMUM_LENGTH as varchar)+')','') + CHAR(10) + CHAR(13) as VARCHAR(MAX))
,       N.[SPECIFIC_CATALOG]
,       N.[SPECIFIC_SCHEMA]
,       N.[SPECIFIC_NAME]
,       N.[ORDINAL_POSITION]
,       N.[PARAMETER_MODE]
from    [INFORMATION_SCHEMA].[PARAMETERS] N 
join    BASE B
on      N.[SPECIFIC_NAME]           = B.[SPECIFIC_NAME]
and     N.[SPECIFIC_SCHEMA]         = B.[SPECIFIC_SCHEMA]
and     N.[SPECIFIC_CATALOG]        = B.[SPECIFIC_CATALOG]
and     N.ORDINAL_POSITION          = B.ORDINAL_POSITION+1
)
, ALLL as ( 
select  *
,       ROW_NUMBER() over (partition by [SPECIFIC_CATALOG],[SPECIFIC_SCHEMA],[SPECIFIC_NAME] order by ORDINAL_POSITION DESC ) as RN  
from    BASE 
)
, PARAMS as (
select * from ALLL where RN = 1
)
select  R.SPECIFIC_SCHEMA + '.' + R.SPECIFIC_NAME as sp
,	coalesce('declare ' + DECLARATION,'')		as DECLARATION
,       'execute ' + R.SPECIFIC_SCHEMA + '.' + R.SPECIFIC_NAME + ' ' + coalesce(B.PARAMTER,'') as sql 
from    INFORMATION_SCHEMA.ROUTINES R
LEFT    JOIN    PARAMS B
on      R.[SPECIFIC_NAME]           = B.[SPECIFIC_NAME]
and     R.[SPECIFIC_SCHEMA]         = B.[SPECIFIC_SCHEMA]
and     R.[SPECIFIC_CATALOG]        = B.[SPECIFIC_CATALOG]
where   R.ROUTINE_TYPE = 'PROCEDURE'

EOF

}


sub generateScripts {

    local $_ = undef;

    my $dbh     = shift ;
    my $dirs    = shift ;

    croak "bad arg dbh"     unless defined $dbh;
    my $database        = databaseName($dbh);

    no warnings;
    my $userName        = @{[getpwuid( $< )]}->[6]; $userName =~ s/,.*//;
    use warnings;
    my $date            = strftime "%d/%m/%Y", localtime;
    
#warn Dumper $ra_columns ;
#exit ;

    my $execs                   = ExecSp($dbh) ;



#warn Dumper     $widest_column_name_padding;
    foreach my $exec (@$execs) {
        
        my $file = $$exec[0];
        my $text = Template($dbh, $$exec[0], $userName, $date, $$exec[1],$$exec[2] ) ;
        my $fh   = IO::File->new("> ${dirs}/${file}.sql") ;
       
        if (defined ${fh} ) {
            print {${fh}} $text ;
            $fh->close;
        }
        else {
            croak "Unable to write to ${file}.sql.";
        }
    }

exit;
}

sub Template {

    local $_ = undef;

    my $dbh             = shift ;
    my $sut             = shift ;

    my $userName        = shift ;
    my $date            = shift ;

    my $declaration     = shift ;
    my $code            = shift ;
    
return <<"EOF";


/* AUTHOR
*    ${userName}
*
* DESCRIPTION
*    Tests the minimal case for ${sut}
*    Runs a basic smoke-test.
*
* SUT
*    ${sut}
*
* OTHER
*    Other notes.
*
* CHANGE HISTORY
*    ${date} ${userName}
*    Created.
*/


set nocount on

begin try

    declare \@testStatus varchar(100) 
    set     \@testStatus = 'Passed'

    begin transaction

    ${declaration}

    ${code}
    
    select \@testStatus    


end try
begin catch

    set \@testStatus = 'Failed'

    select \@testStatus
    select error_state()
    select error_message()
    select error_number()

end catch


if \@\@trancount > 0
    rollback


EOF

}




__DATA__



=head1 SYNOPSIS

Package to support the generation of stored procedure unit test scripts for SQL Server Data Tools.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved@cpan.org> >>


=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VSGDR::TestScriptGen


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TestScriptGen
