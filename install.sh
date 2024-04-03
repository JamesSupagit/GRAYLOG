#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to install Graylog
install_graylog() {
    echo -e "${GREEN}Installing Dependencies for Graylog...${NC}"

    # Asking for Graylog host IP address
    read -p "Enter the IP address of the Graylog host: " GRAYLOG_HOST_IP
    

    echo "Install Dependency"
    sleep 1.5
    apt update -y
    apt upgrade -y
    apt install apt-transport-https gnupg2 uuid-runtime pwgen curl dirmngr -y

    echo "Install Java JDK"
    sleep 1.5
    apt install openjdk-11-jre-headless -y
    java -version

    echo "Install Elasticsearch"
    sleep 1.5
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
    apt update -y
    apt install elasticsearch-oss -y
    echo "cluster.name: graylog
    action.auto_create_index: false" >> /etc/elasticsearch/elasticsearch.yml
    echo "check config Elasticsearch"
    cat /etc/elasticsearch/elasticsearch.yml
    sleep 3
    systemctl daemon-reload
    systemctl start elasticsearch
    systemctl enable elasticsearch
    curl -X GET http://localhost:9200


    echo "Install MongoDB Server"
    sleep 1.5
    curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
    sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-server-6.0.gpg
    echo "deb [ arch=amd64,arm64 signed=/etc/apt/trusted.gpg.d/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    apt update -y
    apt install mongodb-org -y
    mongod --version
    systemctl start mongod
    systemctl enable mongod

    echo "Install Graylog4.3"
    sleep 1.5
    wget https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb
    dpkg -i graylog-4.3-repository_latest.deb
    apt update -y
    apt install graylog-server -y

    systemctl daemon-reload
    systemctl start graylog-server
    systemctl enable graylog-server

    echo "Install Nginx"
    sleep 1.5
    apt install nginx -y
    touch /etc/nginx/sites-available/graylog.conf
    echo "server {
    listen 80;
    server_name graylog.example.org;

    location /
    {
      proxy_set_header Host $http_host;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Server $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Graylog-Server-URL http://$GRAYLOG_HOST_IP/;
      proxy_pass       http://$GRAYLOG_HOST_IP:9000;
    }

    }" > /etc/nginx/sites-available/graylog.conf
    echo "Verify Nginx Configuration"
    nginx -t
    sleep 1.5
    ln -s /etc/nginx/sites-available/graylog.conf /etc/nginx/sites-enabled/
    rm -rf /etc/nginx/sites-enabled/default
    systemctl restart nginx
    systemctl enable nginx
    echo -e "${GREEN}Complete Install Graylog4.3${NC}"
}

uninstall_graylog()
{
    clear
    echo "Uninstall Graylog v.4.3"
    sleep 1.5
    clear
    echo "Search Old Package's Graylog and uninstall"
    apt list --installed | grep graylog
    sleep 1.5
    clear
    apt remove --purge graylog-4.3-repository -y
    clear
    apt remove --purge graylog-server -y
    clear
    echo "Warning!! Your system will rebooting now...."
    echo 1.5
    clear
    reboot
}

