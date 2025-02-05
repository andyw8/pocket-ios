// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Sails
import NIO


class HomeTests: XCTestCase {
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
            } else if apiRequest.isForSlateDetail {
                return Response.slateDetail()
            } else if apiRequest.isForMyListContent {
                return Response.myList()
            } else if apiRequest.isForArchivedContent {
                return Response.archivedContent()
            } else if apiRequest.isToSaveAnItem {
                return Response.saveItem()
            } else if apiRequest.isToArchiveAnItem {
                return Response.archive()
            } else {
                fatalError("Unexpected request")
            }
        }

        server.routes.get("/hello") { _, _ in
            Response {
                Status.ok
                Fixture.data(name: "hello", ext: "html")
            }
        }

        try server.start()

        app.launch()
    }

    override func tearDownWithError() throws {
        try server.stop()
        app.terminate()
    }

    func test_navigatingToHomeTab_showsASectionForEachSlate() {
        let home = app.homeView

        home.slateHeader("Slate 1").wait()
        home.recommendationCell("Slate 1, Recommendation 1").verify()
        home.recommendationCell("Slate 1, Recommendation 2").verify()

        home.element.swipeUp()

        home.slateHeader("Slate 2").verify()
        home.recommendationCell("Slate 2, Recommendation 1").verify()
    }

    func test_selectingChipInTopicCarousel_showsSlateDetailView() {
        app.homeView.topicChip("Slate 2").wait().tap()
        app.slateDetailView.recommendationCell("Slate 1, Recommendation 1").wait()
        app.slateDetailView.recommendationCell("Slate 1, Recommendation 2").verify()
        app.slateDetailView.recommendationCell("Slate 1, Recommendation 3").verify()
    }

    func test_tappingRecommendationCell_opensItemInReader() {
        app.homeView.recommendationCell("Slate 1, Recommendation 1").wait().tap()
        app.readerView.cell(containing: "Jacob and David").wait()
    }

    func test_tappingRecommendationCellInSlateDetailView_opensItemInReader() {
        app.homeView.topicChip("Slate 1").wait().tap()
        app.slateDetailView.recommendationCell("Slate 1, Recommendation 1").wait().tap()
        app.readerView.cell(containing: "Jacob and David").wait()
    }

    func test_tappingSaveButtonInRecommendationCell_savesItemToList() {
        let cell = app.homeView.recommendationCell("Slate 1, Recommendation 1")
        let saveButton = cell.saveButton.wait()

        let saveRequestExpectation = expectation(description: "A save mutation request")
        let archiveRequestExpectation = expectation(description: "An archive mutation request")
        var promise: EventLoopPromise<Response>?
        server.routes.post("/graphql") { request, loop in
            let apiRequest = ClientAPIRequest(request)

            if apiRequest.isForSlateLineup {
                return Response.slateLineup()
            } else if apiRequest.isForSlateDetail {
                return Response.slateDetail()
            } else if apiRequest.isForMyListContent {
                return Response.myList()
            } else if apiRequest.isForArchivedContent {
                return Response.archivedContent()
            } else if apiRequest.isToSaveAnItem {
                XCTAssertTrue(apiRequest.contains("https:\\/\\/example.com\\/item-1"))
                saveRequestExpectation.fulfill()
                promise = loop.makePromise()
                return promise!.futureResult
            } else if apiRequest.isToArchiveAnItem {
                archiveRequestExpectation.fulfill()
                return Response.archive()
            } else {
                fatalError("Unexpected request")
            }
        }

        saveButton.tap()
        XCTAssertEqual(saveButton.label, "Saved")

        app.tabBar.myListButton.tap()
        app.myListView.itemView(matching: "Slate 1, Recommendation 1").wait()

        wait(for: [saveRequestExpectation], timeout: 1)

        promise?.succeed(Response.saveItem())
        app.myListView.itemView(matching: "Saved Recommendation 1").wait()

        app.tabBar.homeButton.tap()
        saveButton.tap()

        XCTAssertEqual(saveButton.label, "Save")
        wait(for: [archiveRequestExpectation], timeout: 1)
        XCTAssertFalse(app.myListView.itemView(matching: "Slate 1, Recommendation 1").exists)
    }

    func test_tappingSaveButtonInRecommendationCellinSlateDetailView_savesItemToList() {
        app.homeView.topicChip("Slate 1").wait().tap()

        do {
            let saveButton = app.slateDetailView.recommendationCell("Slate 1, Recommendation 1").saveButton.wait()
            saveButton.tap()
            XCTAssertEqual(saveButton.label, "Saved")
        }

        app.tabBar.myListButton.tap()
        app.myListView.itemView(matching: "Saved Recommendation 1").wait()

        app.tabBar.homeButton.tap()

        do {
            let saveButton = app.slateDetailView.recommendationCell("Slate 1, Recommendation 1").saveButton.wait()
            saveButton.tap()
            XCTAssertEqual(saveButton.label, "Save")
        }
    }
}

extension HomeTests {
    func test_pullToRefresh_fetchesUpdatedContent() {
        let home = app.homeView
        home.recommendationCell("Slate 1, Recommendation 1").wait()
        
        server.routes.post("/graphql") { request, _ in
            Response.slateLineup("updated-slates")
        }
        
        home.pullToRefresh()
        home.recommendationCell("Updated Slate 1, Recommendation 1").wait()
    }

    // Disabled
    // Started failing in Xcode 13.2.1
    // Error: Failed to determine hittability of "home-overscroll" Other: Activation point invalid and no suggested hit points based on element frame
    func xtest_overscrollingHome_showsOverscrollView() {
        let home = app.homeView
        let overscrollView = home.overscrollView

        home.slateHeader("Slate 1").wait()
        
        DispatchQueue.main.async {
            home.overscroll()
        }
        
        let exists = NSPredicate(format: "exists == 1")
        let doesExist = expectation(for: exists, evaluatedWith: overscrollView)
        let isHittable = NSPredicate(format: "isHittable == 1")
        let hittable = expectation(for: isHittable, evaluatedWith: overscrollView)
        wait(for: [doesExist, hittable], timeout: 20)
    }

    // Disabled
    // Started failing in Xcode 13.2.1
    // Error: Failed to determine hittability of "home-overscroll" Other: Activation point invalid and no suggested hit points based on element frame
    func xtest_overscrollingSlateDetail_showsOverscrollView() {
        app.homeView.topicChip("Slate 1").wait().tap()
        
        let slateDetail = app.slateDetailView
        let overscrollView = slateDetail.overscrollView
        slateDetail.recommendationCell("Slate 1, Recommendation 1").wait()

        
        DispatchQueue.main.async {
            slateDetail.overscroll()
        }
        
        let exists = NSPredicate(format: "exists == 1")
        let doesExist = expectation(for: exists, evaluatedWith: overscrollView)
        let isHittable = NSPredicate(format: "isHittable == 1")
        let hittable = expectation(for: isHittable, evaluatedWith: overscrollView)
        wait(for: [doesExist, hittable], timeout: 10)
    }
}
