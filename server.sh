#!/bin/bash
# A basic web server which returns "Hello World"
# Inspiration from http://paulbuchheit.blogspot.co.uk/2007/04/webserver-in-bash.html

# Setup a named pipe to send responses to netcat
RESP=$(dirname $0)'/webresp'
[ -p $RESP ] || mkfifo $RESP

# Validate arguments
die () {
echo >&2 "$@"
exit 1
}
[ "$#" -ge 1 ] || die "Port required as first argument"
echo $1 | grep -E -q '^[0-9]+$' || die "Numeric port required, \"$1\" provided"

# Run nc to listen to incoming connections on the given port
echo "Running port on $1"
while true ; do
( cat $RESP ) | nc -l -p $1 | (

	# Get the path out of the first line of the request
	read REQ
	reqparts=( $REQ )
	path=${reqparts[1]}

	# Match the path
	case $path in
		/)	body="Hello World"
			status="200 OK"
			;;

		# If the path doesn't match, return a 404
		*)	body="No World"
			status="404 Not Found"
			echo "File $path Not Found" >&2
			;;
	esac

	# Output the response with the relevant headers
	cat >$RESP <<EOF
HTTP/1.0 $status
Content-Type: text/plain
Server: lucos_helloworld
Connection: Close
Content-Length: ${#body}

$body
EOF
)
done