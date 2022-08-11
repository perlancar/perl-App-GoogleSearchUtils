package App::GoogleSearchUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Object 'envresmulti';

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

$SPEC{google_search} = {
    v => 1.1,
    summary => 'Open google search page in browser',
    description => <<'_',

This utility can save you time when you want to open multiple queries (with
added common prefix/suffix words) or specify some options like time limit. It
will formulate the search URL(s) then open them for you in browser. You can also
specify to print out the URLs instead.

Aside from standard web search, you can also generate/open other searches like
image, video, news, or map.

_
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
        time_start => {
            schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural'], 'x.perl.coerce_to'=>'DateTime'],
            tags => ['category:time-period-criteria'],
        },
        time_end => {
            schema => ['date*', 'x.perl.coerce_rules' => ['From_str::natural'], 'x.perl.coerce_to'=>'DateTime'],
            tags => ['category:time-period-criteria'],
        },
        time_past => {
            summary => 'Limit time period to the past hour/24hour/week/month/year',
            schema => ['str*', in=>[qw/hour 24hour day week month year/]],
            tags => ['category:time-period-criteria'],
        },
        action => {
            summary => 'What to do with the URLs',
            schema => ['str*', in=>[qw/open_url print_url print_html_link print_org_link/]],
            default => 'open_url',
            cmdline_aliases => {
                open_url        => {is_flag=>1, summary=>'Alias for --action=open_url'       , code=>sub {$_[0]{action}='open_url'       }},
                print_url       => {is_flag=>1, summary=>'Alias for --action=print_url'      , code=>sub {$_[0]{action}='print_url'      }},
                print_html_link => {is_flag=>1, summary=>'Alias for --action=print_html_link', code=>sub {$_[0]{action}='print_html_link'}},
                print_org_link  => {is_flag=>1, summary=>'Alias for --action=print_org_link' , code=>sub {$_[0]{action}='print_org_link' }},
            },
            description => <<'_',

Instead of opening the queries in browser, you can also do other action instead.
For example, `print_url` will print the search URL. `print_html_link` will print
the HTML link (the <a> tag). And `print_org_link` will print the Org-mode link,
e.g. `[[url...][query]]`.

_
        },
        type => {
            summary => 'Search type',
            schema => ['str*', in=>[qw/web image video news map/]],
            default => 'web',
            cmdline_aliases => {
                web   => {is_flag=>1, summary=>'Alias for --type=web'  , code=>sub {$_[0]{type}='web'  }},
                image => {is_flag=>1, summary=>'Alias for --type=image', code=>sub {$_[0]{type}='image'}},
                video => {is_flag=>1, summary=>'Alias for --type=video', code=>sub {$_[0]{type}='video'}},
                news  => {is_flag=>1, summary=>'Alias for --type=news' , code=>sub {$_[0]{type}='news' }},
                map   => {is_flag=>1, summary=>'Alias for --type=map'  , code=>sub {$_[0]{type}='map'  }},
            },
        },
    },
    args_rels => {
        choose_all => [qw/time_start time_end/],
        choose_one => [qw/time_start time_past/],
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
            summary => 'Open several queries, limit time period all search to the past month',
            src => '[[prog]] "query one" query2 "query number three" --time-past month',
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
        {
            summary => 'Show image search URLs instead of opening them in browser',
            src => '[[prog]] --image --print-url "query one" query2',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Print map search URLs as Org links',
            src => '[[prog]] --map --print-org-link "jakarta selatan" "kebun raya bogor"',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:firefox-container'},
        {url=>'pm:App::FirefoxMultiAccountContainersUtils'},
    ],
};
sub google_search {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $num = defined($args{num}) ? $args{num} + 0 : 100;
    my $action = $args{action} // 'web';
    my $type = $args{type} // 'web';

    my @rows;
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
        my $query_esc = URI::Escape::uri_escape($query);

        my $time_param = '';
        if (my $p = $args{time_past}) {
            if ($p eq 'h' || $p eq 'hour') {
                $time_param = 'tbs=qdr:h';
            } elsif ($p eq '24hour' || $p eq 'day') {
                $time_param = 'tbs=qdr:d';
            } elsif ($p eq 'w' || $p eq 'week') {
                $time_param = 'tbs=qdr:w';
            } elsif ($p eq 'm' || $p eq 'month') {
                $time_param = 'tbs=qdr:m';
            } elsif ($p eq 'y' || $p eq 'year') {
                $time_param = 'tbs=qdr:y';
            } else {
                return [400, "Invalid time_past value '$p'"];
            }
        } elsif ($args{time_start} && $args{time_end}) {
            my ($t1, $t2) = ($args{time_start}, $args{time_end});
            $time_param = "tbs=".URI::Escape::uri_escape(
                "cdr:1,cd_min:".
                ($args{time_start}->strftime("%m/%d/%Y")).
                ",cd_max:".($args{time_end}->strftime("%m/%d/%Y"))
            );
        }

        my $url;
        if ($type eq 'web') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'image') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=isch" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'video') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=isch" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'news') {
            $url = "https://www.google.com/search?num=$num&q=$query_esc&tbm=nws" .
                ($time_param ? "&$time_param" : "");
        } elsif ($type eq 'map') {
            return [409, "Can't specify time period for map search"];
            $url = "https://www.google.com/maps/search/$query_esc/";
        } else {
            return [400, "Unknown type '$type'"];
        }

        if ($action eq 'open_url') {
            my $res = Browser::Open::open_browser($url);
            $envres->add_result(
                ($res ? (500, "Failed") : (200, "OK")), {item_id=>$i});
        } elsif ($action eq 'print_url') {
            push @rows, $url;
        } elsif ($action eq 'print_html_link') {
            require HTML::Entities;
            my $query_htmlesc = HTML::Entities::encode_entities($query);
            push @rows, qq(<a href="$url">$query_htmlesc<</a>);
        } elsif ($action eq 'print_org_link') {
            push @rows, qq([[$url][$query]]);
        } else {
            return [400, "Unknown action '$action'"];
        }
    }
    if ($action eq 'open_url') {
        return $envres->as_struct;
    } else {
        return [200, "OK", \@rows];
    }
}

1;
#ABSTRACT: CLI utilites related to google searching

=head1 SYNOPSIS

This distribution provides the following utilities:

# INSERT_EXECS_LIST
