#!/usr/local/bin/perl -w
#
# SCCS INFO: @(#) LogCarp.pm 1.04 98/01/06
# $Id: LogCarp.pm,v 1.04 1998/01/06 20:52:19 mak Exp $
#
# Copyright (C) 1997,1998 Michael King (mike808@mo.net)
# Fenton, MO USA.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

LogCarp - Error, log and debug streams, httpd style format

LogCarp redefines the STDERR stream and the defines the STDBUG and STDLOG
streams in such a way that all messages are formatted similar to an HTTPD
error log.
Methods are defined for directing messages to the STDBUG and STDLOG streams.
Each stream can be directed to its own location independent of the others.

=head1 SYNOPSIS

    use LogCarp;

    print "LogCarp version: ", LogCarp::VERSION;
    DEBUGLEVEL 2;

    croak "We're outta here!";
    confess "It was my fault: $!";
    carp "It was your fault!";
    warn "I'm confused";
    die "I'm dying.\n";


    debug "Just for debugging: somevar=", $somevar, "\n";
    logmsg "Just for logging: We're here.\n";
    trace "detail=", $detail, "\n";

    carpout \*ERRFILE;
    debugout \*DEBUGFILE;
    logmsgout \*LOGFILE;

    is_STDOUT \*ERRFILE
    is_STDERR \*LOGFILE
    is_STDBUG \*LOGFILE
    is_STDLOG \*ERRFILE

=head1 DESCRIPTION

LogCarp.pm is a Perl5 package defining methods for directing
the existing STDERR stream as well as creating and directing
two new messaging streams, STDBUG and STDLOG.

Their use was intended mainly for a CGI development environment,
or where separate facilities for errors, logging, and debugging
output are needed.

This is because CGI scripts have a nasty habit of leaving warning messages
in the error logs that are neither time stamped nor fully identified.
Tracking down the script that caused the error is a pain. This fixes that.
Replace the usual

    use Carp;

with

    use LogCarp;

And the standard C<warn()>, C<die()>, C<croak()>, C<confess()>
and C<carp()> calls will automagically be replaced with methods
that write out nicely time-, process-, program-, and stream-stamped messages
to the STDERR, STDLOG, and STDBUG streams.

A new method to generate messages on the new STDLOG stream
is C<logmsg()>. Calls to C<logmsg()> will write out the same nicely
time-, process-, program-, and stream-stamped messages
described above to both the STDLOG and the STDBUG streams.

Messages on multiple streams directed to the same location
do not receive multiple copies.

New methods to generate messages on the new STDBUG stream
are C<debug()> and C<trace()>.

In addition, the process number (represented below as $$)
and the stream on which the message appears is displayed
to disambiguate multiple simultaneous executions
as well as multiple streams directed to the same location.

For example:

    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: I'm confused at test.pl line 3.
    [Mon Sep 15 09:04:55 1997] $$ test.pl BUG: answer=42.
    [Mon Sep 15 09:04:55 1997] $$ test.pl LOG: I did something.
    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: Got a warning: Permission denied.
    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: I'm dying.

=head1 REDIRECTING ERROR MESSAGES

By default, error messages are sent to STDERR. Most HTTPD servers
direct STDERR to the server's error log. Some applications may wish
to keep private error logs, distinct from the server's error log, or
they may wish to direct error messages to STDOUT so that the browser
will receive them (for debugging, not for public consumption).

The C<carpout()> method is provided for this purpose.

For CGI programs that need to send something to the HTTPD server's
real error log, the original STDERR stream has not been closed,
it has been saved as _STDERR. The reason for this is twofold.

The first is that your CGI application might really need to write something
to the server's error log, unrelated to your own error log. To do so,
simply write directly to the _STDERR stream.

The second is that some servers, when dealing with CGI scripts,
close their connection to the browser when the script closes
either STDOUT or STDERR.

Saving the program's initial STDERR in _STDERR is used
to prevent this from happening prematurely.

Do not manipulate the _STDERR filehandle in any other way other than writing to it.
For CGI applications, the C<serverwarn()> method formats and sends your message
to the HTTPD error log (on the _STDERR stream).

=head1 REDIRECTING LOG MESSAGES

A new stream, STDLOG, has been defined for log messages.
By default, STDLOG is routed to STDERR. Most HTTPD servers
direct STDERR (and thus the default STDLOG also)
to the server's error log. Some applications may wish
to keep private activity logs, distinct from the server's log, or
they may wish to direct log messages to STDOUT so that the browser
will receive them (for debugging, not for public consumption).

