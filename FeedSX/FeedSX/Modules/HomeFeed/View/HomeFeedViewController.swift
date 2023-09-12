//
//  HomeFeedViewController.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 27/03/23.
//

import Foundation
import UIKit
import Kingfisher
import BSImagePicker
import PDFKit
import LikeMindsFeed
import AVFoundation

public final class HomeFeedViewControler: BaseViewController {
    
    let feedTableView: UITableView = UITableView()
    let homeFeedViewModel = HomeFeedViewModel()
    let refreshControl = UIRefreshControl()
    var bottomLoadSpinner: UIActivityIndicatorView!
    fileprivate var lastKnowScrollViewContentOfsset: CGFloat = 0
    private var createButtonWidthConstraints: NSLayoutConstraint?
    private static let createPostTitle = "NEW RESOURCE"
    let createPostButton: LMButton = {
        let createPost = LMButton()
        createPost.setImage(UIImage(systemName: ImageIcon.calenderBadgePlus), for: .normal)
        createPost.setTitle(createPostTitle, for: .normal)
        createPost.titleLabel?.font = LMBranding.shared.font(13, .medium)
        createPost.tintColor = .white
        createPost.backgroundColor = LMBranding.shared.buttonColor
        createPost.clipsToBounds = true
        createPost.translatesAutoresizingMaskIntoConstraints = false
        return createPost
    }()
    
    let postingProgressSuperView: UIView = {
        let sv = UIView()
        sv.backgroundColor = .white
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let postingProgressShimmerView: HomeFeedShimmerView = {
        let width = UIScreen.main.bounds.width
        let sView = HomeFeedShimmerView(frame: .zero)
//        sv.backgroundColor = .white
//        sView.translatesAutoresizingMaskIntoConstraints = false
        return sView
    }()
    
    let postingProgressSuperStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .vertical
        sv.alignment = .fill
        sv.distribution = .fillProportionally
        sv.backgroundColor = .white
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let postingProgressStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let postingImageView: UIImageView = {
        let imageSize = 50.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: imageSize, height: imageSize)
        return imageView
    }()
    
