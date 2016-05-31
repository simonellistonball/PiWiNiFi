Web application to display your trace around the venue.

Shows the venue maps and the trace of pings.

Consists of:
Spark Streaming app to write trace to HBase
Server to interface with HBase
Front end web application to display maps and locations


location.json
-------------

Stores the location of the pis in the venue once determined. These are pts relative to the contents of the venue map svgs.