The C<logmsgout()> method is provided for this purpose.

=head1 REDIRECTING DEBUG MESSAGES

A new stream, STDBUG, has been defined for debugging messages.
Since this stream is for producing debugging output,
the default STDBUG is routed to STDOUT. Some applications may wish
to keep private debug logs, distinct from the application output, or
CGI applications may wish to leave debug messages directed to STDOUT
so that the browser will receive them (only when debugging).
Your program may also control the output by manipulating DEBUGLEVEL
in the application.

The C<debugout()> method is provided for this purpose.

=head1 REDIRECTING MESSAGES IN GENERAL

Each of these methods, C<carpout()>, C<logmsgout()>, and C<debugout()>,
requires one argument, which should be a reference to an open filehandle for writing.
It should be called in a C<BEGIN> block at the top of the application so that
compiler errors will be caught. Example:

    BEGIN {
    use LogCarp;
    open \*LOG, ">>/usr/local/cgi-logs/mycgi-log"
        or die "Unable to open mycgi-log: $!\n";
    carpout \*LOG;
    }

NOTE: C<carpout()> does handle file locking on systems that support flock
so multiple simultaneous CGIs are not an issue.

If you want to send errors to the browser, give C<carpout()> a reference
to STDOUT:

   BEGIN {
     use LogCarp;
     carpout \*STDOUT;
   }

If you do this, be sure to send a Content-Type header immediately --
perhaps even within the BEGIN block -- to prevent server errors.

You can pass filehandles to C<carpout()> in a variety of ways. The "correct"
way according to Tom Christiansen is to pass a reference to a filehandle
GLOB:

    carpout \*LOG;

This looks weird to mere mortals however, so the following syntaxes are
accepted as well:

    carpout(LOG);
    carpout(\LOG);
    carpout('LOG');
    carpout(\'LOG');
    carpout(main::LOG);
    carpout('main::LOG');
    carpout(\'main::LOG');

    ... and so on

Use of C<carpout()> is not great for performance, so it is recommended
for debugging purposes or for moderate-use applications. A future
version of this module may delay redirecting STDERR until one of the
LogCarp methods is called to prevent the performance hit.

=head1 EXPORTED PACKAGE METHODS

The following methods are for generating a message on the respective stream:

    The STDERR stream: warn() and die()
    The STDLOG stream: logmsg()
    The STDBUG stream: debug() and trace()

The following methods are for generating a message on the respective stream,
but will indicate the message location from the caller's perspective.
See the standard B<Carp.pm> module for details.

    The STDERR stream: carp(), croak() and confess()

The following methods are for manipulating the respective stream:

    The STDERR stream: carpout()
    The STDLOG stream: logmsgout()
    The STDBUG stream: debugout()

The following methods are for manipulating the amount (or level)
of output filtering on the respective stream:

    The STDBUG stream: DEBUGLEVEL()
    The STDLOG stream: LOGLEVEL()

=head1 INTERNAL PACKAGE METHODS

The following methods are for comparing a filehandle to the respective stream:

    is_STDOUT()
    is_STDERR()
    is_STDBUG()
    is_STDLOG()

Each is explained in its own section below.

=head1 EXPORTED PACKAGE VARIABLES

No variables are exported into the caller's namespace.

=head1 INTERNAL PACKAGE VARIABLES

=over

=item $DEBUGLEVEL

A number indicating the level of debugging output that is to occur.
At each increase in level, additional debugging output is allowed.

Currently three levels are defined:
    0 - No messages are output on the STDBUG stream.
    1 - debug() messages are output on the STDBUG stream.
    2 - debug() and trace() messages are output on the STDBUG stream.

It is recommended to use the DEBUGLEVEL method to get/set this value.

=item $LOGLEVEL

A number indicating the level of logging output that is to occur.
At each increase in level, additional logging output is allowed.

Currently two levels are defined:
    0 - No messages are output on the STDLOG stream.
    1 - logmsg() messages are output on the STDLOG stream.

It is recommended to use the LOGLEVEL method to get/set this value.

=back

=head1 RETURN VALUE

The value returned by executing the package is 1 (or true).

=head1 ENVIRONMENT

=head1 FILES

=head1 ERRORS

=head1 WARNINGS

carpout(), debugout(), and logmsgout() do not handle file locking for you at this point.

=head1 DIAGNOSTICS

=head1 BUGS

