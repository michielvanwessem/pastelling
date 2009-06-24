#!/usr/bin/perl

#    Perl Paster - A script to paste text to rafb.net/paste    
#    Copyright (C) 2006  Steven Robson <steven@gnu.org>

#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License as
#    published by the Free Software Foundation; either version 2 of
#    the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301 USA

#    Usage:
#    There are no options for this program, it accepts text from stdin
#    or a file specified and places the text on the rafb.net/paste
#    pastebin, returning the URL of the paste.

use strict;
use warnings;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Text::Wrap;

$Text::Wrap::columns = 80;

my @buffer = <>;

my $buf= wrap('', '', @buffer);

my $ua = LWP::UserAgent->new ||die "cannot create user agent";

my $req = POST 'http://pastebin.slackadelic.com/paste.php',
   [ lang => 'Plain Text',
     nick => 'Michiel',
     desc => 'paste',
     cvt_tabs => 'No',
     text => $buf, ];

my $url = $ua->request($req)->header('Location');
print $url . "\n";
