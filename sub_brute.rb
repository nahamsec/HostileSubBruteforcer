#!/usr/bin/env ruby
require 'io/console'
require 'net/http'
require 'open-uri'
require 'resolv'
require 'socket'
require 'timeout'


=begin
###############################################
Pure subdomain bruteforcer:
Will check and see if host is pointing to AWS
Alrets if a subdomain returns 404 so you can
manually check and see if it's hosted on a
3rd party website and if they are registered
properly or not.

Author : Behrouz Sadeghipour
Email  : bensadeghi@gmail.chom
Twitter: @NahamSec
http:://github.com/nahamsec
###############################################
=end

class String
def black;          "\e[30m#{self}\e[0m" end
def red;            "\e[31m#{self}\e[0m" end
def green;          "\e[32m#{self}\e[0m" end
def brown;          "\e[33m#{self}\e[0m" end
def blue;           "\e[34m#{self}\e[0m" end
def magenta;        "\e[35m#{self}\e[0m" end
def cyan;           "\e[36m#{self}\e[0m" end
def brown;           "\e[37m#{self}\e[0m" end

def bg_black;       "\e[40m#{self}\e[0m" end
def bg_red;         "\e[41m#{self}\e[0m" end
def bg_green;       "\e[42m#{self}\e[0m" end
def bg_brown;       "\e[43m#{self}\e[0m" end
def bg_blue;        "\e[44m#{self}\e[0m" end
def bg_magenta;     "\e[45m#{self}\e[0m" end
def bg_cyan;        "\e[46m#{self}\e[0m" end
def bg_brown;        "\e[47m#{self}\e[0m" end

def bold;           "\e[1m#{self}\e[22m" end
def italic;         "\e[3m#{self}\e[23m" end
def underline;      "\e[4m#{self}\e[24m" end
def blink;          "\e[5m#{self}\e[25m" end
def reverse_color;  "\e[7m#{self}\e[27m" end
end

def host(get_host) #get cname data and check response code for 404 and alert user
  Resolv::DNS.open do |dns|
    res = dns.getresources get_host, Resolv::DNS::Resource::IN::CNAME
    if res.empty?
      break
    end

    heroku_error = "there is no app configured at that hostname".red.bold
    amazonAWS_error = "NoSuchBucket".red.bold
    squarespace_error = "No Such Account".red.bold
    github_error = "There isn't a GitHub Pages site here".red.bold
    shopify_error = "Sorry, this shop is currently unavailable.".red.bold
    tumblr_error = "There's nothing here.".red.bold
    wpengine_error = "The site you were looking for couldn't be found.".red.bold

    check_it = ""
    real_host = res.first.name.to_s
      check_real_host = "http://"+real_host
      check_it = Net::HTTP.get(URI.parse(check_real_host))
      if  (check_it.index("There is no app configured at that hostname"))
        puts "- Subdomain pointing to a non-existing Heroku app showing: ".red + heroku_error
      elsif (check_it.index("NoSuchBucket"))
        puts "- Subdomain pointing to an unclaimed AmazonAWS bucket showing: ".red + amazonAWS_error
      elsif (check_it.index("No Such Account"))
        puts "- Subdomain pointing to a non-existing SquareSpace account showing: ".red + squarespace_error
      elsif (check_it.index("You're Almost There"))
        puts "- Subdomain pointing to a non-existing SquareSpace account showing: ".red + squarespace_error
      elsif (check_it.index("There isn't a GitHub Pages site here"))
        puts "- Subdomain pointing to a non-existing Github subdomain indicating".red + github_error
      elsif (check_it.index("Sorry, this shop is currently unavailable."))
        puts "- Subdomain pointing to a non-existing Shopify subdomain indicating".red + shopify_error
      elsif (check_it.index("There's nothing here."))
        puts "- Subdomain pointing to a non-existing Tumblr subdomain indicating".red + tumblr_error
      elsif  (check_it.index("The site you were looking for couldn't be found."))
        puts "- Subdomain pointing to a non-existing WPEngine subdomain indicating".red + wpengine_error
      end
      #if (real_host = get_host)
      #else
        puts ("- Seems like " + get_host +  " is an alias for " + real_host).brown
      #end
  end
  return
end

def find_subs(targetURI)
      target = "http://"+targetURI
        begin
          #Timeout::timeout(600) {
            res = Net::HTTP.get_response(URI.parse(target))
            getCode = res.code
            ip_address = Resolv.getaddress targetURI
            if (getCode != "503")
              File.open("output.txt", "a") do |file|
                file.puts targetURI
              end
              puts  "[#{Time.now.asctime}] " + getCode + " " + targetURI.green + " ---> " + ip_address + " "
              host targetURI
            else
            end

            if getCode == "404"
              puts "----> Check for further information on where this is pointing to.".red
            end
          #}

        rescue Timeout::Error
        rescue Errno::EHOSTUNREACH
        rescue URI::InvalidURIError
        rescue SocketError
        rescue Errno::ECONNREFUSED
        rescue Resolv::ResolvError
        rescue Errno::ETIMEDOUT
        rescue Errno::ENETUNREACH
        end
#        recursiveBruteForce
end


def createURI(getURI)
  File.open("newlist", "r") do |f|
    f.each_line do |line|
      targetURI = line.chomp + "." + getURI
      find_subs targetURI
    end
  end
end



File.open("output.txt", "w")
system "clear"
puts "Enter a domain you'd like to brute force and look for hostile subdomain takeover(example: hackme.ltd)"
getURI = gets.chomp
createURI getURI

puts "\n\n\n\n\nStarting to bruteforce the subdomains using the same wordlist"
File.open("output.txt", "r").each do |ff|
  File.open("list.txt", "r").each do |f|
    ff.each_line do |domain|
    f.each_line do |line|
      targetURI = line.chomp + "." + domain.chomp
      find_subs targetURI
      end
    end
  end
end
