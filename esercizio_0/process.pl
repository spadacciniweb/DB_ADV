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

use Data::Dumper;
use DateTime;
use DBI;
use ENV::Util;
$| = 1;

ENV::Util::load_dotenv($ENV{HOME}.'/.env/db_adv_25_esercizio_0');

my $dsn = sprintf("dbi:mysql:dbname=%s;host=%s;port=%s;",
                    $ENV{DB_NAME}, $ENV{DB_HOST}, $ENV{DB_PORT}
                 ) or die "Connection error: $DBI::errstr";
my $dbh = DBI->connect($dsn, $ENV{DB_USER}, $ENV{DB_PWD})
            or die "Connection error: $DBI::errstr";

my $dt_start = time();

my %user = ();

process_movements();
update_accounts();

my $delta_t = time() - $dt_start;
my_log( sprintf "END in %d minutes %d seconds", $delta_t / 60, $delta_t % 60 )
    if $ENV{DEBUG};
exit 0;

sub my_log {
    $_ = shift;
    printf "[%s] %s\n", DateTime->now->datetime(' '), $_ || '-> missing <-';
}

sub process_movements {
    my $sql_select = 'SELECT id, user_id, euro FROM bank_movement WHERE processed = 0';
    my $sql_upd_account = 'UPDATE bank_account SET available_balance = available_balance + ? WHERE id = ?';
    my $sql_upd_movement = 'UPDATE bank_movement SET processed = 1 WHERE id = ?';
    my $sth_select = $dbh->prepare($sql_select);
    my $sth_upd_account = $dbh->prepare($sql_upd_account);
    my $sth_upd_movement = $dbh->prepare($sql_upd_movement);

    my_log("process movements...");
    my ($counts)  = $dbh->selectrow_array('SELECT count(*) AS cnt FROM bank_movement WHERE processed = 0');

    my $line = 0;
    my $rv = $sth_select->execute;
    while (my $movement_ref = $sth_select->fetchrow_hashref) {
        $line++;
        printf "\r%.2f%%", $line*100/$counts
            if $line % 10 == 0;
        #warn Dumper( $movement_ref );
        $sth_upd_account->execute( $movement_ref->{euro}, $movement_ref->{user_id} );
        $sth_upd_movement->execute( $movement_ref->{id} );
    }
}

sub update_accounts {
    my_log( "Update accounts (available_balance -> accounting_balance)..." );
    $dbh->do('UPDATE bank_account SET accounting_balance = available_balance');
    my_log( "Updated accounts (available_balance -> accounting_balance)" );
}
