#!/usr/bin/perl

use Modern::Perl;
use autodie;
package racoonbot;
use base qw( Bot::BasicBot );
use WWW::Shorten 'Metamark', ':short';
use URI::Find::Schemeless;


#save keys and values using syntax key>>value
sub save_memory{

   my $mem_file = shift;
   my $key = shift;
   my $value = shift;
   
   open my $fh, ">>", $mem_file or die "$!";
   
   print $fh "$key>>$value\n";
   
   close $fh;
   return 1;
}

#load from a memory file to a hash following the syntax key>>value
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

#store messages sent to the bot in a log file
sub log_messages{
   my $logfile = shift;
   my $msg = shift;
   open my $log, ">>", $logfile;
   
   say $log $msg;         
   
   close $log;
}


#the 'ear' of the bot, here he listen every message and parses it and then
#return the message 
sub said {
   my ($self, $message) = @_;
      
   if($message->{address} eq 'racoonbot' or #messages to bot 
      $message->{address} eq 'msg')  {
      
      my $msgs = "$message->{raw_nick} ($message->{address}) $message->{body}";
      $msgs .= " in ".scalar localtime;
      log_messages("log.txt", $msgs);         
      say $msgs;
   
      if ($message->{body} =~ /(.*)\+\+/ ) #find things like 'word++' 
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
         
      if ($message->{body} =~ /^exp (.*)/ )#find things like 'exp word' 
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
      
      if ($message->{body} =~ /(.+) =save (.+)/ ) { # key =save value
        
        #replacing links
         my $text =  $message->{body};

         my @uris;
         my $finder = URI::Find::Schemeless->new(sub {
             my $uri = shift;
             push @uris, $uri;
         });

         print "@uris\n";
         my $count = 1;
         if ($finder->find(\$text)){

            foreach (@uris){
               
               my $short = short_link($_);

               $text =~ s/$count/$short/g;
               $count++;
            }

        }
        
        if ($text =~ /(.+) =save (.+)/){
                        
           save_memory("memory.txt", $1, $2);
           my $refer = load_memory("memory.txt");
                  
           return "The key '$1' is stored with value '$2'"; #message of storage
      }
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
         return $tinyurlmsg; #shorter urls are returned
      }
      
      if ($message->{body} =~ /(.*)\+\+/ ) #search in memory for added names 
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

#help of the bot
sub help { "Bot of #minix, always read to help you! Please save only useful things using key =save value syntax, thanks very much! :)" }

#attributes of the bot
racoonbot->new(
   server => 'irc.freenode.net',
   channels => [ '#minix', '#minix-dev'],
   nick => 'racoonbot',
)->run();
