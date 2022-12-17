//
//  WorkManager.swift
//  Join
//
//  Created by Riley Lai on 2022/12/17.
//

import Foundation

extension FirebaseManager {
    func addNewWork(work: Work,completion: @escaping (Result<WorkID, Error>) -> Void ) {
        let ref = FirestoreMyDocEndpoint.myWorks.ref
        let workID = ref.document().documentID
        var work = work
        work.workID = workID
        work.latestUpdatedTime = Date()

        ref.document(workID).setData(work.toDict) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success(workID))
        }
    }

    func addNewRecords(
        records: [WorkRecord],to myWorkID: WorkID,
        completion: @escaping (Result<[RecordID], Error>) -> Void) {
        let ref = FirestoreMyDocEndpoint.myRecordsOfWork(myWorkID).ref

        let group = DispatchGroup()
        var shouldContinue = true
        var recordsIDs = [RecordID]()
        for record in records {
            group.enter()
            guard shouldContinue else { return }
            let recordID = ref.document().documentID
            var record = record
            record.recordID = recordID
            ref.document(recordID).setData(record.toDict) { err in
                if let err = err {
                    print(err)
                    group.leave()
                    shouldContinue = false
                    return
                }
                recordsIDs.append(recordID)
                group.leave()
            }
        }
        group.notify(queue: .main) {
            if shouldContinue {
                completion(.success(recordsIDs))
            } else {
                //                completion(.failure(err))
            }
        }
    }

    func updateWorkRecordsOrder(
        of workID: WorkID, by ordersIDs: [RecordID],
        completion: @escaping (Result<String, Error>) -> Void) {
        let ref = FirestoreMyDocEndpoint.myWorks.ref
        ref.document(workID).updateData(["recordsOrder": ordersIDs]) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            completion(.success(workID))
        }
    }

    func getUserWorks(userID: UserID, completion: @escaping (Result<[Work], Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref.document(userID).collection("Works")
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let works: [Work] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: Work.self)
                    } catch {
                        return nil
                    }
                }
                completion(.success(works))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }

    func getWorkRecords(
        userID: UserID, by workID: WorkID,
        completion: @escaping (Result<[WorkRecord], Error>) -> Void) {
        let ref = FirestoreEndpoint.users.ref.document(userID).collection("Works").document(workID).collection("Records")
        ref.getDocuments { (snapshot, err) in
            if let err = err {
                completion(.failure(err))
            }
            if let snapshot = snapshot {
                let workRecords: [WorkRecord] = snapshot.documents.compactMap {
                    do {
                        return try $0.data(as: WorkRecord.self)
                    } catch {
                        return nil
                    }
                }
                completion(.success(workRecords))
            } else {
                completion(.failure(CommonError.noValidQuerysnapshot))
            }
        }
    }
}
