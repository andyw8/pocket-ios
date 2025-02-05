// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Sails


struct ClientAPIRequest {
    private let request: Request
    private let requestBody: String?

    init(_ request: Request) {
        self.request = request
        self.requestBody = body(of: request)
    }

    var isEmpty: Bool {
        requestBody == nil
    }

    var isForMyListContent: Bool {
        contains("userByToken") && !contains(#""isArchived":true"#)
    }

    var isForArchivedContent: Bool {
        contains("userByToken") && contains(#""isArchived":true"#)
    }
    
    var isForFavoritedArchivedContent: Bool {
        contains("userByToken") && contains(#""isArchived":true"#) && contains(#""isFavorite":true"#)
    }

    var isForSlateLineup: Bool {
        contains("getSlateLineup")
    }

    var isToArchiveAnItem: Bool {
        contains("updateSavedItemArchive")
    }

    var isToDeleteAnItem: Bool {
        contains("deleteSavedItem")
    }

    var isToFavoriteAnItem: Bool {
        contains("updateSavedItemFavorite")
    }

    var isToUnfavoriteAnItem: Bool {
        contains("updateSavedItemUnFavorite")
    }

    var isForSlateDetail: Bool {
        contains("getSlate(")
    }

    var isToSaveAnItem: Bool {
        contains("upsertSavedItem")
    }

    func contains(_ string: String) -> Bool {
        requestBody?.contains(string) == true
    }
}
