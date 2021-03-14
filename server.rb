require "socket"
server = TCPServer.new(8080)

CORES = %x{sysctl -n hw.ncpu}.chomp.to_i

workers = CORES.times.map do
  Ractor.new do
    loop do
      sock = Ractor.recv

      request = sock.gets
      puts request

      sock.print "HTTP/1.1 200\r\n"
      sock.print "Content-Type: text/html\r\n"
      sock.print "\r\n"
      sock.print "Hello world! The time is #{Time.now}"

      sock.close
    end
  end
end

loop do
  sock = server.accept
  workers.sample.send(sock, move: true)
end
