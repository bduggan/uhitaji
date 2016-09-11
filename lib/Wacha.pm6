use nqp;
use QAST:from<NQP>;

use Utiaji::App;
use Utiaji::Router;
use Utiaji::Server;

my $router;

sub set-router($r) is export {
    $router = $r;
}

multi sub add_route($pattern, Str $str) is export {
    my $r = Utiaji::Route.new(
        verb => 'GET',
        pattern => Utiaji::Pattern.new( :$pattern ),
        code => sub { return $str });
    $router.routes.push: $r;
}

multi sub add_route($pattern, Code $block) is export {
    my $r = Utiaji::Route.new(
        verb => 'GET',
        pattern => Utiaji::Pattern.new( :$pattern ),
        code => $block);
    $router.routes.push: $r;
}

role Wacha::Grammar {
    rule statement_control:sym<route> {
        <route-verb> <route-pattern> [ <block(1)> | <term> ]
    }

    token route-verb { [ get | post | put | del | '' ] }

    token route-pattern { '/' \S* }
}

role Wacha::Actions {
    sub sval($str) {
        return QAST::SVal.new(:value(~$str));
    }

    sub atkeyish(Mu \h, \k) {
       nqp::atkey(nqp::findmethod(h, 'hash')(h), k)
    }

    method statement_control:sym<route>(Mu $/) {
        my $pattern = atkeyish($/, 'route-pattern').Str;
        my $target = atkeyish($/, 'term') || atkeyish($/, 'block');
        $/.make: QAST::Op.new( :name<&add_route>, :op<call>, sval($pattern), $target.ast);
    }
}

class AutoApp is Utiaji::App { }
my $app = AutoApp.new();

sub go is export {
    Utiaji::Server.new(app => $app).start-fork;
    loop {}
}

sub EXPORT {
    set-router($app.router);
    %*LANG<MAIN> := %*LANG<MAIN>.^mixin(Wacha::Grammar);
    %*LANG<MAIN-actions> := %*LANG<MAIN-actions>.^mixin(Wacha::Actions);
    {}
}


