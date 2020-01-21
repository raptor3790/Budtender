//
//  MainVC.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import SideMenu
import SDWebImage
import UIEmptyState
import TTSegmentedControl
import WebKit
import Crashlytics

class MainVC: CommonVC {
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var category: TTSegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var marginTop: NSLayoutConstraint!
    @IBOutlet weak var categoryHeight: NSLayoutConstraint!

    var filter: [Feed] = []
    var feeds: [Feed] = []
    var feedType: FeedType!

    var webView: WKWebView?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // fabric
        Answers.logLogin(withMethod: "Digits", success: true, customAttributes: [:])
        
        // has side menu
        sideMenu()

        // empty state
        emptyStateDataSource = self
        emptyStateDelegate = self

        // tableview
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.rowHeight = 100
        tableView.estimatedRowHeight = 100

        // category
        categoryHeight.constant = isLogged ? 48 : 0
        category.itemTitles = ["All", "Favorite", "Unwatched"]
        category.defaultTextFont = UIFont.systemFont(ofSize: 20)
        category.selectedTextFont = UIFont.systemFont(ofSize: 20)
        category.thumbColor = UIColor(rgb: 0x68A949)
        category.hasBounceAnimation = true
        category.allowDrag = false
        category.allowChangeThumbWidth = false
        category.didSelectItemWith = { index, title in
            self.loadCategory(index)
        }

        // load status at first time
        loadFeed(type: .status)

        view.layoutIfNeeded()

        // update device token
        if getBool(.refreshDeviceToken), let token = getString(.deviceToken) {
            let param: [String: Any] = [
                "dt": token,
                "os": "IOS"
            ]
            post(url: "/API_UpdateDeviceToken.php", param: param, indicator: false) { _ in self.clear(forKey: .refreshDeviceToken) }
        }

