#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "iOS Frameworks Benchmark Suite"
echo "════════════════════════════════════════════════════════════"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Results storage
RESULTS_DIR="../Results"
mkdir -p $RESULTS_DIR

run_benchmark() {
    local framework=$1
    local example_path=$2
    
    echo -e "\n${YELLOW}▶ Running $framework benchmark...${NC}"
    
    cd $example_path
    
    # Build and run
    if [ "$framework" == "SwiftUI" ] || [ "$framework" == "UIKit" ]; then
        xcodebuild test \
            -scheme "${framework}Benchmark" \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -resultBundlePath "${RESULTS_DIR}/${framework}_results.xcresult" \
            2>&1 | tee "${RESULTS_DIR}/${framework}_output.log"
    fi
    
    cd - > /dev/null
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ $framework benchmark complete${NC}"
        return 0
    else
        echo -e "${RED}✗ $framework benchmark failed${NC}"
        return 1
    fi
}

# Run all benchmarks
echo -e "\n📊 Starting benchmark suite...\n"

run_benchmark "SwiftUI" "Examples/SwiftUI/SwiftUIBenchmark"
run_benchmark "UIKit" "Examples/UIKit/UIKitBenchmark"

# Generate comparison report
echo -e "\n${YELLOW}Generating comparison report...${NC}"

python3 << EOF
import json
import glob

results = {}
for log in glob.glob("$RESULTS_DIR/*_output.log"):
    framework = log.split('/')[-1].replace('_output.log', '')
    with open(log, 'r') as f:
        content = f.read()
        # Extract total time
        import re
        match = re.search(r'TOTAL TO RENDER COMPLETE:\s+([\d.]+)ms', content)
        if match:
            results[framework] = float(match.group(1))

print("\n" + "="*60)
print("BENCHMARK COMPARISON RESULTS")
print("="*60)
for framework, time in sorted(results.items(), key=lambda x: x[1]):
    print(f"  {framework:12} {time:8.2f}ms")
print("="*60)
EOF

echo -e "\n${GREEN}✓ All benchmarks complete!${NC}"
