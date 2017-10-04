import zmq

context = zmq.Context()

# create socket to talk with server
print 'Connecting to hello world server...'
socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

# Create 10 request/reply pairs
for request in range(10):
	print('Sending request %s...' % request)
	socket.send(b"Hello")

	message = socket.recv()
	print('Received reply %s [%s]' % (request, message))
