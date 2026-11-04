#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
swiftc -Onone -o /tmp/bite_catalog_tests BITE/Models.swift BITE/WorldTableData.swift BITE/DraftData.swift BITE/Catalog.swift BITE/SimpleRecipes.swift BITE/PantryTemplates.swift Tests/CatalogTests.swift
/tmp/bite_catalog_tests BITE/simple_recipes.json
swiftc -Onone -o /tmp/bite_receipt_tests BITE/ReceiptParser.swift Tests/ReceiptParserTests.swift
/tmp/bite_receipt_tests
swiftc -Onone -o /tmp/bite_profile_tests BITE/Models.swift BITE/WorldTableData.swift BITE/DraftData.swift BITE/Catalog.swift BITE/SimpleRecipes.swift BITE/PantryTemplates.swift Tests/OnboardingAndGlutenFreeTests.swift
/tmp/bite_profile_tests BITE/simple_recipes.json
swiftc -frontend -parse BITE/*.swift
if command -v plutil >/dev/null 2>&1; then plutil -lint -- BITE.xcodeproj/project.pbxproj BITE/Info.plist; fi
if command -v node >/dev/null 2>&1; then node Backend/test_worker.mjs; fi
