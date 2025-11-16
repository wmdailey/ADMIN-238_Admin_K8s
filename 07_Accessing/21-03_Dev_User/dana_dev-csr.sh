#!/bin/bash

# Copyright 2024 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Disclaimer
# This script is for training purposes only and is to be used only
# in support of approved training. The author assumes no liability
# for use outside of a training environments. Unless required by
# applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, either express or implied.

# Title: submit_csr.sh
# Author: WKD
# Date: 1MAY25

# DEBUG
# set -x
#set -eu
#set >> /tmp/setvar.txt

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dana_dev-csr 
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1pqQ0NBVTRDQVFBd0lURVJNQThHQTFVRUF3d0laR0Z1WVY5a1pYWXhEREFLQmdOVkJBb01BMlJsZGpDQwpBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQU0yc0hiQW9ONm9rTjFSN3VOWEd4NC9YCmozNUNlL2o5WW9tTXZiUTg1dHJZaCsvWWJwQ0lHeHIvS09hSmtDQUhSM2gralJXdHNYWWRrSjRiQXA0NGxmZjgKcVNYVXlTUUlNNDI4UnZId1VZVEJCVHJWMDYxQmJCQS96K0tITW10c1dySHZVcnF1d05tL0pleXdzc0pYaEJxMQpHeVFyYXlUcWluTTZTZnJNKzlKQkEvemZOWmhOSmtwRmxnZHJFMzFuS1kzUytmZHZtbGdwbkh3N0h6YVcxWGwvCnN6RHVHbDVJTFJHMjNYVGMrZ21PcVJkME5LSTRCKzduK090TUVETEpNRUNjcVdCZWdubjJpeFNNY1h0Q0tOVW0KSDlxT3Rua2x6TnhGYjYxMGdDa2M2NytVZGo2RmRxMWE1N2ltcVdlOWhaR3Y5R2pUaTVIbzBsbjMyQlNUWXcwQwpBd0VBQWFBQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQytuQmxQcUlQUWFGdm4yS0ZYMTRJUlVzTnJ6a29SCnVoOXE0RDRxNG5JT1RBU0tMTFkzNDBkT05mcU9BdXlUMTVnb1BMMGp6YTFnWDBNYlA3THZ5TTlUZFRFWnc0bWUKVlpUeUt6ais4ejZHVlZ2bHZ1b2d0OWJkSlhFeTBlYXZJZS81S2F1dDlmcE5FRVgwR2RHVmsrSjlKcVczbWxiYQptdlJ5TGNNdzhkV2Z5K09mUHhobnY3TmZRQW9KOVRLSW1HaDFYSVFjV0tOYWFrS3puT1Q4eUZlVFZpYUxSL291ClNkV3B1NHNpYzZjejZlamorUUZGSnh2djhHVGxQZEx5UUlFVlVldmNBQ0NIRXVhRGJ3QzJWQ3VWQW04VVg0a1AKZE1NN2RaMXpjRjFrTzZJRGljRmJhN3J3cE5vNkZPQWlDOGd5TXE4dGxFR1ZCbHpDcFY2bnRFODQKLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==  
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
