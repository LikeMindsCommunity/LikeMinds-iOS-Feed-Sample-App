//
//  ReplyCommentTableViewCell.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 09/04/23.
//

import UIKit

class ReplyCommentTableViewCell: UITableViewCell {
    
    static let reuseIdentifier: String = String(describing: CommentHeaderViewCell.self)
    
    let commentHeaderStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 5
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let usernameAndBadgeStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let badgeImageView: UIImageView = {
        let imageSize = 18.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: imageSize, height: imageSize)
        imageView.drawCornerRadius(radius: CGSize(width: imageSize, height: imageSize))
        return imageView
    }()
    
    let usernameLabel: LMLabel = {
        let label = LMLabel()
        label.font = LMBranding.shared.font(14, .bold)
        label.text = "Pushpendra"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var badgeSpaceView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = .red
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let commentAndMoreStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    var commentLabel: LMLabel = {
        let label = LMLabel()
        label.numberOfLines = 0
        label.font = LMBranding.shared.font(14, .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var spaceView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = .red
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let moreImageView: UIImageView = {
        let menuImageSize = 30
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: menuImageSize, height: menuImageSize))
        imageView.backgroundColor = .white
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(systemName: "ellipsis")
        imageView.tintColor = .darkGray
        imageView.preferredSymbolConfiguration = .init(pointSize: 20, weight: .light, scale: .large)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: 24, height: 22)
        return imageView
    }()
    
    let likeAndReplyStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let likeStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let likeImageView: UIImageView = {
        let imageSize = 20.0
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(systemName: "suit.heart")
        imageView.tintColor = .darkGray
        imageView.preferredSymbolConfiguration = .init(pointSize: 15, weight: .light, scale: .medium)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: imageSize, height: imageSize)
        return imageView
    }()
    
    let likeCountLabel: LMLabel = {
        let label = LMLabel()
        label.textColor = .gray
        label.font = LMBranding.shared.font(12, .regular)
        label.text = "Like"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var likeAndTimeSpaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let timeLabel: LMLabel = {
        let label = LMLabel()
        label.textColor = .gray
        label.font = LMBranding.shared.font(12, .regular)
        label.text = "2h"
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() -> Void {
        contentView.addSubview(commentHeaderStackView)
        commentHeaderStackView.addArrangedSubview(usernameAndBadgeStackView)
        usernameAndBadgeStackView.addArrangedSubview(usernameLabel)
        usernameAndBadgeStackView.addArrangedSubview(badgeImageView)
        usernameAndBadgeStackView.addArrangedSubview(badgeSpaceView)
        badgeSpaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        commentAndMoreStackView.addArrangedSubview(commentLabel)
        commentAndMoreStackView.addArrangedSubview(spaceView)
        spaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        commentAndMoreStackView.addArrangedSubview(moreImageView)
        commentHeaderStackView.addArrangedSubview(commentAndMoreStackView)
        likeStackView.addArrangedSubview(likeImageView)
        likeStackView.addArrangedSubview(likeCountLabel)
        likeAndReplyStackView.addArrangedSubview(likeStackView)
        likeAndReplyStackView.addArrangedSubview(likeAndTimeSpaceView)
        likeAndTimeSpaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        likeAndReplyStackView.addArrangedSubview(timeLabel)
        commentHeaderStackView.addArrangedSubview(likeAndReplyStackView)
        let g = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            commentHeaderStackView.topAnchor.constraint(equalTo: g.topAnchor),
            commentHeaderStackView.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 32),
            commentHeaderStackView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            commentHeaderStackView.bottomAnchor.constraint(equalTo: g.bottomAnchor)
        ])
        
    }

}