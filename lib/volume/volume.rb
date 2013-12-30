require 'subexec'

class Miaoyun::Gluster::Volume

  @@gluster_bin = "/usr/sbin/gluster"

  def self.init(opts)
    @@gluster_bin = opts[:gluster_bin] if opts[:gluster_bin]
  end

  def self.start(volname, force=false, timeout=120)
    cmd = "echo y | #{@@gluster_bin} volume start #{volname} #{force ? 'force' : ''}"
    sub = Subexec.run cmd, :timeout => timeout
    if sub.exitstatus != 0
      return true if sub.exitstatus == 255 and sub.output =~ /already started/
      raise Miaoyun::Gluster::CommonError, "Failed to start volume #{volname} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.stop(volname, force=false, timeout=120)
    cmd = "echo y | #{@@gluster_bin} volume stop #{volname} #{force ? 'force' : ''}"
    sub = Subexec.run cmd, :timeout => timeout
    if sub.exitstatus != 0
      return true if sub.exitstatus == 255 and sub.output =~ /is not in the started state/
      raise Miaoyun::Gluster::CommonError, "Failed to stop volume #{volname} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.set_option(volume, key, value, timeout=600)
    raise Miaoyun::Gluster::CommonError, "Should specify gluster option #{key} = #{value}" unless key && value
    cmd ="#{@@gluster_bin} volume set #{volume} #{key} #{value}"
    sub = Subexec.run cmd, :timeout => timeout
    unless sub.exitstatus == 0
      raise Miaoyun::Gluster::CommonError, "Failed to set gluster option #{key} = #{value} of volume #{volume} for #{sub.output}  with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.enable_quota(volume, path="/", timeout=240)
    cmd = "#{@@gluster_bin} volume quota #{volume} enable"
    sub = Subexec.run cmd, :timeout => timeout
    unless sub.output =~ /Enabling quota has been successful/ or sub.output =~ /Quota is already enabled/
      raise Miaoyun::Gluster::CommonError, "Failed to enable quota for volume #{volume} path #{path} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.set_quota(volume, quota_value, path="/", timeout=600)
    enable_quota(volume, path, timeout)
    cmd = "#{@@gluster_bin} volume quota #{volume} limit-usage #{path} #{quota_value}"
    sub = Subexec.run cmd, :timeout => timeout
    unless sub.output =~ /limit set on #{path}/
      raise Miaoyun::gluster::CommonError, "Failed to set quota for voluem #{volume} path #{path} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.create(options, timeout=240)
    brickdiv = 1
    volname = options[:name]
    unless volname && volname.class == String && volname.chars.count > 0
      raise Miaoyun::Gluster::CommonError, "Name should be provided"
    end

    bricks = options[:bricks] || []
    unless bricks.class == Array && bricks.size > 0
      raise Miaoyun::Gluster::CommonError, "Bricks should not be empty"
    end

    transport = options[:transport] || "tcp"
    unless ["tcp","rdma","tcp,rdma","rdma,tcp"].include? transport
      raise Miaoyun::Gluster::CommonError, "Not supported transport type #{transport}"
    end

    cmd = "#{@@gluster_bin} volume create #{volname} "

    stripe = options[:stripe]
    if stripe
      brickdiv = stripe.to_i
      cmd += "stripe #{stripe.to_i} "
    end

    replica = options[:replica]
    if replica
      brickdiv = brickdiv * replica.to_i
      cmd += "replica #{replica.to_i} "
    end

    unless bricks.size % brickdiv == 0
      raise Miaoyun::Gluster::CommonError, "Brick number should be multiple of #{brickdiv}"
    end

    cmd += "transport #{transport} "

    bricks.each do |brick|
      cmd +="#{brick} "
    end

    puts "cmd is #{cmd}"

    sub = Subexec.run cmd, :timeout => timeout
    puts "#{sub.exitstatus}"
    if sub.exitstatus != 0
      raise Miaoyun::Gluster::CommonError, "Failed to create the volume #{volname} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  rescue => e
    raise Miaoyun::Gluster::CommonError, "Failed to create a volume for #{e.message} - #{e.backtrace.join("|")}"
  end

  def self.delete(volname, force=false, timeout=120)
    ret = stop(volname, force, timeout)
    if ret
      cmd = "echo y | #{@@gluster_bin} volume delete #{volname}"
      sub = Subexec.run cmd, :timeout => timeout
      if sub.exitstatus != 0
        raise Miaoyun::Gluster::CommonError, "Failed to delete the volume #{volname} for #{sub.output} with exit code #{sub.exitstatus}"
      end
    else
      raise Miaoyun::Gluster::CommonError, "Failed to stop the volume #{volname} first to delete"
    end
  rescue => e
    raise Miaoyun::Gluster::CommonError, "Failed to delete the volume #{volname} for #{e.message} - #{e.backtrace.join("|")}"
  end

  def self.list()
    volumes = []
    cmd = "#{@@gluster_bin} volume list"
    begin
      sub = Subexec.run cmd, :timeout => 10
      if sub.exitstatus == 0
        volumes += sub.output.split("\n")
      else
        raise Miaoyun::Gluster::CommonError, "Failed to get list of volumes for #{sub.output} with exit code #{sub.exitstatus}"
      end
    rescue => e
        raise Miaoyun::Gluster::CommonError, "Failed to get list of volumes for #{e.message} - #{e.backtrace.join("|")}"
    end
    volumes
  end

  def self.info(volname="all", timeout = 10)
    volumes = {}
    cmd = "#{@@gluster_bin} volume info #{volname}"
    begin
        sub = Subexec.run cmd, :timeout => 10
        if sub.exitstatus == 0
          response =  sub.output
          tmp_volname = volname
          sub.output.split("\n").each do |line|
            case line
            when /Volume Name: (.+)/
                tmp_volname = $1
                volumes[tmp_volname] = {"bricks" => [], "options" => {}}
            when /Type: (.+)/
                volumes[tmp_volname]["type"] = $1
            when /Status: (.+)/
                volumes[tmp_volname]["status"] = $1
            when /Transport-type: (.+)/
                volumes[tmp_volname]["transport"] = $1
            when /Brick[1-9][0-9]*: (.+)/
                volumes[tmp_volname]["bricks"] << $1
            when /^([-.a-z]+: .+)$/
                optk, optv = $1.split(": ")
                volumes[tmp_volname]["options"][optk] = optv
            end
          end
        else
          if /Volume test does not exist/.match(sub.output)
            raise Miaoyun::Gluster::NotFoundError.new
          else
            raise Miaoyun::Gluster::CommonError, "Failed to get information of #{volname} volume for #{sub.output} with exit code #{sub.exitstatus}"
          end
        end
    rescue => e
      raise Miaoyun::Gluster::CommonError, "Failed to get information of #{volname} volume for #{e.message} - #{e.backtrace.join("|")}"
    end
     volumes
  end
end
