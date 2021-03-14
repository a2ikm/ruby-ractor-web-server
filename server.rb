require "socket"

CORES = %x{sysctl -n hw.ncpu}.chomp.to_i

pipe = Ractor.new do
  loop do
    Ractor.yield(Ractor.receive, move:true)
  end
end

workers = CORES.times.map do
  Ractor.new(pipe) do |pipe|
    loop do
      sock = pipe.take

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

server = TCPServer.new(8080)
loop do
  sock = server.accept
  pipe.send(sock, move: true)
end
