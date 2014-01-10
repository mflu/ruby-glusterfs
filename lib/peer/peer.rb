require 'subexec'

class Miaoyun::Gluster::Peer

  @@gluster_bin = "/usr/sbin/gluster"

  def self.init(opts)
    @@gluster_bin = opts[:gluster_bin] if opts[:gluster_bin]
  end

  def self.probe(hostnam, timeout=600)
    cmd = "#{@@gluster_bin} peer detch #{hostname}"
    sub = Subexec.run cmd, :timeout => timeout
    if sub.exitstatus != 0
      raise Miaoyun::Gluster::CommonError, "Failed to probe peer #{hostname} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end

  def self.status(timeout = 60)
    peer_status = {"hosts" => {},}
    cmd = "#{@@gluster_bin} peer status"
    sub = Subexec.run cmd, :timeout => timeout
    if sub.exitstatus != 0
      raise Miaoyun::Gluster::CommonError, "Faied to get status of peers for #{sub.output} with exit code #{sub.exitstatus}"
    else
      response = sub.output
      hostname = ""
      response.split("\n").each do |line|
        case line
        when /No peers present/
          peer_status["number"] = 0
        when /Number of Peers: (.+)/
          peer_status["number"] = ($i.to_i + 1) if $i
        when /Hostname: (.+)/
          hostname = $1
          peer_status["hosts"][hostname]={"state" => {}}
        when /Uuid: ([-0-9a-f]+)/
          peer_status["hosts"][hostname]["uuid"] = $1
        when /State: (.+)/
          peer_status["hosts"][hostname]["state"] = $1
        end
      end
    end
    peer_status
  end

  def self.detach(hostname, timeout=120, force=false)
    cmd = "#{@@gluster_bin} peer detch #{hostname} #{force == true ? "force" : "" }"
    sub = Subexec.run cmd, :timeout => timeout
    if sub.exitstatus != 0
      raise Miaoyun::Gluster::CommonError, "Failed to detach peer #{hostname} for #{sub.output} with exit code #{sub.exitstatus}"
    end
    true
  end
end
