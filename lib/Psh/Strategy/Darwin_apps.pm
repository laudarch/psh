package Psh::Strategy::Darwin_apps;


=item * C<darwin_apps>

This strategy will search for Mac OS X/Darwin .app bundles and
execute them using the system 'open' command'

=cut

require Psh::Strategy;

use vars qw(@ISA);
@ISA=('Psh::Strategy');

sub consumes {
	return Psh::Strategy::CONSUME_TOKENS;
}

sub runs_before {
	return qw(eval);
}

sub _recursive_search {
	my $file= shift;
	my $dir= shift;
	my $lvl= shift;

	opendir( DIR, $dir) || return ();
	my @files= readdir(DIR);
	closedir( DIR);
	my @result= map { File::Spec->catdir($dir,$_) }
	                     grep { /^$file\.app$/i } @files;
	return $result[0] if @result;
	if ($lvl<10) {
		foreach my $tmp (@files) {
			my $tmpdir= File::Spec->catdir($dir,$tmp);
			next if ! -d $tmpdir || !File::Spec->no_upwards($tmp);
			next if index($tmpdir,'.')>=0;
			push @result, _recursive_search($file, $tmpdir, $lvl+1);
		}
	}
	return $result[0] if @result;
}


sub applies {
	my $com= @{$_[2]}->[0];
	my $path=$ENV{APP_PATH}||'/Applications';
	my @path= split /:/, $path;
	my $executable;
	foreach (@path) {
		$executable= _recursive_search($com,$_,1);
		last if $executable;
	}
	return $executable if defined $executable;
	return '';
}

sub execute {
	my $executable= $_[3];
	return (undef, undef, undef, CORE::system("/usr/bin/open $executable"));
}

1;