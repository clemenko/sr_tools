curl -k "http://splunk.splunk:8088/services/collector" \
    -H "Authorization: Splunk 51295452-b5b2-4dd7-af92-11092afcd74a" \
    -d '{"event": "Hello, world!", "sourcetype": "manual"}'




curl -k "http://splunk.dockr.life:30991/services/collector" -H "Authorization: Splunk 51295452-b5b2-4dd7-af92-11092afcd74a" -d '{"event": "Hello, world!", "sourcetype": "manual"}'



 curl -k -x POST "http://splunk.dockr.life:30991/services/collector" -H "Authorization: Splunk 51295452-b5b2-4dd7-af92-11092afcd74a" -d '{"sourcetype": "_json", "event": {"a": "value1", "b": ["value1_1", "value1_2"]}}'