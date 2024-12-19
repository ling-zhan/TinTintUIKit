//
//  AlbumViewController.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import UIKit
import Combine

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var viewModel = AlbumViewModel()
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        subscribeAlbum()
        viewModel.fetchAlbums()
    }
    
    func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        let nib = UINib(nibName: "AlbumCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "AlbumCell")
    }
    
    func subscribeAlbum() {
        viewModel.$albums
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
}

extension AlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let id = viewModel.albums[indexPath.row].id
        let url = viewModel.albums[indexPath.row].thumbnailUrl
        
        if let albumCell = cell as? AlbumCell {
            // 清空舊的圖片，避免錯誤展示
            albumCell.thumbnailImageView.image = nil
            
            // 檢查 Memory Cache
            if let cachedImage = ImageCacheManager.shared.getImage(forKey: url) {
                albumCell.thumbnailImageView.image = cachedImage
                return
            }
            
            // 檢查 Disk Cache
            if let diskImage = ImageCacheManager.shared.getImageFromDisk(forKey: url) {
                albumCell.thumbnailImageView.image = diskImage
                // 儲存到 Memory Cache
                ImageCacheManager.shared.saveImage(diskImage, id: id, forKey: url)
                return
            }
            
            HttpManager.shared.fetchImage(from: url, id: id)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        print("圖片抓取失敗：\(error)")
                    case .finished:
                        break
                    }
                } receiveValue: { [weak self] image in
                    guard let self = self else { return }
                    // 確保該 Cell 尚未被重用後再更新圖片
                    if let visibleCell = collectionView.cellForItem(at: indexPath) as? AlbumCell {
                        visibleCell.thumbnailImageView.image = image
                        
                        // 儲存圖片到 Cache
                        ImageCacheManager.shared.saveImage(image, id: id, forKey: url)
                        ImageCacheManager.shared.saveImageToDisk(image, id: id, forKey: url)
                    }
                }
                // 防止多次下載
                .store(in: &albumCell.cancellables)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCell", for: indexPath) as! AlbumCell
        let album = viewModel.albums[indexPath.row]
        cell.configure(with: album)
        return cell
    }
    
}

extension AlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        /* 計算每個 Cell 的寬度 */
        
        // 每列 4 個 Cell
        let cellWidth = collectionView.frame.width / 4
        // 回傳正方型
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
