#!/usr/bin/perl

use Modern::Perl;
use autodie;
package racoonbot;
use base qw( Bot::BasicBot );
use WWW::Shorten 'Metamark', ':short';
use URI::Find::Schemeless;

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
   my $hashref;
   open my $fh, "<", $mem_file;
   
   while (<$fh>){
      
      my ($key, $value) = split />>/, $_;
      $hashref->{$key} = $value;     
           
   }

   close $fh;
   return $hashref;
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
      
   if($message->{address} eq 'racoonbot' or 
      $message->{address} eq 'msg')  {
      
      my $msgs = "$message->{raw_nick} ($message->{address}) $message->{body}";
      $msgs .= " in ".scalar localtime;
      log_messages("log.txt", $msgs);         
      say $msgs;
   
      if ($message->{body} =~ /(.*)\+\+/ ) 
      {
         
         my $name = $1;
         my $refer = load_memory("minix.txt");
                 
         my $check;
         foreach ( keys %$refer){
            
            if ($1 =~ /\b$_\b/){
               save_memory("minix.txt", $name, ++$refer->{$_});
               $check++;
               last;
            }
         }
         save_memory("minix.txt", $name, ++$refer->{$_}) unless $check;
      }
      
      my $refer = load_memory("memory.txt");
         
      if ($message->{body} =~ /^exp (.*)/ ) 
      {
      
         my $refer = load_memory("minix.txt");
         my $save = $1;
         
         foreach (keys %$refer){
         
            if ($1 =~ /\b$_\b/){
               chomp($refer->{$_});
               return "$save has $refer->{$_} minix exp";
            }
            
            else{
               return "$save has no minix exp";
            
            }
         }                  
      }
      
      if ($message->{body} =~ /(.+) =save (.+)/ ) {
        save_memory("memory.txt", $1, $2);
        my $refer = load_memory("memory.txt");
               
        return "The key '$1' is stored with value '$2'";
      }
      
      foreach ( keys %$refer) {
      
         if ($message->{body} =~ /\b$_\b/i) {
            return $refer->{$_};
         }
      }
      
      my $fl = substr $message->{body}, 0, 1;
      
      my @mem_list = grep { $_  =~ /^$fl/i} keys %$refer;
      my $words = join ' : ', @mem_list;
      
      if(@mem_list){
         return "Did you mean: $words";
      }
      elsif ( $message->{body} =~ /(.*)\+\+/  ){
         return;
      }
      else{
         return "Key not found! Try again! :(";
      }
   }
   
   my $text = $message->{body};
   
      my @uris;
      my $finder = URI::Find::Schemeless->new(sub {
          my($uri) = shift;
          push @uris, $uri;
      });
      my $tinyurlmsg =  "Shorter urls: ";
      
      if ( $finder->find(\$text) ){
      
         foreach ( @uris){
         
            $tinyurlmsg .= " ".short_link($_);
         
         }
         return $tinyurlmsg;
      }
      
      if ($message->{body} =~ /(.*)\+\+/ ) 
      {
         my $name = $1;
         my $refer = load_memory("minix.txt");
                  
         my $check;
         foreach ( keys %$refer){
            
            if ($1 =~ /\b$_\b/){
               save_memory("minix.txt", $name, ++$refer->{$_});
               $check++;
               return;
            }
         }
         save_memory("minix.txt", $name, ++$refer->{$_}) unless $check;
      }
   return;
}

sub help { "Bot of #minix, always read to help you! Please save only useful things using key =save value syntax, thanks very much! :)" }

racoonbot->new(
   server => 'irc.freenode.net',
   channels => [ '#minix', '#minix-dev'],
   nick => 'racoonbot'
)->run();
