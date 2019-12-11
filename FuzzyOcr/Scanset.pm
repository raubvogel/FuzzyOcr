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

package FuzzyOcr::Scanset;

use lib qw(..);
use FuzzyOcr::Logging qw(errorlog);

sub new {
    my ($class, $label, $preprocessors, $command, $args, $output_in) = @_;

    bless {
        "label"         => $label,
        "preprocessors" => $preprocessors,
        "command"       => $command,
        "args"          => $args,
        "force_output_in" => $output_in,
        "hit_counter"   => 0
    }, $class;
}

sub run {
    my ($self, $input) = @_;
    my $conf = FuzzyOcr::Config::get_config();
    my $tmpdir = FuzzyOcr::Config::get_tmpdir();
    my $label = $self->{label};
    my $output = "$tmpdir/scanset.$label.out";
    my $stderr = ">$tmpdir/scanset.$label.err";

    my @result;
    my $retcode;
    my $stdin = undef;
    my $stdout = undef;
    my $rcmd = $self->{command};

    #Replace supported scanner macros by full path
    if ($rcmd =~ m/^\$/) {
        my $t = 'focr_bin_'.substr($rcmd,1);
        $rcmd = $conf->{$t} if defined $conf->{$t};
    }
    if (defined $self->{args}) {
        $rcmd .= ' ' . $self->{args};
    }

    # First, run all preprocessors
    my $preprocessors = $self->{preprocessors};
        if ($preprocessors) {
        $preprocessors =~ s/ //g;
        my @prep = split(',', $preprocessors);
        foreach (@prep) {
            my $proc = FuzzyOcr::Config::get_preprocessor($_);
            my $plabel  = $proc->{label};
            my $command = $proc->{command};
            if (defined $proc->{args}) {
                $command .= ' ' . $proc->{args};
            }
            $retcode = $proc->run($input);
            if ($retcode<0) {
                errorlog("Cannot find/execute preprocessor($plabel): $command");
                return ($retcode,@result);
            } elsif ($retcode>0) {
                errorlog("Error running preprocessor($plabel): $command");
                open ERR, "<$tmpdir/prep.$plabel.err";
                @result = <ERR>;
                close ERR;
                return ($retcode,@result);
            }
            # Input of next processor is output of last
            $input = "$tmpdir/prep.$plabel.out";
        }
    }

    # All preprocessors done, filename with result of last is in $input
    # Does the scanner expect input from file or from stdin?
    if($rcmd =~ /\$input/) {
        $rcmd =~ s/\$input/$input/;
    } else {
        $stdin = "<$input";
    }

    # Does it output to file or to stdout?
    if($rcmd =~ /\$output/) {
        $rcmd =~ s/\$output/$output/;
    } else {
        $stdout = ">$output";
    }

    # Run scanner
    my $out_in = $self->{force_output_in};

    # Scanset enforces OCR output in file $out_in (for example TesserAct has multiple files as output)
    if ($out_in) {
        $out_in =~ s/\$output/$output/;
        $out_in =~ s/\$tmpdir/$tmpdir/;
        $retcode = FuzzyOcr::Misc::save_execute($rcmd, $stdin, $stdout, $stderr);
        unless ( open(INFILE, "<$out_in") ) {
            errorlog("Unable to read output from \"$out_in\" for scanset $self->{label}");
            $stderr =~ tr/>|</   /;
            if (open(INFILE, "<$stderr")) {
                @result = <INFILE>;
                close(INFILE);
                return ($retcode, @result);
            }
        }
        @result = <INFILE>;
        close(INFILE);
    } else {
        ($retcode, @result) = FuzzyOcr::Misc::save_execute($rcmd, $stdin, $stdout, $stderr, 1);
    }

    # If there were errors in the scan, return the errors instead of OCR results
    if ($retcode>0) {
        $stderr =~ tr/>|</   /;
        open(INFILE, "<$stderr");
        @result = <INFILE>;
        close(INFILE);
    }
    # Return scanner results and return code

    return ($retcode, @result);
}

1;
