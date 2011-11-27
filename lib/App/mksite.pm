package App::mksite;

use strict;
use warnings;

use Exporter 'import';

use File::Find;
use Text::Markdown qw(markdown);
use YAML qw(LoadFile);
use Template::Toolkit::Simple;
use Cwd;

use lib 'mksite';
use App::mksite::DebugServer;

sub process_page {
	return unless -f;
	print "File: $_\n";
	my $doc      = LoadFile $_;
	my $contents = $doc->{contents};
	$contents = markdown $contents if $doc->{format} eq 'markdown';
	$_ =~ s/(\S)\.yml/$1/x;

	my $cwd   = cwd;
	my $final = tt->absolute(1)->render(
		"$cwd/templates/$doc->{template}.tt",
		{
			title   => $doc->{name},
			content => $contents,
			styles  => $doc->{styles},
			scripts => $doc->{scripts},
		}
	);

	my $outname = $doc->{slug} // $_;
	my $res = open my $out, '>', "$cwd/output/$outname.html";
	print $out $final;
	close $out;
	return;
}

sub mksite {
	my ( $config, $debug ) = @_;
	find( \&process_page, "src/" );
    system("cd","-r","static","output");

	if ( not defined $debug or $debug ne 'debug' ) {
        system("rsync","-r","-t","-v","output/",$config->{dest});
	} else {
        my $server = mksite::DebugServer->new;
		$server->run();
	}
    return;
}

our @EXPORT_OK = qw( mksite );

1;

# ABSTRACT: turns baubles into trinkets
