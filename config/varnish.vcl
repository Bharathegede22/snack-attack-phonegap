backend default {
  .host = "localhost";
  .port = "3000";
  .first_byte_timeout = 300s;
}

# Handling of requests that are received from clients.
# First decide whether or not to lookup data in the cache.
sub vcl_recv {
	
	# Pipe requests for zoomcaradmin.com
  #if (req.http.host != "(www\.)?zoomcar\.com") {
  #   return(pipe);
  #}
  
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
  if (req.url ~ "^/assets/*" || 
    req.url ~ "^/users/*" || 
    req.url ~ "^/(delhi|bangalore|chennai|hyderabad|pune)/search" || 
    req.url ~ "^/(delhi|bangalore|chennai|hyderabad|pune)/bookings/*" || 
    req.url ~ "^/users/*" || 
    req.url ~ "^/bookings/*" || 
    req.url ~ "^/wallets/*" || 
    req.url ~ "^/signup/*" || 
    req.url ~ "^/calculator/*"
  ) {
    return(pipe);
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
	
  # This rule is to insert the client's ip address into the request header
  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }

  # Removing params
  set req.url = regsub(req.url, "\?.*", "");

	# Stripping cookies etc
  unset req.http.Cookie;
  unset req.http.Authorization;
  unset req.http.If-None-Match;

  return(lookup);
}

sub vcl_hit {
  if(req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

sub vcl_miss {
  if(req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}

# Called when entering pipe mode
sub vcl_pipe {
  # If we don't set the Connection: close header, any following
  # requests from the client will also be piped through and
  # left untouched by varnish. We don't want that.
  set req.http.connection = "close";
  return(pipe);
}

# Called when the requested object has been retrieved from the
# backend, or the request to the backend has failed
sub vcl_fetch {
  # Set the grace time
  set beresp.grace = 1h;
	
  # Do not cache the object if the status is not in the 200s
  if (beresp.status >= 300) {
    return(hit_for_pass);
  }
	
	# Do not cache the object if the backend application does not want us to.
	if (beresp.http.Cache-Control ~ "(no-cache|no-store|private|must-revalidate)") {
	  return(hit_for_pass);
	}
  
  set beresp.do_esi = true;
  unset beresp.http.Set-Cookie;
  unset beresp.http.Etag;
  return(deliver);
}

# Called before the response is sent back to the client
sub vcl_deliver {
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
