#
# riteclubrecorder
#
# This script implements a TCP server which acts as a front-end to starting
# and stopping a FFmpeg subprocess. We try to determine where Pyre's window
# is being displayed, and invoke FFmpeg to record its footage. It will keep
# recording until explicitly stopped.
#
# The idea is that the Rite Club Companion app will start and stop FFmpeg
# automatically, on the behalf of the player, when interesting events happen
# from within Pyre (namely, when a rite starts and when a rite ends). The
# Companion will rely on this script in order to communicate with FFmpeg.
#
# XXX Really should come up with a way to let the user tailor the video
# encoding settings... what video you're capable of highly depends on the
# player's specs.
#

require 'fileutils'
require 'optparse'
require 'rubygems'
require 'socket'

class App
  attr_accessor :ffmpeg
  attr_accessor :quiet
  attr_accessor :outdir

  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 9876
  DEFAULT_FFMPEG = "ffmpeg"
  WINDOWS_FLAVORS = ["windows", "mingw32"]

  def initialize(**kwargs)
    @host = kwargs[:host] || DEFAULT_HOST
    @port = kwargs[:port] || DEFAULT_PORT
    @platform = Gem::Platform.new(Gem::Platform::CURRENT).os
    @quiet = kwargs[:quiet]
    @ffmpeg = kwargs[:ffmpeg] || DEFAULT_FFMPEG
    @screen_no = kwargs[:screen_no] || 1
    @outdir = kwargs[:outdir] || Dir.pwd

    if self.windows?
      $stdout.sync = true
      $stderr.sync = true
    end
  end

  def windows?
    return WINDOWS_FLAVORS.include?(@platform)
  end

  # We create a new thread which will launch ffmpeg(1).
  def start_recording(outfile)
    @ffmpeg_pid = -1
    @ffmpeg_exitstatus = nil

    @capture_thread = Thread.new do
      v = @quiet ? "0" : "1"

      case @platform
      when "darwin"
        capture_cmd = [
          @ffmpeg, "-v", v, "-y", "-nostdin",
          "-f", "avfoundation", "-capture_cursor", "1", "-i", "#{@screen_no.to_s}:",
          "-s", "1280x720", "-codec:v", "libx264", "-preset", "ultrafast", outfile
        ]
      when *WINDOWS_FLAVORS
        capture_cmd = [
          @ffmpeg, "-v", v, "-y", "-nostdin",
          "-f", "gdigrab", "-draw_mouse", "1", "-i", "title=Pyre",
          "-f", "dshow", "-i", "audio=virtual-audio-capturer",
          "-s", "1280x720", "-codec:v", "libx264", "-preset", "ultrafast", outfile
        ]
      end

      @ffmpeg_pid = spawn(*capture_cmd)
      $stdout.puts("\t- FFMPEG_PID=#{@ffmpeg_pid}")
      $stdout.puts("\t- FFMPEG_CMD=#{capture_cmd.join(' ')}")
      _, @ffmpeg_exitstatus = Process.wait2(@ffmpeg_pid)

      $stdout.puts("\t- " + @ffmpeg_exitstatus.inspect)

      # Exit status 255 is normal for FFmpeg, apparently. Additionally, on
      # Windows, an exit status of 1 seems acceptable when using 'taskkill /f'.
      ok_options = [0, 255]
      ok_options << 1 if self.windows?
      if ok_options.include?(@ffmpeg_exitstatus.exitstatus)
        $stdout.puts("\t- OK (#{@ffmpeg_exitstatus.exitstatus})")
      else
        $stderr.puts("\t- ERROR: FFmpeg had an error! (#{@ffmpeg_exitstatus})")
      end
    end
  end

  def stop_recording
    # This only kills the FFmpeg process, it does NOT terminate the thread in which
    # it was spawned.
    if self.windows?
      system("taskkill /pid #{@ffmpeg_pid} /f")
    else
      Process.kill("INT", @ffmpeg_pid)
    end

    # So now let's really make sure the thread actually terminates.
    @capture_thread.join
    @capture_thread = nil
  end

  def main_loop
    $stdout.puts("******************************")
    $stdout.puts("*** Rite Club Video Server ***")
    $stdout.puts("******************************")
    $stdout.puts(">> PID #{Process.pid}")
    $stdout.puts(">> Using FFmpeg: #{@ffmpeg}")
    $stdout.puts(">> Video directory: #{@outdir}")
    $stdout.puts(">> Listening on #{@host}:#{@port.to_s}")
    @server = TCPServer.new(@host, @port)
    done = false

    until done
      client = @server.accept
      client.sync = true
      remote = client.remote_address
      $stdout.puts("CONNECTION from #{remote.ip_address}:#{remote.ip_port}")
      msg = client.gets.chomp
      case msg
      when "START"
        if @capture_thread
          client.puts("ALREADY STARTED")
        else
          container = "mkv"
          basename = "#{Time.now.strftime('%Y%m%d%H%M%S')}.#{container}"
          self.start_recording(File.join(@outdir, basename))
          client.puts("STARTING")
        end
      when "STOP"
        if @capture_thread
          self.stop_recording
          client.puts("STOPPING")
        else
          client.puts("WASNT ALREADY STARTED")
        end
      when "QUIT"
        if @capture_thread
          client.puts("STILL RECORDING")
        else
          done = true
          $stdout.puts("(quitting)")
          client.puts("QUITTING")
        end
      else
        client.puts("UNKNOWN COMMAND")
      end
      client.close
    end
  end
end

########## ########## ##########

ffmpeg = "ffmpeg"
screen_no = nil
quiet = false
outdir = nil

parser = OptionParser.new do |opts|
  opts.on("--video-dir PATH", "Directory to save videos") { |path| outdir = File.expand_path(path) }
  opts.on("--ffmpeg PATH") { |path| ffmpeg = File.expand_path(path) }
  opts.on("--screen N", "for AVFoundation") { |n| screen_no = n.to_i }
  opts.on("-q", "--quiet") { quiet = true }
end

parser.parse!(ARGV)

Thread.abort_on_exception = true

app = App.new(
  :quiet => quiet,
  :screen_no => screen_no,
  :outdir => outdir,
  :ffmpeg => ffmpeg,
)

app.main_loop 
