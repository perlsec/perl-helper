package Perlsec::Helper;

##
#
# Copyright 2012 Kim Jørgensen (http://perlsec.dk)
#
# Licensed under the MIT license
# Redistribution of files must retain the above copyright notice
#
##

use strict;
use base qw( Exporter );
our @EXPORT=qw(say dsay stop);
our @EXPORT_OK=qw(stop var_print say dsay file_as_array write_to_file append_to_file run_command run_command_with_output url_as_array get_flag set_flag db_hash_as_insert unixtime_now);

#allows using module like: use Perlsec::Helper ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
stop
var_print
say
dsay
file_as_array
write_to_file
append_to_file
run_command
run_command_with_output
url_as_array
get_flag
set_flag
db_hash_as_insert
unixtime_now
) ] );

##### FLAGS
my $has_curl = 0;

sub import {
    my($class, @params) = @_;
    # CONDITIONAL USE OF DATA DUMPER, only if var_print is exported
    if(grep(/var_print/, @params)){
        use Data::Dumper qw(Dumper);
    }
    #now return control to the normal import routine
    Perlsec::Helper->export_to_level(1, @_);
}


## SUBS

sub say($){
 #like print but appends \n
 if(@_){
    print $_[0] . "\n";
 }
 else{
    print "ERROR: No argument given to say function\n";
 }
}

sub dsay($){
 #like say, put only prints, if the environment var DEBUG is set
 if($ENV{DEBUG}){
    &say("DEBUG: " . $_[0]);
 }
}


sub var_print($\[$@%&*]){
 #name/tag (string)
 my $tag = shift;
 my @data = @_;
 #variable or reference to it
 #print with Data::Dumper
 if($ENV{DEBUG}){
     print "DEBUG-VAR; $tag: \n". Dumper(@data);
     print "#####End dump#####\n\n";
 }
}

sub stop(;$){
 #preemptive closing function
 #call to end excution
 if(@_){
    print "DEBUG - execution stopped: $_[0]\n";
 }
 else{
    print "DEBUG - execution stopped\n";
 }
 exit();
}

sub file_as_array($){
 my $filepath = shift;
 #check for read permission or die
 unless(-r $filepath){
    die "ERROR: Could not read: $filepath";
 }
 #open and read into array
 my @filecontent;
 open FILE, "<",$filepath or die "ERROR: Failed open of: $filepath";
 @filecontent = <FILE>;
 close FILE;
 return @filecontent;
 
}

sub write_to_file($@){
 my $filepath = shift;
 my @content = @_;
 open FILE, ">", $filepath or die "ERROR: could not open for writing: $filepath";
 print FILE @content;
 close FILE or die "ERROR: could not close file after write";
}

sub append_to_file($@){
 my $filepath = shift;
 my @content = @_;
 #check if its exists, is a file, and is writeable
 if(-e $filepath && -f $filepath && -w $filepath){
     open FILE, ">>", $filepath or die "ERROR: could not open for writing: $filepath";
     print FILE @content;
     close FILE or die "ERROR: could not close file after write";
 }else{
    die "ERROR: Could not append to file: $filepath";
 }
}

sub run_command($){
#runs a command, returns nothing if everything goes fine
#returns output if command fails
my $command = shift;
$command .= " 2>&1";
my $output = `$command`;
if( $? != 0){ #check for non-0 return value
 return $output if $output;
 return "Command Failed: $command";
}
return "";
}

sub run_command_with_output($){
#runs command and returns all results
#also returns a non-0 number as second parameter if command fails
my $command = shift;

$command .= " 2>&1";
my $output = `$command`;
#$? is return-code
return ($output, $?);
}

sub url_as_array($){
    my $url = shift;
#   check we have a curl command we can call
    unless($has_curl){
        if(&verify_command_exists("curl")){
            $has_curl = 1;
        }
        else{
            die "No curl for url_as_array";
        }
    }
#   attempt to get url 
    my @data = `curl --fail --silent $url` or die "Couldnt get data from: $url - $!";
    return @data;
}


