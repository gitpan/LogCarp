use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'         => 'CGI::LogCarp',
	'DISTNAME'     => 'CGI::LogCarp',
	'VERSION_FROM' => 'CGI/LogCarp.pm', # Finds $VERSION
    'dist'         => { 'COMPRESS' => 'gzip', 'SUFFIX' => '.gz' }
);
