# Solo el loopback es "local": las demas IP del laboratorio (10.44.0.0/24) se tratan como internet y se les aplica SPF, DKIM y DMARC
local_addrs = "127.0.0.0/8";
