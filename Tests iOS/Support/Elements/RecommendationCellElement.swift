// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest


struct RecommendationCellElement: PocketUIElement {
    let element: XCUIElement

    init(_ element: XCUIElement) {
        self.element = element
    }

    var saveButton: XCUIElement {
        element.buttons["save-button"]
    }
    
    var reportButton: XCUIElement {
        element.buttons["report-button"]
    }
}
