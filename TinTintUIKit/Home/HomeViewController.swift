//
//  HomeViewController.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func toAlbumViewControllerAction(_ sender: Any) {
        let albumViewController = AlbumViewController()
        self.navigationController?.pushViewController(albumViewController, animated: true)
    }

}
