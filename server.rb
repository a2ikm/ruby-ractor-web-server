require "socket"
server = TCPServer.new(8080)

while sock = server.accept
  request = sock.gets
  puts request

  sock.print "HTTP/1.1 200\r\n"
  sock.print "Content-Type: text/html\r\n"
  sock.print "\r\n"
  sock.print "Hello world! The time is #{Time.now}"

  sock.close
end