Check out what's left in the TODO file.

=head1 RESTRICTIONS

=head1 CPAN DEPENDENCIES

=head1 LOCAL DEPENDENCIES

=head1 SEE ALSO

Carp, CGI::Carp

=head1 NOTES

=head1 ACKNOWLEDGEMENTS

 Based heavily on CGI::Carp by Lincoln D. Stein (lstein@genome.wi.mit.edu).

=head1 AUTHORZ<>(S)

 mak - Michael King (mike808@mo.net)

=head1 HISTORY

 LogCarp.pm
 v1.01 09/15/97 09:04:00 mak
 v1.02 01/04/98 19:03:25 mak
 v1.03 01/04/98 19:03:25 mak
 v1.04 01/06/98 20:52:19 mak

=head1 MODIFICATIONS

=head1 COPYRIGHT

 Copyright (C) 1997,1998 Michael King (mike808@mo.net)
 Fenton, MO USA.

 This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This module is copyright (c) 1997,1998 by Michael King (mike808@mo.net) and is
made available to the Perl public under terms of the Artistic License used to
cover Perl itself. See the file Artistic in the distribution  of Perl 5.002 or
later for details of copy and distribution terms.

=head1 AVAILABILITY

The latest version of this module is likely to be available from:

 http://walden.mo.net/~mike808/LogCarp

The best place to discuss this code is via email with the author.

=cut

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Play nice
require 5.004;
use strict;

# The package name
package LogCarp;

# Define external interface
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
require Exporter;
@ISA = qw( Exporter );

# Always exported into callers namespace
@EXPORT = qw(
    confess croak carp
    logmsg trace debug
    carpout logmsgout debugout
    DEBUGLEVEL
    LOGLEVEL
);

# Externally visible if specified
@EXPORT_OK = qw(
    is_STDOUT
    is_STDERR
    is_STDBUG
    is_STDLOG
);

# Standard packages
use Carp;
use FileHandle;

# CPAN packages

# Local packages

# Package Version
$VERSION = "1.04";
sub VERSION () { $VERSION; };

# Constants

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Compile-time initialization code
BEGIN {
    # Save the real STDERR
    open \*main::_STDERR, ">&STDERR";

    # Default STDLOG and STDBUG
    open \*main::STDBUG,">&STDOUT";
    open \*main::STDLOG,">&STDERR";

    # Initialize the debug level (OFF)
    $LogCarp::DEBUGLEVEL = 0;

    # Initialize the log level (OFF)
    $LogCarp::LOGLEVEL = 0;
}

# Grab Perl's signal handlers
# Note: Do we want to stack ours on top of whatever was there?
$main::SIG{'__WARN__'} = 'LogCarp::warn';
$main::SIG{'__DIE__'}  = 'LogCarp::die';

# Take over top-level definitions
*main::logmsg = *main::logmsg = \&LogCarp::logmsg;
*main::debug  = *main::debug  = \&LogCarp::debug;
*main::trace  = *main::trace  = \&LogCarp::trace;

# Take over carp(), croak(), and confess()
#
# Avoid "subroutine redefined" warnings with this popular hack
# mak - BTW, this fixes a problem when you pass Carp::croak and Carp::carp
# a list of more than one parameter( shortmess uses $_[0] and not @_ );
{
    local $^W=0;
eval <<EOF;
    sub confess { LogCarp::die(  Carp::longmess,  join("",@_) ); }
    sub croak   { LogCarp::die(  Carp::shortmess, join("",@_) ); }
    sub carp    { LogCarp::warn( Carp::shortmess, join("",@_) ); }
EOF
}

# Predeclare and prototype our private methods
sub stamp ($);
sub lock (*);
sub unlock (*);
sub streams_are_equal (**);
sub is_STDOUT (*);
sub is_STDERR (*);
sub is_STDLOG (*);
sub is_STDBUG (*);
sub realdie (@);
sub realwarn (@);
sub realbug (@);
sub reallog (@);

# These are private aliases for various "levels"
# Alter these to your language/dialect if you'd like
my $NO    = join "|", qw( no  false off );
my $YES   = join "|", qw( yes true  on  );
my $TRACE = join "|", qw( trace tracing );

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head1 PACKAGE PUBLIC METHODS

=head2 DEBUGLEVEL $LEVEL

DEBUGLEVEL is a normal get/set method.

