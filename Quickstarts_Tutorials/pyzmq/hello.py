import time
import zmq

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind("tcp://*:5555")

while True:
	# block on request from a client
	message = socket.recv()
	print('Received request message : %s' % message)

	# do work son
	time.sleep(1)

	# Reply in byte format
	socket.send(b"World")
