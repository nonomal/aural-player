//
//  VisualizerUIPersistentState.swift
//  Aural
//
//  Copyright © 2021 Kartik Venugopal. All rights reserved.
//
//  This software is licensed under the MIT software license.
//  See the file "LICENSE" in the project root directory for license terms.
//
import Cocoa

///
/// Persistent state for all Visualizer settings.
///
/// - SeeAlso: `VisualizerViewState`
///
struct VisualizerUIPersistentState: Codable {
    
    let type: VisualizationType?
    let options: VisualizerOptionsPersistentState?
}

///
/// Persistent state for Visualizer options.
///
/// - SeeAlso: `VisualizerViewOptions`
///
struct VisualizerOptionsPersistentState: Codable {
    
    let lowAmplitudeColor: ColorPersistentState?
    let highAmplitudeColor: ColorPersistentState?
}
