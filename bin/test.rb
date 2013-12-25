#!/usr/bin/env ruby
## -*- mode: ruby -*-
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)
require 'bundler/setup'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require "gluster"

puts Miaoyun::Gluster::Volume.list
puts Miaoyun::Gluster::Volume.info
puts Miaoyun::Gluster::Service.status

test_vol = 'ruby-glusterfs'

opts = {
  :replica => 2,
  :stripe => 2,
  :name => test_vol,
  :transport => 'tcp',
  :bricks => [
    'glusterfs-test-dev001.qiyi.virtual:/mnt/xfsd/ruby-glusterfs',
    'glusterfs-test-dev002.qiyi.virtual:/mnt/xfsd/ruby-glusterfs',
    'glusterfs-test-dev003.qiyi.virtual:/mnt/xfsd/ruby-glusterfs',
    'glusterfs-test-dev004.qiyi.virtual:/mnt/xfsd/ruby-glusterfs'
  ]
}

if Miaoyun::Gluster::Volume.list.include? test_vol
  print "It is very dangerous for you want to delete the volume #{test_vol}, continue [y|n]:"
  answer = gets
  if answer.strip.downcase == 'y'
    Miaoyun::Gluster::Volume.delete test_vol
  else
    puts "Will exit!"
    exit 0
  end
end

Miaoyun::Gluster::Volume.create(opts)
if Miaoyun::Gluster::Volume.list.include? test_vol
  puts "ruby-glusterfs created!"
end
Miaoyun::Gluster::Volume.start test_vol
puts "*************started****************"
Miaoyun::Gluster::Volume.stop test_vol
puts "*************stopped****************"
Miaoyun::Gluster::Volume.start test_vol
puts "*************stopped****************"
Miaoyun::Gluster::Volume.start test_vol
puts "*************started****************"
Miaoyun::Gluster::Volume.start test_vol
puts "*************started****************"
Miaoyun::Gluster::Volume.delete test_vol
