//
//  NetworkErrorView.swift
//  Demoly
//

import SwiftUI

struct NetworkErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        ActionPromptView(
            icon: "wifi.exclamationmark",
            title: "Connection Error",
            message: message,
            buttonTitle: "Tap to Retry",
            action: retryAction
        )
    }
}

#Preview {
    NetworkErrorView(message: "Could not connect to the server.") {}
}
