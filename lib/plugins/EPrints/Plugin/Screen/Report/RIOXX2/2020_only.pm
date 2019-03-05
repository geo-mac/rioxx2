package EPrints::Plugin::Screen::Report::RIOXX2::2020_only;

use EPrints::Plugin::Screen::Report::RIOXX2;
our @ISA = ( 'EPrints::Plugin::Screen::Report::RIOXX2' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{report} = 'rioxx2-2020-only';

	return $self;
}

sub filters
{
	my( $self ) = @_;

	my @filters = @{ $self->SUPER::filters || [] };

	push @filters, { meta_fields => [ "date" ], value => '2020', match => "IN" };

	return \@filters;
}

1;
