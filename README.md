# Perlsec::Helper

## Intro
This is a simple Perl helper library i use myself to simplify repetative tasks.
I have tried to keep it simple in use, code and dependencys.

It only depends on *Exporter* and *Data::Dumper*, both are standard in Perl.
Data:Dumper is only loaded when the var_print function is used.
The url_as_array also depends on the curl commandline tool being installed.

I opted not to write it object oriented, to make the use as straight-forward as possible.

If any function can get in trouble, it will die so it can be caught instead of possibly failing silently.

## Installation

You can install the library in two ways, depending on how you want to ue it.

I personally prefer to install it via the second option to have it available everywhere on the system.

Once the library is installed, you can use it in a script like this:

```perl
use Perlsec::Helper ':all';
say "Helper works!";
```

### Same dir installation
Here you just need to put the Perlsec folder in the same place as the code that includes it.

### System-wide installation
To make the library availble for all scripts, we can install it in a Perl-library location.
To find all the places Perl will check for librarys, use this command:
```perl
perl -le 'print foreach @INC'
```

Then pick a folder of those listed, and put the Perlsec folder in there.

(I usually use the folder: /usr/local/lib/site_perl)

## Functions

**stop**
Stops execution, and posts debug message
args:
(optional) string, which is appended to debug message 

**say**
Like print, but adds a newline at the end of the output.

**file_as_array**
Does sanity checks for reading a file, reads it and returns the content as an array.

**write_to_file**
Does sanity checks for writing to a file,
then takes the input and overwrites the file with it. If the file does not exist it is created.
args:
string, filename
array/string, content in the file

**append_to_file**
Does sanity checks for opening and writing to a file, then appends the data at the end of the file. Will die if the file doesnt exist.
args:
string, filename
array/string, content to append to the file

**run_command**
Runs a command, without returning the output.
Returns nothing if everything is ok
Dies on non-0 return value from the command and returns the output i there is any, or a generic failure message.
args:
string, the command to be run

**run_command_with_output**
Runs a command, and returns the output and the exit code. It lets the programmer handle any errors.
Returns an array with two values.
0 - The output of the command
1 - The return code of the command.
args:
string, the command to be run

**url_as_array**
Uses commandline Curl to grab that output of a URl.
Will die if Curl does not exist or the Curl command fails.
Returns the data Curl got from the url as an array.
args:
string, the URL to get the data from

**set_flag**
Used to set a simple value in a file in /tmp
the can the be changed and read later.
The name of the tmp file is based on the name of the script using the library.
So the same tmp file is used as long as the scripts name stays the same.
If the flag is already set, it will update it.
If the flag file does not exist it will create it.
args:
string, flag/value name
string, content/value to set

**get_flag**
This function reads the value of a given flag.
Returns nothing if the flag isn't found or the flag file doesnt exist.
See set_flag for how the flag data is saved.
args:
string, the name of the flag.


###Debug functions
These functions will only be run if the DEBUG shell variable is set to something

**var_print**
Prints content of variable, using Data::Dumper.
args:
string, identifier for the output, f.x. variable name
var/array/hash/obj/ref, to be printed

**dsay**
Like the say function, but will only output when the DEBUG shell-variable is set.


## Examples

### Loading
The library can be loaded with all functions like.
```perl
use Perlsec::Helper ':all';
```

Or you can choose to only load the commands you know you need.
```perl
use Perlsec::Helper qw'say dsay stop';
```


### Debug
Some functions, like dsay and var_print, are only active in debug mode.
To activate debug mode for a script that has the helper loaded, simply set the shell variable DEBUG to something.
```bash
DEBUG=true ./script.pl
```

### Examples of function use
```perl

set_flag("fishy", "like tuna or something");
say "flag is: " . get_flag("fishy");

my @web_data = url_as_array("http://perlsec.dk");
var_print('@web_data', @web_data);

say("test message");

stop("test");
stop();

dsay("test debug output");

my @test_array = qw(one two three four five six seven eight nine ten);
var_print("numbers array", @test_array);

my %test_hash = (
    test => "one",
    test2 => "two"
);
var_print("hash test", %test_hash);

my $test_var = "test var content";
var_print("string test ", $test_var);



#read a testfile
my @testfile = file_as_array("/tmp/testfile");
print "@testfile \n";

#write content to a file
my @test_content = ("testlinie 1\n", "linie2\n", "linie3\n", "linie4\n");
var_print("content", @test_content);
write_to_file("/tmp/testfile", @test_content);


### testing command-functions without output if there is no error
my $test_command_work = "cat /etc/passwd";
my $out1 = run_command($test_command_work);
say $out1 if ($out1);

my $test_command_fail = "cat /etc/idontEXIstsss";
my $out2 = run_command($test_command_fail);
say $out2 if ($out2);

## testing command-functions with output
my @out3 = run_command_with_output($test_command_work);
if($out3[1] != 0){
 say "got an error!: $out3[0]";
}
else{
 say $out3[0];
}

my @out4 = run_command_with_output($test_command_fail);
if($out4[1] != 0){
 say "got an error!: $out4[0]";
}
else{
 say $out4[0];
}
```

