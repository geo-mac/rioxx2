
$c->{rioxx2}->{type_map} = {
	article		=> 'journal_article',
	book_section	=> 'book_chapter',
	monograph	=> 'monograph',
	conference_item	=> 'conference_item',
	book		=> 'book',
	thesis		=> 'thesis',
};

$c->{rioxx2}->{content_map} = {
	draft		=> "AO",
	submitted	=> "SMUR",
	accepted	=> "AM",
	published	=> "P",
};

my @rioxx2_fields = (
	{
		target => "dc:coverage",
		source => "eprint.rioxx2_coverage",
		required => "optional",
	},
	{
		target => "dc:description",
		source => "eprint.abstract", # TODO strip HTML
		required => "recommended",
	},
	{
		target => "dc:format",
		source => "document.mime_type",
		required => "recommended",
	},
	{
		target => "dc:identifier",
		source => sub {
			my( undef, $objects ) = @_;
			return $objects->{document}->get_url if defined $objects->{document};
			return undef;
		},
		required => "mandatory",
	},
	{
		target => "dc:language",
		source => sub {
			my( undef, $objects ) = @_;
			return  $objects->{eprint}->value( "rioxx2_language" ) if $objects->{eprint}->is_set( "rioxx2_language" );
			return $objects->{document}->value( "language" ) if defined $objects->{document} && $objects->{document}->is_set( "language" );
			return undef;
		},
		required => "mandatory",
	},
	{
		target => "dc:publisher",
		source => "eprint.publisher",
		required => "recommended",
	},
	{
		target => "dc:relation",
		source => "eprint.related_url_url",
		required => "optional",
	},
	{
		target => "dc:source",
		source => sub {
			my ( undef, $objects ) = @_;

			my $eprint = $objects->{eprint};
			my $type = $eprint->get_type;

			return $eprint->value( "issn" ) if ( $type eq "article" || $type eq "conference_item" ) && $eprint->is_set( "issn" );
			return $eprint->value( "publication" ) if $type eq "article" && $eprint->is_set( "pubication" );
			return $eprint->value( "isbn" ) if ( $type eq "book_section" || $type eq "conference_item" ) && $eprint->is_set( "isbn" );
			return $eprint->value( "book_title" ) if $type eq "book_section" && $eprint->is_set( "book_title" );
			return $eprint->value( "event_title" ) if $type eq "conference_item" && $eprint->is_set( "event_title" );

			return undef;
			
		},
		required => "mandatory", # TODO only mandatory for article, book_section, conference_item
	},
	{
		target => "dc:subject",
		source => "eprint.subjects",
		required => "recommended",
	},
	{
		target => "dc:title",
		source => "eprint.title",
		required => "mandatory",
	},
	{
		target => "dcterms:dateAccepted",
		source => "eprint.rioxx2_dateAccepted",
		required => "mandatory",
	},
	{
		target => "free_to_read",
		source => sub {
			my( undef, $objects ) = @_;
			return $objects->{eprint}->value( "rioxx2_free_to_read" ) if $objects->{eprint}->is_set( "rioxx2_free_to_read" );
			return unless defined $objects->{document};
			return { free_to_read => 1 } if $objects->{document}->is_set( "security" ) && $objects->{document}->value( "security" ) eq "public";
			return { free_to_read => 1, start_date => $objects->{document}->value( "date_embargo" ) } if $objects->{document}->is_set( "date_embargo" );
			return undef;
		},
		required => "optional",
	},
	{
		target => "license_ref",
		source => "eprint.rioxx2_license_ref", # TODO document.license + document.date_embargo
		required => "mandatory",
	},
	{
		target => "rioxxterms:apc",
		source => "eprint.rioxx2_apc",
		required => "optional",
	},
	{
		target => "rioxxterms:author",
		source => "eprint.creators", # TODO corp_creators
		required => "mandatory",
	},
	{
		target => "rioxxterms:contributor",
		source => "eprint.editors", # TODO contributors
		required => "optional",
	},
	{
		target => "rioxxterms:project",
		source => sub {
			my( undef, $objects ) = @_;

			return $objects->{eprint}->value( "rioxx2_project" ) if $objects->{eprint}->is_set( "rioxx2_project" );

			return unless $objects->{eprint}->is_set( "funders" ) && $objects->{eprint}->is_set( "projects" );

			my @projects = @{ $objects->{eprint}->value( "projects" ) };
			my @funders = @{ $objects->{eprint}->value( "funders" ) };

			while( scalar @projects < scalar @funders )
			{
				push @projects, $projects[$#projects];
			}

			my @value;
			for( my $i = 0; $i < scalar @projects; $i++ )
			{
				push @value, {
					project => $projects[$i],
					funder_name => ( $i > $#funders ? $funders[$#funders] : $funders[$i] ),
				};
			}
			return \@value;
		},
		required => "mandatory",
	},
	{
		target => "rioxxterms:publication_date",
		source => sub {
			my( undef, $objects ) = @_;
			return $objects->{eprint}->value( "rioxx2_publication_date" ) if $objects->{eprint}->is_set( "rioxx2_publication_date" );
			return $objects->{eprint}->value( "date" ) if $objects->{eprint}->is_set( "date" )
				&& ( !$objects->{eprint}->is_set( "date_type" ) || $objects->{eprint}->value( "date_type" ) eq "published" );
			return undef;
		},
		required => "optional",
	},
	{
		target => "rioxxterms:type",
		source => sub {
			my( $plugin, $objects ) = @_;
			return $objects->{eprint}->value( "rioxx2_type" ) if $objects->{eprint}->is_set( "rioxx2_type" );
			return $plugin->{repository}->config( "rioxx2", "type_map", $objects->{eprint}->get_type ) || "other";
		},
		required => "mandatory",
	},
	{
		target => "rioxxterms:version",
		source => sub {
			my( $plugin, $objects ) = @_;
			return $objects->{eprint}->value( "rioxx2_version" ) if $objects->{eprint}->is_set( "rioxx2_version" );
			my $content = defined $objects->{document} ? $objects->{document}->value( "content" ) : "";
			return $plugin->{repository}->config( "rioxx2", "content_map", $content ) || "NA";
		},
		required => "mandatory",
	},
	{
		target => "rioxxterms:version_of_record",
		source => sub {
			my( undef, $objects ) = @_;
			return $objects->{eprint}->value( "doi" ) if $objects->{eprint}->exists_and_set( 'doi' );
			return $objects->{eprint}->value( 'id_number' ) if  $objects->{eprint}->is_set ( 'id_number' );
			return undef;
		},
		required => "recommended",
	},
);

for( @rioxx2_fields )
{
	next if defined $_->{validate};
	next if $_->{required} ne "mandatory";
	$_->{validate} = "required";
}

$c->{rioxx2}->{field_lookup} = { map { $_->{target} =~ /^(.*:)?(.*)$/; "rioxx2_$2" => $_ } @rioxx2_fields };

$c->{reports}->{"rioxx2"}->{fields} = [ map { $_->{target} } @rioxx2_fields ];
$c->{reports}->{"rioxx2"}->{mappings} = { map { $_->{target} => $_->{source} } @rioxx2_fields };
$c->{reports}->{"rioxx2"}->{defaults} = { map { $_->{target} => $_->{default} } @rioxx2_fields };
$c->{reports}->{"rioxx2"}->{validate} = { map { $_->{target} => $_->{validate} } @rioxx2_fields };

$c->{reports}->{"rioxx2-articles"}->{fields} = [ map { $_->{target} } @rioxx2_fields ];
$c->{reports}->{"rioxx2-articles"}->{mappings} = { map { $_->{target} => $_->{source} } @rioxx2_fields };
$c->{reports}->{"rioxx2-articles"}->{validate} = { map { $_->{target} => $_->{validate} } @rioxx2_fields };
