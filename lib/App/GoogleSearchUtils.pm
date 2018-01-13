package App::GoogleSearchUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{google_search} = {
    v => 1.1,
    summary => 'Open google search page in browser',
    args => {
        query => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        num => {
            summary => 'Number of results per page',
            schema => 'posint*',
            default => 100,
        },
    },
};
sub google_search {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $query = $args{query} or return [400, "Please specify query"];
    my $num = $args{num} + 0;

    my $url = "https://www.google.com/search?num=$num&q=".
        URI::Escape::uri_escape($query);

    my $res = Browser::Open::open_browser($url);

    $res ? [500, "Failed"] : [200, "OK"];
}

1;
#ABSTRACT: CLI utilites related to google searching

=head1 SYNOPSIS

This distribution provides the following utilities:

# INSERT_EXECS_LIST
