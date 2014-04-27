user www-data;
worker_processes auto;
pid /var/run/nginx.pid;

# only log critical errors
error_log /var/log/nginx/error.log crit

# provides the configuration file context in which the directives that affect connection processing are specified.

events {
  worker_connections 768;
  
  # optmized to serve many clients with each thread, essential for linux
  use epoll;
  
  # accept as many connections as possible, may flood worker connections if set too low
  # multi_accept on;
}

# cache informations about FDs, frequently accessed files
# can boost performance, but you need to test those values
open_file_cache max=200000 inactive=20s; 
open_file_cache_valid 30s; 
open_file_cache_min_uses 2;
open_file_cache_errors on;

# to boost IO on HDD we can disable access logs
access_log off;

# copies data between one FD and other from within the kernel
# faster then read() + write()
sendfile on;

# send headers in one peace, its better then sending them one by one 
tcp_nopush on;

# don't buffer data sent, good for small data bursts in real time
tcp_nodelay on;

# server will close connection after this time
keepalive_timeout 30;

# number of requests client can make over keep-alive -- for testing
keepalive_requests 100000;

# allow the server to close connection on non responding client, this will free up memory
reset_timedout_connection on;

# request timed out -- default 60
client_body_timeout 30;

# if client stop responding, free up memory -- default 60
send_timeout 10;

http {

  types_hash_max_size 2048;

  # http://tautt.com/best-nginx-configuration-for-security/
  #########################################################
  
  #don't send the nginx version number in error pages and Server header
  server_tokens off;
   
  # config to don't allow the browser to render the page inside an frame or iframe
  # and avoid clickjacking http://en.wikipedia.org/wiki/Clickjacking
  # if you need to allow [i]frames, you can use SAMEORIGIN or even set an uri with ALLOW-FROM uri
  # https://developer.mozilla.org/en-US/docs/HTTP/X-Frame-Options
  add_header X-Frame-Options SAMEORIGIN;
   
  # when serving user-supplied content, include a X-Content-Type-Options: nosniff header along with the Content-Type: header,
  # to disable content-type sniffing on some browsers.
  # https://www.owasp.org/index.php/List_of_useful_HTTP_headers
  # currently suppoorted in IE > 8 http://blogs.msdn.com/b/ie/archive/2008/09/02/ie8-security-part-vi-beta-2-update.aspx
  # http://msdn.microsoft.com/en-us/library/ie/gg622941(v=vs.85).aspx
  # 'soon' on Firefox https://bugzilla.mozilla.org/show_bug.cgi?id=471020
  add_header X-Content-Type-Options nosniff;
   
  # This header enables the Cross-site scripting (XSS) filter built into most recent web browsers.
  # It's usually enabled by default anyway, so the role of this header is to re-enable the filter for 
  # this particular website if it was disabled by the user.
  # https://www.owasp.org/index.php/List_of_useful_HTTP_headers
  add_header X-XSS-Protection "1; mode=block";
   
  # Simple DDoS Defense
  #####################

  # limit the number of connections per single IP
  limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

  # limit the number of requests for a given session
  limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;

  # zone which we want to limit by upper values, we want limit whole server
  server {
      limit_conn conn_limit_per_ip 10;
      limit_req zone=req_limit_per_ip burst=10 nodelay;
  }

  # if the request body size is more than the buffer size, then the entire (or partial) request body is written into a temporary file
  client_body_buffer_size  128k;

  # headerbuffer size for the request header from client, its set for testing purpose
  client_header_buffer_size 3m;

  # maximum number and size of buffers for large headers to read from client request
  large_client_header_buffers 4 256k;

  # read timeout for the request body from client, its set for testing purpose
  client_body_timeout   3m;

  # how long to wait for the client to send a request header, its set for testing purpose
  client_header_timeout 3m;

  # server_names_hash_bucket_size 64;
  # server_name_in_redirect off;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  ##
  # Logging Settings
  ##

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  ##
  # Gzip Settings
  ##

  # reduce the data that needs to be sent over network
  gzip on;
  gzip_min_length 10240;
  gzip_proxied expired no-cache no-store private auth;
  gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
  gzip_disable "MSIE [1-6]\.";

  ##
  # Virtual Host Configs
  ##

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