upgrade_graylog()
{
    echo "Upgrade Graylog to V.5.2.5-1"
    sleep 2
    clear
    wget https://packages.graylog2.org/repo/packages/graylog-5.2-repository_latest.deb
    sudo dpkg -i graylog-5.2-repository_latest.deb
    sudo apt-get update -y
    sudo apt-cache policy graylog-server
    sudo apt-get install graylog-server=5.2.5-1
    clear
    echo "${GREEN}Upgrade Graylog to V.5.2.5-1 Complete...${NC}"
    sleep 2
    clear
    echo "############################
    # GRAYLOG CONFIGURATION FILE
    ############################
    #
    # This is the Graylog configuration file. The file has to use ISO 8859-1/Latin-1 character encoding.
    # Characters that cannot be directly represented in this encoding can be written using Unicode escapes
    # as defined in https://docs.oracle.com/javase/specs/jls/se8/html/jls-3.html#jls-3.3, using the \u prefix.
    # For example, \u002c.
    #
    # * Entries are generally expected to be a single line of the form, one of the following:
    #
    # propertyName=propertyValue
    # propertyName:propertyValue
    #
    # * White space that appears between the property name and property value is ignored,
    #   so the following are equivalent:
    #
    # name=Stephen
    # name = Stephen
    #
    # * White space at the beginning of the line is also ignored.
    #
    # * Lines that start with the comment characters ! or # are ignored. Blank lines are also ignored.
    #
    # * The property value is generally terminated by the end of the line. White space following the
    #   property value is not ignored, and is treated as part of the property value.
    #
    # * A property value can span several lines if each line is terminated by a backslash (‘\’) character.
    #   For example:
    #
    # targetCities=\
    #         Detroit,\
    #         Chicago,\
    #         Los Angeles
    #
    #   This is equivalent to targetCities=Detroit,Chicago,Los Angeles (white space at the beginning of lines is ignored).
    #
    # * The characters newline, carriage return, and tab can be inserted with characters \n, \r, and \t, respectively.
    #
    # * The backslash character must be escaped as a double backslash. For example:
    #
    # path=c:\\docs\\doc1
    #

    # If you are running more than one instances of Graylog server you have to select one of these
    # instances as leader. The leader will perform some periodical tasks that non-leaders won't perform.
    is_leader = true

    # The auto-generated node ID will be stored in this file and read after restarts. It is a good idea
    # to use an absolute file path here if you are starting Graylog server from init scripts or similar.
    node_id_file = /etc/graylog/server/node-id

    # You MUST set a secret to secure/pepper the stored user passwords here. Use at least 64 characters.
    # Generate one by using for example: pwgen -N 1 -s 96
    # ATTENTION: This value must be the same on all Graylog nodes in the cluster.
    # Changing this value after installation will render all user sessions and encrypted values in the database invalid. (e.g. encrypted access tokens)
    password_secret = DSi8TxelpPWw9sCjJW3ggwmEt9wq2VnorybBA3iyqWAXgDtbff3e1YpHDPmjbGNOpsrDN2LiNLCgsI1dqxAojhdZdYhMheny

    # The default root user is named 'admin'
    #root_username = admin

    # You MUST specify a hash password for the root user (which you only need to initially set up the
    # system and in case you lose connectivity to your authentication backend)
    # This password cannot be changed using the API or via the web interface. If you need to change it,
    # modify it in this file.
    # Create one by using for example: echo -n yourpassword | shasum -a 256
    # and put the resulting hash value into the following line
    # Default User/Pass admin/demo
    root_password_sha2 = 2a97516c354b68848cdbd8f54a226a0a55b21ed138e207ad6c5cbb9c00aa5aea

    # The email address of the root user.
    # Default is empty
    #root_email = ""

    # The time zone setting of the root user. See http://www.joda.org/joda-time/timezones.html for a list of valid time zones.
    # Default is UTC
    #root_timezone = UTC

    # Set the bin directory here (relative or absolute)
    # This directory contains binaries that are used by the Graylog server.
    # Default: bin
    bin_dir = /usr/share/graylog-server/bin

    # Set the data directory here (relative or absolute)
    # This directory is used to store Graylog server state.
    # Default: data
    data_dir = /var/lib/graylog-server

    # Set plugin directory here (relative or absolute)
    plugin_dir = /usr/share/graylog-server/plugin

    ###############
    # HTTP settings
    ###############

    #### HTTP bind address
    #
    # The network interface used by the Graylog HTTP interface.
    #
    # This network interface must be accessible by all Graylog nodes in the cluster and by all clients
    # using the Graylog web interface.
    #
    # If the port is omitted, Graylog will use port 9000 by default.
    #
    # Default: 127.0.0.1:9000
    http_bind_address = $GRAYLOG_HOST_IP:9000
    #http_bind_address = [2001:db8::1]:9000

    #### HTTP publish URI
    #
    # The HTTP URI of this Graylog node which is used to communicate with the other Graylog nodes in the cluster and by all
    # clients using the Graylog web interface.
    #
    # The URI will be published in the cluster discovery APIs, so that other Graylog nodes will be able to find and connect to this Graylog node.
    #
    # This configuration setting has to be used if this Graylog node is available on another network interface than $http_bind_address,
    # for example if the machine has multiple network interfaces or is behind a NAT gateway.
    #
    # If $http_bind_address contains a wildcard IPv4 address (0.0.0.0), the first non-loopback IPv4 address of this machine will be used.
    # This configuration setting *must not* contain a wildcard address!
    #
    # Default: http://$http_bind_address/
    #http_publish_uri = http://192.168.1.1:9000/

    #### External Graylog URI
    #
    # The public URI of Graylog which will be used by the Graylog web interface to communicate with the Graylog REST API.
    #
    # The external Graylog URI usually has to be specified, if Graylog is running behind a reverse proxy or load-balancer
    # and it will be used to generate URLs addressing entities in the Graylog REST API (see $http_bind_address).
    #
    # When using Graylog Collector, this URI will be used to receive heartbeat messages and must be accessible for all collectors.
    #
    # This setting can be overridden on a per-request basis with the "X-Graylog-Server-URL" HTTP request header.
    #
    # Default: $http_publish_uri
    #http_external_uri =

    #### Enable CORS headers for HTTP interface
    #
    # This allows browsers to make Cross-Origin requests from any origin.
    # This is disabled for security reasons and typically only needed if running graylog
    # with a separate server for frontend development.
    #
    # Default: false
    #http_enable_cors = false

    #### Enable GZIP support for HTTP interface
    #
    # This compresses API responses and therefore helps to reduce
    # overall round trip times. This is enabled by default. Uncomment the next line to disable it.
    #http_enable_gzip = false

    # The maximum size of the HTTP request headers in bytes.
    #http_max_header_size = 8192

    # The size of the thread pool used exclusively for serving the HTTP interface.
    #http_thread_pool_size = 64

    ################
    # HTTPS settings
    ################

    #### Enable HTTPS support for the HTTP interface
    #
    # This secures the communication with the HTTP interface with TLS to prevent request forgery and eavesdropping.
    #
    # Default: false
    #http_enable_tls = true

    # The X.509 certificate chain file in PEM format to use for securing the HTTP interface.
    #http_tls_cert_file = /path/to/graylog.crt

    # The PKCS#8 private key file in PEM format to use for securing the HTTP interface.
    #http_tls_key_file = /path/to/graylog.key

    # The password to unlock the private key used for securing the HTTP interface.
    #http_tls_key_password = secret

    # If set to "true", Graylog will periodically investigate indices to figure out which fields are used in which streams.
    # It will make field list in Graylog interface show only fields used in selected streams, but can decrease system performance,
    # especially on systems with great number of streams and fields.
    stream_aware_field_types=false

    # Comma separated list of trusted proxies that are allowed to set the client address with X-Forwarded-For
    # header. May be subnets, or hosts.
    #trusted_proxies = 127.0.0.1/32, 0:0:0:0:0:0:0:1/128

    # List of Elasticsearch hosts Graylog should connect to.
    # Need to be specified as a comma-separated list of valid URIs for the http ports of your elasticsearch nodes.
    # If one or more of your elasticsearch hosts require authentication, include the credentials in each node URI that
    # requires authentication.
    #
    # Default: http://127.0.0.1:9200
    #elasticsearch_hosts = http://node1:9200,http://user:password@node2:19200

    # Maximum number of attempts to connect to elasticsearch on boot for the version probe.
    #
    # Default: 0, retry indefinitely with the given delay until a connection could be established
    #elasticsearch_version_probe_attempts = 5

    # Waiting time in between connection attempts for elasticsearch_version_probe_attempts
    #
    # Default: 5s
    #elasticsearch_version_probe_delay = 5s

    # Maximum amount of time to wait for successful connection to Elasticsearch HTTP port.
    #
    # Default: 10 Seconds
    #elasticsearch_connect_timeout = 10s

    # Maximum amount of time to wait for reading back a response from an Elasticsearch server.
    # (e. g. during search, index creation, or index time-range calculations)
    #
    # Default: 60 seconds
    #elasticsearch_socket_timeout = 60s

    # Maximum idle time for an Elasticsearch connection. If this is exceeded, this connection will
    # be tore down.
    #
    # Default: inf
    #elasticsearch_idle_timeout = -1s

    # Maximum number of total connections to Elasticsearch.
    #
    # Default: 200
    #elasticsearch_max_total_connections = 200

    # Maximum number of total connections per Elasticsearch route (normally this means per
    # elasticsearch server).
    #
    # Default: 20
    #elasticsearch_max_total_connections_per_route = 20

    # Maximum number of times Graylog will retry failed requests to Elasticsearch.
    #
    # Default: 2
    #elasticsearch_max_retries = 2

    # Enable automatic Elasticsearch node discovery through Nodes Info,
    # see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/cluster-nodes-info.html
    #
    # WARNING: Automatic node discovery does not work if Elasticsearch requires authentication, e. g. with Shield.
    #
    # Default: false
    #elasticsearch_discovery_enabled = true

    # Filter for including/excluding Elasticsearch nodes in discovery according to their custom attributes,
    # see https://www.elastic.co/guide/en/elasticsearch/reference/5.4/cluster.html#cluster-nodes
    #
    # Default: empty
    #elasticsearch_discovery_filter = rack:42

    # Frequency of the Elasticsearch node discovery.
    #
    # Default: 30s
    # elasticsearch_discovery_frequency = 30s

    # Set the default scheme when connecting to Elasticsearch discovered nodes
    #
    # Default: http (available options: http, https)
    #elasticsearch_discovery_default_scheme = http

    # Enable payload compression for Elasticsearch requests.
    #
    # Default: false
    #elasticsearch_compression_enabled = true

    # Enable use of "Expect: 100-continue" Header for Elasticsearch index requests.
    # If this is disabled, Graylog cannot properly handle HTTP 413 Request Entity Too Large errors.
    #
    # Default: true
    #elasticsearch_use_expect_continue = true

    # Graylog uses Index Sets to manage settings for groups of indices. The default options for index sets are configurable
    # for each index set in Graylog under System > Configuration > Index Set Defaults.
    # The following settings are used to initialize in-database defaults on the first Graylog server startup.
    # Specify these values if you want the Graylog server and indices to start with specific settings.

    # The prefix for the Default Graylog index set.
    #
    #elasticsearch_index_prefix = graylog

    # The name of the index template for the Default Graylog index set.
    #
    #elasticsearch_template_name = graylog-internal

    # The prefix for the for graylog event indices.
    #
    #default_events_index_prefix = gl-events

    # The prefix for graylog system event indices.
    #
    #default_system_events_index_prefix = gl-system-events

    # Analyzer (tokenizer) to use for message and full_message field. The "standard" filter usually is a good idea.
    # All supported analyzers are: standard, simple, whitespace, stop, keyword, pattern, language, snowball, custom
    # Elasticsearch documentation: https://www.elastic.co/guide/en/elasticsearch/reference/2.3/analysis.html
    # Note that this setting only takes effect on newly created indices.
    #
    #elasticsearch_analyzer = standard

    # How many Elasticsearch shards and replicas should be used per index?
    #
    #elasticsearch_shards = 1
    #elasticsearch_replicas = 0

    # Disable the optimization of Elasticsearch indices after index cycling. This may take some load from Elasticsearch
    # on heavily used systems with large indices, but it will decrease search performance. The default is to optimize
    # cycled indices.
    #
    #disable_index_optimization = true

    # Optimize the index down to <= index_optimization_max_num_segments. A higher number may take some load from Elasticsearch
    # on heavily used systems with large indices, but it will decrease search performance. The default is 1.
    #
    #index_optimization_max_num_segments = 1

    # Time interval to trigger a full refresh of the index field types for all indexes. This will query ES for all indexes
    # and populate any missing field type information to the database.
    #
    #index_field_type_periodical_full_refresh_interval = 5m

    # You can configure the default strategy used to determine when to rotate the currently active write index.
    # Multiple rotation strategies are supported, the default being "time-size-optimizing":
    #   - "time-size-optimizing" tries to rotate daily, while focussing on optimal sized shards.
    #      The global default values can be configured with
    #       "time_size_optimizing_retention_min_lifetime" and "time_size_optimizing_retention_max_lifetime".
    #   - "count" of messages per index, use elasticsearch_max_docs_per_index below to configure
    #   - "size" per index, use elasticsearch_max_size_per_index below to configure
    #   - "time" interval between index rotations, use elasticsearch_max_time_per_index to configure
    # A strategy may be disabled by specifying the optional enabled_index_rotation_strategies list and excluding that strategy.
    #
    #enabled_index_rotation_strategies = count,size,time,time-size-optimizing

    # The default index rotation strategy to use.
    #rotation_strategy = time-size-optimizing

    # (Approximate) maximum number of documents in an Elasticsearch index before a new index
    # is being created, also see no_retention and elasticsearch_max_number_of_indices.
    # Configure this if you used 'rotation_strategy = count' above.
    #
    #elasticsearch_max_docs_per_index = 20000000

    # (Approximate) maximum size in bytes per Elasticsearch index on disk before a new index is being created, also see
    # no_retention and elasticsearch_max_number_of_indices. Default is 30GB.
    # Configure this if you used 'rotation_strategy = size' above.
    #
    #elasticsearch_max_size_per_index = 32212254720

    # (Approximate) maximum time before a new Elasticsearch index is being created, also see
    # no_retention and elasticsearch_max_number_of_indices. Default is 1 day.
    # Configure this if you used 'rotation_strategy = time' above.
    # Please note that this rotation period does not look at the time specified in the received messages, but is
    # using the real clock value to decide when to rotate the index!
    # Specify the time using a duration and a suffix indicating which unit you want:
    #  1w  = 1 week
    #  1d  = 1 day
    #  12h = 12 hours
    # Permitted suffixes are: d for day, h for hour, m for minute, s for second.
    #
    #elasticsearch_max_time_per_index = 1d

    # Controls whether empty indices are rotated. Only applies to the "time" rotation_strategy.
    #
    #elasticsearch_rotate_empty_index_set=false

    # Provides a hard upper limit for the retention period of any index set at configuration time.
    #
    # This setting is used to validate the value a user chooses for the maximum number of retained indexes, when configuring
    # an index set. However, it is only in effect, when a time-based rotation strategy is chosen.
    #
    # If a rotation strategy other than time-based is selected and/or no value is provided for this setting, no upper limit
    # for index retention will be enforced. This is also the default.

    # Default: none
    #max_index_retention_period = P90d

    # Optional upper bound on elasticsearch_max_time_per_index
    #
    #elasticsearch_max_write_index_age = 1d

    # Disable message retention on this node, i. e. disable Elasticsearch index rotation.
    #no_retention = false

    # Decide what happens with the oldest indices when the maximum number of indices is reached.
    # The following strategies are available:
    #   - delete # Deletes the index completely (Default)
    #   - close # Closes the index and hides it from the system. Can be re-opened later.
    #
    #retention_strategy = delete

    # This configuration list limits the retention strategies available for user configuration via the UI
    # The following strategies can be disabled:
    #   - delete # Deletes the index completely (Default)
    #   - close # Closes the index and hides it from the system. Can be re-opened later.
    #   - none #  No operation is performed. The index stays open. (Not recommended)
    # WARNING: At least one strategy must be enabled
    disabled_retention_strategies = none

    # How many indices do you want to keep for the delete and close retention types?
    #
    #elasticsearch_max_number_of_indices = 20

    # Disable checking the version of Elasticsearch for being compatible with this Graylog release.
    # WARNING: Using Graylog with unsupported and untested versions of Elasticsearch may lead to data loss!
    #
    #elasticsearch_disable_version_check = true

    # Do you want to allow searches with leading wildcards? This can be extremely resource hungry and should only
    # be enabled with care. See also: https://docs.graylog.org/docs/query-language
    allow_leading_wildcard_searches = false

    # Do you want to allow searches to be highlighted? Depending on the size of your messages this can be memory hungry and
    # should only be enabled after making sure your Elasticsearch cluster has enough memory.
    allow_highlighting = false

    # Sets field value suggestion mode. The possible values are:
    #  1. "off" - field value suggestions are turned off
    #  2. "textual_only" - field values are suggested only for textual fields
    #  3. "on" (default) - field values are suggested for all field types, even the types where suggestions are inefficient performance-wise
    field_value_suggestion_mode = on

    # Global timeout for index optimization (force merge) requests.
    # Default: 1h
    #elasticsearch_index_optimization_timeout = 1h

    # Maximum number of concurrently running index optimization (force merge) jobs.
    # If you are using lots of different index sets, you might want to increase that number.
    # This value should be set lower than elasticsearch_max_total_connections_per_route, otherwise index optimization
    # could deplete all the client connections to the search server and block new messages ingestion for prolonged
    # periods of time.
    # Default: 10
    #elasticsearch_index_optimization_jobs = 10

    # Mute the logging-output of ES deprecation warnings during REST calls in the ES RestClient
    #elasticsearch_mute_deprecation_warnings = true

    # Time interval for index range information cleanups. This setting defines how often stale index range information
    # is being purged from the database.
    # Default: 1h
    #index_ranges_cleanup_interval = 1h

    # Batch size for the Elasticsearch output. This is the maximum (!) number of messages the Elasticsearch output
    # module will get at once and write to Elasticsearch in a batch call. If the configured batch size has not been
    # reached within output_flush_interval seconds, everything that is available will be flushed at once. Remember
    # that every outputbuffer processor manages its own batch and performs its own batch write calls.
    # ("outputbuffer_processors" variable)
    output_batch_size = 500

    # Flush interval (in seconds) for the Elasticsearch output. This is the maximum amount of time between two
    # batches of messages written to Elasticsearch. It is only effective at all if your minimum number of messages
    # for this time period is less than output_batch_size * outputbuffer_processors.
    output_flush_interval = 1

    # As stream outputs are loaded only on demand, an output which is failing to initialize will be tried over and
    # over again. To prevent this, the following configuration options define after how many faults an output will
    # not be tried again for an also configurable amount of seconds.
    output_fault_count_threshold = 5
    output_fault_penalty_seconds = 30

    # The number of parallel running processors.
    # Raise this number if your buffers are filling up.
    processbuffer_processors = 5
    outputbuffer_processors = 3

    # The size of the thread pool in the output buffer processor.
    # Default: 3
    #outputbuffer_processor_threads_core_pool_size = 3

    # UDP receive buffer size for all message inputs (e. g. SyslogUDPInput).
    #udp_recvbuffer_sizes = 1048576

    # Wait strategy describing how buffer processors wait on a cursor sequence. (default: sleeping)
    # Possible types:
    #  - yielding
    #     Compromise between performance and CPU usage.
    #  - sleeping
    #     Compromise between performance and CPU usage. Latency spikes can occur after quiet periods.
    #  - blocking
    #     High throughput, low latency, higher CPU usage.
    #  - busy_spinning
    #     Avoids syscalls which could introduce latency jitter. Best when threads can be bound to specific CPU cores.
    processor_wait_strategy = blocking

    # Size of internal ring buffers. Raise this if raising outputbuffer_processors does not help anymore.
    # For optimum performance your LogMessage objects in the ring buffer should fit in your CPU L3 cache.
    # Must be a power of 2. (512, 1024, 2048, ...)
    ring_size = 65536

    inputbuffer_ring_size = 65536
    inputbuffer_processors = 2
    inputbuffer_wait_strategy = blocking

    # Manually stopped inputs are no longer auto-restarted. To re-enable the previous behavior, set auto_restart_inputs to true.
    #auto_restart_inputs = true

    # Enable the message journal.
    message_journal_enabled = true

    # The directory which will be used to store the message journal. The directory must be exclusively used by Graylog and
    # must not contain any other files than the ones created by Graylog itself.
    #
    # ATTENTION:
    #   If you create a separate partition for the journal files and use a file system creating directories like 'lost+found'
    #   in the root directory, you need to create a sub directory for your journal.
    #   Otherwise Graylog will log an error message that the journal is corrupt and Graylog will not start.
    message_journal_dir = /var/lib/graylog-server/journal

    # Journal hold messages before they could be written to Elasticsearch.
    # For a maximum of 12 hours or 5 GB whichever happens first.
    # During normal operation the journal will be smaller.
    #message_journal_max_age = 12h
    #message_journal_max_size = 5gb

    #message_journal_flush_age = 1m
    #message_journal_flush_interval = 1000000
    #message_journal_segment_age = 1h
    #message_journal_segment_size = 100mb

    # Number of threads used exclusively for dispatching internal events. Default is 2.
    #async_eventbus_processors = 2

    # How many seconds to wait between marking node as DEAD for possible load balancers and starting the actual
    # shutdown process. Set to 0 if you have no status checking load balancers in front.
    lb_recognition_period_seconds = 3

    # Journal usage percentage that triggers requesting throttling for this server node from load balancers. The feature is
    # disabled if not set.
    #lb_throttle_threshold_percentage = 95

    # Every message is matched against the configured streams and it can happen that a stream contains rules which
    # take an unusual amount of time to run, for example if its using regular expressions that perform excessive backtracking.
    # This will impact the processing of the entire server. To keep such misbehaving stream rules from impacting other
    # streams, Graylog limits the execution time for each stream.
    # The default values are noted below, the timeout is in milliseconds.
    # If the stream matching for one stream took longer than the timeout value, and this happened more than "max_faults" times
    # that stream is disabled and a notification is shown in the web interface.
    #stream_processing_timeout = 2000
    #stream_processing_max_faults = 3

    # Since 0.21 the Graylog server supports pluggable output modules. This means a single message can be written to multiple
    # outputs. The next setting defines the timeout for a single output module, including the default output module where all
    # messages end up.
    #
    # Time in milliseconds to wait for all message outputs to finish writing a single message.
    #output_module_timeout = 10000

    # Time in milliseconds after which a detected stale leader node is being rechecked on startup.
    #stale_leader_timeout = 2000

    # Time in milliseconds which Graylog is waiting for all threads to stop on shutdown.
    #shutdown_timeout = 30000

    # MongoDB connection string
    # See https://docs.mongodb.com/manual/reference/connection-string/ for details
    mongodb_uri = mongodb://localhost/graylog

    # Authenticate against the MongoDB server
    # '+'-signs in the username or password need to be replaced by '%2B'
    #mongodb_uri = mongodb://grayloguser:secret@localhost:27017/graylog

    # Use a replica set instead of a single host
    #mongodb_uri = mongodb://grayloguser:secret@localhost:27017,localhost:27018,localhost:27019/graylog?replicaSet=rs01

    # DNS Seedlist https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format
    #mongodb_uri = mongodb+srv://server.example.org/graylog

    # Increase this value according to the maximum connections your MongoDB server can handle from a single client
    # if you encounter MongoDB connection problems.
    mongodb_max_connections = 1000

    # Maximum number of attempts to connect to MongoDB on boot for the version probe.
    #
    # Default: 0, retry indefinitely until a connection can be established
    #mongodb_version_probe_attempts = 5

    # Email transport
    #transport_email_enabled = false
    #transport_email_hostname = mail.example.com
    #transport_email_port = 587
    #transport_email_use_auth = true
    #transport_email_auth_username = you@example.com
    #transport_email_auth_password = secret
    #transport_email_from_email = graylog@example.com
    #transport_email_socket_connection_timeout = 10s
    #transport_email_socket_timeout = 10s

    # Encryption settings
    #
    # ATTENTION:
    #    Using SMTP with STARTTLS *and* SMTPS at the same time is *not* possible.

    # Use SMTP with STARTTLS, see https://en.wikipedia.org/wiki/Opportunistic_TLS
    #transport_email_use_tls = true

    # Use SMTP over SSL (SMTPS), see https://en.wikipedia.org/wiki/SMTPS
    # This is deprecated on most SMTP services!
    #transport_email_use_ssl = false


    # Specify and uncomment this if you want to include links to the stream in your stream alert mails.
    # This should define the fully qualified base url to your web interface exactly the same way as it is accessed by your users.
    #transport_email_web_interface_url = https://graylog.example.com

    # The default connect timeout for outgoing HTTP connections.
    # Values must be a positive duration (and between 1 and 2147483647 when converted to milliseconds).
    # Default: 5s
    #http_connect_timeout = 5s

    # The default read timeout for outgoing HTTP connections.
    # Values must be a positive duration (and between 1 and 2147483647 when converted to milliseconds).
    # Default: 10s
    #http_read_timeout = 10s

    # The default write timeout for outgoing HTTP connections.
    # Values must be a positive duration (and between 1 and 2147483647 when converted to milliseconds).
    # Default: 10s
    #http_write_timeout = 10s

    # HTTP proxy for outgoing HTTP connections
    # ATTENTION: If you configure a proxy, make sure to also configure the "http_non_proxy_hosts" option so internal
    #            HTTP connections with other nodes does not go through the proxy.
    # Examples:
    #   - http://proxy.example.com:8123
    #   - http://username:password@proxy.example.com:8123
    #http_proxy_uri =

    # A list of hosts that should be reached directly, bypassing the configured proxy server.
    # This is a list of patterns separated by ",". The patterns may start or end with a "*" for wildcards.
    # Any host matching one of these patterns will be reached through a direct connection instead of through a proxy.
    # Examples:
    #   - localhost,127.0.0.1
    #   - 10.0.*,*.example.com
    #http_non_proxy_hosts =

    # Connection timeout for a configured LDAP server (e. g. ActiveDirectory) in milliseconds.
    #ldap_connection_timeout = 2000

    # Disable the use of a native system stats collector (currently OSHI)
    #disable_native_system_stats_collector = false

    # The default cache time for dashboard widgets. (Default: 10 seconds, minimum: 1 second)
    #dashboard_widget_default_cache_time = 10s

    # For some cluster-related REST requests, the node must query all other nodes in the cluster. This is the maximum number
    # of threads available for this. Increase it, if '/cluster/*' requests take long to complete.
    # Should be http_thread_pool_size * average_cluster_size if you have a high number of concurrent users.
    #proxied_requests_thread_pool_size = 64

    # The default HTTP call timeout for cluster-related REST requests. This timeout might be overriden for some
    # resources in code or other configuration values. (some cluster metrics resources use a lower timeout)
    #proxied_requests_default_call_timeout = 5s

    # The server is writing processing status information to the database on a regular basis. This setting controls how
    # often the data is written to the database.
    # Default: 1s (cannot be less than 1s)
    #processing_status_persist_interval = 1s

    # Configures the threshold for detecting outdated processing status records. Any records that haven't been updated
    # in the configured threshold will be ignored.
    # Default: 1m (one minute)
    #processing_status_update_threshold = 1m

    # Configures the journal write rate threshold for selecting processing status records. Any records that have a lower
    # one minute rate than the configured value might be ignored. (dependent on number of messages in the journal)
    # Default: 1
    #processing_status_journal_write_rate_threshold = 1

    # Automatically load content packs in "content_packs_dir" on the first start of Graylog.
    #content_packs_loader_enabled = false

    # The directory which contains content packs which should be loaded on the first start of Graylog.
    #content_packs_dir = data/contentpacks

    # A comma-separated list of content packs (files in "content_packs_dir") which should be applied on
    # the first start of Graylog.
    # Default: empty
    #content_packs_auto_install = grok-patterns.json

    # The allowed TLS protocols for system wide TLS enabled servers. (e.g. message inputs, http interface)
    # Setting this to an empty value, leaves it up to system libraries and the used JDK to chose a default.
    # Default: TLSv1.2,TLSv1.3  (might be automatically adjusted to protocols supported by the JDK)
    #enabled_tls_protocols = TLSv1.2,TLSv1.3

    # Enable Prometheus exporter HTTP server.
    # Default: false
    #prometheus_exporter_enabled = false

    # IP address and port for the Prometheus exporter HTTP server.
    # Default: 127.0.0.1:9833
    #prometheus_exporter_bind_address = 127.0.0.1:9833

    # Path to the Prometheus exporter core mapping file. If this option is enabled, the full built-in core mapping is
    # replaced with the mappings in this file.
    # This file is monitored for changes and updates will be applied at runtime.
    # Default: none
    #prometheus_exporter_mapping_file_path_core = prometheus-exporter-mapping-core.yml

    # Path to the Prometheus exporter custom mapping file. If this option is enabled, the mappings in this file are
    # configured in addition to the built-in core mappings. The mappings in this file cannot overwrite any core mappings.
    # This file is monitored for changes and updates will be applied at runtime.
    # Default: none
    #prometheus_exporter_mapping_file_path_custom = prometheus-exporter-mapping-custom.yml

    # Configures the refresh interval for the monitored Prometheus exporter mapping files.
    # Default: 60s
    #prometheus_exporter_mapping_file_refresh_interval = 60s

    # Optional allowed paths for Graylog data files. If provided, certain operations in Graylog will only be permitted
    # if the data file(s) are located in the specified paths (for example, with the CSV File lookup adapter).
    # All subdirectories of indicated paths are allowed by default. This Provides an additional layer of security,
    # and allows administrators to control where in the file system Graylog users can select files from.
    #allowed_auxiliary_paths = /etc/graylog/data-files,/etc/custom-allowed-path

    # Do not perform any preflight checks when starting Graylog
    # Default: false
    #skip_preflight_checks = false

    # Ignore any exceptions encountered when running migrations
    # Use with caution - skipping failing migrations may result in an inconsistent DB state.
    # Default: false
    #ignore_migration_failures = false

    # Comma-separated list of notifcation types which should not emit a system event.
    # Default: SIDECAR_STATUS_UNKNOWN which would create a new event whenever the status of a sidecar becomes "Unknown"
    #system_event_excluded_types = SIDECAR_STATUS_UNKNOWN

    # RSS settings for content stream
    #content_stream_rss_url = https://www.graylog.org/post
    #content_stream_refresh_interval = 7d

    # Maximum value that can be set for an event limit.
    # Default: 1000
    #event_definition_max_event_limit = 1000" > /etc/graylog/server/server.conf

    systemctl daemon-reload
    systemctl start graylog-server
    systemctl enable graylog-server
    clear
    echo "Upgrade Graylog to V.5.2.5-1 Complete...."
    sleep 2
    clear
    echo "Please access Web Console http://$GRAYLOG_HOST_IP:9000" 
    sleep 1.5
    clear



}

# Function to display menu
display_menu() {
    echo -e "${YELLOW}Select an option:${NC}"
    echo -e "${YELLOW}1. Install Graylog V.4.3${NC}"
    echo -e "${YELLOW}2. Uninstall Graylog v.4.3${NC}"
    echo -e "${YELLOW}2. Upgrade Graylog to V.5.2.5-1${NC}"
    echo -e "${YELLOW}3. Exit${NC}"
}

# Main function
main() {
    while true; do
        display_menu

        read -p "Enter your choice: " choice

        case $choice in
            1)
                install_graylog
                ;;
            2)
                uninstall_graylog
                ;;
            3)
                upgrade_graylog
                ;;
            4)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select again!!!${NC}"
                ;;
        esac
    done
}

main
