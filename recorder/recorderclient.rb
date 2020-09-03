#
# Simple client app to control the riteclubrecorder server from the command
# line.
#

require 'optparse'
require 'socket'

$stdout.sync = true
$stderr.sync = true

PROGNAME = File.basename($0)

class App
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 9876

  def initialize(**kwargs)
    @host = kwargs[:host] || DEFAULT_HOST
    @port = kwargs[:port] || DEFAULT_PORT
    @cmd = kwargs[:cmd].upcase
  end

  def main
    case @cmd
    when "START", "STOP", "QUIT"
      msg = @cmd
    else
      $stderr.puts("FATAL: unknown command #{@cmd}")
      return 1
    end
    socket = TCPSocket.new(@host, @port)
    socket.sync = true
    socket.puts(@cmd)
    puts socket.gets.chomp
    socket.close
    return 0
  end
end

######### ########## ##########

host = nil
port = nil
cmd = nil

parser = OptionParser.new do |opts|
  opts.banner = "usage: #{PROGNAME} [options] START|STOP|QUIT"
  opts.on("-h", "--host HOST", "default: #{App::DEFAULT_HOST}") { |h| host = h }
  opts.on("-p", "--port PORT", "default: #{App::DEFAULT_PORT.to_s}") { |p| port = p.to_i }
end

parser.parse!(ARGV)

cmd = ARGV.shift

if not cmd
  $stderr.puts("FATAL: expected a command!")
  $stderr.puts(parser.to_s)
  exit 1
end

exit App.new(host: host, port: port, cmd: cmd).main
