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
  name: allan_admin-csr 
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2REQ0NBVndDQVFBd0x6RVVNQklHQTFVRUF3d0xZV3hzWVc1ZllXUnRhVzR4RnpBVkJnTlZCQW9NRG1GawpiV2x1Y3pwdFlYTjBaWEp6TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUE1YmJ3CmgrckpHYW1lTk9SWmc1Q3I3dk1leEwzZUJGdWxmbjhkZ2J3ZXkyMnVWVGlKbDNkaTM3eDZIMStaS2orbnp5NVcKSCtTN3FzZDFicGllTkRHWFV0ZjVOTWlNYi9HMm9FdG5LV2VZV2g1YUlTYzVhWkx3Z1g4RXB1ckxYRFRzcHNGNApXVVpZRmpzeDFpTFV3ZzcvRTdTWVc4UG5vQW1ndHhPTjQ5bHVadmw2U1NjUzBrMDRoc255ZnhYdEhzak1pQWtxCmdjMDUzaEp2TDMrSktTazlnQXlZcDE2NXBmZmFoUEZuMmZwczFxOUNwblVQMTVHOXRTbnN5RjZBS1Y2VVM5Tk4KbjN6NEpZYzVKYnBtY2xjZlcrWlZkbVorSm9hS3U4ZWJJVjJQTnpsOEN0b3hLR1M2S1dLcnd3SWRIQUwzbmxyZApDbjZnaG85WjdjRGZVNmZvN3dJREFRQUJvQUF3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUk1R09pWDhxcml6Cm5WR1FFakhoam91S1FHUjdBYU5LRWRrbm1oL28vNnEzeTJlSk9tK2wrY3N3bENibk4vbXE5b2xiVTNoWldoT3MKWEV3Z1hEOHVQcWhkV0FTU2JRN1dJYXBFWVN6cWdFNGo0SHk0TXRMM3B6M0NDNm9pY0J2V3dTcnZZVFpUdnI4KwpHdWQxL3BGbFpGNW5LT0hDeFZBenIrbWhuTFZpT2ppekthUTZTRDh2eWJSM081Q2RZbEx4ZkVKZVhDTVRseUF1CjF4aHloSThwN0xqeER2NENqVTNzWG5LNUd4c2pVRVVwckJObzdueWYxRW9hcjAzbEQzMzJPU1JGZlRsa1FIbzMKcUdqcFBSZHBOVlNuYllpRUw3b0NJWExJMm9iZDdPSVBxd24vQjdTQldyM3EyRFk1dXFIVGdERTBpYjhrTWFHNApNWTB3UzFJUmMrYz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg== 
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
