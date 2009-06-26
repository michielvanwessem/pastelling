#!/usr/bin/perl -w
#
# File:
# Purpose:  Pastes files to http://pastebin.slackadelic.com/
#           See ./pastelling.pl -h for more information
#
# Source File:  rafb.pl (http://pragma.homeip.net/stuff/code/rafb.pl)
#            :          (http://code.google.com/p/rafb-pl/)
#
# Author: _pragma (irc.freenode.net/#c,#perl,etc)
# Version History
#
# 0.1.12(06/26/09): Renamed rafb.pl to pastelling.pl (for historic reasons)
#                 : Modified to make it the default script for http://pastebin.slackadelic.com/
#                   since rafb.net has gone to the great pastebin in the sky.
#                 : moved all references to rafb.net to http://pastebin.slackadelic.com
#
# 0.1.12(05/23/06): added copyleft
# 0.1.11(02/02/05): fixed redirection response, shows URL to paste again
# 0.1.10(12/11/04): updated -h to reflect addition of -t
# 0.1.9 (12/11/04): now automagically detects language if using STDIN
# 0.1.8 (12/11/04): beautified some code blocks
# 0.1.7 (12/10/04): fixed support for C++ and C files and stopped using letters in
#                   the versioning
# 0.1.6e(12/10/04): added support for header files, der...
# 0.1.6d(12/10/04): added dumping of request header if failed and -v
# 0.1.6c(12/10/04): strk says, 'you're calling detect_lang on undefined $file (STDIN case)'
# 0.1.6b(12/10/04): Misc. tiny clean-ups, fixes.
# 0.1.6 (12/10/04): Added -t to show text, instead of with -v
# 0.1.5 (12/10/04): Received generous constructive criticism from Somni 
#                   of irc.freenode.net/#perl - made changes throughout.
#                   (note: have not implemented all criticism, yet)
# 0.1.4 (12/10/04): Add -s to use force using STDIN
# 0.1.3 (12/10/04): Uses file(1) to determine lang to use if ext is unknown/missing
# 0.1.2 (12/10/04): Attempts to use STDIN if no file is supplied
# 0.1.1 (12/10/04): Added -h, -v, and -D switches.  Tons of verbose and
#                   debugging output added.
# 0.1.0 (12/09/04): Mature enough to warrant new minor version increment.
#                   Several optimizations and code clean ups.  1.0.0 yet?
# 0.0.9 (12/09/04): Added support to automatically select proper
#                   language based on file extension (overridable with -l)
# 0.0.8 (12/09/04): Use $ENV{USER} for default now
# 0.0.7 (12/09/04): Added sane -l option checking
# 0.0.6 (12/09/04): Gah, how stupid can I get?!  Now shows URL to paste
# 0.0.5 (12/09/04): uri_escaped options, used $0 in show_usage
# 0.0.4 (12/09/04): Cleaned up show_usage and conformed to Posix
# 0.0.3 (12/09/04): Added 'example' to show_usage
# 0.0.2 (12/09/04): Uses Getopt::Std and processes options
# 0.0.1 (12/09/04): Posted initial version on website
#
# Inspired by prec.
#
# Special thanks to strk for contributions and to dorto, PoppaVic,
# twkm, Zhivago, and others for constructive ;) criticisms.

# copyleft - this script may be freely distributed and modified to suit 
# needs as long as everything above this line remains intact with 
# the exception that your modifications are added to the version history
# and credit is given where due.

my $VERSION = "0.1.12";

use strict;
use LWP::UserAgent;
use URI::Escape;
use Getopt::Std;

sub show_usage;

my %options=();
my ($lang, $desc, $nick, $verbose, $debug, $usestdin, $file, $showtext);

my %valid_lang = (
                  'h'    => 'C',
                  'hpp'  => 'C++',
                  'hh'   => 'C++',
                  'c'    => 'C',     
                  'cpp'  => 'C++', 
                  'cs'   => 'C#', 
                  'java' => 'Java',
                  'pas'  => 'Pascal', 
                  'pl'   => 'Perl', 
                  'php'  => 'PHP', 
                  'pli'  => 'PL/I',
                  'py'   => 'Python', 
                  'rb'   => 'Ruby', 
                  'sql'  => 'SQL', 
                  'vb'   => 'Visual Basic',
                  'xml'  => 'XML', 
                  'txt'   => 'Plain Text'
                 );

$nick     = $ENV{USER};
$desc     = "Pasted with pastelling.pl";
$verbose  = 0;
$debug    = 0;
$showtext = 0;
$usestdin = 0;

