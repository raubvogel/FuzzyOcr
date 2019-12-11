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

package FuzzyOcr::Preprocessor;

sub new {
    my ($class, $label, $command, $args) = @_;

    bless {
        "label"     => $label,
        "command"   => $command,
        "args"      => $args
    }, $class;
}

sub run {
    my ($self, $input) = @_;
    my $tmpdir = FuzzyOcr::Config::get_tmpdir();
    my $label = $self->{label};
    my $output = "$tmpdir/prep.$label.out";
    my $stderr = ">$tmpdir/prep.$label.err";

    my $stdin = undef;
    my $stdout = undef;
    my $args = $self->{args};
    my $rcmd = $self->{command};

    if (defined $args) {
        $rcmd .= ' ' . $args;
    }

    # Does the processor expect input from file or from stdin?
    if(defined $args and $args =~ /\$input/) {
        $rcmd =~ s/\$input/$input/;
    } else {
        $stdin = "<$input";
    }

    # Does it output to file or to stdout?
    if(defined $args and $args =~ /\$output/) {
        $rcmd =~ s/\$output/$output/;
    } else {
        $stdout = ">$output";
    }

    # Run processor
    my $retcode = FuzzyOcr::Misc::save_execute($rcmd, $stdin, $stdout, $stderr);

    # Return code
    return $retcode;
}

1;
