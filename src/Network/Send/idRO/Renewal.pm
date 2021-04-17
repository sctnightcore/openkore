#########################################################################
#  OpenKore - Network subsystem
#  This module contains functions for sending messages to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# Servertype overview: https://openkore.com/wiki/ServerType
package Network::Send::idRO::Renewal;

use strict;
use base qw(Network::Send::idRO);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);

	my %handlers = qw(
		char_create 0A39
	);
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;

	$self->{char_create_version} = 0x0A39;

	#buyer shop
	$self->{buy_bulk_openShop_size} = "(a10)*";
	$self->{buy_bulk_openShop_size_unpack} = "V v V";

	$self->{buy_bulk_buyer_size} = "(a8)*";
	$self->{buy_bulk_buyer_size_unpack} = "a2 V v";

	return $self;
}

=for comment
sub sendMasterSecureLogin {
	my ($self, $username, $password, $salt, $version, $master_version, $type, $account) = @_;

	$self->{packet_lut}{master_login} ||= $type < 3 ? '01DD' : '01FA';

	my $packet = $self->reconstruct({
		switch => 'master_login',
		version => $version || $self->version,
		master_version => $master_version,
		username => $username,
		password_salted_md5 => $self->secureLoginHash($password, $salt, $type),
		clientInfo => $account > 0 ? $account - 1 : 0,
	});

	my @msg;

	for(my $i = 0; $i < length($packet); $i++) {
		push @msg, 0x.unpack("C*", substr($packet, $i, 1));
	}

	$self->sendToServer($self->encrypt_packet(@msg));
}
=cut

# here's what the packet look like
# 75 0A 43 00 yy yy yy yy 94 39 00 00 3F 00 00 00
# 2F 00 00 00 xx xx xx xx xx xx xx xx xx xx xx xx
# xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx
# xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx

# yy yy yy yy = encryption second phase
# xx xx xx xx = encryption first phase

