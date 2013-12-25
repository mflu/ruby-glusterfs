
module Miaoyun
  module Gluster
    class CommonError < Exception
    end

    class VolumeNotFoundError < CommonError
    end
  end
end
