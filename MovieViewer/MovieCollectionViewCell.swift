//
//  MovieCollectionViewCell.swift
//  MovieViewer
//
//  Created by Singh, Jagdeep on 10/14/16.
//  Copyright © 2016 Singh, Jagdeep. All rights reserved.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    
    var movieImageView: UIImageView!
    
    override func awakeFromNib() {
        movieImageView = UIImageView(frame: contentView.frame)
        movieImageView.contentMode = .scaleAspectFill
        movieImageView.clipsToBounds = true
        contentView.addSubview(movieImageView)
    }
    
}
