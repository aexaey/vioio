#!/usr/bin/perl

use IO::Socket;

system("adb forward tcp:4545 tcp:4545");

my $sock = new IO::Socket::INET (
    PeerAddr => '127.0.0.1',
    PeerPort => '4545',
    Proto => 'tcp',
    );
die "Could not create socket: $!\n" unless $sock;
binmode($sock);
$sock->autoflush();
print $sock "\0IOIOSPRK0016IOIO0100IOIO0300";
my $buf="";
while (!(substr($buf,1,7) eq "IOIO000")){
    $len = sysread($sock, $buf, 9);
#    print "buf='$buf'; len='$len'\n";
    sleep(1);
}
print "Connected! reply='$buf'\n";
syswrite($sock, "\002=", 2);
my @pin;
my $adc=-1;
while (1){
    $len = sysread($sock, $buf, 2);
    @bytes = unpack ('C*', $buf);
    $hex = unpack ('H20', $buf);
    if ($bytes[0]==4){
	my $bit=$bytes[1] & 1;
	my $dir=($bytes[1] & 2 ) >> 1;
	my $address=$bytes[1] >> 2;
	if ($dir == 0){
	    $pin[$address]=$bit;
	}else{
	    printf("cmd=0x04 bit=%d dir=%d address=%02x\n",$bit, $dir, $address);
	}
    }elsif ($bytes[0]==0x0b){
	$adc=$bytes[1];
        syswrite($sock, "\x0c\x01\x21", 3);
    }else{
	printf("cmd=%02x data=%02x\n",$bytes[0],$bytes[1]);
    }
    for($i=0;$i<48;$i++){
	printf("%1b",$pin[$i]);
    }
    print "\n";
    # Ugly hack for ADC input
    if ($adc>=0){
	if (rand(100)<1){
    	    syswrite($sock, "\x0b\x02", 2);
    	    syswrite($sock, rand(255), 1);
        }
    }
}
close($sock);