When the scalar argument LEVEL is present, the DEBUGLEVEL will be set to LEVEL.
LEVEL is expected to be numeric, with the following case-insensitive
character-valued translations:

 NO,  FALSE, and OFF all equate to a value of 0 (ZERO).
 YES, TRUE,  and ON  all equate to a value of 1 (ONE).
 TRACE or TRACING equate to a value of 2 (TWO).

 Values in scientific notation equate to their numeric equivalent.

NOTE:

    All other character values of LEVEL equate to 0 (ZERO). This
will have the effect of turning off debug output.

After this translation to a numeric value is performed,
the DEBUGLEVEL is set to LEVEL.

Whenever the DEBUGLEVEL is set to a non-zero value (i.e. ON or TRACE),
the LOGLEVEL will be also set to 1 (ONE).

The value of DEBUGLEVEL is then returned to the caller,
whether or not LEVEL is present.

=cut

sub DEBUGLEVEL (;$)
{
    my ($value) = shift;
    if (defined $value)
    {
        # Allow the usual non-numeric values
        $value = 0 if $value =~ m/^($NO)$/i;
        $value = 1 if $value =~ m/^($YES)$/i;
        $value = 2 if $value =~ m/^($TRACE)$/i;

        # Coerce to numeric - note scientific notation is OK
        $LogCarp::DEBUGLEVEL = 0 + $value;

        # Also turn on logging if we are debugging
        LOGLEVEL(1) if ($LogCarp::DEBUGLEVEL and not $LogCarp::LOGLEVEL);
    }
    $LogCarp::DEBUGLEVEL;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 LOGLEVEL $LEVEL

LOGLEVEL is a normal get/set method.

When the scalar argument LEVEL is present, the LOGLEVEL will be set to LEVEL.
LEVEL is expected to be numeric, with the following case-insensitive
character-valued translations:

 NO,  FALSE, and OFF all equate to a value of 0 (ZERO).
 YES, TRUE,  and ON  all equate to a value of 1 (ONE).

 Values in scientific notation equate to their numeric equivalent.

NOTE:

    All other character values of LEVEL equate to 0 (ZERO). This
will have the effect of turning off log output.

After this translation to a numeric value is performed,
the LOGLEVEL is set to LEVEL.

The value of LOGLEVEL is then returned to the caller,
whether or not LEVEL is present.

=cut

sub LOGLEVEL (;$)
{
    my ($value) = shift;
    if (defined $value)
    {
        # Allow the usual non-numeric values
        $value = 0 if $value =~ m/^($NO)$/i;
        $value = 1 if $value =~ m/^($YES)$/i;

        # Coerce to numeric - note scientific notation is OK
        $LogCarp::LOGLEVEL = 0 + $value;
    }
    $LogCarp::LOGLEVEL;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 warn @message

This method is a replacement for Perl's builtin C<warn()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub warn (@)
{
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "ERR";
    $message =~ s/^/$stamp/gm;

    my $stdlog = \*main::STDLOG;
    realbug($message) unless is_STDERR \*main::STDBUG;
    reallog($message) unless (
        is_STDERR $stdlog
        or
        is_STDBUG $stdlog
    );
    realwarn $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 die @message

This method is a replacement for Perl's builtin C<die()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub die (@)
{
    my $message = join "", @_; # Flatten the list
    my $time = scalar localtime;
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "ERR";
    $message =~ s/^/$stamp/gm;

    my $stdlog = \*main::STDLOG;
    realbug($message) unless is_STDERR \*main::STDBUG;
    reallog($message) unless (
        is_STDERR $stdlog
        or
        is_STDBUG $stdlog
    );
    realdie $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# These were replaced a while back.

=head2 carp @message

This method is a replacement for C<Carp::carp()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=head2 croak @message

This method is a replacement for C<Carp::croak()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=head2 confess @message

This method is a replacement for C<Carp::confess()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 logmsg @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDLOG and STDBUG streams.

=cut

sub logmsg (@)
{
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "LOG";
    $message =~ s/^/$stamp/gm;

    realbug($message) unless is_STDLOG \*main::STDBUG;
    reallog $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 debug @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDBUG stream when DEBUGLEVEL > 0.

=cut

sub debug (@)
{
    return unless LogCarp::DEBUGLEVEL() > 0;
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "BUG";
    $message =~ s/^/$stamp/gm;

    realbug $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 trace @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDBUG stream
when DEBUGLEVEL is greater than one.

=cut

sub trace (@)
{
    return unless LogCarp::DEBUGLEVEL() > 1;
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "TRC";
    $message =~ s/^/$stamp/gm;

    realbug($message);
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 carpout FILEHANDLE

A method to redirect the STDERR stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on REDIRECTING ERROR MESSAGES
and the section on REDIRECTING MESSAGES IN GENERAL.

=cut

sub carpout (*)
{
    my ($fh) = shift;
    $fh = $$fh if ref $fh; # Dereference if needed
    my ($no) = fileno $fh;
    unless (defined $no)
    {
        my ($package) = caller;
        my ($handle) = ($fh =~ /[':]/) ? $fh : "$package\:\:$fh";
        $no = fileno $handle;
    }
    die "Invalid filehandle $fh\n" unless $no;

    open \*main::STDERR, ">&$no"
        or die "Unable to redirect STDERR: $!\n";
    autoflush main::STDERR;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 logmsgout FILEHANDLE

A method to redirect the STDLOG stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on REDIRECTING ERROR MESSAGES
and the section on REDIRECTING MESSAGES IN GENERAL.

=cut

sub logmsgout (*)
{
    my ($fh) = shift;
    $fh = $$fh if ref $fh; # Dereference if needed
    my ($no) = fileno $fh;
    unless (defined $no)
    {
        my ($package) = caller;
        my ($handle) = ($fh =~ /[':]/) ? $fh : "$package\:\:$fh";
        $no = fileno $handle;
    }
    die "Invalid filehandle $fh\n" unless $no;

    open \*main::STDLOG, ">&$no"
        or die "Unable to redirect STDLOG: $!\n";

    autoflush main::STDLOG;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 debugout FILEHANDLE

A method to redirect the STDBUG stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on REDIRECTING ERROR MESSAGES
and the section on REDIRECTING MESSAGES IN GENERAL.

=cut

sub debugout (*)
{
    my ($fh) = shift;
    $fh = $$fh if ref $fh; # Dereference if needed
    my ($no) = fileno $fh;
    unless (defined $no)
    {
        my ($package) = caller;
        my ($handle) = ($fh =~ /[':]/) ? $fh : "$package\:\:$fh";
        $no = fileno $handle;
    }
    die "Invalid filehandle $fh\n" unless $no;

    open \*main::STDBUG, ">&$no"
        or die "Unable to redirect STDBUG: $!\n";
    autoflush main::STDBUG;
}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 is_STDOUT FILEHANDLE

This method compares FILEHANDLE with the STDOUT stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDOUT (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDOUT;
}

=head2 is_STDERR FILEHANDLE

This method compares FILEHANDLE with the STDERR stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDERR (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDERR;
}

=head2 is_STDBUG FILEHANDLE

This method compares FILEHANDLE with the STDBUG stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDBUG (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDBUG;
}

=head2 is_STDLOG FILEHANDLE

This method compares FILEHANDLE with the STDLOG stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDLOG (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDLOG;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head1 PRIVATE METHODS

=cut

# Locks are fine grained
# Do we need a higher level lock/unlock around a block of messages?
# e.g.: lock \*STDLOG; iterated_log_writes @lines; unlock \*STDLOG;
#
# These are the originals

=head2 realwarn @MESSAGE

This private method encapsulates Perl's underlying C<warn()> method,
actually producing the message on the STDERR stream.
Locking is performed to ensure exclusive access while appending.

This method is not exportable.

=cut

sub realwarn (@)
{
    lock   \*main::STDERR;
    warn @_;
    unlock \*main::STDERR;
}

=head2 realdie @MESSAGE

This private method encapsulates Perl's underlying C<die()> method,
actually producing the message on the STDERR stream and then terminating
execution.
Locking is performed to ensure exclusive access while appending.

This method is not exportable.

=cut

sub realdie (@)
{
    lock   \*main::STDERR;
    die @_;
}

# The OS *should* unlock the stream as the process ends, but ...
END { unlock \*main::STDERR; }

=head2 reallog @MESSAGE

This private method synthesizes an underlying C<logmsg()> method,
actually producing the message on the STDLOG stream.
Locking is performed to ensure exclusive access while appending.
The message will only be sent when LOGLEVEL is greater than zero.

This method is not exportable.

=cut

sub reallog (@)
{
    return unless LOGLEVEL > 0;
    lock    \*main::STDLOG;
    print { \*main::STDLOG } @_;
    unlock  \*main::STDLOG;
}

=head2 realbug @message

This private method synthesizes an underlying C<debug()> method,
actually producing the message on the STDBUG stream.
Locking is performed to ensure exclusive access while appending.
The message will only be sent when DEBUGLEVEL is greater than zero.

This method is not exportable.

=cut

sub realbug (@)
{
    return unless DEBUGLEVEL > 0;
    lock    \*main::STDBUG;
    print { \*main::STDBUG } @_;
    unlock  \*main::STDBUG;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 id $level

This private method returns the file, line, and basename
of the currently executing function.

This method is not exportable.

=cut

sub id ($)
{
    my ($level) = shift;
    my ($pack,$file,$line,$sub) = caller $level;
    my ($id) = $file =~ m|([^/]+)$|;
    return ($file,$line,$id);
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 stamp $stream_id

A private method to construct a normalized timestamp prefix for a message.

This method is not exportable.

=cut

sub stamp ($)
{
    my ($stream_id) = shift;
    my $time = scalar localtime;
    my $frame = 0;
    my ($id,$pkg,$file);
    do {
        $id = $file;
        ($pkg,$file) = caller $frame++;
    } until !$file;
    ($id) = $id =~ m|([^/]+)$|;
    return "[$time]" . sprintf("%6d",$$) . " $id $stream_id: ";
}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 streams_are_equal FILEHANDLE, FILEHANDLE

This private method compares two FILEHANDLE streams to each other
and returns the boolean result.

This method is not exportable.

Note: This function is probably not portable to non-Unix-based
operating systems (i.e. NT, VMS, etc.).

=cut

sub streams_are_equal (**)
{
    my ($fh1,$fh2) = (shift,shift);
    $fh1 = $$fh1 if ref $fh1; # Dereference if needed
    $fh2 = $$fh2 if ref $fh2; # Dereference if needed
    my ($device1,$inode1) = stat $fh1;
    my ($device2,$inode2) = stat $fh2;
    ( $device1 == $device2 and $inode1 == $inode2 );
}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 LOCK_SH, LOCK_EX, LOCK_NB, LOCK_UN

Some private methods encapsulating the implementation-defined
values for the OPERATION parameter of the Perl builtin C<flock()>,
based upon the operating system C<flock(2)> function.
See the manual page for C<flock(2)> for your system-specific values.

The as-defined-here values for the C<flock()> OPERATION parameter are:

    LOCK_SH = 1 - Shared lock
    LOCK_EX = 2 - Exclusive lock
    LOCK_NB = 4 - Non-blocking lock
    LOCK_UN = 8 - Unlock

NOTE: YMMV.

=cut

# Some flock-related globals for lock/unlock
sub LOCK_SH { 1; };
sub LOCK_EX { 2; };
sub LOCK_NB { 4; };
sub LOCK_UN { 8; };

=head2 SEEK_BOF, SEEK_CUR, SEEK_EOF

Some private methods encapsulating the implementation-defined
values for the WHENCE parameter of the Perl builtin C<seek()>,
based upon the operating system C<flock(2)> function.
See the manual page for C<flock(2)> for your system-specific values.

The as-defined-here values for the C<seek()> WHENCE parameter are:

    SEEK_BOF = 0 - Beginning of the file
    SEEK_CUR = 1 - Current location in the file
    SEEK_BOF = 2 - End of the file

NOTE: YMMV.

=cut

# Some seek-related globals for lock/unlock
sub SEEK_BOF { 0; };
sub SEEK_CUR { 1; };
sub SEEK_EOF { 2; };

=head2 lock FILEHANDLE

A private method that uses Perl's builtin C<flock()> and C<seek()>
to obtain an exclusive lock on the stream specified by FILEHANDLE.
A lock is only attempted on actual files that are writeable.

This method is not exportable.

=cut

sub lock (*)
{
    my ($fh) = shift;
    $fh = $$fh if ref $fh; # Dereference if needed
    return unless ( -f $fh and -w _ );
    flock $fh, LOCK_EX;
    # Just in case someone appended while we weren't looking...
    seek $fh, 0, SEEK_EOF;
}

=head2 unlock FILEHANDLE

A private method that uses Perl's builtin C<flock()>
to release any exclusive lock on the stream specified by FILEHANDLE.
An unlock is only attempted on actual files that are writeable.

This method is not exportable.

=cut

sub unlock (*)
{
    my ($fh) = shift;
    $fh = $$fh if ref $fh; # Dereference if needed
    return unless ( -f $fh and -w _ );
    flock $fh, LOCK_UN;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End of LogCarp.pm
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1;