sub verify_command_exists($){
    #check if command exists in path
    my $command = shift;
    my @paths = split(/:/, $ENV{'PATH'});
    my $found = 0; 
    foreach my $dir (@paths){
       my $complete_path = "$dir/$command";
           if (-e $complete_path){
         $found++;
       }    
    }    
    if($found >= 1){
        return "true";
    }    
    else{
        return "";
    }    
}

sub unixtime_now(){
	if (!&verify_command_exists('date')){
		die "No data command could be found for unixtime_now function";
	}

	my @unixtimestamp_cmd_output = &run_command_with_output('date +%s');
	if($unixtimestamp_cmd_output[1] != 0){
		die "Error on date execution in unixtime_now function: " . $unixtimestamp_cmd_output[0];
	}
	my $unixtimestamp = $unixtimestamp_cmd_output[0];
	chomp($unixtimestamp);
	return $unixtimestamp;
}

### FLAG subs

sub get_flag($){
    my $flag = shift;
    my $tmpflagfile = &_get_flag_tmpfile();
    if(!-e $tmpflagfile){
        return "";
    }
     #check for flag
    my @file_data = file_as_array($tmpflagfile);
    foreach my $line(@file_data){
        my @split_line = split(/\|/, $line);
	chomp($split_line[1]);
        if($split_line[0] eq $flag){
            return $split_line[1];
        }
    }
    #if no flag is found, return nothing
    return "";
}


sub set_flag($$){
    #no lock method implemented, so there could be a race condition.
    #usecases for this should make that unlikely, and this should work pretty fast anyway
    my($flag, $value) = @_;
    my $data_to_write = "$flag|$value\n";
    my $tmpflagfile = &_get_flag_tmpfile();
    #check if file exists
    if(-e $tmpflagfile){
        #check if file is writeable, else die
        die "ERROR: Can not write to tmp flag file: $tmpflagfile" if(!-w $tmpflagfile);
        #read file
        my @file_data = file_as_array($tmpflagfile);
        my @writeback_data;
        my $found_match;
        foreach my $line (@file_data){
            my @split_line = split(/\|/, $line);
            #check if flag is already in that file
            if($split_line[0] eq $flag){
                #if it is replace that line
                push @writeback_data, $data_to_write;
                #and mark that we found it
                $found_match = 1;
            }
            else{
                #if  not found we just keep any extra data in the file
                push @writeback_data, $line;
            }
        }
        #if not found, just append it to the file
        push @writeback_data, $data_to_write if(!$found_match);
        #write entire file back out
        write_to_file($tmpflagfile, @writeback_data);
        return ""; #return OK
    }
    else{
        #if file doesnt exist we just write the data into the new file
        write_to_file($tmpflagfile,$data_to_write);
        return ""; #all is good, return nothing
    }
}


sub _get_flag_tmpfile(){
    my $script_path = $0;
    $script_path =~ m/\/([a-zA-Z0-9_.-]+)$/ or die "ERROR: Could not get script name";
    my $script_name = $1;
    my $flagtmpfile = "/tmp/$script_name.flags";
    return $flagtmpfile;
}

### /FLAG subs

### DB functions

sub db_hash_as_insert($$){
        my $table_name = shift;
        my $data_hash_ref = shift;
        my $sql_fields;
        my $sql_values;
        foreach my $field( keys(%$data_hash_ref) ){
                my $value = $$data_hash_ref{$field};
                $sql_fields .= "$field, ";
                #check if NULL or UUID value
                if( !defined($value) ){
                        $sql_values .= "NULL, "
                }
                elsif( $value eq 'UUID'){
                        $sql_values .= "UUID(), ";
                }
                else{
                        $sql_values .= "'$value', ";
                }
        }
        #cut trailing comma and spave off of strings
        $sql_values = substr($sql_values, 0,-2);
        $sql_fields = substr($sql_fields, 0,-2);

        my $sql = "INSERT INTO $table_name ($sql_fields) VALUES ($sql_values);";
        return $sql;
}

### /DB functions


1;
