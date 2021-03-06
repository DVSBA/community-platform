package DDGC::User::Page;

use Moose;
use DDGC::User::Page::Field;
use URI;

# default type = text

my @attributes = (

############################ About

	headline => 'Userpage headline, instead of username' => {},
	about => 'About you' => { type => 'textarea' },
	whyddg => 'Why DuckDuckGo?' => { type => 'textarea' },
	realname => 'If you want to make your real name public, do it here:' => {},
	country => 'Living in country' => { type => 'country' },
	city => 'Living in city/town' => {},
	birth_country => 'Born in country' => { type => 'country' },

########################### Links

	email => 'Your public email' => { type => 'email' },
	web => 'Your website' => { type => 'url' },
	twitter => 'Your Twitter username' => {
		type => 'remote',
		validators => [sub {
			m/^\w{1,15}$/ ? () : ("Invalid Twitter username")
		}],
		params => {
			url_prefix => 'https://twitter.com/',
			icon => 'twitter',
			user_prefix => '@',
		},
	},
	facebook => 'Your Facebook profile url' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.\/]+$/ ? () : ("Invalid facebook url")
		}],
		params => {
			url_prefix => 'https://facebook.com/',
			icon => 'facebook',
			user => 'Facebook profile',
		},
	},
	github => 'Your GitHub username' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid GitHub username")
		}],
		params => {
			url_prefix => 'https://github.com/',
			icon => 'github',
		},
	},
	reddit => 'Your reddit username' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid reddit username")
		}],
		params => {
			url_prefix => 'http://www.reddit.com/user/',
			user_suffix => ' on reddit',
		},
	},
	deviantart => 'Your deviantART username' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid deviantART username")
		}],
		params => {
			url_prefix => 'http://',
			url_suffix => '.deviantart.com/',
			user_suffix => ' on deviantART',
		},
	},
	imgur => 'Your imgur username' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid imgur username")
		}],
		params => {
			url_prefix => 'http://',
			url_suffix => '.imgur.com/',
			user_suffix => ' on imgur',
		},
	},
	youtube => 'Your YouTube channel' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid YouTube username")
		}],
		params => {
			url_prefix => 'https://youtube.com/user/',
			user_suffix => ' on YouTube',
		},
	},
	flickr => 'Your flickr username' => {
		type => 'remote',
		validators => [sub {
			m/^[\w\.]+$/ ? () : ("Invalid flickr username")
		}],
		params => {
			url_prefix => 'http://www.flickr.com/photos/',
			user_suffix => ' on flickr',
		},
	},

############ Other widgets

	languages => 'Show your languages and translation counts public?' => { type => 'noyes',
		view => 'languages',
		export => sub {
			my ( $self ) = @_;
			return { map { $_->language->locale => $_->grade } $self->page->user->user_languages };
		},
	},
);

has data => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	default => sub {{}},
);

sub export {
	my ( $self ) = @_;
	my %export;
	my %errors;
	for (keys %{$self->attribute_fields}) {
		$export{$_} = $self->field($_)->export_value;
		$errors{$_} = $self->field($_)->errors if $self->field($_)->error_count;
	}
	$export{errors} = \%errors if %errors;
	return \%export;
}

has user => (
	is => 'ro',
	isa => 'DDGC::User',
	required => 1,
);

has attribute_fields => (
	is => 'ro',
	isa => 'HashRef[DDGC::User::Page::Field]',
	lazy_build => 1,
);

sub field {
	my ( $self, $name ) = @_;
	return $self->attribute_fields->{$name};
}

sub _build_attribute_fields {
	my ( $self ) = @_;
	my %fields;
	my @attrs = @attributes;
	while (@attrs) {
		my $name = shift @attrs;
		my $desc = shift @attrs;
		my %extra = %{shift @attrs};
		my $value = defined $self->data->{$name}
			? $self->data->{$name}
			: '';
		$fields{$name} = DDGC::User::Page::Field->new(
			page => $self,
			name => $name,
			description => $desc,
			value => $value,
			%extra,
		);
	}
	return \%fields;
}

sub update_data {
	my ( $self, $data ) = @_;
	my $error_count;
	for (keys %{$data}) {
		my $key = $_;
		my $value = $data->{$_};
		my $field = $self->field($_);
		if ($field) {
			$field->value($value);
			if ($field->error_count) {
				$error_count += $field->error_count;
			} else {
				$self->data->{$key} = $value;
			}
		}
	}
	return $error_count;
}

sub new_from_user {
	my ( $class, $user ) = @_;
	my $data = defined $user->data->{userpage}
		? $user->data->{userpage}
		: {};
	return $class->new(
		data => $data,
		user => $user,
	);
}

sub update {
	my ( $self ) = @_;
	my $data = $self->user->data;
	$data->{userpage} = $self->data;
	$self->user->data($data);
	$self->user->update;
}

sub has_value_for {
	my ( $self, @fields ) = @_;
	for (@fields) {
		return 1 if $self->field($_)->value;
	}
	return 0;
}

1;