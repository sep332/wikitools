#!/usr/bin/perl
use strict;
use open ':encoding(utf8)';

use XML::Twig;
use DBI;
use Regexp::Assemble;

my $dsn = 'dbi:mysql:wikis';
my $dbh = DBI->connect($dsn, "user", "password", { RaiseError => 1, AutoCommit => 0 } );

# UTF-8 all the things
my $encoding = <<'ENCODING';
SET character_set_results = 'utf8',
character_set_client = 'utf8',
character_set_connection = 'utf8',
character_set_database = 'utf8',
character_set_server = 'utf8'
ENCODING
$dbh->do($encoding);

my $sth = $dbh->prepare("INSERT INTO `wikis`.`wikipedia` (`id`, `title`, `body`) VALUES (?, ?, ?)");

my $boring = Regexp::Assemble->new;
$boring->add( '^Wikipedia:' );
$boring->add( '^List of ' );
$boring->add( '^Lists of ' );
$boring->add( '^Recipients of ' );
my $exclude = $boring->re;

my $default = select(STDOUT);
$|++;
select($default);

my ($title, $body, $index, $actual);

## We can't use "id" as a field_accessor, because there's already a member "id".
my $twig = XML::Twig->new( twig_roots => { 'page' => \&page },
                           field_accessors => ['title', 'ns'],
                           ignore_elts => [ 'parentid', 'timestamp', 'contributor',
                                            'minor', 'comment', 'sha1', 'model',
                                            'format' ] );

## Commit every $count entries.
## Don't worry too much about data loss,
## you can pick up where you left off.
my $count = 10000;
my $dcount = $count;

if ( my $file= $ARGV[0] ) { $twig->parsefile( $file ); } 
else                      { $twig->parse( \*STDIN );   }

$dbh->commit;
$dbh->disconnect;
print "\n";

sub page 
{
        my ($twig, $page) = @_;

        $index++;
        if ($index == $count)
        {
                $dbh->commit;
                $count += $dcount;
        }
        printf "\rRead %d, Inserted %d", $index, $actual;

        if ($page->has_child('redirect')) { $twig->purge; return; }

        if ($page->ns != 0) { $twig->purge; return; }

        $title = $page->title;
        if ($title =~ $exclude) { $twig->purge; return; }

        $body = $page->first_child('revision')->field('text');

        $sth->execute($page->field('id'), $title, $body);

        $actual++;

        $twig->purge;
}
