# Postfix habla con Rspamd como milter (puerto 11332)
milter = yes;
timeout = 120s;
upstream "local" {
  default = yes;
  self_scan = yes;
}
