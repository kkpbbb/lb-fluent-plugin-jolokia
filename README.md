
Requires:
  - install jolokia.war in web app server
  
Install:

git clone https://github.com/kkpbbb/lb-fluent-plugin-jolokia
cd lb-fluent-plugin-jolokia/
/opt/td-agent/usr/sbin/td-agent-gem build lb-fluent-plugin-jolokia.gemspec
/opt/td-agent/usr/sbin/td-agent-gem install ./fluent-plugin-jolokia-0.0.1.gem 


fluent config example:

<source>
  @type jolokia
  tag jolokia
  jolokia_url 'http://192.168.21.182:8080/jolokia/'
  jmx_bean  'java.lang:type=Memory'
  jmx_attribute HeapMemoryUsage
  jmx_path used
  run_interval 30
</source>


<source>
  @type jolokia
  tag jolokia
  jolokia_url 'http://192.168.21.182:8080/jolokia/'
  jmx_bean  'java.lang:type=GarbageCollector,name=PS MarkSweep'
  run_interval 30
</source>




