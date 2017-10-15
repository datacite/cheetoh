# Cheetoh

[![Build Status](https://travis-ci.org/datacite/cheetoh.svg?branch=test)](https://travis-ci.org/datacite/cheetoh)
[![Code Climate](https://codeclimate.com/github/datacite/cheetoh/badges/gpa.svg)](https://codeclimate.com/github/datacite/cheetoh)
[![Test Coverage](https://codeclimate.com/github/datacite/cheetoh/badges/coverage.svg)](https://codeclimate.com/github/datacite/cheetoh/coverage)

Rails web application for providing a compatibility API layer for the DataCite MDS API,
enabling [EZID API](https://ezid.cdlib.org/doc/apidoc.html) calls for DOI and
metadata registration. The application does not store any data internally.

## Documentation

The service tries to be as compatible as possible with the [EZID API](https://ezid.cdlib.org/doc/apidoc.html) as of September 2017. While we try to implement features added to the EZID service going forward, no guaranties are made doing so. Because of some fundamental differences between the services provided by EZID and DataCite, some functionalities make no sense as a DataCite service and have not been implemented, including

* Registration of identifiers other than DOIs, for example ARKs
* Crossref registration

Some features have not yet been implemented as of September 2017, but are planned for Q4 2017 or Q1 2018 (see [DataCite roadmap](https://www.datacite.org/roadmap.html) for details):

* Reserve a DOI
* Registration of metadata in other formats, e.g. Dublin Core

Requests for functionality of the EZID service not (yet) implemented will return appropriate error codes, e.g. a status `501 not implemented`.

The base URL of the service is `https://mds.datacite.org`.

### API vs. UI

The EZID-compatible API provided by DataCite is complemented by the user interface of the DOI Fabrica service available at [https://doi.datacite.org](https://doi.datacite.org). The UI can be used to manage registered DOIs, and to reset the password.

### Authentication

Most requests require authentication. The API supports HTTP Basic authentication. With this method, the client supplies HTTP Basic authentication credentials on every request. For example, credentials can be added manually in Python as follows:

```
import base64, urllib2
r = urllib2.Request("https://mds.datacite.org/...")
r.add_header("Authorization", "Basic " + base64.b64encode("username:password"))
```

But most programming libraries provide higher-level support for authentication. For example, Python provides HTTPBasicAuthHandler:

```
import urllib2
h = urllib2.HTTPBasicAuthHandler()
h.add_password("EZID", "https://mds.datacite.org/", "username", "password")
o = urllib2.build_opener(h)
o.open("https://mds.datacite.org/...")
```

The downside of using higher-level authentication mechanisms is that they often do not supply credentials initially, but only in response to a challenge from the service, thus doubling the number of HTTP transactions.

To manually provide credentials in Java, using Apache Commons Codec to do the Base64 encoding:

```
import java.net.*;
import org.apache.commons.codec.binary.*;

URL u = new URL("https://ezid.cdlib.org/...);
URLConnection c = u.openConnection();
c.setRequestProperty("Accept", "text/plain");
c.setRequestProperty("Authorization", "Basic " +
  new String(Base64.encodeBase64("username:password".getBytes())));
c.connect();
```

Java also provides an Authenticator class:

```
import java.net.*;

class MyAuthenticator extends Authenticator {
  protected PasswordAuthentication getPasswordAuthentication () {
    return new PasswordAuthentication("username", "password".toCharArray());
  }
}

Authenticator.setDefault(new MyAuthenticator());
```

If authentication is required and credentials are either missing or invalid, the service returns a 401 HTTP status code and the status line "error: unauthorized" (see [Error handling](#error-handling) below). If authentication is successful but the request is still not authorized, the service returns a 403 HTTP status code and the status line "error: forbidden".

### Request & response bodies

Request and response bodies are used to transmit identifier metadata. The HTTP content type for all bodies is "text/plain" using UTF-8 charset encoding. In request bodies, if no charset encoding is declared in the HTTP Content-Type header, it is assumed to be UTF-8.

The service's data model for metadata is a dictionary of element name/value pairs. The dictionary is single-valued: an element name may not be repeated. Names and values are strings. Leading and trailing whitespace in names and values is not significant. Neither element names nor element values may be empty. (When modifying an identifier, an uploaded empty value is treated as a command to delete the element entirely.)

Metadata dictionaries are serialized using a subset of [A Name-Value Language (ANVL)](https://confluence.ucop.edu/display/Curation/Anvl) rules:

* One element name/value pair per line.
* Names separated from values by colons.

For example:

```
who: Proust, Marcel
what: Remembrance of Things Past
when: 1922
```

In addition, two ANVL features may be used when uploading metadata to the service (but clients can safely assume that DataCite will never use these features when returning metadata):

* A line beginning with a number sign ("#", U+0023) is a comment and will be ignored.
* A line beginning with whitespace continues the previous line (the intervening line terminator and whitespace are converted to a single space).

For example:

```
# The following two elements are identical:
who: Proust,
  Marcel
who: Proust, Marcel
```

Care must be taken to escape structural characters that appear in element names and values, specifically, line terminators (both newlines ("\n", U+000A) and carriage returns ("\r", U+000D)) and, in element names, colons (":", U+003A). EZID employs percent-encoding as the escaping mechanism, and thus percent signs ("%", U+0025) must be escaped as well. In Python, a dictionary of Unicode metadata element names and values, metadata, is serialized into a UTF-8 encoded string, anvl, with the following code:

```
import re

def escape (s):
  return re.sub("[%:\r\n]", lambda c: "%%%02X" % ord(c.group(0)), s)

anvl = "\n".join("%s: %s" % (escape(name), escape(value)) for name,
  value in metadata.items()).encode("UTF-8")
```

Conversely, to parse a UTF-8 encoded string, anvl, producing a dictionary, metadata:

```
import re

def unescape (s):
  return re.sub("%([0-9A-Fa-f][0-9A-Fa-f])",
    lambda m: chr(int(m.group(1), 16)), s)

metadata = dict(tuple(unescape(v).strip() for v in l.split(":", 1)) \
  for l in anvl.decode("UTF-8").splitlines())
```

In Java, to serialize a HashMap of metadata element names and values, metadata, into an ANVL-formatted Unicode string, anvl:

```
import java.util.*;

String escape (String s) {
  return s.replace("%", "%25").replace("\n", "%0A").
    replace("\r", "%0D").replace(":", "%3A");
}

Iterator<Map.Entry<String, String>> i = metadata.entrySet().iterator();
StringBuffer b = new StringBuffer();
while (i.hasNext()) {
  Map.Entry<String, String> e = i.next();
  b.append(escape(e.getKey()) + ": " + escape(e.getValue()) + "\n");
}
String anvl = b.toString();
```

And conversely, to parse a Unicode ANVL-formatted string, anvl, producing a HashMap, metadata:

```
import java.util.*;

String unescape (String s) {
  StringBuffer b = new StringBuffer();
  int i;
  while ((i = s.indexOf("%")) >= 0) {
    b.append(s.substring(0, i));
    b.append((char) Integer.parseInt(s.substring(i+1, i+3), 16));
    s = s.substring(i+3);
  }
  b.append(s);
  return b.toString();
}

HashMap<String, String> metadata = new HashMap<String, String>();
for (String l : anvl.split("[\\r\\n]+")) {
  String[] kv = l.split(":", 2);
  metadata.put(unescape(kv[0]).trim(), unescape(kv[1]).trim());
}
```

The first line of an EZID response body is a status indicator consisting of "success" or "error", followed by a colon, followed by additional information. Two examples:

```
success: ark:/99999/fk4test
error: bad request - no such identifier
```

### Error handling

An error is indicated by both an HTTP status code and an error status line of the form "error: reason". For example:

```
⇒ GET /id/doi:/10.5072/bogus HTTP/1.1
⇒ Host: mds.datacite.org

⇐ HTTP/1.1 400 BAD REQUEST
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 39
⇐
⇐ error: bad request - no such identifier
```

Some programming libraries make it a little difficult to read the content following an error status code. For example, from Java, it is necessary to explicitly switch between the input and error streams based on the status code:

```
java.net.HttpURLConnection c;
java.io.InputStream s;
...
if (c.getResponseCode() < 400) {
  s = c.getInputStream();
} else {
  s = c.getErrorStream();
}
// read from s...
```

### Operation: get identifier metadata

Metadata can be retrieved for any existing identifier; no authentication is required. Simply issue a GET request to the identifier's URL. Here is a sample interaction:

```
⇒ GET /id/doi:10.5072/test9999 HTTP/1.1
⇒ Host: mds.datacite.org

⇐ HTTP/1.1 200 OK
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 208
⇐
⇐ success: doi:10.5072/test9999
⇐ _created: 1300812337
⇐ _updated: 1300913550
⇐ _target: http://www.gutenberg.org/ebooks/7178
⇐ _profile: erc
⇐ erc.who: Proust, Marcel
⇐ erc.what: Remembrance of Things Past
⇐ erc.when: 1922
```

The first line of the response body is a status line. Assuming success (see [Error handling](#error-handling) above), the remainder of the status line echoes the canonical form of the requested identifier.

The remaining lines are metadata element name/value pairs serialized per ANVL rules; see Request & response bodies above. The order of elements is undefined. Element names beginning with an underscore ("_", U+005F) are reserved for use by the system; their meanings are described in Internal metadata below. Some elements may be drawn from citation metadata standards; see Metadata profiles below.

### Operation: create identifier

An identifier can be "created" by sending a PUT request to the identifier's URL. Here, identifier creation means establishing a record of the identifier (to be successful, no such record can already exist). Authentication is required, and the user must have permission to create identifiers using the identifier's prefix. Users can view the prefixes available to them by visiting the DOI Fabrica service and navigating to the **Prefixes** tab.

A request body is optional; if present, it defines the identifier's starting metadata. There are no restrictions on what metadata elements can be submitted, but a convention has been established for naming metadata elements, and the service has built-in support for certain sets of metadata elements; see Metadata profiles below. A few of the internal service metadata elements may be set; see Internal metadata below.

Here's a sample interaction creating a doi identifier:

```
⇒ PUT /id/doi:/10.5072/test9999 HTTP/1.1
⇒ Host: mds.datacite.org
⇒ Content-Type: text/plain; charset=UTF-8
⇒ Content-Length: 30
⇒
⇒ _target: https://mds.datacite.org/

⇐ HTTP/1.1 201 CREATED
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 27
⇐
⇐ success: doi:/10.5072/test9999
```

The return is a status line. If a doi identifier was created successfully, the normalized form of the identifier is returned as shown above.

### Operation: mint identifier

Minting an identifier is the same as creating an identifier, but instead of supplying a complete identifier, the client specifies only a namespace (or "shoulder") that forms the identifier's prefix, and the service generates an opaque, random string for the identifier's suffix. An identifier can be minted by sending a POST request to the URL https://mds.datacite.org/shoulder/myshoulder where `myshoulder` is the desired namespace. For example:

```
⇒ POST /shoulder/doi:/10.5072/test HTTP/1.1
⇒ Host: mds.datacite.org
⇒ Content-Type: text/plain; charset=UTF-8
⇒ Content-Length: 30
⇒
⇒ _target: https://mds.datacite.org/

⇐ HTTP/1.1 201 CREATED
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 29
⇐
⇐ success: doi:/10.5072/testc9cz3dh0
```

Aside from specifying a complete identifier versus specifying a shoulder only, the create and mint operations operate identically. Authentication is required to mint an identifier; namespace permission is required; and prefixes can be viewed in the DOI Fabrica service under the **Prefixes** tab. The request and response bodies are identical.

The service automatically embeds the newly-minted identifier in certain types of uploaded metadata. See Metadata profiles below for when this is performed.

### Operation: modify identifier

An identifier's metadata can be modified by sending a POST request to the identifier's URL. Authentication is required; only the identifier's owner and certain other users may modify the identifier (see Ownership model below).

Metadata elements are operated on individually. If the identifier already has a value for a metadata element included in the request body, the value is overwritten, otherwise the element and its value are added. Only a few of the reserved metadata elements may be modified; see Internal metadata below. Here's a sample interaction:

```
⇒ POST /id/doi:/10.5072/test9999 HTTP/1.1
⇒ Host: mds.datacite.org
⇒ Content-Type: text/plain; charset=UTF-8
⇒ Content-Length: 30
⇒
⇒ _target: https://mds.datacite.org/

⇐ HTTP/1.1 200 OK
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 29
⇐
⇐ success: doi:/10.5072/test9999
```

The return is a status line. Assuming success (see [Error handling](#error-handling) above), the remainder of the status line echoes the canonical form of the identifier in question.

To delete a metadata element, set its value to the empty string.

### Operation: delete identifier

An identifier that has only been reserved can be deleted by sending a DELETE request to the identifier's URL. We emphasize that only reserved identifiers may be deleted; see Identifier status below. Authentication is required; only the identifier's owner and certain other users may delete the identifier (see Ownership model below).

Here's a sample interaction:

```
⇒ DELETE /id/doi:/10.5072/test9999 HTTP/1.1
⇒ Host: mds.datacite.org

⇐ HTTP/1.1 200 OK
⇐ Content-Type: text/plain; charset=UTF-8
⇐ Content-Length: 29
⇐
⇐ success: doi:/10.5072/test9999
```

The return is a status line. Assuming success (see [Error handling](#error-handling) above), the remainder of the status line echoes the canonical form of the identifier just deleted.

### Ownership model

The service maintains ownership information about identifiers and uses that information to enforce access control.

The ownership model employed by DataCite is based on clients: each identifier is owned by one client. Permission to create identifiers is governed by the prefixes that have been assigned to a client by it's DOI Service Provider. But once created, permission to subsequently modify an identifier is governed solely by the identifier's ownership.

Clients in turn are managed DOI service providers, including the assignment of prefixes and users.

### Identifier status

Each identifier in the service has a status. The status is recorded as the value of the "_status" reserved metadata element (see Internal metadata below) and may be one of:

* **public**. The default value.
* **reserved**. The identifier is known only to DataCite. This status may be used to reserve an identifier name within DataCite without advertising the identifier's existence to resolvers and other external services. A reserved identifier may be deleted.
* **unavailable**. The identifier is public, but the object referenced by the identifier is not available. A reason for the object's unavailability may optionally follow the status separated by a pipe character ("|", U+007C), e.g., "unavailable | withdrawn by author". The identifier redirects to a "tombstone" page (an HTML page that displays the identifier's citation metadata and the reason for the object's unavailability) regardless of its target URL.

An identifier's status may be changed by setting a new value for the aforementioned "_status" metadata element. DataCite permits only certain status transitions:

* A status of "reserved" may be specified only at identifier creation time.
* A reserved identifier may be made public. At this time the identifier will be registered with resolvers and other external services.
* A public identifier may be marked as unavailable. At this time the identifier will be removed from any external services.
* An unavailable identifier may be returned to public status. At this time the identifier will be re-registered with resolvers and other external services.

## Installation

Using Docker.

```
docker run -p 8080:80 datacite/cheetoh
```

You can now point your browser to `http://localhost:8080` and use the application.

By default the application connects to the DataCite production infrastructure.
Set the `SANDBOX` environment variable to connect to the DataCite test
infrastructure, e.g.

```
SANDBOX=true
```

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/datacite/cheetoh/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License
**Cheetoh** is released under the [MIT License](https://github.com/datacite/cheetoh/blob/master/LICENSE).
