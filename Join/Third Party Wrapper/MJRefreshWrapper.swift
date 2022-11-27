//
//  MJRefreshWrapper.swift
//  Join
//
//  Created by Riley Lai on 2022/11/27.
//

import UIKit
import MJRefresh

extension UITableView {
    func addRefreshHeader(refreshingBlock: @escaping () -> Void) {
        mj_header = MJRefreshNormalHeader(refreshingBlock: refreshingBlock)
    }

    func endHeaderRefreshing() {
        mj_header?.endRefreshing()
    }

    func beginHeaderRefreshing() {
        mj_header?.beginRefreshing()
    }
}

extension UICollectionView {
    func addRefreshHeader(refreshingBlock: @escaping () -> Void) {
        mj_header = MJRefreshNormalHeader(refreshingBlock: refreshingBlock)
    }

    func endHeaderRefreshing() {
        mj_header?.endRefreshing()
    }

    func beginHeaderRefreshing() {
        mj_header?.beginRefreshing()
    }
}
