//
//  DailyUSApp.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI
import FirebaseCore

@main
struct DailyUSApp: App {
    init() {
        // 初始化 Firebase，只需要呼叫一次
        FirebaseApp.configure()
        // 可選：執行一次簡單的 Firestore 測試（若你已完成 Firestore 建置）
        // FirestoreInitializer.firestoreSmokeTest()
    }

    var body: some Scene {
        WindowGroup {
            
            ContentView() // 你的現有入口
        }
    }
}


//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
//
//    return true
//  }
//}

//@main
//struct YourApp: App {
//  // register app delegate for Firebase setup
//  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//
//
//  var body: some Scene {
//    WindowGroup {
//      NavigationView {
//        ContentView()
//      }
//    }
//  }
//}
