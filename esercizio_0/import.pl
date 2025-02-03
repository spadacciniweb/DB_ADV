#!/usr/bin/env perl

=head
bank_account
"username","euro","datetime"
username String
euro     2 decimal value
datetime YYYY-MM-DDThh:mm:ss

bank_movements
"username","type","euro","datetime"
username String
type     String
euro     2 decimal value
datetime YYYY-MM-DDThh:mm:ss.mil
=cut

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;
use DateTime;
use DBI;
use ENV::Util;

ENV::Util::load_dotenv($ENV{HOME}.'/.env/db_adv_25_esercizio_0');

my $dsn = sprintf("dbi:mysql:dbname=%s;host=%s;port=%s;",
                    $ENV{DB_NAME}, $ENV{DB_HOST}, $ENV{DB_PORT}
                 ) or die "Connection error: $DBI::errstr";
my $dbh = DBI->connect($dsn, $ENV{DB_USER}, $ENV{DB_PWD})
            or die "Connection error: $DBI::errstr";

my $dt_start = DateTime->now;

my %user = ();

deletePrev()
    if $ENV{DELETE};


import_bank_accounts();
import_movements();
        
my $dt_end = DateTime->now;
my_log( sprintf "END in %s seconds", ($dt_end - $dt_start)->seconds )
    if $ENV{DEBUG};
exit 0;

sub my_log {
    $_ = shift;
    printf "[%s] %s\n", DateTime->now, $_ || '-> missing <-';
}

sub deletePrev {
    my @tables = qw/ bank_movement bank_movement_trigger bank_account /;
    foreach my $table (@tables) {
        my $sql = sprintf "DELETE FROM %s", $table;
        $dbh->do( $sql );
        my_log( sprintf "DELETE TABLE %s", $table)
            if $ENV{DEBUG};
    }
}

sub import_bank_accounts {
    my $csv = Text::CSV->new({
      binary    => 1,
      auto_diag => 1,
      sep_char  => ','
    });

    my_log("import bank accounts...");

    my $line = 0;
    open(my $data, '<:encoding(utf8)', $ENV{BANK_ACCOUNTS})
        or die "Could not open '$ENV{BANK_ACCOUNTS}' $!\n";
    $csv->getline( $data ); # skip header

    my $sql_select = 'SELECT id  FROM bank_account WHERE username = ?';
    my $sth_select = $dbh->prepare($sql_select);
    my $sql_insert = 'INSERT INTO bank_account (username, accounting_balance, available_balance) VALUES (?,?,?)';
    my $sth_insert = $dbh->prepare($sql_insert);

    while (my $fields = $csv->getline( $data )) {
        $line++;
        my_log( sprintf "line %d...", $line )
            if $line % 1000 == 0;
        my %account = (
            username => $fields->[0],
            euro     => $fields->[1],
            dt       => $fields->[2],
        );
        # warn Dumper( \%account );
        $sth_select->execute( $account{username} );
        my ($user_id) = $sth_select->fetchrow_array;
        if ($user_id) {
            $user{ $account{username} } = $user_id;
            # already in the DB so I don't do anything
        } else {
            $sth_insert->execute( $account{username}, $account{euro}, $account{euro} );
            $sth_select->execute( $account{username} );
            ($user_id) = $sth_select->fetchrow_array;
            $user{ $account{username} } = $user_id;
        }
    }
    if (not $csv->eof) {
      $csv->error_diag();
    }
    close $data;
}

sub import_movements {
    my $csv = Text::CSV->new({
      binary    => 1,
      auto_diag => 1,
      sep_char  => ','
    });

    my_log("import bank movements...");

    my $line = 0;
    open(my $data, '<:encoding(utf8)', $ENV{BANK_MOVEMENTS})
        or die "Could not open '$ENV{BANK_MOVEMENTS}' $!\n";
    $csv->getline( $data ); # skip header

    my $sql_insert = 'INSERT INTO bank_movement (user_id, euro, dt_src) VALUES (?,?,?)';
    my $sth_insert = $dbh->prepare($sql_insert);

    while (my $fields = $csv->getline( $data )) {
        $line++;
        my_log( sprintf "line %d...", $line )
            if $line % 1000 == 0;
        my %movement = (
            user_id => $user{ $fields->[0] },
            euro    => ($fields->[1] eq 'ADD')
                ? $fields->[2]
                : -$fields->[2],
            dt_src => $fields->[3],
        );
        #warn Dumper( \%movement );
        $sth_insert->execute( $movement{user_id}, $movement{euro}, $movement{dt_src} );
    }
    if (not $csv->eof) {
      $csv->error_diag();
    }
    close $data;
}
