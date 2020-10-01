package App::GoogleSearchUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object 'envresmulti';

our %SPEC;

$SPEC{google_search} = {
    v => 1.1,
    summary => 'Open google search page in browser',
    args => {
        queries => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'query',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        delay => {
            summary => 'Delay between opening each query',
            schema => 'duration*',
        },
        prepend => {
            summary => 'String to add at the beginning of each query',
            schema => 'str*',
        },
        append => {
            summary => 'String to add at the end of each query',
            schema => 'str*',
        },
        num => {
            summary => 'Number of results per page',
            schema => 'posint*',
            default => 100,
        },
    },
    examples => [
        {
            summary => 'Open a single query, show 100 results',
            src => '[[prog]] "a query" -n 100',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Open several queries',
            src => '[[prog]] "query one" query2 "query number three"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use a custom browser',
            src => 'BROWSER=lynx [[prog]] "a query"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use with firefox-container',
            src => 'BROWSER="firefox-container mycontainer" [[prog]] "query one" query2',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub google_search {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $num = $args{num} + 0;

    my $envres = envresmulti();
    my $i = -1;
    for my $query0 (@{ $args{queries} }) {
        $i++;
        if ($i > 0 && $args{delay}) {
            log_trace "Sleeping %s second(s) ...", $args{delay};
            sleep $args{delay};
        }
        my $query = join(
            "",
            defined($args{prepend}) ? $args{prepend} : "",
            $query0,
            defined($args{append}) ? $args{append} : "",
        );
        my $url = "https://www.google.com/search?num=$num&q=".
            URI::Escape::uri_escape($query);
        my $res = Browser::Open::open_browser($url);
        $envres->add_result(
            ($res ? (500, "Failed") : (200, "OK")), {item_id=>$i});
    }
    $envres->as_struct;
}

1;
#ABSTRACT: CLI utilites related to google searching

=head1 SYNOPSIS

This distribution provides the following utilities:

# INSERT_EXECS_LIST
