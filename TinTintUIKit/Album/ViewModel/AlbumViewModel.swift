//
//  AlbumViewModel.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import Foundation
import Combine

class AlbumViewModel {
    
    @Published var albums: [Album] = []
    var cancellables = Set<AnyCancellable>()
    
    func fetchAlbums() {
        HttpManager.shared.fetchAlbums()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    switch error {
                    case .invalidUrl:
                        print("invalidUrl")
                    case .invalidData:
                        print("invalidData")
                    case .invalidResponse:
                        print("invalidResponse")
                    case .unknown:
                        print("unknown")
                    }
                }
            } receiveValue: { albums in
                self.albums = albums
            }
            .store(in: &cancellables)
    }
}