if($#ARGV == -1) {
  $usestdin = 1;
}
else {
  $file = $ARGV[$#ARGV];
}

getopts("l:n:d:hvDst", \%options);

show_usage and exit                            if defined $options{h};
$nick                = uri_escape($options{n}) if defined $options{n};
$desc                = uri_escape($options{d}) if defined $options{d};
$verbose             = 1                       if defined $options{v};
$debug               = 1                       if defined $options{D};
$usestdin            = 1                       if defined $options{s};
$showtext            = 1                       if defined $options{t};

if($usestdin) {
  $lang = "Plain Text";
}
else {
  $lang = detect_lang($file);
}

if($verbose) {
  print STDERR "Using nick:     $nick\n";
  print STDERR "Detected lang:  $lang\n";
  print STDERR "Using  desc:    $desc\n";
  print STDERR "File:           $file\n" if defined($ARGV[$#ARGV]);
}

if(defined $options{l}) {
  my $valid = 0;
  $lang = $options{l};

  foreach my $chk (keys %valid_lang) {
    if($lang eq $valid_lang{$chk}) {
      print STDERR "Overriding lang with: $lang\n\n" if($verbose);
      $lang = uri_escape($lang);
      $valid = 1;
      last;
    }
  }

  if(!$valid) {
    print "'$lang' is not a valid language, valid languages are:\n\t";
    foreach my $chk (keys %valid_lang) {
      print "$valid_lang{$chk}, ";
    }
    print "\n"; exit;
  }
}

$usestdin = 1 if(not defined $ARGV[$#ARGV]);

if($usestdin) {
  *FILE = *STDIN;
}
else {
  open(FILE, "< $file")
    or die "Failed to open $file for reading: $!\n"
}

my @textin = <FILE>;

if($usestdin) {
  $lang = detect_lang_firstline($textin[0]);
  print "Detected lang from stdin: $lang\n" if $verbose;
}

my $text = join('', @textin);

$text = uri_escape($text);

print STDERR "text: [$text]\n" if $showtext;

my $ua = LWP::UserAgent->new;
$ua->agent('pastelling.pl/0.1 ');

my $req = HTTP::Request->new(POST => 'http://pastebin.slackadelic.com/paste.php');
$req->content_type('application/x-www-form-urlencoded');
$desc =~ s/\s/+/g;
$req->content("lang=$lang&nick=$nick&desc=$desc&cvt_tabs=&text=$text");
$req->header('Referer' => 'http://pastebin.slackadelic.com/');

print STDERR "Sending request...\n" if $verbose and not $debug;
my $res = $ua->request($req) if not $debug;

if(not $debug and $res->is_redirect) {
  print $res->as_string, "\n" if $verbose;
  print $res->header('Location'), "\n";
}
elsif(not $debug and $res->is_success) {
  print "Pasted.\n";
  print STDERR $res->as_string, "\n" if $verbose;
}
elsif ($debug) {
  print "Debugging, request not sent.\n";
}
else {
  print "Failed.\n";
  print STDERR $res->as_string, "\n" if $verbose;  
}

sub show_usage {

  # This ought to be a here-doc, but I'm too lazy to convert it.

  print "$0 $VERSION, \n\nPastes text to http://pastebin.slackadelic.com\n";
  print "URL: http://github.com/michielvw/pastelling/tree/master\n\n";
  print "Usage: $0 [-Dstv] [-l <lang>] [-n <nick>] [-d <desc>] [filename]\n";
  print "Switches:\n";
  print "\t -h \t\t\tprints this text\n";
  print "\t -l <lang>\t\tlang=C,C++,Python,Java,etc (default: detected)\n";
  print "\t -n <nick> \t\tnick name (default: \$ENV{USER} : $ENV{USER})\n";
  print "\t -d <description>\tdescription (default: Pasted with pastelling.pl)\n";
  print "\t -s \t\t\tforce using STDIN\n";
  print "\t -v\t\t\tverbose\n";
  print "\t -t\t\t\tshow text being submitted\n";
  print "\t -D\t\t\tdebug (doesn't actually paste)\n";
  print "\nExamples:  ./pastelling.pl -n \"Bob\" -d \"A broken program\" program.c\n";
  print   "           cat code.c - | pastelling.pl\n";
}

sub detect_lang {
  my $file=shift;

  $file =~ /.*\.(.*)/;
  my $ext = $1;

  if(defined $ext) {
    return "Plain Text" if not defined $valid_lang{lc $ext};
  }

  my $fileoutput=`file $file`;
  return 'Ruby'    if $fileoutput =~ /ruby/i;
  return 'Perl'    if $fileoutput =~ /perl/i;
  return 'PHP'     if $fileoutput =~ /php/i;
  return 'Python'  if $fileoutput =~ /python/i;
  return 'XML'     if $fileoutput =~ / XML/;
  return 'C'       if $fileoutput =~ / C.*? program/i;
 
  return 'Plain Text'; # none of the above
}

sub detect_lang_firstline {
  my $line = join('', $_[0]);

  return 'Ruby'     if $line =~ /^#!.*?ruby/i;
  return 'Perl'     if $line =~ /^#!.*?perl/i;
  return 'PHP'      if $line =~ /^#!.*?php/i;
  return 'Python'   if $line =~ /^#!.*?python/i;
  return 'C'        if $line =~ /\/\*/i;
  return 'C'        if $line =~ /#include/;
  return 'C'        if $line =~ /#if?def/;
  return 'C++'      if $line =~ /\/\//i;

  return 'Plain Text'; # none of the above  
}
