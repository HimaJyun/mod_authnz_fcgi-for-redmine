#!/usr/bin/perl

=head1 NAME

fcgiauthredmine - Apache mod_authnz_fcgi for Redmine.

=head1 SYNOPSIS

fcgiauthredmine.pl [options]

 Options:
   --dsn  Database connection string.
   --user Database user.
   --pass Database password.
   --mysql_auto_reconnect Only MySQL, Automatically reconnect.

 DSN:
   MySQL => DBI:mysql:database=${DB_NAME};host=localhost;mysql_socket=/run/mysqld/mysqld.sock
   SQLite => DBI:SQLite:database=/your/redmine/sqlite/database/path.db # Deprecated.
   PostgresSQL => DBI:Pg:database=${DB_NAME};host=localhost

 Example:
   fcgiauthredmine.pl --dsn="DBI:mysql....." --user="root" --pass="123" --mysql_auto_reconnect
   fcgiauthredmine.pl --dsn="DBI:SQLite....."

 Heed:
   Be sure to use spawn-fcgi.

=cut

use strict;
use warnings;

use DBI;
use FCGI;
use Digest::SHA "sha1_hex";
use Pod::Usage qw(pod2usage);
use Getopt::Long qw(:config posix_default bundling auto_help no_ignore_case);

GetOptions(
	\my %opt, qw(
		dsn=s
		user=s
		pass=s
		mysql_auto_reconnect
));
pod2usage(2) if !exists $opt{dsn};

# DB Connection.
my $dbh;
if(exists($opt{user}) && exists($opt{pass})) {
	$dbh = DBI->connect($opt{dsn},$opt{user},$opt{pass});
} else {
	$dbh = DBI->connect($opt{dsn});
}
if ( $opt{mysql_auto_reconnect} ) {
	$dbh->{"mysql_auto_reconnect"} = 1;
}

$SIG{"TERM"} = sub {
	# DB disconnect.
	$dbh->disconnect;
	exit(0);
};

my $fcgi = FCGI::Request();
while($fcgi->Accept() >= 0) {
	if($ENV{"FCGI_APACHE_ROLE"} ne "AUTHENTICATOR"
	|| $ENV{"FCGI_ROLE"} ne "AUTHORIZER"
	|| !$ENV{"REMOTE_PASSWD"}
	|| !$ENV{"REMOTE_USER"}) {
		die("Value is invalid.\n");
	}

	my $prepare = $dbh->prepare("SELECT hashed_password, salt FROM users WHERE login=? LIMIT 1");
	$prepare->execute($ENV{"REMOTE_USER"});

	my $hashed_password;
	my $salt;
	$prepare->bind_col(1, \$hashed_password);
	$prepare->bind_col(2, \$salt);

	if($prepare->fetch) {
		my $calc_hash = sha1_hex(
			$salt.sha1_hex($ENV{"REMOTE_PASSWD"})
		);
		if($calc_hash eq $hashed_password) {
			# match
			print "Status: 200\n";
			print "Variable-AUTHN_1: authn_01\n";
			print "Variable-AUTHN_2: authn_02\n";
			print "\n";
		} else {
			# not match
			sleep(1);
			print "Status: 401\n\n";
		}
	} else {
		# User not found.
		#select(undef,undef,undef,0.5);
		sleep(1);
		print "Status: 401\n\n";
	}

	$prepare->finish();
}