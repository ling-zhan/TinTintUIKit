//
//  AlbumCell.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import UIKit
import Combine

class AlbumCell: UICollectionViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var cancellables = Set<AnyCancellable>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 清空圖片以避免重用錯誤
        thumbnailImageView.image = nil
        
        // 取消當前的圖片下載
        cancellables.forEach { $0.cancel() }
        
        cancellables.removeAll()
    }
    
    func configure(with album: Album) {
        idLabel.text = String(album.id)
        titleLabel.text = album.title
    }

}
