use Utiaji::Log;

# Turns patterns for routes into regexes.

grammar Utiaji::Router {
    token TOP          { '/' <part> *%% '/' }
    token part         { <literal> || <placeholder> }
    token literal      { <[a..z]>+ }

    token placeholder  {
              <placeholder_word>
            | <placeholder_ascii_lc>
            | <placeholder_date> }
    token placeholder_word     { ':' <var> }
    token placeholder_ascii_lc { '_' <var> }
    token placeholder_date     { 'Δ' <var> } # delta : D*

    token var { <[a..z]>+ }
}

use MONKEY-SEE-NO-EVAL;
# NB: It is possible to avoid the above and just use =placeholder*, but
# then there are extra named captures.
class Utiaji::RouterActions {
    method TOP($/)     {
        $/.make: q[ '/' ] ~ join q[ '/' ], map { .made }, $<part>;
    }
    method part($/)    {
        $/.make: $<literal>.made // $<placeholder>.made;
    }
    method placeholder($/){
        $/.make: $<placeholder_word>.made
              // $<placeholder_ascii_lc>.made
              // $<placeholder_date>.made}
    method placeholder_word($/)     { $/.make: "<" ~ $<var>.made ~ '=&placeholder_word>'; }
    method placeholder_ascii_lc($/) { $/.make: "<" ~ $<var>.made ~ '=&placeholder_ascii_lc>'; }
    method placeholder_date($/)     { $/.make: "<" ~ $<var>.made ~ '=&placeholder_date>'; }

    method var($/)     {
        $/.make: ~$/;
    }
    method literal($/) {
        $/.make: ~$/;
    }
}

class Utiaji::Matcher {
    has Str $.pattern;
    has Str $.rex is rw;       # Compiled pattern ( used within a regex )
    has Match $.captures is rw;

    my regex placeholder_word     { [ \w | '-' ]+ }
    my regex placeholder_ascii_lc { [ <[a..z]> | <[0..9]> | '_' | '-' ]+ }
    my regex placeholder_date     { <[0..9]>**4 '-' <[0..9]>**2 '-' <[0..9]>**2 }

    method !compile {
        trace "compiling $.pattern";
        $.rex //= do {
            my $parser = Utiaji::Router.parse(
                        $.pattern,
                        actions => Utiaji::RouterActions.new);
            $parser.made;
        };
    }

    method match(Str $path) is export {
        trace "Parsing $path";
        self!compile;
        my $result = $path ~~ rx{ ^ <captured={$.rex}> $ };
        $.captures = $<captured>.clone;
        # TODO grep: { $_.kv[0] !~~ /^placeholder/ };
        # $_ = ~$_ for values %.captures;
        return $result;
    }
}
