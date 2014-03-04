#!/usr/bin/env ruby
# encoding: utf-8
# contacts icon found at: http://www.iconarchive.com/show/circle-icons-by-martz90/contacts-icon.html
# contacts icon artist: Martz90
# contacts license: CC Attribution-Noncommercial-No Derivate 3.0

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require "net-ldap"

#TODO: Use alfred to set user/password/host/port/base/base_filter/encryption
#TODO: Search by displayname, samaccountname, email
#TODO: Gracefully fail if LDAP settings are incorrect

USER = "REPLACE_ME"
PASSWORD = "REPLACE_ME"

HOST = "REPLACE_ME"
PORT = "REPLACE_ME"
BASE = "REPLACE_ME"
BASE_FILTER = '(objectClass=user)(objectCategory=person)'
ENCRYPTION = :simple_tls
SIZE = 10
ATTRS_MAP = { :mail => :email,
              :title =>  :title,
              :department => :department,
              :l => :location,
              :st => :state,
              :c => :country,
              :telephonenumber => :phone,
              :manager => :manager,
              :displayname => :name}
ATTR_ORDER = [:mail,
              :title,
              :department,
              :l,
              :st, 
              :c, 
              :telephonenumber, 
              :manager,
              :displayname]

def export (fb, title, subtitle, arg)
  fb.add_item({
    :uid      => ""             ,   
    :title    => title          ,   
    :subtitle => subtitle       ,   
    :arg      => arg            ,
    :valid    => "yes"          ,   
  })
end

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback
  q = ARGV[0]

  if q.nil? or q.length > 3
    ldap = Net::LDAP.new(:host => HOST, :port => PORT, :encryption => ENCRYPTION)
    ldap.auth USER, PASSWORD
    filter = Net::LDAP::Filter.construct("(&#{BASE_FILTER}(samaccountname=#{q}))")
    ldap.search(:base => BASE, :filter => filter, :attributes => ATTRS_MAP.keys, :size => SIZE) do |entry|
      ATTR_ORDER.each do |attr|
        if attr == :manager
          begin
            mgr = entry[attr].to_s.split(",")[0].split("=")[1]
          rescue
            export(fb, "No Manager Found", "#{ATTRS_MAP[attr]}", "")
          end
          export(fb, "#{mgr}", "#{ATTRS_MAP[attr]}", "#{mgr}")
        else
          export(fb, "#{entry[attr]}", "#{ATTRS_MAP[attr]}", "#{entry[attr]}")
        end
      end 
    end 
  else
    export(fb, "Usage: ldap <sAMAccountName>", "sAMAccountName must be atleast 4 characters", "argument?")
  end

  puts fb.to_xml
end
