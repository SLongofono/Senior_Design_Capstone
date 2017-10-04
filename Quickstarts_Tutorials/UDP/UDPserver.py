"""
SL 2017

server_UDP.py

This file demonstrates a simple UDP server which accepts strings and returns
the string with all lowercase characters replaced by their uppercase
characters.

Usage:

    python server_UDP.py -P <Port to listen on>
    
"""

import socket
import argparse

# Converts string argument to their uppercase representation
def convert(myStr):
    if(type(myStr) != str):
        return str(myStr).upper()
    return myStr.upper()

def print_address_port(a,b):
    print("\tIP Address {}\n\tPort {}\n".format(a,b))

BUFLEN = 2048

parser = argparse.ArgumentParser()
parser.add_argument('--port', '-P', type=int, help='The desired port to listen on', required=True)

args = parser.parse_args()

PORT = args.port

try:
    # Set up connection, use internet protocol and datagrams (UDP)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('', PORT))
    print("Local socket created")
    print("Press Ctrl-C to quit")


    while True:
        # Grab up to BUFLEN bytes from the connection
        payload, address = sock.recvfrom(BUFLEN)

        if payload:
            print("Local details:\n")
            localaddr, localport = sock.getsockname()
            print_address_port(localaddr, localport)

            print("Received {} from a client...".format(payload)
            print("Remote details:\n")
            print_address_port(address[0], address[1])

            # Send back the altered text
            # We can't use the same port we are listening on, since it will
            # create an endless loop.  Instead, we simply send it to the
            # address we received the message from, and let the other end
            # decide what to do with it.
            sock.sendto(convert(payload), address)

except KeyboardInterrupt:
    # Handle intentional quit gracefully
    print("\n\nQuitting...")
