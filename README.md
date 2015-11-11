# HostileSubBruteforcer
This app will bruteforce for exisiting subdomains and provide the following information:
   - IP address
   - Host
   - if the 3rd party host has been properly setup. (for example if site.example.com is poiting to a nonexisiting Heroku subdomain, it'll alert you) -> Currently only works with AWS, Github, Heroku, shopify, tumblr and squarespace.

There may be some false positives depending on the host configurations. (Tried to take them out as much as possible)
Also works recursively at the end to get the subdomains under the ones that it has already found and dumps all your data into an output.txt file just in case (fresh one gets created at the beginning of each process) 


##Example output

`````
Enter a domain you'd like to brute force and look for hostile subdomain takeover(example: yahoo.com)
example.com
200 0.example.com ---> 198.185.159.177
- Subdomain pointing to a non-existing SquareSpace account showing: No Such Account
- Seems like 0.example.com is an alias for exampledomain111.squarespace.com
404 a.example.com ---> 50.116.58.222
- Subdomain pointing to a non-existing WPEngine subdomain indicatingThe site you were looking for couldn't be found.
- Seems like a.example.com is an alias for exampledomain111.wpengine.com
----> Check for further information on where this is pointing to.
404 b.example.com ---> 54.231.18.81
- Subdomain pointing to an unclaimed AmazonAWS bucket showing: NoSuchBucket
- Seems like b.example.com is an alias for exampledomain111.images.s3.amazonaws.com
----> Check for further information on where this is pointing to.
404 c.example.com ---> 23.227.38.70
- Subdomain pointing to a non-existing Shopify subdomain indicatingSorry, this shop is currently unavailable.
- Seems like c.example.com is an alias for theresnosuchdomain.myshopify.com
----> Check for further information on where this is pointing to.
301 cpanel.example.com ---> 1.1.1.1
404 e.example.com ---> 23.235.47.133
- Subdomain pointing to a non-existing Github subdomain indicatingThere isn't a GitHub Pages site here
- Seems like e.example.com is an alias for noneexistingexampledomain.github.com
----> Check for further information on where this is pointing to.
404 f.example.com ---> 199.27.79.133
- Subdomain pointing to a non-existing Github subdomain indicatingThere isn't a GitHub Pages site here
- Seems like f.example.com is an alias for noneexistingexampledomain.github.io
----> Check for further information on where this is pointing to.
200 ftp.example.com ---> 1.1.1.1
200 g.example.com ---> 104.238.181.195
- Seems like g.example.com is an alias for somedomain.anotherexample.com
`````


Good luck!