    let postingImageSuperView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSizeConstraint(width: 70, height: 70)
        return view
    }()
    
    let postingLabel: LMLabel = {
        let label = LMLabel()
        label.font = LMBranding.shared.font(16, .medium)
        label.text = "Posting"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    let leftTitleLabel: LMLabel = {
        let label = LMLabel()
        label.font = LMBranding.shared.font(24, .medium)
        label.textColor = LMBranding.shared.headerColor.isDarkColor ? .white : ColorConstant.navigationTitleColor
        label.text = "Community"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var spaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let progressIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    var notificationBarItem: UIBarButtonItem!
    let notificationBellButton: LMButton = {
        let button = LMButton(frame: CGRect(x: 0, y: 6, width: 44, height: 44))
        button.setImage(UIImage(systemName: ImageIcon.bellFillIcon), for: .normal)
        button.tintColor = ColorConstant.likeTextColor
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22), forImageIn: .normal)
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let notificationBadgeLabel: LMPaddedLabel = {
        let badgeSize = 20
        let label = LMPaddedLabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        label.paddingLeft = 2
        label.paddingRight = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.textColor = .white
        label.font = LMBranding.shared.font(12, .regular)
        label.backgroundColor = .systemRed
        return label
    }()
    var isPostCreatingInProgress: Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        setupTableView()
        setupCreateButton()
        setupPostingProgress()
        self.createPostButton.isHidden = true
        homeFeedViewModel.delegate = self
        self.postingImageSuperView.superview?.isHidden = true
        homeFeedViewModel.getFeed()
        createPostButton.addTarget(self, action: #selector(createNewPost), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(postEditCompleted), name: .postEditCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationCompleted), name: .postCreationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationStarted), name: .postCreationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFeed), name: .refreshHomeFeedData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDataObject), name: .refreshHomeFeedDataObject, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorMessage), name: .errorInApi, object: nil)
//        self.setTitleAndSubtile(title: "Home Feed", subTitle: nil)
        self.setRightItemsOfNavigationBar()
        self.setLeftItemOfNavigationBar()
        LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Feed.opened, eventProperties: ["feed_type": "universal_feed"])
        self.feedTableView.backgroundColor = ColorConstant.backgroudColor
        self.view.backgroundColor = ColorConstant.backgroudColor
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        homeFeedViewModel.getMemberState()
        homeFeedViewModel.getUnreadNotificationCount()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideo()
    }
    
    @objc func refreshDataObject(notification: Notification) {
        if let postData = notification.object as? PostFeedDataView {
            self.homeFeedViewModel.refreshFeedDataObject(postData)
            guard let index = homeFeedViewModel.feeds.firstIndex(where: {$0.postId == postData.postId}) else {return }
            self.feedTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    func setRightItemsOfNavigationBar() {
        let containView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let profileImageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
        profileImageview.center = containView.center
        profileImageview.makeCircleView()
        profileImageview.setImage(withUrl: LocalPrefrerences.getUserData()?.imageUrl ?? "", placeholder: UIImage.generateLetterImage(with:  LocalPrefrerences.getUserData()?.name ?? ""))
        
        containView.addSubview(profileImageview)
        let profileBarButton = UIBarButtonItem(customView: containView)
        setNotificationBarItem()
        self.navigationItem.rightBarButtonItems = [profileBarButton, notificationBarItem]
        guard let parent = self.parent else { return }
        parent.navigationItem.rightBarButtonItem = notificationBarItem
    }
    
    func setNotificationBarItem() {
        notificationBarItem = UIBarButtonItem(customView: notificationBellButton)
        notificationBellButton.addTarget(self, action: #selector(notificationIconClicked), for: .touchUpInside)
        NSLayoutConstraint.activate([
            notificationBellButton.widthAnchor.constraint(equalToConstant: 44),
            notificationBellButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    func showBadge(withCount count: Int) {
        notificationBadgeLabel.text = count > 99 ? "99+" : "\(count)"
        notificationBellButton.addSubview(notificationBadgeLabel)
        NSLayoutConstraint.activate([
            notificationBadgeLabel.leftAnchor.constraint(equalTo: notificationBellButton.leftAnchor, constant: 16),
            notificationBadgeLabel.topAnchor.constraint(equalTo: notificationBellButton.topAnchor, constant: 4),
            notificationBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            notificationBadgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setLeftItemOfNavigationBar() {
        let leftItem = UIBarButtonItem(customView: leftTitleLabel)
        self.navigationItem.leftBarButtonItem = leftItem
    }
    
    @objc func postCreationStarted(notification: Notification) {
        print("postCreationStarted")
        self.isPostCreatingInProgress = true
        self.postingImageSuperView.superview?.isHidden = false
        if let image = notification.object as? UIImage {
            postingImageView.superview?.isHidden = false
            postingImageView.image = image
        } else {
            self.postingImageView.isHidden = true
        }
        if homeFeedViewModel.feeds.count > 0 {
            self.feedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    @objc func postCreationCompleted(notification: Notification) {
        print("postCreationCompleted")
        self.isPostCreatingInProgress = false
        self.postingImageSuperView.superview?.isHidden = true
        if let error = notification.object as? String {
            self.presentAlert(message: error)
            return
        }
        refreshFeed()
        if homeFeedViewModel.feeds.count > 0 {
            self.feedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    @objc func postEditingStarted(notification: Notification) {
        print("postEditingStarted")
        self.postingImageSuperView.superview?.isHidden = false
        if let image = notification.object as? UIImage {
            postingImageView.superview?.isHidden = false
            postingImageView.image = image
        } else {
            self.postingImageView.isHidden = true
        }
    }
    
    @objc func postEditCompleted(notification: Notification) {
        print("postEditCompleted")
        self.postingImageSuperView.superview?.isHidden = true
        let notificationObject = notification.object
        if let error = notificationObject as? String {
            self.presentAlert(message: error)
            return
        }
        let updatedAtIndex = self.homeFeedViewModel.updateEditedPost(postDetail: notificationObject as? PostFeedDataView)
        self.feedTableView.reloadRows(at: [IndexPath(row: updatedAtIndex, section: 0)], with: .none)
    }
    
    func setupTableView() {
        self.postingProgressSuperView.addSubview(postingProgressSuperStackView)
        self.view.addSubview(postingProgressSuperView)
        self.view.addSubview(feedTableView)
        self.view.addSubview(createPostButton)
        feedTableView.translatesAutoresizingMaskIntoConstraints = false
        feedTableView.topAnchor.constraint(equalTo: postingProgressSuperView.bottomAnchor).isActive = true
        feedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        feedTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        feedTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        feedTableView.showsVerticalScrollIndicator = false
        
        feedTableView.register(UINib(nibName: HomeFeedVideoCell.nibName, bundle: HomeFeedVideoCell.bundle), forCellReuseIdentifier: HomeFeedVideoCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedImageCell.nibName, bundle: HomeFeedImageCell.bundle), forCellReuseIdentifier: HomeFeedImageCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedLinkCell.nibName, bundle: HomeFeedLinkCell.bundle), forCellReuseIdentifier: HomeFeedLinkCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedPDFCell.nibName, bundle: HomeFeedPDFCell.bundle), forCellReuseIdentifier: HomeFeedPDFCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedArticleCell.nibName, bundle: HomeFeedArticleCell.bundle), forCellReuseIdentifier: HomeFeedArticleCell.nibName)
        feedTableView.register(UINib(nibName: HomeFeedWithoutResourceCell.nibName, bundle: HomeFeedWithoutResourceCell.bundle), forCellReuseIdentifier: HomeFeedWithoutResourceCell.nibName)
        
        
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        feedTableView.refreshControl = refreshControl
        setupSpinner()
    }
    func setupSpinner(){
        bottomLoadSpinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height:40))
        bottomLoadSpinner.color = .gray
        self.feedTableView.tableFooterView = bottomLoadSpinner
        bottomLoadSpinner.hidesWhenStopped = true
    }
    
    func setupCreateButton() {
        createPostButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        createPostButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        createButtonWidthConstraints = createPostButton.widthAnchor.constraint(equalToConstant: 170)
        createButtonWidthConstraints?.isActive = true
        createPostButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 10)
        createPostButton.layer.cornerRadius = 25
    }
    
    func setupPostingProgress() {
//        feedTableView.tableHeaderView = postingProgressShimmerView
//        postingProgressSuperStackView.addArrangedSubview(postingProgressShimmerView)
        postingProgressSuperStackView.addArrangedSubview(postingProgressStackView)
        postingProgressStackView.addArrangedSubview(postingImageSuperView)
        postingProgressStackView.addArrangedSubview(postingLabel)
        postingProgressStackView.addArrangedSubview(spaceView)
        postingProgressStackView.addArrangedSubview(progressIndicator)
        postingImageSuperView.addSubview(postingImageView)
        postingImageView.centerYAnchor.constraint(equalTo: self.postingImageSuperView.centerYAnchor).isActive = true
        postingImageView.centerXAnchor.constraint(equalTo: self.postingImageSuperView.centerXAnchor).isActive = true
        spaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        
        postingProgressSuperView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        postingProgressSuperView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        postingProgressSuperView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        
        postingProgressSuperStackView.topAnchor.constraint(equalTo: postingProgressSuperView.safeAreaLayoutGuide.topAnchor).isActive = true
        postingProgressSuperStackView.bottomAnchor.constraint(equalTo: postingProgressSuperView.bottomAnchor).isActive = true
        postingProgressSuperStackView.rightAnchor.constraint(equalTo: postingProgressSuperView.rightAnchor, constant: -16).isActive = true
        postingProgressSuperStackView.leftAnchor.constraint(equalTo: postingProgressSuperView.leftAnchor, constant: 16).isActive = true
    }
    
    @objc func createNewPost() {
        if self.isPostCreatingInProgress {
            self.presentAlert(message: MessageConstant.postingInProgress)
            return
        }
        guard self.homeFeedViewModel.hasRightForCreatePost() else  {
            self.presentAlert(message: MessageConstant.restrictToCreatePost)
            return
        }
        
        showNewPostMenu()
    }
    
    func moveToAddResources(resourceType: CreatePostViewModel.AttachmentUploadType, url: URL?) {
        let createView = CreatePostViewController(nibName: "CreatePostViewController", bundle: Bundle(for: CreatePostViewController.self))
        createView.resourceType = resourceType
        createView.resourceURL = url
        LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.creationStarted, eventProperties: nil)
        self.navigationController?.pushViewController(createView, animated: true)
    }
    
    func showNewPostMenu() {
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let articalAction = UIAlertAction(title: "Add Article", style: .default) {[weak self] action in
            self?.moveToAddResources(resourceType: .article, url: nil)
        }
        let videoAction = UIAlertAction(title: "Add Video", style: .default) {[weak self] action in
            self?.addImageOrVideoResource()
        }
        let pdfAction = UIAlertAction(title: "Add PDF", style: .default) {[weak self] action in
            self?.addPDFResource()
        }
        let linkAction = UIAlertAction(title: "Add Link", style: .default) { [weak self] action in
            self?.addLinkResource()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alertSheet.addAction(articalAction)
        alertSheet.addAction(videoAction)
        alertSheet.addAction(pdfAction)
        alertSheet.addAction(linkAction)
        alertSheet.addAction(cancel)
        self.present(alertSheet, animated: true)
    }
    
    func enableCreateNewPostButton(isEnable: Bool) {
        if isEnable {
            self.createPostButton.backgroundColor = LMBranding.shared.buttonColor
        } else {
            self.createPostButton.backgroundColor = .lightGray
        }
    }
    
    @objc func refreshFeed() {
        homeFeedViewModel.pullToRefresh()
    }
    
    @objc func notificationIconClicked() {
        let notificationFeedVC = NotificationFeedViewController()
        self.navigationController?.pushViewController(notificationFeedVC, animated: true)
    }
    
    func newPostButtonExapndAndCollapes(_ offsetY: CGFloat) {
        if offsetY > self.lastKnowScrollViewContentOfsset {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration:0.2) { [weak self] in
                guard let weakSelf = self else {return}
                weakSelf.createPostButton.setTitle(nil, for: .normal)
                weakSelf.createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 0)
                self?.createButtonWidthConstraints?.isActive = false
                self?.createButtonWidthConstraints = self?.createPostButton.widthAnchor.constraint(equalToConstant: 50.0)
                self?.createButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        }
        else {
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) {[weak self] in
                guard let weakSelf = self else {return}
                weakSelf.createPostButton.setTitle(Self.createPostTitle, for: .normal)
                weakSelf.createPostButton.setInsets(forContentPadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), imageTitlePadding: 10)
                self?.createButtonWidthConstraints?.isActive = false
                self?.createButtonWidthConstraints = self?.createPostButton.widthAnchor.constraint(equalToConstant: 170.0)
                self?.createButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        }
    }
    
    func setHomeFeedEmptyView() {
        let emptyView = EmptyHomeFeedView(frame: CGRect(x: 0, y: 0, width: feedTableView.bounds.size.width, height: feedTableView.bounds.size.height))
        emptyView.delegate = self
        feedTableView.backgroundView = emptyView
        feedTableView.separatorStyle = .none
    }
    
    func addImageOrVideoResource() {
        let imagePicker = ImagePickerController()
        imagePicker.settings.selection.max = 1
        imagePicker.settings.theme.selectionStyle = .checked
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.video]
        imagePicker.settings.selection.unselectOnReachingMax = true
        imagePicker.doneButton.isEnabled = false
        self.presentImagePicker(imagePicker, select: {[weak self] (asset) in
            print("Selected: \(asset)")
            asset.getURL { [weak self] responseURL in
                guard let url = responseURL else { return }
                DispatchQueue.main.async {
                    let mediaType: CreatePostViewModel.AttachmentUploadType = asset.mediaType == .image ? .image : .video
                    if mediaType == .video {
                        let asset = AVAsset(url: url)
                        let duration = asset.duration
                        let durationTime = CMTimeGetSeconds(duration)
                        if durationTime > (10*60) {
                            self?.showErrorAlert(message: "Max video duration is 10 mins!")
                            return
                        }
                    }
                    self?.moveToAddResources(resourceType: mediaType, url: url)
                    imagePicker.dismiss(animated: true)
                }
            }
        }, deselect: {_ in }, cancel: {_ in }, finish: {_ in }, completion: {})
    }
    
    func addLinkResource() {
        let alertView = UIAlertController(title: "Enter Link URL", message: "Enter the link/URL you want to post.", preferredStyle: .alert)
        alertView.addTextField { (txtField) in
            txtField.placeholder = "http://www.example.com"
        }
        let actionSubmit = UIAlertAction(title: "Continue", style: .default) { [weak self] (action) in
            guard let txtfield = alertView.textFields?.first,
                  let inputText = txtfield.text?.trimmedText(),
                  let url = inputText.detectedFirstURL else {
                return
            }
            self?.moveToAddResources(resourceType: .link, url: url)
            alertView.dismiss(animated: true, completion: nil)
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            alertView.dismiss(animated: true)
        }
        alertView.addAction(actionSubmit)
        alertView.addAction(actionCancel)
        self.present(alertView, animated: true, completion: nil)
    }
    
    func addPDFResource() {
        let types: [String] = [
            "com.adobe.pdf"
        ]
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
}

extension HomeFeedViewControler: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homeFeedViewModel.feeds.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feed = homeFeedViewModel.feeds[indexPath.row]
        switch feed.postAttachmentType() {
        case .document:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedPDFCell.nibName, for: indexPath) as! HomeFeedPDFCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        case .link:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedLinkCell.nibName, for: indexPath) as! HomeFeedLinkCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedImageCell.nibName, for: indexPath) as! HomeFeedImageCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        case .article:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedArticleCell.nibName, for: indexPath) as! HomeFeedArticleCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedVideoCell.nibName, for: indexPath) as! HomeFeedVideoCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedWithoutResourceCell.nibName, for: indexPath) as! HomeFeedWithoutResourceCell
            cell.setupFeedCell(feed, withDelegate: self)
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? HomeFeedImageVideoTableViewCell {
            cell.pauseAllInVisibleVideos()
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? HomeFeedImageVideoTableViewCell {
            cell.pauseAllInVisibleVideos()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postData = homeFeedViewModel.feeds[indexPath.row]
        let postId = postData.postId 
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        self.lastKnowScrollViewContentOfsset = scrollView.contentOffset.y

        checkWhichVideoToEnable()
        if offsetY > contentHeight - (scrollView.frame.height + 60) && !homeFeedViewModel.isFeedLoading
        {
            homeFeedViewModel.getFeed()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        newPostButtonExapndAndCollapes(offsetY)
    }
    
    func checkWhichVideoToEnable() {
        
        for cell in feedTableView.visibleCells as [UITableViewCell] {
            
            if let cell = cell as? HomeFeedVideoCell {
                
                let indexPath = feedTableView.indexPath(for: cell)
                let cellRect = feedTableView.rectForRow(at: indexPath!)
                let superView = feedTableView.superview
                
                let convertedRect = feedTableView.convert(cellRect, to: superView)
                let intersect = CGRectIntersection(feedTableView.frame, convertedRect)
                let visibleHeight = CGRectGetHeight(intersect)
                if visibleHeight > self.view.bounds.size.height * 0.6 {  // only if 60% of the cell is visible.
                    //cell is visible more than 60%
                    cell.pauseVideo()
                } else {
                    cell.pauseVideo()
                }
            } else {
//                pauseAllVideo()
            }
        }
    }
    
    func pauseAllVideo() {
        for cell in feedTableView.visibleCells as [UITableViewCell] {
            (cell as? HomeFeedVideoCell)?.pauseVideo()
        }
    }
    
}

extension HomeFeedViewControler: HomeFeedViewModelDelegate {
    
    func didReceivedFeedData(success: Bool) {
        if homeFeedViewModel.feeds.count == 0 {
            setHomeFeedEmptyView()
            self.createPostButton.isHidden = true
        } else {
            feedTableView.restore()
            self.createPostButton.isHidden = false
        }
        bottomLoadSpinner.stopAnimating()
        refreshControl.endRefreshing()
        guard success else {return}
        feedTableView.reloadData()
    }
    
    func didReceivedMemberState() {
        if self.homeFeedViewModel.hasRightForCreatePost() {
            self.createPostButton.backgroundColor = LMBranding.shared.buttonColor
        } else {
            self.createPostButton.backgroundColor = .lightGray
        }
    }
    
    func reloadSection(_ indexPath: IndexPath) {
        self.feedTableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func updateNotificationFeedCount(_ count: Int){
        if count > 0 {
            showBadge(withCount: count)
        } else {
            notificationBadgeLabel.removeFromSuperview()
        }
    }
}

extension HomeFeedViewControler: ProfileHeaderViewDelegate {
    func didTapOnMoreButton(selectedPost: PostFeedDataView?) {
        guard let menues = selectedPost?.postMenuItems else { return }
        print("more taped reached VC")
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for menu in menues {
            switch menu.id {
            case .report:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    let reportContent = ReportContentViewController(nibName: "ReportContentViewController", bundle: Bundle(for: ReportContentViewController.self))
                    reportContent.entityId = selectedPost?.postId
                    reportContent.uuid = selectedPost?.postByUser?.uuid
                    reportContent.reportEntityType = .post
                    self?.navigationController?.pushViewController(reportContent, animated: true)
                }
            case .delete:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    let deleteController = DeleteContentViewController(nibName: "DeleteContentViewController", bundle: Bundle(for: DeleteContentViewController.self))
                    deleteController.modalPresentationStyle = .overCurrentContext
                    deleteController.postId = selectedPost?.postId
                    deleteController.delegate = self
                    deleteController.isAdminRemoving = LocalPrefrerences.uuid() != (selectedPost?.postByUser?.uuid ?? "") ? (self?.homeFeedViewModel.isAdmin() ?? false) :  false
                    self?.navigationController?.present(deleteController, animated: false)
                }
            case .edit:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.edited, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    let editPost = EditPostViewController(nibName: "EditPostViewController", bundle: Bundle(for: EditPostViewController.self))
                    editPost.postId = postId
                    self?.navigationController?.pushViewController(editPost, animated: true)
                }
            case .pin:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.pinned, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    self?.homeFeedViewModel.pinUnpinPost(postId: postId)
                }
            case .unpin:
                actionSheet.addAction(withOptions: menu.name) { [weak self] in
                    guard let postId = selectedPost?.postId else {return}
                    self?.homeFeedViewModel.trackPostActionEvent(postId: postId, creatorId: selectedPost?.postByUser?.uuid ?? "", eventName: LMFeedAnalyticsEventName.Post.unpinned, postType: selectedPost?.postAttachmentType().rawValue ?? "")
                    self?.homeFeedViewModel.pinUnpinPost(postId: postId)
                }
            default:
                break
            }
        }
        actionSheet.addCancelAction(withOptions: "Cancel", actionHandler: nil)
        self.present(actionSheet, animated: true)
    }
    
    func didTapOnFeedCollection(_ feedDataView: PostFeedDataView?) {
        guard let postId = feedDataView?.postId else {return}
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }
}

