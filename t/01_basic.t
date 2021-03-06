use strict;
use Test::More;
use Test::Exception;
use FindBin;
use t::Util;
use lib ( "$FindBin::Bin/lib" );
use MySchema;
use Data::Model::Driver::MongoDB;

my ( $server, $guard ) = run_test_server();

my $mongodb;
my $c;

lives_ok {
    $mongodb = Data::Model::Driver::MongoDB->new(
        host => 'localhost',
        port => $server->port,
        db => 'mytest',
    );
} 'generating an instance of D::M::D::MongoDB';

lives_ok {
    $c = MySchema->new;
} 'MySchema --- D::M::Schema for testing';

isa_ok $mongodb, 'Data::Model::Driver::MongoDB';
isa_ok $c, 'MySchema';
lives_ok { $c->set_base_driver( $mongodb ) } 'set_base_driver';
isa_ok $c->get_base_driver, 'Data::Model::Driver::MongoDB';


{
    my $res;
    my $cols = { 
        name => 'ytnobody',
        age => 30,
    };

    lives_ok { $res = $c->set( people => $cols ) } 'set a data';
    isa_ok $res, 'MySchema::people';
    is $res->$_, $cols->{ $_ } for keys %{ $cols };
    is $res->id, $res->{ column_values }->{ _id }->to_string, 'primary_key == stringified object-id';
    
    my $res2;
    lives_ok { $res2 = $c->lookup( people => $res->id ) } 'lookup a data by primary_key' ;
    isa_ok $res2, 'MySchema::people';
    is_deeply $res->get_columns, $res2->get_columns, 'deeply-equal';

    lives_ok { $res->delete } 'delete a data';

    lives_ok { $res->age( 25 ) } 'change age column';
    lives_ok { $res->name( 'YellowTurtle' ) } 'change name column';
    lives_ok { $res->update } 'commit changes';
    is $res->age, 25;
    is $res->name, 'YellowTurtle';

    my $res3;
    lives_ok {
        $res3 = $c->lookup( people => $res->id );
    } 'lookup a deleted data --- warn, but not die';
    is $res3, undef, 'could not lookup a data';

    is $c->lookup( people => '123456789' ), undef, 'nothing data with such id';
}

undef $server;

done_testing();
