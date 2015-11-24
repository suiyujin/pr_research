require 'cgi'
require File.expand_path(File.dirname(__FILE__)).sub(/web_community/, 'new') + '/common'

class Node
  include Common

  attr_accessor :id, :url, :url_hash

  def initialize(url)
    @url = url.include?('%3A%2F%2F') ? url : encode_url(url)
    @url_hash = get_hash_from_url(url)
  end

  def encode_url(url)
    url.include?('%3A%2F%2F') ? url : CGI.escape(url)
  end

  def decode_url(url)
    url.include?('%3A%2F%2F') ? CGI.unescape(url) : url
  end

  def get_url_from_hash(hash)
    result = MY.query("
      SELECT url
      FROM urls
      WHERE url_hash = '#{hash}';
             ").fetch_row
    result.nil? ? nil : result[0]
  end

  def get_hash_from_url(url)
    en_url = url.include?('%3A%2F%2F') ? url : encode_url(url)
    result = MY.query("
      SELECT url_hash
      FROM urls
      WHERE url = '#{en_url}';
             ").fetch_row
    result.nil? ? nil : result[0]
  end
end
