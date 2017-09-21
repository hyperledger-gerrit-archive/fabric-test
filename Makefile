# Copyright IBM Corp All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#		 http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - ci-daily: Execute daily tests suite in hyperledger CI
#   - ci-smoke: Executes smoke tests suite in hyperledger CI
#   - ci-release: Executes release tests suite in hyperledger CI

ci-daily: .FORCE
	chmod +x regression/ci-scripts/daily-tests.sh
	@regression/ci-scripts/daily-tests.sh

ci-smoke: .FORCE
	chmod +x regression/ci-scripts/smoke-tests.sh
	@regression/ci-scripts/smoke-tests.sh

ci-release: .FORCE
	chmod +x regression/ci-scripts/release-tests.sh
	@regression/ci-scripts/release-tests.sh

.FORCE:
