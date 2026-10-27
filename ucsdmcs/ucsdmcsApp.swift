//
//  ucsdmcsApp.swift
//  ucsdmcs
//
//  Created by Lucius Scala on 9/9/26.
//

import SwiftUI

@main
struct ucsdmcsApp: App {
    @State private var dataService = DataService()
    @State private var deepLinkManager = DeepLinkManager()
    @State private var captain = CaptainSession()
    @State private var updateChecker = UpdateChecker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataService)
                .environment(deepLinkManager)
                .environment(captain)
                .environment(updateChecker)
                .tint(AppTheme.buttonBlue)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
        }
    }
}
