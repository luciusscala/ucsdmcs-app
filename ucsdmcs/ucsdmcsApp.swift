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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataService)
                .environment(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
        }
    }
}
