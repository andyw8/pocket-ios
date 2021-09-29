// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import Sails


class HomeTests: XCTestCase {
    var server: Application!
    var app: PocketAppElement!

    func listResponse(_ fixtureName: String = "initial-list") -> Response {
        Response {
            Status.ok
            Fixture
                .load(name: fixtureName)
                .replacing("PARTICLE_JSON", withFixtureNamed: "particle-sample", escape: .encodeJSON)
                .data
        }
    }

    func slateResponse() -> Response {
        Response {
            Status.ok
            Fixture.load(name: "slates")
                .replacing("PARTICLE_JSON", withFixtureNamed: "particle-sample", escape: .encodeJSON)
                .data
        }
    }

    func slateDetailResponse() -> Response {
        Response {
            Status.ok
            Fixture.load(name: "slate-detail")
                .replacing("PARTICLE_JSON", withFixtureNamed: "particle-sample", escape: .encodeJSON)
                .data
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false

        let uiApp = XCUIApplication()
        app = PocketAppElement(app: uiApp)

        server = Application()

        server.routes.post("/graphql") { request, _ in
            let requestBody = body(of: request)

            if requestBody!.contains("getSlateLineup")  {
                return self.slateResponse()
            } else if requestBody!.contains("getSlate(") {
                return self.slateDetailResponse()
            } else {
                return self.listResponse()
            }
        }

        server.routes.get("/hello") { _, _ in
            Response {
                Status.ok
                Fixture.data(name: "hello", ext: "html")
            }
        }

        try server.start()

        app.launch(
            arguments: [
                "clearKeychain",
                "clearCoreData",
                "clearImageCache"
            ],
            environment: [
                "accessToken": "test-access-token",
                "sessionGUID": "session-guid",
                "sessionUserID": "session-user-id",
            ]
        )
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
        app.readerView.cell(containing: "By Jacob & David").wait()
    }

    func test_tappingRecommendationCellInSlateDetailView_opensItemInReader() {
        app.homeView.topicChip("Slate 1").wait().tap()
        app.slateDetailView.recommendationCell("Slate 1, Recommendation 1").wait().tap()
        app.readerView.cell(containing: "By Jacob & David").wait()
    }
}
