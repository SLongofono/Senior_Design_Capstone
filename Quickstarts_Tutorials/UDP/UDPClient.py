"""
SL 2017

client_UDP.py

This file demonstrates a simple UDP client which sends data to a remote server
and gathers the reply.

Usage:

    python client_UDP.py -A <IP Address of the remote server> -P <Desired port on the remote server>
    
"""

import socket
import argparse

# Trims input to expected maximum size
def trim(myStr):
    if len(myStr) > 2048:
        print("Your input was larger than the maximum of {} bytes and has been truncated to fit.".format(BUFLEN))
        return myStr[:2048-len(myStr)]
    return myStr

def print_address_port(a,b):
    print("\tIP Address {}\n\tPort {}\n".format(a,b))

BUFLEN = 2048

parser = argparse.ArgumentParser()
parser.add_argument('--port', '-P', type=int, help='The desired port to communicate with on the remote server', required=True)
parser.add_argument('--address', '-A', type=str, help='The IP address of the remote server to connect to', required=True)

args = parser.parse_args()

PORT = args.port
SERVER_ADDR = args.address

try:
    # Establish a UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print("Local socket created")
    print("Press Ctrl-C to quit")
 
    while True:
        
        raw = raw_input("Please enter the statement: ")

        # Send the user's input through the socket TCP connection
        sock.sendto(trim(raw), (SERVER_ADDR, PORT))

        print("Sent message to remote server")

        # Use built-in functions to determine what port we ended up using
        print("Local details:\n")
        print(sock.getsockname())
        localaddr, localport = sock.getsockname()
        print_address_port(localaddr, localport)

        
        # Grab up to BUFLEN bytes from the connection reply
        # In this case, we don't specify the port, we simply look for any
        # response.  This doesn't seem safe.
        payload, address = sock.recvfrom(BUFLEN)
        if None != payload:
            print("Return text from the server: {}".format(payload))
            print("Remote server details:\n")
            print_address_port(address, PORT)

except KeyboardInterrupt:
    # Handle intentional quit gracefully
    print("\n\nQuitting...")