# Algoritm Code by @FF
# Converted to opekore by @alisonrag
# Here we convert 01DD to 0A75
sub encrypt_packet {
	my ($self, @msg) = @_;
	my ($temporary_calc, $hex_indexer, $counter) = 0;
	my @encrypted_packet = (0x75, 0x0A, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00, 0x94, 0x39, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x2F, 0x00, 0x00, 0x00);

	my @key = ( 0x00,0x00,0x00,0x00,0x96,0x30,0x07,0x77,0x2C,0x61,0x0E,0xEE,
	0xBA,0x51,0x09,0x99,0x19,0xC4,0x6D,0x07,0x8F,0xF4,0x6A,0x70,0x35,0xA5,0x63,0xE9,
	0xA3,0x95,0x64,0x9E,0x32,0x88,0xDB,0x0E,0xA4,0xB8,0xDC,0x79,0x1E,0xE9,0xD5,0xE0,
	0x88,0xD9,0xD2,0x97,0x2B,0x4C,0xB6,0x09,0xBD,0x7C,0xB1,0x7E,0x07,0x2D,0xB8,0xE7,
	0x91,0x1D,0xBF,0x90,0x64,0x10,0xB7,0x1D,0xF2,0x20,0xB0,0x6A,0x48,0x71,0xB9,0xF3,
	0xDE,0x41,0xBE,0x84,0x7D,0xD4,0xDA,0x1A,0xEB,0xE4,0xDD,0x6D,0x51,0xB5,0xD4,0xF4,
	0xC7,0x85,0xD3,0x83,0x56,0x98,0x6C,0x13,0xC0,0xA8,0x6B,0x64,0x7A,0xF9,0x62,0xFD,
	0xEC,0xC9,0x65,0x8A,0x4F,0x5C,0x01,0x14,0xD9,0x6C,0x06,0x63,0x63,0x3D,0x0F,0xFA,
	0xF5,0x0D,0x08,0x8D,0xC8,0x20,0x6E,0x3B,0x5E,0x10,0x69,0x4C,0xE4,0x41,0x60,0xD5,
	0x72,0x71,0x67,0xA2,0xD1,0xE4,0x03,0x3C,0x47,0xD4,0x04,0x4B,0xFD,0x85,0x0D,0xD2,
	0x6B,0xB5,0x0A,0xA5,0xFA,0xA8,0xB5,0x35,0x6C,0x98,0xB2,0x42,0xD6,0xC9,0xBB,0xDB,
	0x40,0xF9,0xBC,0xAC,0xE3,0x6C,0xD8,0x32,0x75,0x5C,0xDF,0x45,0xCF,0x0D,0xD6,0xDC,
	0x59,0x3D,0xD1,0xAB,0xAC,0x30,0xD9,0x26,0x3A,0x00,0xDE,0x51,0x80,0x51,0xD7,0xC8,
	0x16,0x61,0xD0,0xBF,0xB5,0xF4,0xB4,0x21,0x23,0xC4,0xB3,0x56,0x99,0x95,0xBA,0xCF,
	0x0F,0xA5,0xBD,0xB8,0x9E,0xB8,0x02,0x28,0x08,0x88,0x05,0x5F,0xB2,0xD9,0x0C,0xC6,
	0x24,0xE9,0x0B,0xB1,0x87,0x7C,0x6F,0x2F,0x11,0x4C,0x68,0x58,0xAB,0x1D,0x61,0xC1,
	0x3D,0x2D,0x66,0xB6,0x90,0x41,0xDC,0x76,0x06,0x71,0xDB,0x01,0xBC,0x20,0xD2,0x98,
	0x2A,0x10,0xD5,0xEF,0x89,0x85,0xB1,0x71,0x1F,0xB5,0xB6,0x06,0xA5,0xE4,0xBF,0x9F,
	0x33,0xD4,0xB8,0xE8,0xA2,0xC9,0x07,0x78,0x34,0xF9,0x00,0x0F,0x8E,0xA8,0x09,0x96,
	0x18,0x98,0x0E,0xE1,0xBB,0x0D,0x6A,0x7F,0x2D,0x3D,0x6D,0x08,0x97,0x6C,0x64,0x91,
	0x01,0x5C,0x63,0xE6,0xF4,0x51,0x6B,0x6B,0x62,0x61,0x6C,0x1C,0xD8,0x30,0x65,0x85,
	0x4E,0x00,0x62,0xF2,0xED,0x95,0x06,0x6C,0x7B,0xA5,0x01,0x1B,0xC1,0xF4,0x08,0x82,
	0x57,0xC4,0x0F,0xF5,0xC6,0xD9,0xB0,0x65,0x50,0xE9,0xB7,0x12,0xEA,0xB8,0xBE,0x8B,
	0x7C,0x88,0xB9,0xFC,0xDF,0x1D,0xDD,0x62,0x49,0x2D,0xDA,0x15,0xF3,0x7C,0xD3,0x8C,
	0x65,0x4C,0xD4,0xFB,0x58,0x61,0xB2,0x4D,0xCE,0x51,0xB5,0x3A,0x74,0x00,0xBC,0xA3,
	0xE2,0x30,0xBB,0xD4,0x41,0xA5,0xDF,0x4A,0xD7,0x95,0xD8,0x3D,0x6D,0xC4,0xD1,0xA4,
	0xFB,0xF4,0xD6,0xD3,0x6A,0xE9,0x69,0x43,0xFC,0xD9,0x6E,0x34,0x46,0x88,0x67,0xAD,
	0xD0,0xB8,0x60,0xDA,0x73,0x2D,0x04,0x44,0xE5,0x1D,0x03,0x33,0x5F,0x4C,0x0A,0xAA,
	0xC9,0x7C,0x0D,0xDD,0x3C,0x71,0x05,0x50,0xAA,0x41,0x02,0x27,0x10,0x10,0x0B,0xBE,
	0x86,0x20,0x0C,0xC9,0x25,0xB5,0x68,0x57,0xB3,0x85,0x6F,0x20,0x09,0xD4,0x66,0xB9,
	0x9F,0xE4,0x61,0xCE,0x0E,0xF9,0xDE,0x5E,0x98,0xC9,0xD9,0x29,0x22,0x98,0xD0,0xB0,
	0xB4,0xA8,0xD7,0xC7,0x17,0x3D,0xB3,0x59,0x81,0x0D,0xB4,0x2E,0x3B,0x5C,0xBD,0xB7,
	0xAD,0x6C,0xBA,0xC0,0x20,0x83,0xB8,0xED,0xB6,0xB3,0xBF,0x9A,0x0C,0xE2,0xB6,0x03,
	0x9A,0xD2,0xB1,0x74,0x39,0x47,0xD5,0xEA,0xAF,0x77,0xD2,0x9D,0x15,0x26,0xDB,0x04,
	0x83,0x16,0xDC,0x73,0x12,0x0B,0x63,0xE3,0x84,0x3B,0x64,0x94,0x3E,0x6A,0x6D,0x0D,
	0xA8,0x5A,0x6A,0x7A,0x0B,0xCF,0x0E,0xE4,0x9D,0xFF,0x09,0x93,0x27,0xAE,0x00,0x0A,
	0xB1,0x9E,0x07,0x7D,0x44,0x93,0x0F,0xF0,0xD2,0xA3,0x08,0x87,0x68,0xF2,0x01,0x1E,
	0xFE,0xC2,0x06,0x69,0x5D,0x57,0x62,0xF7,0xCB,0x67,0x65,0x80,0x71,0x36,0x6C,0x19,
	0xE7,0x06,0x6B,0x6E,0x76,0x1B,0xD4,0xFE,0xE0,0x2B,0xD3,0x89,0x5A,0x7A,0xDA,0x10,
	0xCC,0x4A,0xDD,0x67,0x6F,0xDF,0xB9,0xF9,0xF9,0xEF,0xBE,0x8E,0x43,0xBE,0xB7,0x17,
	0xD5,0x8E,0xB0,0x60,0xE8,0xA3,0xD6,0xD6,0x7E,0x93,0xD1,0xA1,0xC4,0xC2,0xD8,0x38,
	0x52,0xF2,0xDF,0x4F,0xF1,0x67,0xBB,0xD1,0x67,0x57,0xBC,0xA6,0xDD,0x06,0xB5,0x3F,
	0x4B,0x36,0xB2,0x48,0xDA,0x2B,0x0D,0xD8,0x4C,0x1B,0x0A,0xAF,0xF6,0x4A,0x03,0x36,
	0x60,0x7A,0x04,0x41,0xC3,0xEF,0x60,0xDF,0x55,0xDF,0x67,0xA8,0xEF,0x8E,0x6E,0x31,
	0x79,0xBE,0x69,0x46,0x8C,0xB3,0x61,0xCB,0x1A,0x83,0x66,0xBC,0xA0,0xD2,0x6F,0x25,
	0x36,0xE2,0x68,0x52,0x95,0x77,0x0C,0xCC,0x03,0x47,0x0B,0xBB,0xB9,0x16,0x02,0x22,
	0x2F,0x26,0x05,0x55,0xBE,0x3B,0xBA,0xC5,0x28,0x0B,0xBD,0xB2,0x92,0x5A,0xB4,0x2B,
	0x04,0x6A,0xB3,0x5C,0xA7,0xFF,0xD7,0xC2,0x31,0xCF,0xD0,0xB5,0x8B,0x9E,0xD9,0x2C,
	0x1D,0xAE,0xDE,0x5B,0xB0,0xC2,0x64,0x9B,0x26,0xF2,0x63,0xEC,0x9C,0xA3,0x6A,0x75,
	0x0A,0x93,0x6D,0x02,0xA9,0x06,0x09,0x9C,0x3F,0x36,0x0E,0xEB,0x85,0x67,0x07,0x72,
	0x13,0x57,0x00,0x05,0x82,0x4A,0xBF,0x95,0x14,0x7A,0xB8,0xE2,0xAE,0x2B,0xB1,0x7B,
	0x38,0x1B,0xB6,0x0C,0x9B,0x8E,0xD2,0x92,0x0D,0xBE,0xD5,0xE5,0xB7,0xEF,0xDC,0x7C,
	0x21,0xDF,0xDB,0x0B,0xD4,0xD2,0xD3,0x86,0x42,0xE2,0xD4,0xF1,0xF8,0xB3,0xDD,0x68,
	0x6E,0x83,0xDA,0x1F,0xCD,0x16,0xBE,0x81,0x5B,0x26,0xB9,0xF6,0xE1,0x77,0xB0,0x6F,
	0x77,0x47,0xB7,0x18,0xE6,0x5A,0x08,0x88,0x70,0x6A,0x0F,0xFF,0xCA,0x3B,0x06,0x66,
	0x5C,0x0B,0x01,0x11,0xFF,0x9E,0x65,0x8F,0x69,0xAE,0x62,0xF8,0xD3,0xFF,0x6B,0x61,
	0x45,0xCF,0x6C,0x16,0x78,0xE2,0x0A,0xA0,0xEE,0xD2,0x0D,0xD7,0x54,0x83,0x04,0x4E,
	0xC2,0xB3,0x03,0x39,0x61,0x26,0x67,0xA7,0xF7,0x16,0x60,0xD0,0x4D,0x47,0x69,0x49,
	0xDB,0x77,0x6E,0x3E,0x4A,0x6A,0xD1,0xAE,0xDC,0x5A,0xD6,0xD9,0x66,0x0B,0xDF,0x40,
	0xF0,0x3B,0xD8,0x37,0x53,0xAE,0xBC,0xA9,0xC5,0x9E,0xBB,0xDE,0x7F,0xCF,0xB2,0x47,
	0xE9,0xFF,0xB5,0x30,0x1C,0xF2,0xBD,0xBD,0x8A,0xC2,0xBA,0xCA,0x30,0x93,0xB3,0x53,
	0xA6,0xA3,0xB4,0x24,0x05,0x36,0xD0,0xBA,0x93,0x06,0xD7,0xCD,0x29,0x57,0xDE,0x54,
	0xBF,0x67,0xD9,0x23,0x2E,0x7A,0x66,0xB3,0xB8,0x4A,0x61,0xC4,0x02,0x1B,0x68,0x5D,
	0x94,0x2B,0x6F,0x2A,0x37,0xBE,0x0B,0xB4,0xA1,0x8E,0x0C,0xC3,0x1B,0xDF,0x05,0x5A,
	0x8D,0xEF,0x02,0x2D );

	my @mini_key = ( 0x38, 0x59, 0x00, 0x00 );
	my @container;
	my $final_packet;

	# Undef Packet ID
	($msg[0], $msg[1]) = 0x00;

	# First Phase (19th - 47th byte)
	for (my $i = 0; $i < 47; $i++) {
		if ($counter == 4) { $counter = 0; }
		$encrypted_packet[$i + 20] = (($msg[$i] ^ $i) ^ $mini_key[$counter]) ^ 0x3F;
		$counter++;
	}

	# Second Phase (5th - 8th byte)
	for (my $i = 0; $i < 59; $i++) {
		$hex_indexer = (($encrypted_packet[$i + 8] ^ ($temporary_calc & 0xFF)) * 4);

		for (my $b = 0; $b < 4; $b++) {
			$container[$b] = $key[$hex_indexer + $b];
		}

		my $dword = ($container[3]) << 24 | ($container[2]) << 16 | ($container[1]) << 8 | ($container[0]);
		$temporary_calc = $dword ^ ($temporary_calc >> 8);
	}

	$container[0] = $temporary_calc & 0xFF;
	$container[1] = (($temporary_calc >> 8) & 0xFF);
	$container[2] = (($temporary_calc >> 16) & 0xFF);
	$container[3] = (($temporary_calc >> 24) & 0xFF);

	for (my	 $i = 0; $i < 4; $i++) {
		$encrypted_packet[$i + 4] = $container[$i];
	}

	for(my $i = 0; $i < scalar @encrypted_packet; $i++) {
		$final_packet .= pack("C*", $encrypted_packet[$i]);
	}

	return $final_packet;
}

1;