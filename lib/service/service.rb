require 'subexec'

class Miaoyun::Gluster::Service

  @@gluster_bin = "/usr/sbin/gluster"
  @@vols_dir = "/var/lib/glusterd/vols"

  def self.init(opts)
    @@gluster_bin = opts[:gluster_bin] if opts[:gluster_bin]
    @@vols_dir = opts[:vols_dir] if opt[:vols_dir]
  end

  def self.shutdown
    sub = Subexec.run "/etc/init.d/glusterd stop", :timeout => 20
    sub.exitstatus == 0
  end

  def self.start
    sub = Subexec.run "/etc/init.d/glusterd start", :timeout => 20
    sub.exitstatus == 0
  end

  def self.status()
    service = { "bricks" => {}, "glusterd" => "ok"}
    bricks = service["bricks"]
    begin
        sub = Subexec.run "/etc/init.d/glusterd status", :timeout => 10
        if sub.exitstatus == 0
           case sub.output
           when /is running/
            service["glusterd"] = "ok"
           when /is stopped/
            service["glusterd"] = "offline"
           else
            service["glusterd"] = "offline"
           end
        else
           service["glsuterd"] = "unknown"
        end

        vols = Dir.glob("#{@@vols_dir}/*").map do |d| d.split("/").last end
         vols.each do |vol|
           pidfile = Dir.glob("#{@@vols_dir}/#{vol}/run/*.pid").first
            if pidfile
               begin
               pid = File.read('pidfile').to_i
               begin
                Process.kill(0, pid)
                    bricks[vol] = "ok"
                rescue Errno::ESRCH
                   bricks[vol] = "offline"
                end
               rescue => e
                  bricks[vol] = "unknown"
               end
            else
               bricks[vol] = "unknown"
            end

         end
    rescue => e
      raise Miaoyun::Gluster::CommonError, "Failed to get status of all bricks in local node for #{e.message} - #{e.backtrace.join("\n")}"
    end
    service
  end
end