extension HomeFeedViewControler: ActionsFooterViewDelegate {
   
    func didTappedAction(withActionType actionType: CellActionType, postData: PostFeedDataView?) {
        switch actionType {
        case .like:
            guard let postId = postData?.postId else { return }
            homeFeedViewModel.likePost(postId: postId)
        case .savePost:
            guard let postId = postData?.postId else { return }
            homeFeedViewModel.savePost(postId: postId)
        case .comment:
            guard let postId = postData?.postId else { return }
            let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
            postDetail.postId = postId
            postDetail.isViewPost = false
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Comment.listOpened, eventProperties: ["post_id": postId])
            self.navigationController?.pushViewController(postDetail, animated: true)
        case .likeCount:
            guard let postId = postData?.postId, (postData?.likedCount ?? 0) > 0 else { return }
            let likedUserListView = LikedUserListViewController()
            likedUserListView.viewModel = .init(postId: postId, commentId: nil)
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Post.likeListOpen, eventProperties: ["post_id": postId])
            self.navigationController?.pushViewController(likedUserListView, animated: true)
        case .sharePost:
            guard let postId = postData?.postId else { return }
            ShareContentUtil.sharePost(viewController: self, postId: postId)
        default:
            break
        }
    }
}

extension HomeFeedViewControler: DeleteContentViewProtocol {
    
