import UIKit
import WebKit
import CoreLocation

/// Author: Pratham
/// Stop Detail screen: shows the photo, notes, and distance from the user for
/// a selected stop, plus a WKWebView looking up the stop's name/category.
class StopDetailVC: UIViewController {

    /// Set by the presenting controller (TripDetailVC) before push.
    var stop: Stop?

    /// Shows the stop's saved photo, if any.
    @IBOutlet weak var photoImageView: UIImageView!
    /// Shows the stop's free-text notes, if any.
    @IBOutlet weak var notesLabel: UILabel!
    /// Shows distance from the user's current location, via RouteHelper.
    @IBOutlet weak var distanceLabel: UILabel!
    /// Container the WKWebView is added to programmatically, since WKWebView
    /// is more stable created in code than wired up as a storyboard IBOutlet.
    @IBOutlet weak var webContainerView: UIView!

    /// Web view looking up the stop's name/category, added as a subview of
    /// webContainerView in viewDidLoad rather than placed in the storyboard.
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = stop?.name ?? "Stop"

        if let photoURL = stop?.photoURL {
            photoImageView.image = UIImage(contentsOfFile: photoURL.path)
        }
        notesLabel.text = stop?.notes?.isEmpty == false ? stop?.notes : "No notes"

        setUpWebView()
        loadLookupURL()
        updateDistanceLabel()
    }

    /// Author: Neel. Geocodes the stop's name (via RouteHelper's cache) and, if the user's
    /// location is available, renders the distance between them; otherwise shows an
    /// unavailable state. Fills the placeholder per the team's IP-19/IP-23 handoff plan.
    private func updateDistanceLabel() {
        guard let name = stop?.name else { return }
        distanceLabel.text = "Finding distance…"

        RouteHelper.shared.coordinate(forStopName: name) { [weak self] coordinate in
            guard let self else { return }
            guard let coordinate, let userLocation = RouteHelper.shared.currentLocation else {
                self.distanceLabel.text = "Distance unavailable"
                return
            }
            let stopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.distanceLabel.text = RouteHelper.shared.distanceString(from: userLocation, to: stopLocation)
        }
    }

    /// Creates the WKWebView programmatically and pins it to fill webContainerView.
    private func setUpWebView() {
        webView = WKWebView(frame: webContainerView.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webContainerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webContainerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webContainerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webContainerView.bottomAnchor)
        ])
    }

    /// Loads a Wikipedia search for the stop's name/category into the web view.
    private func loadLookupURL() {
        guard let name = stop?.name,
              let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://en.wikipedia.org/wiki/Special:Search?search=\(query)") else { return }
        webView.load(URLRequest(url: url))
    }
}
