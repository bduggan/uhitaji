use Utiaji::Log;

grammar header-parser {
     rule TOP {
        <verb> <path> "HTTP/1.1" \n
        <headers>
     }
     token ws { \h* }
     token verb {
         GET | POST | PUT
     }
     token path {
         '/' <segment>* %% '/'
     }
     token segment {
         [ <alpha> | <digit> | '+' | '-' | '.' ]*
     }
     rule headers {
        [ <header> \n ]*
     }
     rule header {
        <field-name> ':' <field-value>
     }
     token field-name {
         <-[:]>+
     }
     token field-value {
         <-[\n\r]>+
     }
}

class header-actions {
    method TOP($/) {
        $/.make: Utiaji::Request.new:
            path => $<path>.made,
            method => $<verb>.made,
            headers => $<headers>.made,
    }
    method headers($/) {
        $/.make: Utiaji::Headers.new:
        fields => [ map {.made }, $<header> ]
    }
    method header($/) {
        $/.make: $<field-name>.made => $<field-value>.made
    }
    method path($/) { $/.make: ~$/; }
    method verb($/) { $/.make: ~$/; }
    method field-name($/) { $/.make: ~$/ }
    method field-value($/) { $/.make: ~$/ }
}

class Utiaji::Headers {
    has $.raw;
    has %.fields;
    has Str $.content-type;
    has Int $.content-length;

    method parse {
        my $actions = header-actions.new;
        my $match = header-parser.parse("$!raw\n", :$actions);
        unless $match {
            error "did not parse headers { $!raw.perl }";
            return;
        }
        my $request = $match.made;
        self.normalize;
    }

    method host {
        return %!fields<Host>;
    }

    method normalize {
        for %!fields.kv -> $k, $v {
            if fc($k) eq fc('content-length') {
                $!content-length = 0+$v;
            }
        }
    }
}