    func didReceivedDeletePostResponse(postId: String, commentId: String?) {
        homeFeedViewModel.feeds.removeAll(where: {$0.postId == postId})
        feedTableView.reloadData()
    }
}
extension HomeFeedViewControler: HomeFeedTableViewCellDelegate {
    func didTapOnCell(_ feedDataView: PostFeedDataView?) {
        guard let postId = feedDataView?.postId else { return }
        let postDetail = PostDetailViewController(nibName: "PostDetailViewController", bundle: Bundle(for: PostDetailViewController.self))
        postDetail.postId = postId
        self.navigationController?.pushViewController(postDetail, animated: true)
    }
}


extension HomeFeedViewControler: EmptyHomeFeedViewDelegate {
    func clickedOnNewPostButton() {
        if homeFeedViewModel.hasRightForCreatePost() {
            self.createNewPost()
        } else {
            self.showErrorAlert(message: "You don't have permission to create the resource!")
        }
    }
}

//MARK: - Ext. Delegate DocumentPicker
extension HomeFeedViewControler: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        if let attr = try? FileManager.default.attributesOfItem(atPath: url.relativePath), let size = attr[.size] as? Int, (size/1000000) > 8 {
            print(size)
            print((size/1000000))
            self.showErrorAlert(message: "Max size limit is 8 MB!")
            return
        }
        print(url)
        self.moveToAddResources(resourceType: .document, url: url)
        controller.dismiss(animated: true)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    
}
