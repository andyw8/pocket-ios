// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Sails
import Combine
import NIO


class MyListFiltersTests: XCTestCase {
    var server: Application!
    var app: PocketAppElement!

    override func setUpWithError() throws {
        continueAfterFailure = false

        let uiApp = XCUIApplication()
        app = PocketAppElement(app: uiApp)

        server = Application()

        server.routes.post("/graphql") { request, _ in
            let apiRequest = ClientAPIRequest(request)

            if apiRequest.isForSlateLineup {
                return Response.slateLineup()
            } else if apiRequest.isForMyListContent {
                return Response.myList()
            } else if apiRequest.isForArchivedContent {
                return Response.archivedContent()
            } else if apiRequest.isToFavoriteAnItem {
                return Response.favorite()
            } else if apiRequest.isToUnfavoriteAnItem {
                return Response.unfavorite()
            } else {
                fatalError("Unexpected request")
            }
        }

        try server.start()
    }

    override func tearDownWithError() throws {
        try server.stop()
        app.terminate()
    }

    func testTappingFavoritesPill_showsOnlyFavoritedItems() {
        app.launch().tabBar.myListButton.wait().tap()
        XCTAssertEqual(app.myListView.wait().itemCells.count, 2)

        app.myListView.favoritesButton.tap()
        XCTAssertEqual(app.myListView.wait().itemCells.count, 0)

        app.myListView.favoritesButton.tap()
        app.myListView.itemView(at: 0).favoriteButton.tap()

        app.myListView.favoritesButton.tap()
        XCTAssertEqual(app.myListView.wait().itemCells.count, 1)
    }
}
