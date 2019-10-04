# docker-haproxytcpredirect

Defines a simple haproxy service to expose a list of ports to a list of backend servers

# Env variables
 - PORTS
   - comma-separated list of ports to map to haproxy frontend binds
 - BACKENDS
   - comma-separated list of backends to map to haproxy backends (will use round-robin)
 - VERBOSE
   - set to 1 for increased logging, do not run production with this env variable set!