#!/bin/bash
set -e

# Load Test Configs
THREADS=${JVM_THREADS:-10}
LOOPS=${JVM_LOOPS:-1}
DURATION=${JVM_DURATION:-60}

# Target application URL (domain only, no protocol/port)
APP_URL=${JVM_APP_URL:-dtpay.34.67.92.11.nip.io}

# Dynatrace Configs (Passed from K8s Secret)
DT_URL=${JVM_DT_URL}
DT_TOKEN=${JVM_DT_TOKEN}

echo "=== Starting JMeter Test ==="
echo "Threads: $THREADS"
echo "Loops: $LOOPS"
echo "Duration: $DURATION seconds"
echo "Target App URL: $APP_URL"
echo "Sending performance data to Dynatrace URL: $DT_URL"
echo "============================="

jmeter -n \
  -t /jmeter/dtpay-testing.jmx \
  -l /jmeter/results.jtl \
  -Jp_threads=$THREADS \
  -Jp_loops=$LOOPS \
  -Jp_duration=$DURATION \
  -Jp_app_url="$APP_URL" \
  -Jp_dt_url="$DT_URL" \
  -Jp_dt_token="$DT_TOKEN"

echo "=== JMeter Test Completed ==="