        // rating app
        if getInt(.ratingCount) == 5 {
            let alertVC = UIAlertController(
                title: "Rate Us",
                message: "Do you like our app?",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.set(0, forKey: .ratingCount)
            }))
            alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.openUrl("itms-apps://itunes.apple.com/app/id1340019859")
            }))
            present(alertVC, animated: true, completion: nil)
        }
    }

    // configure side menu
    func sideMenu() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "SideMenuVC") as? SideMenuVC else { return }
        vc.delegate = self
        SideMenuManager.default.menuLeftNavigationController = UISideMenuNavigationController(rootViewController: vc)
        SideMenuManager.default.menuAddPanGestureToPresent(toView: view)
        SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)
        SideMenuManager.default.menuAnimationBackgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "menubg"))
        SideMenuManager.default.menuBlurEffectStyle = .light
        SideMenuManager.default.menuPresentMode = .menuSlideIn
        SideMenuManager.default.menuFadeStatusBar = false
    }

    @IBAction func onMenuAction(_ sender: UIBarButtonItem) {
        present(SideMenuManager.default.menuLeftNavigationController!, animated: true, completion: nil)
    }

    @objc func onNewQuestionAction(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ask", sender: nil)
    }

    func loadFeed(type: FeedType) {
        // prevent load same feed type
        guard type != feedType else { return }

        var param: [String: Any]!
        if let token = getString(.authToken) {
            param = [
                "a": token,
                "t": type.rawValue,
                "uid": getInt(.userId)
            ]
        } else {
            param = [
                "a": "e89f8a00b477b9f658afca9ac91f8666",
                "t": type.rawValue
            ]
        }
        get(url: "/API_getfeed.php", param: param) { result in
            self.feedType = type
            self.category.selectItemAt(index: 0)
            switch type {
            case .status: self.title = "Steve's Status"
            case .news: self.title = "Canadian Cannabis News"
            case .faq: self.title = "Canabis Q/A"
            case .product: self.title = "Recommended Products"
            }

            // load feeds
            self.feeds = result.arrayValue.map { Feed(json: $0) }

            // category -> all
            self.filter.removeAll()
            self.filter.append(contentsOf: self.feeds)

            // tableview refresh
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)

            // layout
            if type != .status, self.marginTop.constant == 0 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.marginTop.constant = 0 - self.videoView.bounds.height - (self.isLogged ? 0 : self.category.bounds.height)
                    self.view.layoutIfNeeded()
                }) { success in
                    if success {
                        self.webView?.removeFromSuperview()
                        self.webView = nil
                    }
                }
            } else if type == .status, self.marginTop.constant < 0 {
                UIView.animate(withDuration: 0.3) {
                    self.marginTop.constant = 0
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    func loadCategory(_ index: Int) {
        switch index {
        case 0: // all
            self.filter.removeAll()
            self.filter.append(contentsOf: self.feeds)
        case 1: // favorite
            self.filter = self.feeds.filter { $0.favorite ?? false }
        case 2: // unwatched
            self.filter = self.feeds.filter { !($0.watched ?? false) }
        default:
            break
        }

        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "feedDetail", let vc = segue.destination as? DetailVC, let feed = sender as? Feed {
            vc.feed = feed
            vc.feedType = feedType
        }
    }
}

extension MainVC: SideMenuDelegate {
    func onStatus() {
        loadFeed(type: .status)
        self.navigationItem.rightBarButtonItem = nil
    }

    func onNews() {
        loadFeed(type: .news)
        self.navigationItem.rightBarButtonItem = nil
    }

    func onFAQ() {
        loadFeed(type: .faq)
        if let _ = getString(.authToken) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.onNewQuestionAction(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    func onProducts() {
        loadFeed(type: .product)
        self.navigationItem.rightBarButtonItem = nil
    }

    func onShare() {
        let shareVC = UIActivityViewController(activityItems: ["Check out Budtender app, Cannabis Culture in your phone. https://goo.gl/9jypQu"], applicationActivities: nil)
        shareVC.excludedActivityTypes = [.postToFacebook, .postToTwitter, .mail, .airDrop, .message]
        present(shareVC, animated: true, completion: nil)
    }

    func onLogout() {
        clear()
        navigationController?.popToRootViewController(animated: true)
    }
}

extension MainVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as? FeedTableViewCell else {
            fatalError("Dequeue Reusable Cell failed: FeedTableViewCell")
        }

        let feed = filter[indexPath.row]

        // load image
        if let imageURL = feed.imageURL, let url = URL(string: imageURL) {
            cell.photo.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "camera"))
        } else {
            cell.photo.image = #imageLiteral(resourceName: "camera")
        }
        // title
        cell.title.text = feed.title
        // body
        cell.body.text = feed.body
        // date
        cell.date.text = feed.date
        // go 2 detail or load video
        cell.accessoryType = feedType == .status ? .none : .disclosureIndicator

        // favorite
        if let token = getString(.authToken) {
            // logged in
            cell.favorite.setImage(feed.favorite ?? false ? #imageLiteral(resourceName: "favorite_on"): #imageLiteral(resourceName: "favorite_off"), for: .normal)
            cell.favorite.tag = feed.favorite ?? false ? 1 : 0
            cell.favorite.alpha = 1
            cell.onFavorite = { button in
                let newFavorite = button.tag == 0
                let param: [String: Any] = [
                    "a": token,
                    "uid": self.getInt(.userId),
                    "mid": feed.id!,
                    "isfavorite": newFavorite ? 1 : 0
                ]
                // toggle favorite and update server
                self.post(url: "/API_UpdateUserPreference.php", param: param) { _ in
                    // update data source
                    self.feeds.filter { $0.id == feed.id }.first?.favorite = newFavorite ? true : false

                    if self.category.currentIndex == 1, !newFavorite {
                        // remove cell on Favorite category when deselect favorite
                        self.tableView.beginUpdates()
                        self.filter.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                        self.reloadEmptyStateForTableView(self.tableView)
                    } else {
                        button.tag = newFavorite ? 1 : 0
                        button.setImage(newFavorite ? #imageLiteral(resourceName: "favorite_on"): #imageLiteral(resourceName: "favorite_off"), for: .normal)
                    }
                }
            }
        } else {
            // guest
            cell.favorite.alpha = 0
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = filter[indexPath.row]

        if feedType == .status {
            // play video
            if webView == nil {
                webView = WKWebView(frame: videoView.bounds, configuration: WKWebViewConfiguration())
                videoView.addSubview(webView!)
            }
            if let urlString = feed.clickURL, let url = URL(string: urlString) {
                webView?.isHidden = false
                webView?.load(URLRequest(url: url))
            } else {
                webView?.removeFromSuperview()
                webView = nil
            }
        } else {
            // detail page
            performSegue(withIdentifier: "feedDetail", sender: feed)
        }
        if let token = getString(.authToken) {
            let param: [String: Any] = [
                "a": token,
                "uid": getInt(.userId),
                "mid": feed.id!,
                "iswatched": 1
            ]
            post(url: "/API_UpdateUserPreference.php", param: param, indicator: false) { _ in
                // update data source
                self.feeds.filter { $0.id == feed.id }.first?.watched = true

                if self.category.currentIndex == 2 {
                    // remove cell on Favorite category when deselect favorite
                    self.tableView.beginUpdates()
                    self.filter.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.tableView.endUpdates()
                    self.reloadEmptyStateForTableView(self.tableView)
                }
            }
        }
    }
}

extension MainVC: UIEmptyStateDataSource, UIEmptyStateDelegate {
    var emptyStateImage: UIImage? {
        return #imageLiteral(resourceName: "no_entry")
    }

    var emptyStateImageSize: CGSize? {
        return CGSize(width: 50, height: 50)
    }

    var emptyStateTitle: NSAttributedString {
        let attrs = [
            NSAttributedStringKey.foregroundColor: UIColor(rgb: 0xE6794C),
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22)
        ]
        return NSAttributedString(string: "No Data", attributes: attrs)
    }

    func emptyStateViewWillShow(view: UIView) {
        if let view = view as? UIEmptyStateView {
            view.centerYOffset = feedType == .status ? videoView.bounds.height / 2 : 0
        }
    }
}
