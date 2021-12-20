# domain-check
Bash script to grab the status codes of a list containing domains &amp; subdomains.
You should just be able to run this on a list of domains in a text file.


If this doesnt work, you can try:
for URL in `cat domains.txt` ; do echo $URL; curl -m 10 -s -I $1 "$URL" | grep HTTP/1.1 | awk {'print $2'};
