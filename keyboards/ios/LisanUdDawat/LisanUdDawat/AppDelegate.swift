import CoreText
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerBundledFonts()
        let tabs = UITabBarController()

        let setup = UINavigationController(rootViewController: ViewController())
        setup.tabBarItem = UITabBarItem(
            title: "Setup", image: UIImage(systemName: "keyboard"), tag: 0)

        let notepad = UINavigationController(rootViewController: NotepadViewController())
        notepad.tabBarItem = UITabBarItem(
            title: "Notepad", image: UIImage(systemName: "doc.text"), tag: 1)

        let contribute = UINavigationController(rootViewController: FederationSettingsViewController())
        contribute.tabBarItem = UITabBarItem(
            title: "Contribute", image: UIImage(systemName: "arrow.triangle.2.circlepath"), tag: 2)

        tabs.viewControllers = [setup, notepad, contribute]

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabs
        window?.makeKeyAndVisible()
        return true
    }

    private func registerBundledFonts() {
        for ext in ["ttf", "otf", "TTF", "OTF"] {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
