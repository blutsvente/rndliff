###############################################################################
#  RCSId: $Id: liff.pm,v 1.3 2006/09/12 15:33:52 lutscher Exp $
###############################################################################
#
#  Related Files :  rndliff.pl
#
#  Author(s)     :  Thorsten Dworzak
#  Email         :  ttlemail69-github@yahoo.com
#
#  Creation Date :  03.08.2005
#
#  Contents      :  Class for accessing meaning_of_liff.txt (Perl OO excercise)
#
###############################################################################

package liff;

#------------------------------------------------------------------------------
# Used packages
#------------------------------------------------------------------------------
use strict;
use Data::Dumper;
use File::stat;

#------------------------------------------------------------------------------
# Class members
#------------------------------------------------------------------------------
# <none>

#------------------------------------------------------------------------------
# Constructor
# returns a hash reference to the data members of this class
# package; does NOT call the subclass constructors.
# Input: hash for setting member variables (optional)
#------------------------------------------------------------------------------
sub new {
	my $this = shift;
	my %params = @_;

	# data member default values
	my $ref_member  = {
					   'filename' => "./meaning_of_liff.txt",
					   'data'     => {},
					   'n_keys'   => 0  # number of keys in data hash
					  };

	# init data members w/ parameters from constructor call
	foreach (keys %params) {
		$ref_member->{$_} = $params{$_};
	};

	$this = bless $ref_member, $this;

	# read data
	$this->init_data();

	# init random generator
	srand();

	return $this;
};

#------------------------------------------------------------------------------
# Methods
# First parameter passed to method is object reference ($this) if the method
# is called in <object> -> <method>() fashion.
#------------------------------------------------------------------------------

# read the text file or the cached data, depending on which one is newer
sub init_data {
	my $this = shift;

	my ($href, $cmtime);
	my $cachefile = $this->{'filename'};
	$cachefile =~ s/txt$/cache/;
	my $cache_is_stale = 0;

	# modification time of cache file
	my $st = stat($cachefile);
	if ($st) {
		$cmtime = $st->mtime;
	} else {
		$cmtime = 0;
	};

	# modification time of original file
	my $filename = $this->{'filename'};
	my $fst = stat($filename) or die "ERROR: could not stat file \'$filename\'\n";
	if ($fst->mtime > $cmtime) {
		$cache_is_stale = 1;
	};

	if ($cache_is_stale) {
	  read_original_file:
		open(SHANDLE, $filename) or die "could not open file \'$filename\' for reading\n";
		my %hdata;
		my $entry;
		my $key;
		while(<SHANDLE>) {
			next if $_ =~ m/^\s*\n/;
			if ($_ =~ /^(([A-Z\-]{2,}\s?)+)/) {
				if ($key) {
					$hdata{$key} = $entry;
				};
				$entry = $';
				$key = $2;
			} else {
				$entry .= $_;
			};
		};
		close (SHANDLE);

		# save data to cache
		my $dump = Data::Dumper->new([\%hdata]);
		open(CHANDLE, ">$cachefile") or die "ERROR: could not open file \'$cachefile\' for writing\n";
		print CHANDLE $dump->Dump;
		close(CHANDLE);
		%{$this->{'data'}} = %hdata;
		%hdata = ();
	} else {
		# read data from cache file
		open(CHANDLE, $cachefile) or die "ERROR: could not open file \'$cachefile\' for reading\n";
		local ($/) = undef;
		my $VAR1;
		eval(<CHANDLE>);
		close CHANDLE;
		# check if the data is valid
		if (not defined $VAR1 or scalar(keys %$VAR1) < 2) {
			print STDERR "WARNING: bad cache file\n";
			goto read_original_file;
		};
		%{$this->{'data'}} = %$VAR1;
	};
	$this->{'n_keys'} = scalar(%{$this->{'data'}});
};

# return a random entry from meaning of liff as a string
sub get_rnd_entry {
	my $this = shift;
	my $rand = rand($this->{'n_keys'});
	my $key = (keys(%{$this->{'data'}}))[$rand];
	return join(" ", $key, $this->{'data'}->{$key});
};

# display method for debugging (every class should have one)
sub display {
	my $this = shift;
	my $dump  = Data::Dumper->new([$this]);
	$dump->Sortkeys(1);
	print $dump->Dump;
};

1;
