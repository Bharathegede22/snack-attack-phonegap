backend default {
  .host = "localhost";
  .port = "3000";
  .first_byte_timeout = 300s;
}

# Handling of requests that are received from clients.
# First decide whether or not to lookup data in the cache.
sub vcl_recv {
	
	# Pipe requests for zoomcaradmin.com
  if (req.http.host ~ "(www\.)?zoomcaradmin\.com") {
     return(pipe);
  }
  
  # Pipe requests that are non-RFC2616 or CONNECT which is weird.
  if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
    return(pipe);
  }
	
	# Pipe requests for assets, users, search & bookings
  if (req.url ~ "^/assets/*" || req.url ~ "^/users/*" || req.url ~ "^/search/*" || req.url ~ "^/bookings/*" || req.url ~ "^/admin/*") {
    return(pipe);
  }
  
  if (req.request != "GET" && req.request != "HEAD") {
    /* We only deal with GET and HEAD by default */
    return(pass);
  }

  if (req.backend.healthy) {
     set req.grace = 30s;
  } else {
     set req.grace = 1h;
  }

  # Handle compression correctly. Varnish treats headers literally, not
  # semantically. So it is very well possible that there are cache misses
  # because the headers sent by different browsers aren't the same.
  # @see: http://varnish.projects.linpro.no/wiki/FAQ/Compression
  if (req.http.Accept-Encoding) {
    if (req.http.Accept-Encoding ~ "gzip") {
      # if the browser supports it, we'll use gzip
      set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
      # next, try deflate if it is supported
      set req.http.Accept-Encoding = "deflate";
    } else {
      # unknown algorithm. Probably junk, remove it
      remove req.http.Accept-Encoding;
    }
  }
	
	# Stripping cookies etc
  unset req.http.cookie;
  unset req.http.authorization;
  unset req.http.If-None-Match;

  return(lookup);
}

# Called when entering pipe mode
sub vcl_pipe {
  # If we don't set the Connection: close header, any following
  # requests from the client will also be piped through and
  # left untouched by varnish. We don't want that.
  set req.http.connection = "close";
  #set bereq.http.connection = "close";
  #if (req.http.X-Forwarded-For) {
  #  set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
  #} else {
  #  set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
  #}
  return(pipe);
}

#sub vcl_pass {
#  set bereq.http.connection = "close";
#  if (req.http.X-Forwarded-For) {
#    set bereq.http.X-Forwarded-For = req.http.X-Forwarded-For;
#  } else {
#    set bereq.http.X-Forwarded-For = regsub(client.ip, ":.*", "");
#  }
#  return(pass);
#}

# Called when the requested object has been retrieved from the
# backend, or the request to the backend has failed
sub vcl_fetch {
  # Set the grace time
  set beresp.grace = 1h;
	
  # Do not cache the object if the status is not in the 200s
  if (beresp.status >= 300) {
    return(hit_for_pass);
  }
	
	if (req.url ~ "^/jsi/*") {
		if (req.url ~ "\.(png|gif|jpg|swf|css|js)$") {
		} else if (req.url ~ "autoComplete.do$") {
			unset beresp.http.expires;
			set beresp.ttl = 1d;
		}
  } else {
  	# Do not cache the object if the backend application does not want us to.
		if (beresp.http.Cache-Control ~ "(no-cache|no-store|private|must-revalidate)") {
		  return(hit_for_pass);
		}
  }
  
  set beresp.do_esi = true;
  unset beresp.http.set-cookie;
  unset beresp.http.Etag;
  return(deliver);
}

# Called before the response is sent back to the client
sub vcl_deliver {
	if (req.url ~ "^/jsi/*" && req.url ~ "\.(png|gif|jpg|swf|css|js)$") {
		set resp.http.Cache-Control = "max-age=86400";
	} else {
		# Force browsers and intermediary caches to always check back with us
		set resp.http.Cache-Control = "private, max-age=0";
		set resp.http.Pragma = "no-cache";

		# Add a header to indicate a cache HIT/MISS
		if (obj.hits > 0) {
		  set resp.http.X-Cache = "HIT";
		} else {
		  set resp.http.X-Cache = "MISS";
		}
	}
}
