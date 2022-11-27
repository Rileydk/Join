////
////  SelectionCategoriesViewController.swift
////  Join
////
////  Created by Riley Lai on 2022/10/31.
////
//
//import UIKit
//
//class SelectionCategoriesViewController: UIViewController {
//    let tagView = TTGTextTagCollectionView()
//    var allCategories = ["Software", "Social Networking", "Workshop", "Music", "+"]
//    var selectedCategories: [String]
//    var passingHandler: (([String]) -> Void)?
//    let firebaseManager = FirebaseManager.shared
//
//    init(selectedCategories: [String]) {
//        self.selectedCategories = selectedCategories
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        firebaseManager.getPersonalInfo(of: .interests) { [weak self] result in
//            switch result {
//            case .success(let interests):
//                self?.allCategories = interests
//                self?.layoutViews()
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        passingHandler?(selectedCategories)
//    }
//
//    func layoutViews() {
//        view.addSubview(tagView)
//        tagView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            tagView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
//            tagView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            tagView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
//        ])
//
//        tagView.delegate = self
//        tagView.alignment = .left
//        let style = TTGTextTagStyle()
//        style.backgroundColor = .yellow
//        style.cornerRadius = 10
//        let selectedStyle = TTGTextTagStyle()
//        selectedStyle.backgroundColor = .green
//
//        let tags: [TTGTextTag] = allCategories.map {
//            let tag = TTGTextTag(
//                content: TTGTextTagStringContent(text: $0),
//                style: style,
//                selectedContent: TTGTextTagStringContent(text: $0),
//                selectedStyle: selectedStyle
//            )
//            tag.selected = selectedCategories.contains($0)
//            return tag
//        }
//        tags.last!.selectedStyle = style
//
//        tagView.add(tags)
//        tagView.reload()
//    }
//}
//
//// MARK: - TTG Delegate
//extension SelectionCategoriesViewController: TTGTextTagCollectionViewDelegate {
//    // swiftlint:disable line_length
//    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
//        if tag == textTagCollectionView.allTags().last! {
//            tag.selected = false
//            return
//        }
//
//        if let selectedCategory = (tag.content as? TTGTextTagStringContent)?.text {
//            if selectedCategories.contains(selectedCategory) {
//                let index = selectedCategories.firstIndex(of: selectedCategory)!
//                self.selectedCategories.remove(at: index)
//            } else {
//                self.selectedCategories.append(selectedCategory)
//            }
//        }
//    }
//}
