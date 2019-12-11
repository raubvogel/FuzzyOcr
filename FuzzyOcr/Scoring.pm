# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

use strict;
package FuzzyOcr::Scoring;

use base 'Exporter';
our @EXPORT_OK = qw(wrong_ctype corrupt_img known_img_hash wrong_extension);

use lib qw(..);
use FuzzyOcr::Config qw(get_pms get_config);
use FuzzyOcr::Logging qw(infolog);

# Provide custom scoring functions

sub wrong_ctype {
    my $conf = get_config();
    my $pms = get_pms();
    my ( $format, $ctype ) = @_;
    if ($conf->{'focr_wrongctype_score'}) {
        my $debuginfo = "";
        if ( $conf->{"focr_verbose"} > 0 ) {
            $debuginfo = 
              ("Image has format \"$format\" but content-type is \"$ctype\"");
        }
        infolog($debuginfo);
        my $ws = sprintf( "%0.3f", $conf->{'focr_wrongctype_score'} );
        for my $set ( 0 .. 3 ) {
            $pms->{conf}->{scoreset}->[$set]->{"FUZZY_OCR_WRONG_CTYPE"} = $ws;
        }
	my @dinfo = split('\n', $debuginfo);
        foreach (@dinfo) {
            $pms->test_log($_);
        }
        $pms->_handle_hit( "FUZZY_OCR_WRONG_CTYPE",
            $conf->{'focr_wrongctype_score'}, "BODY: ", "BODY",
	    $pms->{conf}->get_description_for_rule("FUZZY_OCR_WRONG_CTYPE"));
    }
}

sub wrong_extension {
    my $conf = get_config();
    my $pms = get_pms();
    my ( $format, $suffix ) = @_;
    if ($conf->{'focr_wrongext_score'}) {
        my $debuginfo = "";
        if ( $conf->{"focr_verbose"} > 0 ) {
            $debuginfo = 
              ("Image has format \"$format\" but file extension is \"$suffix\"");
        }
        infolog($debuginfo);
        my $ws = sprintf( "%0.3f", $conf->{'focr_wrongext_score'} );
        for my $set ( 0 .. 3 ) {
            $pms->{conf}->{scoreset}->[$set]->{"FUZZY_OCR_WRONG_EXTENSION"} = $ws;
        }
	my @dinfo = split('\n', $debuginfo);
        foreach (@dinfo) {
            $pms->test_log($_);
        }
        $pms->_handle_hit( "FUZZY_OCR_WRONG_EXTENSION",
            $conf->{'focr_wrongext_score'}, "BODY: ", "BODY",
            $pms->{conf}->get_description_for_rule("FUZZY_OCR_WRONG_EXTENSION"));
    }
}

sub corrupt_img {
    my $conf = get_config();
    my $pms = get_pms();
    my ($score, $err) = @_;
    if ($score>0) {
        my $debuginfo = "";
        if ( $conf->{"focr_verbose"} > 0 ) {
            chomp($err);
            $debuginfo = ("Corrupt image: $err");
        }
        infolog($debuginfo);
        my $ws = sprintf( "%0.3f", $score );
        for my $set ( 0 .. 3 ) {
            $pms->{conf}->{scoreset}->[$set]->{"FUZZY_OCR_CORRUPT_IMG"} = $ws;
        }
	my @dinfo = split('\n', $debuginfo);
        foreach (@dinfo) {
                $pms->test_log($_);
        }
        $pms->_handle_hit( "FUZZY_OCR_CORRUPT_IMG", $score, "BODY: ", "BODY",
            $pms->{conf}->get_description_for_rule("FUZZY_OCR_CORRUPT_IMG"));
    }
}

sub known_img_hash {
    my $conf = get_config();
    my $pms = get_pms();
    my $score = $_[0] || $conf->{'focr_base_score'};
    my $debuginfo = $_[1] ? "\n$_[1]" : '';
    my $ws = sprintf( "%0.3f", $score );
    for my $set ( 0 .. 3 ) {
        $pms->{conf}->{scoreset}->[$set]->{"FUZZY_OCR_KNOWN_HASH"} = $ws;
    }
    my @dinfo = split('\n', $debuginfo);
    foreach (@dinfo) {
        $pms->test_log($_);
    }
    $pms->_handle_hit( "FUZZY_OCR_KNOWN_HASH", $score, "BODY: ", "BODY",
        $pms->{conf}->get_description_for_rule("FUZZY_OCR_KNOWN_HASH"));
}

1;
