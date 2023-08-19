import Foundation

public final class LocalFeedImageDataLoader {
    private let store: FeedImageDataStore
    
    public init(store: FeedImageDataStore) {
        self.store = store
    }
}

extension LocalFeedImageDataLoader {
    public typealias SaveResult = Result<Void, Error>
    
    public enum SaveError: Error {
        case failed
    }
    
    private func handleSaveResult(_ result: (Result<Void, Error>),
                                  completion: @escaping (SaveResult) -> Void) {
        completion(result.mapError { _ in SaveError.failed })
    }

    public func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        store.insert(data, for: url) { [weak self] result in
            self?.handleSaveResult(result, completion: completion)
        }
    }
}

extension LocalFeedImageDataLoader: FeedImageDataLoader {
    public typealias LoadResult = FeedImageDataLoader.Result
    
    public enum LoadError: Error {
        case failed
        case notFound
    }
    
    private final class LoadImageDataTask: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?
        
        init(_ completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    private func handleLoadImageData(result: Result<Data?, Error>,
                                     task: LoadImageDataTask) {
        task.complete(with: result
            .mapError { _ in LoadError.failed }
            .flatMap { data in
                data.map { .success($0) } ?? .failure(LoadError.notFound)
            })
    }
    
    public func loadImageData(from url: URL,
                              completion: @escaping (LoadResult) -> Void) -> FeedImageDataLoaderTask {
        let task = LoadImageDataTask(completion)
        store.retrieve(dataForURL: url) { [weak self] result in
            self?.handleLoadImageData(result: result,
                                      task: task)
        }
        return task
    }
}
