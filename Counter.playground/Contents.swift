import SwiftUI
import PlaygroundSupport

// MARK: Complier Error ❌

//struct ContentView: View {
//    var count = 0
//    
//    var body: some View {
//        VStack {
//            Text(count.description)
//            Button("Next") {
//               changeCount()
//            }
//        }
//    }
//    
//    private func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}



// MARK: Introduce @State ✅

//struct ContentView: View {
//    @State var count = 0
//
//    var body: some View {
//        VStack {
//            Text(count.description)
//            Button("Next") {
//               changeCount()
//            }
//        }
//    }
//
//    private func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}



// MARK: Introduce ViewModel - View doen't update ❌

//struct ContentView: View {
//    
//    @State var viewModel = ViewModel()
//    
//    var body: some View {
//        VStack {
//            Text(viewModel.count.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}
//
//class ViewModel {
//    private(set) var count = 0
//    
//    func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}



// MARK: Introduce @StateObject + ObservableObject ✅

//struct ContentView: View {
//    
//    @StateObject var viewModel = ViewModel()
//    
//    var body: some View {
//        VStack {
//            Text(viewModel.count.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}
//
//class ViewModel: ObservableObject {
//    @Published private(set) var count = 0
//    
//    func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}



// MARK: Introduce Observation ✅ - Note: Obervation is broken in playgrounds

//import Observation
//
//struct ContentView: View {
//    
//    @State var viewModel = ViewModel()
//    
//    var body: some View {
//        VStack {
//            Text(viewModel.count.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}
//
//@Observable
//class ViewModel {
//    private(set) var count = 0
//    
//    func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}



// MARK: Introduce computed property ✅

//import Observation
//
//struct ContentView: View {
//    
//    @State var viewModel = ViewModel()
//    
//    var body: some View {
//        VStack {
//            Text(viewModel.annotatedCount.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}
//
//@Observable
//class ViewModel {
//    private var count = 0
//    
//    func changeCount() {
//        count = Int.random(in: 0...100)
//    }
//}
//
//extension ViewModel {
//    var annotatedCount: String {
//        return "The view-model's count is: \(count)"
//    }
//}



// MARK: Introduce model ❌ - model is not @Observable

//import Observation
//
//// Model
//class Model {
//    private(set) var count = 0
//}
//
//extension Model {
//    func updateCount() {
//        count = Int.random(in: 0...100)
//    }
//}
//
////View-Model
//@Observable
//class ViewModel {
//    private var model = Model()
//}
//
//extension ViewModel {
//    var annotatedCount: String {
//        return "The view-model's count is: \(model.count)"
//    }
//}
//
//extension ViewModel {
//    func changeCount() {
//        model.updateCount()
//    }
//}
//
////View
//struct ContentView: View {
//
//    @State var viewModel = ViewModel()
//
//    var body: some View {
//        VStack {
//            Text(viewModel.annotatedCount.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}



// MARK: Introduce model ✅ - model is now @Observable

//import Observation
//
//// Model
//@Observable
//class Model {
//    private(set) var count = 0
//}
//
//extension Model {
//    func updateCount() {
//        count = Int.random(in: 0...100)
//    }
//}
//
////View-Model
//@Observable
//class ViewModel {
//    private var model = Model()
//}
//
//extension ViewModel {
//    var annotatedCount: String {
//        return "The view-model's count is: \(model.count)"
//    }
//}
//
//extension ViewModel {
//    func changeCount() {
//        model.updateCount()
//    }
//}
//
////View
//struct ContentView: View {
//
//    @State var viewModel = ViewModel()
//
//    var body: some View {
//        VStack {
//            Text(viewModel.annotatedCount.description)
//            Button("Next") {
//                viewModel.changeCount()
//            }
//        }
//    }
//}



// MARK: Introduce model ✅ - Note: Remove not required @Observable from ViewModel

import Observation

// Model
@Observable
class Model {
    private(set) var count = 0
}

extension Model {
    func updateCount() {
        count = Int.random(in: 0...100)
    }
}

//View-Model
@Observable
class ViewModel {
    private var model = Model()
}

extension ViewModel {
    var annotatedCount: String {
        return "The view-model's count is: \(model.count)"
    }
}

extension ViewModel {
    func changeCount() {
        model.updateCount()
    }
}

//View
struct ContentView: View {

    @State var viewModel = ViewModel()

    var body: some View {
        VStack {
            Text(viewModel.annotatedCount.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())
