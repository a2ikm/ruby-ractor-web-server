require "socket"

CORES = %x{sysctl -n hw.ncpu}.chomp.to_i

def create_worker(pipe)
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
    rescue => e
      sock.close if sock && !sock.closed?
      raise
    end
  end
end

def create_listener(pipe)
  Ractor.new(pipe) do |pipe|
    server = TCPServer.new(8080)
    loop do
      sock = server.accept
      pipe.send(sock, move: true)
    end
  rescue => e
    server.shutdown
    raise
  end
end

pipe = Ractor.new do
  loop do
    Ractor.yield(Ractor.receive, move:true)
  end
end

workers = CORES.times.map { create_worker(pipe) }
listener = create_listener(pipe)

loop do
  Ractor.select(listener, *workers)
rescue Ractor::RemoteError => e
  if workers.include?(e.ractor)
    $stderr.puts "recreating worker"
    workers.delete(e.ractor)
    workers << create_worker(pipe)
  elsif listener == e.ractor
    $stderr.puts "recreating listener"
    listener = create_listerner(pipe)
  else
    raise "unknown ractor dead"
  end
  retry
end
