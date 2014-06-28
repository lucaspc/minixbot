#!/usr/bin/perl

use Modern::Perl;
use autodie;
package racoonbot;
use base qw( Bot::BasicBot );
use WWW::Shorten 'Metamark', ':short';
use URI::Find::Schemeless;

our %memory;

sub save_memory{

   my $mem_file = shift;
   my $key = shift;
   my $value = shift;
   
   open my $fh, ">>", $mem_file;
   
   print $fh "$key>>$value\n";
   
   close $fh;
   return 1;
}

sub load_memory{
   my $mem_file = shift;
   open my $fh, "<", $mem_file;

   while (<$fh>){
      
      my ($key, $value) = split />>/, $_;
      $memory{$key} = $value;     
           
   }

   close $fh;
   return 1;
}

sub log_messages{
   my $logfile = shift;
   my $msg = shift;
   open my $log, ">>", $logfile;
   
   say $log $msg;         
   
   close $log;
}

sub said {
   my ($self, $message) = @_;
      
   my $text = $message->{body};
   
   my @uris;
   my $finder = URI::Find::Schemeless->new(sub {
       my($uri) = shift;
       push @uris, $uri;
   });
   my $tinyurlmsg =  "Shorten urls: ";
   
   if ( $finder->find(\$text) ){
   
      foreach ( @uris){
      
         $tinyurlmsg .= " ".short_link($_);
      
      }
      return $tinyurlmsg;
   }
   
   my $msgs = "$message->{raw_nick} ($message->{address}) $message->{body}";
   $msgs .= " in ".scalar localtime;
   log_messages("log.txt", $msgs);         
   say $msgs;
   
   if($message->{address} eq 'racoonbot' or 
      $message->{address} eq 'msg')  {
      load_memory("memory.txt");
   
      if ($message->{body} =~ /(.+) =save (.+)/ ) {
        save_memory("memory.txt", $1, $2);
        load_memory("memory.txt");
        return "The key '$1' is stored with value '$2'";
      }
      
      foreach ( keys %memory) {
      
         if ($message->{body} =~ /$_/i) {
            return $memory{$_};
         }
      }
   }
}

sub help { "Bot of #minix, always read to help you! Please save only useful things using key =save value syntax, thanks very much! :)" }

racoonbot->new(
   server => 'irc.freenode.net',
   channels => [ '#minix', '#minix-dev'],
   nick => 'racoonbot',
)->run();
