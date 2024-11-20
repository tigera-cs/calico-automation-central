#!/bin/bash

file="/Users/lbarron/Documents/argocd-final/argocd-charts/charts/test-policies/templates/03-policies.yaml"

# Replace crd.projectcalico.org/v1 with projectcalico.org/v3
sed -i '' 's/crd\.projectcalico\.org\/v1/projectcalico.org\/v3/g' "$file"

# Remove quotes around numbers
#sed -i '' -E 's/"([0-9]+)"/\1/g' "$file"
sed -i '' -E "s/'([0-9]+)'/\1/g" "$file"

# Remove specific entries
sed -i '' '/serviceAccountSelector: ""/d' "$file"
sed -i '' '/selector: ""/d' "$file"
sed -i '' '/namespaceSelector: ""/d' "$file"
sed -i '' '/applyOnForward: false/d' "$file"
sed -i '' '/doNotTrack: false/d' "$file"
sed -i '' '/preDNAT: false/d' "$file"
