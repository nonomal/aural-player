//
//  OperationQueueExtensions.swift
//  Aural
//
//  Copyright © 2025 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//  
import Foundation

extension OperationQueue {
    
    convenience init(opCount: Int, qos: DispatchQoS.QoSClass) {
        
        self.init()
        self.maxConcurrentOperationCount = opCount
        self.underlyingQueue = .global(qos: qos)
        
        switch qos {
            
        case .background:
            self.qualityOfService = .background
            
        case .utility:
            self.qualityOfService = .utility
            
        case .default:
            self.qualityOfService = .default
            
        case .userInitiated:
            self.qualityOfService = .userInitiated
            
        case .userInteractive:
            self.qualityOfService = .userInteractive
            
        case .unspecified:
            self.qualityOfService = .background
            
        @unknown default:
            self.qualityOfService = .background
        }
    }
    
    func cancelOpsAndWait() {
        
        if operationCount > 0 {
            
            cancelAllOperations()
            waitUntilAllOperationsAreFinished()
        }
    }
}
