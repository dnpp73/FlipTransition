import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
}

final class FrontSideViewController: UITableViewController {
    @IBAction func backToFront(_ segue: UIStoryboardSegue) {
    }
}
